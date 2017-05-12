#!/usr/bin/perl -w

use lib 't/lib';
use Test::More 'no_plan';
use Test::NoWarnings;

require_ok('mixin');
require_ok('mixin::with');


package Dog;
sub speak { "Bark!\n" }
sub new { my $class = shift;  bless {}, $class }


package Dog::Small;
use base 'Dog';
sub speak { "Yip!\n"; }


package Dog::Retriever;
use mixin::with 'Dog';
sub fetch { "Get your own stinking $_[1]\n" }


package Dog::Small::Retriever;
use base 'Dog::Small';
use mixin 'Dog::Retriever';


package main;
my $small_retriever = Dog::Small::Retriever->new;
is( $small_retriever->speak,            "Yip!\n" );
is( $small_retriever->fetch('ball'),    "Get your own stinking ball\n" );


package Hamish;
use base  'Dog';
use mixin 'Dog::Hamish';


package main;
my $hamish = Hamish->new;
isa_ok( $hamish, 'Hamish' );
is( $hamish->speak,                     "Bark!\n" );
is( $hamish->burglers,                  'burglers are everywhere!' );
