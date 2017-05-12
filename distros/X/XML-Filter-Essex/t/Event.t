use Test;
use XML::Essex::Event;
use strict;

my $e;

@XML::Essex::Event::foo_event::ISA = qw( XML::Essex::Event );

my @tests = (
sub {
    $e = XML::Essex::Event::foo_event->new;
    ok 1;
},

sub {
    ok $e->isa( "XML::Essex::Event::foo_event" );
},

sub {
    ok $e->isa( "XML::Essex::Event" );
},

sub {
    ok $e->isa( "foo_event" );
},

);

plan tests => 0+@tests;

$_->() for @tests;
