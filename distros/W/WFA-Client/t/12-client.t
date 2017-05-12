#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

use HTTP::Response;
use Test::LWP::UserAgent;
use WFA::Client;

my $ua = Test::LWP::UserAgent->new();
$ua->map_response(
    qr{/job$},
    HTTP::Response->new(
        200,
        undef,
        undef,
        '<arbitraryXml>5</arbitraryXml>',
    ),
);

$ua->map_response(
    qr{/rest/workflows$},
    HTTP::Response->new(
        200,
        undef,
        undef,
        '<collection>
            <workflow><name>wf1</name></workflow>
            <workflow><name>wf2</name></workflow>
        </collection>',
    ),
);

$ua->map_response(
    qr{name=},
    HTTP::Response->new(
        200,
        undef,
        undef,
        '<collection>
            <workflow><name>wf1</name></workflow>
        </collection>',
    ),
);

my $wfa_client = WFA::Client->new(
    server   => 'server',
    username => 'username',
    password => 'password',
    ua_obj   => $ua,
);

subtest lowlevel => sub {
    my %expected_parameters = (foo => 'bar', bar => 'baz');
    
    my $xml_parameter_blob = $wfa_client->construct_xml_request_parameters(%expected_parameters);
    
    my %actual_parameters = map { $_->{key} => $_->{value} } @{ $wfa_client->xml_obj()->XMLin($xml_parameter_blob)->{workflowInput}->{userInputValues}->{userInputEntry} };
    
    is_deeply(
        \%actual_parameters,
        \%expected_parameters,
    );

    my $response = $wfa_client->submit_wfa_request('https://server/rest/workflows/uuid/job', $xml_parameter_blob);
    my $request = $ua->last_http_request_sent();

    is_deeply(
        $response,
        { arbitraryXml => 5 },
    );

    is(
        $request->method(),
        'POST',
    );

    is(
        $request->uri(),
        'https://server/rest/workflows/uuid/job',
    );

    is(
        $request->content(),
        $xml_parameter_blob,
    );
};


subtest highlevel => sub {
    my @workflow_names = $wfa_client->get_workflow_names();
    is_deeply(
        \@workflow_names,
        [ 'wf1', 'wf2' ],
    );

    my $workflow = $wfa_client->get_workflow('wf1');

    isa_ok($workflow, 'WFA::Workflow');

    is($workflow->name(), 'wf1');
};

done_testing();
