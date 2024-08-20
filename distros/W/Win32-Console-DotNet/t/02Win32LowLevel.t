use 5.014;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 9;
  }
}

BEGIN {
  use_ok 'Win32API::File';
  use_ok 'Win32::Console::DotNet';
  use_ok 'Win32Native';
};

#----------------
note 'Constants';
#----------------

is(
  Win32Native::ERROR_INVALID_HANDLE,
  0x6,
  'ERROR_INVALID_HANDLE'
);

is(
  Win32Native::KEY_EVENT,
  0x0001,
  'KEY_EVENT'
);

#----------------
note 'API calls';
#----------------

lives_ok(
  sub {
    Win32Native::Beep(800, 200);
  },
  'Beep(800, 200)'
);

lives_ok(
  sub {
    my $h = Win32API::File::FdGetOsFHandle(fileno(\*STDERR)) // -1;
    Win32Native::WriteFile($h, 'A', 0, local $_, undef) || die;
  },
  'WriteFile'
);

lives_ok(
  sub {
    my $lock = Win32Native::GetKeyState(0x14) & 1;
    note sprintf("CapsLock: %s", $lock ? 'enabled' : 'disabled');
  },
  'GetKeyState(VK_CAPITAL)'
);

lives_ok(
  sub {
    my $lock = Win32Native::GetKeyState(0x90) & 1;
    note sprintf("NumberLock: %s", $lock ? 'enabled' : 'disabled');
  },
  'GetKeyState(VK_NUMLOCK)'
);

done_testing;
