##-*- Mode: CPerl -*-
##
## File: Tie/File/Indexed/Freeze.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: tied array access to indexed data files: Storable-frozen references (native byte-order)

package Tie::File::Indexed::Freeze;
use Tie::File::Indexed;
use Storable;
use strict;

##======================================================================
## Globals

our @ISA = qw(Tie::File::Indexed);

##======================================================================
## Subclass API: Data I/O: overrides

## $bool = $tfi->writeData($data)
##  + override transparently encodes data using Storable::freeze()
sub writeData {
  return 1 if (!defined($_[1])); ##-- don't waste space on undef
  return $_[0]{datfh}->print( Storable::freeze($_[1]) );
}

## $data_or_undef = $tfi->readData($length)
##  + override transparently decodes data using Storable::thaw()
sub readData {
  return undef if ($_[1]==0 || !defined(my $buf=$_[0]->SUPER::readData($_[1])));
  return Storable::thaw($buf);
}


1; ##-- be happpy
