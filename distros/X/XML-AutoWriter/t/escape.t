#!/usr/local/bin/perl -w

=head1 NAME

escape.t - Escaping test suite for XML::ValidWriter

=cut

package Foo ;
use Test ;

package main ;

use strict ;
use Test ;
use XML::Doctype ;
use UNIVERSAL qw( isa ) ;

my $w ;
my $doctype ;

my $t = 't' ;

my $dtd = <<TOHERE ;
<!ELEMENT a (#PCDATA|b)*>

<!ELEMENT b EMPTY >

TOHERE

my $out_name    = "$t/out"  ;

my $buf ;

my $xml_decl = qq{<?xml version="1.0"?>} ;

sub test_cdata_esc {
   ## See if contiguously emitted CDATA end sequences are escaped properly
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   ## The extra ()'s are necessary because we didn't import at compile time.
   xmlDecl() ;
   start_a()  ;
   ## Kick us in to CDATA mode
   characters( "<<<<<" ) ;
   ## play games
   characters( $_ ) for @_ ;
   end_a()    ;
   $buf =~ s{.*<a>}{}sg ;
   $buf =~ s{]]></a>.*}{}sg ;
   $buf =~ s{<!\[CDATA\[<<<<<}{} ;
   return $buf ;
}

sub test_char_data_esc {
   ## See if regular CharData is escaped properly
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   ## The extra ()'s are necessary because we didn't import at compile time.
   xmlDecl() ;
   start_a()  ;
   ## play games
   characters( $_ ) for @_ ;
   end_a()    ;
   $buf =~ s{.*<a>}{}sg ;
   $buf =~ s{</a>.*}{}sg ;
   return $buf ;
}

my @tests = (

sub {
   $doctype = XML::Doctype->new( 'a', DTD_TEXT => $dtd ) ;
   ok( $doctype ) ;
},

sub {
   package Foo ;
   eval 'use XML::ValidWriter qw(:all :dtd_tags), DOCTYPE => $doctype' ;
   die $@ if $@ ;
   ok( defined &a ) ;
},

##
## CharData escape tests
##
sub { ok( test_char_data_esc( "&"      ), "&amp;"         ) },
sub { ok( test_char_data_esc( "<"      ), "&lt;"          ) },
sub { ok( test_char_data_esc( ">"      ), "&gt;"          ) },
sub { ok( test_char_data_esc( "]>"     ), "]&gt;"         ) },
sub { ok( test_char_data_esc( "a", ">" ), "a&gt;"         ) },
sub { ok( test_char_data_esc( "]", ">" ), "]&gt;"         ) },
sub { ok( test_char_data_esc( "]]", ">" ),"]]&gt;"        ) },
sub { ok( test_char_data_esc( "]]>"    ), "]]&gt;"        ) },
sub { ok( test_char_data_esc( "]]>]]>" ), "]]&gt;]]&gt;"  ) },
sub { ok( test_char_data_esc( "a>" ),     "a>"            ) },
sub { ok( test_char_data_esc( "a]>" ),    "a]>"           ) },
sub { ok( test_char_data_esc( "a]>" ),    "a]>"           ) },
sub { ok( test_char_data_esc( "\t"      ), "\t", "\\t, 0x09, ^I, TAB" ) },
sub { ok( test_char_data_esc( "\n"      ), "\n", "\\n, 0x0A, ^J, NL"  ) },
sub { ok( test_char_data_esc( "\r"      ), "\r", "\\r, 0x0D, ^M, CR"  ) },

## Throw in a bunch of oddball characters and see what happens
(
   map {
      my $ord = $_ ;
      my $char = chr( $ord ) ;
      ( 
	 sub {
	    eval { test_char_data_esc( $char ) } ;
	    ## Older dists of perl don't know about qr// passed to ok():
	    if ( $@ && $@ =~ /invalid char/i ) {
	       ok( 1 ) ;
	    }
	    else {
	       ok( $@, "invalid char", sprintf( "0x%02x", $ord ) )
	    }
	 },
	 sub {
	    eval { test_cdata_esc( $char ) } ;
	    ## Older dists of perl don't know about qr// passed to ok():
	    if ( $@ && $@ =~ /invalid char/i ) {
	       ok( 1 ) ;
	    }
	    else {
	       ok( $@, "invalid char", sprintf( "0x%02x", $ord ) )
	    }
	 },
      )
   } ( 0..0x08, 0x0b, 0x0c, 0x0e..0x1f )
),

##
## CDATA escape mode tests
##
sub { ok( test_cdata_esc( "]]>"     ), "]]]]><![CDATA[>" ) },
sub { ok( test_cdata_esc( "]]>"     ), "]]]]><![CDATA[>" ) },
sub { ok( test_cdata_esc( "]]", ">" ), "]]]]><![CDATA[>" ) },
sub { ok( test_cdata_esc( "]", "]>" ), "]]]]><![CDATA[>" ) },
sub { ok( test_cdata_esc( "\t"      ), "\t", "\\t, 0x09, ^I, TAB" ) },
sub { ok( test_cdata_esc( "\n"      ), "\n", "\\n, 0x0A, ^J, NL"  ) },
sub { ok( test_cdata_esc( "\r"      ), "\r", "\\r, 0x0D, ^M, CR"  ) },

sub {
   package Foo ;
   $buf = '' ;
   defaultWriter()->reset ;
   select_xml( \$buf ) ;
   ## The extra ()'s are necessary because we didn't import at compile time.
   xmlDecl() ;
   start_a()  ;
   ## Kick us in to CDATA mode, but with a closing ']'
   characters( "<<<<<]" ) ;
   b() ;
   end_a()    ;
   $buf =~ s{.*<a><!\[CDATA\[<<<<<}{}sg ;
   $buf =~ s{<b />.*}{}sg ;
   $buf =~ s{\]\]>}{}sg ;
   ok( $buf, "]" ) ;
   return $buf ;
},
) ;

plan tests => scalar @tests ;

## Do this after planing so that the test harness can see that we 
## started, then failed.
use XML::ValidWriter qw( :all ) ;

$_->() for @tests ;

