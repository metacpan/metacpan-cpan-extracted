use Test2::Plugin::Cover;
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;
use Fcntl qw/O_RDONLY/;

$CLASS->reset_coverage;
my $fh;

sysopen($fh, 'fff.json', O_RDONLY);
close($fh);

sysopen($fh, 'ggg.json', O_RDONLY, 0);
close($fh);

sysopen($fh, 'hhh.json', O_RDONLY);
close($fh);

sysopen($fh, 'iii.json', O_RDONLY);
close($fh);

# sysopen nested inside other stack activity, this used to read unrelated
# stack slots (and could segv) when the handler assumed a mark was pushed.
my @list = ('AAA', 'BBB', do { sysopen($fh, 'jjj.json', O_RDONLY); close($fh); 'CCC' });

like(
    $CLASS->files(root => path('.')),
    bag {
        item('fff.json');
        item('ggg.json');
        item('hhh.json');
        item('iii.json');
        item('jjj.json');
    },
    "Got files we (tried to) open"
);

# Final cleanup
$CLASS->reset_coverage;

done_testing;
