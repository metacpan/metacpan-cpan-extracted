use Test::More tests => 13;
use t::TestCase_i qw ( getmask $expect_i );
use t::TestCase_ii qw ( $expect_ii );

sub testit
{
    my $expect=shift;
    my $got=getmask(@_);
    is ($expect->expectvalue(@_), $got , (join ' | ',@_).' = '.$got);
}

testit $expect_i,qw(i_alfa i_delta);
testit $expect_i,qw(i_gamma i_rho);
testit $expect_i,qw(i_alfa i_beta i_gamma i_delta );
testit $expect_i,qw(i_beta i_eps i_detha);
testit $expect_i, qw(i_fi i_psi);

# print '-'x66,"\n";

testit $expect_ii,qw(ii_alfa ii_delta);
testit $expect_ii,qw(ii_gamma ii_rho);
testit $expect_ii,qw(ii_alfa ii_beta ii_gamma ii_delta );
testit $expect_ii,qw(ii_beta ii_eps ii_detha);
testit $expect_ii, qw(ii_fi ii_psi);
testit $expect_ii, qw(ii_chi);
testit $expect_ii, qw(ii_zeta);

testit $expect_ii, qw(ii_gamma ii_runaway ii_dummy ii_alfa);