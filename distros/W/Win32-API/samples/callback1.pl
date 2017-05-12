$| = 1;

use blib;
use Win32::API;
use Win32::API::Callback;

my $Callback = Win32::API::Callback->new(
    sub {
        my ($hwnd, $lparam) = @_;
        printf "EnumWindows callback got: HWND=0x%08x LPARAM=%d\n", $hwnd, $lparam;
        return 1;
    },
    "NN",
    "N"
);

$EnumWindows = new Win32::API("user32", "EnumWindows", "KN", "N");

$EnumWindows->Call($Callback, 42);

