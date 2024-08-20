use 5.014;
use warnings;

use Test::More tests => 10;
use Test::Exception;

use FindBin qw( $Script );

BEGIN {
  use_ok 'Win32::Console::DotNet';
  use_ok 'IO::DebugOutputTextWriter';
}

my $stream;
lives_ok { $stream = IO::DebugOutputTextWriter->new() || die } 'new';
lives_ok { $stream->open("[$Script] ") || die } 'open';
lives_ok { $stream->print('Debug', 'View') } 'print';
lives_ok { $stream->printf('printf? %s', 'works') } 'printf';
lives_ok { $stream->say('filtered!') } 'say';
lives_ok { $stream->say(local $_) } 'say(undef)';
lives_ok { $stream->fileno() == -1 || die } 'fileno';
lives_ok { $stream->close() || die } 'close';

done_testing;
