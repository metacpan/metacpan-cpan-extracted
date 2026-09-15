package Uniform::HTTP::Auth;

use strict;
use warnings;
use Carp qw(croak);

use Uniform::HTTP::Auth::Basic ();
use Uniform::HTTP::Auth::Bearer ();
use Uniform::HTTP::Auth::Digest ();

our $VERSION = '0.02';

my %SCHEME_CLASS = (
    basic  => 'Uniform::HTTP::Auth::Basic',
    bearer => 'Uniform::HTTP::Auth::Bearer',
    digest => 'Uniform::HTTP::Auth::Digest',
);

sub new {
    my ($class, %args) = @_;

    for my $name (keys %args) {
        croak "unknown constructor option '$name'"
            unless $name eq 'schemes'
                || $name eq 'credentials'
                || $name eq 'origin';
    }

    my $schemes = exists $args{schemes}
        ? $args{schemes}
        : [qw(digest bearer basic)];

    croak "schemes must be an array reference"
        unless ref($schemes) eq 'ARRAY';

    my (@normalized, %seen);
    for my $scheme (@$schemes) {
        croak "scheme names must be plain scalars"
            if !defined($scheme) || ref($scheme);
        my $name = lc $scheme;
        croak "unsupported authentication scheme '$scheme'"
            unless exists $SCHEME_CLASS{$name};
        croak "duplicate authentication scheme '$scheme'"
            if $seen{$name}++;
        push @normalized, $name;
    }

    _validate_origin($args{origin}) if exists $args{origin};

    my $credentials = $args{credentials};
    if (exists $args{credentials}) {
        my $type = ref($credentials);
        croak "credentials must be a hash reference or coderef"
            unless $type eq 'HASH' || $type eq 'CODE';

        if ($type eq 'HASH') {
            croak "origin is required when credentials is a hash reference"
                unless exists $args{origin};
            _validate_static_credentials($credentials);
            $credentials = { %$credentials };
        }
    }

    my $self = bless {
        schemes     => \@normalized,
        credentials => $credentials,
        origin      => $args{origin},
        digest      => Uniform::HTTP::Auth::Digest->new,
    }, $class;

    return $self;
}

sub schemes {
    my ($self) = @_;
    return [ @{ $self->{schemes} } ];
}

sub parse_challenges {
    my ($self, @values) = @_;

    my @out;
    for my $value (@values) {
        if (!defined($value) || ref($value)) {
            push @out, {
                scheme    => undef,
                raw       => defined($value) ? "$value" : '',
                params    => {},
                token68   => undef,
                malformed => 1,
                error     => 'challenge header value must be a plain scalar',
            };
            next;
        }
        push @out, @{ _parse_field($value) };
    }

    for my $challenge (@out) {
        next if $challenge->{malformed};
        my $scheme = $challenge->{scheme};
        next unless defined $scheme && exists $SCHEME_CLASS{$scheme};

        my $class = $SCHEME_CLASS{$scheme};
        my $error = $class->validate_challenge($challenge);
        if (defined $error) {
            $challenge->{malformed} = 1;
            $challenge->{error} = $error;
        }
    }

    return \@out;
}

sub select {
    my ($self, $challenges) = @_;
    croak "select() requires an array reference"
        unless ref($challenges) eq 'ARRAY';

    for my $scheme (@{ $self->{schemes} }) {
        my @candidates = grep {
            ref($_) eq 'HASH'
                && !$_->{malformed}
                && defined($_->{scheme})
                && $_->{scheme} eq $scheme
        } @$challenges;

        next unless @candidates;

        my $handler = $self->_handler($scheme);
        my $chosen = $handler->select_challenge(\@candidates);
        return $chosen if $chosen;
    }

    return;
}

