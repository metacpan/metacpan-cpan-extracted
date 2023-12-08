use strict;
use warnings;

BEGIN {
    use Test2::Formatter::YAMLEnhancedTAP;
    use Test2::API qw(test2_formatter_set);
    test2_formatter_set('Test2::Formatter::YAMLEnhancedTAP');
}

use Test::More;

plan tests => 1;

ok 0, 'simple-fail-msg';
