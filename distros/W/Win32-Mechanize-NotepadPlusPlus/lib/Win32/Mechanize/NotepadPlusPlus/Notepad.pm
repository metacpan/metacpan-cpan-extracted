package Win32::Mechanize::NotepadPlusPlus::Notepad;
use 5.010;
use warnings;
use strict;
use Exporter 'import';
use IPC::Open2;
use Carp qw/croak carp cluck confess/;
use Config;
use Win32::API;
use Win32::GuiTest 1.64 qw':FUNC !SendMessage';     # 1.64 required for 64-bit SendMessage
use Win32::Mechanize::NotepadPlusPlus::__hwnd;
use Win32::Mechanize::NotepadPlusPlus::Notepad::Messages;  # exports the various message and "enum" hashes
use Win32::Mechanize::NotepadPlusPlus::Editor;

BEGIN {
    # import the GetWindowThreadProcessId, GetModuleFileNameEx, and EnumProcessModules
    #   functions from the user32 and psapi DLLs.

    Win32::API::->Import("user32","DWORD GetWindowThreadProcessId( HWND hWnd, LPDWORD lpdwProcessId)") or die "GetWindowThreadProcessId: $^E";  # uncoverable branch true
    # http://www.perlmonks.org/?node_id=806573 shows how to import the GetWindowThreadProcessId(), and it's reply shows how to pack/unpack the arguments to extract appropriate PID

    # by using the Win32::GuiTest AllocateVirtualBuffer, it already implements the handle and open-process
    #   so, I don't need these commented-out Imports
    # Win32::API::->Import("kernel32","HMODULE GetModuleHandle(LPCTSTR lpModuleName)") or die "GetModuleHandle: $^E";  # uncoverable branch true
    # my $hModule = GetModuleHandle("kernel32.dll") or die "GetModuleHandle: $! ($^E)";  # uncoverable branch true
    #print "handle(kernel32.dll) = '$hModule'\n";
    # Win32::API::->Import("kernel32","BOOL WINAPI GetModuleHandleEx(DWORD dwFlags, LPCTSTR lpModuleName, HMODULE *phModule)") or die "GetModuleHandleEx: $^E";  # uncoverable branch true
    # Win32::API::->Import("kernel32","HANDLE WINAPI OpenProcess(DWORD dwDesiredAccess, BOOL bInheritHandle, DWORD dwProcessId)") or die "OpenProcess: $! ($^E)";  # uncoverable branch true

    Win32::API::->Import("psapi","DWORD WINAPI GetModuleFileNameEx(HANDLE  hProcess, HMODULE hModule, LPTSTR  lpFilename, DWORD   nSize)") or die "GetModuleFileNameEx: $^E";  # uncoverable branch true
    Win32::API::->Import("psapi","BOOL EnumProcessModules(HANDLE  hProcess, HMODULE *lphModule, DWORD   cb, LPDWORD lpcbNeeded)") or die "EnumProcessModules: $^E";  # uncoverable branch true
}

our $VERSION = '0.006001'; # auto-populated from W::M::NPP

our @EXPORT_VARS = (@Win32::Mechanize::NotepadPlusPlus::Notepad::Messages::EXPORT);

our @EXPORT_OK = (@EXPORT_VARS);
our %EXPORT_TAGS = (
    vars            => [@EXPORT_VARS],
    all             => [@EXPORT_OK],
);

# __ptrBytes and __ptrPack: use for setting number of bytes or the pack/unpack character for a perl-compatible pointer
sub __ptrBytes64 () { 8 }
sub __ptrPack64  () { 'Q' }
sub __ptrBytes32 () { 4 }
sub __ptrPack32  () { 'L' }

if( $Config{ptrsize}==8 ) {
    *__ptrBytes = \&__ptrBytes64;
    *__ptrPack  = \&__ptrPack64;
} elsif ( $Config{ptrsize}==4) {
    *__ptrBytes = \&__ptrBytes32;
    *__ptrPack  = \&__ptrPack32;
} else {
    die "unknown pointer size: $Config{ptrsize}bytes";
}

=encoding utf8

=head1 NAME

Win32::Mechanize::NotepadPlusPlus::Notepad - The main application object for Notepad++ automation

=head1 SYNOPSIS

    use Win32::Mechanize::NotepadPlusPlus ':main';
    my $npp = notepad();    # main application

=head1 DESCRIPTION

The editor object for Notepad++ automation using L<Win32::Mechanize::NotepadPlusPlus>

=head2 Version Requirements

The module was developed with Notepad++ v7.7 or newer in mind, though some features should still
work on older versions of Notepad++.  As Notepad++ adds new features, the minimum version for
that method will be indicated in the help.

=cut

=head1 CONSTRUCTORS

The constructors and similar object methods in this section are purely for class access, and will be called by the NotepadPlusPlus
object.  They should never need to be referenced directly.
(Instead, you will get the notepad, editor1, editor2, and editor instances from the app instance)

=over

=item * notepad

=item * editor1

=item * editor2

=item * editor

    use Win32::Mechanize::NotepadPlusPlus;                      # creates the singleton ::Notepad object
    my $npp = Win32::Mechanize::NotepadPlusPlus::notepad();     # calls ...Notepad::notepad()
    my $ed1 = Win32::Mechanize::NotepadPlusPlus::editor1();     # calls ...Notepad::editor1()
    my $ed2 = Win32::Mechanize::NotepadPlusPlus::editor2();     # calls ...Notepad::editor2()
    my $ed  = Win32::Mechanize::NotepadPlusPlus::editor();      # calls ...Notepad::editor()

=for comment
The _enumScintillaHwnds is considered private by Pod::Coverage, because it starts with underscore.

=for comment
_new is a private creation method; the end user should never need to call it directly

=back

=cut

my %pid_started;

sub _new
{
    my ($class, @args) = @_;
    my $self = bless {
        _exe => undef,
        _pid => undef,
        _hwnd => undef,
        _menuID => undef,
        editor1 => undef,
        editor2 => undef,
    }, $class;

    # 2019-Oct-03: finally have a method of deriving
    #   the executable path from the hwnd, here's my plan for $npp_exe going forward
    #   * hwnd = FindWindowLike():
    #       FOUND) $npp_exe = path(hwnd)
    #       ELSE)  a) move the PATH/ENV{ProgramFiles} search from above BEGIN into here
    #              b) assuming a $npp_exe is found, start the process
    #   * pid = pid_from_hwnd(hwnd) -- ie, the single foreach loop below
    #   * then delete the BEGIN block above, not needed
    #   might use _functions for the above

    # check if there's an existing instance running
    my $i_ran_npp;
    if( ($self->{_hwnd}) = FindWindowLike(0, undef, '^Notepad\+\+$', undef, undef) ) {
        # grab the path from it, if possible
        $self->{_exe} = $self->_hwnd_to_path();
    } else {
        # search PATH and standard program locations for notepad++.exe
        my $npp_exe = $self->_search_for_npp_exe(); # will die if not found

        # start the process:
        my $launchPid = open2(my $npo, my $npi, $npp_exe);  # qw/notepad++ -multiInst -noPlugin/, $fname)
        $self->{_hwnd} = WaitWindowLike( 0, undef, '^Notepad\+\+$', undef, undef, 5 ) # wait up to 5sec
            or croak "could not run the Notepad++ application";  # uncoverable branch true
        $self->{_exe} = $npp_exe;
        $i_ran_npp = 1;
    }

    # get the PID for the hWnd
    foreach my $hwnd ( $self->{_hwnd} ) {
        #  need to grab the process back from the hwnd found
        my $pidStruct = pack("L" => 0);
        my $gwtpi = GetWindowThreadProcessId($hwnd, $pidStruct);
        my $extractPid = unpack("L" => $pidStruct);
        $self->{_pid} = $extractPid;
        if($i_ran_npp) {
            my $pidx = sprintf '%08x', $extractPid;
            $pid_started{$pidx} = $extractPid;
            #warn sprintf "CREATE: perl process '%s' created process '%s'\n", $$, $pid_started{$pidx};
        }
    }
    $self->{_hwobj} = Win32::Mechanize::NotepadPlusPlus::__hwnd->new( $self->{_hwnd} ); # create an object

    $self->{_menuID} = GetMenu($self->{_hwnd});

    # instantiate the two view-scintilla Editors from the first two Scintilla HWND children of the Editor HWND.
    my @sci_hwnds = @{$self->_enumScintillaHwnds()}[0..1];       # first two are the main editors
    @{$self}{qw/editor1 editor2/} = map Win32::Mechanize::NotepadPlusPlus::Editor->_new($_, $self->{_hwobj}), @sci_hwnds;

    return $self;
}

sub DESTROY {
    my $self = shift;
    my $pidx = sprintf '%08x', $self->{_pid} // 0;
    if( exists $pid_started{$pidx} ) {
        #warn sprintf "DESTROY: perl process '%s' is killing process '%s'\n", $$, $pid_started{$pidx};
        my $pid = delete $pid_started{$pidx};
        kill 9 => $pid;
    }
}

sub notepad { my $self = shift; $self }
sub editor1 { my $self = shift; $self->{editor1} }
sub editor2 { my $self = shift; $self->{editor2} }
sub editor  {
    # choose either editor1 or editor2, depending on which is active
    my $self = shift;
    $self->editor1 and $self->editor2 or croak "default editor object not initialized";
    my $view = $self->getCurrentView();
    return $self->{editor1} if 0 == $view;
    return $self->{editor2} if 1 == $view;
    croak "Notepad->editor(): unknown GETCURRENTSCIINTILLA=$view";
}

