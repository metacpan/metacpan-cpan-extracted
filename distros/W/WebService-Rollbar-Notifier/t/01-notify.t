#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;
use Test::RequiresInternet 'api.rollbar.com' => 80;

use Devel::StackTrace;
use WebService::Rollbar::Notifier;

my $rollbar = WebService::Rollbar::Notifier->new(
    access_token => $ENV{TEST_ROLLBAR_ACCESS_TOKEN} || 'dc851d5abb5c41edad589c336d49004e',
    callback => undef, # block to read response
);

isa_ok $rollbar, 'WebService::Rollbar::Notifier';
can_ok $rollbar, qw/
    access_token  environment  code_version
    critical error warning info debug notify
    callback framework language server
/;

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
