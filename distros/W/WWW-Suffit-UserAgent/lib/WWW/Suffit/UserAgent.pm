package WWW::Suffit::UserAgent;
use warnings;
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::Suffit::UserAgent - Suffit API user agent library

=head1 SYNOPSIS

    use WWW::Suffit::UserAgent;

    my $clinet = WWW::Suffit::UserAgent->new(
        url                 => "https://localhost",
        username            => "username", # optional
        password            => "password", # optional
        max_redirects       => 2, # Default: 10
        connect_timeout     => 3, # Default: 10 sec
        inactivity_timeout  => 5, # Default: 30 sec
        request_timeout     => 10, # Default: 5 min (300 sec)
    );
    my $status = $client->check();

    if ($status) {
        print STDOUT $client->res->body;
    } else {
        print STDERR $clinet->error;
    }

=head1 DESCRIPTION

Suffit API user agent library

=head2 new

    my $clinet = WWW::Suffit::UserAgent->new(
        url                 => "https://localhost",
        username            => "username", # optional
        password            => "password", # optional
        max_redirects       => 2, # Default: 10
        connect_timeout     => 3, # Default: 10 sec
        inactivity_timeout  => 5, # Default: 30 sec
        request_timeout     => 10, # Default: 5 min (300 sec)
    );

Returns the client instance

=over 8

=item B<auth_scheme>

Sets the authentication scheme. HTTP Authentication Schemes: Bearer, Basic, ApiKey

Default: ApiKey (use token header)

=item B<ask_credentials>

Enables ask username and password from terminal

=item B<max_redirects>

Maximum number of redirects the user agent will follow before it fails. Default - 10

=item B<password>

Default password for basic authentication

=item B<*timeout>

Timeout for connections, requests and inactivity periods in seconds.

=item B<ua>

The Mojo UserAgent object

=item B<url>

Full URL of the WEB Server

=item B<username>

Default username for basic authentication

=back

=head1 METHODS

List of the User Agent interface methods

=head2 cleanup

    $client->cleanup;

Cleanup all variable data in object and returns client object

=head2 code

    my $code = $clinet->code;
    $client  = $clinet->code(200);

Returns HTTP code of the response

=head2 credentials

    my $userinfo = $client->credentials(1);

Gets credentials for User Agent

=head2 error

    print $clinet->error;
    $clinet = $clinet->error("My error");

Returns error string

=head2 path2url

    # For url = http://localhost:8695/api
    my $url_str = $client->path2url("/foo/bar");
        # http://localhost:8695/api/foo/bar

Merges path to tail of url

    # For url = http://localhost:8695/api
    my $url_str = $client->path2url("/foo/bar", 1);
        # http://localhost:8695/foo/bar

Sets path to url

=head2 private_key

    $clinet = $clinet->private_key("---- BEGIN ... END -----");
    my $private_key = $client->private_key;

Sets or returns RSA private key

=head2 public_key

    $clinet = $clinet->public_key("---- BEGIN ... END -----");
    my $public_key = $client->public_key;

Sets or returns RSA public key

=head2 proxy

    my $proxy = $client->proxy;
    $client->proxy('http://47.88.62.42:80');

Get or set proxy

=head2 req

    my $request = $clinet->req;

Returns Mojo::Message::Request object

=head2 request

    my $json = $clinet->request("METHOD", "PATH", ...ATTRIBUTES...);

Send request

=head2 res

    my $response = $clinet->res;

Returns Mojo::Message::Response object

=head2 status

    my $status = $clinet->status;
    $clinet    = $clinet->status(1);

Returns object status value. 0 - Error; 1 - Ok

=head2 str2url

    # http://localhost/api -> http://localhost/api/foo/bar
    my $url = $self->str2url("foo/bar");

    # http://localhost/api -> http://localhost/foo/bar
    my $url = $self->str2url("/foo/bar");

    # http://localhost/api/baz -> http://localhost/api/baz
    my $url = $self->str2url("http://localhost/api/baz");

Returns URL from specified sting

=head2 token

    $clinet = $clinet->token("abc123...fcd");
    my $token = $client->token;

Returns token

=head2 trace

    my $trace = $client->trace;
    print $client->trace("New trace record");

Gets trace stack or pushes new trace record to trace stack

=head2 tx

    my $status = $clinet->tx($tx);

Works with Mojo::Transaction object, interface with it

=head2 tx_string

    print $client->tx_string;

Retruns transaction status string

=head2 ua

    my $ua = $clinet->ua;

Returns Mojo::UserAgent object

=head2 url

    my $url_object = $clinet->url;

