package Twiggy::Server::TLS;

use strict;
use warnings;

use base 'Twiggy::Server';

use IO::Socket::SSL;
use Twiggy::TLS::Info;
require Carp;

use constant DEBUG => $ENV{TWIGGY_DEBUG};

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    Carp::croak('missed required option "tls_key"')
      unless $self->{tls_key};

    Carp::croak('missed required option "tls_cert"')
      unless $self->{tls_cert};

    my %tls = (
        SSL_server => 1,

        SSL_version     => $self->{tls_version} || 'SSLv23:!SSLv2',
        SSL_cipher_list => $self->{tls_ciphers} || 'HIGH:!aNULL:!MD5',

        SSL_key_file  => $self->{tls_key},
        SSL_cert_file => $self->{tls_cert},
        SSL_ca_file   => $self->{tls_ca},

        SSL_verify_mode => SSL_VERIFY_NONE,
    );

    if (my $verify = $self->{tls_verify}) {
        if ($verify eq 'off') {
        }
        elsif ($verify eq 'on') {
            $tls{SSL_verify_mode} =
              SSL_VERIFY_PEER | SSL_VERIFY_FAIL_IF_NO_PEER_CERT;
        }
        elsif ($verify eq 'optional') {
            $tls{SSL_verify_mode} = SSL_VERIFY_PEER;
        }
        else {
            Carp::croak qq(Invalid tls_verify value "$verify");
        }
    }

    $self->{_tls_opts} = \%tls;

    $self->{_tls_context} = IO::Socket::SSL::SSL_Context->new(%tls)
      or Carp::croak(
        "TLS context initialization failed: " . IO::Socket::SSL::errstr);

    if (my $server_ready_orig = $self->{server_ready}) {
        $self->{server_ready} = sub {
            my $args = shift;
            $args->{proto} = 'https';
            $server_ready_orig->($args);
        };
    }

    $self;
}

sub _accept_handler {
    my $self = shift;

    my $super = $self->SUPER::_accept_handler(@_);

    return sub {
        my ($sock, $peer_host, $peer_port) = @_;

        DEBUG
          && warn "$sock TLS connection accepted $peer_host:$peer_port\n";
        return unless $sock;

        $self->{exit_guard}->begin;

        my $tls_guard;
        IO::Socket::SSL->start_SSL(
            $sock,
            SSL_server         => 1,
            SSL_startHandshake => 0,

            SSL_error_trap => sub {
                my ($sock, $error) = @_;

                $self->{exit_guard}->end;
                undef $tls_guard;
                $sock->close;
                DEBUG && warn "$sock TLS error: $error\n";
            },
            SSL_reuse_ctx => $self->{_tls_context},

            # This option is not inherited from context
            SSL_cipher_list => $self->{_tls_opts}->{SSL_cipher_list}
        );

        $self->_setup_tls(
            $sock,
            \$tls_guard,
            sub {
                $self->{exit_guard}->end;

                DEBUG && warn "$sock TLS connection established\n";
                $super->($sock, $peer_host, $peer_port);
            }
        );

      }
}

sub _run_app {
    my ($self, $app, $env, $sock) = @_;

    $env->{'psgi.url_scheme'} = 'https';
    $env->{'psgi.tls'}        = Twiggy::TLS::Info->new($sock);

    $self->SUPER::_run_app($app, $env, $sock);
}

sub _setup_tls {
    my ($self, $sock, $guard, $cb) = @_;

    return $cb->() if $sock->accept_SSL;

    my $error = $IO::Socket::SSL::SSL_ERROR;
    return unless $error == SSL_WANT_READ || $error == SSL_WANT_WRITE;

    $$guard = AE::io(
        $sock,
        $error == SSL_WANT_WRITE,
        sub {
            undef $$guard;
            $self->_setup_tls($sock, $guard, $cb);
        }
    );
}

1;
