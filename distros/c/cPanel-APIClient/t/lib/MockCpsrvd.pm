package MockCpsrvd;

# Copyright 2020 cPanel, L. L. C.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;
use autodie;

use Test::More;
use Socket;

use HTTP::Request          ();
use HTTP::Response         ();
use IO::Socket::SSL        ();
use IO::Socket::SSL::Utils ();

my $example_com_crt = <<END;
-----BEGIN CERTIFICATE-----
MIIDNTCCAh2gAwIBAgIJAKNLmRsAWAk5MA0GCSqGSIb3DQEBCwUAMBYxFDASBgNV
BAMMC2V4YW1wbGUuY29tMB4XDTIwMDMxNjEwNTcwN1oXDTIwMDQxNTEwNTcwN1ow
FjEUMBIGA1UEAwwLZXhhbXBsZS5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAw
ggEKAoIBAQDiujckiiMG9TDOMjtHMprRgZWD/PgH6nPKzJy3HTgTDVcsapboBbTy
wdxS4gID+KKIJBsYFEkWXuQXSUBtOAe4+KjAC0nsQaGye6ABeUPkikN8qfQpPlXB
M5rrJTrrHo4HwQbRmAEWY51rdQGA1bwCL+URxVTPJ7Z+IFdvrlNiqj6dTT+tC/IP
2fpfYDiNqB/Go4P3e6n4WST3zqL/31/+krYnl5jhgdlfOK/i0NaOv3f1p+xwN8Wr
c6fTTA/BVy6av1Hhhr07FarPr+R20eX9tHKBAC0nR2PPb4cDxEKr5coZE2901QmE
jAOZKmzJN7l7AS5R8D2QJ+MZfsiTjTYpAgMBAAGjgYUwgYIwHQYDVR0OBBYEFLRR
xey06W3lCbDy7q3sb5rPyNYNMB8GA1UdIwQYMBaAFLRRxey06W3lCbDy7q3sb5rP
yNYNMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAJBgNVHRMEAjAAMBYG
A1UdEQQPMA2CC2V4YW1wbGUuY29tMA0GCSqGSIb3DQEBCwUAA4IBAQANW8K3yvQP
ef+NsM+ccOMfAp05SeyaQTX0XPQ0RsLYiy1R/2bCI4hGOxyS6fqrkUDGeymojIL1
rjmru6Yc5UXcYYY6poHadzfgh3yJ/ZAebPRhQPC2xd043rBei45wVnoD2rHqsyr2
DG4z8yHfi0ApRhlhq9yvCABuQfhrp4CVYm5RSqsya7bAqE0PzBcrYfY55LMtMJYU
tfcrqiNvuIe6LryVltFebA9+cJd/dQx8jhOfzjtab391EwDyOPV6TFZIuDszgHsk
XygPxE7mcI+o2AJbv2DwvodS1OfuVOZGhA9Blirk0HMENJiqVPNPe4GVT4BIRgIt
HWmwv22tVmWF
-----END CERTIFICATE-----
END

