package WebService::Litportnet::FreeProxy;

use strict;
use warnings;

our $VERSION = '0.001';

use HTTP::Tiny  ();
use JSON::PP    ();
use Time::Local ();
use Scalar::Util ();
use POSIX ();

=head1 NAME

WebService::Litportnet::FreeProxy - Client for Litport's free proxy snapshot API

=head1 SYNOPSIS

    use WebService::Litportnet::FreeProxy;

    my $client = WebService::Litportnet::FreeProxy->new;
    my $proxies = $client->pick_best(5, {
        protocol        => 'socks5',
        country         => 'us',
        max_latency_ms  => 500,
        min_uptime_7d   => 90,
        min_checks_7d   => 50,
        checked_within_min => 30,
    });
    print "$_->{url}\n" for @$proxies;

=head1 DESCRIPTION

C<WebService::Litportnet::FreeProxy> is a dependency-free (core-modules-only) Perl
client for Litport's API snapshot of verified HTTP, SOCKS4, and SOCKS5 proxies. It
fetches a JSON snapshot, validates its envelope and rows, normalizes each record into
a plain hash reference, applies caller-supplied filters, and returns the results
sorted by freshness-aware uptime and latency.

The client only retrieves proxy records; it does not route traffic through any proxy.
Free proxies are for testing only. Never send credentials, cookies, payment data, or
other private data through them.

The client is built on core modules, but C<IO::Socket::SSL> and C<Net::SSLeay> are required
runtime prerequisites: the default snapshot endpoint is https, and C<HTTP::Tiny> cannot
negotiate TLS without them. Pass a plain C<http> C<api_url>, or your own C<transport>
callback, if you need to avoid them.

=head1 CONSTRUCTOR

=head2 new

    my $client = WebService::Litportnet::FreeProxy->new(
        api_url   => $url,      # default https://litport.net/api/free-proxy/snapshot?checkedWithinMin=1440
        timeout   => 10,        # seconds, must be a positive finite number
        transport => sub { my ($url, $timeout) = @_; return ($status, $headers_hashref, $body_string) },
        now       => sub { time },
    );

C<transport> and C<now> are optional and mainly intended for deterministic tests.
When C<transport> is omitted, requests are made with L<HTTP::Tiny>. When C<now> is
omitted, it defaults to C<sub { time }> (current epoch seconds, UTC).

Throws C<WebService::Litportnet::FreeProxy::Error::FilterValidationError> if
C<timeout> is not a positive finite number.

=head1 METHODS

=head2 get_proxies

    my $proxies = $client->get_proxies(\%filters);

Fetches the snapshot, validates it, normalizes and filters the rows, and returns an
array reference of normalized proxy hash references (see L</FILTERS> for the record
and filter shapes). C<%filters> is optional.

=head2 pick_best

    my $proxies = $client->pick_best($n, \%filters);

Equivalent to calling C<get_proxies> and returning at most the first C<$n> results.
C<$n> must be a non-negative integer.

=head1 FILTERS

All filter keys are optional and use snake_case:

=over 4

=item * C<protocol> - one of C<http>, C<socks4>, C<socks5>

=item * C<country> - a two-letter ASCII country code, case-insensitive (normalized to lowercase)

=item * C<anonymity> - one of C<transparent>, C<anonymous>, C<elite>, C<unknown>

=item * C<https> - boolean or C<undef>; accepts Perl-style C<0>/C<1> and L<JSON::PP::Boolean> values

=item * C<max_latency_ms> - non-negative integer

=item * C<min_uptime_7d> - non-negative integer

=item * C<min_checks_7d> - non-negative integer

=item * C<checked_within_min> - integer from 1 to 1440, default 30

=item * C<limit> - non-negative integer

=back

Unknown filter keys raise C<WebService::Litportnet::FreeProxy::Error::FilterValidationError>.

