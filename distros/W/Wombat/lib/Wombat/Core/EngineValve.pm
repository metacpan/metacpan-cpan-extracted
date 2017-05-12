# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::EngineValve;

use base qw(Wombat::Valve::ValveBase);
use fields qw();
use strict;
use warnings;

use Servlet::Util::Exception ();

# public methods

sub getName { return 'EngineValve' }

sub invoke {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $engine = $self->getContainer();
    my $host = $engine->map($request);
    unless ($host) {
        my $status =
            Servlet::Http::HttpServletResponse::SC_INTERNAL_SERVER_ERROR;
        $response->getResponse()->sendError($status);

        my $msg = sprintf("no host mapped for %s",
                          $request->getRequest()->getServerName());
        my $e = Servlet::Util::Exception->new($msg);

        $engine->handleError($request, $response, $e);
        return 1;
    }

    $host->invoke($request, $response);

    return 1;
}

1;
__END__
