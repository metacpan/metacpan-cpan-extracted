use Test::Distribution tests => 4, podcoveropts => {trustme => [qr/run_tests/]};;
use Test::More;
ok(1, 'extra test');

# 4 descriptions + 4 * (1 module) + 4 extra + 1 prereq + 1 manifest
my $number_of_tests = 14;

is(Test::Distribution::num_tests(), $number_of_tests, 'number of tests');

is_deeply(Test::Distribution::packages(), 'Test::Distribution',
    'packages found');

my @files = Test::Distribution::files();
# On non Unix type file systems the first file separator could be different
# than the unix /. This is because it comes from File::Spec. The others will
# still be a unix / because they come from File::Find::Rule
like($files[0], qr/lib.*?Test.*?Distribution.pm/);

