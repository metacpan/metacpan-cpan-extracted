use Test::More;

use YAML::Conditional;

my $struct = q|
if:
    m: test
    key: test
    then:
        abc: 123
elsif:
    m: other
    key: test
    then:
        def: 456
else:
    then:
        ghi: 789
|;

my $compiled = YAML::Conditional->new->compile($struct, { test => "other" }, 1);
is_deeply($compiled, { def => 456 });

done_testing;
