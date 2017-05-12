use strict;
use warnings;
no warnings qw/ uninitialized /;

use Test::More;

$ENV{ TEST_AUTHOR } =~ /WWW::Ohloh::API/ and eval q{
    use Test::Pod::Coverage;
    goto RUN_TESTS;
};

plan skip_all => $@
       ? 'Test::Pod::Coverage not installed; skipping pod coverage testing'
       :   q{Set TEST_AUTHOR to 'WWW::Ohloh::API' in your environment }
         . q{ to enable these tests};

RUN_TESTS: 

all_pod_coverage_ok();
