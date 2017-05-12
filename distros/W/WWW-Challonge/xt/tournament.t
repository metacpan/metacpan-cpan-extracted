#!perl -T
use strict;
use warnings;
use WWW::Challonge;
use Test::More tests => 8;

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge::Tournament") || BAIL_OUT();
}

diag("Testing WWW::Challonge::Tournament $WWW::Challonge::Tournament::VERSION, Perl $], $^X");

SKIP:
{
	skip "Requires 'key' file with API key to run xt tests", 1
		unless( -f "xt/key");

	open my $file, '<', "xt/key" or die "Error: Cannot open key file: $!";
	chomp(my $key = <$file>);

	# Create a new tournament to test:
	my $c = WWW::Challonge->new($key);
	my $url = "";
	my @chars = ("a".."z", "A".."Z", "_");
	$url .= $chars[rand @chars] for(1..20);
	my $test = $c->new_tournament({
		name => "Perl Test",
		url => $url,
	});

	isa_ok($test, "WWW::Challonge::Tournament");

	# Test the attributes work:
	subtest "attributes work" => sub
	{
		is($test->attributes->{name}, "Perl Test",
			"Tournament name is 'Perl Test'");
		ok($test->attributes->{created_by_api},
			"Tournament is created by API");
	};

	# Test updating the tournament works:
	subtest "update works" => sub
	{
		ok($test->update({ game_name => "Perl" },
			"Game name update ok"));
		is($test->attributes->{game_name}, "Perl",
			"Game name is 'Perl'");
	};

	# Create two participants (participants are tested in 'participant.t'):
	$test->new_participant({ name => $_ }) for(1..2);

	# Test we can start, finalise and reset a tournament:
	subtest "start works" => sub
	{
		ok($test->start, "Tournament started ok");
		is($test->attributes->{state}, "underway",
			"Tournament status set to 'underway'");
	};

	# Complete the match between the two players (matches are tested in
	# 'match.t'):
	$test->matches->[0]->update(["1-0"]);

	subtest "finalize works" => sub
	{
		ok($test->finalize, "Tournament finalised ok");
		is($test->attributes->{state}, "complete",
			"Tournament status set to 'complete'");
	};

	subtest "reset works" => sub
	{
		ok($test->reset, "Tournament reset ok");
		is($test->attributes->{state}, "pending",
			"Tournament status set to 'pending'");
	};

	# Check we can destroy a tournament:
	subtest "destroy works" => sub
	{
		ok($test->destroy, "Tournament destroyed ok");
		eval { $test->update({ name => "foo" }); } or my $at = $@;
		like($at, qr/Tournament has been destroyed/, "Dies on attempting to
			update destroyed tournament");
	};
	done_testing();
}
