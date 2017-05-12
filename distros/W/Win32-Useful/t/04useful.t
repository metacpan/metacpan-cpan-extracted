use Test::More tests => 3;

use_ok('Win32::Useful');

Win32::SetLastError(0);
ok(Win32::Useful::IsLastError(0x0), 'Win32::Useful::IsLastError(0x0)');

Win32::SetLastError(-2146885628);
ok(Win32::Useful::IsLastError(0x80092004), 'Win32::Useful::IsLastError(0x80092004)');