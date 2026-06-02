package TimeZone::TimeZoneDB;

use strict;
use warnings;
use autodie qw(:all);

use Carp;
use CHI;
use JSON::MaybeXS;
use LWP::UserAgent;
use Object::Configure;
use Params::Get 0.13;
use Params::Validate::Strict 0.10;
use Readonly;
use Return::Set;
use Scalar::Util;
use Time::HiRes;
use URI;

=head1 NAME

TimeZone::TimeZoneDB - Interface to L<https://timezonedb.com> for looking up Timezone data

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

# ---------------------------------------------------------------------------
# Compile-time constants for the timezonedb.com REST API.
# These never vary and are inlined by the compiler.
# ---------------------------------------------------------------------------
Readonly::Scalar my $API_FORMAT    => 'json';
Readonly::Scalar my $API_BY        => 'position';	# query by geographic position

# printf-style format for the cache key; 6 dp normalises 0.1 and 0.1000000
Readonly::Scalar my $CACHE_KEY_FMT => 'tz:%.6f:%.6f';

# Valid coordinate ranges as defined by the WGS-84 standard
Readonly::Scalar my $LAT_MIN => -90;
Readonly::Scalar my $LAT_MAX =>  90;
Readonly::Scalar my $LNG_MIN => -180;
Readonly::Scalar my $LNG_MAX =>  180;

# ---------------------------------------------------------------------------
# Runtime defaults.  Every key may be overridden via Object::Configure,
# which reads from a per-class configuration file or environment variables.
# ---------------------------------------------------------------------------
my %config = (
	host          => 'api.timezonedb.com',	# remote API hostname
	api_version   => 'v2.1',		# path component for the API version
	api_endpoint  => 'get-time-zone',	# path component for the lookup method
	cache_expires => '1 day',		# CHI expiry string for cached responses
	min_interval  => 0,			# minimum seconds between outbound requests
);

=head1 SYNOPSIS

    use TimeZone::TimeZoneDB;

    my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXXXXX');
    my $tz = $tzdb->get_time_zone({ latitude => 0.1, longitude => 0.2 });

=head1 DESCRIPTION

The C<TimeZone::TimeZoneDB> Perl module provides an interface to the
L<https://timezonedb.com> API, enabling users to retrieve timezone data
based on geographic coordinates.
It supports configurable HTTP user agents, allowing for proxy settings
and request throttling.
The module includes robust error handling, ensuring proper validation of
input parameters and secure API interactions.
JSON responses are safely parsed with error handling to prevent crashes.
Designed for flexibility, it allows users to override default configurations
while maintaining a lightweight and efficient structure for querying timezone
information.

=over 4

=item * Caching

Identical requests are cached (using L<CHI> or a user-supplied caching object),
reducing the number of HTTP requests to the API and speeding up repeated queries.

A cache key is constructed from the normalised coordinates (6 decimal places)
so that C<0.1> and C<0.1000000> share the same cache entry.

=item * Rate-Limiting

A minimum interval between successive API calls can be enforced to ensure that
the API is not overwhelmed and to comply with any request throttling requirements.

Rate-limiting is implemented using L<Time::HiRes>.
A minimum interval between API calls can be specified via the C<min_interval>
parameter in the constructor.
Before making an API call, the module checks how much time has elapsed since
the last request and, if necessary, sleeps for the remaining time.

=back

=head1 METHODS

=head2 new

    my $tzdb = TimeZone::TimeZoneDB->new(key => 'XXXXX');

    # With a throttled user-agent that respects free-tier rate limits
    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->env_proxy(1);
    $tzdb = TimeZone::TimeZoneDB->new(ua => $ua, key => 'XXXXX');

    # Retrieve the timezone for Ramsgate, UK
    my $tz = $tzdb->get_time_zone({ latitude => 51.34, longitude => 1.42 })->{'zoneName'};
    print "Ramsgate timezone: $tz\n";