my $example_com_key = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA4ro3JIojBvUwzjI7RzKa0YGVg/z4B+pzysyctx04Ew1XLGqW
6AW08sHcUuICA/iiiCQbGBRJFl7kF0lAbTgHuPiowAtJ7EGhsnugAXlD5IpDfKn0
KT5VwTOa6yU66x6OB8EG0ZgBFmOda3UBgNW8Ai/lEcVUzye2fiBXb65TYqo+nU0/
rQvyD9n6X2A4jagfxqOD93up+Fkk986i/99f/pK2J5eY4YHZXziv4tDWjr939afs
cDfFq3On00wPwVcumr9R4Ya9OxWqz6/kdtHl/bRygQAtJ0djz2+HA8RCq+XKGRNv
dNUJhIwDmSpsyTe5ewEuUfA9kCfjGX7Ik402KQIDAQABAoIBAE8pOUuWt3gcb7fu
refD8W4o0m1NC8SnxVoPasA8gXGVfNRTOvEz3OPNcAG4S3/bddQW1ybnHkWjR/wh
ZU88+uVIXJMA3gSRPcW1iD47esr2w21pYYhs7UARpotnalThTDHE4X6YlfidOz9j
kOzMs2IIGvDDd0ME2KDc5epmcVLG+blZtrqTd/rX31eJVrIDMFqWVSz7emsyNAkE
XQjMpe5km0DyL7p+CHhCN0qB9BSR/rVsP64eo1XJC0TDQDgOx8NWCIW85MqT1Q2n
26gptE7etuBjSKTef2pBaiM/2SXG7Q9OF7LQp7VbmFvaA2p0RAQcsLsVgXMIp5NM
iVxFL4kCgYEA/RO0jFYWKtJPHyr4UQW/ffnjpGJhrt9U99JDwk0qFrBegKFnd+VP
4Yq1yLwquGBnwNO0r7nUZNF6Gpx5gghA7ToIw4eDIiNtFXUxlSR3RedalADZEb4Q
o8IC1jP+nMn33MlMBE6PfFTKD7vG5B69FcSw0hVAFxJ0mTtpG0gAfDsCgYEA5ViZ
nfe6Hlhqz+8Zz40rFWrZKRgajARyNMNahflfwiUSSqEicyQX+qsnR5T95Bw9aN56
D4Jtp6SxsQotXY5Q2/hPfs2XR4C6SWTSHUoawooWxHFnyJjRBvmRbVdvljOOFSj9
Mswjd67y3nUdMWVGUecKSuu686t60/LCL5oaxOsCgYA4YBZdGKQxf83eTI0qR1SD
9JGQQdYuxVNBLVaoxtW0Xi9/CfVpkOx9eo/KGpiNn/Qc0UwzxPqaRsujd+3dWIdW
ERJ4tAwzI58eI5AbABeNu97Cj3nLaQJ96C8HlmeGd7s+NJ05bGKsOJsWbCb/FBXc
7obRFajEOvk8VS6xxBVPlwKBgG6XRKwJsrPDSu4ti7KrjeTr+v934gU2d6O9t772
uxgxLBrUjHodI3r6YRyBWdRPUcVp0k38RMgcAJswHyQH5jHMEPlCRfpytmGBvlfl
TfYVBFmBndv65ICKg3fIO8Sf45mMhFukWE30DKT8sDELdtczo6Dw/ttVCwt8+epe
Ux41AoGBAJGaPrnpou2cmvIqts2Tk64WpWb2eIcJxHFdHzvROHUzpUIWKUHbColY
XJpgVyV5TQlG5mcJBMHOzyQI8kAaX0rQjgnDBMRmkhzLIhtRkuuqMg9H5XXFEpvB
Mrr8RzxD0PoQlQ76jizWZtl3Mtyf6d/rk8D4ou7Cx5mpJcqRdZqI
-----END RSA PRIVATE KEY-----
END

sub new {
    my ($class) = @_;

    my $s = IO::Socket::SSL->new(
        Listen    => 10,
        LocalAddr => "0.0.0.0:0",
        SSL_cert  => IO::Socket::SSL::Utils::PEM_string2cert($example_com_crt),
        SSL_key   => IO::Socket::SSL::Utils::PEM_string2key($example_com_key),
    ) or die;

    my $name = getsockname($s);
    my ($port) = Socket::unpack_sockaddr_in($name);

    my $pid = fork or do {
        listen $s, 10;

        diag "PID $$ listening on port $port …$/";

        my $ok = eval {
            $class->_serve_socket($s);
            1;
        };

        warn "Server child PID $$: $@" if !$ok;
        exit( !$ok ? 1 : 0 );
    };

    my %self = (
        port => $port,
        pid  => $pid,
    );

    return bless \%self, $class;
}

