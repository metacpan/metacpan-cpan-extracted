use strict;
use warnings;
use Test::More;

use Woothee;

subtest 'version string pattern' => sub {
    ok ( $Woothee::VERSION =~ /^[0-9]+\.[0-9]+\.[0-9]+$/ );
};

done_testing;
