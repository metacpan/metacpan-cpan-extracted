# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::HostValve;

use base qw(Wombat::Valve::ValveBase);
use fields qw();
use strict;
use warnings;

use Servlet::Util::Exception ();

# public methods

sub getName { return 'HostValve' }

sub invoke {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $host = $self->getContainer();
    my $application = $host->map($request);
    unless ($application) {
        my $status = Servlet::Http::HttpServletResponse::SC_NOT_FOUND;
        $response->getResponse()->sendError($status);

        $host->handleError($request, $response);
        return 1;
    }

    $application->invoke($request, $response);

    return 1;
}

1;
__END__
