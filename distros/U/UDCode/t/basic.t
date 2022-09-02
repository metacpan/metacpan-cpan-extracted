use strict; use warnings;
use UDCode;
use Test::More;
BEGIN { eval { require Test::Differences } ? Test::Differences->import : ( *eq_or_diff = \&is_deeply ) }

my @case = (
	[ [qw(b ab abba)] => [qw(abba b)], [qw(ab b ab)] ],
	[ [qw(a ab b)]    => [qw(a b)],    [qw(ab)] ],
	[ [qw(a ab ba)]   => [qw(ab a)],   [qw(a ba)] ],
	[ [qw(ab ba)] ],
	[ [qw(a b)] ],
	[ [qw(aab ab b)] ],

	# not a prefix code:
	[ [qw(a ab)] ],

	# trivial:
	[ [qw(a)] ],
	[ [qw(a a)] ],
	[ [qw(a a a)] ],

	# redundant code words (should be ignored):
	[ [qw(a ab ba a)]    => [qw(ab a)],   [qw(a ba)] ],
	[ [qw(b ab ab abba)] => [qw(abba b)], [qw(ab b ab)] ],
	[ [qw(ab ba ba)] ],
	[ [qw(a b b)] ],
	[ [qw(a b b a)] ],
	[ [qw(a b c d e f g)] ],
	[ [qw(a b c d e f g abcdefg)] => [qw(a b c d e f g)], [qw(abcdefg)] ],
);

plan tests => 3 * @case;

for my $expect (@case) {
	my $c = shift @$expect;

	my @got = ud_pair(@$c);

	eq_or_diff \@got, $expect, @$expect
		? "{@$c} ?? {@{$$expect[0]}} == {@{$$expect[1]}}"
		: "{@$c} ?? ¯\\_(ツ)_/¯";

	my @union;
	if ( eval { @union = map @$_, @got; 1 } ) {
		my %got = map +( $_ => 1 ), @union;
		delete @got{ @$c };
		eq_or_diff \%got, {}, "{@$c} >= {@union}";
	} else {
		fail 'should never happen';
	}

	is is_udcode(@$c), !@$expect, "{@$c} :: is_udcode() == !ud_pair()";
}
