use strict;
use warnings;
use Test::More;
use IPC::Open3;

my @cmd = ($^X, '-Ilib', 't/fail');
my $pid = open3(undef, my $out, undef, @cmd);
waitpid($pid, 0);

like join(',', <$out>), qr{at t/fail line 7}, '$Test::Builder::Level ok';

done_testing;