sub prepare_authentication {
    my ($self, %args) = @_;

    croak "prepare_authentication() requires credentials"
        unless ref($self->{credentials}) eq 'HASH'
            || ref($self->{credentials}) eq 'CODE';

    croak "challenge_headers must be an array reference"
        unless ref($args{challenge_headers}) eq 'ARRAY';

    if (exists $args{request}) {
        my $request = $args{request};
        croak "request must implement method(), target(), and has_buffered_body()"
            unless ref($request)
                && $request->can('method')
                && $request->can('target')
                && $request->can('has_buffered_body');

        $args{method} = $request->method
            unless exists $args{method};
        $args{request_target} = $request->target
            unless exists $args{request_target};
        if (!exists($args{entity_body}) && $request->has_buffered_body) {
            croak "request reports a buffered body but does not implement body()"
                unless $request->can('body');
            $args{entity_body} = $request->body;
        }
    }

    my $origin;
    if (exists $args{origin}) {
        _validate_origin($args{origin});
        if (defined($self->{origin}) && $args{origin} ne $self->{origin}) {
            croak "origin does not match the origin bound at construction";
        }
        $origin = $args{origin};
    }
    else {
        $origin = $self->{origin};
        _validate_origin($origin);
    }

    my $challenges = $self->parse_challenges(@{ $args{challenge_headers} });

    for my $scheme (@{ $self->{schemes} }) {
        my @candidates = grep {
            !$_->{malformed}
                && defined($_->{scheme})
                && $_->{scheme} eq $scheme
        } @$challenges;
        next unless @candidates;

        my $handler = $self->_handler($scheme);
        my $challenge = $handler->select_challenge(\@candidates);
        next unless $challenge;

        my $context = {
            scheme    => $scheme,
            origin    => $origin,
            realm     => $challenge->{params}{realm},
            challenge => $challenge,
        };

        my $credentials;
        if (ref($self->{credentials}) eq 'CODE') {
            $credentials = $self->{credentials}->($context);
            next unless defined $credentials;
            croak "credentials callback must return a hash reference or undef"
                unless ref($credentials) eq 'HASH';
        }
        else {
            $credentials = _static_credentials_for_scheme(
                $self->{credentials}, $scheme,
            );
            next unless $credentials;
        }

        my $value;
        if ($scheme eq 'basic') {
            _require_fields($credentials, qw(username password));
            $value = Uniform::HTTP::Auth::Basic->authorization(
                %$credentials,
                challenge => $challenge,
            );
        }
        elsif ($scheme eq 'bearer') {
            _require_fields($credentials, qw(token));
            $value = Uniform::HTTP::Auth::Bearer->authorization(
                %$credentials,
                challenge => $challenge,
            );
        }
        elsif ($scheme eq 'digest') {
            _require_fields($credentials, qw(username password));
            croak "method is required for Digest authentication"
                unless defined($args{method}) && !ref($args{method});
            croak "request_target is required for Digest authentication"
                unless defined($args{request_target}) && !ref($args{request_target});

            my %digest_args = (
                %$credentials,
                challenge      => $challenge,
                origin         => $origin,
                method         => $args{method},
                request_target => $args{request_target},
            );
            $digest_args{entity_body} = $args{entity_body}
                if exists $args{entity_body};

            $value = $handler->authorization(%digest_args);
            next unless defined $value;
        }

        return {
            scheme    => $scheme,
            value     => $value,
            challenge => $challenge,
        };
    }

    return;
}

sub _handler {
    my ($self, $scheme) = @_;
    return $self->{digest} if $scheme eq 'digest';
    return $SCHEME_CLASS{$scheme};
}

sub _validate_static_credentials {
    my ($credentials) = @_;

    my $has_token = exists $credentials->{token};
    my $has_username = exists $credentials->{username};
    my $has_password = exists $credentials->{password};

    croak "static credentials require both username and password"
        if $has_username != $has_password;
    croak "static credentials require token or username/password"
        unless $has_token || ($has_username && $has_password);

    for my $field (qw(token username password)) {
        next unless exists $credentials->{$field};
        croak "credential '$field' must be defined"
            unless defined $credentials->{$field};
        croak "credential '$field' must be a plain scalar"
            if ref($credentials->{$field});
    }
}