Each normalized proxy record is a hash reference with the keys: C<protocol>, C<ip>,
C<port>, C<url>, C<country>, C<region>, C<city>, C<timezone>, C<asn>, C<asn_org>,
C<anonymity>, C<https>, C<latency_ms>, C<latency_median_ms>, C<uptime_24h>,
C<uptime_7d>, C<checks_7d>, C<exit_ip>, C<sources_count>, C<first_seen>,
C<last_checked>. C<uptime_7d> is C<undef> whenever a record has fewer than 50
seven-day checks. Results are sorted with defined C<uptime_7d> first (descending),
then defined C<latency_ms> first (ascending), then ascending C<url>.

=head1 ERRORS

All errors are blessed objects rooted at C<WebService::Litportnet::FreeProxy::Error>,
which overloads stringification to its message, so both C<ref($@)> and
C<$@-E<gt>isa(...)> work as expected in C<eval>/C<$@> or C<Try::Tiny>-style handling:

=over 4

=item * C<WebService::Litportnet::FreeProxy::Error> - base class

=item * C<WebService::Litportnet::FreeProxy::Error::TimeoutError> - the request timed out

=item * C<WebService::Litportnet::FreeProxy::Error::HttpError> - the HTTP status was outside 200..299; carries a C<status> accessor

=item * C<WebService::Litportnet::FreeProxy::Error::SnapshotValidationError> - the snapshot envelope or a row failed validation

=item * C<WebService::Litportnet::FreeProxy::Error::SnapshotTruncatedError> - the snapshot reported C<truncated =E<gt> true>

=item * C<WebService::Litportnet::FreeProxy::Error::FilterValidationError> - the supplied filters (or constructor arguments) were invalid

=back

=head1 RESOURCES

=over 4

=item * L<https://litport.net/free-proxy> - Free proxy list

=item * L<https://litport.net/docs/free-proxy-api> - API documentation

=back

This client only retrieves proxy records over the snapshot API; it does not route any
traffic through a proxy. Free proxies are for testing only - never send credentials,
cookies, payment data, or other private data through them.

=head1 AUTHOR

Litport <litport@cpan.org>

=head1 LICENSE

This software is copyright (c) 2026 by Litport. It is released under the MIT license.
See the LICENSE file included with this distribution for the full text.

=cut

my $DEFAULT_API_URL = 'https://litport.net/api/free-proxy/snapshot?checkedWithinMin=1440';

my @PROTOCOLS   = qw(http socks4 socks5);
my @ANONYMITY   = qw(transparent anonymous elite unknown);
my @FILTER_KEYS = qw(
    protocol country anonymity https max_latency_ms
    min_uptime_7d min_checks_7d checked_within_min limit
);

my @BLOCKED_RANGES = (
    [ '0.0.0.0',       8 ],
    [ '10.0.0.0',      8 ],
    [ '100.64.0.0',   10 ],
    [ '127.0.0.0',     8 ],
    [ '169.254.0.0',  16 ],
    [ '172.16.0.0',   12 ],
    [ '192.0.0.0',    24 ],
    [ '192.0.2.0',    24 ],
    [ '192.168.0.0',  16 ],
    [ '198.18.0.0',   15 ],
    [ '198.51.100.0', 24 ],
    [ '203.0.113.0',  24 ],
    [ '224.0.0.0',     4 ],
    [ '240.0.0.0',     4 ],
);

my @DAYS_IN_MONTH = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

sub _ip_to_int {
    my ($ip) = @_;
    my @o = split /\./, $ip;
    return ( ( $o[0] << 24 ) | ( $o[1] << 16 ) | ( $o[2] << 8 ) | $o[3] );
}

my @BLOCKED_RANGES_INT = map { [ _ip_to_int( $_->[0] ), $_->[1] ] } @BLOCKED_RANGES;

