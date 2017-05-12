#!perl -T
use warnings;
use strict;
use WWW::Challonge;
use Test::More tests => 15;
use Test::LWP::UserAgent;

# Read the JSON files:
my $DIR = "t/json/tournament";
opendir my $dir, $DIR
	or die "Cannot open dir '$DIR': $!\n";
my %files;
for(readdir $dir)
{
	# Get the file name and store the data in the hash:
	if(/^(.*)\.json$/)
	{
		# Open the file and store the contents:
		open my $file, '<', "$DIR/$_"
			or die "Cannot open file '$DIR/$_': $!\n";
		chomp(my $content = <$file>);
		$files{$1} = $content;
	}
}

# Configure the test useragent:
our $HOST = $WWW::Challonge::HOST;
my $ua = Test::LWP::UserAgent->new;

# destroy
$ua->map_response(
	sub {
		my $request = shift;
		return (($request->uri =~ m{^$HOST/tournaments.json$}) &&
			($request->method eq "POST") &&
			($request->content =~ /perl_test_3/)) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_3}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_3.json\?api_key=foo$}) &&
			($request->method eq "DELETE")) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{destroy}
));

# process_check_ins
$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments.json$}) &&
			($request->method eq "POST") &&
			($request->content =~ /perl_test_4/)) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_4}
));

$ua->map_response(
	qr{^$HOST/tournaments/perl_test_4/process_check_ins.json$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{process_check_ins}
));

$ua->map_response(
	qr{^$HOST/tournaments/perl_test_4.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{process_check_ins}
));

$ua->map_response(
	qr{^$HOST/tournaments/sourwithurhunni/process_check_ins.json$},
	HTTP::Response->new('401', 'Unauthorized',
	[ 'Content-Type' => 'application/json' ],
	$files{"process_check_ins-unauthorised"}
));

$ua->map_response(
	qr{^$HOST/tournaments/sourwithurhunni.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{"hunni"}
));

# abort_check_in
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_4/abort_check_in.json$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{abort_check_in}
));

# start
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_3/start.json$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{start}
));

# finalise
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_3/finalize.json$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{finalize}
));

# reset
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_3/reset.json$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{reset}
));

# attributes
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_3.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_3}
));

# participants
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_1}
));

$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1/participants.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{participants}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/participants/25012378.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{25012378}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/participants/25012379.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{25012379}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/participants/25012380.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{25012380}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/participants/25012381.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{25012381}
));

# participant
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1/participants/25012378.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{25012378}
));

$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1/participants/1.json\?api_key=foo$},
	HTTP::Response->new('404', 'Not Found',
	[ 'Content-Type' => 'application/json' ],
	$files{"participant-404"}
));

# new_participant
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_2.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_2}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->content =~ m/"Alice"/) &&
			($request->content =~ m/"1"/)
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{new_participant}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612182/participants/26462746.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{new_participant}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->content =~ m/"Alice"/) &&
			($request->content =~ m/"2"/)
		) ? 1 : 0;
	},
	HTTP::Response->new('422', 'Unprocessable Entity',
	[ 'Content-Type' => 'application/json' ],
	$files{name_taken}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->content =~ m/"Bob"/) &&
			($request->content =~ m/"99"/)
		) ? 1 : 0;
	},
	HTTP::Response->new('422', 'Unprocessable Entity',
	[ 'Content-Type' => 'application/json' ],
	$files{invalid_seed}
));

$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1/participants.json$},
	HTTP::Response->new('422', 'Unprocessable Entity',
	[ 'Content-Type' => 'application/json' ],
	$files{cannot_add}
));

# matches
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1/matches.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{matches}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{36649651}
));

# match
$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1/matches/36649651.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{36649651}
));

$ua->map_response(
	qr{^$HOST/tournaments/perl_test_1/matches/1.json\?api_key=foo$},
	HTTP::Response->new('404', 'Not Found',
	[ 'Content-Type' => 'application/json' ],
	$files{"match-404"}
));

# update
$ua->map_response(qr{^$HOST/tournaments.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{tournaments}
));

$ua->map_response(qr{^$HOST/tournaments/perl_test_1.json$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{update}
));

my $c = WWW::Challonge->new({ key => "foo", client => $ua });
my $test = $c->tournament("perl_test_1");

# --- BEGIN TESTS:

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge::Tournament") || BAIL_OUT();
}

