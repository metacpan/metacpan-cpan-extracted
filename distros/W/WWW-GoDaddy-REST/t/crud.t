#!perl

use strict;
use warnings;

use FindBin;
use WWW::GoDaddy::REST;
use LWP::UserAgent;
use Test::Exception;
use Test::MockObject::Extends;
use Test::More;
use WWW::GoDaddy::REST::Util qw(is_json json_decode json_encode );

my $URL_BASE    = 'http://example.com/v1';
my $SCHEMA_FILE = "$FindBin::Bin/schema.json";
my $SLOW_SPEED  = 3;

my $lwp_mock = Test::MockObject::Extends->new( LWP::UserAgent->new );
$lwp_mock->mock(
    'simple_request' => sub {
        my ( $self, $request ) = @_;

        my $url = $request->uri->as_string;

        my $content_json = $request->decoded_content;
        my $content_perl = is_json($content_json) ? json_decode($content_json) : undef;

        my $echoResponse = {
            'id'                     => 'echo',
            'type'                   => 'echoResponse',
            'child_resource'         => { 'id' => 'child' },
            'request_method'         => $request->method,
            'request_uri'            => $url,
            'request_content'        => $content_json,
            'request_content_struct' => $content_perl,
            'links'                  => {
                'self'    => $url,
                'schemas' => "http://example.com/v1/schemas"
            },
            'actions' => { 'reverb' => "$url?reverb", 'echoCount' => "$url?echoCount" },
        };

        my $content;

        if ( $request->method eq 'DELETE' ) {
            if ( $request->uri->path =~ /slow/ ) {
                sleep $SLOW_SPEED;
            }
            return HTTP::Response->new(204);
        }
        elsif ( $request->uri->path =~ m|^/v1/respondNonResource| ) {
            $content = $content_json;
        }
        elsif ( $request->uri->path =~ m|^/v1/echoResponses/?$| ) {

            # collection
            $content = {
                "type"         => "collection",
                "resourceType" => "echoResponse",
                "links"        => {
                    "self"    => $url,
                    "schemas" => "http://example.com/v1/schemas"
                },
                "data" => []
            };
            for ( 0 .. 3 ) {
                my %copy = %{$echoResponse};
                $copy{id}                = "echo$_";
                $copy{links}->{self}     = "http://example.com/v1/echoResponses/echo$_";
                $copy{actions}->{reverb} = "http://example.com/v1/echoResponses/echo$_?reverb";
                push @{ $content->{data} }, \%copy;
            }
            $content = json_encode($content);
        }
        elsif ( $request->uri->path =~ m|^/v1/echoResponseChildren/(.*)$| ) {
            $echoResponse->{id} = $1;
            $content = json_encode($echoResponse);
        }
        elsif ( $request->uri->path =~ m|^/v1/slowResponses/(.*)$| ) {
            $echoResponse->{id} = $1;
            if ( $url =~ m|die| ) {
                die('internal die - not alarm');
            }
            sleep $SLOW_SPEED;
            $content = json_encode($echoResponse);
        }
        else {
            if ( $url =~ m|^http://example.com/v1/echoResponses/(.*)$| ) {
                $echoResponse->{id} = $1;
            }

            $content = json_encode($echoResponse);
        }

        my $response = HTTP::Response->new(200);
        if ( $url =~ /badJson/ ) {
            $response->content('badJson');
        }
        else {
            $response->content($content);
        }
        return $response;
    }
);

my $client = WWW::GoDaddy::REST->new(
    {   url          => $URL_BASE,
        user_agent   => $lwp_mock,
        schemas_file => $SCHEMA_FILE,
    }
);

