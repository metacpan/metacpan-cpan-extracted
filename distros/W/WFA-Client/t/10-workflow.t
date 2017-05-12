#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

use HTTP::Response;
use Test::LWP::UserAgent;
use WFA::Client;
use WFA::Workflow;

my $ua = Test::LWP::UserAgent->new();
$ua->map_response(
    qr//,
    HTTP::Response->new(
        200,
        undef,
        undef,
        '<job><jobId>5</jobId><workflow></workflow></job>',
    ),
);

my $wfa_client = WFA::Client->new(
    server   => 'server',
    username => 'username',
    password => 'password',
    ua_obj   => $ua,
);

my $wfa_response = {
    workflow => {
        returnParameters => {},
        certification => 'NONE',
        description => 'This is a test workflow. It asks for an email address and sends an email to that address to confirm it has succeeded.',
        'atom:link' => {
            'out-parameter' => { href => 'https://wfa/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/out' },
            execute         => { href => 'https://wfa/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/jobs' },
            export          => { href => 'https://wfa/rest/dars/26140bc4-4e99-4783-ba3d-8fd27f0c185d' },
            list            => { href => 'https://wfa/rest/workflows' },
            preview         => { href => 'https://wfa/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d/preview' },
            self            => { href => 'https://wfa/rest/workflows/26140bc4-4e99-4783-ba3d-8fd27f0c185d' },
        },
        categories => { category => 'Clone Operations' },
        uuid => '26140bc4-4e99-4783-ba3d-8fd27f0c185d',
        userInputList => {
            userInput => {
                Recipient => {
                    type      => 'String',
                    mandatory => 'true'
                },
                Message => {
                    mandatory   => 'false',
                    type        => 'String',
                    description => 'Test to be displayed in the message body; useful for testing parameter passing.'
                },
            },
        },
        version => {
            major    => '1',
            minor    => '2',
            revision => '3'
        },
        name => 'Test - Noop',
    },
};

my $workflow = WFA::Workflow->new(
    client   => $wfa_client,
    response => $wfa_response,
);

subtest metadata => sub {
    is($workflow->name(), $wfa_response->{workflow}->{name});
    is($workflow->description(), $wfa_response->{workflow}->{description});
    is($workflow->uuid(), $wfa_response->{workflow}->{uuid});

    is($workflow->version(), '1.2.3');
    is_deeply(
        { $workflow->parameters() },
        $wfa_response->{workflow}->{userInputList}->{userInput},
    );

    is($workflow->url_for_action('execute'), $wfa_response->{workflow}->{'atom:link'}->{execute}->{href});
};

subtest actions => sub {
    my %parameters = (
        p1 => 'v1',
        p2 => 'v2',
    );

    my $job = $workflow->execute(%parameters);

    isa_ok($job, 'WFA::Job');
    is($job->id(), 5);

    my $request = $ua->last_http_request_sent();

    is ($request->method(), 'POST');

    is($request->uri(), $workflow->url_for_action('execute'));

    is(
        length($request->content()),
        length($wfa_client->construct_xml_request_parameters(%parameters)),
    );
};

done_testing();
