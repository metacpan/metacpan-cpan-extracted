#!perl
use strict;
use warnings;
use Test::More;
BEGIN {
    eval 'use Moose; 1';
    plan skip_all => 'requires Moose' if $@;
}

{
    package Thing;
    use Moose;
    has 'ua' => ( is => 'ro', isa => 'LWP::UserAgent' );
}

{
    use LWP::UserAgent;
    my $thing = Thing->new(ua => LWP::UserAgent->new);
    isa_ok $thing, 'Thing';
    isa_ok $thing->ua, 'LWP::UserAgent';
}

{
    use Test::Mock::LWP::Dispatch;
    my $thing = Thing->new(ua => $mock_ua);
    isa_ok $thing, 'Thing';
    isa_ok $thing->ua, 'LWP::UserAgent';
}

{
    use Test::Mock::LWP::Dispatch ();
    my $thing = Thing->new(ua => LWP::UserAgent->new);
    isa_ok $thing, 'Thing';
    isa_ok $thing->ua, 'LWP::UserAgent';
}
done_testing;

