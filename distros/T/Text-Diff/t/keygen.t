#!/usr/bin/perl

use strict ;
use Test ;
use Text::Diff ;

my @A = map "$_\n", qw( 1 2  3_ 4_ ) ;
my @B = map "$_\n", qw( 1 2_ 3  4_ ) ;

my @tests = (
sub {
    ok !diff \@A, \@B, {
        KEYGEN => sub {
            local $_ = shift ; 
            s/_+//g ;
            return $_ . shift ;
        },
	KEYGEN_ARGS => [ "args" ],
    } ;
},
) ;

plan tests => scalar @tests ;

$_->() for @tests ;
