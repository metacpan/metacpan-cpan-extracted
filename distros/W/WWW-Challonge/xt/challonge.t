#!perl -T
use strict;
use warnings;
use Test::More tests => 5;

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge") || BAIL_OUT();
}

diag("Testing WWW::Challonge $WWW::Challonge::VERSION, Perl $], $^X");

SKIP:
{
	skip "Requires 'key' file with API key to run xt tests", 1
		unless( -f "xt/key");

	open my $file, '<', "xt/key" or die "Error: Cannot open key file: $!";
	chomp(my $key = <$file>);

	# Test we can create a new object with a valid API key:
	my $test;
	subtest "new works" => sub
	{
		$test = new_ok("WWW::Challonge" => [ $key ]);
		eval { my $test2 = WWW::Challonge->new("foo"); } or my $at = $@;
		like($at, qr/Invalid API key/, "Dies on bad API key");
	};

	# Test we can get an arrayref of all the user's tournaments:
	subtest "tournaments works" => sub
	{
		my $tournaments = $test->tournaments;
		is(ref $tournaments, "ARRAY", "Returned value is arrayref");
		for my $tournament(@{$tournaments})
		{
			isa_ok($tournament, "WWW::Challonge::Tournament");
		}
	};

	# Test a specific tournament (we test the specific attributes in
	# tournament.t):
	my $tournament = $test->tournament("perl_test_1");
	isa_ok($tournament, "WWW::Challonge::Tournament");

	# Tests we can create a tournament:
	my $url = "";
	my @chars = ("a".."z", "A".."Z", "_");
	$url .= $chars[rand @chars] for(1..20);
	my $new = $test->new_tournament({
		name => "Perl Test",
		url => $url,
	});	
	isa_ok($new, "WWW::Challonge::Tournament");

	# Destroy the tournament we just made so we don't clog up the account:
	$new->destroy;
	done_testing();
}
