package Uniform::HTTP::Auth;

use strict;
use warnings;
use Carp qw(croak);

use Uniform::HTTP::Auth::Basic ();
use Uniform::HTTP::Auth::Bearer ();
use Uniform::HTTP::Auth::Digest ();

our $VERSION = '0.06';

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

Uniform::HTTP::Auth - HTTP authentication without an HTTP framework

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
        ],
        method         => 'GET',
        request_target => '/private',
    );

    my $value = $result->{value};

=head1 DESCRIPTION

Uniform::HTTP::Auth prepares HTTP authentication field values.

It supports:

=over 4

=item * Basic

=item * Bearer

=item * Digest

=back

It does not send requests, receive 401 responses, retry requests, manage
connections, or choose an HTTP framework.

The normal flow is:

    server challenge
          |
          v
    Uniform::HTTP::Auth
          |
          v
    authentication field value
          |
          v
    your HTTP client or server

The calling HTTP implementation decides whether the value belongs in
C<Authorization> or C<Proxy-Authorization> and whether a request should be
retried.

=head1 SIMPLE USERNAME AND PASSWORD

For one server, store credentials on the auth object:

    my $auth = Uniform::HTTP::Auth->new(
        origin => 'https://example.com:443',
        credentials => {
            username => 'user',
            password => 'secret',
        },
    );

The credentials are bound to that origin.

When a challenge arrives:

    my $result = $auth->prepare_authentication(
        challenge_headers => \@www_authenticate,
        method         => 'GET',
        request_target => '/private',
    );

If a supported challenge can be satisfied, C<$result> contains:

    {
        scheme    => 'digest',
        value     => 'Digest username="...", ...',
        challenge => $challenge,
    }

Use C<$result-E<gt>{value}> as the complete authentication field value.

The configured default preference is:

    digest
    bearer
    basic

You can choose another order with C<schemes>.

=head1 BEARER TOKENS

For Bearer authentication:

    my $auth = Uniform::HTTP::Auth->new(
        origin => 'https://api.example.com:443',
        credentials => {
            token => $token,
        },
    );

The token is treated as opaque data. Uniform::HTTP::Auth does not obtain,
refresh, decode, or validate OAuth tokens or JWTs.

=head1 USING A REQUEST OBJECT

C<prepare_authentication()> can read the request information from a
L<Uniform::HTTP::Request> object:

    my $result = $auth->prepare_authentication(
        challenge_headers => \@www_authenticate,
        request           => $request,
    );

It reads C<method()> and C<target()>.

A body is read only when C<has_buffered_body()> is true. Authentication never
drains a streaming body.

Explicit C<method>, C<request_target>, and C<entity_body> arguments override
values from the request object.

=head1 CONSTRUCTOR

=head2 new

    my $auth = Uniform::HTTP::Auth->new(
        origin      => $origin,
        credentials => $credentials,
        schemes     => [qw(digest basic)],
    );

=head3 origin

A normalized origin such as:

    https://example.com:443

Static credentials require an origin and are never used for a different
origin.

=head3 credentials

For Basic or Digest:

    {
        username => 'user',
        password => 'secret',
    }

For Bearer:

    {
        token => $token,
    }

A hash may contain both forms.

For applications with a credential store, C<credentials> may instead be a
callback. See L</DYNAMIC CREDENTIAL LOOKUP>.

=head3 schemes

An optional array reference containing enabled schemes in preference order.

The default is:

    [qw(digest bearer basic)]

=head1 MAIN METHODS

=head2 prepare_authentication

    my $result = $auth->prepare_authentication(
        challenge_headers => \@values,
        method            => 'GET',
        request_target    => '/private',
    );

This is the main application method.

It parses the challenges, chooses a supported scheme, finds credentials, and
constructs the authentication value.

It returns C<undef> when no challenge can be satisfied.

Digest needs C<method> and C<request_target>. C<entity_body> is used only for
Digest C<qop=auth-int>.

This method performs no network I/O.

=head2 parse_challenges

    my $challenges = $auth->parse_challenges(@header_values);

Parses complete C<WWW-Authenticate> or C<Proxy-Authenticate> values.

It returns an array reference in wire order. Unknown schemes are preserved.
Malformed remote challenges are returned as malformed data rather than causing
an exception merely because the server sent bad input.

=head2 select

    my $challenge = $auth->select($challenges);

Returns the best usable challenge according to the configured scheme order, or
C<undef> when none is usable.

This method only selects a challenge. It does not look up credentials.

=head2 schemes

Returns a new array reference containing the configured scheme names.

=head1 DYNAMIC CREDENTIAL LOOKUP

Reusable HTTP libraries and applications with a credential store can supply a
callback:

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

The callback receives:

    {
        scheme    => 'digest',
        origin    => 'https://example.com:443',
        realm     => 'Members',
        challenge => $challenge,
    }

Return C<undef> when credentials are unavailable.

For Basic and Digest return:

    {
        username => 'user',
        password => 'secret',
    }

For Bearer return:

    {
        token => $token,
    }

=head1 DIGEST SUPPORT

Digest supports:

=over 4

=item * MD5 and MD5-sess

=item * SHA-256 and SHA-256-sess

=item * SHA-512/256 and SHA-512/256-sess

=item * C<qop=auth>

=item * C<qop=auth-int>

=item * UTF-8

=item * C<userhash>

=item * stale nonces and nonce-count state

=back

MD5 remains available for compatibility with older servers.

=head1 ERRORS

Programmer mistakes throw exceptions. Examples include bad constructor
arguments, invalid credential values, and invalid callback results.

Bad challenge data received from a remote server is represented as malformed
challenge data so callers can inspect it safely.

=head1 SECURITY

Basic authentication only encodes credentials with Base64. It should normally
be used over TLS.

Bearer tokens are credentials and should be protected accordingly.

Digest is an authentication mechanism, not transport encryption. Legacy MD5
Digest is supported for interoperability but should not be preferred when a
stronger option is available.

=head1 LOWER-LEVEL MODULES

Most applications should use this module.

The lower-level calculation modules are available when needed:

=over 4

=item * L<Uniform::HTTP::Auth::Basic>

=item * L<Uniform::HTTP::Auth::Bearer>

=item * L<Uniform::HTTP::Auth::Digest>

=back

=head1 SEE ALSO

L<Uniform::HTTP>, L<Uniform::HTTP::Request>.

The detailed authentication contract is in F<docs/AUTH-SPEC.md>.

=head1 AUTHOR

Joshua S. Day E<lt>HAX@cpan.orgE<gt>

=head1 LICENSE

This software is available under the MIT License.

=cut
