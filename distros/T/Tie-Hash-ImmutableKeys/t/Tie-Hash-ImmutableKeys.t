# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-Hash-ImmutableKeys.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok( 'Tie::Hash::ImmutableKeys' ) }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#use Data::Dumper;
#
#
my $z = { aze => 100, tyuiop => 333, qsdfg => 987 };
my $f = { A   => 0,   Z      => 1,   E     => 0, L => $z };
my $a = { a   => 0,   z      => 1,   e     => 1, r => 1, AA => $f };
#
my $list = {
    S => $a,
    F => $f,
    P => "leaf"
};

my %a;
tie( %a, 'Tie::Hash::ImmutableKeys', $list );
my $ar = 'e';
cmp_ok( defined( $a{ S }->{ $ar } = 1111 ), '==', 1, "Modification of an non existing key" );

$ar = 'p';
eval { $a{ S }->{ $ar } = 1111 };

if ( $@ )
{
    my $res = $@ =~ /COULD NOT DELETE/;
    cmp_ok( $res, '==', 1, "Modification of an existing key" );
}