subtest 'query_by_id' => sub {
    my $response = $client->query_by_id( 'echoResponse', '1234' );
    is( $response->f('request_method'), "GET", "id only: requested method is good" );
    is( $response->f('request_uri'),
        "$URL_BASE/echoResponses/1234",
        "id only: requested URI is good"
    );
    is( $response->f('request_content'), '', "id only: requested content is empty" );

    $response = $client->query_by_id( 'echoResponse', '1234', { showAccounts => 'true' } );
    is( $response->f('request_method'), "GET", "complex: requested method is good" );
    is( $response->f('request_uri'),
        "$URL_BASE/echoResponses/1234?showAccounts=true",
        "complex: requested URI is good"
    );
    is( $response->f('request_content'), '', "complex: requested content is empty" );

    my $timeout_sooner = $SLOW_SPEED - 2;
    my $timeout_later  = $SLOW_SPEED + 2;

    $client->timeout($timeout_sooner);
    throws_ok { $client->query_by_id( 'slowResponse', '12345' ) }
    qr/timed out while calling 'GET' 'http:\/\/example.com\/v1\/slowResponses\/12345'/,
        'query was slow: and over timeout - die';

    $client->timeout($timeout_later);
    lives_ok { $response = $client->query_by_id( 'slowResponse', '12345' ) }
    'query was slow: but below timeout - live';
    is( $response->f('request_method'),
        "GET", "query was slow: timeout global: requested method is good" );
    is( $response->f('request_uri'),
        "$URL_BASE/slowResponses/12345",
        "query was slow: timeout global: requested URI is good"
    );
    is( $response->f('request_content'),
        '', "query was slow: timeout global: requested content is empty" );

    $client->timeout($timeout_sooner);
    lives_ok {
        $response
            = $client->query_by_id( 'slowResponse', '12345', undef, { timeout => $timeout_later } )
    }
    'query was slow: global timeout would fail - single call override';
    is( $response->f('request_method'),
        "GET", "query was slow: timeout override: requested method is good" );
    is( $response->f('request_uri'),
        "$URL_BASE/slowResponses/12345",
        "query was slow: timeout override: requested URI is good"
    );
    is( $response->f('request_content'),
        '', "query was slow: timeout override: requested content is empty" );

    $client->timeout($timeout_sooner);
    throws_ok { $client->query_by_id( 'slowResponse', '12345', { badJson => 1 } ) }
    qr/timed out while calling 'GET' 'http:\/\/example.com\/v1\/slowResponses\/12345\?badJson=1'/,
        'query was slow: and over timeout - die 2';

    $client->timeout($timeout_later);
    lives_ok {
        $response = $client->query_by_id(
            'slowResponse', '12345',
            { timeout => 1 },
            { timeout => $timeout_later }
            )
    }
    'timeout param + override: lives';
    is( $response->f('request_method'),
        "GET", "timeout param + override: requested method is good" );
    is( $response->f('request_uri'),
        "$URL_BASE/slowResponses/12345?timeout=1",
        "timeout param + override: requested URI is good"
    );
    is( $response->f('request_content'),
        '', "timeout param + override: requested content is empty" );

    $client->timeout($timeout_later);
    throws_ok {
        $client->query_by_id( 'slowResponse', '12345', undef, { timeout => $timeout_sooner } )
    }
    qr/timed out while calling 'GET' 'http:\/\/example.com\/v1\/slowResponses\/12345'/,
        'query was slow: global timeout would pass - single call override fail';

    $client->timeout($timeout_later);
    throws_ok { $client->query_by_id( 'slowResponse', '12345', { 'die' => '1' } ) }
    qr/internal die - not alarm/, 'lwp die is preserved';

};