sub new {
    my ( $class, %args ) = @_;

    my $api_url = defined $args{api_url} ? $args{api_url} : $DEFAULT_API_URL;
    my $timeout = defined $args{timeout} ? $args{timeout} : 10;

    WebService::Litportnet::FreeProxy::Error::FilterValidationError->throw(
        'timeout must be a positive finite number')
        unless _is_finite_number($timeout) && $timeout > 0;

    my $now = $args{now} || sub { time };

    return bless {
        api_url   => $api_url,
        timeout   => $timeout + 0,
        transport => $args{transport},
        now       => $now,
    }, $class;
}

sub get_proxies {
    my ( $self, $filters ) = @_;

    my $f = $self->_validate_filters($filters);

    my ( $status, undef, $body ) = $self->_request;

    WebService::Litportnet::FreeProxy::Error::HttpError->throw($status)
        unless $status >= 200 && $status <= 299;

    my $snapshot;
    if ( ref($body) eq 'HASH' ) {
        $snapshot = $body;
    }
    else {
        $snapshot = eval { JSON::PP->new->decode($body) };
        WebService::Litportnet::FreeProxy::Error::SnapshotValidationError->throw(
            'Malformed snapshot JSON')
            unless defined $snapshot;
    }

    WebService::Litportnet::FreeProxy::Error::SnapshotValidationError->throw(
        'Malformed snapshot envelope')
        unless ref($snapshot) eq 'HASH' && ref( $snapshot->{proxies} ) eq 'ARRAY';

    WebService::Litportnet::FreeProxy::Error::SnapshotTruncatedError->throw(
        'Snapshot is truncated')
        if _is_true( $snapshot->{truncated} );

    my $count_ok = _is_nonneg_int( $snapshot->{count} )
        && $snapshot->{count} == scalar @{ $snapshot->{proxies} };
    my $truncated_ok = !exists $snapshot->{truncated} || _valid_bool( $snapshot->{truncated} );

    WebService::Litportnet::FreeProxy::Error::SnapshotValidationError->throw(
        'Malformed snapshot envelope')
        unless $count_ok && $truncated_ok;

    $self->_validate_generated_at( $snapshot->{generatedAt} );

    my $now    = $self->{now}->();
    my $cutoff = $now - $f->{checked_within_min} * 60;

    my @rows = map { $self->_map_row($_) } @{ $snapshot->{proxies} };

    my @filtered = grep {
        my $checked = _parse_time( $_->{last_checked} );
        defined($checked) && $checked >= $cutoff && $checked <= $now + 5
            && $self->_matches( $_, $f );
    } @rows;

    my @sorted = sort { _compare_rows( $a, $b ) } @filtered;

    my $limit = $f->{limit};
    if ( defined $limit && $limit < scalar @sorted ) {
        @sorted = @sorted[ 0 .. $limit - 1 ];
    }

    return \@sorted;
}

sub pick_best {
    my ( $self, $count, $filters ) = @_;

    WebService::Litportnet::FreeProxy::Error::FilterValidationError->throw(
        'count must be a non-negative integer')
        unless _is_nonneg_int($count);

    my $rows = $self->get_proxies($filters);
    return $count < scalar(@$rows) ? [ @{$rows}[ 0 .. $count - 1 ] ] : $rows;
}

sub _request {
    my ($self) = @_;

    if ( $self->{transport} ) {
        return $self->{transport}->( $self->{api_url}, $self->{timeout} );
    }

    my $http = HTTP::Tiny->new( timeout => $self->{timeout} );
    my $response = $http->get( $self->{api_url} );

    # HTTP::Tiny reports every internal failure as status 599 with the reason in
    # the body, so a timeout has to be told apart from other transport errors.
    if ( !$response->{success} && ( $response->{status} || 0 ) == 599 ) {
        my $reason = $response->{content};
        $reason = '' unless defined $reason;
        $reason =~ s/\s+\z//;

        if ( $reason =~ /timed?\s*out/i ) {
            WebService::Litportnet::FreeProxy::Error::TimeoutError->throw(
                sprintf( 'Snapshot request timed out after %ss', $self->{timeout} ) );
        }

        WebService::Litportnet::FreeProxy::Error->throw(
            sprintf( 'Snapshot request failed: %s', $reason || 'transport error' ) );
    }

    return ( $response->{status}, $response->{headers}, $response->{content} );
}

