# chres.pl - change the resolution of the screen
#
# This script was written by Aldo Calpini (dada@perl.it) in 2001.
# It is released into the public domain.  You may use it freely, however,
# if you make any modifications and redistribute, please list your name
# and describe the changes. This script is distributed without any warranty,
# express or implied.

use Win32::API 0.20;
use Getopt::Mixed;

my $VERSION = '0.51';

# the required APIs
my $EnumDisplaySettings = new Win32::API("user32", "EnumDisplaySettings", "PNP", "N");
my $ChangeDisplaySettings = new Win32::API("user32", "ChangeDisplaySettings", "PN", "N");
my $CreateDC      = new Win32::API("gdi32", "CreateDC",      "PPPP", "N");
my $GetDeviceCaps = new Win32::API("gdi32", "GetDeviceCaps", "NN",   "N");
my $DeleteDC      = new Win32::API("gdi32", "DeleteDC",      "N",    "V");

# process command line options
Getopt::Mixed::getOptions qw(
    help h>help ?>help
    quiet q>quiet
    test t>test
    list l>list
    info i>info
    permanent p>permanent
    global g>global
    reset r>reset
    x=i
    y=i
    colordepth=s c>colordepth
    frequency=i f>frequency
);

# beautify list for BPPs
my %colors = (
    4  => "16 Colors",
    8  => "256 Colors",
    16 => "High Color",
    24 => "True Color",
    32 => "True Color",
);

$opt_colordepth = color2bpp($opt_colordepth) if $opt_colordepth;

# process non-options on command line
$doing = "x";
while (@ARGV) {
    $argv = shift @ARGV;
    if ($doing eq "x") {
        if ($argv =~ /(\d+)x(\d+)/i) {
            $opt_x = $1;
            $opt_y = $2;
            $doing = "colordepth";
        }
        else {
            $opt_x = $argv;
            $doing = "y";
        }
    }
    elsif ($doing eq "y") {
        $opt_y = $argv;
        $doing = "colordepth";
    }
    elsif ($doing eq "colordepth") {
        $opt_colordepth = color2bpp($argv);
        $doing          = "frequency";
    }
    elsif ($doing eq "frequency") {
        $opt_frequency = $argv;
        $doing         = "skip";
    }
}

if ($opt_test) {
    $flag = 0x02;
}
elsif ($opt_permanent) {
    $flag = 0x01;
}
elsif ($opt_global) {
    $flag = 0x08;
}
else {
    $flag = 0;
}

if ($opt_help) {
    display_help();
    exit();
}

if ($opt_reset) {
    $res = $ChangeDisplaySettings->Call(0, 0);
    print "Default mode restored.\n" unless $opt_quiet;
    exit($res);
}

if ($opt_info) {
    ($X, $Y, $BPP, $HZ) = getres();
    printf "%dx%d %s (%d Bit) %dHz\n", $X, $Y, $colors{$BPP}, $BPP, $HZ unless $opt_quiet;
    exit();
}

if ($opt_list) {
    exit(list_modes($opt_x, $opt_y, $opt_colordepth, $opt_frequency));
}

if (    not defined $opt_x
    and not defined $opt_y
    and not defined $opt_colordepth
    and not defined $opt_frequency)
{
    if (not $opt_quiet) {
        print "Nothing to do.\n";
        print "Type $0 --help for more information.\n";
    }
    exit();
}

$res = chres($opt_x, $opt_y, $opt_colordepth, $opt_frequency, $flag);

unless ($opt_quiet) {
    if ($res == 0) {
        if   ($opt_test) { print "Test successful.\n"; }
        else             { print "Mode changed.\n"; }
    }
    if ($res == 1) { print "The computer must be restarted.\n"; }
    if ($res == -1) {
        print "The display driver failed the specified graphics mode.\n";
    }
    if ($res == -2) { print "The graphics mode is not supported.\n"; }
    if ($res == -3) { print "Unable to write settings to the registry.\n"; }
    if ($res == -4) { print "Invalid parameters.\n"; }
    if ($res == -5) { print "Invalid parameters.\n"; }
}
exit($res);

sub chres {
    my ($wanted_X, $wanted_Y, $wanted_BPP, $wanted_HZ, $flags) = @_;

    $flags = 0 unless defined $flags;

    my ($actual_X, $actual_Y, $actual_BPP, $actual_HZ) = @_;
    if (   not defined $wanted_X
        or not defined $wanted_X
        or not defined $wanted_BPP
        or not defined $wanted_HZ)
    {
        ($actual_X, $actual_Y, $actual_BPP, $actual_HZ) = getres();
    }

    my $wanted;
    $wanted = ((defined $wanted_X) ? $wanted_X : $actual_X);
    $wanted .= "," . ((defined $wanted_Y)   ? $wanted_Y   : $actual_Y);
    $wanted .= "," . ((defined $wanted_BPP) ? $wanted_BPP : $actual_BPP);
    $wanted .= "," . ((defined $wanted_HZ)  ? $wanted_HZ  : $actual_HZ);

    my $devmode = init_devmode();
    my $newmode = undef;
    my $i       = 0;
    my $res     = $EnumDisplaySettings->Call(0, $i, $devmode);
    while ($res != 0) {
        ($BPP, $X, $Y, undef, $HZ) = unpack("x104 LLLLL", $devmode);
        $mode = "$X,$Y,$BPP,$HZ";
        if ($mode eq $wanted) {
            $newmode = $devmode;
            last;
        }
        $res = $EnumDisplaySettings->Call(0, ++$i, $devmode);
    }

    if (defined $newmode) {
        $res = $ChangeDisplaySettings->Call($newmode, $flags);
    }
    else {
        $res = -2;
    }
    return $res;
}

