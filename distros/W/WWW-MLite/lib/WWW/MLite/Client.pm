package WWW::MLite::Client; # $Id: Client.pm 52 2019-06-29 16:21:14Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

WWW::MLite::Client - WWW::MLite REST Client base class

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    use WWW::MLite::Client;

    my $client = new MDScore::Client(
            verbose         => 0, # 0 - off, 1 - on
            url             => "https://your.domain.name/path",
            timeout         => 180,
            format          => "auto", # xml, json, yaml, auto
            content_type    => "text/plain",
            sr_attrs        => {
                xml => [
                        { # For serialize
                            RootName   => "request",
                        },
                        { # For deserialize
                            ForceArray => 1,
                            ForceContent => 1,
                        }
                    ],
                json => [
                        { # For serialize
                            utf8 => 0,
                            pretty => 1,
                            allow_nonref => 1,
                            allow_blessed => 1,
                        },
                        { # For deserialize
                            utf8 => 0,
                            allow_nonref => 1,
                            allow_blessed => 1,
                        },
                    ],
            },
            no_check_redirect => 0,
            ua_opts => {
                    agent                   => "MyClient/1.00",
                    max_redirect            => 10,
                    requests_redirectable   => ['GET','HEAD'],
                    protocols_allowed       => ['http', 'https'],
                },
            headers => {
                    'Cache-Control' => "no-cache",
                    'Accept'        => "text/plain",
                },
        );

    my $perl = $client->request( POST => "/api", "...data..." );
    print STDERR $client->error unless $client->status;
    print Dumper($perl) if defined($perl);

=head1 DESCRIPTION

WWW::MLite REST Client base class.

This module provides interaction between the REST server and the REST client

=head2 new

    my $client = new MDScore::Client(
            verbose         => 0, # 0 - off, 1 - on
            url             => "https://your.domain.name/path",
            timeout         => 180,
            format          => "auto", # xml, json, yaml, auto
            content_type    => "text/plain",
            sr_attrs        => {
                xml => [
                        { # For serialize
                            RootName   => "request",
                        },
                        { # For deserialize
                            ForceArray => 1,
                            ForceContent => 1,
                        }
                    ],
                json => [
                        { # For serialize
                            utf8 => 0,
                            pretty => 1,
                            allow_nonref => 1,
                            allow_blessed => 1,
                        },
                        { # For deserialize
                            utf8 => 0,
                            allow_nonref => 1,
                            allow_blessed => 1,
                        },
                    ],
            },
            no_check_redirect => 0,
            ua_opts => {
                    agent                   => "MyClient/1.00",
                    max_redirect            => 10,
                    requests_redirectable   => ['GET','HEAD'],
                    protocols_allowed       => ['http', 'https'],
                },
            headers => {
                    'Cache-Control' => "no-cache",
                    'Accept'        => "text/plain",
                },
        );

=over 4

=item C<content_type>

Content type of request and response

Default: text/plain

=item C<format>

Format name: xml, json, yaml, none or auto

Deserialization will be skipped if format not specified

=item C<headers>

hash of headers for Agent

Default: { 'Cache-Control' => "no-cache" }

=item C<no_check_redirect>

If set the no_check_redirect to true then the check for redirects will not be performed

=item C<sr_attrs>

Hash of the attributes-array for request serialization and deserialization

