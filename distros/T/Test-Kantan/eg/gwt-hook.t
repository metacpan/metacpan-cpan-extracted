use strict;
use warnings;
use utf8;
use Test::Kantan;

my @p;
setup { push @p, 'a' };

Feature 'foo', sub {
    Then 'pushed';
    ok { 1 };
};

Feature 'bar', sub {
    Then 'pushed';
    ok { 2 };
};

done_testing;

