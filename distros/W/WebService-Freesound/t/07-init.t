#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 55;
use Test::Exception;
use LWP::UserAgent;
use Test::MockModule;
use HTTP::Response;
use JSON qw(decode_json);
use Data::Dumper;

# Create mock methods for LWP::UserAgent.
#
my $mocked_ua = Test::MockModule->new('LWP::UserAgent');
$mocked_ua->mock(
    'post',
    sub {
        my $self      = shift;
        my $url       = shift;
        my $post_args = shift;
        my $response  = HTTP::Response->new;
        $response->code(200);

        # Return a new set of tokens on refresh.
        #
        if ( $post_args->{grant_type} eq 'refresh_token' ) {
            $response->content(
                '{"access_token": "333333333333333333333333333333", "token_type": "Bearer", "expires_in": 36000, "refresh_token": "444444444444444444444444444444", "scope": "read write"}'
            );
        }

        # Force and auth error.
        #
        elsif ( $post_args->{code} eq 'force_auth_error' ) {
            $response->code(401);
        }

        # Force a nonjson return for some reason.
        #
        elsif ( $post_args->{code} eq 'force_json_error' ) {
            $response->content(
                '{"access_token: "111111111111111111111111111111", token_type": "Bearer", "expires_in": 36000, "refresh_token: "222222222222222222222222222222", "scope": "read write"}'
            );
        }

        # Return tokens as Freesound.org would.
        #
        else {
            $response->content(
                '{"access_token": "111111111111111111111111111111", "token_type": "Bearer", "expires_in": 36000, "refresh_token": "222222222222222222222222222222", "scope": "read write"}'
            );
        }

        return $response;
    }
);

$mocked_ua->mock(
    'get',
    sub {
        my $self          = shift;
        my $url           = shift;
        my $read_sizehint = shift;
        my $size          = shift;
        my $callback      = shift;

        my $response = HTTP::Response->new;

        # In download method. Difficult to test the code
        # I've put into the callback.
        #
        if ( defined $callback ) {

            if ( $url =~ /83253/ ) {
                $response->code(200);
            }
            else {
                $response->code(401);
            }
            $response->content("");

        }
        else {
            my $search_results = <<'EOSR';
{"count":1,"next":null,"results":[{"id":83253,"name":"BASS0209.wav","type":"wav","tags":["bass"],"license":"http://creativecommons.org/publicdomain/zero/1.0/","username":"zgump"}],"previous":null}
EOSR

            # Found id on Freesound, and have results ok.
            #
            if ( $url =~ /83253/ ) {
                $response->code(200);
                $response->content($search_results);

                # Unauthorised to get results.
                #
            }
            elsif ( $url =~ /99999/ ) {
                $response->code(401);
                $response->content("");
                $response->status_line("401 unauthorised");

                # Invalid id.
                #
            }
            else {
                $response->code(200);
                $response->content("");
            }
        }
        return $response;
    }
);

# Load the WebService::Freesound module
BEGIN { use_ok('WebService::Freesound') }

# Create a constructor.
#
my %args = (
    client_id     => 'test_client_id',
    client_secret => 'test_client_secret',
    session_file  => './freesoundrc',
);

my $freesound = WebService::Freesound->new(%args);

isa_ok( $freesound, "WebService::Freesound" );

# Now look at accessors.
#
is( $freesound->client_id, "test_client_id", "client_id is correct" );
is( $freesound->client_secret, "test_client_secret",
    "client_secret is correct" );
is( $freesound->session_file, "./freesoundrc", "session_file is correct" );
isa_ok( $freesound->ua, "LWP::UserAgent", "ua defined ok" );

# Not defined yet.
#
is( $freesound->error,         '', "error not defined yet ok" );
is( $freesound->access_token,  '', "access_token not defined yet ok" );
is( $freesound->refresh_token, '', "refresh_token not defined yet ok" );
is( $freesound->expires_in,    '', "expires_in not defined yet ok" );

# Get URL string.
#
my $auth_url
    = 'https://www.freesound.org/apiv2/oauth2/authorize/?'
    . 'client_id=test_client_id'
    . '&response_type=code'
    . '&state=xyz';

is( $freesound->get_authorization_url, $auth_url, "Auth URL correct" );

# Authority should not be granted yet, so test check_authority here.
#
is( $freesound->check_authority( refresh_if_expired => 1 ),
    undef, "check_authority on no auth tokens ok" );
is( $freesound->error,
    "Need to re-authorise with Freesound, use get_authorization_url then get_oauth_tokens with the returned code from Freesound",
    "check_authority error message ok"
);

# Try get_oauth_tokens with errors.
#
dies_ok { $freesound->get_oauth_tokens() }
'Dies ok with no code from Freesound auth';
is( $freesound->get_new_oauth_tokens('force_auth_error'),
    undef, "get_oauth_tokens error ok" );
