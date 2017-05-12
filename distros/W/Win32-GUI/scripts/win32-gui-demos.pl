#!perl -w
use strict;
use warnings;

# Display and run the Win32::GUI demonstrations
# $Id: win32-gui-demos.pl,v 1.6 2008/01/13 20:21:16 robertemay Exp $
# (c) Robert May, 2006.  This software is released
# under the same terms as perl itself.

# TODO:
# mouse feedback on launching events
# hide console windows on launch
# load_treeview can take a long time, provide re-draw and cursor feedback
#   (and progress bar?)

our $VERSION = '0.03';
$VERSION = eval $VERSION;

my $progname  = "Win32::GUI Demo Launcher";
my $copyright = "(c) Robert May, 2006.";

use Config();
use File::Find();
use File::Basename();

use Win32::GUI 1.03_04, qw( WS_CLIPCHILDREN WS_EX_CLIENTEDGE
                            WM_MENUSELECT WM_NOTIFY WM_GETDLGCODE NM_RETURN
                            CW_USEDEFAULT SW_SHOWDEFAULT TVHT_ONITEM
                            IDC_WAIT DLGC_HASSETSEL WM_KEYDOWN WM_CHAR VK_TAB);

#use Win32::GUI::Console();
use Win32::GUI::Scintilla::Perl();

# We want Win32::Process, but can manage without
# Win32::Process may not be installed (although it is standard
# with ActiveState perl).

#our ($HAS_WIN32_PROCESS);
#BEGIN {
#    eval "use Win32::Process qw(DETACHED_PROCESS)";
#    $HAS_WIN32_PROCESS = $@ ? 0 : 1;
#}

## Globals:
my $options = MyConfig::load_config();         # Hash of option values
my %nodes;          # mapping of treeview node_id to demo path/file.pl

######################################################################
# Build the UI
######################################################################

######################################################################
# Main menu
######################################################################
my $menu = Win32::GUI::Menu->new(
    "&File"     =>            "File",
    ">&Options...\tCtrl-O" => { -name => "Options", -onClick => \&getOptions },
    ">&Source\tCtrl-S"     => { -name => "Source",  -onClick => \&showMySource },
    ">-"        => 0,
    ">E&xit"    => { -name => "Exit",    -onClick => sub {-1}, },
    "&Help"     =>            "HelpB",
    ">&Help\tF1"           => { -name => "Help",    -onClick => \&showHelp, },
    ">&About..."           => { -name => "About",   -onClick => \&showAboutBox, },
);

my @menu_help = (
    undef,  # File Button
    undef,  # Help Button
    "Change program options.",
    "View the source for this program.",
    undef,  # Seperator
    "Exit.",
    undef,  # ??
    "View help for using this program.",
    $copyright,
);

## Accelerators:
my $accel = Win32::GUI::AcceleratorTable->new(
	"Ctrl-O" => \&getOptions,
	"Ctrl-S" => \&showMySource,
	"F1"     => \&showHelp,
);

######################################################################
# A class that removes the Win32::GUI default CS_HDRAW and CS_VDRAW
# styles - helps with reducing flicker when we are not scaling the
# content of the windows
######################################################################
my $class = Win32::GUI::Class->new(
    -name  => "Win32_GUI_MyClass",
    -style => 0,
) or die "Class";

######################################################################
# Main window
######################################################################
my $mw = Win32::GUI::Window->new(
    -title     => $progname,
    -left      => CW_USEDEFAULT,
    -size      => [750,500],
    -menu      => $menu,
    -accel     => $accel,
    -class     => $class,
    -pushstyle => WS_CLIPCHILDREN,  # avoid flicker on resize
    -onResize  => \&mwResize,
    -dialogui  => 1,
) or die "MainWindow";

## Hook for displaying menu help in the status bar
$mw->Hook(WM_MENUSELECT, \&showMenuHelp);

######################################################################
# Status bar
######################################################################
$mw->AddStatusBar(
    -name => 'SB',
) or die "StatusBar";

