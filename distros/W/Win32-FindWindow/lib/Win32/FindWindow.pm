package Win32::FindWindow;

use warnings;
use strict;
use utf8;
use Encode;
use Win32::API;
use Win32::API::Callback;

use base qw(Exporter Class::Accessor::Fast);
__PACKAGE__->mk_ro_accessors(qw(hwnd windowtext classname pid filename basename));

use constant PROCESS_VM_READ           => 0x0010;
use constant PROCESS_QUERY_INFORMATION => 0x0400;

our $VERSION = '0.03';

our @EXPORT = qw();
our @EXPORT_OK = qw(find_window find_windows);
our @ARGS_REGEXP = qw(windowtext classname filename basename);

our $ENCODING  = 'cp1252';
our $LENGTH_MAX = 1024;

our $args = {};
our @instances = ();

Win32::API->Import("user32",   "GetWindowThreadProcessId", "NP",   "N");
Win32::API->Import("user32",   "GetClassName",             "NPI",  "I");
Win32::API->Import("user32",   "GetWindowTextLength",      "N",    "I");
Win32::API->Import("user32",   "GetWindowText",            "NPI",  "I");
Win32::API->Import("kernel32", "OpenProcess",              "NIN",  "N");
Win32::API->Import("psapi",    "EnumProcessModules",       "NPNP", "I");
Win32::API->Import("kernel32", "CloseHandle",              "N",    "I");
Win32::API->Import("psapi",    "GetModuleFileNameEx",      "NNPN", "N");
Win32::API->Import("psapi",    "GetModuleBaseName",        "NNPN", "N");
Win32::API->Import("user32",   "GetDesktopWindow",         "",     "N");
Win32::API->Import("user32",   "EnumChildWindows",         "NKP",  "I");

sub _neg(@) { map { $_, "$_!" } @_ } ## no critic

our $EnumChildProc = Win32::API::Callback->new(sub {
    my %result = ();
    $result{hwnd} = shift;
    
    # GetWindowThreadProcessId()
    {
        my $ppid = "\x0" x Win32::API::Type->sizeof( 'LPDWORD' );
        GetWindowThreadProcessId($result{hwnd}, $ppid);
        $result{pid} = Win32::API::Type::Unpack('LPDWORD', $ppid);
    }
    
    if ($result{pid}) {
        # GetClassName()
        {
            my $size = Win32::API::Type->sizeof( 'CHAR*' ) * $LENGTH_MAX;
            my $pclassname = "\x0" x $size;
            GetClassName($result{hwnd}, $pclassname, $size);
            $result{classname} = Encode::decode($ENCODING, Win32::API::Type::Unpack('CHAR*', $pclassname));
        }
        
        # GetWindowText()
        {
            my $size = GetWindowTextLength($result{hwnd});
            if (Win32::API::IsUnicode()) { $size *= 2; }
            $size++;
            my $pwindowtext = "\x0" x $size;
            GetWindowText($result{hwnd}, $pwindowtext, $size);
            $result{windowtext} = Encode::decode($ENCODING, Win32::API::Type::Unpack('CHAR*', $pwindowtext));
        }
        
        my $hprocess;
           ($hprocess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, 0, $result{pid}))
        or ($hprocess = OpenProcess(PROCESS_QUERY_INFORMATION,                   0, $result{pid}));
        if ($hprocess > 0) {
            my $cb         = Win32::API::Type->sizeof( 'HMODULE' ) * $LENGTH_MAX;
            my $lphmodule  = "\x0" x $cb;
            my $lpcbneeded = "\x0" x $cb;
            if (EnumProcessModules($hprocess, $lphmodule, $cb, $lpcbneeded)) {
                my $hmodule = Win32::API::Type::Unpack('HMODULE', $lphmodule);
                
                # GetModuleFileNameEx()
                {
                    my $size = Win32::API::Type->sizeof( 'CHAR*' ) * $LENGTH_MAX;
                    my $lpfilenameex = "\x0" x $size;
                    GetModuleFileNameEx($hprocess, $hmodule, $lpfilenameex, $size);
                    $result{filename} = Encode::decode($ENCODING, Win32::API::Type::Unpack('CHAR*', $lpfilenameex));
                }
                
                # GetModuleBaseName()
                {
                    my $size = Win32::API::Type->sizeof( 'CHAR*' ) * $LENGTH_MAX;
                    my $lpbasename = "\x0" x $size;
                    GetModuleBaseName($hprocess, $hmodule, $lpbasename, $size);
                    $result{basename} = Encode::decode($ENCODING, Win32::API::Type::Unpack('CHAR*', $lpbasename));
                }
            }
            CloseHandle($hprocess);
        }
        
        my $found = 1;
        for my $_key (_neg @ARGS_REGEXP) {
            next unless defined($args->{$_key});
            my $neg = '';
            (my $key, $neg) = ($_key =~ /(\w+)(!)?$/);
            next unless defined($args->{$key});
            
            if ($neg) {
                $found = 0     if $result{$key} =~ $args->{$key};
            }
            else {
                $found = 0 unless $result{$key} =~ $args->{$key};
            }
        }
        
        if ($found) {
            push(@instances, __PACKAGE__->new(%result));
        }
    }
    1;
}, "NN", "I");

