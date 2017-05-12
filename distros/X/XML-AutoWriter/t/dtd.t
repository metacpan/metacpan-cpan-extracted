#!/usr/local/bin/perl -w

=head1 NAME

dtd.t - test suite for XML::Doctype

=cut

use strict ;
use Test ;
use UNIVERSAL qw( isa ) ;

use XML::Doctype;

my $w ;
my $dtd = <<TOHERE ;
<!ELEMENT a ( b1, b2?, b3* ) >

    <!ATTLIST   a aa1 CDATA       #REQUIRED >

<!ELEMENT b1 ( c1 ) >
<!ELEMENT b2 ( c2 ) >
<!ELEMENT b3 ( c3 ) >
TOHERE


my $t = 't' ;
my $dtd_file = "$t/dtd_t.dtd" ;

unlink $dtd_file ;

open DTD, ">$dtd_file" or die "$!: $dtd_file" ;
print DTD $dtd         or die "$!: $dtd_file" ;
close DTD              or die "$!: $dtd_file" ;

my $pm ;

my %dtd1_elts = (
   a  => { KIDS => [qw( b1 b2 b3 )],  },
   b1 => { KIDS => [qw( c1 )], },
   b2 => { KIDS => [qw( c2 )], },
   b3 => { KIDS => [qw( c3 )], },
   c1 => { KIDS => [] },
   c2 => { KIDS => [] },
   c3 => { KIDS => [] },
) ;

my XML::Doctype $doctype;

my @tests = (

##
## File parsing
##
sub {
   $doctype= XML::Doctype->new( 'a', $dtd_file ) ;
   ok( $doctype) ;
},

sub { ok( $doctype->name,      'a'       ) },
sub { ok( $doctype->system_id, $dtd_file ) },

( map {
   my $elt = $_ ;
   (
      sub { ok( exists  $doctype->{ELTS}->{$elt} ) ; },
      sub { ok( defined $doctype->{ELTS}->{$elt} ) ; },
      sub {
         ok(
	    join( ',', sort $doctype->{ELTS}->{$elt}->child_names ),
	    join( ',', sort @{$dtd1_elts    {$elt}->{KIDS}} )
	 ) ;
      },
   ) ;
} keys %dtd1_elts ),

##
## Text parsing
##
sub {
   $doctype= XML::Doctype->new( 'a', DTD_TEXT => $dtd ) ;
   ok( $doctype) ;
},

sub { ok( $doctype->name,      'a'      ) },
sub { ok( ! defined $doctype->system_id ) },

( map {
   my $elt = $_ ;
   (
      sub { ok( exists  $doctype->{ELTS}->{$elt} ) ; },
      sub { ok( defined $doctype->{ELTS}->{$elt} ) ; },
      sub {
         ok(
	    join( ',', sort $doctype->{ELTS}->{$elt}->child_names ),
	    join( ',', sort @{$dtd1_elts    {$elt}->{KIDS}} )
	 ) ;
      },
   ) ;
} keys %dtd1_elts ),

sub {
   ok(
      join( ',', sort $doctype->element_names ),
      join( ',', sort keys %dtd1_elts )
   ) ;
},

##
## Saving as a module and reloading
##
sub {
   $pm = $doctype->as_pm( 'Foo' ) ;
   ok( $pm, qr/package Foo ;(.*'a'|.*'c2'){2}/s ) ;
},

sub {
   unlink 'Foo.pm' ;
   open PM, ">Foo.pm" or die "$!: 'Foo.pm'" ;
   print PM $pm       or die "$!: 'Foo.pm'" ;
   close PM           or die "$!: 'Foo.pm'" ;
   local @INC = ( @INC, '.' ) ;
   ok( !! eval "package Bar ; use Foo ; 1;" ) ;
   unlink 'Foo.pm'    or warn "$!: Foo.pm" ;
},

sub {
   ok( $@ || '', '' ) ;
},

sub {
   ok( !! $XML::Doctype::_default_dtds{Bar} ) ;
},

##
## Default object parsing
##
sub {
   eval <<TOHERE ;
use XML::Doctype NAME => 'a', SYSTEM_ID => '$dtd_file' ;
TOHERE
   die $@ if $@ ;
   ok( 1 ) ;
},

sub { ok( !! $XML::Doctype::_default_dtds{main} ) ; },


) ;

plan tests => scalar @tests ;

## Do this after planing so that the test harness can see that we 
## started, then failed.
use XML::Doctype ;

$_->() for @tests ;

unlink $dtd_file or warn "$!: $dtd_file" ;

