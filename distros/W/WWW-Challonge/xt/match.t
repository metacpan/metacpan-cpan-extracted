#!perl -T
use strict;
use warnings;
use WWW::Challonge;
use Test::More tests => 4;

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge::Participant") || BAIL_OUT();
}

diag("Testing WWW::Challonge::Participant $WWW::Challonge::Participant::VERSION, Perl $], $^X");

SKIP:
{
	skip "Requires 'key' file with API key to run xt tests", 1
		unless( -f "xt/key");

	open my $file, '<', "xt/key" or die "Error: Cannot open key file: $!";
	chomp(my $key = <$file>);

	# Create a new tournament and two participants:
	my $c = WWW::Challonge->new($key);
	my $url = "";
	my @chars = ("a".."z", "A".."Z", "_");
	$url .= $chars[rand @chars] for(1..20);
	my $t = $c->new_tournament({
		name => "Perl Test",
		url => $url,
	});
	my $p1 = $t->new_participant({ name => "alice" });
	my $p2 = $t->new_participant({ name => "bob" });
	$t->start;

	# Test the index works:
	my $test;
	subtest "index works" => sub
	{
		my $matches = $t->matches;
		is(@{$matches}, 1, "Index gives one match");
		isa_ok($matches->[0], "WWW::Challonge::Match");
		$test = $matches->[0];
	};

	# Test attributes:
	subtest "attributes work" => sub
	{
		is($test->attributes->{player1_id}, $p1->attributes->{id},
			"Player 1 id matches");
		is($test->attributes->{player2_id}, $p2->attributes->{id},
			"Player 2 id matches");
	};

	# Test updating scores works:
	subtest "updating scores works" => sub
	{
		ok($test->update(["2-1"]), "Match updates ok");
		is($test->attributes->{winner_id}, $p1->attributes->{id},
			"Player 1 is the winner");
	};
	$t->destroy;
	done_testing();
}
