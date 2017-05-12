use strict;
use warnings;
use utf8;
use Test::Kantan;

Feature 'Foo', sub {
    Scenario 'bar', sub {
         Then 'baz';
         die;
    };
};

done_testing;

