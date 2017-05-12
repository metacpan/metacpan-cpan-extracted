#!/usr/local/bin/perl -w

=head1 NAME

cd_re.t - Tests content model -> RE compiliation

=cut

package Foo ;
use Test ;

package main ;

use strict ;
use Test ;
use XML::Doctype ;
use UNIVERSAL qw( isa ) ;

my $dt ;
my $re ;

my @tests = (

sub {
   $dt = XML::Doctype->new( 'a', DTD_TEXT => <<TOHERE ) ;
<!ELEMENT a ( b1, b2?, b3*, (b4|b5|(b6,b7)) ) >
<!ELEMENT b (#PCDATA) >
<!ELEMENT c (#PCDATA|a|b|c)* >
TOHERE

   ok( isa( $dt, 'XML::Doctype' ) ) ;
},

sub { ok( eval { qr/^$dt->{ELTS}->{b}->{CONTENT}$/ } ) },

sub {
   my $r = '^(?:(?:#PCDATA)?)$' ;
   ok( $dt->element_decl('b')->{CONTENT}, "$r" ) ;
},

sub { ok( eval { qr/$dt->{ELTS}->{c}->{CONTENT}/, 1 } ) },

sub {
   my $r = '^(?:(?:#PCDATA)?|<a>|<b>|<c>)*$' ;
   ok( $dt->{ELTS}->{c}->{CONTENT}, "$r" ) ;
},

sub { ok( $re = eval { qr/$dt->{ELTS}->{a}->{CONTENT}/ } ) },

sub { ok( '<b1><b2><b3><b3><b6><b7>' =~ $re ) },

sub {
   my $r = '^<b1>(?:<b2>)?(?:<b3>)*(?:<b4>|<b5>|<b6><b7>)$' ;
   ok( $dt->{ELTS}->{a}->{CONTENT}, "$r" ) ;
},

sub {
   ok( $dt->element_decl('a')->validate_content( [qw( b1 b2 b3 b3 b6 b7 )] ));
},

) ;

plan tests => scalar @tests ;

## Do this after planing so that the test harness can see that we 
## started, then failed.
package Foo ;
use XML::Doctype ;

package ::main ;
use XML::Doctype ;

skip "undo deprecation warning", 1 or $_->() for @tests ;

