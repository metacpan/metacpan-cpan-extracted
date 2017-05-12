##-*- Mode: CPerl -*-
##
## File: Tie/File/Indexed/StorableN.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: tied array access to indexed data files: Storable-encoded references (network byte-order)

package Tie::File::Indexed::StorableN;
use Tie::File::Indexed::Storable;
use Storable;
use strict;

##======================================================================
## Globals

our @ISA = qw(Tie::File::Indexed::Storable);

##======================================================================
## Subclass API: Data I/O: overrides

## $bool = $tfi->writeData($utf8_string)
##  + override transparently encodes $data using Storable::nstore_fd()
sub writeData {
  return 1 if (!defined($_[1])); ##-- don't waste space on undef
  return Storable::nstore_fd($_[1],$_[0]{datfh});
}


1; ##-- be happpy
