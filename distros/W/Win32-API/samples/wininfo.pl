use strict;
use Win32::API;

my $VERSION = "1.01";

my %output;

foreach ("handles", "titles", "classes", "sizes", "styles") {
    $output{$_} = 1;
}

my $arg;
foreach $arg (@ARGV) {
    help(), exit() if $arg =~ m|^[-/]h$|i;
    if ($arg =~ m|^[-/]o:(.*)$|i) {
        my $output = $1;
        foreach ("handles", "titles", "classes", "sizes", "styles") {
            $output{$_} = 0;
        }
        $output{"handles"} = 1 if $output =~ m|h|i;
        $output{"titles"}  = 1 if $output =~ m|t|i;
        $output{"classes"} = 1 if $output =~ m|c|i;
        $output{"sizes"}   = 1 if $output =~ m|s|i;
        $output{"styles"}  = 1 if $output =~ m|y|i;
    }
    if ($arg =~ m|^[-/]r|i) {
        $output{"childs"} = 1;
    }
    if ($arg =~ m|^[-/]x|i) {
        $output{"hex"} = 1;
    }
}

my $GetCursorPos = new Win32::API("user32", "GetCursorPos", ['P'], 'N');
my $WindowFromPoint = new Win32::API("user32", "WindowFromPoint", ['N', 'N'], 'N');
my $GetWindow       = new Win32::API("user32", "GetWindow",       ['N', 'N'], 'N');
my $GetClassName = new Win32::API("user32", "GetClassName", ['N', 'P', 'N'], 'N');
my $GetWindowLong = new Win32::API("user32", "GetWindowLong", ['N', 'N'], 'N');
my $GetWindowText = new Win32::API("user32", "GetWindowText", ['N', 'P', 'N'], 'N');
my $GetWindowRect = new Win32::API("user32", "GetWindowRect", ['N', 'P'], 'N');

print STDERR "Type '$0 -h' for help.\n";
print STDERR "Move the mouse over a window and press ENTER:";

my $enter = <STDIN>;
print "\n";

my ($x, $y) = GetCursorPos();
print "Window at ($x, $y):\n";
my $HWND = WindowFromPoint($x, $y);

my $ParentHWND = $GetWindowLong->Call($HWND, -8);
while ($ParentHWND != 0) {
    $HWND = $ParentHWND;
    $ParentHWND = $GetWindowLong->Call($HWND, -8);
}
OutputWinInfo($HWND, 0);

if ($output{"childs"}) {
    FindChilds(\$HWND, $HWND);
}

#=================
sub GetClassName {

#=================
    my ($hwnd)  = @_;
    my $name    = " " x 1024;
    my $nameLen = 1024;
    my $result = $GetClassName->Call($hwnd, $name, $nameLen);
    if ($result) {
        return substr($name, 0, $result);
    }
    else {
        return "";
    }
}

#=================
sub GetCursorPos {

#=================
    my $POINT = pack("LL", 0, 0);
    $GetCursorPos->Call($POINT);
    return wantarray ? unpack("LL", $POINT) : $POINT;
}

#====================
sub WindowFromPoint {

#====================
    my ($x, $y) = @_;
    my $POINT = pack("LL", $x, $y);
    return $WindowFromPoint->Call($x, $y);
}

#==================
sub GetWindowText {

#==================
    my ($hwnd)   = @_;
    my $title    = " " x 1024;
    my $titleLen = 1024;
    my $result = $GetWindowText->Call($hwnd, $title, $titleLen);
    if ($result) {
        return substr($title, 0, $result);
    }
    else {
        return "";
    }
}

#==================
sub GetWindowRect {

#==================
    my ($hwnd) = @_;
    my $RECT = pack("iiii", 0, 0);
    $GetWindowRect->Call($hwnd, $RECT);
    return wantarray ? unpack("iiii", $RECT) : $RECT;
}

#==================
sub OutputWinInfo {

#==================
    my ($HWND, $level) = @_;

#    print "OutputWinInfo.level = $level\n";
    print "\t" x $level;
    if ($output{"handles"}) {
        if ($output{"hex"}) {
            printf("(%x) ", $HWND);
        }
        else {
            print "($HWND) ";
        }
    }
    if ($output{"titles"}) {
        my $title = GetWindowText($HWND);
        print " \"$title\"" if $title;
    }
    print "\n";
    if ($output{"classes"}) {
        my $class = GetClassName($HWND);
        print "\t" x $level;
        print "\tClass: $class\n" if $class;
    }
    if ($output{"sizes"}) {
        my ($left, $top, $right, $bottom) = GetWindowRect($HWND);
        print "\t" x $level;
        print "\tPosition: ($left, $top)\n";
        my $width  = $right - $left;
        my $height = $bottom - $top;
        print "\t" x $level;
        print "\tSize: ($width x $height)\n";
    }
    if ($output{"styles"}) {
        my $style = $GetWindowLong->Call($HWND, -16);
        print "\t" x $level;
        printf("\tStyle: %X\n", $style);
        my $exstyle = $GetWindowLong->Call($HWND, -20);
        print "\t" x $level;
        printf("\tExtended Style: %X\n", $exstyle);
    }
}

#===============
sub FindChilds {

#===============
    my ($parent, $hwnd, $level) = @_;
    my $Child;
    my $NextChild;
    my $left;
    my $right;
    my $top;
    my $bottom;
    my $height;
    my $width;
    my $class;
    my $text;
    my $style;
    my $args;
    my $child;
    my $header;

    $Child = $GetWindow->Call($hwnd, 5);
    $level++;
    $header = "\t" x $level . "Child windows:\n";
    while ($Child != 0) {
        if ($header) {
            print $header;
            undef $header;
        }
        OutputWinInfo($Child, $level);
        FindChilds(\$child, $Child, $level);
        $NextChild = $GetWindow->Call($Child, 2);
        $Child = $NextChild;
    }
}


#=========
sub help {

#=========
    print <<END_OF_HELP;

WinInfo version $VERSION
by Aldo Calpini <dada\@perl.it>

Usage: perl $0 [options]

Options:
    -o:[flags]: output the following informations:
        h: window handles
        t: window titles
        c: window classes
        s: window sizes
        y: window styles
        Default is '-o:htcsy' (all of them)

    -r: recurse child windows       

    -x: show handles in hexadecimal format

END_OF_HELP
}
