# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::WrapperValve;

use base qw(Wombat::Valve::ValveBase);
use fields qw();
use strict;
use warnings;

use Servlet::Http::HttpServletResponse ();

# public methods

sub getName { return 'WrapperValve' }

sub invoke {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    # XXX: in order to cleanly support non-HTTP protocols, maybe
    # delegate to ErrorHandler and SuccessHandler classes that can be
    # subclassed for other protocols

    my $wrapper = $self->getContainer();
    my $parent = $wrapper->getParent();

    my $unavailable = ! $parent->getAvailable() ||
        $wrapper->isUnavailable();
    if ($unavailable) {
        if ($response->isa('Wombat::HttpResponse')) {
            my $status =
                Servlet::Http::HttpServletResponse::SC_SERVICE_UNAVAILABLE;
            $response->sendError($status);
        }

        $wrapper->handleError($request, $response);
        return 1;
    }

    my $servlet;
    eval {
        $servlet = $wrapper->allocate();
    };
    if ($@) {
        # the servlet could not be loaded, so consider it
        # unavailable, but also log the error
        if ($response->isa('Wombat::HttpResponse')) {
            $wrapper->unavailable();
            my $status =
                Servlet::Http::HttpServletResponse::SC_SERVICE_UNAVAILABLE;
            $response->sendError($status);
        }

        $wrapper->handleError($request, $response, $@);
        return 1;
    }

    # XXX: create filter chain

    # XXX: do filters

    eval {
        $servlet->service($request->getRequest(),
                          $response->getResponse());
    };
    if ($@) {
        if ($response->isa('Wombat::HttpResponse')) {
            my $status =
                Servlet::Http::HttpServletResponse::SC_INTERNAL_SERVER_ERROR;
            $response->sendError($status);
        }

        $wrapper->handleError($request, $response, $@);
        return 1;
    }

    # XXX: release filter chain

    eval {
        $wrapper->deallocate();
    };
    if ($@) {
        $self->log("problem deallocating wrapper", $@);
    }

    if ($response->isError()) {
        $wrapper->handleError($request, $response);
    } else {
        $wrapper->handleSuccess($request, $response);
    }

    return 1;
}

1;
__END__
