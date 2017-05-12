# Attention !
# this file is used only during make test on installation of bitflag
# it shoul have been removed  finally
#
package t::TestCase_i;

use 5.008007;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw ( getmask $expect_i );
our @EXPORT = qw( );
our $VERSION = 0.01;

use t::TestHelp;

our $expect_i = new t::TestHelp
qw(
    i_alfa 1 i_beta 2 i_gamma 4 i_delta 8 i_eps 16 i_fi 32 i_detha 64 i_psi 128 i_rho 256
  );

=pod
$expect_i->printexpect(qw(i_alfa i_beta i_gamma i_delta i_eps i_fi  i_detha i_psi i_rho));
=cut

use bitflag {ic=>1}, qw( i_alfa i_beta i_gamma i_delta );
use bitflag qw( I_EPS I_FI I_DETHA I_PSI );
# use bitflag qw( i_eps i_fi i_detha i_psi );
use bitflag qw( i_rho );

1;