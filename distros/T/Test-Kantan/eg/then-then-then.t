use strict;
use warnings;
use utf8;
use Test::Kantan;

Feature 'Then-Then-Then', sub {
    Then 'A';
    Then 'B';
    Then 'C';
};

done_testing;

