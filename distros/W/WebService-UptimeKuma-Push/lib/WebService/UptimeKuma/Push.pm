# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2026 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.010;
use strict;
use warnings;

package WebService::UptimeKuma::Push;

our $VERSION = '0.002';

use Carp             ();
use HTTP::Tiny 0.025 ();
use JSON::PP         ();
use Scalar::Util     ();
use Time::HiRes      ();

# WebService::UptimeKuma::Push->new( url => $url, %options );
# WebService::UptimeKuma::Push->new( server => $server, token => $token, %options );
# options:
#   - fatal     (default 0)
#   - http      (default HTTP::Tiny object)
#   - timeout   (default 10)
sub new {
    my ( $class, @args ) = @_;

    Carp::croak 'usage: new( url => URL, [ARGS] ) or new( server => SERVER, token => TOKEN, [ARGS] )' if @args % 2;
    my %args = @args;

    my %args_keys = map { $_ => 1 } keys %args;
    my %self      = (
        _fatal => !!0,
    );

    # url, or server and token
    if ( exists $args{url} ) {
        Carp::croak 'Cannot specify url together with server or token' if exists $args{server} || exists $args{token};

        my $url = $args{url};
        Carp::croak 'url must be defined' if !defined $url;

        # The push URL shown by Uptime Kuma contains a query string
        # (?status=up&msg=OK&ping=) which we ignore.
        my ( $server, $token ) = "$url" =~ m{ \A ( https? :// [^?#]+? ) /api/push/ ( [^/?#]+ ) /? (?: [?#] .* )? \z }xsmi
          or Carp::croak "Not an Uptime Kuma push URL: '$url'";

        $self{_server} = $server;
        $self{_token}  = $token;
        delete $args_keys{url};
    }
    else {
        for my $arg (qw(server token)) {
            Carp::croak "Missing argument: '$arg'" if !defined $args{$arg} || $args{$arg} eq q{};
        }

        my $server = "$args{server}";
        $server =~ s{ /+ \z }{}xsm;
        Carp::croak "server must be a http or https URL: '$args{server}'" if $server !~ m{ \A https? :// [^/?#]+ }xsmi;

        $self{_server} = $server;
        $self{_token}  = "$args{token}";
        delete @args_keys{qw(server token)};
    }

    # fatal
    if ( exists $args{fatal} ) {
        $self{_fatal} = !!$args{fatal};
        delete $args_keys{fatal};
    }

    # http and timeout
    Carp::croak 'Cannot specify http together with timeout' if exists $args{http} && exists $args{timeout};

    if ( exists $args{http} ) {
        my $http = $args{http};
        Carp::croak 'http must be an object with a get method' if !defined Scalar::Util::blessed($http) || !$http->can('get');

        $self{_http} = $http;
        delete $args_keys{http};
    }
    else {
        my $timeout = 10;
        if ( exists $args{timeout} ) {
            $timeout = $args{timeout};
            Carp::croak 'timeout must be a positive number' if !defined $timeout || $timeout !~ m{ \A [0-9]+ (?: [.] [0-9]+ )? \z }xsm || $timeout <= 0;
            delete $args_keys{timeout};
        }

        $self{_http} = HTTP::Tiny->new(
            agent      => "WebService-UptimeKuma-Push/$VERSION ",
            timeout    => $timeout,
            verify_SSL => 1,
        );
    }

    #
    my @unknown = sort keys %args_keys;
    Carp::croak 'Unknown argument' . ( @unknown > 1 ? 's' : q{} ) . q{: '} . join( q{', '}, @unknown ) . q{'} if @unknown;

    return bless \%self, $class;
}

sub down {
    my ( $self, @args ) = @_;

    return $self->_push( 'down', $self->{_fatal}, @args );
}

sub error {
    my ($self) = @_;

    return $self->{_error};
}

sub run {
    my ( $self, $code, @args ) = @_;

    Carp::croak 'usage: run( CODE, [ARGS] )' if ref $code ne 'CODE' || @args % 2;
    my %args = @args;

    my @unknown = sort grep { $_ ne 'msg' } keys %args;
    Carp::croak 'Unknown argument' . ( @unknown > 1 ? 's' : q{} ) . q{: '} . join( q{', '}, @unknown ) . q{'} if @unknown;

    my $wantarray = wantarray;    ## no critic (Community::Wantarray)
    my @result;
    my $start = [Time::HiRes::gettimeofday];
    my $ok;
    my $e;
    {
        local $@;                 ## no critic (Variables::RequireInitializationForLocalVars)
        $ok = eval {
            if ($wantarray) {
                @result = $code->();
            }
            elsif ( defined $wantarray ) {
                $result[0] = $code->();
            }
            else {
                $code->();
            }

            1;
        };
        $e = $@;
    }
    my $ping = sprintf '%.3f', 1000 * Time::HiRes::tv_interval($start);

    if ( !$ok ) {
        my $msg = defined $e && $e ne q{} ? "$e" : 'Unknown error';
        $msg =~ s{ \s+ \z }{}xsm;

        # The exception from the code is more important than a failed
        # heartbeat, even if fatal is set.
        $self->_push( 'down', !!0, msg => $msg, ping => $ping );

        # rethrow the original exception
        die $e;    ## no critic (ErrorHandling::RequireCarping)
    }

    $self->up( ( exists $args{msg} ? ( msg => $args{msg} ) : () ), ping => $ping );

    return @result if $wantarray;
    return $result[0];
}

sub server {
    my ($self) = @_;

    return $self->{_server};
}

sub token {
    my ($self) = @_;

    return $self->{_token};
}

sub up {
    my ( $self, @args ) = @_;

    return $self->_push( 'up', $self->{_fatal}, @args );
}

sub url {
    my ($self) = @_;

    return "$self->{_server}/api/push/" . _uri_escape( $self->{_token} );
}

sub _push {
    my ( $self, $status, $fatal, @args ) = @_;

    Carp::croak "usage: $status( [ARGS] )" if @args % 2;
    my %args = @args;

    my %args_keys = map { $_ => 1 } keys %args;
    my @query     = ( status => $status );

    # msg
    if ( exists $args{msg} ) {
        if ( defined $args{msg} ) {
            push @query, msg => "$args{msg}";
        }
        delete $args_keys{msg};
    }

    # ping
    if ( exists $args{ping} ) {
        my $ping = $args{ping};
        if ( defined $ping ) {
            Carp::croak "ping must be a non-negative number: '$ping'" if $ping !~ m{ \A [0-9]+ (?: [.] [0-9]+ )? \z }xsm;
            push @query, ping => $ping;
        }
        delete $args_keys{ping};
    }

    #
    my @unknown = sort keys %args_keys;
    Carp::croak 'Unknown argument' . ( @unknown > 1 ? 's' : q{} ) . q{: '} . join( q{', '}, @unknown ) . q{'} if @unknown;

    my @query_string;
    while ( my ( $key, $value ) = splice @query, 0, 2 ) {
        push @query_string, "$key=" . _uri_escape($value);
    }
    my $url = $self->url . q{?} . join q{&}, @query_string;

    delete $self->{_error};

    my $error;
    {
        local $@;    ## no critic (Variables::RequireInitializationForLocalVars)
        my $response = eval { $self->{_http}->get($url) };

        if ( !defined $response ) {
            $error = defined $@ && $@ ne q{} ? qq{$@} : 'HTTP request failed';
            $error =~ s{ \s+ \z }{}xsm;
        }
        else {
            $error = _check_response($response);
        }
    }

    return !!1 if !defined $error;

    $self->{_error} = $error;
    Carp::croak "Cannot push status '$status' to Uptime Kuma: $error" if $fatal;

    return !!0;
}

sub _check_response {
    my ($response) = @_;

    return 'Invalid response from HTTP client' if !defined Scalar::Util::reftype($response) || Scalar::Util::reftype($response) ne 'HASH';

    my $content = defined $response->{content} ? $response->{content} : q{};

    # HTTP::Tiny uses status 599 for internal errors (e.g. connection
    # failed) with the error message as content
    if ( defined $response->{status} && $response->{status} eq '599' ) {
        $content =~ s{ \s+ \z }{}xsm;
        return $content ne q{} ? $content : 'HTTP request failed';
    }

    my $json = eval { JSON::PP->new->decode($content) };
    if ( defined Scalar::Util::reftype($json) && Scalar::Util::reftype($json) eq 'HASH' && exists $json->{ok} ) {
        return              if $json->{ok}          && $response->{success};
        return $json->{msg} if defined $json->{msg} && $json->{msg} ne q{};
    }

    my $status = defined $response->{status} ? $response->{status} : q{???};
    my $reason = defined $response->{reason} ? $response->{reason} : q{};
    return $response->{success} ? "Unexpected response from Uptime Kuma: $status $reason" : "$status $reason";
}

sub _uri_escape {
    my ($value) = @_;

    utf8::encode($value);
    $value =~ s{ ( [^A-Za-z0-9\-._~] ) }{ sprintf '%%%02X', ord $1 }xsmge;

    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::UptimeKuma::Push - update Uptime Kuma push monitors

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

    use WebService::UptimeKuma::Push 0.001;

    my $kuma = WebService::UptimeKuma::Push->new(
        server => 'https://kuma.example.net:3001',
        token  => 'MSCHnx6nVs',
    );

    # or use the push URL from the Uptime Kuma web interface
    my $kuma = WebService::UptimeKuma::Push->new(
        url => 'https://kuma.example.net:3001/api/push/MSCHnx6nVs?status=up&msg=OK&ping=',
    );

    $kuma->up( msg => 'hello world', ping => 7 );
    $kuma->down( msg => 'backup failed' );

    # run the code, report its runtime as ping and up or down
    # depending on whether it threw an exception
    $kuma->run( sub { do_backup() } );

=head1 DESCRIPTION

L<Uptime Kuma|https://uptime.kuma.pet/> supports I<push> monitors. Instead
of Uptime Kuma checking a service, the service (or a script) sends a
heartbeat to Uptime Kuma. If no heartbeat arrives in time, Uptime Kuma
marks the monitor as down.

This module sends these heartbeats, so you don't have to construct the push
URL yourself in every script.

By default, failing to reach Uptime Kuma is not fatal. A script which does
its job should not die because the monitoring is unavailable. The methods
C<up> and C<down> return false instead and the reason is available from
C<error>. Use the C<fatal> option to get an exception instead.

=head1 USAGE

=head2 new( ARGS )

Creates and returns a new C<WebService::UptimeKuma::Push> object for one
push monitor. C<new> throws an exception on invalid arguments.

    my $kuma = WebService::UptimeKuma::Push->new( url => $url );
    my $kuma = WebService::UptimeKuma::Push->new( server => $server, token => $token );
    my $kuma = WebService::UptimeKuma::Push->new( url => $url, fatal => 1, timeout => 3 );

The following arguments are supported:

=head3 url

The push URL of the monitor, as shown by the Uptime Kuma web interface. The
query string is ignored.

Either C<url>, or C<server> and C<token> must be specified.

=head3 server

The base URL of the Uptime Kuma server, consisting of the scheme, the host
and, optionally, the port.

=head3 token

The push token of the monitor.

=head3 fatal

If true, C<up>, C<down>, and C<run> throw an exception if the heartbeat
cannot be delivered. Defaults to false.

=head3 timeout

The timeout, in seconds, for the HTTP request. Defaults to 10.

=head3 http

An object to use instead of the default L<HTTP::Tiny> object. It must
provide a C<get> method compatible with C<HTTP::Tiny>. This can be used to
configure a proxy or SSL options. Cannot be combined with C<timeout>.

=head2 up( [ARGS] )

Sends an up heartbeat to Uptime Kuma. Returns true on success and false
otherwise. If C<fatal> is set, an exception is thrown instead of returning
false.

    $kuma->up;
    $kuma->up( msg => 'all good', ping => 17 );

The following arguments are supported:

=over 4

=item * C<msg> - The message shown in Uptime Kuma. Uptime Kuma uses C<OK> if
none is given.

=item * C<ping> - The response time, in milliseconds, shown in Uptime Kuma.

=back

=head2 down( [ARGS] )

Sends a down heartbeat to Uptime Kuma. Supports the same arguments, and
returns the same, as C<up>.

    $kuma->down( msg => 'disk full' );

=head2 run( CODE, [ARGS] )

Runs the code reference and measures its runtime. If the code returns,
an up heartbeat is sent with the runtime as C<ping>. If the code throws an
exception, a down heartbeat is sent with the exception as C<msg> and the
exception is rethrown. In that case a failure to deliver the down
heartbeat is never fatal, the exception from the code takes precedence.

Returns whatever the code returned, in the context C<run> was called in.

    my $result = $kuma->run( sub { do_backup() }, msg => 'backup done' );

The only supported argument is C<msg>, the message to send on success.

=head2 error

Returns the error of the last failed C<up> or C<down>, or C<undef> if the
last heartbeat was delivered successfully.

=head2 server

Returns the base URL of the Uptime Kuma server.

=head2 token

Returns the push token.

=head2 url

Returns the push URL, without query string.

=head1 EXAMPLES

=head2 Example 1 Report the result of a cron job

    use WebService::UptimeKuma::Push;

    my $kuma = WebService::UptimeKuma::Push->new(
        url => 'https://kuma.example.net:3001/api/push/MSCHnx6nVs',
    );

    $kuma->run(
        sub {
            system( 'rsync', '-a', '/data/', 'backup:/data/' ) == 0
              or die "rsync failed with exit code " . ( $? >> 8 ) . "\n";
        },
        msg => 'backup successful',
    );

=head1 SEE ALSO

L<HTTP::Tiny>, L<https://github.com/louislam/uptime-kuma>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/WebService-UptimeKuma-Push/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/WebService-UptimeKuma-Push>

  git clone https://github.com/skirmess/WebService-UptimeKuma-Push.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=cut
