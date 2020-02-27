use Test2::V0;
use Test2::Plugin::IOEvents;

ok(1, "start");

my $fh;
my $pid = open($fh, '-|');

if (!$pid) {
    print('hello world');
    exit;
}

is(<$fh>, 'hello world', 'pipe as STDOUT works');

done_testing;