sub _validate_filters {
    my ( $self, $input ) = @_;

    $input = {} unless defined $input;

    my $E = 'WebService::Litportnet::FreeProxy::Error::FilterValidationError';

    $E->throw('Filters must be a hash reference') unless ref($input) eq 'HASH';

    for my $key ( keys %$input ) {
        $E->throw("Unknown filter: $key") unless grep { $_ eq $key } @FILTER_KEYS;
    }

    my %f = %$input;

    $E->throw('protocol must be http, socks4, or socks5')
        if defined( $f{protocol} )
        && !( !ref( $f{protocol} ) && grep { $_ eq $f{protocol} } @PROTOCOLS );

    $E->throw('country must be a two-letter code')
        if defined( $f{country} )
        && !( !ref( $f{country} ) && $f{country} =~ /\A[A-Za-z]{2}\z/ );

    $E->throw('Invalid anonymity value')
        if defined( $f{anonymity} )
        && !( !ref( $f{anonymity} ) && grep { $_ eq $f{anonymity} } @ANONYMITY );

    $E->throw('https must be boolean')
        if defined( $f{https} ) && !_valid_bool( $f{https} );

    for my $name (qw(max_latency_ms min_uptime_7d min_checks_7d limit)) {
        $E->throw("$name must be a non-negative integer")
            if defined( $f{$name} ) && !_is_nonneg_int( $f{$name} );
    }

    my $minutes = defined( $f{checked_within_min} ) ? $f{checked_within_min} : 30;
    $E->throw('checked_within_min must be from 1 to 1440')
        unless _is_nonneg_int($minutes) && $minutes >= 1 && $minutes <= 1440;

    return {
        protocol           => $f{protocol},
        country            => defined( $f{country} ) ? lc( $f{country} ) : undef,
        anonymity          => $f{anonymity},
        https              => defined( $f{https} ) ? _bool_val( $f{https} ) : undef,
        max_latency_ms     => defined( $f{max_latency_ms} ) ? $f{max_latency_ms} + 0 : undef,
        min_uptime_7d      => defined( $f{min_uptime_7d} ) ? $f{min_uptime_7d} + 0 : undef,
        min_checks_7d      => defined( $f{min_checks_7d} ) ? $f{min_checks_7d} + 0 : undef,
        checked_within_min => $minutes + 0,
        limit              => defined( $f{limit} ) ? $f{limit} + 0 : undef,
    };
}

