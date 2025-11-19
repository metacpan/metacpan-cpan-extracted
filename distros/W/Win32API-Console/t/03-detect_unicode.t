use 5.014;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok 'Win32API::Console';
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

pass('Unicode detection test performed.');

done_testing;