Creates and returns a new C<TimeZone::TimeZoneDB> instance.
When invoked on an existing object rather than a class name, it returns a
shallow clone of that object with any supplied parameters merged in.
Passing C<ua =E<gt> undef> in a clone call is silently ignored so that the
original user-agent is inherited unchanged.

=head3 ARGUMENTS

=over 4

=item C<key> (required)

API key for timezonedb.com.  Free keys are available at
L<https://timezonedb.com/register>.

=item C<ua> (optional)

An HTTP user-agent object.  Must respond to C<get()>.  Defaults to a plain
L<LWP::UserAgent> with C<gzip,deflate> accepted.

=item C<host> (optional)

Override the API hostname.  Defaults to C<api.timezonedb.com>.

=item C<cache> (optional)

A L<CHI>-compatible caching object.  Defaults to a private in-memory cache
with a one-day expiry.

=item C<min_interval> (optional)

Minimum number of seconds to wait between successive API calls.
Defaults to C<0> (no enforced delay).

=back

=head3 RETURNS

A blessed C<TimeZone::TimeZoneDB> reference.
Croaks if C<key> is absent.

=head3 SIDE EFFECTS

None.

=head3 NOTES

An optional C<logger> key may be passed; if present it must be an object
implementing C<warn()> and C<error()> (e.g. L<Log::Log4perl>).

=head3 API SPECIFICATION

=head4 INPUT

  {
    'key'          => { type => 'string' },
    'ua'           => { type => 'object', can => 'get',    optional => 1 },
    'host'         => { type => 'string',                  optional => 1 },
    'cache'        => { type => 'object',                  optional => 1 },
    'min_interval' => { type => 'number', min => 0,        optional => 1 },
  }

=head4 OUTPUT

  { type => 'object' }   # a blessed TimeZone::TimeZoneDB reference

=cut

sub new
{
	my $class = shift;
	# Normalise both positional and named calling conventions
	my $params = Params::Get::get_params(undef, \@_) || {};

	# Support function-style call: TimeZone::TimeZoneDB::new() without ->
	if(!defined($class)) {
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		# Clone path: merge new params over the existing object's fields.
		if(exists($params->{ua})) {
			if(!defined($params->{ua})) {
				# ua=>undef means "keep the original" -- silently drop it
				delete $params->{ua};
			} elsif(!Scalar::Util::blessed($params->{ua}) || !$params->{ua}->can('get')) {
				# A defined ua must be a proper object with a get() method
				Carp::croak("'ua' argument must be an object with a get() method");
			}
		}
		return bless { %{$class}, %{$params} }, ref($class);
	}

	# Merge any file- or environment-based configuration into $params
	$params = Object::Configure::configure($class, $params);

	# The API key is the only mandatory argument
	my $key = $params->{'key'} or Carp::croak("'key' argument is required");

	# Build a default user-agent if the caller did not supply one
	my $ua = $params->{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}

	# Prefer an explicit host override, then the package-level default
	my $host = $params->{host} || $config{host};

	# Fall back to a private in-memory cache if none was supplied
	my $cache = $params->{cache} || CHI->new(
		driver     => 'Memory',
		global     => 0,
		expires_in => $config{cache_expires},
	);

	# Use // so that an explicit 0 (disabled) is not replaced by the default
	my $min_interval = $params->{min_interval} // $config{min_interval};

	return bless {
		key          => $key,
		min_interval => $min_interval,
		last_request => 0,		# epoch zero: no request has been made yet
		%{$params},			# pass any extra keys (e.g. logger) through
		cache        => $cache,		# computed values override %{$params} copies
		host         => $host,
		ua           => $ua,
	}, $class;
}

=head2 get_time_zone

    my $result = $tzdb->get_time_zone({ latitude => 51.34, longitude => 1.42 });
    print $result->{'zoneName'}, "\n";

    # Also accepts a Geo::Location::Point-compatible object
    use Geo::Location::Point;
    my $ramsgate = Geo::Location::Point->new({ latitude => 51.34, longitude => 1.42 });
    my $tz = $tzdb->get_time_zone($ramsgate)->{'zoneName'};

