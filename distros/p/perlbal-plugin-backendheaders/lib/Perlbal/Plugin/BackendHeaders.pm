package Perlbal::Plugin::BackendHeaders;

use Perlbal;
use strict;
use warnings;

#
# Add 
#    my $svc = $self->{service};
#    if(ref($svc) && UNIVERSAL::can($svc,'can')) {
#      $svc->run_hook('modify_response_headers', $self);
#    }
# To sub handle_response in BackendHTTP after Content-Length is set.
#
# LOAD BackendHeaders
# SET plugins        = backendheaders

sub load {
    my $class = shift;
    return 1;
}

sub unload {
    my $class = shift;
    return 1;
}

# called when we're being added to a service
sub register {
    my ( $class, $svc ) = @_;

    my $modify_response_headers_hook = sub {
        my Perlbal::BackendHTTP $be  = shift;
        my Perlbal::HTTPHeaders $hds = $be->{res_headers};
        my Perlbal::Service $svc     = $be->{service};
        return 0 unless defined $hds && defined $svc;

        $hds->header( 'X-Backend', $be->{ipport} );

        return 0;
    };

    $svc->register_hook( 'BackendHeaders', 'modify_response_headers',
        $modify_response_headers_hook );
    return 1;
}

# called when we're no longer active on a service
sub unregister {
    my ( $class, $svc ) = @_;
    $svc->unregister_hooks('BackendHeaders');
    $svc->unregister_setters('BackendHeaders');
    return 1;
}

1;

=head1 NAME

Perlbal::Plugin::BackendHeaders - See which backend served the request

=head1 SYNOPSIS

This plugin provides Perlbal with the ability to show which backend served
the request in the response HTTP header.

You *must* patch Perlbal for this plugin to work correctly.

Configuration as follows:

  LOAD BackendHeaders
  SET plugins       = backendheaders

=cut

