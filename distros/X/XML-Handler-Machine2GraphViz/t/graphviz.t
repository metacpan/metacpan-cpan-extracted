#!/usr/local/bin/perl -w

use strict;
use Test;

use XML::SAX::Machines qw( Pipeline );
use XML::Handler::Machine2GraphViz;
use UNIVERSAL;

my $m;
my $h;

my @tests = (
sub {
    $m = Pipeline( ( "XML::SAX::Base" ) x 3 );
    ok UNIVERSAL::isa( $m, "XML::SAX::Pipeline" );
},

sub {
    $h = XML::Handler::Machine2GraphViz->new;
    ok UNIVERSAL::isa( $h, "XML::Handler::Machine2GraphViz" );
},

sub {
    $m->generate_description( $h );
    ok 1;
},

sub {
    ok $h->graphviz->as_dot;
},

sub {
    my $g = machine2graphviz $m ;
    ok $g->as_dot;
},

);

plan tests => scalar @tests;

$_->() for @tests;