is( $freesound->error,
    "401 Unauthorized",
    "error message from get_oauth_tokens ok"
);
is( $freesound->get_new_oauth_tokens('force_json_error'),
    undef, "get_oauth_tokens error ok" );
is( $freesound->error,
    "Response from user agent appears not to be JSON",
    "error message from get_oauth_tokens ok"
);

# Test it does work.
#
my $code = "12345";
is( $freesound->get_new_oauth_tokens($code), 1, "Auth tokens got ok" );

# Make sure these are unchanged.
#
is( $freesound->client_id, "test_client_id", "client_id is correct" );
is( $freesound->client_secret, "test_client_secret",
    "client_secret is correct" );
is( $freesound->session_file, "./freesoundrc", "session_file is correct" );
is( $freesound->error, '', "error not defined yet ok" );

# And these are updated.
#
is( $freesound->access_token,
    '111111111111111111111111111111',
    "access_token defined ok"
);
is( $freesound->refresh_token,
    '222222222222222222222222222222',
    "refresh_token defined ok"
);
is( $freesound->expires_in, '36000', "expires_in defined ok" );

# Test the check_authority method now is ok.
#
is( $freesound->check_authority( refresh_if_expired => 1 ),
    1, "check_authority on valid tokens ok" );

# Test the query method.
#
my $query = "big bass drum&filter=id:83253";
dies_ok { $freesound->query() } 'Dies ok with no params to query';
isa_ok( $freesound->query($query),
    "HTTP::Response", "query returns a HTTP::Response" );

# Extract the data and check its as above.
#
my $response = $freesound->query($query);
my $contents = decode_json( $response->content );

is( $contents->{count},                1,              "count is ok" );
is( $contents->{previous},             undef,          "previous is ok" );
is( $contents->{next},                 undef,          "next is ok" );
is( $contents->{results}->[0]->{id},   83253,          "id is ok" );
is( $contents->{results}->[0]->{name}, "BASS0209.wav", "name is ok" );
is( $contents->{results}->[0]->{type}, "wav",          "type is ok" );
is( $contents->{results}->[0]->{tags}->[0], "bass", "tags are ok" );
is( $contents->{results}->[0]->{license},
    'http://creativecommons.org/publicdomain/zero/1.0/',
    "license is ok"
);
is( $contents->{results}->[0]->{username}, 'zgump', "username is ok" );

# Now expire the access_token and see if it is updated with a new
# refresh_token with check_authority.
#
# Manipulate the rc file.
#
open my $fh, '>', './freesoundrc'
    or die "Cannot write to ./freesoundrc : $!\n";
print $fh
    '{"access_token": "111111111111111111111111111111", "token_type": "Bearer", "expires_in": 0, "refresh_token": "222222222222222222222222222222", "scope": "read write"}';
close $fh;

# Wait for filesystem.
#
sleep 2;
is( $freesound->check_authority( refresh_if_expired => undef ),
    undef, "check_authority on refreshable tokens ok" );
is( $freesound->error,
    "Authority has expired",
    "check_authority error message ok with refreshable tokens "
);

# Now try query and download to see if they fail too.
#
my $id = "99999";    # Unauth in get mock.
my $to = "./";

# Force error on query to get error messages.
#
$query    = "big bass drum&filter=id:$id";
$response = $freesound->query($query);
is( $response->status_line,
    "401 Unauthorized",
    "No auth ok on query with expired tokens"
);
is( $freesound->download( $id, $to ),
    undef, "No auth ok on download with expired tokens" );
is( $freesound->error,
    "401 Unauthorized",
    "error message wih no auth ok on download with expired tokens"
);

# New do the refresh.
#
is( $freesound->check_authority( refresh_if_expired => 1 ),
    1, "check_authority on valid tokens ok" );

# Now the tokens should be updated as they have expired.
#
is( $freesound->access_token,
    '333333333333333333333333333333',
    "new access_token defined ok"
);
is( $freesound->refresh_token,
    '444444444444444444444444444444',
    "new refresh_token defined ok"
);
is( $freesound->expires_in, '36000', "new expires_in defined ok" );

# Download
#
dies_ok { $freesound->download() } 'download dies ok with no inputs';
dies_ok { $freesound->download($id) } 'download dies ok with ony one input';

# Download with no name for id.
#
$id = "22222";    # not a valid id in get mock.
is( $freesound->get_filename_from_id($id), undef, "no name from id ok" );
is( $freesound->error, "Cannot find a name or type for Freesound id $id" );

# Download calls get_filename_from_id but test it here first.
#
$id = "83253";    # valid id in get mock.
is( $freesound->get_filename_from_id($id), "BASS0209.wav",
    "name from id ok" );

# Not easy to test as there is a callback in the Use Agent for download.
#
is( $freesound->download( $id, $to ), "$to/BASS0209.wav", "Download ok" );

# Unlink the rc file.
#
ok( unlink('./freesoundrc'),    "delete ./freesoundrc ok" );
ok( unlink("$to/BASS0209.wav"), "delete $to/BASS0209.wav ok" );