sub _enumScintillaHwnds
{
    my $self = shift;
    my @hwnds = FindWindowLike($self->hwnd(), undef, '^Scintilla$', undef, 2); # this will find all Scintilla-class windows that are direct children of the Notepad++ window
    return [@hwnds];
}

sub _hwnd_to_path
{
    my $self = shift;
    my $hwnd = $self->hwnd();
    my $filename;

    # use a dummy vbuf for getting the hprocess
    my $vbuf = AllocateVirtualBuffer($hwnd, 1);
    my $hprocess = $vbuf->{process};

    my $LENGTH_MAX = 1024;
    my $ENCODING  = 'cp1252';
    my $cb = Win32::API::Type->sizeof( 'HMODULE' ) * $LENGTH_MAX;
    my $lphmodule  = "\x0" x $cb;
    my $lpcbneeded = "\x0" x $cb;

    if (EnumProcessModules($hprocess, $lphmodule, $cb, $lpcbneeded)) {
        # the first 8 bytes of lphmodule would be the first pointer...
        my $hmodule = unpack __ptrPack(), substr($lphmodule,0,8);
        my $size = Win32::API::Type->sizeof( 'CHAR*' ) * $LENGTH_MAX;
        my $lpfilenameex = "\x0" x $size;
        GetModuleFileNameEx($hprocess, $hmodule, $lpfilenameex, $size);
        $filename = Encode::decode($ENCODING, unpack "Z*", $lpfilenameex);
    }
    FreeVirtualBuffer($vbuf);
    return $filename;
}

sub _search_for_npp_exe {
    my $npp_exe;
    use File::Which 'which';
    # priority to path, 64bit, default, then x86-specific locations
    my @try = ( which('notepad++') );
    push @try, "$ENV{ProgramW6432}/Notepad++/notepad++.exe" if exists $ENV{ProgramW6432};
    push @try, "$ENV{ProgramFiles}/Notepad++/notepad++.exe" if exists $ENV{ProgramFiles};
    push @try, "$ENV{'ProgramFiles(x86)'}/Notepad++/notepad++.exe" if exists $ENV{'ProgramFiles(x86)'};
    foreach my $try ( @try )
    {
        $npp_exe = $try if -x $try;
        last if defined $npp_exe;
    }
    die "could not find an instance of Notepad++; please add it to your path\n" unless defined $npp_exe;
    #print STDERR __PACKAGE__, " found '$npp_exe'\n";
    return $npp_exe;
}

=head2 Window Handle

=over

=item hwnd

    notepad->hwnd();

    my $npp_hWnd = notepad()->hwnd();

Grabs the window handle of the Notepad++ main window.

This is used for sending Windows messages; if you are enhancing the Notepad object's functionality (implementing some new Notepad++
message that hasn't made its way into this module, for example), you will likely need access to this handle.

=back

=cut

sub hwnd {
    $_[0]->{_hwnd};
}



=head1 NOTEPAD OBJECT API

These are the object-oriented methods for manipulating the Notepad++ GUI, using the C<notepad()> instance.

=cut

=head2 Files

These methods open, close, and save files (standard File menu operations).

=over

=item close

    notepad->close();

Closes the currently active document

=cut

sub close {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $NPPIDM{IDM_FILE_CLOSE} );
}

=item closeAll

    notepad->closeAll();

Closes all open documents

=cut

sub closeAll {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $NPPIDM{IDM_FILE_CLOSEALL} );
}

=item closeAllButCurrent

    notepad->closeAllButCurrent();

Closes all but the currently active document

=cut

sub closeAllButCurrent {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $NPPIDM{IDM_FILE_CLOSEALL_BUT_CURRENT} );
}

=item newFile

    notepad->newFile();

Create a new document.

=cut

sub newFile {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $NPPIDM{IDM_FILE_NEW} );
}

=item open

    notepad->open($filename);

Opens the given file.

=cut

sub open {
    my $self = shift;
    my $fileName = shift;
    croak "->open() method requires \$fileName argument" unless defined $fileName;

    my $ret = '<undef>';
    eval {
        $ret = $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_DOOPEN} , 0, $fileName);
        1;
    } or do {
        croak sprintf "->open('%s') died with msg:'%s'", $fileName, $@;
    };
    return $ret;
}

=item save

    notepad->save();

Save the current file

=cut

sub save {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_SAVECURRENTFILE} , 0 , 0 );
}

=item saveAllFiles

    notepad->saveAllFiles();

Saves all currently unsaved files

=cut

sub saveAllFiles {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_SAVEALLFILES} , 0 , 0 );
}

=item saveAs

    notepad->saveAs($filename);

Save the current file as the specified $filename

=cut

sub saveAs {
    my $self = shift;
    my $filename = shift;
    return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_SAVECURRENTFILEAS} , 0 , $filename );
}

=item saveAsCopy

    notepad->saveAsCopy($filename);

Save the current file as the specified $filename, but don’t change the filename for the buffer in Notepad++

=cut

sub saveAsCopy {
    my $self = shift;
    my $filename = shift;
    return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_SAVECURRENTFILEAS} , 1 , $filename );
}

=back

=head3 Sessions

Sessions allow you to make a group of files that you can easily reload by loading the session.

=over

=item saveCurrentSession

    notepad->saveCurrentSession($filename);

Save the current session (list of open files) to a file.

=cut

sub saveCurrentSession {
    my $self = shift;
    my $fname = shift;
    return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_SAVECURRENTSESSION}, 0 , $fname );
}

=item saveSession

    notepad->saveSession($filename, @filesList);

Saves a session (list of filenames in @filesList) to a file.

=cut

sub saveSession {
    my $self = shift;
    my $sessionFile = shift;
    my @fileList = @_;
    my $nFiles = scalar @fileList;

    my $hwnd = $self->hwnd();
    my $wparam = 0; # lparam below

    # NPPM_SAVESESSION

    #   TCHAR* sessionFilePathName;
    #       the full path name of session file to save
    #   int nbFile;
    #       the number of files in the session
    #   TCHAR** files;
    #       files' full path

    # memory for the $nFiles pointers, and the $nFiles strings that go into those pointers
    my $tcharpp = AllocateVirtualBuffer( $hwnd, $nFiles*__ptrBytes() ); #allocate 8-bytes per file for the pointer to each buffer (or 4bytes on 32bit perl)
    my @strBufs;
    for my $i ( 0 .. $#fileList ) {
        # allocate and populate each filename and buffer
        my $filename_ucs2le = Encode::encode( 'ucs2-le', $fileList[$i]);
        $strBufs[$i] = AllocateVirtualBuffer( $hwnd, length($filename_ucs2le) );
        WriteToVirtualBuffer( $strBufs[$i], $filename_ucs2le );
    }
    my @strPtrs = map { $_->{ptr} } @strBufs;   # want an array of pointers
    my $pk = __ptrPack();     # L is 32bit, so maybe I need to pick L or Q depending on ptrsize?
    my $tcharpp_val = pack $pk."*", @strPtrs;
    WriteToVirtualBuffer( $tcharpp , $tcharpp_val );

    # memory for the sessionFilePathName
    my $ucs2le = Encode::encode('ucs2-le', $sessionFile);
    my $sessionFilePathName = AllocateVirtualBuffer( $hwnd, length($ucs2le) );
    WriteToVirtualBuffer( $sessionFilePathName, $ucs2le );

    # memory for structure
    my $structure = AllocateVirtualBuffer( $hwnd , __ptrBytes() * 3 );
    my $struct_val = pack "$pk $pk $pk", $sessionFilePathName->{ptr}, $nFiles, $tcharpp->{ptr};
    WriteToVirtualBuffer( $structure, $struct_val );
    my $lparam = $structure->{ptr};

    # send the message
    my $ret = $self->SendMessage( $NPPMSG{NPPM_SAVESESSION}, $wparam, $lparam );
    # warn sprintf "saveSession(): SendMessage(NPPM_SAVESESSION, 0x%016x, l:0x%016x): ret = %d", $wparam, $lparam, $ret;

    # free virtual memories
    FreeVirtualBuffer($_) for $structure, $sessionFilePathName, @strBufs;

    return $ret;
}

=item loadSession

    notepad->loadSession($sessionFilename);

Opens the session by loading all the files listed in the $sessionFilename.

=cut

sub loadSession {
    my $self = shift;
    my $fname = shift;
    return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_LOADSESSION}, 0 , $fname );
}

=item getSessionFiles

    notepad->getSessionFiles($sessionFilename);

Reads the session stored in $sessionFilename, and returns a list of the file paths that it references.

This does not open the files in the session; to do that, use C<notepad()-E<gt>loadSession($sessionFilename)>

=cut

