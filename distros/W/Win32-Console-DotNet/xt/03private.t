use 5.014;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  unless ( $^O eq 'MSWin32' ) {
    plan skip_all => 'This is not MSWin32';
  }
  else {
    plan tests => 2;
  }
}

BEGIN {
  use_ok 'Win32::Console::DotNet';
}

throws_ok(
  sub { System::Console->ColorAttributeToConsoleColor(0) },
  qr/Can't|Undefined/i,
  'Exception when calling a private subroutine'
);

done_testing;
