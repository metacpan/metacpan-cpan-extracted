#!perl

use strict;
use warnings;

use PDL::Core qw(pdl);
use Test2::V0;
use Test2::Tools::PDL;

eval {
    require Alt::Data::Frame::ButMore;
    require PDL::SV;
    require PDL::Lite;
};
if ($@) { plan skip_all => 'Requires PDL::SV'; }

subtest pdlsv => sub {

    my $events = intercept {
        def ok => (
            pdl_is(
                PDL::SV->new( [qw(foo bar)] ),
                PDL::SV->new( [qw(foo bar)] ),
                'simple pass'
            ),
            'simple pass'
        );
        def ok => (
            !pdl_is(
                PDL::SV->new( [qw(foo baz)] ),
                PDL::SV->new( [qw(foo bar)] ),
                'simple fail'
            ),
            'simple fail'
        );
        def ok => (
            !pdl_is(
                pdl( [ 0, 0 ] ),
                PDL::SV->new( [qw(foo bar)] ),
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