Queries the timezonedb.com API for the IANA timezone name and associated
metadata at the supplied geographic coordinates.
Identical queries are served from cache without making a network request.

=head3 ARGUMENTS

=over 4

=item C<latitude> (required)

Decimal degrees, range C<-90> to C<+90>.

=item C<longitude> (required)

Decimal degrees, range C<-180> to C<+180>.

Alternatively, a single L<Geo::Location::Point>-compatible object (any
object implementing C<latitude()> and C<longitude()> methods) may be passed
instead of a hash or hashref.

=back

=head3 RETURNS

A hashref containing at least C<zoneName> on success.
Returns C<undef> when the API responds with a non-C<OK> status.
Croaks on HTTP errors or invalid arguments.

=head3 SIDE EFFECTS

Updates the internal response cache and the C<last_request> timestamp.

=head3 NOTES

The API key is transmitted as a URL query parameter because the
timezonedb.com API does not support an C<Authorization> header.
The key is redacted from all error and warning messages to prevent
accidental secret leakage into log aggregators or crash reporters.

=head3 API SPECIFICATION

=head4 INPUT

  {
    'latitude'  => { type => 'number', min => -90,  max => 90  },
    'longitude' => { type => 'number', min => -180, max => 180 },
  }

=head4 OUTPUT

  Argument error : croak
  HTTP error     : croak
  Non-OK status  : undef
  Success        : { type => 'hashref', min => 1 }

=cut

sub get_time_zone
{
	my $self = shift;
	my $params;

	# Accept a Geo::Location::Point-compatible object or a plain hash/hashref
	if((@_ == 1) && Scalar::Util::blessed($_[0]) && $_[0]->can('latitude')) {
		my $location = $_[0];
		$params->{latitude}  = $location->latitude();
		$params->{longitude} = $location->longitude();
	} else {
		$params = Params::Get::get_params(undef, \@_);
	}

	# Validate coordinate ranges; croaks on out-of-range or missing values
	$params = Params::Validate::Strict::validate_strict(
		args   => $params,
		schema => {
			'latitude'  => { type => 'number', min => $LAT_MIN, max => $LAT_MAX },
			'longitude' => { type => 'number', min => $LNG_MIN, max => $LNG_MAX },
		}
	);

	my $latitude  = $params->{latitude};
	my $longitude = $params->{longitude};

	# Params::Validate::Strict silently skips type/range checks for undef values,
	# so guard explicitly to avoid sprintf warnings and silent URL corruption
	Carp::croak("Required parameter 'latitude' must be defined")  unless defined($latitude);
	Carp::croak("Required parameter 'longitude' must be defined") unless defined($longitude);

	# Build the full API URL; key must go in the query string (API requirement)
	my $uri = URI->new(
		sprintf('https://%s/%s/%s',
			$self->{host},
			$config{api_version},
			$config{api_endpoint}
		)
	);
	$uri->query_form(
		by     => $API_BY,
		lat    => $latitude,
		lng    => $longitude,
		format => $API_FORMAT,
		key    => $self->{'key'},
	);
	my $url = $uri->as_string();

	# Normalise to 6 dp so that 0.1 and 0.1000000 share the same cache slot
	my $cache_key = sprintf($CACHE_KEY_FMT, $latitude, $longitude);
	if(my $cached = $self->{cache}->get($cache_key)) {
		return $cached;
	}

	# Sleep if needed to honour the caller's minimum inter-request interval
	my $now     = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	# Perform the HTTP GET; all transport details are the UA's responsibility
	my $res = $self->{ua}->get($url);

	# Stamp the request time before any early return so rate-limiting is correct
	$self->{last_request} = time();

	# Redact the API key before including the URL in any error message
	if($res->is_error()) {
		(my $safe_url = $url) =~ s/key=[^&]*/key=REDACTED/;
		if(my $logger = $self->{logger}) {
			$logger->error($safe_url . ' API returned error: ' . $res->status_line());
		}
		Carp::croak($safe_url . ' API returned error: ' . $res->status_line());
	}

	# Safely decode the JSON body; a malformed response is a soft failure
	my $rc;
	eval { $rc = JSON::MaybeXS->new()->utf8()->decode($res->decoded_content()) };
	if($@) {
		if(my $logger = $self->{logger}) {
			$logger->warn("Failed to parse JSON response: $@");
		}
		Carp::carp("Failed to parse JSON response: $@");
		return;
	}

	# Cache the decoded response before returning so the next caller is served
	$self->{'cache'}->set($cache_key, $rc);

	# A non-OK API status means the coordinates returned no result
	if($rc && defined($rc->{'status'}) && ($rc->{'status'} ne 'OK')) {
		if(my $logger = $self->{'logger'}) {
			(my $safe_url = $url) =~ s/key=[^&]*/key=REDACTED/;
			$logger->warn(__PACKAGE__ . ": $safe_url returns $rc->{status}");
		}
		return;
	}

	# Assert the output contract: a non-empty hashref
	return Return::Set::set_return($rc, { 'type' => 'hashref', 'min' => 1 });
}

