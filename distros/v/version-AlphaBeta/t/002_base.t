# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More qw(no_plan);
BEGIN { use_ok('version::AlphaBeta') };

diag "Tests with base class" unless $ENV{PERL_CORE};
BaseTests("version::AlphaBeta");

#########################

package version::AlphaBeta::Empty;
use vars qw($VERSION);
use base qw(version::AlphaBeta);
$VERSION = 0.01;

package main;
diag "Tests with empty derived class" unless $ENV{PERL_CORE};
BaseTests("version::AlphaBeta::Empty");

sub BaseTests {

    my $class = shift;

    my $v = $class->new("1.2a");
    is ("1.2a","$v", "Alpha: [$v]");
    is ("1.2a", $v, "1.2a eq Alpha");
    ok ("1.2a" == $v, "1.2a == Alpha");
    ok ($v->is_alpha, "$v->is_alpha");
    is ($v->numify, "1.199997", "alpha->numify");
    
    my $v2 = $class->new("1.2b");
    is ("1.2b", "$v2", "Beta: [$v]");
    is ("1.2b", $v2, "1.2b eq Beta");
    ok ("1.2b" == $v2, "1.2b == Beta");
    ok ($v2->is_beta, "$v->is_beta");
    ok ($v2 > $v, "beta > alpha");
    is ($v2->numify, "1.199998", "beta->numify");

    $v = $v2; # save this for next round of testing
    
    $v2 = $class->new("1.2rc");
    is ("1.2rc", "$v2", "Release candidate: [$v2]");
    is ($v2->numify, "1.199999", "rc->numify");
    ok ($v2 > $v, "rc > beta");
    
    $v = $v2; # save this for next round of testing
    
    $v2 = $class->new("1.2");
    is ("1.2", "$v2", "Release: [$v]");
    ok ("1.2a" < $v2 , "Alpha < Release");
    is ($v2->numify, "1.200000", "v->numify");
    
    ok ( $v2 > $v , "Release > Release Candidate ");
    
    eval { my $v3 = $class->new("nothing") };
    like($@, qr/Illegal version string format/, substr($@,0,index($@," at ")) );
    eval { my $v3 = $class->new("1.2.3") };
    like($@, qr/Illegal version string format/, substr($@,0,index($@," at ")) );

    # reported by Bhavesh Jardosh <perltastic@gmail.com>
    isnt ( $v2, undef, "comparison with undef" );
    isnt ( $v2, 'nothing', "comparison with string" );
    isnt ( $v2, '1.2.3', "comparison with illegal version format" );
 }