sub getSessionFiles {
    my $self = shift;
    my $sessionFile = shift;
    my $hwnd = $self->hwnd();

    # first determine how many files are involved
    my $nFiles = $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_GETNBSESSIONFILES}, 0, $sessionFile );
    # warn sprintf "getSessionFiles(%s): msg{NPPM_GETNBSESSIONFILES} => nFiles = %d\n", $sessionFile, $nFiles;

    #   wParam:     [out] TCHAR ** sessionFileArray
    #   lParam:     [in]const TCHAR * sessionFilePathName

    # memory for the $nFiles pointers, and the $nFiles strings that go into those pointers
    my $tcharpp = AllocateVirtualBuffer( $hwnd, $nFiles*__ptrBytes() ); #allocate 8-bytes per file for the pointer to each buffer (or 4bytes on 32bit perl)
    my @strBufs = map { AllocateVirtualBuffer( $hwnd, 1024 ) } 1 .. $nFiles;
    my @strPtrs = map { $_->{ptr} } @strBufs;   # want an array of pointers
    my $pk = __ptrPack();     # L is 32bit, so maybe I need to pick L or Q depending on ptrsize
    my $tcharpp_val = pack $pk."*", @strPtrs;
    WriteToVirtualBuffer( $tcharpp , $tcharpp_val );
    my $wparam = $tcharpp->{ptr};

    # memory for the sessionFilePathName
    my $ucs2le = Encode::encode('ucs2-le', $sessionFile);
    my $sessionFilePathName = AllocateVirtualBuffer( $hwnd, length($ucs2le) );
    WriteToVirtualBuffer( $sessionFilePathName, $ucs2le );
    my $lparam = $sessionFilePathName->{ptr};

    # send the message
    my $ret = $self->SendMessage( $NPPMSG{NPPM_GETSESSIONFILES}, $wparam, $lparam );
    # warn sprintf "getSessionFiles(): SendMessage(NPPM_GETSESSIONFILES, 0x%016x, l:0x%016x): ret = %d", $wparam, $lparam, $ret;

    # read the filenames
    my @filenameList;
    for my $bufidx ( 0 .. $#strBufs ) {
        my $text_buf = $strBufs[$bufidx];
        my $fname = Encode::decode('ucs2-le', ReadFromVirtualBuffer( $text_buf , 1024 ) );
        $fname =~ s/\0*$//;
        # warn sprintf "getSessionFiles(): #%d = \"%s\"\n", $bufidx, $fname;
        push @filenameList, $fname;
    }

    # free virtual memories
    FreeVirtualBuffer($_) for $sessionFilePathName, @strBufs;

    return @filenameList;
}

=back

=for comment /end of Files

=head2 Buffers and Views

These methods influence which views are available and which file buffers are available in which views;
they also read or manipulate the information about the files in these buffers.

Views relate to the one or two editor windows inside Notepad++.
Buffers are the individual file-editing buffers in each view.
Because each view has a group of buffers, each buffer has an index within that view.

Don't get confused: while the editor objects are named C<editor1> and C<editor2>, the
views are numbered 0 and 1.  That's why it's usually best to use
L<%VIEW|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%VIEW">,
either C<$VIEW{MAIN_VIEW}> (0) or C<$VIEW{SUB_VIEW}> (1), when selecting views.

=cut

=head3 Get/Change Active Buffers

These methods allow you to change which file buffer is active in a given view,
and get information about which view and buffer are active.

=over

=item activateBufferID

    notepad->activateBufferID($bufferID);

Activates the given $bufferID

=cut

sub activateBufferID {
    my $self = shift;
    my $bufid = shift // croak "->activateBufferID(\$bufferID): \$bufferID required";
    my $index = $self->SendMessage( $NPPMSG{NPPM_GETPOSFROMBUFFERID} , $bufid , 0 );
    my $view = ($index & 0xC0000000) >> 30; # upper bit is view
    $index &= 0x3FFFFFFF;
    return $self->SendMessage( $NPPMSG{NPPM_ACTIVATEDOC} , $view , $index );
}

=item activateFile

    notepad->activateFile($filename);

Activates the buffer with the given $filename, regardless of view.

=cut

sub activateFile {
    my $self = shift;
    my $fileName = shift // croak "->activateFile(\$filename): \$filename required";
    return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_SWITCHTOFILE} , 0, $fileName);
}

=item activateIndex

    notepad->activateIndex($view, $index);

Activates the document with the given $view and $index.

The value for C<$view> comes from L<%VIEW|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%VIEW">,
either C<$VIEW{MAIN_VIEW}> (0) or C<$VIEW{SUB_VIEW}> (1).

=cut

sub activateIndex {
    my $self = shift;
    my ($view, $index) = @_;
    croak "->activateIndex(): view must be defined" unless defined $view;
    croak "->activateIndex(): index must be defined" unless defined $index;
    return $self->SendMessage( $NPPMSG{NPPM_ACTIVATEDOC} , $view , $index );
}

=item getCurrentBufferID

    notepad->getCurrentBufferID();

Gets the bufferID of the currently active buffer

=cut

sub getCurrentBufferID {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_GETCURRENTBUFFERID} , 0 , 0 );
}

=item getCurrentDocIndex

    notepad->getCurrentDocIndex($view);

Gets the current active index for the given $view.

The value for C<$view> comes from L<%VIEW|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%VIEW">,
either C<$VIEW{MAIN_VIEW}> (0) or C<$VIEW{SUB_VIEW}> (1).

=cut

sub getCurrentDocIndex {
#msgs indicate it might need MAIN_VIEW or SUB_VIEW arguemnt
    my $self = shift;
    my $view = shift; croak "->getCurrentDocIndex(\$view) requires a view of \$VIEW{MAIN_VIEW} or \$VIEW{SUB_VIEW}" unless defined $view;
    return $self->SendMessage( $NPPMSG{NPPM_GETCURRENTDOCINDEX} , 0 , 0 );
}

=item getCurrentView


=item getCurrentScintilla

    notepad->getCurrentView();
    notepad->getCurrentScintilla();

Get the currently active view

The value returned comes from L<%VIEW|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%VIEW">,
either C<$VIEW{MAIN_VIEW}> (0) or C<$VIEW{SUB_VIEW}> (1).


=cut

sub getCurrentView {
    my $self = shift;
    return my $view = $self->SendMessage( $NPPMSG{NPPM_GETCURRENTVIEW} , 0 , 0 );
}

sub getCurrentScintilla {
    my $self = shift;
    return my $scint = $self->{_hwobj}->SendMessage_get32u( $NPPMSG{NPPM_GETCURRENTSCINTILLA} , 0 );
}

=item moveCurrentToOtherView

    notepad->moveCurrentToOtherView();

Moves the active file from one view to another

=cut

# pythonscript doesn't have it, but for my test suite, I want access to IDM_VIEW_GOTO_ANOTHER_VIEW
sub moveCurrentToOtherView {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $NPPIDM{IDM_VIEW_GOTO_ANOTHER_VIEW} );
}

=item cloneCurrentToOtherView

    notepad->cloneCurrentToOtherView();

Clones the active file from one view to the other, so it's now available in both views
(which makes it easy to look at different sections of the same file)

=cut

# pythonscript doesn't have it, but for my test suite, I want access to IDM_VIEW_GOTO_ANOTHER_VIEW
sub cloneCurrentToOtherView {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $NPPIDM{IDM_VIEW_CLONE_TO_ANOTHER_VIEW} );
}

=back

=head3 Get Filename Information

These methods allow you to get the filename for a selected or active buffer,
or get the list of all currently-open files.

=over

=item getBufferFilename

    notepad->getBufferFilename( $bufferid );
    notepad->getBufferFilename( );

Gets the filename of the selected buffer.

If $bufferid is omitted, it will get the filename of the active document

=cut

sub getBufferFilename {
    my $self = shift;
    my $bufid = shift || $self->getCurrentBufferID();   # optional argument: default to  NPPM_GETCURRENTBUFFERID
    return $self->{_hwobj}->SendMessage_getUcs2le( $NPPMSG{NPPM_GETFULLPATHFROMBUFFERID} , int($bufid) , { trim => 'retval' } );
}

=item getCurrentFilename

    notepad->getCurrentFilename();

Gets the filename of the active document

=cut

sub getCurrentFilename {
    return $_[0]->getBufferFilename();
}

=item getFiles

    notepad->getFiles();

Gets a list of the open filenames.

Returns:
A reference to an array-of-arrays, one row for each file, with filename, bufferID, index, and view as the elements of each row:

C<[ [$filename1, $bufferID1, $index1, $view1], ... [$filenameN, $bufferIDN, $indexN, $viewN] ]>

=cut

