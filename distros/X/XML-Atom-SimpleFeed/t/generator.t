use strict;
use warnings;

use XML::Atom::SimpleFeed;
use Test::More 0.88; # for done_testing

my $g = XML::Atom::SimpleFeed::DEFAULT_GENERATOR;

like $_, qr!<generator uri="$g->{'uri'}" version="$g->{'version'}">$g->{'name'}</generator>!, 'default generator'
	for XML::Atom::SimpleFeed->new( qw( title x id y ) )->as_string;

like $_, qr!<generator>z</generator>!, 'specified generator'
	for XML::Atom::SimpleFeed->new( qw( title x id y generator z ) )->as_string;

unlike $_, qr!<generator!, 'suppressed generator'
	for XML::Atom::SimpleFeed->new( qw( title x id y generator ), undef )->as_string;

done_testing;