subtest "destroy works" => sub
{
	# Regular usage:
	my $t = $c->new_tournament({ name => "perl_test_3", url => "perl_test_3" });
	ok($t->destroy, "Destroys ok");
	is($ua->last_http_request_sent->method, "DELETE", "Destroy sends DELETE");

	# Try every method and make sure they all fail:
	my %dispatch = (
		update => $t->can("update"),
		destroy => $t->can("destroy"),
		process_check_ins => $t->can("process_check_ins"),
		abort_check_in => $t->can("abort_check_in"),
		start => $t->can("start"),
		finalize => $t->can("finalize"),
		reset => $t->can("reset"),
		attributes => $t->can("attributes"),
		participants => $t->can("participants"),
		participant => $t->can("participant"),
		new_participant => $t->can("new_participant"),
		matches => $t->can("matches"),
		match => $t->can("match"),
	);

	for my $sub(keys %dispatch)
	{
		eval { &{$dispatch{$sub}->($t)} } or my $at = $@;
		like($at, qr/^Tournament has been destroyed/,
			"'$sub' does not operate on dead tournament");
	}
};

subtest "process_check_ins works" => sub
{
	# Regular usage:
	my $tournament = $c->new_tournament({
		name => "perl_test_4",
		url => "perl_test_4",
		start_at => "2015-05-27T18:00:00Z",
		check_in_duration => 120,
	});
	ok($tournament->process_check_ins, "Process check ins works ok");
	is($tournament->attributes->{state}, "checked_in", "State is 'checked_in'");

	# Unauthorised:
	$tournament = $c->tournament("sourwithurhunni");
	eval { $tournament->process_check_ins } or my $at = $@;
	like($at, qr/You only have read access/,
		"Cannot check in read-only tournament");
};

subtest "abort_check_in works" => sub
{
	# Regular usage:
	my $tournament = $c->new_tournament({
		name => "perl_test_4",
		url => "perl_test_4",
		start_at => "2015-05-27T18:00:00Z",
		check_in_duration => 120,
	});
	ok($tournament->abort_check_in, "Aborts check in ok");
	like($ua->last_http_response_received->content, qr/"state":"pending"/,
		"State is 'pending'");
};

subtest "start works" => sub
{
	# Regular usage:
	my $tournament = $c->new_tournament({
		name => "perl_test_3",
		url => "perl_test_3",
	});
	ok($tournament->start, "Starts ok");
	like($ua->last_http_response_received->content, qr/"state":"underway"/,
		"State is 'underway'");
};

subtest "finalize works" => sub
{
	# Regular usage:
	my $tournament = $c->new_tournament({
		name => "perl_test_3",
		url => "perl_test_3",
	});
	ok($tournament->finalize, "Finishes ok");
	like($ua->last_http_response_received->content, qr/"state":"complete"/,
		"State is 'complete'");
};

subtest "reset works" => sub
{
	# Regular usage:
	my $tournament = $c->new_tournament({
		name => "perl_test_3",
		url => "perl_test_3",
	});
	ok($tournament->reset, "Resets ok");
	like($ua->last_http_response_received->content, qr/"state":"pending"/,
		"State is 'pending'");
};

subtest "attributes works" => sub
{
	# Regular usage:
	my $tournament = $c->new_tournament({
		name => "perl_test_3",
		url => "perl_test_3",
	});
	is(ref $tournament->attributes, "HASH", "Returns hashref");
};

subtest "participants works" => sub
{
	# Regular usage:
	my $tournament = $c->tournament("perl_test_1");
	my $participants = $tournament->participants;
	is(ref $participants, "ARRAY", "Participants returns arrayref");
	isa_ok($_, "WWW::Challonge::Participant") for(@{$participants});
	my @by_name = sort(map { $_->attributes->{name} } @{$participants});
	my @names = qw/Brian Larry Randall Tom/;
	is_deeply(\@by_name, \@names, "Array of names matches");
};

subtest "participant works" => sub
{
	# Regular usage:
	my $tournament = $c->tournament("perl_test_1");
	my $participant = $tournament->participant("25012378");
	isa_ok($participant, "WWW::Challonge::Participant");
	is($participant->attributes->{name}, "Larry", "Name is 'Larry'");

	# 404 error:
	eval { $tournament->participant(1) } or my $at = $@;
	like($at, qr/Participant not found/, "Dies on 404");

	# No arguments:
	eval { $tournament->participant } or $at = $@;
	like($at, qr/No arguments given/, "Dies on no arguments");
};

