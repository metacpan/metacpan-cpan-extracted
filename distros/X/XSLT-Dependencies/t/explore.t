use Test::More qw(no_plan);
use XSLT::Dependencies;
use Cwd;

my $dep = new XSLT::Dependencies;
my $cwd = getcwd();
my @list = qw(
    inc.xslt
    include/a.xslt
    include/b.xslt
    include/deep.xslt
    include/import.xslt
);

my @deps = sort grep {s{^$cwd/t/xslt/}{}} $dep->explore('t/xslt/test.xslt');
ok(join('|', @list) eq join('|', @deps), 'Recursive include/import dependencies');