######################################################################
# Treeview
######################################################################
$mw->AddTreeView(
    -name            => 'TV',
    -pos             => [0,0],
    -width           => 200,
    -height          => $mw->ScaleHeight() - $mw->SB->Height(),
    -rootlines       => 1,
    -lines           => 1,
    -buttons         => 1,
    -onNodeClick     => \&loadFile,
    #-onMouseDown     => \&tvClick,
    -onMouseDblClick => \&tvDoubleClick,
    -tabstop         => 1,
) or die "Treeview";
## Hook for getting notification when <RETURN> key is pressed
$mw->TV->Hook(NM_RETURN, \&tvReturnHook);

######################################################################
# Splitter
######################################################################
$mw->AddSplitter(
    -name      => 'SP',
    -top       => 0,
    -left      => $mw->TV->Width(),
    -height    => $mw->ScaleHeight() - $mw->SB->Height(),
    -width     => 3,
    -onRelease => \&splitterRelease,
) or die "Splitter";

######################################################################
# Launch Button
######################################################################
$mw->AddButton(
    -name     => 'BUT',
    -text     => "Run demo ...",
    -disabled => 1,
    -top      => 10,
    -onClick  => \&runCurrent,
    -tabstop  => 1,
) or die "Button";
$mw->BUT->Left($mw->ScaleWidth()-10-$mw->BUT->Width());

######################################################################
# Code display area
######################################################################
$mw->AddScintillaPerl(
    -name       => 'RE',
    -left       => $mw->SP->Left() + $mw->SP->Width(),
    -top        => $mw->BUT->Top() + $mw->BUT->Height() + 10,
    -width      => $mw->ScaleWidth() - $mw->TV->Width() - $mw->SP->Width(),
    -height     => $mw->ScaleHeight() -$mw->SB->Height()- $mw->BUT->Height() - 20,
    -readonly   => 1,
    -addexstyle => WS_EX_CLIENTEDGE,
    -tabstop    => 1,
) or die "Editor";
$mw->RE->Hook(WM_GETDLGCODE, \&fixScintillaDlgCode);

######################################################################
# load tree view and run application
######################################################################
load_treeview($mw->TV);

$mw->Show();
$mw->TV->SetFocus();
Win32::GUI::Dialog();
$mw->Hide();
undef $mw;
exit(0);

######################################################################
# Callbacks
######################################################################

######################################################################
# Resize main window
######################################################################
sub mwResize {
    my $win = shift;
    my $h = $win->ScaleHeight();
    my $w = $win->ScaleWidth();

    # Move the Status bar
    $win->SB->Top($h - $win->SB->Height());
    $win->SB->Width($w);

    # Adjust Height of treeview and splitter
    $win->TV->Height($h - $win->SB->Height());
    $win->SP->Height($h - $win->SB->Height());

    # Re-position button
    my $butleft = $win->ScaleWidth() - 10 - $win->BUT->Width();
    my $butleft_min = $win->TV->Width() + $win->SP->Width();
    $butleft = $butleft_min if $butleft < $butleft_min;

    $win->BUT->Left($butleft);

    # Fill remaining space with code display area
    $win->RE->Width($w - $win->TV->Width() - $win->SP->Width());
    $win->RE->Height($win->TV->Height() - $win->BUT->Height() - 20);

    # Stop the splitter moving over our button
    $win->SP->Change(-max => $win->BUT->Left() - 10);

    return 1;
}

######################################################################
# Reposition splitter
# Horizontal splitter, so only need to resize the 2 panes
######################################################################
sub splitterRelease {
    my ($s, $coord) = @_;
    my $p = $s->GetParent();

    $p->TV->Width($coord);
    $p->RE->Left($coord + $s->Width());
    $p->RE->Width($p->ScaleWidth() - $coord - $s->Width());

    return 1;
}

######################################################################
# Display menu help in the status bar
######################################################################
sub showMenuHelp {
    my ($win, $wParam, $lParam, $type, $msgcode) = @_;
    return 1 unless $type == 0;
    return 1 unless $msgcode == WM_MENUSELECT;

    if($lParam == 0) { # leaving menu
        $win->SB->Text($options->{current} || '');
    }
    else {
        # This technique is distinctly flakey, and depends
        # on understanding how the internals of Win32::GUI
        # allocates ids to menu items.  This mechanism has
        # changed since Win32::GUI 1.03, the code below
        # should work with old and new builds
        my $item = $wParam & 0xFF;
        $item -= 100 if $item > 100;;
        $win->SB->Text($menu_help[$item] || '');
    }

    return 1;
}

