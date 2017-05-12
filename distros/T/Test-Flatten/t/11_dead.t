use strict;
use warnings;
use Test::More;
use IPC::Open3;

my @cmd = ($^X, '-Ilib', 't/dead');
my $pid = open3(undef, my $out, undef, @cmd);
waitpid($pid, 0);

like join(',', <$out>), qr{Undefined subroutine &main::bar}, 'throws ok';

done_testing;
