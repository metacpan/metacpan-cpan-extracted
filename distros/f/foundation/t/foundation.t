# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
use strict;

use vars qw($Total_tests);

my $loaded;
my $test_num = 1;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use foundation;
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
        my($e1,$e2) = ($a1->[$_], $a2->[$_]);
        unless($e1 eq $e2) {
            if( UNIVERSAL::isa($e1, 'ARRAY') and 
                UNIVERSAL::isa($e2, 'ARRAY') ) 
            {
                $ok = eqarray($e1, $e2);
            }
            else {
                $ok = 0;
            }
            last unless $ok;
        }
    }
    return $ok;
}

# Change this to your # of ok() calls + 1
BEGIN { $Total_tests = 10 }

package Foo;

use vars qw($Walla_Walla);
$Walla_Walla = "Washington";
sub fooble { 42 }

package Bar;

sub mooble { 23 }
sub hooble { 13 }

package FooBar;
use foundation;
foundation(qw(Foo Bar));

::ok( fooble() == 42 );
::ok( mooble() == 23 );

sub hooble { 31 }

::ok( hooble == 31 );
::ok( SUPER('hooble') == 13 );
::ok( $FooBar::Walla_Walla and $FooBar::Walla_Walla eq 'Washington' );

package Moo;
use foundation;
foundation qw(FooBar);

::ok( hooble() == 31 );
::ok( fooble() == 42 );
::ok( mooble() == 23 );
::ok( $Moo::Walla_Walla and $Moo::Walla_Walla eq 'Washington' );
