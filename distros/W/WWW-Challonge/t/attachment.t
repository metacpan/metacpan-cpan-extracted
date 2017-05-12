#!perl -T
use warnings;
use strict;
use WWW::Challonge;
use Test::More tests => 4;
use Test::LWP::UserAgent;

# Read the JSON files:
my $DIR = "t/json/attachment";
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

$ua->map_response(
	qr{^$HOST/tournaments/1612181/matches/36649651/attachments/129264.json\?api_key=foo$},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{attachment}
));

# update
$ua->map_response(
	sub {
	my $request = shift;
	return (
	($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments/129264.json$}) &&
	($request->method eq "PUT") &&
	($request->content =~ /url/)
	) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{update_url}
));

$ua->map_response(
	sub {
	my $request = shift;
	return (
	($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments/129264.json$}) &&
	($request->method eq "PUT") &&
	($request->content =~ /asset/)
	) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{update_asset}
));

# destroy
$ua->map_response(
	sub {
	my $request = shift;
	return (
	($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments.json$}) &&
	($request->method eq "POST")
	) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{new_attachment}
));

$ua->map_response(
	sub {
	my $request = shift;
	return (
	($request->uri =~ m{^$HOST/tournaments/1612181/matches/36649651/attachments/129805.json\?api_key=foo$}) &&
	($request->method eq "DELETE")
	) ? 1 : 0;
	},
	HTTP::Response->new('200', 'OK',
	[ 'Content-Type' => 'application/json' ],
	$files{destroy}
));

my $c = WWW::Challonge->new({ key => "foo", client => $ua });
my $tournament = $c->tournament("perl_test_1");
my @matches = @{$tournament->matches};
my $attachment = $matches[0]->attachment(129264);

# --- BEGIN TESTS:

# Check if compiles:
BEGIN
{
	require_ok("WWW::Challonge::Match::Attachment") || BAIL_OUT();
}

subtest "update works" => sub
{
	# Regular usage:
	ok($attachment->update({ url => "https://google.co.uk" }),
		"Updates url ok");
	is($ua->last_http_request_sent->method, "PUT", "Sends PUT request");
	like($ua->last_http_response_received->content,
		qr{"url":"https://google.co.uk"}, "Url is correct");

	ok($attachment->update({ asset => "t/test_file1" }),
		"Updates asset ok");
	is($ua->last_http_request_sent->method, "PUT", "Sends PUT request");
	like($ua->last_http_response_received->content,
		qr{"original_file_name":"test_file1"}, "Filename is correct");

	# No arguments:
	eval { $attachment->update } or my $at = $@;
	like($at, qr/No arguments given/, "Dies on no arguments");
};

subtest "attributes works" => sub
{
	is(ref $attachment->attributes, "HASH", "Attributes returns hashref");
	is($attachment->attributes->{id}, "129264", "Returns correct id");
};

subtest "destroy works" => sub
{
	my $a = $matches[0]->new_attachment({ description => "foo" });
	ok($a->destroy, "Destroys ok");
	is($ua->last_http_request_sent->method, "DELETE", "Sends DELETE request");

	# Try every method and make sure they all fail:
	my %dispatch = (
		update => $a->can("update"),
		attributes => $a->can("attributes"),
		destroy => $a->can("destroy"),
	);

	for my $sub(keys %dispatch)
	{
		eval { &{$dispatch{$sub}->($a)} } or my $at = $@;
		like($at, qr/^Attachment has been destroyed/,
			"'$sub' does not operate on dead tournament");
	}
};

done_testing();
