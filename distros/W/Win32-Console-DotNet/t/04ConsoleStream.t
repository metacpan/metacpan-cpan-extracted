use 5.014;
use warnings;

use Test::More tests => 7;
use Test::Exception;

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'System';
}

my $stderr;
lives_ok { $stderr = System::Console->OpenStandardError() || die } 
  'GetStandardFile';
lives_ok { $stderr->say('say something') } 'say';
lives_ok { $stderr->flush() || die } 'flush';
lives_ok { $stderr->fileno() != -1 || die } 'fileno';
lives_ok { $stderr->close() || die } 'close';

done_testing;
