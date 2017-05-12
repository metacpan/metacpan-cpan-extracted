use strict;
use warnings;

use Test::More 0.96;

use Cpanel::JSON::XS qw( encode_json );
use DateTime;
use HTTP::Response;
use Test::LWP::UserAgent;
use WebService::TeamCity;

my $uri;
my $ua = Test::LWP::UserAgent->new( network_fallback => 0 );
$ua->map_response(
    sub {
        return 1;
    },
    sub {
        my $req = shift;

        $uri = $req->uri;

        return HTTP::Response->new(
            200,
            undef,
            [ 'Content-Type' => 'application/json' ],
            encode_json( { build => [] } ),
        );
    }
);

{
    my $client = WebService::TeamCity->new(
        host     => 'example.com',
        user     => 'u',
        password => 'p',
        ua       => $ua,
    );

    my @tests = (
        [
            id => 'build42',
            '/httpAuth/app/rest/builds?locator=id%3Abuild42',
        ],
        [
            build_type => { id => 'bt42' },
            '/httpAuth/app/rest/builds?locator=buildType%3A(id%3Abt42)',
        ],
        [
            tags => [qw( foo bar baz )],
            '/httpAuth/app/rest/builds?locator=tags%3A(foo%2Cbar%2Cbaz)',
        ],
        [
            agent_name   => 'Bob',
            build_type   => { id => 'bt42' },
            count        => 42,
            lookup_limit => 100,
            personal     => 1,
            project      => { id => 'p84' },
            since_date => DateTime->new( year => 2016, time_zone => '-0300' ),
            start      => 7,
            status     => 'SUCCESS',
            tags       => [qw( x y )],
            '/httpAuth/app/rest/builds?locator='
                . 'agentName%3ABob%2C'
                . 'buildType%3A(id%3Abt42)%2C'
                . 'count%3A42%2C'
                . 'lookupLimit%3A100%2C'
                . 'personal%3Atrue%2C'
                . 'project%3A(id%3Ap84)%2C'
                . 'sinceDate%3A20160101T000000-0300%2C'
                . 'start%3A7%2C'
                . 'status%3ASUCCESS%2C'
                . 'tags%3A(x%2Cy)',
        ],
    );

    for my $test (@tests) {
        my $expect = pop @{$test};
        $client->builds( @{$test} );
        is(
            $uri->path_query,
            $expect,
            $expect,
        );
    }
}

done_testing();
