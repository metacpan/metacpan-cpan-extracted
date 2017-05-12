#!perl -T
use warnings;
use strict;
use Test::More tests => 5;
use Test::LWP::UserAgent;

# Read the JSON files:
my $DIR = "t/json/challonge";
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
$ua->map_response(qr{^$HOST/tournaments.json\?api_key=success$},
	HTTP::Response->new('200', 'OK',
	['Content-Type' => 'application/json'],
	$files{tournaments}
));

$ua->map_response(qr{^$HOST/tournaments.json\?api_key=success&state=pending$},
	HTTP::Response->new('200', 'OK',
	['Content-Type' => 'application/json'],
	$files{"tournaments-pending"}
));

$ua->map_response(qr{^$HOST/tournaments/perl_test_1.json\?api_key=success$},
	HTTP::Response->new('200', 'OK',
	['Content-Type' => 'application/json'],
	$files{tournament}
));

$ua->map_response(qr{^$HOST/tournaments/perl_test_2.json\?api_key=success$},
	HTTP::Response->new('200', 'OK',
	['Content-Type' => 'application/json'],
	$files{"tournament-pending"}
));

$ua->map_response(qr{^$HOST/tournaments/perl_test_3.json\?api_key=success$},
	HTTP::Response->new('200', 'OK',
	['Content-Type' => 'application/json'],
	$files{"new_tournament"}
));

$ua->map_response(qr{^$HOST/tournaments/notfound404.json\?api_key=success$},
	HTTP::Response->new('404', 'Not Found',
	['Content-Type' => 'application/json'],
	$files{"not-found"}
));

$ua->map_response(sub {
	my $request = shift;
	return (($request->uri =~ m{^$HOST/tournaments.json$}) &&
		($request->method eq "POST") &&
		($request->content =~ /perl_test_4/)) ? 1 : 0;
	},
	HTTP::Response->new('422', 'Unprocessable Entity',
	['Content-Type' => 'application/json'],
	$files{invalid_start_time}
));

$ua->map_response(qr{^$HOST/tournaments.json$},
	HTTP::Response->new('200', 'OK',
	['Content-Type' => 'application/json'],
	$files{new_tournament}
));

# --- BEGIN TESTS:

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge") || BAIL_OUT();
}

my $test;
my $test2;
subtest "new works" => sub
{
	# Regular use:
	$test = new_ok("WWW::Challonge" => [ { key => "success", client => $ua } ]);

	# Invalid key:
	my $ua2 = Test::LWP::UserAgent->new;
	$ua2->map_response(qr{^$HOST/tournaments.json\?api_key=fail$},
		HTTP::Response->new('401', 'Unathorized',
		['Content-Type' => 'application/json'],
		$files{"new-fail"}
	));
	eval { $test2 = WWW::Challonge->new( { key => "fail", client => $ua2 } )}
		or my $at = $@;
	like($at, qr/Invalid API key/, "Dies on bad API key");

	# Invalid client:
	eval { my $test3 = WWW::Challonge->new( { key => "fail", client => "hello" } )}
		or $at = $@;
	like($at, qr/must be a LWP::UserAgent/, "Dies on bad useragent");

	# Passing an arrayref:
	eval { my $test4 = WWW::Challonge->new( [ 1 ] )}
		or $at = $@;
	like($at, qr/Expected scalar or hashref/, "Dies on bad arguments");

	# Passing nothing:
	eval { my $test5 = WWW::Challonge->new }
		or $at = $@;
	like($at, qr/Expected scalar or hashref/, "Dies on no arguments");
};

# Test we can get an arrayref of all the user's tournaments:
subtest "tournaments works" => sub
{
	# Just fetching tournaments:
	is(ref $test->tournaments, "ARRAY", "Returned value is arrayref");
	is(@{$test->tournaments}, 2, "Returned array is 2 elements large");
	for my $tournament(@{$test->tournaments})
	{
		isa_ok($tournament, "WWW::Challonge::Tournament");
	}

	# Testing 'state' argument:
	is(ref $test->tournaments({ state => "pending" }), "ARRAY",
		"Returned value is arrayref");
	is(@{$test->tournaments({ state => "pending" })}, 1,
		"Returned array is 1 element large");
	for my $tournament(@{$test->tournaments({ state => "pending"})})
	{
		isa_ok($tournament, "WWW::Challonge::Tournament");
	}
	is($test->tournaments({ state => "pending" })->[0]->attributes->{url},
		"perl_test_2", "Fetches correct tournament");

	# Testing invalid value for argument:
	eval { $test->tournaments({ state => "sdhdfgh" }); } or my $at = $@;
	like($at, qr/is invalid/, "Dies on bad argument");

	# Testing unknown argument:
	local $SIG{__WARN__} = sub { my $message = shift; die "warn" . $message; };
	eval { $test->tournaments({ foo => "sdhdfgh" }); } or $at = $@;
	like($at, qr/warnUnknown option/, "Warns on unknown argument");
};

# Test a specific tournament (we test the specific attributes in tournament.t):
subtest "tournament works" => sub
{
	# Regular usage:
	my $tournament = $test->tournament("perl_test_1");
	isa_ok($tournament, "WWW::Challonge::Tournament");
	is($tournament->attributes->{url}, "perl_test_1",
		"Fetches correct tournament");

	# No argument:
	eval { $tournament = $test->tournament; } or my $at = $@;
	like($at, qr/No tournament specified/, "Dies on no tournament");

	# 404 error:
	eval { $tournament = $test->tournament("notfound404"); } or $at = $@;
	like($at, qr/tournament not found/, "Dies on 404");
};

# Tests we can create a tournament:
subtest "new_tournament works" => sub
{
	# Regular usage:
	my $new = $test->new_tournament({
		name => "perl_test_3",
		url => "perl_test_3",
	});
	isa_ok($new, "WWW::Challonge::Tournament");
	is($new->attributes->{url}, "perl_test_3", "Name matches");

	# Missing arguments:
	eval { my $new = $test->new_tournament({
		name => "perl_test_3",
	}); } or my $at = $@;
	like($at, qr/Name and URL are required/, "Dies on missing arguments");

	# No arguments:
	eval { my $new = $test->new_tournament } or $at = $@;
	like($at, qr/Name and URL are required/, "Dies on no arguments");

	# URL has been taken
	my $ua2 = Test::LWP::UserAgent->new;
	$ua2->map_response(qr{^$HOST/tournaments.json\?api_key=taken$},
		HTTP::Response->new('200', 'OK',
		['Content-Type' => 'application/json'],
		$files{tournaments}
	));
	$ua2->map_response(qr{^$HOST/tournaments.json$},
		HTTP::Response->new('422', 'Unprocessable Entity',
		['Content-Type' => 'application/json'],
		$files{"new_tournament-taken"}
	));
	my $test2 = WWW::Challonge->new({ key => "taken", client => $ua2 });
	eval { my $new = $test2->new_tournament({
		name => "perl_test_3",
		url => "perl_test_3",
	}); } or $at = $@;
	like($at, qr/URL has already been taken/, "Dies on taken URL");

	# Invalid start time:
	eval { my $new = $test->new_tournament({
		name => "perl_test_4",
		url => "perl_test_4",
		start_at => "2014-05-27T18:00:00Z",
		check_in_duration => 120,
	}); } or $at = $@;
	like($at, qr/Start time must be in the future/,
		"Dies on invalid start time");
};

done_testing();
