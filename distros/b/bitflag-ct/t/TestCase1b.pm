package t::TestCase1b;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw ( getmask $expectB );
our @EXPORT = qw( );
our $VERSION = 0.01;

use t::TestHelp;

our $expectB = new t::TestHelp
qw(
    mercury 8 venus 16 earth 32 mars 64 jupiter 2  saturn 4 uranus 8 neptune 16
    pluto 256 sedna 512 ida 1024 eros 2048
  );

use bitflag::ct {ic=>1,sm=>8}, qw( mercury venus earth mars );
use bitflag::ct {sm=>2}, qw( JUPITER SATURN URANUS NEPTUNE );
use bitflag::ct 256, qw( pluto sedna ida eros );


1;