######################################################################
# Treeview <RETURN> pressed
######################################################################
sub tvReturnHook {
    my ($win, $wParam, $lParam, $type, $msgcode) = @_;
    return 1 unless $type == WM_NOTIFY;
    return 1 unless $msgcode == NM_RETURN;

    my $node = $win->GetSelection();
    loadFile($win, $node);

    # Force a non-zero return value to stop the beep that results
    # from default processing
    $win->Result(1);
    return 0;
}

######################################################################
# Treview node click - if node has associate file, load it
######################################################################
sub loadFile {
    my ($tv, $node) = @_;

    return 0 unless exists $nodes{$node};

    my $file = $nodes{$node};

    if(!defined($options->{current}) or $file ne $options->{current}) {
        $options->{current} = $file;
        # Can't use $tv->GetParent(), as GetParent is redefined to get
        # the parent node ... oops
        my $p = Win32::GUI::GetWindowObject(Win32::GUI::GetParent($tv));

        # If Scintilla is readonly, then LoadFile doesn't work
        $p->RE->SetReadOnly(0);
        $p->RE->LoadFile($file);
        $p->RE->SetReadOnly(1);

        $p->SB->Text($options->{current});
        $p->BUT->Enable();
    }

    return 1;
}

######################################################################
# Treview double click - if double click is on a node, load and run
# the associated file
######################################################################
sub tvDoubleClick {
    my ($tv, $x, $y) = @_;
    my ($node, $flags) = $tv->HitTest($x,$y);

    if($node && ($flags & TVHT_ONITEM)) {
        my $loaded = loadFile($tv, $node);
        runCurrent($tv) if($loaded);
    }

    return 1;
}

######################################################################
# Scintilla Notify Events
# - handle folding events
######################################################################
sub RE_Notify {
    my (%evt) = @_;

    if ($evt{-code} == Win32::GUI::Scintilla::SCN_MARGINCLICK) {
        # Click on folder margin
        if ($evt{-margin} == 2) {
            $mw->RE->FolderEvent(%evt);
        }
    }
}

######################################################################
# Scintilla fixScintillaDlgCode
# - Scintilla returns DLGC_HASSETSEL|DLGC_WANTALLKEYS in response
# to a WM_GETDLGCODE message.  This prevents 'TAB' navigation working,
# so this hook fixes that
######################################################################
sub fixScintillaDlgCode {
    my ($win, $wParam, $lParam, $type, $msgcode) = @_;
    return 1 unless $type == 0;
    return 1 unless $msgcode == WM_GETDLGCODE;

	# $lParam is a pointer to a MSG structure, or NULL:
	if($lParam == 0) {
		$win->Result(DLGC_HASSETSEL);
		return 0;
	}
	else {
		my($m_hwnd, $m_msgcode, $m_wParam, $m_lParam, $m_time, $m_x, $m_y)
			= unpack("LLLLLLL", unpack("P28", pack( "L", $lParam)));

		if($m_msgcode == WM_KEYDOWN or $msgcode == WM_CHAR) {
			if($m_wParam == VK_TAB) {
				$win->Result(DLGC_HASSETSEL);
				return 0;
			}
		}
	}
	return 1;  # Do default processing
}

