#!perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::PDL;

eval {
    require Alt::Data::Frame::ButMore;
    require PDL::Factor;
    require PDL::Lite;
};
if ($@) { plan skip_all => 'Requires PDL::Factor'; }

subtest pdlsv => sub {
    my $events = intercept {
        def ok => (
            pdl_is(
                PDL::Factor->new( [qw(foo bar foo)] ),
                PDL::Factor->new( [qw(foo bar foo)] ),
                'simple pass'
            ),
            'simple pass'
        );
        def ok => (
            !pdl_is(
                PDL::Factor->new( [qw(foo bar foo)] ),
                PDL::Factor->new( [qw(foo bar baz)] ),
                'simple fail'
            ),
            'simple fail'
        );
        def ok => (
            !pdl_is(
                PDL::Factor->new( [qw(foo bar foo)], levels => [qw(bar foo)] ),
                PDL::Factor->new( [qw(foo bar foo)], levels => [qw(foo bar)] ),
                'levels fail'
            ),
            'levels fail'
        );
        def ok => (
            !pdl_is(
                PDL::Factor->new( [qw(foo bar foo)] ),
                PDL::Factor->new( [qw(foo baz foo)] ),
                'levels fail 2'
            ),
            'levels fail 2'
        );
    };

    do_def;

    like(
        $events,
        array {
            event Ok => sub {
                call pass => T();
                call name => 'simple pass';
            };
            event Fail => sub {
                call name => 'simple fail';
            };
            event Fail => sub {
                call name => 'levels fail';
            };
            event Fail => sub {
                call name => 'levels fail 2';
            };
            end;
        },
        "got expected events"
    );
};

done_testing;
