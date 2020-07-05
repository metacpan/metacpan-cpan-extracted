use Test2::Plugin::Cover;
use Test2::V0 -target => 'Test2::Plugin::Cover';
use Path::Tiny qw/path/;
use File::Spec();

$CLASS->clear;
my $fh;
open($fh, '<', 'aaa.json');
open($fh, '<bbb.json');
open($fh, '+<ccc.json');
open($fh, '-<ddd.json');
open($fh, File::Spec->catfile('dir', 'eee'));


close($fh);
my $data = $CLASS->files(root => path('.'));
like(
    [ sort grep { !m/\.pm$/ } @$data ],
    array {
        item('aaa.json');
        item('bbb.json');
        item('ccc.json');
        item('ddd.json');
        item(path(File::Spec->catfile('dir', 'eee'))->relative(path('.'))->stringify());
    },
    "Got files we (tried to) open",
);


$CLASS->clear;

# The next several are to make sure things do not segv, nothing useful can be captured from them
my $ref = "";
open($fh, '>', \$ref);
print $fh "HI\n";
close($fh);
is($ref, "HI\n", "Wrote hi");

# This will incidentally catch the last statement as a potential file, thats
# fine.
open($fh, '-|', $^X, '-e', 'print "HI\n"; exit 0');
close($fh);
ok(1, "Made it here");

# Final cleanup
$CLASS->clear;

done_testing;
