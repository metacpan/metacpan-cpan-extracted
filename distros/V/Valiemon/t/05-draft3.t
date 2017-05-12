use strict;
use warnings;
use lib 't/lib/';

use Test::More;

use SuiteRunner;

use Valiemon;

my $runner = SuiteRunner->new;

my @tests = map { glob $_ } qw(
    t/test-suite/tests/draft3/*.json
    t/test-suite/tests/draft3/optional/*.json
);

# "disallow", "extends" are removed in draft4.
# "divisibleBy" is renamed to "multipleOf" in draft4.
# Behaviour of "dependencies" changed in draft4, so some of draft3-valid schema is no longer valid.
my %todos = map {
    ($_ => 1)
} qw(
    t/test-suite/tests/draft3/additionalProperties.json
    t/test-suite/tests/draft3/dependencies.json
    t/test-suite/tests/draft3/disallow.json
    t/test-suite/tests/draft3/divisibleBy.json
    t/test-suite/tests/draft3/extends.json
    t/test-suite/tests/draft3/minLength.json
    t/test-suite/tests/draft3/optional/bignum.json
    t/test-suite/tests/draft3/optional/format.json
    t/test-suite/tests/draft3/optional/jsregex.json
    t/test-suite/tests/draft3/optional/zeroTerminatedFloats.json
    t/test-suite/tests/draft3/patternProperties.json
    t/test-suite/tests/draft3/properties.json
    t/test-suite/tests/draft3/ref.json
    t/test-suite/tests/draft3/refRemote.json
    t/test-suite/tests/draft3/type.json
);

for my $test (@tests) {
    subtest $test => sub {
        $runner->run($test, $todos{$test});
    };
}

done_testing;