subtest 'query' => sub {
    my $col = $client->query( 'echoResponse', { 'name' => 'foo' } );
    is( $col->type, 'collection', "scalar context gives back a collection" );
    my ($item) = $col->items();
    is( $item->type,                'echoResponse', 'correct item type returned' );
    is( $item->f('request_method'), "GET",          "requested method is good" );
    is( $item->f('request_uri'), "$URL_BASE/echoResponses?name=foo", "requested URI is good" );
    is( $item->f('request_content'), '', "requested content is empty" );

    my @items = $client->query( 'echoResponse', { 'name' => 'bar' } );
    ($item) = @items;
    is( $item->type,                'echoResponse', 'correct item type returned' );
    is( $item->f('request_method'), "GET",          "complex: requested method is good" );
    is( $item->f('request_uri'),
        "$URL_BASE/echoResponses?name=bar",
        "complex: requested URI is good"
    );
    is( $item->f('request_content'), '', "complex: requested content is empty" );

    $item = $client->query( 'echoResponse', '1234' );
    is( $item->f('request_method'), "GET", "id only: requested method is good" );
    is( $item->f('request_uri'), "$URL_BASE/echoResponses/1234", "id only: requested URI is good" );
    is( $item->f('request_content'), '', "id only: requested content is empty" );

    $item = $client->query( 'echoResponse', '1234', { showAccounts => 'true' } );
    is( $item->f('request_method'), "GET", "id + extra: requested method is good" );
    is( $item->f('request_uri'),
        "$URL_BASE/echoResponses/1234?showAccounts=true",
        "id + extra: requested URI is good"
    );
    is( $item->f('request_content'), '', "id + extra: requested content is empty" );

    my $id = '123';
    @items = $client->query(
        'echoResponse',
        {   'id'           => $id,
            'showAccounts' => [
                { 'value' => 'true' }    # implicit 'eq'
            ],
        }
    );
    ($item) = @items;
    is( $item->type,                'echoResponse', 'complex 2: correct item type returned' );
    is( $item->f('request_method'), "GET",          "complex 2: requested method is good" );
    is( $item->f('request_uri'),
        sprintf( '%s/echoResponses?id=123&showAccounts=true', $URL_BASE, $id ),
        "complex 2: requested URI is good"
    );
    is( $item->f('request_content'), '', "complex 2: requested content is empty" );

    my $timeout_sooner = $SLOW_SPEED - 2;
    my $timeout_later  = $SLOW_SPEED + 2;

    $client->timeout($timeout_later);
    $item = $client->query( 'slowResponse', '1234', { timeout => '1' } );
    is( $item->f('request_method'), "GET", "timeout param: id + extra: requested method is good" );
    is( $item->f('request_uri'),
        "$URL_BASE/slowResponses/1234?timeout=1",
        "timeout param: id + extra: ensure timeout is not seen as http option"
    );
    is( $item->f('request_content'), '', "timeout param: id + extra: requested content is empty" );

    $client->timeout($timeout_sooner);
    $item = $client->query( 'slowResponse', '1234', { timeout => '1' },
        { timeout => $timeout_later } );
    is( $item->f('request_method'),
        "GET", "timeout param + timeout override: id + extra: requested method is good" );
    is( $item->f('request_uri'),
        "$URL_BASE/slowResponses/1234?timeout=1",
        "timeout param + timeout override: id + extra: ensure timeout is not seen as http option"
    );
    is( $item->f('request_content'),
        '', "timeout param + timeout override: id + extra: requested content is empty" );

    $client->timeout($timeout_sooner);
    throws_ok { $client->query( 'slowResponse', '1234' ) }
    qr/timed out while calling 'GET' 'http:\/\/example.com\/v1\/slowResponses\/1234'/,
        'query was slow: and over timeout - die';

};

subtest 'non resource responding' => sub {

    # test the case where we don't return a resource
    my $response;

    $response = $client->create( 'respondNonResource', "asdf" );
    is( $response->data, "asdf", "simple string response is ok" );

    $response = $client->create( 'respondNonResource', "3" );
    is( $response->data, "3", "simple number response is ok" );

    $response = $client->create( 'respondNonResource', 'asdf asdf' );
    is( $response->data, "asdf asdf", "simple string response is ok" );

};