# 2019-Sep-23: vr of perlmonks [found the problem](https://perlmonks.org/?node_id=11106581):
#   need to pass SendMessage(hwnd, NPPM_GETOPENFILENAMESPRIMARY, ->{ptr}, $nFiles)
sub getFiles {
    my $self = shift;
    my $hwo = $self->{_hwobj};
    my $hwnd = $hwo->hwnd;
    my @tuples = ();

    foreach my $view (0,1) {
        my $msg = ($NPPMSG{NPPM_GETOPENFILENAMESPRIMARY}, $NPPMSG{NPPM_GETOPENFILENAMESSECOND})[$view];
        my $nbType = ($VIEW{PRIMARY_VIEW}, $VIEW{SECOND_VIEW})[$view];
        my $nFiles = $hwo->SendMessage($NPPMSG{NPPM_GETNBOPENFILES}, 0, $nbType );

        # allocate remote memory for the n pointers, 8 bytes per pointer
        my $tcharpp = AllocateVirtualBuffer( $hwnd, $nFiles*$Config{ptrsize} ); #allocate 8-bytes per file for the pointer to each buffer (or 4bytes on 32bit perl)

        # allocate remote memory for the strings, each 1024 bytes long
        my @strBufs = map { AllocateVirtualBuffer( $hwnd, 1024 ) } 1 .. $nFiles;

        # grab the pointers
        my @strPtrs = map { $_->{ptr} } @strBufs;

        # pack them into a string for writing into the virtual buffer
        my $pk = $Config{ptrsize}==8 ? 'Q*' : 'L*';     # L is 32bit, so maybe I need to pick L or Q depending on ptrsize?
        my $tcharpp_val = pack $pk, @strPtrs;

        # load the pointers into the tcharpp
        WriteToVirtualBuffer( $tcharpp , $tcharpp_val );

        # send the message
        #   https://web.archive.org/web/20190325050754/http://docs.notepad-plus-plus.org/index.php/Messages_And_Notifications
        #   wParam = [out] TCHAR ** fileNames
        #   lParam = [in] int nbFile
        my $ret = $hwo->SendMessage( $msg, $tcharpp->{ptr}, $nFiles );

        # grab the strings
        for my $bufidx ( 0 .. $#strBufs ) {
            my $text_buf = $strBufs[$bufidx];
            my $fname = Encode::decode('ucs2-le', ReadFromVirtualBuffer( $text_buf , 1024 ) );
            $fname =~ s/\0*$//;

            # get buffer id for each position
            my $bufferID = $hwo->SendMessage( $NPPMSG{NPPM_GETBUFFERIDFROMPOS} , $bufidx, $view );

            push @tuples, [$fname, $bufferID, $bufidx, $view];
        }

        # cleanup when done
        FreeVirtualBuffer( $_ ) foreach $tcharpp, @strBufs;
    } # end view loop
    return [@tuples];
}

=item getNumberOpenFiles

    notepad->getNumberOpenFiles($view);
    notepad->getNumberOpenFiles();

Returns the number of open files in $view, which should be 0 or 1.
If $view is C<undef> or not given or 0, return total number of files open in either view.

It can use the L<%VIEW|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%VIEW"> hash,
either C<$VIEW{ALL_OPEN_FILES}>, C<$VIEW{PRIMARY_VIEW}>, or C<$VIEW{SECOND_VIEW}>.

=cut

sub getNumberOpenFiles {
    my $self = shift;
    my $view = shift // 0;
    croak "->getNumberOpenFiles(\$view = $view): \$view must be from %VIEW" if (0+$view)>2 or (0+$view)<0;
    return $self->SendMessage($NPPMSG{NPPM_GETNBOPENFILES}, 0, $view );
}

=back

=head3 Get/Set Language Parser

These methods allow you to determine or change the active language parser for the buffers.

=over

=item getCurrentLang

    notepad->getCurrentLang();

Get the current language type as an integer.  See the L<%LANGTYPE|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%LANGTYPE"> hash.

To convert this integer into the name of the language, use L</getLanguageName>.

=cut

sub getCurrentLang {
    my $self = shift;
    return $self->{_hwobj}->SendMessage_get32u($NPPMSG{NPPM_GETCURRENTLANGTYPE}, 0);
}

=item getLangType

    notepad->getLangType($bufferID);
    notepad->getLangType();

Gets the language type (integer) of the given $bufferID. If no $bufferID is given, then the language integer of the currently active buffer is returned.

See the L<%LANGTYPE|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%LANGTYPE"> hash for the language type integer.

    if( notepad->getLangType() == $LANGTYPE{L_PERL} ) { $usingRightLanguage = 1; }                        # verify you're programming in the right language
    printf qq(%s => %s\n), $_, $LANGTYPE{$_} for sort { $LANGTYPE{$a} <=> $LANGTYPE{$b} } keys %LANGTYPE; # lists the mapping from key to integer, like L_PERL => 21

You can use the L</getLanguageName> method to retrieve a string corresponding to the language integer.

=cut

# https://github.com/bruderstein/PythonScript/blob/1d9230ffcb2c110918c1c9d36176bcce0a6572b6/PythonScript/src/NotepadPlusWrapper.cpp
sub getLangType {
    my $self = shift;
    my $bufferID = shift;
    return $self->getCurrentLang() unless $bufferID;
    return $self->SendMessage($NPPMSG{NPPM_GETBUFFERLANGTYPE}, $bufferID);
}

=item setCurrentLang

    notepad->setCurrentLang($langType);

Set the language type for the currently-active buffer.  C<$langType> should be from the L<%LANGTYPE|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%LANGTYPE"> hash.

=cut

sub setCurrentLang {
    my $self = shift;
    my $langType = shift;
    return $self->SendMessage($NPPMSG{NPPM_SETCURRENTLANGTYPE}, 0, $langType);
}

=item setLangType

    notepad->setLangType($langType, $bufferID);
    notepad->setLangType($langType);

Sets the language type of the given bufferID. If not bufferID is given, sets the language for the currently active buffer.

C<$langType> should be from the L<%LANGTYPE|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%LANGTYPE"> hash.

=cut

sub setLangType {
    my $self = shift;
    my $langType = shift;
    my $bufferID = shift;
    return $self->setCurrentLang($langType) unless $bufferID;
    return $self->SendMessage($NPPMSG{NPPM_SETBUFFERLANGTYPE}, $bufferID, $langType);
}

=item getLanguageName

=item getLanguageDesc

    notepad->getLanguageName($langType);
    notepad->getLanguageDesc($langType);

Get the name and or longer description for the given language $langType, which should either be from the L<%LANGTYPE|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%LANGTYPE"> hash, or
the return value from L</getLangType> or L</getCurrentLang>.

=cut

sub getLanguageName {
    my $self = shift;
    my $langType = shift;
    return $self->{_hwobj}->SendMessage_getUcs2le( $NPPMSG{NPPM_GETLANGUAGENAME}, $langType, { trim => 'retval' } );
}

sub getLanguageDesc {
    my $self = shift;
    my $langType = shift;
    return $self->{_hwobj}->SendMessage_getUcs2le( $NPPMSG{NPPM_GETLANGUAGEDESC}, $langType, { trim => 'retval' } );
}

=back

=head3 Encoding and EOL Information

Determines the encoding for a given file, and determines or changes the EOL-style for the file buffer.

=over

=item getEncoding

    notepad->getEncoding($bufferID);
    notepad->getEncoding();

Gets the encoding of the given bufferID, as an integer. If no bufferID is given, then the encoding of the currently active buffer is returned.

Returns:
An integer corresponding to how the buffer is encoded.

Additional Info:

Using this integer as the key to the
L<%Win32::Mechanize::NotepadPlusPlus::Notepad::Messages::BUFFERENCODING|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/%BUFFERENCODING>
hash will give a string name corresponding to the encoding.

    print $BUFFERENCODING{notepad->getEncoding()};


=cut

sub getEncoding {
    my $self = shift;
    my $bufid = shift || $self->getCurrentBufferID();   # optional argument: default to  NPPM_GETCURRENTBUFFERID
    return $self->SendMessage( $NPPMSG{NPPM_GETBUFFERENCODING} , int($bufid) , 0);
}

=item setEncoding

    notepad->setEncoding($bufferID, $encoding);
    notepad->setEncoding($encoding);

Sets the encoding of the given bufferID. If no bufferID is given, then the encoding of the currently active buffer is set.

You can set C<$encoding> as a value from the
L<%Win32::Mechanize::NotepadPlusPlus::Notepad::Messages::BUFFERENCODING|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/%BUFFERENCODING>
hash.

    notepad->setEncoding($BUFFERENCODING{UTF8_BOM});

Additional Info:
This should behave similarly to using the L</menuCommand> method, with the C<IDM_FORMAT_*> values from C<%NPPIDM>.

=cut

sub setEncoding {
    my $self = shift;
    unshift(@_, $self->getCurrentBufferID()) unless 1 < @_;  # if only one argument left, it's got to be the encoding, so add in buffer ID
    my ($bufid,$enc) = @_;
    return $self->SendMessage( $NPPMSG{NPPM_SETBUFFERENCODING} , int($bufid), int($enc) );
}

=item getFormatType

    notepad->getFormatType($bufferID);
    notepad->getFormatType();

Gets the EOL format type (i.e. Windows [0], Unix [1] or old Mac EOL [2]) of the given bufferID.
If no bufferID is given, then the format of the currently active buffer is returned.

Returns:
The integers 0,1,or 2, corresponding to Windows EOL (CRLF), Unix/Linux (LF), or the old Mac EOL (CR).

=cut

sub getFormatType {
    my $self = shift;
    my $bufid = shift || $self->getCurrentBufferID();   # optional argument: default to  NPPM_GETCURRENTBUFFERID
    return $self->SendMessage( $NPPMSG{NPPM_GETBUFFERFORMAT}, $bufid);
}

=item setFormatType

    notepad->setFormatType($formatType, $bufferID);
    notepad->setFormatType($formatType);

Sets the EOL format type (i.e. Windows [0], Unix [1] or old Mac EOL [2]) of the specified buffer ID. If not bufferID is passed, then the format type of the currently active buffer is set.

=cut

sub setFormatType {
    my $self = shift;
    my $formatType = shift;
    my $bufid = shift || $self->getCurrentBufferID();   # optional argument: default to  NPPM_GETCURRENTBUFFERID
    return $self->SendMessage( $NPPMSG{NPPM_SETBUFFERFORMAT}, $bufid, $formatType);
}

