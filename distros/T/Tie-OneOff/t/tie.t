#!./perl

use strict;
use warnings;

print "1..6\n";

my $testno;

sub t ($) {
    print "not " unless shift;
    print "ok ",++$testno,"\n";
}

require Tie::OneOff;

tie my %REV, 'Tie::OneOff' => {
    FETCH => sub { reverse shift },
};

t ($REV{olleH} eq 'Hello' );

my $rev2 = Tie::OneOff->hash( sub {
    reverse shift;
});

t ($rev2->{olleH} eq 'Hello' );


sub make_counter {
    my $step = shift;
    my $i = 0;
    tie my $counter, 'Tie::OneOff' => {
	BASE => \$i, # Implies: STORE => sub { $i = shift }
	FETCH => sub { $i += $step },
    };
    \$counter;
}

sub make_counter2 {
    my $step = shift;
    my $i = 0;
    Tie::OneOff->scalar({
	BASE => \$i, # Implies: STORE => sub { $i = shift }
	FETCH => sub { $i += $step },
    });
}


my $c1 = make_counter(1);
my $c2 = make_counter2(2);

$$c2 = 10;
t("X $$c1 $$c2 $$c2 $$c2 $$c1 $$c1" eq 'X 1 12 14 16 2 3');

my $internal;

sub lv : lvalue {
    Tie::OneOff->lvalue({
	FETCH => sub { 55 },
	STORE => sub { $internal = shift },
    });
}

t(lv == 55);
lv = 44;
t($internal == 44);

my @a_internal;

my $a = Tie::OneOff->array({
    BASE => \@a_internal,
    STORE => sub {
	$a_internal[$_[0]] = $_[1] + 1;
    },
}); 

$a->[1] = 44;
t( $a->[1] == 45 );			   

