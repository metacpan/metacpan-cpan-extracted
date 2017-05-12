#perl -w
use strict;
use Win32::API;

my %colordesc = (
    0  => "Scrollbars",
    1  => "Background",
    2  => "Active Caption",
    3  => "Inactive Caption",
    4  => "Menu",
    5  => "Window",
    6  => "Window Frame",
    7  => "Menu Text",
    8  => "Window Text",
    9  => "Caption Text",
    10 => "Active Border",
    11 => "Inactive Border",
    12 => "Application Workspace",
    13 => "Highlight",
    14 => "Highlight Text",
    15 => "Button Face",
    16 => "Button Shadow",
    17 => "Gray Text",
    18 => "Button Text",
    19 => "Inactive Caption Text",
    20 => "Button Highlight",
    21 => "3D Objects Shadow",
    22 => "3D Objects Highlight",
    23 => "Tooltip Text",
    24 => "Tooltip Background",
    26 => "Hot-track Highlight",
    27 => "Active Caption Gradient",
    28 => "Inactive Caption Gradient",
);


my $GSC = new Win32::API("user32", "GetSysColor", ['N'], 'N',);

my $SSC = new Win32::API("user32", "SetSysColors", ['N', 'P', 'P'], 'N',);

my ($i, $r, $g, $b, $w, $c);
my @c;
my @oc;
for $i (0 .. 28) {
    next if $i == 25;
    push(@oc, $GSC->Call($i));
}

srand();
for $i (0 .. 28) {
    next if $i == 25;
    $r = int(rand() * 255);
    $g = int(rand() * 255);
    $b = int(rand() * 255);
    push(@c, $r + $g * 255 + $b * (255**2));

    # ffff'));
}
$w = pack("I" x 28, (0 .. 24), (26 .. 28));
$c = pack("I" x 28, @c);
$SSC->Call(28, $w, $c);

for $i (0 .. 28) {
    next if $i == 25;
    PrintColor($i);
}

print "\nPress ENTER to restore original colors:";
my $enter = <STDIN>;

$w = pack("I" x 28, (0 .. 24), (26 .. 28));
$c = pack("I" x 28, @oc);
$SSC->Call(28, $w, $c);

sub PrintColor {
    my ($index) = @_;
    print "$colordesc{$index}: ";
    my $C = $GSC->Call($index);
    my $R = $C & 0x0000FF;
    my $G = ($C & 0x00FF00) >> 8;
    my $B = ($C & 0xFF0000) >> 16;
    printf("%d, %d, %d\n", $R, $G, $B);
}