=back

=head3 Reload Buffers

These methods allow you to reload the contents of the appropriate buffer from what is on disk.

=over

=item reloadBuffer

    notepad->reloadBuffer($bufferID);

Reloads the given $bufferID

=cut

sub reloadBuffer {
    my $self = shift;
    my $bufferID = shift;
    return $self->SendMessage( $NPPMSG{NPPM_RELOADBUFFERID}, $bufferID, 0);
}

=item reloadCurrentDocument

    notepad->reloadCurrentDocument();

Reloads the buffer of the current document

=cut

sub reloadCurrentDocument {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND}, 0, $NPPIDM{IDM_FILE_RELOAD});
}

=item reloadFile

    notepad->reloadFile($filename);

Reloads the buffer for the given $filename

=cut

sub reloadFile {
    my $self = shift;
    my $fileName = shift;
    my $alert = shift() ? 1 : 0;

    return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_RELOADFILE}, $alert , $fileName);
}

=back

=for comment /end of Buffers and Views

=head2 Hidden Scintilla Instances

When automating Notepad++, there are times when you may want an extra
Scintilla Editor instance, even though it never needs to be seen
inside the Notepad++ window.  You can create and destroy hidden
instances using these methods

=over

=item createScintilla

    notepad->createScintilla();
    notepad->createScintilla( $parentHwnd );

Create a new Scintilla handle. Returns an Editor object.
This Scintilla editor instance is not available to be displayed in either view,
but in all other ways behaves like the main Scintilla Editor instances.

If C<$parentHwnd> is passed (non-zero), that HWND will be used as the parent
window for the new Scintilla; otherwise, Notepad++ itself will be used as the parent.

Please note: as of v7.8, there is no way to properly destroy the created Scintilla handle.
There are a limited number of Scintilla handles that can be allocated before.

=cut

sub createScintilla {
    my ($self,$parent) = @_;

    $parent ||= $self->hwnd();    # this makes Notepad++ the parent if $parent is 0 or undefined

    if( !$parent or ref($parent) ) {
        # if it's false, or undefined, or a reference, then it's not a valid hwnd
        die sprintf "%s::createScintilla(%s,%s): requires HWND to use as the parent, not undef or an object", ref($self), $self, defined($parent)?$parent:'<undef/missing>';
    }

    # NPPM_CREATESCINTILLAHANDLE
    my $sci = $self->SendMessage( $NPPMSG{NPPM_CREATESCINTILLAHANDLE}, 0, $parent );
    return Win32::Mechanize::NotepadPlusPlus::Editor->_new($sci, $parent);
}

=item destroyScintilla

    notepad->destroyScintilla($editor);

This method always returns a true, and warns that the method is deprecated.

In Notepad++ v7.7.1 and earlier, the NPPM_DESTROYSCINTILLAHANDLE tried to destroy the scintilla instance.
However, this could crash Notepad++, so as of v7.8, Notepad++ ignores this message.  To prevent
L<Win32::Mechanize::NotepadPlusPlus> from crashing Notepad++, the C<destroyScintilla()> does not
bother to send the message (in case it's Notepad++ v7.7.1 or earlier).

=cut

sub destroyScintilla {
    my $self = shift;
    warnings::warnif('deprecated', '->destroyScintilla() method does nothing, so it does not destroy a Scintilla instance [deprecated]');
    return 1;
    # if Don ever re-implements NPPM_DESTROYSCINTILLAHANDLE to properly destroy the scintilla handle, I should re-implement this.
    if(0) { # uncoverable statement
        my ($self,$hwnd) = @_;

        $hwnd = $hwnd->hwnd() if ref($hwnd) and (UNIVERSAL::isa($hwnd, 'Win32::Mechanize::NotepadPlusPlus::Editor') or UNIVERSAL::isa($hwnd, 'Win32::Mechanize::NotepadPlusPlus::__hwnd'));    # this makes sure it's the HWND, not an object

        if( !(0+$hwnd) or ref($hwnd) ) {
            # if it's 0 (or undefined or a string), or a still a reference, then we didn't find a valid hwnd
            die sprintf "%s::destroyScintilla(%s,%s): requires scintilla HWND to destroy", ref($self), $self, defined($hwnd)?$hwnd:'<undef/missing>';
        }

        if( $hwnd == $self->editor1()->hwnd() or $hwnd == $self->editor2()->hwnd() ) {
            die sprintf "%s::destroyScintilla(%s,%s): not valid to destroy one of Notepad++'s default Scintilla windows (%s, %s)!",
                ref($self), $self, defined($hwnd)?$hwnd:'<undef/missing>',
                $self->editor1()->hwnd(), $self->editor2()->hwnd()
            ;
        }

        # NPPM_DESTROYSCINTILLAHANDLE
        return $self->SendMessage( $NPPMSG{NPPM_DESTROYSCINTILLAHANDLE}, 0, $hwnd );
    }
}

=back

=for comment /end of Hidden Scintilla Instances

=head2 GUI Manipulation

=over

=cut

=item hideMenu

    notepad->hideMenu();

Hides the menu bar.

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub hideMenu {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDEMENU}, 0, 1);
    # NPPM_HIDEMENU, lParam=1
}

=item showMenu

    notepad->showMenu();

Shows the menu bar

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub showMenu {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDEMENU}, 0, 0);
    # NPPM_HIDEMENU, lParam=0
}

=item isMenuHidden

    notepad->isMenuHidden();

Returns 1 if the menu bar is currently hidden, 0 if it is shown.

=cut

sub isMenuHidden {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_ISMENUHIDDEN}, 0, 0);
    # NPPM_ISMENUHIDDEN
}

=item hideTabBar

    notepad->hideTabBar();

Hides the Tab bar.

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub hideTabBar {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDETABBAR}, 0, 1);
    # NPPM_HIDETABBAR, lParam=1
}

=item showTabBar

    notepad->showTabBar();

Shows the Tab bar

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub showTabBar {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDETABBAR}, 0, 0);
    # NPPM_HIDETABBAR, lParam=0
}

=item isTabBarHidden

    notepad->isTabBarHidden();

Returns 1 if the tab bar is currently hidden, 0 if it is shown.

=cut

sub isTabBarHidden {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_ISTABBARHIDDEN}, 0, 0);
    # NPPM_ISTABBARHIDDEN
}

=item hideToolBar

    notepad->hideToolBar();

Hides the toolbar.

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub hideToolBar {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDETOOLBAR}, 0, 1);
    # NPPM_HIDETOOLBAR, lParam=1
}

=item showToolBar

    notepad->showToolBar();

Shows the toolbar

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub showToolBar {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDETOOLBAR}, 0, 0);
    # NPPM_HIDETOOLBAR, lParam=0
}

=item isToolBarHidden

    notepad->isToolBarHidden();

Returns 1 if the toolbar is currently hidden, 0 if it is shown.

=cut

sub isToolBarHidden {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_ISTOOLBARHIDDEN}, 0, 0);
    # NPPM_ISTOOLBARHIDDEN
}

=item hideStatusBar

    notepad->hideStatusBar();

Hides the status bar.

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub hideStatusBar {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDESTATUSBAR}, 0, 1);
    # NPPM_HIDESTATUSBAR, lParam=1
}

=item showStatusBar

    notepad->showStatusBar();

Shows the status bar

RETURN:
The previous state: it will return 1 if it was hidden before, or 0 if it was shown before

=cut

sub showStatusBar {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_HIDESTATUSBAR}, 0, 0);
    # NPPM_HIDESTATUSBAR, lParam=0
}

=item isStatusBarHidden

    notepad->isStatusBarHidden();

Returns 1 if the status bar is currently hidden, 0 if it is shown.

=cut

sub isStatusBarHidden {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_ISSTATUSBARHIDDEN}, 0, 0);
    # NPPM_ISSTATUSBARHIDDEN
}

=item setStatusBar

    notepad->setStatusBar($statusBarSection, $text);

Sets the selected status bar section to the given $text.

For C<$statusBarSection>, use one of the L<%STATUSBAR|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%STATUSBAR"> values.

=cut

sub setStatusBar {
    my $self = shift;
    my $section = shift;
    my $text = shift;
    $section = $STATUSBAR{$section} if exists $STATUSBAR{$section};   # allow name or value
    return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_SETSTATUSBAR} , $section, $text );
    # NPPM_SETSTATUSBAR
}

# make _getStatusBar private, since it doesn't work (yet)
#sub _getStatusBar {
#    # There may be a workaround which could be implemented: for each of the sections, compute the default value...
#    #   or see dev-zoom-tooltips.py : npp_get_statusbar()
#    my $self = shift;
#    my $section = shift;
#    $section = $STATUSBAR{$section} if exists $STATUSBAR{$section};   # allow name or value
#    return undef;
#    #return $self->{_hwobj}->SendMessage_sendStrAsUcs2le( $NPPMSG{NPPM_SETSTATUSBAR} , $section, $text );
#    # NPPM_GETSTATUSBAR -- Does Not Exist!
#}

=item getLineNumberWidthMode

=item setLineNumberWidthMode

    $mode = notepad->getLineNumberWidthMode();
    notepad->setLineNumberWidthMode($mode);

Get or set the line number width mode, either dynamic width mode or
constant width mode.

