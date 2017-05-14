# $Id: xml.pm,v 1.2 2012/05/15 21:26:30 pfeiffer Exp $
use strict;
package Mpp::Signature::xml;

use utf8;
use Mpp::Signature::md5;

our @ISA = qw(Mpp::Signature);

=head1 NAME

Mpp::Signature::xml -- a signature class that ignores insignificant changes and comments

=head1 DESCRIPTION

This signature method signs the essence of an xml document.  Quoting style and
order of attributes are ignored, as is the way empty tags are represented and
whether special characters are protected as entities or in a CDATA section.

Whitespace around tags is ignored completely whereas any whitespace elsewhere
is considered as just one space.  This is usually the right thing to do for
config files, but if you don't want that, use xml-space instead.

=cut

our $xml = bless \@ISA;		# Make the singleton object.

our $libxml;			# Which one did we find?  Can be preset.

eval 'use XML::Parser' unless $libxml;
if( $@ || $libxml ) {
  eval 'use XML::LibXML';	# Try another lib
  if( $@ ) {
    Mpp::log USE_FAIL => 'XML::Parser or XML::LibXML';
    $xml = $Mpp::Signature::md5::md5; # Fall back.
  } else {
    $libxml = 1;
  }
}



our $space;			# Is whitespace important?

# expect	tag => [{attrs}, tag, content, ...]
sub flatten {
  my $res = "\cA$_[0]";
  for my $attr ( sort keys %{$_[1][0]} ) {
    $res .= "\cB$attr\cC$_[1][0]{$attr}";
  }
  for( my $i = 1; $i < @{$_[1]}; $i += 2 ) {
    if( $_[1][$i] ) {
      $res .= flatten( $_[1][$i], $_[1][$i+1] );
    } else {
      my $str = $_[1][$i+1];
      if( $space ) {
	$res .= "\cD$str";
      } else {
	$str =~ s/\A\s+//;
	$str =~ s/\s+\Z//;
	$str =~ s/\s+/ /;
	$res .= "\cD$str" if length $str;
      }
    }
  }
  "$res\cZ";
}

sub signature {
  my $finfo = $_[1];		# Name the argument.
  local $space = 1 if ref( $_[0] ) =~ /xml_space/;
  my $key = $space ? 'XML_SPACE_MD5_SUM' : 'XML_MD5_SUM';
  my $sum = Mpp::File::build_info_string $finfo, $key;

  unless( $sum ) {	       # Don't bother resumming if we know the answer.
    my $fname = Mpp::File::absolute_filename $finfo;
    my $doc =
      eval { $libxml ?
	       XML::LibXML->load_xml( location => $fname ) :
	       XML::Parser->new( Style => 'Tree' )->parsefile( $fname ) };
    if( $@ ) {			 # Not valid xml.
      $@ =~ tr/\n//d;
      Mpp::log ERROR => $finfo, $@, 'falling back to md5';
      $sum = Mpp::Signature::md5::signature $finfo;
    } else {
      my $str = $libxml ? $doc->toStringEC14N : flatten @$doc;
      if( $libxml && !$space ) {
	$str =~ s/\s+/ /g;
	$str =~ s/> />/g;
	$str =~ s/ </</g;
      }
      utf8::encode $str if utf8::valid $str; # MD5 complains about wide chars
      $sum = Digest::MD5::md5_base64 $str;
      Mpp::File::set_build_info_string $finfo, $key, $sum;
    }
  }
  $sum;
}

1;
