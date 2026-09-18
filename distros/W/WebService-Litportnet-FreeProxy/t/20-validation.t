use strict;
use warnings;

use Test::More;
use JSON::PP;
use Time::Local qw(timegm);
use File::Spec;
use FindBin qw($Bin);

use WebService::Litportnet::FreeProxy;

my $NOW = timegm( 0, 0, 0, 10, 8, 2026 );    # 2026-09-10T00:00:00Z

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
    return WebService::Litportnet::FreeProxy->new( now => sub { $NOW }, transport => $transport );
}

# --- constructor validation --------------------------------------------------

for my $bad_timeout ( 0, -1, 'abc', 9**9**9, ( 9**9**9 - 9**9**9 ) ) {
    eval { WebService::Litportnet::FreeProxy->new( timeout => $bad_timeout ) };
    isa_ok(
        $@,
        'WebService::Litportnet::FreeProxy::Error::FilterValidationError',
        "constructor rejects timeout of " . ( defined $bad_timeout ? $bad_timeout : 'undef' )
    );
}

ok(
    WebService::Litportnet::FreeProxy->new( timeout => 5 ),
    'constructor accepts a positive finite timeout'
);

# --- row-level validation -----------------------------------------------

my %invalid_rows = (
    'undef host'                 => { host          => undef },
    'unroutable host (loopback)' => { host          => '127.0.0.1' },
    'unroutable host (private)'  => { host          => '10.1.2.3' },
    'port too low'                => { port          => 0 },
    'port too high'                => { port          => 65_536 },
    'non-numeric port'           => { port          => 'abc' },
    'unknown protocol'           => { protocol      => 'ftp' },
    'unknown anonymity'          => { anonymity     => 'stealth' },
    'numeric geoCountry'          => { geoCountry    => 123 },
    'three-letter geoCountry'    => { geoCountry    => 'usa' },
    'boolean asn'                 => { asn           => JSON::PP::true },
    'negative-looking asn string' => { asn           => 'AS-5' },
    'non-string geoRegion'       => { geoRegion     => JSON::PP::true },
    'non-boolean https'          => { https         => 'yes' },
    'infinite responseTimeMs'    => { responseTimeMs => 9**9**9 },
    'negative checks7d'           => { checks7d      => -1 },
    'negative sourcesCount'       => { sourcesCount  => -1 },
    'timezone-less pingAt'       => { pingAt        => '2026-09-10T00:00:00' },
    'impossible createdAt date'  => { createdAt     => '2026-02-30T00:00:00Z' },
);

for my $label ( sort keys %invalid_rows ) {
    my $invalid = fixture();
    my %overrides = %{ $invalid_rows{$label} };
    $invalid->{proxies}[0]{$_} = $overrides{$_} for keys %overrides;

    eval { client( body => $invalid )->get_proxies };
    isa_ok(
        $@,
        'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError',
        "invalid row is rejected: $label"
    );
}

# --- envelope-level validation ------------------------------------------

{
    my $bad_count = fixture();
    $bad_count->{count} = 99;
    eval { client( body => $bad_count )->get_proxies };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError', 'count mismatch is rejected' );

    my $future = fixture();
    $future->{generatedAt} = '2026-09-10T00:00:06.000Z';    # 6s in the future, outside the +5s window
    eval { client( body => $future )->get_proxies };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError', 'generatedAt too far in the future is rejected' );

    my $not_array = fixture();
    $not_array->{proxies} = { oops => 1 };
    eval { client( body => $not_array )->get_proxies };
    isa_ok( $@, 'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError', 'non-array proxies is rejected' );

    my $bad_truncated_type = fixture();
    $bad_truncated_type->{truncated} = 'true';
    eval { client( body => $bad_truncated_type )->get_proxies };
    isa_ok(
        $@,
        'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError',
        'wrongly-typed truncated value is rejected as malformed rather than treated as truncated'
    );
}

# --- filter validation --------------------------------------------------

my %invalid_filters = (
    'https as a bare string'       => { https => 'yes' },
    'protocol as a non-member'     => { protocol => 0 },
    'country with three letters'  => { country => 'usa' },
    'anonymity not in the allowed set' => { anonymity => 'stealth' },
    'negative max_latency_ms'      => { max_latency_ms => -1 },
    'negative min_uptime_7d'       => { min_uptime_7d  => -1 },
    'negative min_checks_7d'       => { min_checks_7d  => -1 },
    'negative limit'                => { limit => -1 },
    'checked_within_min of zero'   => { checked_within_min => 0 },
    'checked_within_min above 1440' => { checked_within_min => 1441 },
    'non-integer checked_within_min' => { checked_within_min => 1.5 },
    'unknown filter key'            => { unknown => 1 },
);

for my $label ( sort keys %invalid_filters ) {
    eval { client()->get_proxies( $invalid_filters{$label} ) };
    isa_ok(
        $@,
        'WebService::Litportnet::FreeProxy::Error::FilterValidationError',
        "invalid filter is rejected: $label"
    );
}

# --- pick_best count validation ------------------------------------------

for my $bad_count ( -1, 'abc', 1.5 ) {
    eval { client()->pick_best($bad_count) };
    isa_ok(
        $@,
        'WebService::Litportnet::FreeProxy::Error::FilterValidationError',
        "pick_best rejects a bad count: " . $bad_count
    );
}

ok( client()->pick_best(0), 'pick_best accepts a count of zero' );

done_testing;