sub _static_credentials_for_scheme {
    my ($credentials, $scheme) = @_;

    if ($scheme eq 'bearer') {
        return unless exists $credentials->{token};
    }
    else {
        return unless exists($credentials->{username})
            && exists($credentials->{password});
    }

    return { %$credentials };
}

sub _require_fields {
    my ($credentials, @fields) = @_;
    for my $field (@fields) {
        croak "credentials require '$field'"
            unless exists($credentials->{$field}) && defined($credentials->{$field});
        croak "credential '$field' must be a plain scalar"
            if ref($credentials->{$field});
    }
}

sub _validate_origin {
    my ($origin) = @_;
    croak "origin is required"
        unless defined($origin) && !ref($origin) && length($origin);
    croak "origin must not contain whitespace or control characters"
        if $origin =~ /[\x00-\x20\x7f]/;
    croak "origin must be a normalized origin without credentials or path"
        unless $origin =~ m{\A[A-Za-z][A-Za-z0-9+.-]*://[^/?#@]+\z};
}

my $TCHAR = q{!#$%&'*+\-.^_`|~0-9A-Za-z};
my $TOKEN_RE = qr/[$TCHAR]+/;
my $TOKEN68_RE = qr/[A-Za-z0-9\-._~+\/]+={0,}/;

sub _parse_field {
    my ($value) = @_;

    if ($value =~ /[\r\n]/) {
        return [{
            scheme    => undef,
            raw       => $value,
            params    => {},
            token68   => undef,
            malformed => 1,
            error     => 'challenge header value contains a newline',
        }];
    }

    my @parts = _split_top_level_commas($value);
    my @out;
    my $current;

    for my $part (@parts) {
        my $trim = $part;
        $trim =~ s/\A[ \t]+//;
        $trim =~ s/[ \t]+\z//;
        next unless length $trim;

        if ($current && $current->{_mode} && $current->{_mode} eq 'params') {
            my ($name, $param_value, $error) = _parse_auth_param($trim);
            if (defined $name) {
                $current->{raw} .= ',' . $part;
                if (exists $current->{params}{$name}) {
                    $current->{malformed} = 1;
                    $current->{error} ||= "duplicate authentication parameter '$name'";
                }
                else {
                    $current->{params}{$name} = $param_value;
                }
                next;
            }

            if ($trim =~ /\A$TOKEN_RE[ \t]*=/) {
                $current->{raw} .= ',' . $part;
                $current->{malformed} = 1;
                $current->{error} ||= $error || 'malformed authentication parameter';
                next;
            }
        }

        push @out, _finish_challenge($current) if $current;
        $current = _start_challenge($part);
    }

    push @out, _finish_challenge($current) if $current;

    if (!@out && length $value) {
        push @out, {
            scheme    => undef,
            raw       => $value,
            params    => {},
            token68   => undef,
            malformed => 1,
            error     => 'no authentication challenge found',
        };
    }

    return \@out;
}

sub _start_challenge {
    my ($raw) = @_;
    my $trim = $raw;
    $trim =~ s/\A[ \t]+//;
    $trim =~ s/[ \t]+\z//;

    my $challenge = {
        scheme    => undef,
        raw       => $raw,
        params    => {},
        token68   => undef,
        malformed => 0,
        error     => undef,
        _mode     => undef,
    };

    unless ($trim =~ /\A($TOKEN_RE)(?:[ \t]+(.*))?\z/) {
        $challenge->{malformed} = 1;
        $challenge->{error} = 'malformed authentication challenge';
        return $challenge;
    }

    $challenge->{scheme} = lc $1;
    my $rest = $2;
    return $challenge unless defined($rest) && length($rest);

    $rest =~ s/[ \t]+\z//;

    if ($rest =~ /\A($TOKEN68_RE)\z/) {
        $challenge->{token68} = $1;
        $challenge->{_mode} = 'token68';
        return $challenge;
    }

    my ($name, $value, $error) = _parse_auth_param($rest);
    unless (defined $name) {
        $challenge->{malformed} = 1;
        $challenge->{error} = $error || 'malformed authentication parameters';
        return $challenge;
    }

    $challenge->{params}{$name} = $value;
    $challenge->{_mode} = 'params';
    return $challenge;
}

sub _finish_challenge {
    my ($challenge) = @_;
    delete $challenge->{_mode};
    $challenge->{raw} =~ s/\A[ \t]+//;
    $challenge->{raw} =~ s/[ \t]+\z//;
    return $challenge;
}

sub _parse_auth_param {
    my ($text) = @_;

    unless ($text =~ /\A($TOKEN_RE)[ \t]*=[ \t]*(.*)\z/) {
        return (undef, undef, 'authentication parameter requires name=value syntax');
    }

    my $name = lc $1;
    my $raw_value = $2;

    if ($raw_value =~ /\A($TOKEN_RE)\z/) {
        return ($name, $1, undef);
    }

    if ($raw_value =~ /\A"(.*)"\z/s) {
        my $inner = $1;
        return (undef, undef, 'quoted authentication parameter contains a newline')
            if $inner =~ /[\r\n]/;

        my $decoded = '';
        while (length $inner) {
            if ($inner =~ s/\A\\([\x09\x20-\x7e\x80-\xff])//s) {
                $decoded .= $1;
            }
            elsif ($inner =~ s/\A([\x09\x20-\x21\x23-\x5b\x5d-\x7e\x80-\xff]+)//s) {
                $decoded .= $1;
            }
            else {
                return (undef, undef, 'malformed quoted authentication parameter');
            }
        }
        return ($name, $decoded, undef);
    }

    return (undef, undef, 'authentication parameter value must be a token or quoted string');
}

sub _split_top_level_commas {
    my ($text) = @_;
    my @parts;
    my $start = 0;
    my $quoted = 0;
    my $escaped = 0;

    for (my $i = 0; $i < length($text); $i++) {
        my $ch = substr($text, $i, 1);

        if ($quoted) {
            if ($escaped) {
                $escaped = 0;
            }
            elsif ($ch eq '\\') {
                $escaped = 1;
            }
            elsif ($ch eq '"') {
                $quoted = 0;
            }
            next;
        }

        if ($ch eq '"') {
            $quoted = 1;
            next;
        }

        if ($ch eq ',') {
            push @parts, substr($text, $start, $i - $start);
            $start = $i + 1;
        }
    }

    push @parts, substr($text, $start);
    return @parts;
}

1;

__END__

=head1 NAME

Uniform::HTTP::Auth - Framework-agnostic HTTP authentication for Perl

=head1 SYNOPSIS

    use Uniform::HTTP::Auth;

    my $auth = Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => {
            username => 'user',
            password => 'secret',
        },
    );

    my $result = $auth->prepare_authentication(
        challenge_headers => [
            'Digest realm="Members", nonce="abc", qop="auth", algorithm=SHA-256',
            'Basic realm="Members"',
        ],
        method         => 'GET',
        request_target => '/private',
    );

    # $result->{value} is the complete field value, for example:
    # Digest username="user", ...
    #
    # The caller decides whether it belongs in Authorization or
    # Proxy-Authorization and whether the request should be retried.

=head1 DESCRIPTION

C<Uniform::HTTP::Auth> implements HTTP authentication mechanics without
requiring an HTTP client, server, framework, event loop, request object, or
transaction abstraction.

For ordinary applications, construct an auth object with an origin and a set of
credentials.  The object remembers those credentials and uses them later when
that origin presents a supported authentication challenge.

For HTTP libraries or applications with dynamic credential stores,
C<credentials> may instead be a callback that receives the authentication
context and returns credentials for that protection space.

The distribution implements Basic (RFC 7617), Bearer (RFC 6750), and Digest
(RFC 7616).  Unknown schemes are parsed and preserved for introspection but are
not automatically used in version 0.02.

=head1 OWNERSHIP BOUNDARY

This module owns authentication mechanics: challenge parsing, scheme selection,
credential lookup, Basic and Bearer construction, Digest calculation, and
Digest nonce state.

The calling HTTP implementation owns receiving 401 or 407 responses, request
replay, retries, connections, proxy routing, and the choice between
C<Authorization> and C<Proxy-Authorization>.

C<prepare_authentication()> performs no network I/O. It only prepares the
authentication field value that the caller may use for a subsequent HTTP
request.

=head1 CONSTRUCTOR

=head2 new

    my $auth = Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => {
            username => 'user',
            password => 'secret',
        },
    );

