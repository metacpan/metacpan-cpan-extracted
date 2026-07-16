use Test2::V0;
use Path::Tiny qw/path/;
use Fcntl qw/O_RDONLY/;

# This test is identical to the other sysopen test, except it does not use
# Test2::Plugin::Cover. The idea is to weed out sysopen errors not related to
# the plugin.

my $fh;

sysopen($fh, 'fff.json', O_RDONLY);
close($fh);

sysopen($fh, 'ggg.json', O_RDONLY, 0);
close($fh);

sysopen($fh, 'hhh.json', O_RDONLY);
close($fh);

sysopen($fh, 'iii.json', O_RDONLY);
close($fh);

my @list = ('AAA', 'BBB', do { sysopen($fh, 'jjj.json', O_RDONLY); close($fh); 'CCC' });

ok(1, "Lived");

done_testing;
