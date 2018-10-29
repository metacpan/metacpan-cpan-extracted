#!perl -T
use strict;
use warnings;
use Data::Dumper;
use JSON::MaybeXS;
use Test::Exception;
use Test::More;
use WebService::HMRC::CreateTestUser;

plan tests => 13;

my($create, $r, $body);


SKIP: {

    skip 'HMRC_SERVER_TOKEN environment variable not set', 13 unless $ENV{HMRC_SERVER_TOKEN};
    diag 'Executing tests against HMRC sandbox server';


    # Instatiate the basic object
    $create = WebService::HMRC::CreateTestUser->new();
    isa_ok($create, 'WebService::HMRC::CreateTestUser', 'WebService::HMRC::CreateTestUser object created');


    # Set authorisation token
    ok($create->auth->server_token($ENV{HMRC_SERVER_TOKEN}), 'set server token');


    # Create an individual
    isa_ok(
        $r = $create->individual({ services => ['self-assessment'] }),
        'WebService::HMRC::Response',
        'create individual returns response object'
    );
    ok($r->is_success, 'create individual api call returns success');
    ok($r->data->{individualDetails}, 'new individual user created');
    ok($r->data->{saUtr}, 'new individual user registered for self assessment');
    if($r->is_success) {
        diag 'Individual user created:';
        diag Dumper $r->data;
    }


    # Create an organisation
    isa_ok(
        $r = $create->organisation({ services => ['corporation-tax'] }),
        'WebService::HMRC::Response',
        'create organisation returns response object'
    );
    ok($r->is_success, 'create organisation api call returns success');
    ok($r->data->{organisationDetails}, 'new organisation user created');
    ok($r->data->{ctUtr}, 'new organisation user registered for corporation tax');
    if($r->is_success) {
        diag 'Organisation user created:';
        diag Dumper $r->data;
    }


    # Create an agent
    isa_ok(
        $r = $create->agent({ services => ['agent-services'] }),
        'WebService::HMRC::Response',
        'create agent returns response object'
    );
    ok($r->is_success, 'create agent api call returns success');
    ok($r->data->{agentServicesAccountNumber}, 'new agent user created');
    if($r->is_success) {
        diag 'Agent user created:';
        diag Dumper $r->data;
    }
}