Supported options are:

=over 4

=item origin

A normalized origin such as C<https://example.com:443>.  When static
credentials are supplied, C<origin> is required and binds those credentials to
that origin.  Calls to C<prepare_authentication()> may then omit C<origin>.

A callback-based credential source may omit C<origin> and supply it per
C<prepare_authentication()> call instead.  If an origin is supplied at
construction, it is also treated as a binding and a different per-call origin
is rejected.

=item credentials

Usually a hash reference containing credentials to retain for later use.
Basic and Digest use:

    credentials => {
        username => 'user',
        password => 'secret',
    }

Bearer uses:

    credentials => {
        token => $token,
    }

A hash may contain both forms.  Uniform automatically skips a scheme when the
stored credentials do not contain the fields that scheme needs.

For dynamic lookup, C<credentials> may instead be a coderef.  See
L</DYNAMIC CREDENTIAL LOOKUP>.

=item schemes

An array reference containing the enabled authentication schemes in preference
order.  Scheme names are case-insensitive.  The default is:

    [qw(digest bearer basic)]

The order is a convenience policy, not a universal security ranking.  Supply an
explicit order when an application has its own policy.

=back

Unknown constructor options are rejected.

=head1 METHODS

=head2 schemes

    my $schemes = $auth->schemes;

Returns a new array reference containing the configured normalized scheme names.

