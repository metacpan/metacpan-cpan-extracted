#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

use Devel::StackTrace;
use WebService::Rollbar::Notifier;

# The live tests below actually POST to the real Rollbar API
# (api.rollbar.com). Rollbar rejects any request whose access token is not a
# valid, enabled `post_server_item` token, so these tests can only pass when a
# real token is supplied via the TEST_ROLLBAR_ACCESS_TOKEN environment
# variable. When it is not set (the normal case for CPAN smokers and end
# users), we skip the live portion instead of firing off doomed requests that
# would fail with an HTTP 403 response.
my $access_token = $ENV{TEST_ROLLBAR_ACCESS_TOKEN};

my $rollbar = WebService::Rollbar::Notifier->new(
    access_token => $access_token || 'dummy_token',
    callback => undef, # block to read response
);

isa_ok $rollbar, 'WebService::Rollbar::Notifier';
can_ok $rollbar, qw/
    access_token  environment  code_version
    critical error warning info debug notify
    callback framework language server
/;

unless ( $access_token ) {
    diag 'Set the TEST_ROLLBAR_ACCESS_TOKEN environment variable to a valid '
        . 'Rollbar post_server_item access token to run the live API tests.';
    done_testing;
    exit;
}

# We only reach this point with a real token, so we genuinely need a working
# connection to the Rollbar API.
require Test::RequiresInternet;
Test::RequiresInternet->import( 'api.rollbar.com' => 80 );

my $VER = $WebService::Rollbar::Notifier::VERSION;

{
    my $desc = "simplest info message";
    my $tx = $rollbar->info(
        "$VER $desc",
    );
    verify_response( $tx, "Simple info message")
}
{
    my $desc = "simple info message";
    my $tx = $rollbar->info(
        "$VER $desc",
        {
            perl_version => "$^V",
        },
    );
    verify_response( $tx, "Simple info message");
}

{
    my $desc = "same info message, but using report_message";
    my $tx = $rollbar->report_message(
        [
            "$VER $desc", { level => 'info', perl_version => "$^V" },
        ],
    );
    verify_response( $tx, $desc);
}
{
    my $desc = "warn message with some additional fields";
    $rollbar->framework("test_framework");
    my $tx = $rollbar->report_message(
        "$VER $desc",
        {
            level => "warn",
            custom => {
                something => "here",
            },
            context => "our_own",
            server => { host => "sample_host" }
        }
    );
    $rollbar->framework(undef);
    verify_response( $tx, $desc);
}

{
    my $desc = "simplest trace";
    my $tx = $rollbar->report_trace(
        "$VER $desc",
        [ # stacktrace frames
            { filename => '01-notify.t', lineno => __LINE__ }
        ],

    );
    verify_response( $tx, $desc);
}
{
    my $desc = "Devel::StackTrace trace";
    my $tx = $rollbar->report_trace(
        "$VER $desc",
        "Exception message",
        _get_deeper_stacktrace(),
    );
    verify_response( $tx, $desc);
}
{
    my $desc = "setting server via notifier instance";
    $rollbar->server({ host => "sample_host" });
    my $tx = $rollbar->report_message("$VER $desc");
    verify_response( $tx, $desc);
    $rollbar->server(undef);
}


sub verify_response {
    my ($tx, $description) = @_;

    if ($tx->error) {
        diag 'Failed to successfully send request. About to fail. Dumping '
            . 'what we received for debugging purposes: '
            . $tx->res->to_string;
    }

    my $answer = $tx->res->json;
    if ( not defined $answer) {
        diag 'We failed to decode JSON response, which was: ['
            . $tx->res->body . "]\n"
            . "The exception we received is $@";
    }

    cmp_deeply(
        $answer,
        {
            'result' => {
                'id' => undef,
                'uuid' => re('^\w+$'),
            },
            'err' => 0,
        },
        qq{Response data for "$description" looks sane}
    );
}

done_testing;

sub _get_deeper_stacktrace {
    return _get_stacktrace()
}
sub _get_stacktrace {
    return Devel::StackTrace->new();
}
