package Perlbal::Plugin::StickySessions;

use Perlbal;
use strict;
use warnings;
use Data::Dumper;
use HTTP::Date;
use CGI qw/:standard/;
use CGI::Cookie;
use Scalar::Util qw(blessed reftype);

# LOAD StickySessions
# SET plugins        = stickysessions
#
# Add 
#    my $svc = $self->{service};
#    if(ref($svc) && UNIVERSAL::can($svc,'can')) {
#      $svc->run_hook('modify_response_headers', $self);
#    }
# To sub handle_response in BackendHTTP after Content-Length is set.
#

sub load {
    my $class = shift;
    return 1;
}

sub unload {
    my $class = shift;
    return 1;
}

sub get_backend_id {
    my $be = shift;

    for ( my $i = 0 ; $i <= $#{ $be->{ service }->{ pool }->{ nodes } } ; $i++ )
    {
        my ( $nip, $nport ) = @{ $be->{ service }->{ pool }->{ nodes }[$i] };
        my $nipport = $nip . ':' . $nport;
        return $i + 1 if ( $nipport eq $be->{ ipport } );
    }

    # default to the first backend in the node list.
    return 1;
}

sub decode_server_id {
    my $id = shift;
    return ( $id - 1 );
}

sub get_ipport {
    my ( $svc, $req ) = @_;
    my $cookie  = $req->header('Cookie');
    my %cookies = ();
    my $ipport  = undef;

    %cookies = parse CGI::Cookie($cookie) if defined $cookie;
    if ( defined $cookie && defined $cookies{ 'X-SERVERID' } ) {
        my $val =
          $svc->{ pool }
          ->{ nodes }[ decode_server_id( $cookies{ 'X-SERVERID' }->value ) ];
        my ( $ip, $port ) = @{ $val } if defined $val;
        $ipport = $ip . ':' . $port;
    }
    return $ipport;
}

sub find_or_get_new_backend {
    my ( $svc, $req, $client ) = @_;

    my Perlbal::BackendHTTP $be;
    my $ipport = get_ipport( $svc, $req );

    my $now = time;
    while ( $be = shift @{ $svc->{ bored_backends } } ) {
        next if $be->{ closed };

        # now make sure that it's still in our pool, and if not, close it
        next unless $svc->verify_generation($be);

        # don't use connect-ahead connections when we haven't
        # verified we have their attention
        if ( !$be->{ has_attention } && $be->{ create_time } < $now - 5 ) {
            $be->close("too_old_bored");
            next;
        }

        # don't use keep-alive connections if we know the server's
        # just about to kill the connection for being idle
        if ( $be->{ disconnect_at } && $now + 2 > $be->{ disconnect_at } ) {
            $be->close("too_close_disconnect");
            next;
        }

        # give the backend this client
        if ( defined $ipport ) {
            if ( $be->{ ipport } eq $ipport ) {
                if ( $be->assign_client($client) ) {
                    $svc->spawn_backends;
                    return 1;
                }
            }
        } else {
            if ( $be->assign_client($client) ) {
                $svc->spawn_backends;
                return 1;
            }
        }

        # assign client can end up closing the connection, so check for that
        return 1 if $client->{ closed };
    }

    return 0;
}

# called when we're being added to a service
sub register {
    my ( $class, $gsvc ) = @_;

    my $check_cookie_hook = sub {
        my Perlbal::ClientProxy $client = shift;
        my Perlbal::HTTPHeaders $req    = $client->{ req_headers };
        return 0 unless defined $req;

        my $svc = $client->{ service };

        # we define were to send the client request
        $client->{ backend_requested } = 1;

        $client->state('wait_backend');

        return unless $client && !$client->{ closed };

        if ( find_or_get_new_backend( $svc, $req, $client ) != 1 ) {
            push @{ $svc->{ waiting_clients } }, $client;

            $svc->{ waiting_client_count }++;
            $svc->{ waiting_client_map }{ $client->{ fd } } = 1;

            my $ipport = get_ipport( $svc, $req );
            if ( defined($ipport) ) {
                my ( $ip, $port ) = split( /\:/, $ipport );
                $svc->{ spawn_lock } = 1;
                my $be =
                  Perlbal::BackendHTTP->new( $svc, $ip, $port,
                    { pool => $svc->{ pool } } );
                $svc->{ spawn_lock } = 0;
            } else {
                $svc->spawn_backends;
            }
            $client->tcp_cork(1);
        }

        return 0;
    };

    my $set_cookie_hook = sub {
        my Perlbal::BackendHTTP $be  = shift;
        my Perlbal::HTTPHeaders $hds = $be->{ res_headers };
        my Perlbal::HTTPHeaders $req = $be->{ req_headers };
        return 0 unless defined $be && defined $hds;

        my $svc = $be->{ service };

        my $cookie  = $req->header('Cookie');
        my %cookies = ();
        %cookies = parse CGI::Cookie($cookie) if defined $cookie;

        my $backend_id = get_backend_id($be);

        if ( !defined( $cookies{ 'X-SERVERID' } )
            || $cookies{ 'X-SERVERID' }->value != $backend_id )
        {
            my $backend_cookie =
              new CGI::Cookie( -name => 'X-SERVERID', -value => $backend_id );
            if ( defined $hds->header('set-cookie') ) {
                my $val = $hds->header('set-cookie');
                $hds->header( 'Set-Cookie',
                    $val .= "\r\nSet-Cookie: " . $backend_cookie->as_string );
            } else {
                $hds->header( 'Set-Cookie', $backend_cookie );
            }
        }

        return 0;
    };

    $gsvc->register_hook( 'StickySessions', 'start_proxy_request',
        $check_cookie_hook );
    $gsvc->register_hook( 'StickySessions', 'modify_response_headers',
        $set_cookie_hook );
    return 1;
}

# called when we're no longer active on a service
sub unregister {
    my ( $class, $svc ) = @_;
    $svc->unregister_hooks('StickySessions');
    $svc->unregister_setters('StickySessions');
    return 1;
}

1;

=head1 NAME

Perlbal::Plugin::StickySessions - session affinity for perlbal

=head1 SYNOPSIS

This plugin provides a Perlbal the ability to load balance with 
session affinity.

You *must* patch Perlbal for this plugin to work correctly.

Configuration as follows:

  LOAD StickySessions
  SET plugins        = stickysessions

=cut

