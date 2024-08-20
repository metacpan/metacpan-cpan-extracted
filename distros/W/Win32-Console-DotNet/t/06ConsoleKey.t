use 5.014;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'ConsoleKey';
}

#-----------------
note 'Subroutines';
#-----------------

lives_ok {
  no warnings 'void';
  ConsoleKey::elements();
  ConsoleKey->elements();
  (ConsoleKey->elements)[0]; 
} 'elements';

lives_ok {
  no warnings 'void';
  ConsoleKey::values();
  ConsoleKey->values();
  (ConsoleKey->values)[0]; 
} 'values';

lives_ok {
  no warnings 'void';
  ConsoleKey::count();
  ConsoleKey->count();
} 'count';

lives_ok {
  no warnings 'void';
  ConsoleKey::get(0);
  ConsoleKey->get(0);
} 'get';

is_deeply (
  [ (ConsoleKey->values)[0..2] ],
  [0,8,9],
  'deeply'
);

is  ( ConsoleKey->Tab, 9, 'Tab'                 );
is  ( ConsoleKey->count, 145, 'count'           );
like( ConsoleKey->get(0), qr/None/, 'first'     );
like( ConsoleKey->get(-1), qr/OemClear/, 'last' );

done_testing;