######################################################################
# Button click (and node double-click) - run current file
######################################################################
sub runCurrent {
    my $control = shift;

    return 1 unless -f $options->{current};

    # Without putting an extra space on the start of the options
    # perl appears to miss the first option.  I haven't
    # investigated why, but adding this space makes launching
    # with both Win32::Process and ShellExecute work
    my $extra_opts = " ";

    # Environment variable W32G_OPTS allows passing, for example
    # '-Mblib' to executed application;  PERL5OPTS is no good here
    # as it is parsed after command line options, so
    # Win32::GUI::Console is not found.
    $extra_opts .= $ENV{W32G_OPTS} ? $ENV{W32G_OPTS} : "";


    # TODO
    # Here's the strategy that I'm going to use for dealing with console
    # windows:
    #
    # Every launched process will get its own console, regardless
    # of whether this script has a console or not - if we share
    # the console of this process, then output will be
    # very confusing, with output from different processes
    # interspersed (and although I doubt any of the demos read
    # from STDIN, if they did we'd have an unmitigated mess)
    #
    # To avoid lots of console flashing we really need working
    # versions of Win32::Process and Win32::GUI::Console. We assume
    # Win32::GUI::Console, as it is distributed with Win32::GUI, and
    # this script use()s it, so we will have failed to start ...
    #
    # - If we have Win32::Process
    #   Use Win32::Process to launch with DETACHED_PROCESS.
    #   Use -MWin32::GUI::Console=ondemand to create and
    #   show a console if and when it is needed.
    #
    # - If Win32::Process is not available, use ShellExecute.
    #   ShellExecute creates a new console for non-gui apps,
    #   so we use wperl.exe rather than perl.exe, if we have it:
    #
    # - If wperl.exe is available, use it and
    #   pass -MWin32::GUI::Console=ondemand to create and
    #   show a console if it is needed.
    #
    # - If wperl.exe is not available, use perl.exe and use
    #   -MWin32::GUI::Console=ondemand to hide the console and
    #   show it when needed
    #
    #########################
    # CURRENT IMPLEMENTATION:
    # Use ShellExecuteEx with perl (not wperl), and ALWAYS get
    # a console.  In future either the samples should be re-written
    # to not require a console, or above startegy should be used,
    # or BOTH.

    #$extra_opts .= " -MWin32::GUI::Console=ondemand";

    #TODO: should really do some error checking!
    #if ($HAS_WIN32_PROCESS) {
    #    my $result = Win32::Process::Create(my $process_obj,
    #        $options->{perl}, "$extra_opts \"$options->{current}\"",
    #        0, DETACHED_PROCESS, ".");
    #    warn "Failed to start \"$options->{current}\": $^E" unless $result;
    #}
    #else {
        my $result = $control->ShellExecute("open",
            #$options->{wperl} ? $options->{perl} : $options->{perl},
            $options->{perl},
            "$extra_opts \"$options->{current}\"",
            "", SW_SHOWDEFAULT);
    #}

    return 1;
}

######################################################################
# Help menu item.  Show help text in help window
######################################################################
sub showHelp {
	my $win;

	$win = Win32::GUI::Window->new(
		-title       => "$progname Help",
		-left        => CW_USEDEFAULT,
		-size        => [600, 500],
		-pushstyle   => WS_CLIPCHILDREN,
		-onResize    => sub { $_[0]->TEXT->Resize($_[0]->ScaleWidth(), $_[0]->ScaleHeight); 1; },
		-onTerminate => sub { undef $win; 1; },  # Closure prevents $win going out of scope
		                                         # at end of showHelp().  Ref count to $win forced
                                                 # to zero on Terminate event.
		-dialogui    => 1,
	);

	# Hidden button that handles ESC char.
	# Might be better to use an accelerator table
	# but this is nice and quick
	$win->AddButton(
		-visible => 0,
		-cancel  => 1,
		-onClick => sub { undef $win; 1; },     # See comments above
	);

	$win->AddRichEdit(
		-name        => "TEXT",
		-readonly    => 1,
		-background  => 0xFFFFFF,
		-width       => $win->ScaleWidth(),
		-height      => $win->ScaleHeight(),
		-vscroll     => 1,
		-autohscroll => 0,
	);

	$win->TEXT->Text(get_help_text());
	$win->Show();

	return;
}

sub get_help_text
{
	my $parser;

	eval "require Pod::Simple::RTF";
	if($@) {
		eval "require Pod::Simple::Text";
		if($@) {
			return "Pod::Simple required to get help.\r\n".
                   "Try: 'perldoc win32-gui-demos' from the command line";
		}
		else {
			$parser = Pod::Simple::Text->new();
		}
	}
	else {
		$parser = Pod::Simple::RTF->new();
	}

	my $string;
	$parser->output_string(\$string);
	$parser->parse_file($0);

	return $string;
}

