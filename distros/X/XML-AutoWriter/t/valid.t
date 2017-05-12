#!/usr/local/bin/perl -w

=head1 NAME

valid.t - test suite for XML::ValidWriter

=cut

package Foo ;
use Test ;

package main ;

use strict ;
use Test ;
use XML::Doctype ;
use UNIVERSAL qw( isa ) ;
use IO::File;

my $w ;
my $doctype ;

my $t = 't' ;

my $dtd = <<TOHERE ;
<!ELEMENT a ( b1, b2?, b3* ) >

    <!ATTLIST   a aa1 CDATA       #REQUIRED >

<!ELEMENT b1 ( #PCDATA | c1 )* >
<!ELEMENT b2 ( c2 ) >
<!ELEMENT b3 ( c3 ) >
TOHERE

my $out_name    = "$t/out"  ;

my $buf ;

my %dtd1_elts = (
   a  => { KIDS => [qw( b1 b2 b3 )],  },
   b1 => { KIDS => [qw( c1 )], },
   b2 => { KIDS => [qw( c2 )], },
   b3 => { KIDS => [qw( c3 )], },
) ;

sub slurp {
   my ( $in_name ) = @_ ;
   open( F, "<$in_name" ) or die "$!: $in_name" ;
   local $/ = undef ;
   my $in = join( '', <F> ) ;
   close F ;
   $in =~ s/\n//g ;
   return $in ;
}

my $xml_decl = qq{<?xml version="1.0"?>} ;

sub test_xml_decl {
   my $expected = pop ;
   
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   ## The extra ()'s are necessary because we didn't import at compile time.
   xmlDecl( @_ ) ;
   start_a() ;
   start_b1() ;
   start_c1() ;
   endAllTags() ;
   $buf =~ s/\n//g ;
   $expected =~ s/\n//g ;
   ok( $buf, $expected ) ;
}

my @tests = (

sub {
   $doctype = XML::Doctype->new( 'a', DTD_TEXT => $dtd ) ;
   ok( $doctype ) ;
},

##
## Writing to an IO::* or to a named file
##
sub {
   unlink $out_name ;
   my $f = IO::File->new( ">$out_name" ) ;
   my $w = XML::ValidWriter->new(
      DOCTYPE => $doctype,
      OUTPUT  => $f,
   ) ;
   $w->getDoctype->element_decl('a')->attdef('aa1')->default_on_write('foo') ;
   $w->xmlDecl ;
   $w->startTag( 'a' ) ;
   $w->startTag( 'b1' ) ;
   $w->startTag( 'c1' ) ;
   $w->end ;
   $f->close ;
   ok( slurp( $out_name ), qq{$xml_decl<a aa1="foo"><b1><c1 /></b1></a>} ) ;
   unlink $out_name || warn "$!: $out_name" ;
},

sub {
   unlink $out_name ;
   {
      my $w = XML::ValidWriter->new(
	 DOCTYPE => $doctype,
	 OUTPUT  => $out_name,
      ) ;
      $w->getDoctype->element_decl('a')->attdef('aa1')->default_on_write('foo');
      $w->xmlDecl ;
      $w->startTag( 'a' ) ;
      $w->startTag( 'b1' ) ;
      $w->startTag( 'c1' ) ;
      $w->end ;
      ## File should be closed on end of scope.
   }
   ok( slurp( $out_name ), qq{$xml_decl<a aa1="foo"><b1><c1 /></b1></a>} ) ;
   unlink $out_name || warn "$!: $out_name" ;
},

##
## import tests
##
sub {
   package Foo ;
   eval 'use XML::ValidWriter qw(:all :dtd_tags), DOCTYPE => $doctype' ;
   die $@ if $@ ;
   ok( defined &a ) ;
},

sub {
   package Foo ;
   ok( defined &end_a ) ;
},

sub {
   unlink $out_name ;
   eval q{
      package Foo ;
      defaultWriter()->reset ;
      open( F, ">$out_name" ) or die "$!: '$out_name'" ;
      select F   ;
      xmlDecl ;
      start_a foo => '&<>"'  ;
      start_b1 ;
      c1 ;
      endAllTags ;
      select STDOUT ;
      close F ;
   } ;
   die $@ if $@ ;
   ok(
      slurp( $out_name ),
      qq{$xml_decl<a foo="&amp;&lt;>&quot;" aa1="foo"><b1><c1 /></b1></a>}
   ) ;
   unlink $out_name ;
},

##
## XML decl tests
##
# Commented out so as to not to trigger complaints about warnings
#sub {
#   package Foo ;
#   $buf = '' ;
#   defaultWriter()->reset ;
#   select_xml( \$buf ) ;
#   ## The extra ()'s are necessary because we didn't import at compile time.
#   a()  ;
#   ok( $buf, qq{<a aa1="foo">} ) ;
#},

sub {
   test_xml_decl( 'foo', qq{<?xml version="1.0" encoding="foo"?><a aa1="foo"><b1><c1 /></b1></a>} ) ;
},

sub {
   test_xml_decl( 'foo', 'bar',
      qq{<?xml version="1.0" encoding="foo" standalone="yes"?><a aa1="foo"><b1><c1 /></b1></a>}
   ) ;
},

# Commented out so as not to trigger complaints about warnings
#sub {
#   test_xml_decl( '', 'bar',
#      qq{<?xml version="1.0" encoding="" standalone="yes"?><a aa1="foo"><b1><c1 /></b1></a>}
#   ) ;
#},
#
#sub {
#   test_xml_decl( 0, 'bar',
#      qq{<?xml version="1.0" encoding="0" standalone="yes"?><a aa1="foo"><b1><c1 /></b1></a>}
#   ) ;
#},
#
sub { test_xml_decl( undef, '', qq{$xml_decl<a aa1="foo"><b1><c1 /></b1></a>} ) },

sub { test_xml_decl( undef, 0, qq{$xml_decl<a aa1="foo"><b1><c1 /></b1></a>} ) },

sub {
   test_xml_decl( undef, 'no',
      qq{<?xml version="1.0" standalone="no"?><a aa1="foo"><b1><c1 /></b1></a>}
   ) ;
},

##
## Misc tag emission tests
##
sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   ## The extra ()'s are necessary because we didn't import at compile time.
   xmlDecl() ;
   start_a()  ;
   start_b1() ;
   characters( '<>' ) ;
   rawCharacters( '<>' ) ;
   end_b1() ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1>&lt;><></b1></a>} ) ;
},

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   xmlDecl() ;
   start_a()  ;
   start_b1() ;
   characters( '' ) for (1..100) ;
   rawCharacters( '' )  for (1..100) ;
   end_b1() ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1 /></a>} ) ;
},

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   xmlDecl() ;
   start_a()  ;
   start_b1() ;
   empty_c1() ;
   end_b1() ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1><c1 /></b1></a>} ) ;
},

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   xmlDecl() ;
   start_a()  ;
   b1( 'test' ) ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1>test</b1></a>} ) ;
},

# Commented out so as to not to trigger complaints about failing tests
#sub {
#   package Foo ;
#   $buf = '' ;
#   defaultWriter()->reset ;
#   select_xml( \$buf ) ;
#   a()  ;
#   endAllTags() ;
#   a() ;
#   ok( $buf, qq{<a aa1="foo">} ) ;
#},

# Commented out so as to not to trigger complaints about failing tests
#sub {
#   package Foo ;
#   $buf = '' ;
#   defaultWriter()->reset ;
#   select_xml( \$buf ) ;
#   endAllTags() ;
#   ok( $buf, qq{<a aa1="foo">} ) ;
#},

##
## OO tests
##
sub {
   $w = XML::ValidWriter->new() ;
   ok( isa( $w, "XML::ValidWriter" ) ) ;
},

) ;

plan tests => scalar @tests ;

## Do this after planing so that the test harness can see that we 
## started, then failed.
use XML::ValidWriter qw( :all ) ;

$_->() for @tests ;

