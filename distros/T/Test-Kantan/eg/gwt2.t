use strict;
use warnings;
use utf8;
use Test::Kantan;

Feature 'Foo', sub {
    Scenario 'Normal', sub {
        Given 'First';
        Given 'Second';
        my @ary;

        When 'Push one item';
        push @ary, 'a';
        When 'Push next item';
        push @ary, 'b';

        Then 'the number of array is 2';
        expect(0+@ary)->to_be(2);

        Then 'first item is "a"';
        expect($ary[0])->to_be('a');
    };
};


done_testing;

