use strict;
use warnings;

use Test::More;
use JSON::PP;
use Time::Local qw(timegm);
use File::Spec;
use FindBin qw($Bin);

use WebService::Litportnet::FreeProxy;

# generatedAt in the fixture is 2026-09-10T00:00:00.000Z
my $NOW = timegm( 0, 0, 0, 10, 8, 2026 );

my $FIXTURE_PATH = File::Spec->catfile( $Bin, 'fixtures', 'api-snapshot.json' );

sub fixture {
    open my $fh, '<', $FIXTURE_PATH or die "cannot open $FIXTURE_PATH: $!";
    local $/;
    my $json = <$fh>;
    close $fh;
    return JSON::PP->new->decode($json);
}

sub client {
    my %args      = @_;
    my $body      = exists $args{body}   ? $args{body}   : fixture();
    my $status    = exists $args{status} ? $args{status} : 200;
    my $transport = $args{transport} || sub { return ( $status, {}, $body ) };

    my %ctor = ( now => sub { $NOW }, transport => $transport );
    $ctor{timeout} = $args{timeout} if exists $args{timeout};

    return WebService::Litportnet::FreeProxy->new(%ctor);
}

# --- normalization, sorting, and nullable uptime_7d -----------------------

{
    my $rows = client()->get_proxies;
    is( scalar @$rows, 6, 'default filters keep all six fresh rows' );

    is( $rows->[0]{url}, 'http://8.8.8.8:8080', 'highest uptime_7d sorts first' );
    is( $rows->[0]{latency_ms}, 120, 'responseTimeMs is rounded to an integer' );
    is( $rows->[0]{asn}, 15169, 'string ASN "AS15169" is parsed to an integer' );
    is( $rows->[1]{asn}, 54113, 'numeric ASN is passed through as an integer' );

    my @urls = map { $_->{url} } @$rows;
    is_deeply(
        \@urls,
        [
            'http://8.8.8.8:8080',       'socks5://185.199.108.40:1081',
            'http://203.0.114.9:3128',   'socks5://1.1.1.1:1080',
            'socks4://45.33.12.7:4145',  'http://104.21.4.3:80',
        ],
        'sort order: defined uptime_7d desc, then defined latency_ms asc, then url'
    );

    my ($low_checks) = grep { $_->{url} eq 'socks4://45.33.12.7:4145' } @$rows;
    ok( !defined $low_checks->{uptime_7d}, 'uptime_7d is undef when checks_7d < 50' );

    my ($null_city) = grep { $_->{url} eq 'socks5://1.1.1.1:1080' } @$rows;
    ok( !defined $null_city->{city}, 'null geoCity maps to undef city' );

    my ($null_latency) = grep { $_->{url} eq 'http://203.0.114.9:3128' } @$rows;
    ok( !defined $null_latency->{latency_ms}, 'null responseTimeMs maps to undef latency_ms' );
}

# --- filters ----------------------------------------------------------------

{
    my $c = client();

    is( scalar @{ $c->get_proxies( { protocol => 'socks5' } ) }, 2, 'protocol filter' );
    is( scalar @{ $c->get_proxies( { min_uptime_7d => 90 } ) }, 2, 'min_uptime_7d filter' );
    is( scalar @{ $c->get_proxies( { country => 'US' } ) }, 2, 'country filter is case-insensitive' );
    is( scalar @{ $c->get_proxies( { https => 1 } ) }, 3, 'https true filter excludes false/undef' );
    is( scalar @{ $c->get_proxies( { https => 0 } ) }, 2, 'https false filter excludes true/undef' );
    is( scalar @{ $c->get_proxies( { max_latency_ms => 100 } ) }, 1, 'max_latency_ms filter' );
    is( scalar @{ $c->get_proxies( { min_checks_7d  => 60 } ) }, 3, 'min_checks_7d filter' );
    is( scalar @{ $c->get_proxies( { limit => 0 } ) }, 0, 'limit 0 returns no rows' );
    is( scalar @{ $c->get_proxies( { limit => 2 } ) }, 2, 'limit truncates the sorted rows' );

    is( scalar @{ $c->pick_best(1) }, 1, 'pick_best trims to the requested count' );
    is( $c->pick_best(1)->[0]{url}, 'http://8.8.8.8:8080', 'pick_best keeps the top-ranked row' );
    is( scalar @{ $c->pick_best(100) }, 6, 'pick_best is capped at the available rows' );
}

# --- freshness window ---------------------------------------------------

{
    my $stale = fixture();
    $stale->{proxies}[5]{pingAt} = '2026-09-09T23:29:59.000Z';    # 1s outside the default 30 min window
    is( scalar @{ client( body => $stale )->get_proxies }, 5, 'stale row is dropped by the freshness filter' );

    my $edge = fixture();
    $edge->{proxies}[5]{pingAt} = '2026-09-09T23:30:00.000Z';     # exactly at the cutoff
    is( scalar @{ client( body => $edge )->get_proxies }, 6, 'row exactly at the cutoff is kept' );
}

# --- envelope and HTTP errors -----------------------------------------------

{
    eval { client( status => 429 )->get_proxies };
    my $err = $@;
    ok( $err, 'non-2xx status raises' );
    isa_ok( $err, 'WebService::Litportnet::FreeProxy::Error::HttpError' );
    is( $err->status, 429, 'HttpError carries the status' );
    like( "$err", qr/HTTP 429/, 'HttpError stringifies with the status' );

    eval {
        client( body => { generatedAt => '2026-09-10T00:00:00Z', count => 0, truncated => 1, proxies => [] } )
            ->get_proxies;
    };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::SnapshotTruncatedError', 'truncated snapshot' );

    eval {
        client( body => { generatedAt => '2026-09-09T23:57:00Z', count => 0, proxies => [] } )->get_proxies;
    };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError', 'generatedAt too old' );

    my $invalid = fixture();
    $invalid->{proxies}[0]{host} = '127.0.0.1';
    eval { client( body => $invalid )->get_proxies };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError', 'private-range host is rejected' );

    eval { client( body => '{broken' )->get_proxies };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError', 'malformed JSON body' );
}

# --- timeout / transport plumbing -------------------------------------------

{
    my $received;
    my $timeout_client = WebService::Litportnet::FreeProxy->new(
        timeout   => 1.5,
        now       => sub { $NOW },
        transport => sub {
            my ( $url, $timeout ) = @_;
            $received = $timeout;
            WebService::Litportnet::FreeProxy::Error::TimeoutError->throw(
                'Snapshot request timed out after 1.5s');
        },
    );

    eval { $timeout_client->get_proxies };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::TimeoutError' );
    is( $received, 1.5, 'the configured timeout is forwarded to the transport' );
}

done_testing;
