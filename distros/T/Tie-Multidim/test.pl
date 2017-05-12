# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use lib 'lib';
BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tie::Multidim;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):




use strict;

my %stor;

sub Foo::TIEHASH {
	my $pkg = shift;
	bless \%stor, $pkg;
}

sub Foo::FETCH {
	my( $self, $index ) = @_;
	my( $i, $k ) = split $;, $index;
	$self->{ $k }[ $i ]
}

sub Foo::STORE {
	my( $self, $index, $value ) = @_;
	my( $i, $k ) = split $;, $index;
	$self->{ $k }[ $i ] = $value
}

@Subclass::ISA = qw(Tie::Multidim);
$; = "/";
my %foo;
tie %foo, 'Foo';
my $m = new Subclass \%foo, '@%'; # array of hashes

$m->[666]{'Zaphod'} = 42;
print( $m->[666]{'Zaphod'} == 42 ? "ok 2\n" : "not ok 2\n" );
print( $foo{'666/Zaphod'} == 42 ? "ok 3\n" : "not ok 3\n" );
print( $stor{'Zaphod'}[666] == 42 ? "ok 4\n" : "not ok 4\n" );

exit 0;

