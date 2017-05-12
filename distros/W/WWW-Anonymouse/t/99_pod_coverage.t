use strict;
use warnings;
use Test::More;

if ( ($ENV{CPAN_AUTHOR_TESTS}||'') !~ /\bWWW::Anonymouse\b/ ) {
    plan skip_all => 'author tests';
}

eval "use Test::Pod::Coverage 1.00";
if ($@) {
    plan skip_all => 'Test::Pod::Coverage 1.00 required for testing POD coverage';
}

all_pod_coverage_ok();
