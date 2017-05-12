# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
#use strict;

use vars qw($Total_tests);

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use Tie::Math;
$loaded = 1;
ok(1, 'compile');
######################### End of black magic.

# Utility testing functions.
sub ok {
    my($test, $name) = @_;
    print "not " unless $test;
    print "ok $test_num";
    print " - $name" if defined $name;
    print "\n";
    $test_num++;
}

sub eqarray  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    my $ok = 1;
    for (0..$#{$a1}) { 
        unless($a1->[$_] eq $a2->[$_]) {
        $ok = 0;
        last;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 10 }

my %fibo;
tie %fibo, 'Tie::Math', sub { f(N) = f(N-1) + f(N-2) },
                               sub { f(0) = 1;  f(1) = 1; };

ok( $fibo{0} == 1 and $fibo{1} == 1,    'fibo init' );
ok( $fibo{3} == 3,                      'fibo recursive' );


tie %exp, 'Tie::Math', sub { f(N) = N ** 2 };

ok( $exp{9} == 81,                      'simple exponential' );
ok( $exp{0} == 0  );
ok( $exp{-2} == 4 );


use Tie::Math qw(f X Y M A);

my %multi_var;
tie %multi_var, 'Tie::Math', sub { f(X,Y) = X + Y };

ok( $multi_var{1,2} == 3,       'basic multi-variable' );


my %force;
tie %force, 'Tie::Math', sub { f(M,A) = M * A };

ok( $force{10,10} == 100,       'force == mass * acceleration' );


my %pascal;
tie %pascal, 'Tie::Math', sub { 
                              if( X <= Y and Y > 0 and X > 0 ) {
                                  f(X,Y) = f(X-1,Y-1) + f(X,Y-1);
                              }
                              else {
                                  f(X,Y) = 0;
                              }
                          },
                          sub { f(1,1) = 1;  f(1,2) = 1;  f(2,2) = 1; };

ok( $pascal{2,3} == 2,                "Pascal's Triangle" );
ok( $pascal{3,5} == 6);