sub get_port {
    my ($self) = @_;

    return $self->{'port'};
}

sub wait {
    my ($self) = @_;

    local $?;
    return waitpid $self->{'pid'}, 0;
}

sub terminate {
    my ($self) = @_;

    kill 'KILL', $self->{'pid'};

    return $self->wait();
}

sub _serve_socket {
    my ( $class, $socket ) = @_;

    local $SIG{'CHLD'} = 'IGNORE';

    while (1) {
        my $peer = $socket->accept() or do {
            my $err = $IO::Socket::SSL::SSL_ERROR || "$!";

            warn "accept() failed: ($err)$/";

            next;
        };

        if (my $cpid = fork) {
            diag "Forked handler PID $cpid";
            next;
        }

        my $ok = eval {
            my $we_are_done;

            while ( !$we_are_done ) {
                my $hdr = do { local $/ = "\x0d\x0a\x0d\x0a"; <$peer> };

                diag "Handler PID $$ socket is done." if !$hdr;
                last if !$hdr;

                my $req = HTTP::Request->parse($hdr);

                diag "Got request: " . $req->uri()->as_string();

                if ( $req->uri()->as_string() =~ m<noanswer> ) {
                    diag "Handler PID $$ self-terminating per request";
                    kill 'TERM', $$;
                }

                my $resp_obj;

                my $content_length = $req->header('content-length');

                my $body;

                if (defined $content_length) {
                    diag "Expecting $content_length content bytes …";

                    $body = q<>;
                    while ($content_length) {
                        my $got = read( $peer, $body, $content_length, length $body );
                        if ( !$got ) {
                            diag "Empty read; client promised more data than sent.";
                            last;
                        }

                        diag "Got $got content bytes …";
                        $content_length -= $got;
                    }
                }
                else {
                    diag "No Content-Length sent in request; assuming empty payload …";

                    $body        = q<>;
                    $we_are_done = 1;
                }

                $req = HTTP::Request->parse( $hdr . $body );

                my $uri_str = $req->uri()->as_string();

                if ( $uri_str =~ m<forbidden> ) {
                    $resp_obj = HTTP::Response->new(
                        403 => 'Forbidden',
                        undef,
                        'Go away.',
                    );
                }
                elsif ( $uri_str =~ m<\A/login> ) {
                    $resp_obj = $class->_get_login_response($req);
                }
                else {
                    $resp_obj = $class->_get_response($req);
                }

                $resp_obj->header( Connection     => 'close' );
                $resp_obj->header( 'X-TestServer' => $class );

                # Ideally we’d use unbuffered I/O, but since we already used
                # buffered I/O to read we might as well use buffered to write.
                print {$peer} 'HTTP/1.1 ' . $resp_obj->as_string("\x0d\x0a");

                # This has to come after the write, or else TLS might get
                # get confused. (OpenSSL’s write logic might try to read!)
                #
                shutdown $peer, Socket::SHUT_RD;
                1 while read $peer, my $buf, 65536;

                # NB: we can no longer manually close() the peer socket
                # because it’ll fail its TLS shutdown.

                diag "Handler PID $$ sent response";
            }

            1;
        };

        warn "Server grandchild PID $$: $@" if !$ok;

        diag "Handler PID $$ exit (ok? $ok)";

        exit( !$ok ? 1 : 0 );
    }

    return;
}

sub _get_login_response {
    my ( $class, $req ) = @_;

    my $content_uri = URI::Escape::uri_escape( $req->content() );

    my $resp = HTTP::Response->new(
        200, 'OK',
        [
            'Location'   => '/cpses123123123/wherever',
            'Set-Cookie' => 'cpsession=johnny%3a3KCfM88PHoZ4MoUf%2ce95011e2b6a51118250861a505638a8c; HttpOnly; path=/; secure',
            'Set-Cookie' => "login=$content_uri; HttpOnly; path=/; secure",
        ],
        q<>,
    );

    return $resp;
}

1;
