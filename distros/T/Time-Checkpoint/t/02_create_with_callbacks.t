use Test::More qw{ no_plan };

use_ok( 'Time::Checkpoint' );

our $first = 1;

sub a_sub {
	ok( 1, "callback was called" );
	my ($cp, $ot, $nt) = (@_);
	ok( $cp eq 'pie', "checkpoint was conveyed" );
	unless ($first) {
		ok( defined $ot, "time has value" );
	}
	ok( defined $nt, "new timestamp has value" );
	if (not $first) { ok( $nt > $ot, "new timestamp came from the future" ) }
}

my $t = Time::Checkpoint->new( callback => \&a_sub );

ok( $t, "object created" );
ok( ref $t eq 'Time::Checkpoint', "object is what we expected" );

# We need to call it once to set up the rest of our tests.
$t->checkpoint( 'pie' );
$first = 0;
ok( $t->checkpoint( 'pie' ), "called checkpoint" );
sleep 1;
my $delta = $t->checkpoint( 'pie' );
ok( defined $delta, "delta returned" );
ok( $delta > 1, "delta was big enough" );

# jaa // vim:tw=80:ts=2:noet:syntax=perl