subtest 'save' => sub {
    my $response = $client->query_by_id( 'echoResponse', '1234' );
    $response->f( 'new_field', 'new_value' );

    my $result    = $response->save();
    my $submitted = $result->f('request_content_struct');

    is( $result->f('request_method'), 'PUT', 'http method is PUT' );
    is( $result->f('request_uri'),
        'http://example.com/v1/echoResponses/1234',
        'PUT url is correct'
    );
    is( $submitted->{new_field}, 'new_value', 'test submit field was submitted and matched' );

    my $timeout_sooner = $SLOW_SPEED - 2;
    my $timeout_later  = $SLOW_SPEED + 2;

    $response
        = $client->query_by_id( 'slowResponse', '1234', undef, { timeout => $timeout_later } );
    throws_ok { $response->save( { timeout => $timeout_sooner } ) }
    qr/timed out while calling 'PUT' 'http:\/\/example.com\/v1\/slowResponses\/1234'/,
        'test submit - timeout override';
};

subtest 'delete' => sub {
    my $response = $client->query_by_id( 'echoResponse', '1234' );
    $response->f( 'new_field', 'new_value' );

    my $result = $response->delete();
    is_deeply( $result->fields, {}, 'fields are empty' );
    ok( $result->http_response->is_success, 'DELETE was ok' );
    is( $result->http_response->code, 204, 'DELETE came back with expected response code' );

    my $timeout_sooner = $SLOW_SPEED - 2;
    my $timeout_later  = $SLOW_SPEED + 2;

    $response
        = $client->query_by_id( 'slowResponse', '1234', undef, { timeout => $timeout_later } );
    is_deeply( $result->fields, {}, 'timeout param: fields are empty' );
    ok( $result->http_response->is_success, 'timeout param: DELETE was ok' );
    is( $result->http_response->code,
        204, 'timeout param: DELETE came back with expected response code' );
    throws_ok { $response->delete( { timeout => $timeout_sooner } ) }
    qr/timed out while calling 'DELETE' 'http:\/\/example.com\/v1\/slowResponses\/1234'/,
        'test submit - timeout override';
};

subtest 'follow_link' => sub {
    my $response = $client->query_by_id( 'echoResponse', '1234' );
    my $fetched = $response->follow_link('schemas');

    is( $fetched->f('request_method'), 'GET', 'link HTTP method ok' );
    is( $fetched->f('request_uri'), 'http://example.com/v1/schemas', 'link url ok' );

    dies_ok { $response->follow_link('asfasfsafasf') } 'bad fetch url should die';
};

subtest 'do_action' => sub {
    my $response = $client->query_by_id( 'echoResponse', '1234' );
    my $done1 = $response->do_action('reverb');
    is( $done1->f('request_method'), 'POST', 'action http method is POST' );
    is( $done1->f('request_uri'),
        'http://example.com/v1/echoResponses/1234?reverb',
        'action url is correct'
    );
    is( $done1->f('request_content'), '', 'action request content is empty' );

    my $done2 = $response->do_action( 'reverb', { 'amount' => 'alot' } );
    is( $done2->f('request_method'), 'POST', 'action http method is POST' );
    is( $done2->f('request_uri'),
        'http://example.com/v1/echoResponses/1234?reverb',
        'action url is correct'
    );
    isnt( $done2->f('request_content'), '', 'action request content is present' );
    is_deeply(
        $done2->f('request_content_struct'),
        { 'amount' => 'alot' },
        'action request content is correct'
    );

    my $done3 = $response->do_action( 'echoCount', "3" );
    is( $done3->f('request_method'), 'POST', 'action http method is POST' );
    is( $done3->f('request_uri'),
        'http://example.com/v1/echoResponses/1234?echoCount',
        'action url is correct'
    );
    is( $done3->f('request_content'),        '"3"', 'action request content is present' );
    is( $done3->f('request_content_struct'), '3',   'perl data struct is correct' );

    my $child = $response->f_as_resources('child_resource');
    is( $child->id,   'child',             'child resource id matches' );
    is( $child->type, 'echoResponseChild', 'child resource type matches' );
    my $done4 = $child->do_action( 'exampleAction', {} );
    is( $done4->f('request_method'), 'POST', 'action http method is POST' );
    is( $done4->f('request_uri'),
        'http://example.com/v1/echoResponseChildren/child?exampleAction',
        'action url is correct'
    );

    dies_ok { $response->do_action('noExiste') } 'no action in fields or schema';

};

done_testing();
