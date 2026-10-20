use strict;
use warnings;
use Test::More;
use Encode qw(encode_utf8);

use lib 't/lib';

my $class = 'Fitnesse::Slim::Test::EchoScript';
my $loaded = eval "require $class; 1";
ok($loaded, 'load upstream EchoScript fixture');
if (!$loaded) {
    diag $@;
    done_testing;
    exit;
}

my $fixture = $class->new;
my $unicode = pack('U*', 0x8fd9, 0x662f, 0x4e2d, 0x6587);
is($fixture->echo($unicode), $unicode, 'echo preserves Unicode input');

my $stdout = '';
open my $out, '>', \$stdout or die "open scalar stdout: $!";
{
    local *STDOUT = $out;
    my $result = eval { $fixture->echo_to_stdout($unicode) };
    is($@, '', 'echoToStdout is implemented');
    is($result, $unicode, 'echoToStdout returns its input');
}
is($stdout, encode_utf8("$unicode\n"), 'echoToStdout writes the value and newline to stdout');

my $stderr = '';
open my $err, '>', \$stderr or die "open scalar stderr: $!";
{
    local *STDERR = $err;
    my $result = eval { $fixture->echo_to_stderr($unicode) };
    is($@, '', 'echoToStderr is implemented');
    is($result, $unicode, 'echoToStderr returns its input');
}
is($stderr, encode_utf8("$unicode\n"), 'echoToStderr writes the value and newline to stderr');

done_testing;
