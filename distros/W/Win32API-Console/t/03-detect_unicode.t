use 5.014;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok 'Win32API::Console', qw( GetConsoleTitle );
}

# Mock implementations for A and W versions
{
  no warnings;
  *Win32API::Console::GetConsoleTitleA = sub { return 'MOCK-ANSI' };
  *Win32API::Console::GetConsoleTitleW = sub { return 'MOCK-WIDE' };
}

ok(defined &Win32API::Console::UNICODE, 'UNICODE constant is defined');

my $unicode = eval { Win32API::Console::UNICODE() };
if (!defined $unicode) {
  diag 'Unicode detection not clear (undefined)';
}
elsif ($unicode) {
  note 'Win32API::Console was compiled with UNICODE support.';
}
else {
  note 'Win32API::Console was compiled without UNICODE (ANSI mode).';
}

subtest 'Test goto behavior with mocked subs' => sub {
  if ($unicode) {
    is(GetConsoleTitle(), 'MOCK-WIDE', 'goto jumped to mocked Wide version');
  } 
  else {
    is(GetConsoleTitle(), 'MOCK-ANSI', 'goto jumped to mocked ANSI version');
  }
};

done_testing();
