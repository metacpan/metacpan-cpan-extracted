#!perl -T
use warnings;
use strict;
use WWW::Challonge;
use JSON qw/from_json/;
use Test::More tests => 6;
use Test::LWP::UserAgent;
use Test::Deep;

# Read the JSON files:
my $DIR = "t/json/participant";
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

$ua->map_response(qr{^$HOST/tournaments.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{tournaments}
));

$ua->map_response(
	qr{^$HOST/tournaments/perl_test_2.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_2}
));

# check_in
$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments.json$}) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_3}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_3/participants.json$}) &&
			($request->content =~ /Alice/) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{alice}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_3/participants.json$}) &&
			($request->content =~ /Bob/) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{bob}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_3.json$}) &&
			($request->method eq "PUT")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{update_for_check_in}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/1707332/participants/26628821/check_in.json$}) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{check_in}
));

$ua->map_response(
	qr{^$HOST/tournaments/1707332/participants/26628821.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{alice_checked_in}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_3/process_check_ins.json$}) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{process_check_ins}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/1707332/participants/26628822/check_in.json$}) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('422', 'Unprocessable Entity',
	[ 'Content-Type' => 'application/json' ],
	$files{check_in_fail}
));

# destroy
$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{new_participant}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/1612182/participants/26529775.json\?api_key=foo$}) &&
			($request->method eq "DELETE")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{destroy}
));

# randomize
$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->content =~ /Alex/) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{alex}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->content =~ /Bort/) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{bort}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->content =~ /Claire/) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{claire}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/perl_test_2/participants.json$}) &&
			($request->content =~ /Dean/) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{dean}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/1612182/participants/randomize.json$}) &&
			($request->method eq "POST")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{randomize}
));

# attributes
$ua->map_response(
	qr{^$HOST/tournaments/1612182/participants/26529775.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{new_participant}
));

# update
$ua->map_response(
	sub {
		my $request = shift;
		return (
			($request->uri =~ m{^$HOST/tournaments/1612182/participants/26529775.json$}) &&
			($request->method eq "PUT")
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{update}
));

my $c = WWW::Challonge->new({ key => "foo", client => $ua });
my $tournament = $c->tournament("perl_test_2");

# --- BEGIN TESTS:

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge::Participant") || BAIL_OUT();
}

subtest "check_in works" => sub
{
	# Regular usage:
	my $t = $c->new_tournament({
		name => "perl_test_3",
		url => "perl_test_3",
	});
	my $participant = $t->new_participant({ name => "Alice" });
	my $late_participant = $t->new_participant({ name => "Bob" });
	$t->update({
		start_at => "2015-06-01T23:00:00Z",
		 check_in_duration => 120,
	});
	ok($participant->check_in, "Participant checks in");
	ok($participant->attributes->{checked_in}, "'checked_in' is set");

	# Check-in window is closed:
	$t->process_check_ins;
	eval { $late_participant->check_in } or my $at = $@;
	like($at, qr/the check-in window has closed/, "Dies on failed check-in");
};

subtest "destroy works" => sub
{
	# Regular usage:
	my $participant = $tournament->new_participant({ name => "Alice" });
	ok($participant->destroy, "Destroys participant ok");
	is($ua->last_http_request_sent->method, "DELETE", "Destroy sends DELETE");

	# Try every method and make sure they all fail:
	my %dispatch = (
		update => $participant->can("update"),
		check_in => $participant->can("check_in"),
		destroy => $participant->can("destroy"),
		randomize => $participant->can("randomize"),
		attributes => $participant->can("attributes"),
	);

	for my $sub(keys %dispatch)
	{
		eval { &{$dispatch{$sub}->($participant)} } or my $at = $@;
		like($at, qr/^Participant has been destroyed/,
			"'$sub' does not operate on dead tournament");
	}
};

subtest "randomize works" => sub
{
	# Regular usage:
	my $participant;
	for my $name(qw/Alex Bort Claire Dean/)
	{
		$participant = $tournament->new_participant({ name => $name });
	}
	ok($participant->randomize, "Participants randomised ok");
	ok(
		!eq_deeply(
			qw/Alex Bort Claire Dean/,
			map { $_ = $_->{name} } 
				@{from_json($ua->last_http_response_received->content)}
		),
		"Names sorted by seed are not the same"
	);
};

subtest "attributes works" => sub
{
	# Regular usage:
	my $participant = $tournament->new_participant({ name => "Alice" });
	is(ref $participant->attributes, "HASH", "Attributes returns hashref");
	is($participant->attributes->{name}, "Alice", "Name is correct");
};

# We have this last as it requires unmapping the user agent:
subtest "update works" => sub
{
	# Regular usage:
	my $participant = $tournament->new_participant({ name => "Alice" });
	ok($participant->update({ name => "Bob" }), "Updates participant ok");
	is($ua->last_http_request_sent->method, "PUT", "Update sends PUT request");

	$ua->unmap_all($ua);
	$ua->map_response(
		qr{^$HOST/tournaments/1612182/participants/26529775.json\?api_key=foo$},
		HTTP::Response->new('200', 'OK',
		[ 'Content-Type' => 'application/json' ],
		$files{update}
	));
	isnt($participant->attributes->{created_at},
		$participant->attributes->{modified_at},
		"Date created and modified are not equal");
	is($participant->attributes->{name}, "Bob", "Name is updated");

	# Invalid arguments:
	eval { $participant->update({ seed => "foo" }); } or my $at = $@;
	like($at, qr/is not a valid integer/, "Dies on incorrect argument type");

	# Dies on no arguments:
	eval { $participant->update; } or $at = $@;
	like($at, qr/No arguments given/, "Dies on no arguments");
};

done_testing();
