use strict;
use warnings;
use lib 't/lib/';

use Test::More;

use SuiteRunner;

use Valiemon;

my $runner = SuiteRunner->new;

my @tests = map { glob $_ } qw(
    t/test-suite/tests/draft4/*.json
    t/test-suite/tests/draft4/optional/*.json
);

# following tests fail because Valiemon treats 1 as string:
# - not.json
# - type.json
# - maxLength.json
# - minLength.json
# - anyOf.json
# - oneOf.json
# following tests fail because patternProperties are not implemented:
# - additionalProperties.json
# - properties.json
# - patternProperties.json (of course)
# following tests fail because Valiemon onnly supports only single scope:
# - definitions.json
# - ref.json
# - refRemote.json
my %todos = map {
    ($_ => 1)
} qw(
    t/test-suite/tests/draft4/additionalProperties.json
    t/test-suite/tests/draft4/anyOf.json
    t/test-suite/tests/draft4/definitions.json
    t/test-suite/tests/draft4/maxLength.json
    t/test-suite/tests/draft4/minLength.json
    t/test-suite/tests/draft4/not.json
    t/test-suite/tests/draft4/oneOf.json
    t/test-suite/tests/draft4/optional/bignum.json
    t/test-suite/tests/draft4/optional/format.json
    t/test-suite/tests/draft4/optional/zeroTerminatedFloats.json
    t/test-suite/tests/draft4/patternProperties.json
    t/test-suite/tests/draft4/properties.json
    t/test-suite/tests/draft4/ref.json
    t/test-suite/tests/draft4/refRemote.json
    t/test-suite/tests/draft4/type.json
);

for my $test (@tests) {
    subtest $test => sub {
        $runner->run($test, $todos{$test});
    };
}

done_testing;