sub _map_row {
    my ( $self, $row ) = @_;

    my $E = 'WebService::Litportnet::FreeProxy::Error::SnapshotValidationError';

    $E->throw('Snapshot contains an invalid proxy row') unless ref($row) eq 'HASH';

    my $protocol  = $row->{protocol};
    my $ip        = $row->{host};
    my $port      = $row->{port};
    my $anonymity = $row->{anonymity};

    my $row_ok = defined($protocol)
        && !ref($protocol)
        && ( grep { $_ eq $protocol } @PROTOCOLS )
        && _public_ipv4($ip)
        && _is_nonneg_int($port)
        && $port >= 1
        && $port <= 65_535
        && defined($anonymity)
        && !ref($anonymity)
        && ( grep { $_ eq $anonymity } @ANONYMITY );

    $E->throw('Snapshot contains an invalid proxy row') unless $row_ok;

    my $country = $row->{geoCountry};
    $E->throw('Invalid country')
        unless !defined($country) || ( !ref($country) && $country =~ /\A[A-Za-z]{2}\z/ );

    my $asn = $row->{asn};
    if ( defined($asn) && !ref($asn) && $asn =~ /\AAS(\d+)\z/ ) {
        $asn = $1 + 0;
    }
    $E->throw('Invalid ASN') unless !defined($asn) || _is_nonneg_int($asn);

    for my $key (qw(geoRegion geoCity geoTimezone asnOrgName externalIp)) {
        my $v = $row->{$key};
        $E->throw('Invalid nullable string') unless !defined($v) || !ref($v);
    }

    $E->throw('Invalid https value') unless _valid_bool( $row->{https} );
    my $https = _bool_val( $row->{https} );

    for my $key (qw(responseTimeMs responseTimeMedianMs uptime24h uptime7d)) {
        my $v = $row->{$key};
        $E->throw('Invalid nullable number') unless !defined($v) || _is_finite_number($v);
    }

    my $checks7d      = $row->{checks7d};
    my $sources_count = $row->{sourcesCount};
    $E->throw('Invalid count')
        unless _is_nonneg_int($checks7d) && _is_nonneg_int($sources_count);

    my $first_epoch = _parse_time( $row->{createdAt} );
    my $last_epoch  = _parse_time( $row->{pingAt} );
    $E->throw('Invalid timestamp') unless defined($first_epoch) && defined($last_epoch);

    my $latency_ms        = defined( $row->{responseTimeMs} )       ? _round( $row->{responseTimeMs} )        : undef;
    my $latency_median_ms = defined( $row->{responseTimeMedianMs} ) ? $row->{responseTimeMedianMs} + 0         : undef;
    my $uptime_24h        = defined( $row->{uptime24h} )             ? $row->{uptime24h} + 0                   : undef;
    my $uptime_7d         = $checks7d < 50 ? undef : ( defined( $row->{uptime7d} ) ? $row->{uptime7d} + 0 : undef );

    return {
        protocol          => $protocol,
        ip                => $ip,
        port              => $port + 0,
        url               => "$protocol://$ip:$port",
        country           => defined($country) ? lc($country) : undef,
        region            => $row->{geoRegion},
        city              => $row->{geoCity},
        timezone          => $row->{geoTimezone},
        asn               => $asn,
        asn_org           => $row->{asnOrgName},
        anonymity         => $anonymity,
        https             => $https,
        latency_ms        => $latency_ms,
        latency_median_ms => $latency_median_ms,
        uptime_24h        => $uptime_24h,
        uptime_7d         => $uptime_7d,
        checks_7d         => $checks7d + 0,
        exit_ip           => $row->{externalIp},
        sources_count     => $sources_count + 0,
        first_seen        => _iso($first_epoch),
        last_checked      => _iso($last_epoch),
    };
}

sub _matches {
    my ( $self, $row, $f ) = @_;

    return 0 if defined( $f->{protocol} )   && $row->{protocol} ne $f->{protocol};
    return 0 if defined( $f->{country} )    && ( !defined( $row->{country} )    || $row->{country} ne $f->{country} );
    return 0 if defined( $f->{anonymity} )  && $row->{anonymity} ne $f->{anonymity};
    return 0 if defined( $f->{https} )      && ( !defined( $row->{https} )      || $row->{https} != $f->{https} );
    return 0 if defined( $f->{max_latency_ms} ) && ( !defined( $row->{latency_ms} ) || $row->{latency_ms} > $f->{max_latency_ms} );
    return 0 if defined( $f->{min_uptime_7d} )  && ( !defined( $row->{uptime_7d} )  || $row->{uptime_7d} < $f->{min_uptime_7d} );
    return 0 if defined( $f->{min_checks_7d} )  && $row->{checks_7d} < $f->{min_checks_7d};

    return 1;
}