=head2 ua

    # Getter: retrieve the current user-agent
    my $ua = $tzdb->ua();
    $ua->env_proxy(1);

    # Setter: swap in a throttled agent (returns the new agent for compatibility)
    use LWP::UserAgent::Throttled;
    my $new_ua = LWP::UserAgent::Throttled->new();
    $new_ua->throttle('timezonedb.com' => 1);
    $tzdb->ua($new_ua);

Gets or sets the HTTP user-agent object used for API requests.
The return value is always the current user-agent (after any update),
consistent with the convention used by L<LWP::UserAgent> and related
packages that expose a C<ua()> accessor.

=head3 ARGUMENTS

=over 4

=item C<ua> (optional)

Replacement user-agent object.  Must implement a C<get($url)> method.
Omit to use this method as a getter.

=back

=head3 RETURNS

The user-agent object stored on the instance -- the supplied value when
called as a setter, the existing value when called as a getter.
Croaks if a defined but invalid object (no C<get()> method) is supplied,
or if C<undef> is explicitly passed.

=head3 SIDE EFFECTS

When used as a setter, all subsequent API calls on this object use the new
user-agent.

=head3 NOTES

Free timezonedb.com accounts are rate-limited to one request per second.
Use L<LWP::UserAgent::Throttled> to enforce this transparently.

The accessor always returns the user-agent rather than C<$self> so that
callers can do C<$tzdb-E<gt>ua()-E<gt>env_proxy(1)> in a single expression
without ambiguity about what was returned.

=head3 API SPECIFICATION

=head4 INPUT

  # Getter (no argument)
  {}

  # Setter
  { 'ua' => { type => 'object', can => 'get' } }

=head4 OUTPUT

  { type => 'object' }   # the stored user-agent (getter or setter)

=cut

sub ua {
	my $self = shift;

	# Getter path: no arguments, return the stored agent immediately
	return $self->{ua} unless @_;

	# Params::Get::get_params('ua', \@_) mis-routes the named form ua(ua => $ref)
	# into { ua => [$key, $ref] } because its $array_ref path fires before the
	# even-count hash path when the value is a reference (Params::Get line 258).
	# Detect and fix the named-pair form manually before passing to validate_strict.
	my $args;
	if(@_ == 2 && defined($_[0]) && !ref($_[0]) && $_[0] eq 'ua') {
		$args = { ua => $_[1] };	# named: ua(ua => $obj)
	} else {
		$args = Params::Get::get_params('ua', \@_);	# positional: ua($obj)
	}

	# Validate that the supplied object implements the interface we depend on
	my $params = Params::Validate::Strict::validate_strict(
		args   => $args,
		schema => {
			ua => {
				type => 'object',
				can  => 'get',
			}
		}
	);

	# Params::Validate::Strict skips the type check for undef 'object' params,
	# so we must guard explicitly to prevent silent corruption of $self->{ua}
	if(!defined($params->{ua})) {
		if(my $logger = $self->{'logger'}) {
			$logger->error('ua() requires a defined value');
		}
		Carp::croak('ua() requires a defined value');
	}

	# Store the new agent and return it, consistent with LWP::UserAgent convention
	$self->{ua} = $params->{ua};
	return $self->{ua};
}

