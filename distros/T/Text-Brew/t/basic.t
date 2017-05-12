my @tests;
BEGIN {
	my $test_data = <<'EOT';
foo foo 0 INITIAL,MATCH,MATCH,MATCH
foo bar 3 INITIAL,SUBST,SUBST,SUBST
foo foobar 3 INITIAL,MATCH,MATCH,MATCH,INS,INS,INS
foobar foo 3 INITIAL,MATCH,MATCH,MATCH,DEL,DEL,DEL
abcd bcd 1 INITIAL,DEL,MATCH,MATCH,MATCH
bcd abcd 1 INITIAL,INS,MATCH,MATCH,MATCH
abde abcde 1 INITIAL,MATCH,MATCH,INS,MATCH,MATCH
abcde abde 1 INITIAL,MATCH,MATCH,DEL,MATCH,MATCH
EOT
	for ( split /\n/, $test_data ) {
		next unless /\S/ and !/^\s*\#/;
		my @r = split ' ';
		@r == 4 or die "Invalid DATA line";
		push @tests, {
			arg1 => $r[0],
			arg2 => $r[1],
			distance => $r[2],
			edits => [ split /,/, $r[3] ],
		};
	}
}

use Test::More tests => 2 * @tests;

use Text::Brew qw( distance );

for my $t (@tests) {
	my($distance, $edits) = distance( $t->{arg1}, $t->{arg2} );
	is($distance, $t->{distance}, "$t->{arg1}-$t->{arg2} distance");
	is_deeply($edits, $t->{edits}, "$t->{arg1}-$t->{arg2} edits");
}
