use 5.014;
use warnings;

use Test::More tests => 43;

BEGIN {
  use_ok 'Win32';
  use_ok 'Win32::Console';
}

#-----------------
note 'public API';
#-----------------
can_ok('Win32::Console', 'Alloc');
can_ok('Win32::Console', 'Free');
can_ok('Win32', 'GetConsoleCP');
can_ok('Win32', 'GetConsoleOutputCP');
can_ok('Win32', 'SetConsoleCP');
can_ok('Win32', 'SetConsoleOutputCP');

#-----------------
note 'private API';
#-----------------
can_ok('Win32::Console', '_CloseHandle');
can_ok('Win32::Console', '_CreateConsoleScreenBuffer');
can_ok('Win32::Console', '_FillConsoleOutputAttribute');
can_ok('Win32::Console', '_FillConsoleOutputCharacter');
can_ok('Win32::Console', '_FlushConsoleInputBuffer');
can_ok('Win32::Console', '_GenerateConsoleCtrlEvent');
can_ok('Win32::Console', '_GetConsoleCursorInfo');
can_ok('Win32::Console', '_GetConsoleMode');
can_ok('Win32::Console', '_GetConsoleScreenBufferInfo');
can_ok('Win32::Console', '_GetConsoleTitle');
can_ok('Win32::Console', '_GetLargestConsoleWindowSize');
can_ok('Win32::Console', '_GetNumberOfConsoleInputEvents');
can_ok('Win32::Console', '_GetStdHandle');
can_ok('Win32::Console', '_PeekConsoleInput');
can_ok('Win32::Console', '_ReadConsole');
can_ok('Win32::Console', '_ReadConsoleInput');
can_ok('Win32::Console', '_ReadConsoleOutput');
can_ok('Win32::Console', '_ReadConsoleOutputAttribute');
can_ok('Win32::Console', '_ReadConsoleOutputCharacter');
can_ok('Win32::Console', '_ScrollConsoleScreenBuffer');
can_ok('Win32::Console', '_SetConsoleActiveScreenBuffer');
can_ok('Win32::Console', '_SetConsoleCursorInfo');
can_ok('Win32::Console', '_SetConsoleCursorPosition');
can_ok('Win32::Console', '_SetConsoleIcon');
can_ok('Win32::Console', '_SetConsoleMode');
can_ok('Win32::Console', '_SetConsoleScreenBufferSize');
can_ok('Win32::Console', '_SetConsoleTextAttribute');
can_ok('Win32::Console', '_SetConsoleTitle');
can_ok('Win32::Console', '_SetConsoleWindowInfo');
can_ok('Win32::Console', '_SetStdHandle');
can_ok('Win32::Console', '_WriteConsole');
can_ok('Win32::Console', '_WriteConsoleInput');
can_ok('Win32::Console', '_WriteConsoleOutput');
can_ok('Win32::Console', '_WriteConsoleOutputAttribute');
can_ok('Win32::Console', '_WriteConsoleOutputCharacter');

done_testing();