=head2 parse_challenges

    my $challenges = $auth->parse_challenges(@header_values);

Parses one or more complete C<WWW-Authenticate> or C<Proxy-Authenticate> field
values.  Multiple challenges on one field line and multiple field occurrences
are supported.

Returns an array reference in wire order.  Each element is a plain hash
reference with these keys:

    {
        scheme    => 'digest',
        raw       => 'Digest realm="Members", ...',
        params    => { realm => 'Members', ... },
        token68   => undef,
        malformed => 0,
        error     => undef,
    }

Scheme and parameter names are normalized to lowercase.  Unknown schemes are
retained.  Malformed remote input is returned as data with C<malformed> true and
C<error> set; malformed challenge input does not throw merely because it came
from the network.

=head2 select

    my $challenge = $auth->select($challenges);

Selects the best usable challenge according to the configured scheme order.
The method does not obtain credentials.  It returns undef if no supported
well-formed challenge can be used.

When a field contains multiple Digest challenges, Digest-specific algorithm and
qop selection remains the responsibility of L<Uniform::HTTP::Auth::Digest>.

=head2 prepare_authentication

For an object with a bound origin:

    my $result = $auth->prepare_authentication(
        challenge_headers => \@authenticate_values,
        method            => 'GET',
        request_target    => '/private?x=1',
        entity_body       => $body,
    );

A callback-based object without a bound origin supplies one per call:

    my $result = $auth->prepare_authentication(
        challenge_headers => \@authenticate_values,
        origin            => 'https://example.com:443',
        method            => 'GET',
        request_target    => '/private?x=1',
    );