sub _compare_rows {
    my ( $p, $q ) = @_;

    my $up = defined( $p->{uptime_7d} ) ? 0 : 1;
    my $uq = defined( $q->{uptime_7d} ) ? 0 : 1;
    return $up <=> $uq if $up != $uq;

    my $ucmp = ( $q->{uptime_7d} // 0 ) <=> ( $p->{uptime_7d} // 0 );
    return $ucmp if $ucmp;

    my $lp = defined( $p->{latency_ms} ) ? 0 : 1;
    my $lq = defined( $q->{latency_ms} ) ? 0 : 1;
    return $lp <=> $lq if $lp != $lq;

    my $lcmp = ( $p->{latency_ms} // 0 ) <=> ( $q->{latency_ms} // 0 );
    return $lcmp if $lcmp;

    return $p->{url} cmp $q->{url};
}

sub _validate_generated_at {
    my ( $self, $value ) = @_;

    my $time = _parse_time($value);
    my $now  = $self->{now}->();

    WebService::Litportnet::FreeProxy::Error::SnapshotValidationError->throw(
        'Snapshot generatedAt is outside the accepted window')
        unless defined($time) && $time <= $now + 5 && $time >= $now - 120;
}

# POSIX::isnan and POSIX::isinf are not portable across the perl versions this
# distribution supports, so test for NaN and infinity arithmetically instead.
sub _is_nan { my ($v) = @_; return $v != $v }
sub _is_inf { my ($v) = @_; return $v == 9**9**9 || $v == -9**9**9 }

sub _is_finite_number {
    my ($v) = @_;
    return 0 unless defined($v) && !ref($v) && Scalar::Util::looks_like_number($v);
    return 0 if _is_nan($v) || _is_inf($v);
    return 1;
}

sub _is_nonneg_int {
    my ($v) = @_;
    return 0 unless defined($v) && !ref($v) && Scalar::Util::looks_like_number($v);
    return 0 if _is_nan($v) || _is_inf($v);
    return 0 unless $v == int($v);
    return 0 if $v < 0;
    return 1;
}

# Accepts undef, a JSON::PP::Boolean, or the literal strings/numbers '0'/'1'.
sub _valid_bool {
    my ($v) = @_;
    return 1 unless defined $v;
    return 1 if ref($v) eq 'JSON::PP::Boolean';
    return 1 if !ref($v) && ( $v eq '0' || $v eq '1' );
    return 0;
}

sub _bool_val {
    my ($v) = @_;
    return undef unless defined $v;
    return $v ? 1 : 0;
}

# True only for an actual JSON boolean true (or literal '1'), never for merely
# truthy-but-wrongly-typed values such as the string "true".
sub _is_true {
    my ($v) = @_;
    return 0 unless defined $v;
    return $v ? 1 : 0 if ref($v) eq 'JSON::PP::Boolean';
    return 0 if ref($v);
    return $v eq '1' ? 1 : 0;
}

sub _round {
    my ($v) = @_;
    return $v < 0 ? -POSIX::floor( -$v + 0.5 ) : POSIX::floor( $v + 0.5 );
}

sub _is_leap_year {
    my ($y) = @_;
    return ( $y % 4 == 0 && ( $y % 100 != 0 || $y % 400 == 0 ) ) ? 1 : 0;
}

sub _valid_date {
    my ( $y, $mo, $d ) = @_;
    return 0 if $mo < 1 || $mo > 12;
    my $dim = $DAYS_IN_MONTH[ $mo - 1 ];
    $dim = 29 if $mo == 2 && _is_leap_year($y);
    return $d >= 1 && $d <= $dim;
}

# Parses a strict ISO-8601 timestamp into fractional epoch seconds (UTC), or
# undef if the string doesn't parse to a real calendar date/time.
sub _parse_time {
    my ($value) = @_;
    return undef unless defined($value) && !ref($value);
    return undef
        unless $value =~
        /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|[+-]\d{2}:\d{2})\z/;
    my ( $y, $mo, $d, $h, $mi, $s, $frac, $tz ) = ( $1, $2, $3, $4, $5, $6, $7, $8 );

    return undef unless _valid_date( $y + 0, $mo + 0, $d + 0 );
    return undef if $h > 23 || $mi > 59 || $s > 59;

    my $epoch = eval { Time::Local::timegm( $s, $mi, $h, $d, $mo - 1, $y ) };
    return undef if $@;

    my $frac_val = defined($frac) ? ( "0.$frac" + 0 ) : 0;

    my $offset = 0;
    if ( $tz ne 'Z' ) {
        my ( $sign, $oh, $om ) = $tz =~ /\A([+-])(\d{2}):(\d{2})\z/;
        $offset = ( $oh * 3600 + $om * 60 ) * ( $sign eq '-' ? -1 : 1 );
    }

    return $epoch + $frac_val - $offset;
}

# Formats fractional epoch seconds (UTC) back into ISO-8601 with millisecond
# precision, e.g. 2026-09-17T16:39:35.366Z.
sub _iso {
    my ($epoch) = @_;
    return undef unless defined $epoch;

    my $sec_int = POSIX::floor($epoch);
    my $millis  = int( sprintf( '%.0f', ( $epoch - $sec_int ) * 1000 ) );
    if ( $millis >= 1000 ) {
        $millis -= 1000;
        $sec_int += 1;
    }

    my @gt = gmtime($sec_int);
    return sprintf(
        '%04d-%02d-%02dT%02d:%02d:%02d.%03dZ',
        $gt[5] + 1900, $gt[4] + 1, $gt[3], $gt[2], $gt[1], $gt[0], $millis
    );
}

sub _public_ipv4 {
    my ($value) = @_;
    return 0 unless defined($value) && !ref($value);
    return 0 unless $value =~ /\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})\z/;
    my @o = ( $1, $2, $3, $4 );
    for my $octet (@o) {
        return 0 if $octet > 255;
    }

    my $n = ( $o[0] << 24 ) | ( $o[1] << 16 ) | ( $o[2] << 8 ) | $o[3];
    for my $range (@BLOCKED_RANGES_INT) {
        my ( $net, $bits ) = @$range;
        my $mask = $bits == 0 ? 0 : ( 0xFFFFFFFF << ( 32 - $bits ) ) & 0xFFFFFFFF;
        return 0 if ( $n & $mask ) == ( $net & $mask );
    }

    return 1;
}

