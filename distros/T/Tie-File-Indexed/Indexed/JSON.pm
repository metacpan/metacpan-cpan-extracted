##-*- Mode: CPerl -*-
##
## File: Tie/File/Indexed/JSON.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: tied array access to indexed data files: JSON-encoded data structures

package Tie::File::Indexed::JSON;
use Tie::File::Indexed;
use JSON;
use strict;

##======================================================================
## Globals

our @ISA = qw(Tie::File::Indexed);

##======================================================================
## Constructors etc.

## $tfi = CLASS->new(%opts)
## $tfi = CLASS->new($file,%opts)
##  + new %opts, object structure:
##    (
##     json => $json,      ##-- JSON object or HASH-ref of options
##    )

## \%defaults = CLASS_OR_OBJECT->defaults()
##  + default attributes for constructor
sub defaults {
  return (
	  $_[0]->SUPER::defaults,
	  json => {utf8=>1, relaxed=>1, allow_nonref=>1, allow_unknown=>1, allow_blessed=>1, convert_blessed=>1, pretty=>0, canonical=>0},
	 );
}

##--------------------------------------------------------------
## Utilities: JSON

## $json = $aj->json()
##   + returns json codec
sub json {
  return $_[0]{json} if (UNIVERSAL::isa($_[0]{json}, 'JSON'));
  my $json = JSON->new;
  foreach (grep {$json->can($_)} keys %{$_[0]{json}//{}}) {
    $json->can($_)->($json,$_[0]{json}{$_});
  }
  return $_[0]{json} = $json;
}

##======================================================================
## Object API: overrides

##--------------------------------------------------------------
## Object API: overrides: open/close

## $tfi_or_undef = $tfi->open($file,$mode)
## $tfi_or_undef = $tfi->open($file)
## $tfi_or_undef = $tfi->open()
##  + opens file(s)
sub open {
  my $tfi = shift;
  return undef if (!$tfi->SUPER::open(@_));

  ##-- ensure 'json' object is defined
  $tfi->json();
  return $tfi;
}

##======================================================================
## Subclass API: Data I/O

## $bool = $tfi->writeData($utf8_string)
##  + override transparently encodes $data using the JSON module
sub writeData {
  return 1 if (!defined($_[1])); ##-- don't waste space on undef
  return $_[0]{datfh}->print( $_[0]{json}->encode($_[1]) );
}

## $data_or_undef = $tfi->readData($length)
##  + override decodes stored data using the JSON module
sub readData {
  return undef if ($_[1]==0 || !defined(my $buf=$_[0]->SUPER::readData($_[1])));
  return $_[0]{json}->decode($buf);
}


1; ##-- be happpy
