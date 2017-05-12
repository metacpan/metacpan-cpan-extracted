use strict;
use warnings;
use Test::More;
use IPC::Open3;

my @cmd = ($^X, '-Ilib', 't/nested');
my $pid = open3(undef, my $out, undef, @cmd);
waitpid($pid, 0);

like join(',', <$out>), qr{hoge at t/nested line 9\.}, 'nested dead ok';

done_testing;
