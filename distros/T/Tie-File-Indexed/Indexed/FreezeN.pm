##-*- Mode: CPerl -*-
##
## File: Tie/File/Indexed/FreezeN.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: tied array access to indexed data files: Storable-frozen references (network byte-order)

package Tie::File::Indexed::FreezeN;
use Tie::File::Indexed::Freeze;
use Storable;
use strict;

##======================================================================
## Globals

our @ISA = qw(Tie::File::Indexed::Freeze);

##======================================================================
## Subclass API: Data I/O: overrides

## $bool = $tfi->writeData($data)
##  + override transparently encodes data using Storable::nfreeze()
sub writeData {
  return 1 if (!defined($_[1])); ##-- don't waste space on undef
  return $_[0]{datfh}->print( Storable::nfreeze($_[1]) );
}

## $data_or_undef = $tfi->readData($length)
##  + inherited method from Tie::File::Indexed::Freeze transparently decodes data using Storable::thaw()


1; ##-- be happpy