Returns Mojo::URL object

=head1 API METHODS

List of predefined the Suffit API methods

=head2 check

    my $status = $client->check;
    my $status = $client->check( URLorPath );

Returns check-status of server. 0 - Error; 1 - Ok

=head1 HTTP BASIC AUTHORIZATION

For pass HTTP Basic Authorization with ask user credentials from console use follow code:

    my $client = WWW::Suffit::UserAgent->new(
        ask_credentials => 1,
        auth_scheme => 'Basic',
        # ...
    );

... and without ask:

    my $client = WWW::Suffit::UserAgent->new(
        username => 'test',
        password => 'test',
        # ...
    );

You can also use credentials in the userinfo part of a base URL:

    my $client = WWW::Suffit::UserAgent->new(
        url => 'https://test:test@localhost',
        # ...
    )

=head1 TLS CLIENT CERTIFICATES

    $client->ua->cert('tls.crt')->key('tls.key')->ca('ca.crt');

See L<Mojo::UserAgent/cert>, L<Mojo::UserAgent/key>, L<Mojo::UserAgent/ca> and L<Mojo::UserAgent/tls_options>

=head1 PROXY

In constructor:

    my $client = WWW::Suffit::UserAgent->new(
        proxy => 'http://47.88.62.42:80',
        # ...
    );

Before request:

    my $status = $client
        ->proxy('http://47.88.62.42:80')
        ->request(GET => $client->str2url('http://ifconfig.io/all.json'));

    # Socks5
    my $status = $client
        ->proxy('socks://socks:socks@192.168.201.129:1080')
        ->request(GET => $client->str2url('http://ifconfig.io/all.json'));

Directly:

    $client->ua->proxy
        ->http('http://47.88.62.42:80')
        ->https('http://188.125.173.185:8080');

    my $status = $client
        ->proxy('http://47.88.62.42:80')
        #->proxy('socks://socks:socks@192.168.201.129:1080')
        ->request(GET => $client->str2url('http://ifconfig.io/all.json'));

=head1 DEPENDENCIES

L<Mojolicious>, L<Mojo::UserAgent>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::UserAgent>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2025 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '1.01';

use Mojo::UserAgent;
use Mojo::UserAgent::Proxy;
use Mojo::Asset::File;
use Mojo::URL;
use Mojo::Util qw/steady_time b64_encode/;

use WWW::Suffit::Const qw/ DEFAULT_URL TOKEN_HEADER_NAME /;
use Acrux::Util qw/ fbytes fduration /;

use constant {
        MAX_REDIRECTS       => 10,
        CONNECT_TIMEOUT     => 10,
        INACTIVITY_TIMEOUT  => 30,
        REQUEST_TIMEOUT     => 180,
        TRANSACTION_MASK    => "%s %s >>> %s %s [%s in %s%s]", # GET /info >>> 200 OK [1.04 KB in 0.0242 seconds (43.1 KB/sec)]
        CONTENT_TYPE        => 'application/json',
        REALM               => 'Restricted zone',
    };

sub new {
    my $class = shift;
    my %args  = @_;

    # General
    $args{status} = 1; # Boolean status: 0 - error, 1 - ok
    $args{error} = ""; # Error string (message) or HTTP Error message
    $args{code} = 0;   # HTTP Error code (integer) or error code string value (default is integer)

    # Base URL & URL Prefix
    $args{url} = Mojo::URL->new($args{url} || DEFAULT_URL); # base url
    $args{prefix} = $args{url}->path->to_string // ''; $args{prefix} =~ s/\/+$//;

    # HTTP Basic Authorization credentials
    $args{credentials} = "";
    $args{auth_scheme} ||= "";
    $args{username} //= $args{url}->username // '';
    $args{password} //= $args{url}->password // '';
    $args{ask_credentials} ||= 0;

    # API/Access/Session token
    $args{token} //= "";
    $args{token_name} ||= TOKEN_HEADER_NAME;

    # Security
    $args{public_key} //= "";
    $args{private_key} //= "";

    # Proxy string
    $args{proxy} //= "";

    # Transaction (tx)
    $args{trace} = []; # trace pool
    $args{tx_string} = "";
    $args{tx_time} = 0;
    $args{req} = undef;
    $args{res} = undef;

    # User Agent
    my $ua = $args{ua};
    unless ($ua) {
        # Create the instance
        $ua = Mojo::UserAgent->new(
                max_redirects       => $args{max_redirects} || MAX_REDIRECTS,
                connect_timeout     => $args{connect_timeout} || CONNECT_TIMEOUT,
                inactivity_timeout  => $args{inactivity_timeout} || INACTIVITY_TIMEOUT,
                request_timeout     => $args{request_timeout} || REQUEST_TIMEOUT,
                insecure            => $args{insecure} || 0,
            );
        $ua->transactor->name(sprintf("%s/%s", __PACKAGE__, __PACKAGE__->VERSION));

        # Set proxy
        my $proxy = Mojo::UserAgent::Proxy->new;
        $ua->proxy($proxy->http($args{proxy})->https($args{proxy})) if $args{proxy};

        $args{ua} = $ua;
    }

    my $self = bless {%args}, $class;
    return $self;
}

