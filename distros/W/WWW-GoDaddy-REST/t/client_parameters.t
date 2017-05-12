#!perl

use strict;
use warnings;

use Carp qw/cluck/;

use File::Slurp qw( slurp );
use FindBin;
use LWP::UserAgent;
use Test::MockObject::Extends;
use Test::More;
use Test::Exception;
use WWW::GoDaddy::REST;
use WWW::GoDaddy::REST::Resource;
use WWW::GoDaddy::REST::Schema;

my $URL_BASE    = 'http://example.com/v1';
my $SCHEMA_FILE = "$FindBin::Bin/schema.json";
my $SCHEMA_JSON = slurp($SCHEMA_FILE);

subtest 'url' => sub {
    throws_ok { my $client = WWW::GoDaddy::REST->new() } qr/\(url\) is required/, 'url - required';
    lives_ok { my $client = WWW::GoDaddy::REST->new( { url => $URL_BASE } ) } 'url - provided';
};

subtest 'timeout' => sub {
    my $client = WWW::GoDaddy::REST->new( url => $URL_BASE );
    is( $client->timeout, 10, 'default timeout is set' );
    $client->timeout(20);
    is( $client->timeout, 20, 'timeout can be set' );
    throws_ok { $client->timeout(-1); } qr/Attribute \(timeout\) does not pass/,
        'timeout must be > 0';

    throws_ok { my $client => WWW::GoDaddy::REST->new( url => $URL_BASE, timeout => 0 ) }
    qr/Attribute \(timeout\) does not pass/, 'timeout must be > 0';
};

subtest 'user_agent' => sub {
    my $ua_custom = LWP::UserAgent->new( agent => 'testing and should match' );
    my $client = WWW::GoDaddy::REST->new( { url => $URL_BASE } );
    my $defaulted_ua = $client->user_agent;
    isa_ok( $defaulted_ua, 'LWP::UserAgent', 'user_agent - default is filled in' );
    is_deeply( $client->user_agent($ua_custom), $ua_custom, 'user_agent - read write attribute' );

    $client = WWW::GoDaddy::REST->new( { url => $URL_BASE, user_agent => $ua_custom } );
    is_deeply( $client->user_agent, $ua_custom,
        'user_agent - passed in constructor overrides default' );
};

subtest 'basic auth' => sub {
    my $USERNAME = 'a-boy';
    my $PASSWORD = 'and-his-blob';

    throws_ok {
        my $client = WWW::GoDaddy::REST->new( { url => $URL_BASE, basic_username => $USERNAME } )
    }
    qr/\(basic_password\) is required/, 'basic_password is required if user is present';

    throws_ok {
        my $client = WWW::GoDaddy::REST->new( { url => $URL_BASE, basic_password => $PASSWORD } )
    }
    qr/\(basic_username\) is required/, 'basic_username is required if password is present';

    lives_ok {
        my $client = WWW::GoDaddy::REST->new(
            { url => $URL_BASE, basic_username => $USERNAME, basic_password => $PASSWORD } )
    }
    'basic_username and basic_password are provided';
};

subtest 'schemas' => sub {

    my $client_ok = WWW::GoDaddy::REST->new( { url => $URL_BASE } );

    throws_ok {
        my $client = WWW::GoDaddy::REST->new( { url => $URL_BASE, schemas => ['asdf'] } );
    }
    qr/Attribute \(schemas\) does not pass the type constraint/,
        'schemas must only contain ::Schema objects';

    throws_ok {
        my $client = WWW::GoDaddy::REST->new(
            {   url => $URL_BASE,
                schemas =>
                    [ WWW::GoDaddy::REST::Resource->new( { client => $client_ok, fields => {} } ) ]
            }
        );
    }
    qr/Attribute \(schemas\) does not pass the type constraint/,
        'schemas must only contain ::Schema objects';

    lives_ok {
        my $client = WWW::GoDaddy::REST->new(
            {   url => $URL_BASE,
                schemas =>
                    [ WWW::GoDaddy::REST::Schema->new( { client => $client_ok, fields => {} } ) ]
            }
        );
    }
    'schema passes basic type contraints';

};

subtest 'schema lazy loading' => sub {

    my $schema_attempted_from_http = 0;

    my $lwp_mock = Test::MockObject::Extends->new( LWP::UserAgent->new );
    $lwp_mock->mock(
        'simple_request' => sub {
            my ( $self, $request ) = @_;

            my $method = $request->method;
            my $uri    = $request->uri;

            if ( $uri eq "$URL_BASE/schemas/" ) {
                my $response = HTTP::Response->new(200);
                $response->content($SCHEMA_JSON);
                $schema_attempted_from_http++;
                return $response;
            }
            die("unexpected url encountered: $method => $uri");
        }
    );

    my $client = WWW::GoDaddy::REST->new(
        {   url          => $URL_BASE,
            schemas_file => $SCHEMA_FILE,
            user_agent   => $lwp_mock
        }
    );
    $client->schemas();
    ok( !$schema_attempted_from_http, 'schemas_file parameter should prevent http call' );

    dies_ok {
        $client = WWW::GoDaddy::REST->new(
            { url => $URL_BASE, schemas_file => 'sdafasfsdaf', user_agent => $lwp_mock } );
    }
    'schemas_file bad file path should die';

    $client = WWW::GoDaddy::REST->new( { url => $URL_BASE, user_agent => $lwp_mock } );
    ok( !$schema_attempted_from_http,
        'schemas_file missing so load from base url - but not until asked' );
    $client->schemas();
    ok( $schema_attempted_from_http,
        'schemas_file missing so load from base url - since we asked' );

};

done_testing();
