#!/usr/bin/perl -w

use strict;
use Test::More;
use Sys::Hostname;

if( open LOGIN, "t/.login" ) {
    plan 'no_plan';
}
else {
    plan skip_all => 'fill in t/.login if you want to run the tests';
}

use XPlanner;

open LOGIN, "t/.login";
my($url, $user, $pass) = <LOGIN>;
close LOGIN;
chomp($url, $user, $pass);

my $xp = XPlanner->login($url, $user, $pass);
isa_ok $xp, 'XPlanner';

my $person = $xp->people->{test};
isa_ok $person, 'XPlanner::Person';

my $project = $xp->projects->{Test};
isa_ok $project, 'XPlanner::Project';

my $iteration = $project->iterations->{'Testing SOAP'};
isa_ok $iteration, 'XPlanner::Iteration';

my $story = $iteration->stories->{foo};
isa_ok $story, 'XPlanner::Story';

