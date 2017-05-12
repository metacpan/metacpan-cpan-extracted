#!perl -T
use warnings;
use strict;
use feature "state";
use WWW::Challonge;
use Test::More tests => 6;
use Test::LWP::UserAgent;

# Read the JSON files:
my $DIR = "t/json/match";
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

$ua->map_response(qr{^$HOST/tournaments/perl_test_1.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{perl_test_1}
));

$ua->map_response(qr{^$HOST/tournaments/perl_test_1/matches.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{matches}
));

# update:
$ua->map_response(
	sub {
		my $request = shift;
		return (
		($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651.json$}) &&
		($request->method eq "PUT") &&
		($request->content =~ /scores_csv/)
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{update}
));

# attributes:
$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{a}
));

# attachments:
$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651/attachments.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{attachments}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651/attachments/129264.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{129264}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651/attachments/129263.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{129263}
));

$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651/attachments/129262.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{129262}
));

# participant
$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651/attachments/1.json\?api_key=foo$},
	HTTP::Response->new('404', 'Not Found',
	[ 'Content-Type' => 'application/json' ],
	$files{not_found}
));

# new_attachment
$ua->map_response(
	sub {
		my $request = shift;
		return (
		($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments.json$}) &&
		($request->method eq "POST") &&
		($request->content =~ /match_attachment\[url\]/)
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{new_attachment_url}
));

$ua->map_response(
	sub {
		my $request = shift;
		state $count = 0;
		return (
		($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments.json$}) &&
		($request->method eq "POST") &&
		($request->content =~ /match_attachment\[asset\]/) &&
		($request->content =~ /test_file1/) &&
		($count++ > 4)
		) ? 1 : 0;
	},
	HTTP::Response->new('422', 'Unprocessable Entity',
	[ 'Content-Type' => 'application/json' ],
	$files{new_attachment_asset_too_many}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
		($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments.json$}) &&
		($request->method eq "POST") &&
		($request->content =~ /match_attachment\[asset\]/) &&
		($request->content =~ /test_file1/)
		) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{new_attachment_asset}
));

$ua->map_response(
	sub {
		my $request = shift;
		return (
		($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments.json$}) &&
		($request->method eq "POST") &&
		($request->content =~ /match_attachment\[asset\]/) &&
		($request->content =~ /test_file2/)
		) ? 1 : 0;
	},
	HTTP::Response->new('422', 'Unprocessable Entity',
	[ 'Content-Type' => 'application/json' ],
	$files{new_attachment_asset_large}
));

my $c = WWW::Challonge->new({ key => "foo", client => $ua });
my $tournament = $c->tournament("perl_test_1");
my @matches = @{$tournament->matches};

# --- BEGIN TESTS:

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge::Match") || BAIL_OUT();
}

subtest "update works" => sub
{
	# Regular usage:
	ok($matches[0]->update(["3-1"]), "Updates ok");
	like($ua->last_http_request_sent->content, qr/"winner_id":25012378/,
		"Selects winner correctly");
	is($ua->last_http_request_sent->method, "PUT", "Sends PUT request");

	# Incorrect score format:
	eval { $matches[0]->update(["1/2"]) } or my $at = $@;
	like($at, qr/Results must be given in the format/,
		"Dies on incorrect score format");

	# Votes are not given as integers:
	eval { $matches[0]->update({ scores_csv => [ "1-2" ],
		player1_votes => "foo" }) } or $at = $@;
	like($at, qr/must be an integer/, "Dies on invalid data type");

	# Hashref with no scores:
	eval { $matches[0]->update({ player1_votes => 2 }) } or $at = $@;
	like($at, qr/Required argument 'scores_csv'/, "Dies on no scores");

	# Scalar:
	eval { $matches[0]->update("foo") } or $at = $@;
	like($at, qr/Expected an arrayref or hashref/, "Dies on scalar given");

	# No arguments:
	eval { $matches[0]->update } or $at = $@;
	like($at, qr/Expected an arrayref or hashref/, "Dies on no arguments");

	# Warns on invalid arguments:
	local $SIG{__WARN__} = sub { my $message = shift; die "warn" . $message; };
	eval { $matches[0]->update({ scores_csv => ["1-2"], foo => "foo" }); }
		or $at = $@;
	like($at, qr/warnIgnoring/, "Warns on unknown argument");
};

subtest "attributes works" => sub
{
	# Regular usage:
	is(ref $matches[0]->attributes, "HASH", "Attributes returns hashref");
	like($matches[0]->attributes->{scores_csv}, qr/^0-2$/,
		"Match score is correct");
}; 

subtest "attachments works" => sub
{
	# Regular usage:
	my $attachments = $matches[0]->attachments;
	is(ref $attachments, "ARRAY", "Attachments returns arrayref");
	isa_ok($_, "WWW::Challonge::Match::Attachment") for(@{$attachments});
	like($_->attributes->{description}, qr/^A simple/, "Description matches")
		for(@{$attachments});
};

subtest "attachment works" => sub
{
	# Regular usage:
	my $attachment = $matches[0]->attachment(129263);
	isa_ok($attachment, "WWW::Challonge::Match::Attachment");
	is($attachment->attributes->{url},
		"http://search.cpan.org/~kirby/WWW-Challonge", "URL is correct");

	# 404 error:
	eval { $attachment = $matches[0]->attachment(1) } or my $at = $@;
	like($at, qr/not found/, "Dies on 404 error");

	# No arguments:
	eval { $attachment = $matches[0]->attachment } or $at = $@;
	like($at, qr/No arguments given/, "Dies on no arguments");
};

subtest "new_attachment works" => sub
{
	subtest "url" => sub
	{
		# Regular usage:
		my $attachment = $matches[0]->new_attachment({
			url => "https://google.co.uk"
		});
		isa_ok($attachment, "WWW::Challonge::Match::Attachment");

		# No protocol:
		eval { $attachment = $matches[0]->new_attachment({
			url => "google.co.uk"
		}) } or my $at = $@;
		like($at, qr/^URL must start with/, "Dies on no protocol");
	};
	subtest "asset" => sub
	{
		# Regular usage:
		my $attachment = $matches[0]->new_attachment({
			asset => "t/test_file1"
		});
		isa_ok($attachment, "WWW::Challonge::Match::Attachment");

		# Invalid file path:
		eval { $attachment = $matches[0]->new_attachment({
			asset => "foo"
		}) } or my $at = $@;
		like($at, qr/^No such file/, "Dies on no file");

		# File too large:
		eval { $attachment = $matches[0]->new_attachment({
			asset => "t/test_file2"
		}) } or $at = $@;
		like($at, qr/file size must be less/, "Dies on large file");

		# Too many files:
		eval { while(1) { $attachment = $matches[0]->new_attachment({
			asset => "t/test_file1"
		}) } } or $at = $@;
		like($at, qr/Max file attachments per match/, "Dies on too many files");
	};

	# No arguments:
	eval { my $attachment = $matches[0]->new_attachment } or my $at = $@;
	like($at, qr/^No arguments given/, "Dies on no arguments");

	# Warns on invalid arguments:
	local $SIG{__WARN__} = sub { my $message = shift; die "warn" . $message; };
	eval { $matches[0]->new_attachment({ foo => "foo" }); } or $at = $@;
	like($at, qr/warnIgnoring/, "Warns on unknown argument");
};

done_testing();
