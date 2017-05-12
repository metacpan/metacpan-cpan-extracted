##-*- Mode: CPerl -*-
##
## File: Tie/File/Indexed/Utf8.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: tied array access to indexed data files: utf8-encoded strings


package Tie::File::Indexed::Utf8;
use Tie::File::Indexed;
use utf8;
use strict;

##======================================================================
## Globals

our @ISA = qw(Tie::File::Indexed);

##======================================================================
## Subclass API: Data I/O: overides

## $bool = $tfi->writeData($utf8_string)
##  + override transparently encodes $data as utf8
sub writeData {
  my $val = $_[1];
  if (defined($val)) {
    utf8::upgrade($val) if (!utf8::is_utf8($val)); ##-- convert byte-strings to utf8
    utf8::encode($val);                            ##-- ... but write (encoded) byte-strings
  }
  return $_[0]{datfh}->print($val//'');
}

## $data_or_undef = $tfi->readData($length)
##  + read item data from $tfi->{datfh} from its current position
##  + returned scalars should always have their utf8 flag set
sub readData {
  defined(my $buf = $_[0]->SUPER::readData($_[1])) or return undef;
  utf8::decode($buf);
  return $buf;
}


1; ##-- be happpy