C<$mode> uses one of the L<%LINENUMWIDTH|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/"%LINENUMWIDTH"> values.

These were added in Notepad++ v7.9.2 to allow the line-numbering to be
constant-width -- so the line number column will have the same width at
line 1000000 as it shows at line 1000 -- or adjust to the width of the
line number -- so the line-number column will be wider when you get to
line 1000000 then when you were at line 1000.  (Prior to v7.9.2, the
line number width was always dynamic.)

=cut

sub getLineNumberWidthMode {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_GETLINENUMBERWIDTHMODE} , 0, 0);
    # NPPM_GETLINENUMBERWIDTHMODE
}

sub setLineNumberWidthMode {
    my $self = shift;
    my $value = shift // 0;
    return $self->SendMessage( $NPPMSG{NPPM_SETLINENUMBERWIDTHMODE} , 0, $value);
    # NPPM_GETLINENUMBERWIDTHMODE
}

=item getMainMenuHandle

    notepad->getMainMenuHandle();

Gets the handle for the main Notepad++ application menu (which contains File, Edit, Search, ...).

=cut

sub getMainMenuHandle {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_GETMENUHANDLE} , 1, 0);
    # NPPM_GETMENUHANDLE
}

=item getPluginMenuHandle

    notepad->getPluginMenuHandle();

Gets the handle for the Plugins menu.

=cut

sub getPluginMenuHandle {
    my $self = shift;
    return $self->SendMessage( $NPPMSG{NPPM_GETMENUHANDLE} , 0, 0);
    # NPPM_GETMENUHANDLE
}

=item menuCommand

    notepad->menuCommand($menuCommand);

Runs a Notepad++ menu command. Use the MENUCOMMAND values from the C<%NPPIDM> hash (described below), or integers directly from the nativeLang.xml file, or the string name from the hash.

=cut

sub menuCommand {
    my $self = shift;
    my $menuCmdId = shift;
    $menuCmdId = $NPPIDM{$menuCmdId} if exists $NPPIDM{$menuCmdId}; # allow named command string, or the actual ID
    return $self->SendMessage( $NPPMSG{NPPM_MENUCOMMAND} , 0 , $menuCmdId );
    # NPPM_MENUCOMMAND
}

=item runMenuCommand

    notepad->runMenuCommand(@menuNames);
    notepad->runMenuCommand(@menuNames, { refreshCache => $value } );

Runs a command from the menus. For built-in menus use C<notepad-E<gt>menuCommand()>, for non built-in menus (e.g. TextFX and macros you’ve defined), use C<notepad-E<gt>runMenuCommand(menuName, menuOption)>. For other plugin commands (in the plugin menu), use C<notepad-E<gt>runPluginCommand(pluginName, menuOption)>.

Menus are searched for the text, and when found, the internal ID of the menu command is cached. When runMenuCommand is called, the cache is first checked if it holds the internal ID for the given menuName and menuOption. If it does, it simply uses the value from the cache. If the ID could have been updated (for example, you’re calling the name of macro that has been removed and added again), set refreshCache to any Perl expression that evaluates as True.

C<@menuNames> is a one-or-more element list of strings; each string can either be a name from the menu hierarchy (either a menu name or a command name) or a pipe-separated string with multiple names.  See the example below.


Returns:
True if the menu command was found, otherwise False

e.g.:

    notepad()->runMenuCommand('Tools', 'SHA-256', 'Generate from selection into clipboard');
    notepad()->runMenuCommand('Tools', 'SHA-256 | Generate from selection into clipboard');
    notepad()->runMenuCommand('Tools | SHA-256', 'Generate from selection into clipboard');
    notepad()->runMenuCommand('Tools | SHA-256 | Generate from selection into clipboard');

    notepad()->runMenuCommand('Macro', 'Trim Trailing Space and Save', { refreshCache => 1 });

=cut

my %cacheMenuCommands;
sub runMenuCommand {
    my $self = shift;
    # 2019-Oct-14: see debug\menuNav.pl for my attempt to find a specific menu; I will need to add caching here, as well as add test coverage...
    #   It appears 'menuOption' was meant to be a submenu item; in which case, I might want to collapse it down, or otherwise determine whether the third argument is passed or not
    # https://github.com/bruderstein/PythonScript/blob/1d9230ffcb2c110918c1c9d36176bcce0a6572b6/PythonScript/src/NotepadPlusWrapper.cpp#L865
    #printf STDERR "\n__%04d__:runMenuCommand(%s)\n", __LINE__, join ", ", map { defined $_ ? qq('$_') : '<undef>'} @_;
    my %opts = ();
    %opts = %{pop(@_)} if ref($_[-1]) and UNIVERSAL::isa($_[-1],'HASH');
    $opts{refreshCache} = 0 unless exists $opts{refreshCache};

    #printf STDERR "\n__%04d__:runMenuCommand(%s, {refreshCache => %s})\n", __LINE__, join(", ", map { defined $_ ? qq('$_') : '<undef>'} @_), $opts{refreshCache};

    ## printf STDERR "\n__%04d__:\tcacheMenuCommands = (%s\n\t\t)\n", __LINE__, join("\n\t\t\t", '', map { "'$_' => '$cacheMenuCommands{$_}'" } keys %cacheMenuCommands);

    my $cacheKey = undef;
    my $action;
    if(!$opts{refreshCache}) {
        $cacheKey = join ' | ', @_;
        $action = $cacheMenuCommands{$cacheKey} if exists $cacheMenuCommands{$cacheKey};
    }

    #printf STDERR "__%04d__:\tcacheKey = '%s'\n", __LINE__, $cacheKey // '<undef>';

    $action //= _findActionInMenu( $self->{_menuID} , @_ );
    #printf STDERR "__%04d__:\taction(%s) = '%s'\n", __LINE__, $self->{_menuID} // '<undef>', $action // '<undef>';
    return undef unless defined $action;    # pass the problem up the chain

    $cacheMenuCommands{$cacheKey} = $action if defined($cacheKey) and defined $action;


    # 2019-Oct-15: I just realized I don't know how to run the menu item
    #   oh, PythonScript source code implies it's SendMessage(m_nppHandle, WM_COMMAND, commandID, 0);
    #define WM_COMMAND                      0x0111
    $NPPMSG{WM_COMMAND} = Win32::GuiTest::WM_COMMAND unless exists $NPPMSG{WM_COMMAND};
    return $self->SendMessage( $NPPMSG{WM_COMMAND} , $action, 0);

    #exit https://stackoverflow.com/questions/18589385/retrieve-list-of-menu-items-in-windows-in-c
}

=item runPluginCommand

    notepad->runPluginCommand($pluginName, $menuOption, $refreshCache);
    notepad->runPluginCommand($pluginName, $menuOption);

Runs a command from the plugin menu. Use to run direct commands from the Plugins menu. To call TextFX or other menu functions, either use C<notepad-E<gt>menuCommand(menuCommand)> (for Notepad++ menu commands), or C<notepad-E<gt>runMenuCommand(menuName, menuOption)> for TextFX or non standard menus (such as macro names).

Note that menuOption can be a submenu in a plugin’s menu. So:

    notepad->runPluginCommand('Python Script', 'demo script');

Could run a script called “demo script” from the Scripts submenu of Python Script.

Menus are searched for the text, and when found, the internal ID of the menu command is cached. When runPluginCommand is called, the cache is first checked if it holds the internal ID for the given menuName and menuOption. If it does, it simply uses the value from the cache. If the ID could have been updated (for example, you’re calling the name of macro that has been removed and added again), set refreshCache to True. This is False by default.

e.g.:

    notepad->runPluginCommand(‘XML Tools’, ‘Pretty Print (XML only)’);

=cut

sub runPluginCommand {
    my $self = shift;
    # I think I can implement this by just calling the search-function with 'Plugins' as the top level
    return $self->runMenuCommand('Plugins', @_);
}

