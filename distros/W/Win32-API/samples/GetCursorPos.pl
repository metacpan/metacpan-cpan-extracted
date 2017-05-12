
use Win32::API;

Win32::API::Struct->typedef(
    POINT => qw(
        LONG x;
        LONG y;
        )
);

Win32::API->Import('user32' => 'BOOL GetCursorPos(LPPOINT pt)');

#### using OO semantics
my $pt = Win32::API::Struct->new('POINT');
GetCursorPos($pt) or die "GetCursorPos failed: $^E";
print "Cursor is at: $pt->{x}, $pt->{y}\n";

#### using tie semantics
my %pt;
tie %pt, Win32::API::Struct => 'POINT';
GetCursorPos(\%pt) or die "GetCursorPos failed: $^E";
print "Cursor is at: $pt{x}, $pt{y}\n";
