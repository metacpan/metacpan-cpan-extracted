#!perl

use strict;
use warnings;

use PDL::Core qw(pdl);
use Test2::V0;
use Test2::Tools::PDL;

eval {
    require PDL::DateTime;
    require PDL::Lite;
};
if ($@) { plan skip_all => 'Requires PDL::DateTime'; }

subtest pdldt => sub {

    my $events = intercept {
        def ok => (
            pdl_is(
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                'simple pass'
            ),
            'simple pass'
        );
        def ok => (
            !pdl_is(
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-02)] ),
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                'simple fail'
            ),
            'simple fail'
        );
        def ok => (
            !pdl_is(
                pdl( [ 0, 0 ] ),
                PDL::DateTime->new_from_datetime( [qw(2018-01-01 2019-01-01)] ),
                'type fail'
            ),
            'type fail'
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
                call name => 'type fail';
            };
            end;
        },
        "got expected events"
    );
};

done_testing;