######################################################################
# About menu item.
######################################################################
sub showAboutBox {
    my $win = shift;

    my $ab = Win32::GUI::Window->new(
        -parent      => $win,
        -title       => "About ...",
        -size        => [220,180],
        -maximizebox => 0,
        -minimizebox => 0,
        -resizable   => 0,
        -dialogui    => 1,
    );

    my $text = "$progname v$VERSION\r\n";
    $text   .= "Using Win32::GUI v$Win32::GUI::VERSION";

    my $text2 = "$copyright This software is released under "
              . "the same terms as Perl itself.";

    $ab->AddLabel(
        -align  => 'center',
        -pos    => [10,10],
        -width  => $ab->Width()-20,
        -height => 50,
        -text   => $text,
    );
    $ab->AddLabel(
        -pos    => [10,60],
        -width  => $ab->Width()-20,
        -height => 100,
        -text   => $text2,
    );
    $ab->AddButton(
        -text    => 'Ok',
        -size    => [60,25],
        -left    => $ab->ScaleWidth()-70,
        -top     => $ab->ScaleHeight()-35,
        -cancel  => 1,
        -default => 1,
        -onClick => sub {-1},
		-tabstop => 1,
    );

    $ab->Center($win);
    $ab->DoModal();
    return 1;
}

######################################################################
# Options Dialog
######################################################################
sub getOptions {
    my $win = shift;
    my $ok = 0;

    my $ab = Win32::GUI::Window->new(
        -parent      => $win,
        -title       => "$progname Options",
        -size        => [400,120],
        -maximizebox => 0,
        -minimizebox => 0,
        -resizable   => 0,
        -dialogui    => 1,
    );

    $ab->AddTextfield(
        -name    => 'demo_dir',
        -pos     => [10,10],
        -prompt  => ["&Demo directory :",100],
        -text    => $options->{demo_dir},
        -width   => $ab->ScaleWidth()-150,
        -height  => 20,
        -tabstop => 1,
    );

    $ab->AddButton(
        -text => '...',
        -top => 11,
        -height => 18,
        -left => $ab->ScaleWidth()-38,
        -onClick => sub { $ab->demo_dir->Text(getDemoDir($ab)); 1;},
        -tabstop => 1,
    );

    $ab->AddButton(
        -text    => 'Ok',
        -size    => [60,25],
        -left    => $ab->ScaleWidth()-140,
        -top     => $ab->ScaleHeight()-35,
        -ok      => 1,
        -default => 1,
        -onClick => sub { $ok = 1; -1},
        -tabstop => 1,
    );

    $ab->AddButton(
        -text    => 'Cancel',
        -size    => [60,25],
        -left    => $ab->ScaleWidth()-70,
        -top     => $ab->ScaleHeight()-35,
        -cancel  => 1,
        -onClick => sub {-1},
        -tabstop => 1,
    );

    $ab->Center($win);
    $ab->DoModal();

    # update options from dialog - but only if ok pressed
    if($ok) {
        if($options->{demo_dir} ne $ab->demo_dir->Text()) {
            $options->{demo_dir} = $ab->demo_dir->Text();
            load_treeview($win->TV); #only if directory changed
        }
    }
    return 1;
}

######################################################################
# Show this program's source
######################################################################
sub showMySource {
    my $win = shift;

    $win->TV->Select(0); # unselect any tree view node
    $options->{current} = $0; # Set the current file
    $win->RE->SetReadOnly(0);
    $win->RE->LoadFile($options->{current}); # and load it
    $win->RE->SetReadOnly(1);
    $win->SB->Text($options->{current});
    $win->BUT->Disable();  # Don't let us run another instance
    return 1;
}

######################################################################
# Get a directory that contains demonstrations
######################################################################
sub getDemoDir {
    my $p = shift;

    # browse for folder doesn't like unix style paths ...
    my $curdir = $options->{demo_dir};
    $curdir =~ s/\//\\/g;

    my $dir = Win32::GUI::BrowseForFolder(
        -owner => $p,
        -title => 'Select Win32::GUI demos directory',
        -folderonly => 1,
        -directory => $curdir,
    );

    # and back to Unix path seperators again
    $dir =~ s/\\/\//g if $dir;

    return $dir ? $dir : $options->{demo_dir};
}

