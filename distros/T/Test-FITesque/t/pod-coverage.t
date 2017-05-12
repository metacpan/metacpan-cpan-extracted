#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => "Test::Pod::Coverage test only run by author" if !$ENV{AUTHOR_TEST};
all_pod_coverage_ok({ also_private => [ qr{(FETCH|MODIFY)_CODE_ATTRIBUTES} ], });