#item notepad()-E<gt>_findActionInMenu($menuID, @menus)
# helper for the runMenuCommand/runPluginCommand
{
    my @recurse = ();
    my $topID = undef;
    sub _resetFindActionInMenuRecursion {
        @recurse = ();
        $topID = undef;
    }
    sub _findActionInMenu {
        #printf STDERR "\n__%04d__:_findActionInMenu(%s)\n", __LINE__, join ", ", map { defined $_ ? qq('$_') : '<undef>'} @_;
        #print STDERR "\tcallers = (", join(',', caller), ")\n";
        my $menuID = shift;
        my ($top, @hier) = @_;
        my $count = GetMenuItemCount( $menuID );
        $topID = $menuID unless defined $topID;
        #printf STDERR "\ttop='%s'(%s)\tcount=%s\thier=(%s)\n", map { $_//'<undef>'} $top, $topID, $count, join('|',@hier);

        if($top =~ /\|/) {   # need to split into multiple levels
            # print STDERR "found PIPE '|'\n";
            my @tmp = split /\|/, $top;
            s/^\s+|\s+$//g for @tmp;     # trim spaces
            $top = shift @tmp;          # top is really just the first element of the original top
            unshift @hier, @tmp;        # prepend the @hier with the remaining elements of the split top
            #print STDERR "new (", join(', ', map { qq/'$_'/ } $top, @hier), ")\n";
        }

        for my $idx ( 0 .. $count-1 ) {
            my %h = GetMenuItemInfo( $menuID, $idx );
            #print STDERR "\t\%h = (", join(', ', grep { $_ } map { "$_ => '$h{$_}'" if exists $h{$_} } qw/type text/),")\n";
            if( $h{type} eq 'string' ) {
                my $realText = $h{text};
                (my $cleanText = $realText) =~ s/(\&|\t.*$)//g; # might have & _and_ \t, so need to use /g
                if( $top eq $realText or $top eq $cleanText ) {
                    #print STDERR "# ", __LINE__, " FOUND($top): $realText => $cleanText\n";
                    if( my $submenu = GetSubMenu($menuID, $idx) ) {
                        return _findActionInMenu( $submenu, @hier );
                    } elsif ( my $action = GetMenuItemID( $menuID, $idx ) ) {
                        #print STDERR "# ", __LINE__, "\tthe action ID = $action\n";
                        return $action;
                    } else {
                        #print STDERR "# ", __LINE__, "\tcouldn't go deeper in the menu\n";
                        return undef;
                    }
                }
            }
            # this idx didn't match... but I may need it later (assuming it's a submenu)
            if( my $submenu = GetSubMenu($menuID, $idx) ) {
                push @recurse, $submenu;
            }
        }
        #print STDERR "# ", __LINE__, "$menuID# ($top | @hier) wasn't found; try to recurse: (@recurse)\n";
        if($menuID == $topID) { # only try recursion if we're at the top level
            while( my $submenu = shift @recurse ) {
                my $found = _findActionInMenu( $submenu, $top, @hier );
                if($found) {
                    _resetFindActionInMenuRecursion();
                    return $found;
                }
            }
            #print STDERR "$menuID# ($top | @hier) wasn't found, even after recusion\n";
        }
        return undef;
    }
}

=item messageBox

    notepad->messageBox($message, $title, $flags);
    notepad->messageBox($message, $title);
    notepad->messageBox($message);

Displays a message box with the given message and title.

    Flags can be 0 for a standard ‘OK’ message box, or a combination of MESSAGEBOXFLAGS. title is “Win32::Mechanize::NotepadPlusPlus” by default, and flags is 0 by default.

Returns:
A RESULTxxxx member of MESSAGEBOXFLAGS as to which button was pressed.

=cut

sub messageBox {
    my $self = shift;
    my ($message, $title, $flags) = @_;
    $message = "" unless $message;
    $title = "Win32::Mechanize::NotepadPlusPlus" unless $title;
    $flags = 0 unless $flags;
    return Win32::MsgBox( $message, $flags, $title );
    # https://github.com/bruderstein/PythonScript/blob/1d9230ffcb2c110918c1c9d36176bcce0a6572b6/PythonScript/src/NotepadPlusWrapper.cpp#L698
    # retVal = ::MessageBoxA(m_nppHandle, message, title, flags);
    # => https://metacpan.org/pod/Win32 => for Win32::MsgBox
}



=item prompt

    notepad->prompt($prompt, $title, $defaultText);
    notepad->prompt($prompt, $title);

Prompts the user for some text. Optionally provide the default text to initialise the entry field.

Returns:
The string entered.

None if cancel was pressed (note that is different to an empty string, which means that no input was given)

=cut

sub prompt {
    my $self = shift;
    my $prompt = shift;
    my $title = shift // 'PerlScript notepad->prompt()';
    my $text = shift // ''; # default text
    # https://github.com/bruderstein/PythonScript/blob/1d9230ffcb2c110918c1c9d36176bcce0a6572b6/PythonScript/src/NotepadPlusWrapper.cpp#L711

    my $nlines = do {
        my $tmp = $prompt;          # don't change original
        $tmp =~ s/\R*\z/\r\n/ms;    # ensure every line ends in newline, but no extra blank lines
        scalar $tmp =~ s/\R//g;     # number of replacements is number of newlines is number of lines
    };
    my $lheight = do {
        my $h = 4 + 13*$nlines;
        ($h<20) ? 20 : ($h>200) ? 200 : $h;
    };

    {
        # => https://www.mail-archive.com/perl-win32-gui-users@lists.sourceforge.net/msg04117.html => may come in handy for ->prompt()
        use Win32::GUI ();
        my $mw = Win32::GUI::DialogBox->new(
                -caption => $title,
                -pos => [100,100],              # TODO: PythonScript centered it in the Notepad++ window, which makes more sense
                -size => [480,210 + $lheight],  # Per @Alan-Kilborne, prefer bigger than PythonScript's notepad.prompt()
                -helpbox => 1,
        );

        $mw->AddLabel(
                -pos => [10,10],
                -size => [$mw->ScaleWidth() - 20, $lheight],
                -text => $prompt,
                -name => 'PROMPT',
        );

        my $tf = $mw->AddTextfield(
                -pos => [10,$mw->PROMPT->Top()+$lheight+10],
                -size => [$mw->ScaleWidth() - 20, $mw->ScaleHeight() - $lheight - 60],
                -tabstop => 1,
                -text => $text,             # start with original(default) value for text
                -multiline => 1,
                -autovscroll => 1,
                -vscroll => 1,
                -name => 'TEXTFIELD',
        );

        $mw->AddButton(
                -name => 'OK',
                -text => 'Ok',
                -ok => 1,
                -default => 1,
                -tabstop => 1,
                -pos => [$mw->ScaleWidth()-160,$mw->ScaleHeight()-30],
                -size => [70,20],
                -onClick => sub { $text = $tf->Text(); return -1; },
        );

        $mw->AddButton(
                -name => 'CANCEL',
                -text => 'Cancel',
                -cancel => 1,
                -tabstop => 1,
                -pos => [$mw->ScaleWidth()-80,$mw->ScaleHeight()-30],
                -size => [$mw->OK->Width(),$mw->OK->Height()],
                -onClick => sub { $text = undef; return -1; },          # don't return the default value on cancel; best to return undef to disambiguate from an empty value with OK
        );


        $mw->Show();
        $tf->SetFocus();
        Win32::GUI::Dialog();
    }
    # possible alternative: https://stackoverflow.com/questions/4201399/prompting-a-user-with-an-input-box-c
    #   => https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-dialogboxparama?redirectedfrom=MSDN


    return $text;
}

=item SendMessage

    notepad->SendMessage( $msgid, $wparam, $lparam );

For any messages not implemented in the API, if you know the
appropriate $msgid, and what are needed as $wparam and $lparam,
you can send the message to the Notepad GUI directly.

If you have developed a wrapper for a missing message, feel free to send in a
L<Pull Request|https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/pulls>,
or open an L<issue|https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues>,
including your wrapper code.

=cut

sub SendMessage {
    my ($self, $msgid, $wparam, $lparam) = @_;
    return $self->{_hwobj}->SendMessage( $msgid, $wparam, $lparam );
}

=back

=for comment /end of GUI Manipulation

=head2 Meta Information

These give details about the current instance of Notepad++, or the Perl Library, or Perl itself.

=over

=item getNppVersion

    notepad->getNppVersion();

Gets the Notepad++ version as a string.

(This was called getVersion in the PythonScript API.)

=cut

sub getNppVersion {
    my $self = shift;
    my $version_int =  $self->SendMessage( $NPPMSG{NPPM_GETNPPVERSION}, 0, 0);
    my $major = ($version_int & 0xFFFF0000) >> 16;
    my $minor = ($version_int & 0x0000FFFF) >> 0;
    return 'v'.join '.', $major, split //, $minor;
}

=item getPluginVersion

    notepad->getPluginVersion();

Gets the PythonScript plugin version as a string.

=cut

sub getPluginVersion {
    return "v$VERSION";
}

=item getPerlVersion

    notepad->getPerlVersion();

Gets the Perl interpreter version as a string.

=cut

sub getPerlVersion {
    return ''.$^V;
}

=item getPerlBits

    notepad->getPerlBits();

Gets the Perl interpreter bits-information (32-bit vs 64-bit) as an integer.

=cut

sub getPerlBits {
    return __ptrBytes()*8;
}

=item getCommandLine

    notepad->getCommandLine();

Gets the command line used to start Notepad++

NOT IMPLEMENTED.  RETURNS C<undef>.  (May be implemented in the future.)

=cut

sub getCommandLine {
    my $self = shift;
    # https://github.com/bruderstein/PythonScript/blob/1d9230ffcb2c110918c1c9d36176bcce0a6572b6/PythonScript/src/NotepadPlusWrapper.cpp#L893
    return undef;
}

=item getNppDir

    notepad->getNppDir();

Gets the directory Notepad++ is running in (i.e. the location of notepad++.exe)

=cut

sub getNppDir {
    my $self = shift;
    # NPPM_GETNPPDIRECTORY
    my $dir = $self->{_hwobj}->SendMessage_getUcs2le($NPPMSG{NPPM_GETNPPDIRECTORY},1024,{ trim => 'wparam' });
    $dir =~ s/\0*$//;
    return $dir;
}

=item getPluginConfigDir

    notepad->getPluginConfigDir();

Gets the plugin config directory.

=cut

sub getPluginConfigDir {
    my $self = shift;
    # NPPM_GETPLUGINSCONFIGDIR
    my $dir = $self->{_hwobj}->SendMessage_getUcs2le($NPPMSG{NPPM_GETPLUGINSCONFIGDIR},1024,{ trim => 'wparam' });
    $dir =~ s/\0*$//;
    return $dir;
}