######################################################################
# Helper: load treeview with nodes representing the directories
# and files
######################################################################
my %demos;
sub load_treeview {
    my $tv = shift;

    $tv->DeleteAllItems();
    %nodes = ();

    # Fix demo dir to be unix directory seperators
    $options->{demo_dir} =~ s/\\/\//g;

    File::Find::find(\&wanted, $options->{demo_dir});

    sub wanted {
        my $dir = $File::Find::dir;
        $dir =~ s/^$options->{demo_dir}//;
        $dir =~ s/^\///;
        $dir = '/' unless $dir;

        my $file = $_;
        return if $file =~ /^\.$/;
        return if -d $file;
        return unless $file =~ /\.pl$/;

        if (!exists($demos{$dir})) {
            $demos{$dir} = [];
        }

        push @{$demos{$dir}}, { name => $file, fullpath => "$File::Find::dir/$file"};
    }

    #insert the nodes
    for my $dir (sort keys %demos) {
        my $dnode = $tv->InsertItem(
            -text   => ($dir eq '/' ? "Misc" : $dir),
        );
        for my $file (@{$demos{$dir}}) {
            my $cnode = $tv->InsertItem(
                -parent => $dnode,
                -text   => $file->{name},
            );
            $nodes{$cnode} = $file->{fullpath};
            if($options->{current} and $options->{current} eq $nodes{$cnode}) {
                $tv->Select($cnode);
            }
        }
    }
    undef %demos; # release memory

    return;
}

######################################################################
# Global configuration
######################################################################
package MyConfig;

######################################################################
# Load configuration
# - populate hash with configuration values
######################################################################

sub load_config {
    my %config;

    _load_config_from_registry(\%config);
    _load_config_from_file(\%config);

    #defaults, if not provided
    $config{current}      = undef
        unless exists $config{current};
    $config{demo_dir}     = File::Basename::dirname($INC{"Win32/GUI.pm"}) ."/GUI/demos"
        unless exists $config{demo_dir};
    $config{perl}         = _get_perl_exe()
        unless exists $config{perl};
    $config{wperl}        = _get_wperl_exe($config{perl})
        unless exists $config{wperl};

    return \%config;
}

######################################################################
# Load configuration from registry
# - populate hash with configuration values
# - for now a stub
######################################################################

sub _load_config_from_registry {
    return;
}

######################################################################
# Load configuration from file
# - populate hash with configuration values
# - for now a stub
######################################################################

sub _load_config_from_file {
    return;
}

######################################################################
# Find a perl executable, suitable for using to launch the scripts
######################################################################

sub _get_perl_exe {

    # taken from perlvar ($^X).  Should we just use $^X?
    my $perl = $Config::Config{perlpath};
    if ($^O ne 'VMS') {
        $perl .= $Config::Config{_exe}
            unless $perl =~ m/$Config::Config{_exe}$/i;
    }

    return $perl;
}

######################################################################
# Find a perl executable, suitable for using to launch the scripts
# without a console.  In ActiveSate perl we know there'll be wperl.exe
# in the same location as perl.exe (for a standard distribution)
######################################################################

sub _get_wperl_exe {
    my $perl = shift;

    my $wperl = $perl;
    if($wperl =~ s/(perl$Config::Config{_exe})$/w$1/i) {
        return $wperl;
    }
    else {
        return undef;
    }
}
__END__

=head1 NAME

win32-gui-demos - Perl Win32::GUI Demo Launcher application

=head1 SYNOPSIS

C<< C:\> win32-gui-demos >>

=head1 OVERVIEW

See a list of all the demo scripts distributed with the
Win32::GUI package, view their source code, and run
them.

=head1 USING

=head2 List of demos

After starting this application you should see all the
sample code distributed with Win32::GUI and its related
modules in the treeview to the left.  The demos are
grouped by the module they relate to.  Generic
samples are listed under the 'Misc' heading.

=head2 Viewing sample code

Select a demo file name in the left treeview
to see it's source-code in the right pane.

=head2 Running the demos

With code loaded in the right pane, click the
'Run demo' button, or double-click the demo file name
in the left treeview to run the sample itself.

The sample will start, with its own console
window, so that you can see any output it may generate
there.

This behaviour will hopefully changed in the future, to
remove the console window when it is not used.

=head2 Options

If there are no samples shown in the left treeview, then
the options dialog will show you where this application
is looking for them.  It tries to determine this
automatically, by looking at where Win32::GUI is
installed.  If you have performed a non-standard install
you may need to edit this value.

=head2 Other features

To see the source of this program itself, choose the
'Source' item from the File menu.

=head1 AUTHOR

Robert May (robertemay@users.sourceforge.net)

=head1 COPYRIGHT and LICENCE

Copyright Robert May, 2006.

This software is released under the same terms as Perl
itself.

=cut