For example:

    {
        xml => [
                { # For serialize
                    RootName   => "request",
                },
                { # For deserialize
                    ForceArray => 1,
                    ForceContent => 1,
                }
            ],
        json => [
                { # For serialize
                    utf8 => 0,
                    pretty => 1,
                    allow_nonref => 1,
                    allow_blessed => 1,
                },
                { # For deserialize
                    utf8 => 0,
                    allow_nonref => 1,
                    allow_blessed => 1,
                },
    }

=item C<timeout>

Timeout for LWP requests, in seconds

Default: 180 seconds (5 mins)

=item C<ua_opts>

Hash of L<LWP::UserAgent> options

Default:

  {
    agent                   => __PACKAGE__."/".$VERSION,
    max_redirect            => MAX_REDIRECT,
    requests_redirectable   => ['GET','HEAD'],
    protocols_allowed       => ['http', 'https'],
  }

=item C<uri>

URI object, that describes URL of the WEB Server. See B<url> attribute

=item C<url>

Full URL of the WEB Server, eg.: http://user:password@your.domain.name/path/to?foo=bar

=item C<verbose>

Verbose mode. All debug-data are written to trace pool

Default: 0

=back

=head2 cleanup

    $client->cleanup;

Cleanup all variable data in object and returns client object. Returns the Client object

=head2 error

    print $client->error;
    $client->error( " ... error ... " );

Just returns error string if no argument;
sets new error string and returns it if argument specified

=head2 req

    my $request = $client->req;

Returns request object

See L<HTTP::Request>

=head2 request

    my $data = $client->request( GET => "/my/path?foo=bar" );
    my $data = $client->request( GET => "/my/path?foo=bar", undef, sub { ... } );
    my $data = $client->request( GET => "/my/path?foo=bar", sub { ... }, sub { ... } );
    my $data = $client->request( POST => "/my/path", { foo => "bar" } );
    my $data = $client->request( PUT => "/my/path", "...data..." );

Performs request and returns response data

=over 4

=item First arg

HTTP Method:

    HEAD, GET, POST, PUT, PATCH, DELETE and etc.

Default: GET

=item Second arg

Path and query string

Default: undef

=item Third arg

Data: undef, string, perl-structure for serialization or request callback function

Default: undef

Example for uploading:

    my $file = "/path/to/filename";
    $self->request(PUT => "/foo/bar/filename", sub {
        my $req = shift; # HTTP::Request object
        $req->header('Content-Type', 'application/octet-stream');
        if (-e $file and -f $file) {
            my $size = (-s $file) || 0;
            return 0 unless $size;
            my $fh;
            $req->content(sub {
                unless ($fh) {
                    open($fh, "<", $file) or do {
                        $self->error(sprintf("Can't open file %s: %s", $file, $!));
                        return "";
                    };
                    binmode($fh);
                }
                my $buf = "";
                if (my $n = read($fh, $buf, 1024)) {
                    return $buf;
                }
                close($fh);
                return "";
            });
            return $size;
        }
        return 0;
    });

=item Fourth arg

Callback response function

Default: undef

Example for downloading:

    my $expected_length;
    my $bytes_received = 0;
    my $res = $client->request(GET => "/path", undef, sub {
        my($chunk, $res) = @_;
        $bytes_received += length($chunk);
        unless (defined $expected_length) {
            $expected_length = $res->content_length || 0;
        }
        if ($expected_length) {
            printf STDERR "%d%% - ",
                100 * $bytes_received / $expected_length;
        }
        print STDERR "$bytes_received bytes received\n";
        # XXX Should really do something with the chunk itself
        # print $chunk;
    });

See L<LWP::UserAgent>

=back

=head2 res

    my $response = $client->res;

Returns response object

See L<HTTP::Response>

=head2 serializer

    my $serializer = $client->serializer;

Returns serializer object

=head2 status

    my $status = $client->status;
    my $status = $client->status( 1 );

Status accessor. Returns object status value. 0 - Error; 1 - Ok
You also can set new status value

=head2 trace

    my $trace = $client->trace;
    $client->trace("New trace record");

Gets trace stack or pushes new trace record to trace stack

=head2 transaction

    print $client->transaction;

Gets transaction string

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<WWW::MLite>, L<HTTP::Message>, L<LWP>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use Carp;
use Encode;
use Time::HiRes qw/gettimeofday/;

# CTK
use CTK::Util qw/lf_normalize/;
use CTK::TFVals qw/ :ALL /;
use CTK::ConfGenUtil;
use CTK::Serializer;

# LWP (libwww)
use URI;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Headers::Util;
use HTTP::Request::Common qw//;
use LWP::UserAgent;

use constant {
        HTTP_TIMEOUT        => 180,
        MAX_REDIRECT        => 10,
        TRANSACTION_MASK    => "%s%s >>> %s [%s in %s%s]", # GET /auth >>> 200 OK [1.04 KB in 0.0242 seconds (43.1 KB/sec)]
        CONTENT_TYPE        => "text/plain",
    };

sub new {
    my $class = shift;
    my %args  = @_;

    # Constants
    $args{status}   = 1; # 0 - error, 1 - ok
    $args{error}    = ""; # string
    $args{res_time} = 0;
    $args{trace_redirects} = [];
    $args{trace}    = [];
    $args{req}      = undef; # Request object
    $args{res}      = undef; # Response object

    # General
    $args{verbose} ||= 0; # Display content

    # TimeOut
    $args{timeout} ||= HTTP_TIMEOUT;

    # Other defaults
    $args{no_check_redirect} //= 0;

    # Serializer
    $args{format} ||= "";
    $args{format} = "none" if $args{format} =~ /auth?o/;
    my $sr_attrs = $args{sr_attrs};
    my $sr = is_hash($sr_attrs) ? CTK::Serializer->new($args{format}, attrs => $sr_attrs) : CTK::Serializer->new();
    croak(sprintf("Can't create serializer: %s", $sr->error)) unless $sr->status;
    $args{sr} = $sr;

    # Content-Type
    $args{content_type} ||= $sr->content_type || CONTENT_TYPE;

    # Initial URI & URL
    if ($args{uri}) {
        $args{url} = scalar($args{uri}->canonical->as_string);
    } else {
        if ($args{url}) {
            $args{uri} = new URI($args{url});
        } else {
            croak("Can't defined URL or URI");
        }
    }
    my $userinfo = $args{uri}->userinfo;

    # User Agent
    my $ua = $args{ua};
    unless ($ua) {
        my %uaopt = (
                agent                   => __PACKAGE__."/".$VERSION,
                max_redirect            => MAX_REDIRECT,
                timeout                 => $args{timeout},
                requests_redirectable   => ['GET','HEAD'],
                protocols_allowed       => ['http', 'https'],
            );
        my $ua_opts = $args{ua_opts} || {};
        for (keys %$ua_opts) {
            my $uas = node($ua_opts, $_);
            $uaopt{$_} = $uas if is_array($uas);
            $uaopt{$_} = value($uas) if is_value($uas);
            $uaopt{$_} = $uas if is_hash($uas) && $_ ne 'header';
        }
        $ua = new LWP::UserAgent(%uaopt);
        $args{ua} = $ua;
    }

    # Set Headers
    my $hdrs = $args{headers} || {'Cache-Control' => "no-cache"};
    $ua->default_header($_, value($hdrs, $_)) for (keys %$hdrs);

    # URL Replacement (Redirect)
    $args{redirect} = {};
    my @trace_redirects = ();
    my $turl = $args{url};
    unless ($args{no_check_redirect}) {
        my $tres = $args{ua}->head($args{url});
        my $dst_url;
        foreach my $r ($tres->redirects) { # Redirects detected!
            next unless $r->header('location');
            my $dst_uri = new URI($r->header('location'));
               $dst_uri->userinfo($userinfo) if $userinfo;
               $dst_url = $dst_uri->canonical->as_string;
            my $dst_url_wop = _hide_pasword($dst_uri)->canonical->as_string;
            my $src_uri = $r->request->uri;
               $src_uri->userinfo($userinfo) if $userinfo;
            my $src_url = _hide_pasword($src_uri)->canonical->as_string;
            push @trace_redirects, sprintf("Redirect (%s): %s ==> %s", $r->status_line, $src_url, $dst_url_wop);
        }
        if ($dst_url) {
            $args{redirect}->{$turl} = $dst_url; # Set SRC_URL -> DST_URL
            $args{url} = $dst_url;
            $args{uri} = new URI($dst_url);
        }
    }
    $args{trace_redirects} = [@trace_redirects];

    return bless {%args}, $class;
}
sub error {
    my $self = shift;
    my $e = shift;
    $self->{error} = $e if defined $e;
    return $self->{error};
}
sub status {
    my $self = shift;
    my $s = shift;
    $self->{status} = $s if defined $s;
    return $self->{status};
}
sub req {
    my $self = shift;
    return $self->{req};
}
sub res {
    my $self = shift;
    return $self->{res};
}
sub serializer {
    my $self = shift;
    return $self->{sr};
}
sub transaction {
    my $self = shift;
    my $res = $self->res;
    return 'NOOP' unless $res;
    my $length = $res->content_length || 0;
    my $rtime = $self->{res_time} // 0;
    return sprintf(TRANSACTION_MASK,
        $self->req->method, # Method
        sprintf(" %s", _hide_pasword($res->request->uri)->canonical->as_string), # URL
        $res->status_line // "ERROR", # Line
        _fbytes($length), # Length
        _fduration($rtime), # Duration
        $rtime ? sprintf(" (%s/sec)", _fbytes($length/$rtime)) : "",
      )
}
sub trace {
    my $self = shift;
    my $v = shift;
    if (defined($v)) {
        my $a = $self->{trace};
        push @$a, lf_normalize($v);
        return lf_normalize($v);
    }
    my $trace = $self->{trace} || [];
    return join("\n", @$trace);
}
sub cleanup {
    my $self = shift;
    my $status = shift || 0;
    $self->{status}     = $status;
    $self->{error}      = "";
    $self->{res_time}   = 0;
    $self->{req}        = undef;
    $self->{res}        = undef;
    my $trace = $self->{trace_redirects} || [];
    $self->{trace}      = [@$trace];
    return $self;
}
sub request {
    my $self = shift;
    my $method = shift || "GET";
    my $path = shift;
    my $data = shift // '';
    my $cb = shift;
    $self->cleanup;

    my $ua = $self->{ua}; # UserAgent
    my $sr = $self->{sr}; # Serializer
    my $start_time = gettimeofday()*1;
    my $cbmode = ($cb && ref($cb) eq 'CODE') ? 1 : 0;

    # URI
    my $uri = $self->{uri}->clone;
    $uri->path_query($path) if defined $path;
    my $query = $uri->query;
    $uri->query(undef);
    my $turl = $uri->canonical->as_string;
    $uri = URI->new($self->{redirect}->{$turl}) if $self->{redirect}->{$turl};
    $uri->query($query) if defined($query) && length($query);

    # Prepare Request
    my $req = new HTTP::Request(uc($method), $uri);
    my $req_content;
    if ($method =~ /PUT|POST|PATCH/) {
        $req->header('Content-Type', $self->{content_type});
        if (is_hash($data)) { # struct-data
            $req_content = $sr->serialize($data);
            unless ($sr->status) {
                $self->status(0);
                $self->error($sr->error);
                return;
            }
        } else {
            $req_content = $data;
        }
        if (ref($data) eq 'CODE') {
            my $size = $req->$data() || 0; # Call!
            $req->header('Content-Length', $size) if $size;
        } elsif (defined($req_content) && length($req_content)) {
            Encode::_utf8_on($req_content);
            $req->header('Content-Length' => length(Encode::encode("utf8", $req_content)));
            $req->content(Encode::encode("utf8", $req_content));
        } else {
            $req->header('Content-Length', 0);
        }
    }
    $self->{req} = $req;

    # Send Request
    my $res = $cbmode ? $ua->request($req, $cb) : $ua->request($req);
    $self->{res} = $res;
    $self->{res_time} = sprintf("%.*f",4, gettimeofday()*1 - $start_time) * 1;
    my ($stat, $line, $code);
    my $req_string = sprintf("%s %s", $method, _hide_pasword($res->request->uri)->canonical->as_string);
    $stat = ($res->is_info || $res->is_success || $res->is_redirect) ? 1 : 0;
    $self->status($stat);
    $code = $res->code;
    $line = $res->status_line;
    $self->error(sprintf("%s >>> %s", $req_string, $line)) unless $stat;

    # Tracing
    {
        # Request
        $self->trace($req_string);
        $self->trace($res->request->headers_as_string);
        $self->trace(
            sprintf("-----BEGIN REQUEST CONTENT-----\n%s\n-----END REQUEST CONTENT-----", $req->content)
        ) if ($self->{verbose} && defined($req->content) && length($req->content));

        # Response
        $self->trace($line);
        $self->trace($res->headers_as_string);
        $self->trace(
            sprintf("-----BEGIN RESPONSE CONTENT-----\n%s\n-----END RESPONSE CONTENT-----", $res->content)
        ) if ($self->{verbose} && defined($res->content) && length($res->content));
    }

    # Return
    return if $method eq "HEAD";

    # Response content
    my $content = $res->decoded_content // '';
    return unless length($content);
    return $content unless $self->{format};

    # DeSerialization
    my $structure = $sr->deserialize($content);
    unless ($sr->status) {
        if ($stat) {
            $self->status(0);
            $self->error($sr->error);
        }
        return $content;
    }
    return $structure;
}

sub _fduration {
    my $msecs = shift || 0;
    my $secs = int($msecs);
    my $hours = int($secs / (60*60));
    $secs -= $hours * 60*60;
    my $mins = int($secs / 60);
    $secs %= 60;
    if ($hours) {
        return sprintf("%d hours %d minutes", $hours, $mins);
    } elsif ($mins >= 2) {
        return sprintf("%d minutes", $mins);
    } elsif ($secs < 2*60) {
        return sprintf("%.4f seconds", $msecs);
    } else {
        $secs += $mins * 60;
        return sprintf("%d seconds", $secs);
    }
}
sub _fbytes {
    my $n = int(shift);
    if ($n >= 1024 ** 3) {
        return sprintf "%.3g GB", $n / (1024 ** 3);
    } elsif ($n >= 1024 * 1024) {
        return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KB", $n / 1024.0;
    } else {
        return "$n bytes";
    }
}
sub _hide_pasword {
    my $src = shift;
    my $uri_wop = $src->clone;
    my $info = $uri_wop->userinfo();
    if ($info) {
        $info =~ s/:.*//;
        $uri_wop->userinfo($info);
    }
    return $uri_wop;
}

1;

__END__
