# Attention !
# this file is used only during make test on installation of bitflag::ct
# it shoul have been removed  finally
#
package t::TestCase1a;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw ( getmask $expectA );
our @EXPORT = qw( );
our $VERSION = 0.01;

use t::TestHelp;

our $expectA = new t::TestHelp
qw(
    mercury 1 venus 2 earth 4 mars 8 jupiter 16  saturn 32 uranus 64 neptune 128 pluto 256 sedna 512
  );


use bitflag::ct {ic=>1}, qw( mercury venus earth mars );
use bitflag::ct qw( JUPITER SATURN URANUS NEPTUNE );
use bitflag::ct qw( pluto sedna );

1;