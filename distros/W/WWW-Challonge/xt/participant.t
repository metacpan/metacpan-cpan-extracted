#!perl -T
use strict;
use warnings;
use WWW::Challonge;
use Test::More tests => 6;
use Test::Deep;

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

	# Create a new tournament and participant to test:
	my $c = WWW::Challonge->new($key);
	my $url = "";
	my @chars = ("a".."z", "A".."Z", "_");
	$url .= $chars[rand @chars] for(1..20);
	my $t = $c->new_tournament({
		name => "Perl Test",
		url => $url,
	});
	my $test = $t->new_participant({
		name => "test",
		misc => "Created by test program",
	});

	isa_ok($test, "WWW::Challonge::Participant");

	# Test attributes:
	subtest "attributes work" => sub
	{
		is($test->attributes->{name}, "test",
			"Tournament name is 'test'");
		like($test->attributes->{misc}, qr/^Created by test program$/,
			"Misc is created by 'Created by test program'");
	};

	# Test updating the participant works:
	subtest "update works" => sub
	{
		ok($test->update({ name => "test2" }, 
			"Name updates ok"));
		is($test->attributes->{name}, "test2",
			"Name is 'test2'");
	};

	# Test randomise works:
	subtest "randomise works" => sub
	{
		# Make new participants, then get them in seed order:
		$t->new_participant({ name => $_ }) for(1..20);
		my @first = sort { $a->attributes->{seed} <=> $b->attributes->{seed} }
			$t->participants;

		# Make the randomise call:
		ok($test->randomize, "Randomise ok");

		# Get the participants in seed order again:
		my @secnd = sort { $a->attributes->{seed} <=> $b->attributes->{seed} }
			$t->participants;

		# Check they are not the same:
		ok(!eq_deeply(\@secnd, \@first), "Sorted arrays are not equal");
	};

	# Test destroy works:
	subtest "destroy works" => sub
	{
		ok($test->destroy, "Participant destroyed ok");
		eval { $test->update({ name => "foo" }); } or my $at = $@;
		like($at, qr/Participant has been destroyed/, "Dies on attempting to
			update destroyed participant");
	};

	$t->destroy;
	done_testing();
}