=item getNppVar

    notepad->getNppVar($userVar);

Gets the value of the specified Notepad++ User Variable

Use $userVar from L<%INTERNALVAR|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/%INTERNALVAR>.

=cut
my %nppVarMsg = (
    $INTERNALVAR{FULL_CURRENT_PATH}        => $NPPMSG{NPPM_GETFULLCURRENTPATH},
    $INTERNALVAR{CURRENT_DIRECTORY}        => $NPPMSG{NPPM_GETCURRENTDIRECTORY},
    $INTERNALVAR{FILE_NAME}                => $NPPMSG{NPPM_GETFILENAME},
    $INTERNALVAR{NAME_PART}                => $NPPMSG{NPPM_GETNAMEPART},
    $INTERNALVAR{EXT_PART}                 => $NPPMSG{NPPM_GETEXTPART},
    $INTERNALVAR{CURRENT_WORD}             => $NPPMSG{NPPM_GETCURRENTWORD},
    $INTERNALVAR{NPP_DIRECTORY}            => $NPPMSG{NPPM_GETNPPDIRECTORY},
    $INTERNALVAR{GETFILENAMEATCURSOR}      => $NPPMSG{NPPM_GETFILENAMEATCURSOR},
    $INTERNALVAR{CURRENT_LINE}             => $NPPMSG{NPPM_GETCURRENTLINE},
    $INTERNALVAR{CURRENT_COLUMN}           => $NPPMSG{NPPM_GETCURRENTCOLUMN},
    $INTERNALVAR{NPP_FULL_FILE_PATH}       => $NPPMSG{NPPM_GETNPPFULLFILEPATH},
);
sub getNppVar {
    my ($self, $var) = @_;
    die sprintf("notepad()->getNppVar(%s): no such variable\n", $var) unless exists $nppVarMsg{$var};
    my $ret;
    if($var == $INTERNALVAR{CURRENT_LINE} or $var == $INTERNALVAR{CURRENT_COLUMN}) {
        # numeric return
        $ret = $self->{_hwobj}->SendMessage( $nppVarMsg{$var}, 0, 0 );
    } else {
        # I don't like the hardcoded length, but all of the text-based recommend MAX_PATH as the length
        $ret = $self->{_hwobj}->SendMessage_getUcs2le( $nppVarMsg{$var}, 1024, { trim => 'wparam' });
        $ret =~ s/\0*$//;
    }
    return $ret;
}

=item getSettingsOnCloudPath

    $settings_folder = notepad->getSettingsOnCloudPath();

Get the "Settings on Cloud" path (from B<Settings E<gt> Preferences E<gt> Cloud>). It is useful if plugins want to store its settings on Cloud, if this path is set.

=cut

sub getSettingsOnCloudPath {
    # NPPM_GETSETTINGSONCLOUDPATH
    my $self = shift;
    my $dir = $self->{_hwobj}->SendMessage_getUcs2le($NPPMSG{NPPM_GETSETTINGSONCLOUDPATH},0,{ trim => 'retval+1', wlength => 1 });
    $dir =~ s/\0*$//;
    return $dir;
}

=back

=for comment /end of Meta Information

=head2 FUTURE: Callbacks

Callbacks are functions that are registered to various events.

FUTURE: they were in the PythonScript plugin, but I don't know if they'll be able to work in the remote perl module.
If I ever integrated more tightly with a Notepad++ plugin, it may be that they can be implemented then.

=cut

# =over
#
# =cut
#
# =item callback
#
#    notepad->callback(\&function, $notifications)
#
#
# Registers a callback function for a notification. notifications is a list of messages to call the function for.:
#
#     def my_callback(args):
#             console.write("Buffer Activated %d\n" % args["bufferID"]
#
# =item callback
#
#    notepad->callback(\&my_callback, [NOTIFICATION.BUFFERACTIVATED])
#
# The NOTIFICATION enum corresponds to the NPPN_* plugin notifications. The function arguments is a map, and the contents vary dependant on the notification.
#
# Note that the callback will live on past the life of the script, so you can use this to perform operations whenever a document is opened, saved, changed etc.
#
# Also note that it is good practice to put the function in another module (file), and then import that module in the script that calls notepad->callback(). This way you can unregister the callback easily.
#
# For Scintilla notifications, see editor.callback()
#
# Returns:
# True if the registration was successful
#
# =cut
#
# sub callback {
#     my $self = shift;
#     # https://github.com/bruderstein/PythonScript/blob/e1e362178e8bfab90aa908f44214b170c8f40de0/PythonScript/src/NotepadPython.cpp#L64
#     # https://github.com/bruderstein/PythonScript/blob/1d9230ffcb2c110918c1c9d36176bcce0a6572b6/PythonScript/src/NotepadPlusWrapper.cpp#L176
#     return undef;
# }
#
# =item clearCallbacks
#
#    notepad->clearCallbacks()
#
# Unregisters all callbacks
#
# =item clearCallbacks
#
#    notepad->clearCallbacks(\&function)
#
# Unregisters all callbacks for the given function. Note that this uses the actual function object, so if the function has been redefined since it was registered, this will fail. If this has happened, use one of the other clearCallbacks() functions.
#
# =item clearCallbacks
#
#    notepad->clearCallbacks($eventsList)
#
# Unregisters all callbacks for the given list of events.:
#
#     notepad->clearCallbacks([NOTIFICATION.BUFFERACTIVATED, NOTIFICATION.FILESAVED])
#
# See NOTIFICATION
#
# =item clearCallbacks
#
#    notepad->clearCallbacks(\&function, $eventsList)
#
# Unregisters the callback for the given callback function for the list of events.
#
# =cut
#
# sub clearCallbacks {
#     my $self = shift;
#     # https://github.com/bruderstein/PythonScript/blob/e1e362178e8bfab90aa908f44214b170c8f40de0/PythonScript/src/NotepadPython.cpp#L82-L85
#     # https://github.com/bruderstein/PythonScript/blob/1d9230ffcb2c110918c1c9d36176bcce0a6572b6/PythonScript/src/NotepadPlusWrapper.cpp#L741-L812
#     return undef;
# }
#
# =back

=for comment /end of Callbacks

=head1 EXPORTS

The primary interface is through the L</NOTEPAD OBJECT API>, implemented through object methods.

However, there are some hash variables that are useful for use with the API.
These can be exported individually, or using the C<:vars> or C<:all> tags.

=over

=item :vars

Exports just the variables in L<Win32::Mechanize::NotepadPlusPlus::Notepad::Messages>.

It's usually used via L<Win32::Mechanize::NotepadPlusPlus>'s C<:vars> tag, which
exports the variables in L<Win32::Mechanize::NotepadPlusPlus::Notepad::Messages> and
in L<Win32::Mechanize::NotepadPlusPlus::Editor::Messages>:

    use Win32::Mechanize::NotepadPlusPlus ':vars';

The full documentation for the available variables is in L<Win32::Mechanize::NotepadPlusPlus::Notepad::Messages>.
Additionally, some of frequently-used hashes are summarized below.

=over

=item %NPPMSG

This hash contains maps all known message names from L<Notepad_plus_msgs.h|https://github.com/notepad-plus-plus/notepad-plus-plus/blob/master/PowerEditor/src/MISC/PluginsManager/Notepad_plus_msgs.h>, which are useful for passing to the C<SendMessage> method.

You can find out the names and values of all the messages using:

    use Win32::Mechanize::NotepadPlusPlus ':vars';
    printf "%-40s => %s\n", $_, $NPPMSG{$_} for sort keys %NPPMSG;

=item %NPPIDM

This hash contains maps all known message names from L<menuCmdID.h|https://github.com/notepad-plus-plus/notepad-plus-plus/blob/master/PowerEditor/src/menuCmdID.h>, which are useful for passing to the L</notepad()-E<gt>menuCommand()> method (or the C<SendMessage> method with the NPPM_MENUCOMMAND message.)

You can find out the names and values of all the messages using:

    use Win32::Mechanize::NotepadPlusPlus ':vars';
    printf "%-40s => %s\n", $_, $NPPIDM{$_} for sort keys %NPPIDM;

... or by looking at the source code for L<Win32::Mechanize::NotepadPlusPlus::Notepad::Messages>.

=item %BUFFERENCODING

The numerical values from this hash can be passed to
L<notepad-E<gt>setEncoding|Win32::Mechanize::NotepadPlusPlus::Notepad/setEncoding>
to change the encoding of the buffer; the numerical values returned from
L<notepad-E<gt>getEncoding|Win32::Mechanize::NotepadPlusPlus::Notepad/getEncoding>
can be passed as keys for this hash to convert the encoding number back to a string.

See the full table of values at
L<%Win32::Mechanize::NotepadPlusPlus::Notepad::Messages::BUFFERENCODING|Win32::Mechanize::NotepadPlusPlus::Notepad::Messages/%BUFFERENCODING>

=back

=item :all

Exports everything that can be exported.

=back

=head1 INSTALLATION

Installed as part of L<Win32::Mechanize::NotepadPlusPlus>


=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests emailing C<E<lt>bug-Win32-Mechanize-NotepadPlusPlus AT rt.cpan.orgE<gt>>
or thru the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Mechanize-NotepadPlusPlus>,
or thru the repository's interface at L<https://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues>.

=head1 COPYRIGHT

Copyright (C) 2019,2020,2021 Peter C. Jones

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
