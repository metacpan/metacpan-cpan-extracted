use strict;
use warnings;
use Test::More;
use IPC::Open3;

my @cmd = ($^X, '-Ilib', 't/notests');
my $pid = open3(undef, my $out, undef, @cmd);
waitpid($pid, 0);

like join(',', <$out>), qr{No tests run for subtest foo}, '$Test::Builder::Level ok';

done_testing;
