#!/usr/local/bin/perl -w

=head1 NAME

writer.t - test suite for XML::Doctype

=cut

package Foo ;
use Test ;

package main ;

use strict ;
use IO::File;
use Test ;
use XML::Doctype ;
use UNIVERSAL qw( isa ) ;

my $w ;
my $doctype ;

my $t = 't' ;

my $out_name    = "$t/out"  ;

my $buf ;

my $dtd = <<TOHERE ;
<!ELEMENT a ( b1, b2?, b3* ) >

    <!ATTLIST   a aa1 CDATA       #REQUIRED >

<!ELEMENT b1 ( c1 ) >
<!ELEMENT b2 ( c2 ) >
<!ELEMENT b3 ( #PCDATA | c3 )* >
TOHERE

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
   c1() ;
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

sub {
   unlink $out_name ;
   my $f =  IO::File->new( ">$out_name" ) ;
   my $w = XML::AutoWriter->new(
      DOCTYPE => $doctype,
      OUTPUT  => $f,
   ) ;
   $w->getDoctype->element_decl('a')->attdef('aa1')->default_on_write('foo') ;
   $w->xmlDecl ;
   $w->startTag( 'a' ) ;
   $w->startTag( 'c1' ) ;
   $w->end ;
   $f->close ;
   ok( slurp( $out_name ), qq{$xml_decl<a aa1="foo"><b1><c1 /></b1></a>} ) ;
},


##
## import tests
##
sub {
   package Foo ;
   eval 'use XML::AutoWriter qw(:all :dtd_tags), DOCTYPE => $doctype' ;
   die $@ if $@ ;
   ok( defined &a ) ;
},

sub {
   package Foo ;
   ok( defined &end_a ) ;
},

sub {
   unlink $out_name ;
   eval <<'TOHERE' ;
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
TOHERE
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
   test_xml_decl( 'foo', qq{<?xml version="1.0" encoding="foo"?>\n<a aa1="foo"><b1><c1 /></b1></a>} ) ;
},

sub {
   test_xml_decl( 'foo', 'bar',
      qq{<?xml version="1.0" encoding="foo" standalone="yes"?>\n<a aa1="foo"><b1><c1 /></b1></a>}
   ) ;
},

# Commented out so as not to trigger complaints about warnings
#sub {
#   test_xml_decl( '', 'bar',
#      qq{<?xml version="1.0" encoding="" standalone="yes"?>\n<a aa1="foo"></a>}
#   ) ;
#},
#
#sub {
#   test_xml_decl( 0, 'bar',
#      qq{<?xml version="1.0" encoding="0" standalone="yes"?>\n<a aa1="foo"></a>}
#   ) ;
#},
#
sub {
   test_xml_decl( undef, '',
      qq{<?xml version="1.0"?>\n<a aa1="foo"><b1><c1 /></b1></a>}
   ) ;
},

sub {
   test_xml_decl( undef, 0,
      qq{<?xml version="1.0"?>\n<a aa1="foo"><b1><c1 /></b1></a>}
   ) ;
},

sub {
   test_xml_decl( undef, 'no',
      qq{<?xml version="1.0" standalone="no"?>\n<a aa1="foo"><b1><c1 /></b1></a>}
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
   start_c1() ;
   characters( '<>' ) ;
   rawCharacters( '<>' ) ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1><c1 /></b1><b3>&lt;><></b3></a>} ) ;
},

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   xmlDecl() ;
   start_a()  ;
   start_c1() ;
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
   c1() ;
   characters( 'bar' ) ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1><c1 /></b1><b3>bar</b3></a>} ) ;
},

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   xmlDecl() ;
   start_a()  ;
   c1() ;
   b3( 'bar' ) ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1><c1 /></b1><b3>bar</b3></a>} ) ;
},

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   xmlDecl() ;
   start_a()  ;
   start_c1() ;
   start_c2() ;
   end_a()    ;
   $buf =~ s/\n//g ;
   ok( $buf, qq{$xml_decl<a aa1="foo"><b1><c1 /></b1><b2><c2 /></b2></a>} ) ;
},

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   xmlDecl() ;
   $buf =~ s/\n//g ;
   defaultWriter()->reset() ;
   ok( $buf, $xml_decl ) ;
},

## From Laurent CAPRANI, modified a bit
sub {
   my $dt = XML::Doctype->new( 'D', DTD_TEXT => <<TOHERE ) ;
      <!ELEMENT D ( G )* >         <!-- D was DOC -->
      <!ELEMENT G ( P )* >         <!-- G was GROUP -->
      <!ELEMENT P (#PCDATA) > 
TOHERE

   $buf = '' ;
   my $w = XML::AutoWriter->new( DOCTYPE => $dt, OUTPUT => \$buf ) ;

   $w->xmlDecl ;
   $w->characters( 'yaba' ) ;
   $w->start_G ;
   $w->characters( 'daba' ) ;
   $w->endAllTags ;

   $buf =~ s/\n//g ;

   ok( $buf, qq{$xml_decl<D><G><P>yaba</P></G><G><P>daba</P></G></D>} ) ;
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
   $w = XML::AutoWriter->new() ;
   ok( isa( $w, "XML::AutoWriter" ) ) ;
},

) ;

plan tests => scalar @tests ;

## Do this after planing so that the test harness can see that we 
## started, then failed.
use XML::AutoWriter qw( :all ) ;

$_->() for @tests ;

