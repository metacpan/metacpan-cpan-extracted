#!/usr/bin/perl

use strict ;
use Test ;
use Text::Diff ;
use Algorithm::Diff qw( traverse_sequences ) ;

my @A = map "$_\n", qw( 1 a 2 b 3 ) ;
my @B = map "$_\n", qw( 1 A 2 B 3 ) ;

## This tests both that we can overload all 5 methods and that all 5
## methods are called by diff() (and in the right order :)

my $f = "My::Diff::Format" ;
my $diff = diff \@A, \@B, { CONTEXT => 0, STYLE => $f } ;

my @tests = (
sub {
    if ( $diff =~ /(^${f}::.*){8}/sm ) {
        ok 1 ;
    }
    else {
	ok $diff, "8 lines of output" ;
    }
},

sub {
    if ( $diff =~ m{
            file_header.*
	    hunk_header.*
	    hunk.*
	    hunk_footer.*
	    hunk_header.*
	    hunk.*
	    hunk_footer.*
	    file_footer
        }sx
    ) {
        ok 1 ;
    }
    else {
	ok $diff, "proper ordering (see test source)" ;
    }
},

) ;

plan tests => scalar @tests ;

$_->() for @tests ;

package My::Diff::Format ;

use Data::Dumper ;

sub _dump {
    my $prefix = (caller(1))[3] ;
    local $Data::Dumper::Indent = 0 ;
    local $Data::Dumper::Terse  = 1 ;

    join( "",
        map { s/^/$prefix: /mg ; $_ ; } join ", ", map {
	    my $s = ref $_ ? Dumper $_ : $_ ;
	    $s =~ s/([\000-\026])/sprintf "\0x%02x", ord $1/ge ;
	    $s ;
	} @_
    ) . "\n" ;
}

sub file_header { &_dump }
sub hunk_header { &_dump }
sub hunk        { &_dump }
sub hunk_footer { &_dump }
sub file_footer { &_dump }