sub find_window {
    @instances = find_windows(@_);
    if (@instances > 1) { @instances = sort { $a->{pid} <=> $b->{pid} } @instances; }
    $instances[0];
}

sub find_windows {
    $args = {@_};
    
    $args->{hwnd} = (defined($args->{hwnd}) and ($args->{hwnd} =~ /^\d+$/))
                  ? $args->{hwnd}
                  : GetDesktopWindow();
    
    @instances = ();
    EnumChildWindows($args->{hwnd}, $EnumChildProc, 0);
    @instances;
}

sub new {
    my $class = shift;
    bless {@_}, $class;
}

1;
__END__

=encoding utf8

=head1 NAME

Win32::FindWindow - find windows on Win32 systems


=head1 SYNOPSIS

    use Win32::FindWindow qw/find_window find_windows/;
    
    $window = find_window();
    $window = find_window( classname  => 'ExploreWClass' );
    $window = find_window( basename   => qr/^Explorer.EXE$/
                         , filename   => qr/^C:\\WINDOWS\\.*/
                         , windowtext => qr/^C:\\$/
                         , classname  => qr/^ExploreWClass$/ );
    
    @windows = find_windows();
    @windows = find_windows( windowtext => qr/ - Microsoft Internet Explorer$/ );
    @windows = find_windows( basename   => 'mspaint.exe'
                           , filename   => 'C:\\WINDOWS\\system32\\mspaint.exe'
                           , windowtext => qr/^.+$/
                           , classname  => 'MSPaintApp' );
    
    $window->basename;
    $window->filename;
    $window->windowtext;
    $window->classname;
    $window->hwnd;
    $window->pid;

=head1 DESCRIPTION

This module provides routines for finding windows on Win32 systems.


=head1 FUNCTIONS

=over

=item find_window()

Returns C<Win32::FindWindow> objects by supplied search parameters.
The parameters are as follows:

    basename
    filename
    windowtext
    classname
    hwnd
    pid

C<SCALAR> or C<Regexp> value can be specified as search conditions for finding window.
Like this:

    $window = find_window( basename => 'wmplayer.exe' );
    $window = find_window( windowtext => qr/^Windows Media/ );

=item find_windows()

Same as C<find_window()> except it returns multiple objects as C<ARRAY>.

    @windows = find_windows( basename   => 'mspaint.exe'
                           , filename   => 'C:\\WINDOWS\\system32\\mspaint.exe'
                           , windowtext => qr/^.+$/
                           , classname  => 'MSPaintApp' );

=back

=head1 METHODS

    $window = find_window( ... );
    
    # accessors (read-only)
    $window->basename;
    $window->filename;
    $window->windowtext;
    $window->classname;
    $window->hwnd;
    $window->pid;

Accessor methods is being offered as shown in the above. These are read-only.

=head1 GLOBAL VARIABLES

=over

=item $ENCODING

    # how to use regexp with wide characters
    # e.g. pattern matching the character that starts by Japanese `スタート'
    use Win32::FindWindow qw/find_windows/;
    use utf8;
    use encoding 'utf8', STDOUT => 'cp932';
    $Win32::FindWindow::ENCODING = 'cp932';
    @windows = find_windows( classname  => 'Button'
                           , windowtext => qr/^スタート/ );

A string value that shows system encodings. Defaults to 'cp1252'.
Set your system's codepage string that module C<Encode> supported.
Because this module uses C<Encode::decode()> internally.

=item $LENGTH_MAX

A numerical value that shows length of temporary string buffer. Defaults to 1024.
This is used by C<GetClassName()>, C<EnumProcessModules()>, C<GetModuleFileNameEx()> and C<GetModuleBaseName()>.

=back

=head1 SEE ALSO

L<Win32::API>, L<Win32::API::Callback>, L<Class::Accessor::Fast>, L<Encode>,
How To Enumerate Windows Using the WIN32 API: L<http://support.microsoft.com/kb/183009>

=head1 AUTHOR

Michiya Honda  C<< <pia@cpan.org> >>


=head1 LICENCE

This library is free software, licensed under the same terms with Perl.
See L<perlartistic>.
