#!/usr/local/bin perl -w

use strict;

use Test;
use XML::SAX::Machines qw( Machine );
use XML::SAX::Base;
use UNIVERSAL;

my $m;

my $p1 = XML::SAX::Base->new;
my $p2 = XML::SAX::Base->new;

my @tests = (
sub {
    $m = Machine(
        [ Intake => $p1 ],
        [ B      => Machine( [ "BA", Machine( [ "BAA", $p2 ] ) ] ) ],
    );
    ok UNIVERSAL::isa( $m, "XML::SAX::Machine" );
},

sub {
    my $p = $m->find_part( "Intake" );
    ok "$p", "$p1", "Intake";
},

sub {
    my $p = $m->find_part( "/Intake" );
    ok "$p", "$p1", "/Intake";
},

sub {
    my $p = $m->find_part( "/Intake/" );
    ok "$p", "$p1", "/Intake/";
},

sub {
    my $p = $m->find_part( "//../////.//Intake///.///" );
    ok "$p", "$p1", "//../////.//Intake///.///";
},

sub {
    my $p = $m->find_part( "B" );
    ok ref $p, "XML::SAX::Machine", "B";
},

sub {
    my $p = $m->find_part( "/B" );
    ok ref $p, "XML::SAX::Machine", "/B";
},

sub {
    my $p = $m->find_part( "/B/BA" );
    ok ref $p, "XML::SAX::Machine", "/B/BA";
},

sub {
    my $p = $m->find_part( "/B/BA/BAA" );
    ok "$p", "$p2", "/B/BA/BAA";
},

);

plan tests => scalar @tests;

$_->() for @tests;
