use 5.014;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'ConsoleColor';
}

lives_ok {
  no warnings 'void';
  ConsoleColor::elements();
  ConsoleColor->elements();
  (ConsoleColor->elements)[0]; 
} 'elements';

lives_ok {
  no warnings 'void';
  ConsoleColor::values();
  ConsoleColor->values();
  (ConsoleColor->values)[0]; 
} 'values';

lives_ok {
  no warnings 'void';
  ConsoleColor::count();
  ConsoleColor->count();
} 'count';

lives_ok {
  no warnings 'void';
  ConsoleColor::get(0);
  ConsoleColor->get(0);
} 'get';

is_deeply (
  [ConsoleColor->values], 
  [0..15], 
  'deeply'
);

is  ( ConsoleColor->Blue, 9, 'Blue'             );
is  ( ConsoleColor->count, 16, 'count'          );
like( ConsoleColor->get(0), qr/Black/, 'first'  );
like( ConsoleColor->get(-1), qr/White/, 'last'  );

done_testing;
