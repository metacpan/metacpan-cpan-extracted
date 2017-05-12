use Test;
use XML::Filter::Dispatcher;
use strict;

my @tests = (
sub {
    my $d = XML::Filter::Dispatcher->new;
    $d->start_document( {} );
    $d->end_document  ( {} );
    ok 1;
},
sub {
    my $d = XML::Filter::Dispatcher->new( Rules => [] );
    $d->start_document( {} );
    $d->end_document  ( {} );
    ok 1;
},
);

plan tests => 0+@tests;

$_->() for @tests;
