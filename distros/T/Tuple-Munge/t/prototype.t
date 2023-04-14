use warnings;
use strict;

use Test::More tests => 11;

BEGIN {
	use_ok "Tuple::Munge", qw(
		pure_tuple constant_tuple variable_tuple
		tuple_mutable tuple_length tuple_slot tuple_slots
		tuple_set_slot tuple_set_slots tuple_seal
	);
}

my @want;
sub w0 {
	$want[0] = wantarray ? "list" : defined(wantarray) ? "scalar" : "void";
	return $_[0];
}
sub w1 {
	$want[1] = wantarray ? "list" : defined(wantarray) ? "scalar" : "void";
	return $_[0];
}
sub w2 {
	$want[2] = wantarray ? "list" : defined(wantarray) ? "scalar" : "void";
	return $_[0];
}

@want = ();
pure_tuple(w0(\3), w1([]));
is_deeply \@want, [qw(list list)];
@want = ();
constant_tuple(w0(\3), w1([]));
is_deeply \@want, [qw(list list)];
@want = ();
variable_tuple(w0(\3), w1([]));
is_deeply \@want, [qw(list list)];

my $tt0 = variable_tuple(\3, []);
@want = ();
tuple_mutable(w0($tt0));
is_deeply \@want, [qw(scalar)];
@want = ();
tuple_length(w0($tt0));
is_deeply \@want, [qw(scalar)];
@want = ();
tuple_slot(w0($tt0), w1(1));
is_deeply \@want, [qw(scalar scalar)];
@want = ();
tuple_slots(w0($tt0));
is_deeply \@want, [qw(scalar)];

my $tt1 = variable_tuple(\3, []);
@want = ();
tuple_set_slot(w0($tt1), w1(1), w2(\2));
is_deeply \@want, [qw(scalar scalar scalar)];
@want = ();
tuple_set_slots(w0($tt1), w1({}), w2(sub {}));
is_deeply \@want, [qw(scalar list list)];
@want = ();
tuple_seal(w0($tt1));
is_deeply \@want, [qw(scalar)];

1;