package WebService::Litportnet::FreeProxy::Error;

use strict;
use warnings;

use overload
    '""'     => \&message,
    fallback => 1;

sub new {
    my ( $class, $message ) = @_;
    return bless { message => $message }, $class;
}

sub throw {
    my $class = shift;
    die $class->new(@_);
}

sub message { return $_[0]->{message}; }

package WebService::Litportnet::FreeProxy::Error::TimeoutError;

use strict;
use warnings;

our @ISA = ('WebService::Litportnet::FreeProxy::Error');

package WebService::Litportnet::FreeProxy::Error::HttpError;

use strict;
use warnings;

our @ISA = ('WebService::Litportnet::FreeProxy::Error');

sub new {
    my ( $class, $status ) = @_;
    my $self = $class->SUPER::new("Snapshot request failed with HTTP $status");
    $self->{status} = $status;
    return $self;
}

sub status { return $_[0]->{status}; }

package WebService::Litportnet::FreeProxy::Error::SnapshotValidationError;

use strict;
use warnings;

our @ISA = ('WebService::Litportnet::FreeProxy::Error');

package WebService::Litportnet::FreeProxy::Error::SnapshotTruncatedError;

use strict;
use warnings;

our @ISA = ('WebService::Litportnet::FreeProxy::Error');

package WebService::Litportnet::FreeProxy::Error::FilterValidationError;

use strict;
use warnings;

our @ISA = ('WebService::Litportnet::FreeProxy::Error');

1;