sub getres {
    my $hdc = $CreateDC->Call("DISPLAY", 0, 0, 0);
    if (!$hdc) {
        return undef;
    }
    my $HORZRES   = 8;
    my $VERTRES   = 10;
    my $BITSPIXEL = 12;
    my $VREFRESH  = 116;

    my $X   = $GetDeviceCaps->Call($hdc, $HORZRES);
    my $Y   = $GetDeviceCaps->Call($hdc, $VERTRES);
    my $BPP = $GetDeviceCaps->Call($hdc, $BITSPIXEL);
    my $HZ  = $GetDeviceCaps->Call($hdc, $VREFRESH);

    $DeleteDC->Call($hdc);
    return ($X, $Y, $BPP, $HZ);
}

sub list_modes {
    my ($wanted_X, $wanted_Y, $wanted_BPP, $wanted_HZ) = @_;

    my $modes   = 0;
    my $devmode = init_devmode();
    my $i       = 0;
    my $res     = $EnumDisplaySettings->Call(0, $i, $devmode);
    while ($res != 0) {
        ($BPP, $X, $Y, undef, $HZ) = unpack("x104 LLLLL", $devmode);

        if (    (not defined $wanted_X or $wanted_X == $X)
            and (not defined $wanted_Y   or $wanted_Y == $Y)
            and (not defined $wanted_BPP or $wanted_BPP == $BPP)
            and (not defined $wanted_HZ  or $wanted_HZ == $HZ))
        {
            printf "%dx%d %s (%d Bit) %dHz\n", $X, $Y, $colors{$BPP}, $BPP, $HZ
                unless $opt_quiet;
            $modes++;
        }
        $res = $EnumDisplaySettings->Call(0, ++$i, $devmode);
    }
    print "No matching graphics modes.\n" if not $opt_quiet and $modes == 0;
    return $modes;
}

sub init_devmode {
    return pack(
        "B" x 32 . "SSSSLsssssssssssss" . "B" x 32 . "SLLLLL",
        (0 x 32),    # dmDeviceName
        0,           # dmSpecVersion
        0,           # dmDriverVersion
        124,         # dmSize
        0,           # dmDriverExtra
        0,           # dmFields
        0,           # dmOrientation
        0,           # dmPaperSize
        0,           # dmPaperLength
        0,           # dmPaperWidth
        0,           # dmScale
        0,           # dmCopies
        0,           # dmDefaultSource
        0,           # dmPrintQuality
        0,           # dmColor
        0,           # dmDuplex
        0,           # dmYResolution
        0,           # dmTTOption
        0,           # dmCollate
        (0 x 32),    # dmFormName
        0,           # dmLogPixels
        0,           # dmBitsPerPel
        0,           # dmPelsWidth
        0,           # dmPelsHeight
        0,           # dmDisplayFlags
        0,           # dmDisplayFrequency
    );
}

sub color2bpp {
    my ($arg) = shift;
    $arg = lc $arg;
    my %table = (
        1     => 1,
        2     => 2,
        16    => 4,
        256   => 8,
        65000 => 16,
        '64k' => 16,
        '65k' => 16,
        high  => 16,
        '16m' => 24,
        true  => 32,
    );
    if ($arg =~ /^(\d+)b$/) {
        return $1;
    }
    elsif (exists $table{$arg}) {
        return $table{$arg};
    }
}

sub display_help {

    print qq(
$0 version $VERSION, (c) 2001 Aldo Calpini <dada\@perl.it>

usage: $0 [OPTIONS] [NNNxNNN] [COLORS] [FREQ]

OPTIONS:
    --help              shows this help
    --x NNN             width, in pixels
    --y NNN             height, in pixels
    --colordepth COLORS color depth (see below)
    --frequency NNN     vertical refresh rate, in Hz (only WinNT/2000)
    --quiet             does not display information on STDOUT
    --reset             reset the screen to the default mode
    --info              isplay the current mode and exit
    --list              list the available modes. can be combined with
                        --x, --y, --colordepth and --frequency, for 
                        example: '--x 1024 --list' lists all the
                        modes with width of 1024 pixels
    --test              test the given mode without making changes
    --permanent         make change permanent (for the current user)
    --global            make change permanent and global (for all
                        users) (only WinNT/2000)

all options can be given in the short form too (eg. -t for --test,
-h for --help, -x for --x and so on).

COLORS:
    recognized values are:
        1, 2, 1b              >   2 colors (1 bpp)
        16, 4b                =>  16 colors (4 bpp)
        256, 8b               =>  256 colors (8 bpp)
        65000, 64k, high, 16b =>  65536 colors (16 bpp)
        16m, true, 32b        =>  16 millions colors (32 bpp)

the --x, --y, --colordepth and --frequency options can also be
given on command line without introduction, but in this case
order must be respected. for example, to change to a 800x600
screen resolution:
    $0 800x600
or  $0 800 600

to change to 800x600, 32bpp, 85Hz:
    $0 800 600 32 85
    
);
}

=head1 NAME

chres - CHange RESolution

=head1 DESCRIPTION

Change the resolution of the screen on a Windows machine.
Launch the script with the --help option for a detailed
description of the usage.

=head1 README

Change the resolution of the screen on a Windows machine.

=head1 PREREQUISITES

This script requires C<Win32::API 0.20> and C<Getopt::Mixed>.

=pod OSNAMES

MSWin32

=pod SCRIPT CATEGORIES

Win32
Win32/Utilities

=head1 AUTHOR

Aldo Calpini (dada@perl.it).

=cut
