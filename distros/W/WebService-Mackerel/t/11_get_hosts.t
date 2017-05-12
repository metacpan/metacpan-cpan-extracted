use strict;
use Test::More;
use Test::TCP qw(test_tcp);
use Plack::Loader;
use JSON qw/encode_json/;

use WebService::Mackerel;

my $endpoint = 'http://localhost';
my $path     = '/api/v0/hosts.json';
my $response_content = encode_json({
    "hosts" => [ {
        "createdAt" => 1416151310,
        "id"        => "test_host_id",
        "memo"      => "test memo",
        "role"      => { [ "test-role" ] },
    },]
});

subtest 'get_hosts' => sub {
    my $params = { service => 'perl', role => 'app',
        name => '10.0.1.10', status => 'working' };

    test_tcp(
        server => sub {
            my $port = shift;
            Plack::Loader->load('Standalone', port => $port)->run(
                sub {
                    my $env = shift;
                    my $req_path = $env->{PATH_INFO};
                    is $req_path, $path;

                    my $query = $env->{QUERY_STRING};
                    my %qparams = map { split '=', $_ } (split '&', $query);
                    is_deeply \%qparams, $params;

                    return [200, [], [$response_content]];
                }
            );
        },
        client => sub {
            my ($port, $server_pid) = @_;
            my $mackerel = WebService::Mackerel->new(
                api_key  => 'testapikey',
                service_name => 'test',
                mackerel_origin => "$endpoint:$port",
            );

            my $res = $mackerel->get_hosts($params);
            is_deeply $res, $response_content, 'get_hosts : response success';
        },
    );
};

subtest 'get_hosts with specifying multiple roles' => sub {
    test_tcp(
        server => sub {
            my $port = shift;
            Plack::Loader->load('Standalone', port => $port)->run(
                sub {
                    my $env = shift;
                    my $req_url = $env->{REQUEST_URI};
                    is $req_url, "$path?role=app&role=batch";

                    return [200, [], [$response_content]];
                }
            );
        },
        client => sub {
            my ($port, $server_pid) = @_;
            my $mackerel = WebService::Mackerel->new(
                api_key  => 'testapikey',
                service_name => 'test',
                mackerel_origin => "$endpoint:$port",
            );

            my @params = ( role => 'app', role => 'batch' );
            my $res = $mackerel->get_hosts(\@params);
            is_deeply $res, $response_content, 'get_hosts : response success';
        },
    );
};

done_testing;
