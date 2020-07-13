use Test2::Plugin::Cover;
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;
use Fcntl qw/O_RDONLY/;

skip_all 'disabled';

$CLASS->clear;
my $fh;

print STDERR "\nDEBUG A\n";
STDERR->flush();
sysopen($fh, 'fff.json', O_RDONLY);
close($fh);

print STDERR "\nDEBUG B\n";
STDERR->flush();
sysopen($fh, 'ggg.json', O_RDONLY, 0);
close($fh);

print STDERR "\nDEBUG C\n";
STDERR->flush();
sysopen($fh, 'hhh.json', O_RDONLY);
close($fh);

print STDERR "\nDEBUG D\n";
STDERR->flush();
sysopen($fh, 'iii.json', O_RDONLY);
close($fh);

print STDERR "\nDEBUG E\n";
STDERR->flush();

like(
    $CLASS->files(root => path('.')),
    bag {
        item('fff.json');
        item('ggg.json');
        item('hhh.json');
        item('iii.json');
    },
    "Got files we (tried to) open"
);

# Final cleanup
$CLASS->clear;

done_testing;