Performs parsing, scheme selection, credential lookup, and authentication value
construction.  It tries configured schemes in order and can fall through to a
later scheme when suitable credentials are unavailable.  It does not send a
request or otherwise perform network I/O.

C<method> and C<request_target> are required only when Digest is selected.
C<entity_body> is used only for Digest C<qop=auth-int> and must be a plain scalar
when supplied.

Instead of those three values, a caller may supply any object implementing the
L<Uniform::HTTP::Request> contract:

    my $result = $auth->prepare_authentication(
        challenge_headers => \@authenticate_values,
        request           => $request,
    );

Explicit C<method>, C<request_target>, or C<entity_body> arguments take
precedence over values from C<request>. The body is read only when the request
reports true from C<has_buffered_body()>; authentication never consumes an
incremental body source.

On success, the method returns:

    {
        scheme    => 'digest',
        value     => 'Digest username="...", ...',
        challenge => $challenge,
    }

C<value> is the complete authentication field value without a header name.
Returns undef when no supported challenge can be satisfied.

=head1 STATIC CREDENTIALS

Static credentials are the normal application API.  They are copied into the
auth object at construction and bound to the configured origin.

Username/password credentials can satisfy Basic or Digest challenges:

    my $auth = Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => {
            username => 'user',
            password => 'secret',
        },
    );

A token can satisfy Bearer challenges:

    my $auth = Uniform::HTTP::Auth->new(
        origin => 'https://api.example.com:443',
        credentials => {
            token => $token,
        },
    );

Static credentials are never used for a different origin.  To manage many
origins with one object, use dynamic credential lookup instead.

=head1 DYNAMIC CREDENTIAL LOOKUP

HTTP libraries and applications with credential stores can supply a callback:

    my $auth = Uniform::HTTP::Auth->new(
        credentials => sub {
            my ($context) = @_;

            return $store->lookup(
                $context->{origin},
                $context->{realm},
                $context->{scheme},
            );
        },
    );

The callback receives one plain hash reference:

    {
        scheme    => 'digest',
        origin    => 'https://example.com:443',
        realm     => 'Members',
        challenge => $challenge,
    }

Return undef when credentials are unavailable for that protection space.
Return a hash reference otherwise.

Basic and Digest expect:

    { username => 'user', password => 'secret' }

Bearer expects:

    { token => 'token-value' }

The callback supplies credentials; it does not verify them.  Missing fields or
invalid return types are programmer errors and throw exceptions.

=head1 ERROR MODEL

Programmer errors, such as invalid constructor options, invalid argument types,
or malformed credential callback results, throw exceptions with C<croak>.

Malformed remote challenge data is represented in the returned challenge data
and ignored by automatic selection.  A credential callback returning undef is
not an error.

=head1 SECURITY NOTES

Static credentials are bound to one normalized origin.  This prevents an auth
object created for one service from silently offering those credentials to a
different origin.

Basic credentials are only Base64 encoded and should normally be sent over a
secure transport such as TLS.

Bearer tokens are treated as opaque credentials.  This distribution does not
validate JWTs, refresh OAuth tokens, or determine token permissions.

Digest supports legacy MD5 for interoperability as well as SHA-256 and
SHA-512/256 families.  Applications can restrict the enabled authentication
schemes at construction time.

=head1 SEE ALSO

L<Uniform::HTTP::Auth::Basic>, L<Uniform::HTTP::Auth::Bearer>,
L<Uniform::HTTP::Auth::Digest>, RFC 9110, RFC 7617, RFC 7616, RFC 6750.

The distribution also includes F<docs/AUTH-SPEC.md> with the version 0.02 Auth
contract and F<docs/MESSAGE-SPEC.md> with the shared request contract.

=head1 AUTHOR

Joshua S. Day, E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is released under the MIT License.

=cut