=head1 AUTHOR

Nigel Horne, C<< <njh@nigelhorne.com> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at L<https://timezonedb.com>.

=head1 BUGS

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-timezone-timezonedb at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TimeZone-TimeZoneDB>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * TimezoneDB API: L<https://timezonedb.com/api>

=item * L<Test Dashboard|https://nigelhorne.github.io/TimeZone-TimeZoneDB/coverage/>

=back

=encoding utf-8

=head2 FORMAL SPECIFICATION

=head3 new

  TimeZoneDB-State ::= [
    key          : STRING ;
    ua           : USERAGENT ;
    host         : STRING ;
    cache        : CACHE ;
    min_interval : ℕ ;
    last_request : ℕ
  ]

  Init
    key?          : STRING
    ua?           : USERAGENT ∪ {⊥}
    host?         : STRING ∪ {⊥}
    cache?        : CACHE ∪ {⊥}
    min_interval? : ℕ ∪ {⊥}
    result!       : TimeZoneDB-State
  ────────────────────────────────────────────────────────
    key? ≠ "" ∧
    result!.key          = key? ∧
    result!.ua           = (if ua? ≠ ⊥ then ua? else DefaultUA) ∧
    result!.host         = (if host? ≠ ⊥ then host? else config.host) ∧
    result!.cache        = (if cache? ≠ ⊥ then cache? else NewCache) ∧
    result!.min_interval = (if min_interval? ≠ ⊥ then min_interval? else 0) ∧
    result!.last_request = 0

=head3 get_time_zone

  GetTimeZone
    Δ TimeZoneDB-State   (writes cache and last_request)
    lat? : {n : ℝ | -90 ≤ n ≤ 90}
    lng? : {n : ℝ | -180 ≤ n ≤ 180}
    result! : HASHREF ∪ {⊥}
  ────────────────────────────────────────────────────────
    let k == sprintf(CACHE_KEY_FMT, lat?, lng?)
    ∧ cache.has(k) ⇒
          result! = cache.get(k)
        ∧ last_request' = last_request
        ∧ cache' = cache
    ∧ ¬cache.has(k) ⇒
          let r == ua.get(ApiUrl(lat?, lng?, key))
          ∧ ¬r.ok ⇒ ⊥
          ∧ r.ok ∧ r.json.status = "OK" ⇒
                result! = r.json
              ∧ cache' = cache ⊕ {k ↦ r.json}
              ∧ last_request' = now
          ∧ r.ok ∧ r.json.status ≠ "OK" ⇒
                result! = ⊥
              ∧ cache' = cache
              ∧ last_request' = now

=head2 ua

  UA
    Delta TimeZoneDB-State
    ua? : USERAGENT ∪ {⊥}   (⊥ = not supplied)
    ua! : USERAGENT
  ────────────────────────────────────────────────────────
    (ua? = ⊥ ∧ ua' = ua) ∨
    (ua? ≠ ⊥ ∧ defined(ua?) ∧ ua? can 'get'
             ∧ ua' = ua?
             ∧ ∀ x : {key, host, cache, min_interval, last_request} • x' = x)
    ∧ ua! = ua'

=head1 LICENSE AND COPYRIGHT

Copyright 2023-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