## INTERFACE METHODS

sub error {
    my $self = shift;
    my $e = shift;
    if (defined $e) {
        $self->{error} = $e;
        return $self;
    }
    return $self->{error};
}
sub status {
    my $self = shift;
    my $s = shift;
    if (defined $s) {
        $self->{status} = $s;
        return $self;
    }
    return $self->{status};
}
sub code {
    my $self = shift;
    my $c = shift;
    if (defined $c) {
        $self->{code} = $c;
        return $self;
    }
    return $self->{code};
}
sub trace {
    my $self = shift;
    my $v = shift;
    if (defined($v)) {
        my $a = $self->{trace};
        push @$a, $v;
        return $v;
    }
    my $trace = $self->{trace} || [];
    return join("\n",@$trace);
}
sub token {
    my $self = shift;
    my $t = shift;
    if (defined $t) {
        $self->{token} = $t;
        return $self;
    }
    return $self->{token};
}
sub public_key {
    my $self = shift;
    my $k = shift;
    if (defined $k) {
        $self->{public_key} = $k;
        return $self;
    }
    return $self->{public_key};
}
sub private_key {
    my $self = shift;
    my $k = shift;
    if (defined $k) {
        $self->{private_key} = $k;
        return $self;
    }
    return $self->{private_key};
}
sub proxy {
    my $self = shift;
    my $p = shift;
    return $self->{proxy} unless defined $p;
    $self->{proxy} = $p;

    # Set proxy
    $self->ua->proxy->http($p)->https($p) if length $p;

    return $self;
}
sub cleanup {
    my $self = shift;
    $self->{status} = 1;
    $self->{error} = "";
    $self->{code} = 0;
    $self->{tx_string} = "";
    undef $self->{req};
    $self->{req} = undef;
    undef $self->{res};
    $self->{res} = undef;
    undef $self->{trace};
    $self->{trace} = [];
    return $self;
}
sub req {
    my $self = shift;
    return $self->{req};
}
sub res {
    my $self = shift;
    return $self->{res};
}
sub url {
    my $self = shift;
    return $self->{url};
}
sub tx_string {
    my $self = shift;
    return $self->{tx_string} // '';
}
sub path2url {
    my $self = shift;
    my $p = shift // "/";
    my $r = shift; # Is root, no use preffix
    my $url = $self->url->clone;
    my $path = $r ? $p : sprintf("%s/%s", $self->{prefix}, $p);
    $path =~ s/\/{2,}/\//g;
    return $url->path_query($path)->to_string;
}
sub str2url {
    my $self = shift;
    my $str = shift // "";
    if ($str =~ /^https?\:\/\//) { # url (http/https)
        return $str;
    } elsif ($str =~ /^\//) { # absolute path (started from root, e.g.: /foo/bar)
        return $self->path2url($str, 1);
    } elsif (length $str) { # relative path (started from tail of base url, e.g.: foo/bar)
        return $self->path2url($str);
    }
    return $self->url->clone->to_string;
}
sub ua {
    my $self = shift;
    return $self->{ua};
}
sub tx {
    my $self = shift;
    my $tx = shift;

    # Check Error
    my $err = $tx->error;
    unless (!$err || $err->{code}) {
        $self->error($err->{message});
        $self->status(0);
    }
    $self->code($tx->res->code || "000");
    $self->status($tx->res->is_success ? 1 : 0);
    $self->error($tx->res->json("/error") || $tx->res->json("/message") || $err->{message} || "Unknown transaction error" )
        if $tx->res->is_error && !$self->error;

    # Transaction string
    my $length = $tx->res->body_size || 0;
    my $rtime = $self->{tx_time} // 0;
    $self->{tx_string} = sprintf(TRANSACTION_MASK,
        $tx->req->method, $tx->req->url->to_abs, # Method & URL
        $self->code, $tx->res->message || $err->{message} || "Unknown error", # Line
        fbytes($length), # Length
        fduration($rtime), # Duration
        $rtime ? sprintf(" (%s/sec)", fbytes($length/$rtime)) : "",
    );

    # Tracing
    $self->trace($self->{tx_string});
    my $req_hdrs = $tx->req->headers->to_string;
    if ($req_hdrs) {
        $self->trace(join("\n", map {$_ = "> $_"} split(/\n/, $req_hdrs)));
        $self->trace(">");
    }
    my $res_hdrs = $tx->res->headers->to_string;
    if ($res_hdrs) {
        $self->trace(join("\n", map {$_ = "< $_"} split(/\n/, $res_hdrs)));
        $self->trace("<");
    }

    # Request And Response
    $self->{req} = $tx->req;
    $self->{res} = $tx->res;

    return $self->status;
}
sub request {
    my $self = shift;
    my $meth = shift;
    my $_url = shift;
    my @params = @_;
    $self->cleanup(); # Cleanup first

    # Set URL
    my $url = $_url ? Mojo::URL->new("$_url") : $self->url->clone;
    my $credentials = $self->credentials(0); # No ask!
    $url->userinfo($credentials) if $credentials; # + credentials

    # Request
    my $start_time = steady_time() * 1;
    my $tx = $self->ua->build_tx($meth, $url, @params); # Create transaction (tx)
       $self->_set_authorization_header($tx);
    my $res_tx = $self->ua->start($tx); # Run it!
    $self->{tx_time} = sprintf("%.*f",4, steady_time()*1 - $start_time) * 1;
    my $status = $self->tx($res_tx); # Validate!);

    # Auth required? - for Basic scheme set credentials to URL
    if (!$status && $self->{ask_credentials} && ($self->code == 401) && lc($self->{auth_scheme}) eq 'basic') {
        $self->cleanup();
        $credentials = $self->credentials(1); # Ask!;
        $url->userinfo($credentials) if $credentials;

        # Request
        $tx = $self->ua->build_tx($meth, $url, @params); # Create transaction (tx)
        $self->_set_authorization_header($tx);
        $res_tx = $self->ua->start($tx); # Run it!
        $self->{tx_time} = sprintf("%.*f",4, steady_time()*1 - $start_time) * 1;
        $status = $self->tx($res_tx); # Validate!;
    }

    return $status;
}
sub credentials {
    my $self = shift;
    my $ask = shift(@_) ? 1 : 0;

    # Return predefined credentials
    return $self->{credentials} if $self->{credentials};

    # Return predefined credentials if username and password are specified
    if (length($self->{username}) && length($self->{password})) {
        $self->{credentials} = sprintf("%s:%s", $self->{username}, $self->{password});
        return $self->{credentials};
    }

    # Prompt if ask flag is true and has terminal
    if ($ask && -t STDIN) {
        my ($username, $password);
        printf STDERR "Enter username for %s at %s: ", REALM, $self->url->host_port;
        $username = <STDIN>;
        chomp($username);
        if (length($username)) {
            print STDERR "Password: ";
            system("stty -echo");
            $password = <STDIN>;
            system("stty echo");
            print STDERR "\n"; # because we disabled echo
            chomp($password);
            $self->{username} = $username;
            $self->{password} = $password;
        } else {
            return "";
        }
        $self->{credentials} = sprintf("%s:%s", $username, $password);
        return $self->{credentials};
    }

    return "";
}

## SUFFIT API COMMON METHODS

sub check {
    my $self = shift;
    my $url = shift // ''; # URL or String (api)
    return $self->request(HEAD => $self->str2url($url));
}

## INTERNAL METHODS

sub _set_authorization_header {
    my $self = shift;
    my $tx = shift;
    my $scheme = lc($self->{auth_scheme});
    my $header_name = 'Authorization';
    my $header_value = '';

    # HTTP Authentication Schemes: https://www.iana.org/assignments/http-authschemes/http-authschemes.xhtml
    if ($scheme eq 'bearer') { # Bearer [RFC6750]
        $header_value = sprintf('Bearer %s', $self->token) if $self->token;
    } elsif ($scheme eq 'basic') { # Basic [RFC7617]
        $header_value = sprintf('Basic %s',
            b64_encode(sprintf('%s:%s',
                $self->{username} // 'anonymous',
                $self->{password} // ''
            ), '')
        );
    } elsif ($self->token) { # Oops! Use custom header
        $tx->req->headers->header($self->{token_name}, $self->token);
        return $self->token;
    } else {
        return undef;
    }

    # Set header
    $tx->req->headers->header($header_name, $header_value) if $header_value;
    return $header_value;
}

1;

__END__
