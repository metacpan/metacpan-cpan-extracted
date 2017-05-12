#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN {
    foreach my $postfix ("", qw(::Lens ::DeeModel ::Util)) {
        use_ok("Web::Dash$postfix");
    }
}

done_testing();