subtest "new_participant works" => sub
{
	# Regular usage:
	my $tournament = $c->tournament("perl_test_2");
	my $participant = $tournament->new_participant({
		name => "Alice",
		seed => 1,
	});
	isa_ok($participant, "WWW::Challonge::Participant");
	is($participant->attributes->{name}, "Alice", "Name matches");

	# Missing arguments:
	eval { $participant = $tournament->new_participant({
		seed => 2,
	}) } or my $at = $@;
	like($at, qr/are required to create a new participant/,
		"Dies on missing argument");

	# No arguments:
	eval { $participant = $tournament->new_participant } or $at = $@;
	like($at, qr/are required to create a new participant/,
		"Dies on no arguments");

	# Name has been taken:
	eval { $participant = $tournament->new_participant({
		name => "Alice",
		seed => 2,
	}) } or $at = $@;
	like($at, qr/Name has already been taken/, "Dies on taken name");

	# Invalid seed:
	eval { $participant = $tournament->new_participant({
		name => "Bob",
		seed => 99,
	}) } or $at = $@;
	like($at, qr/Seed out of range/, "Dies on invalid seed");

	# Participants can no longer be added:
	$tournament = $c->tournament("perl_test_1");
	eval { $participant = $tournament->new_participant({
		name => "Larry",
		seed => 2,
	}) } or $at = $@;
	like($at, qr/can no longer be added/,
		"Dies on adding to in progress tournament");
};

subtest "matches works" => sub
{
	# Regular usage:
	my $tournament = $c->tournament("perl_test_1");
	my $matches = $tournament->matches;
	is(ref $matches, "ARRAY", "Matches returns arrayref");
	isa_ok($_, "WWW::Challonge::Match") for(@{$matches});
	is($matches->[0]->attributes->{scores_csv}, "0-2",
		"Fetches correct scores");
};

subtest "match works" => sub
{
	# Regular usage:
	my $tournament = $c->tournament("perl_test_1");
	my $match = $tournament->match("36649651");
	isa_ok($match, "WWW::Challonge::Match");
	is($match->attributes->{scores_csv}, "0-2", "Fetches correct scores");

	# 404 error:
	eval { $tournament->match(1) } or my $at = $@;
	like($at, qr/Match not found/, "Dies on 404");

	# No arguments:
	eval { $tournament->match } or $at = $@;
	like($at, qr/No arguments given/, "Dies on no arguments");
};

# We have this last as it requires unmapping the user agent:
subtest "update works" => sub
{
	# Regular usage:
	ok($test->update({ name => "perl-test-updated" }),
		"Updates tournament ok");

	is($ua->last_http_request_sent->method, "PUT", "Update sends PUT request");

	$ua->unmap_all($ua);
	$ua->map_response(qr{^$HOST/tournaments/perl_test_1.json\?api_key=foo$},
		HTTP::Response->new('200', 'OK',
		[ 'Content-Type' => 'application/json' ],
		$files{update}
	));

	is($test->attributes->{name}, "perl-test-updated",
		"Name updates correctly");

	# Invalid arguments:
	eval { $test->update({ swiss_rounds => "foo" }); } or my $at = $@;
	like($at, qr/is not a valid integer/, "Dies on incorrect argument type");

	# Dies on no arguments:
	eval { $test->update; } or $at = $@;
	like($at, qr/No arguments given/, "Dies on no arguments");

	$ua->map_response(qr{^$HOST/tournaments/overstone_ssbm.json\?api_key=foo$},
		HTTP::Response->new('401', 'Unathorized',
		[ 'Content-Type' => 'application/json' ],
		$files{"update-unathorised"}
	));
};

# Explicitly test the ISO8601 regex because it's big and was added later:
subtest "iso8601 works" => sub
{
	# Examples all taken from <https://en.wikipedia.org/?title=ISO_8601>:
	my @dates = (
		{ start_at => "2015-06-18" },
		{ start_at => "2015-06-18T00:59:34+00:00" },
		{ start_at => "2015-06-18T00:59:34Z" },
		{ start_at => "2015-W25" }, 
		{ start_at => "2015-W25-4" },
		{ start_at => "2015-169" },
	);
	for my $date(@dates)
	{
		ok(WWW::Challonge::Tournament::__args_are_valid($date),
			"'$date->{start_at}' is ok");
	}
};

done_testing();
