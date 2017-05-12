package t::TestCase_ii;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw ( getmask $expect_ii );
our @EXPORT = qw( );
our $VERSION = 0.01;

use t::TestHelp;

our $expect_ii = new t::TestHelp
qw(
    mercury 8 ii_beta 16 ii_gamma 32 ii_delta 64 ii_eps 2 ii_fi 4 ii_detha 8 ii_psi 16
    ii_rho 256 ii_chi 512 ii_zeta 1024 ii_omega 2048
  );

use bitflag {sm=>8},qw(mercury ii_beta ii_gamma ii_delta );
use bitflag {sm=>2}, qw( II_Eps II_Fi II_Detha II_Psi );
use bitflag 256, qw( ii_rho  ii_chi ii_zeta ii_omega );


1;