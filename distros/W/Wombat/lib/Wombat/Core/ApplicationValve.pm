# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::ApplicationValve;

use base qw(Wombat::Valve::ValveBase);
use fields qw();
use strict;
use warnings;

use Servlet::Util::Exception ();
use Wombat::Globals ();

# public methods

sub getName { return 'ApplicationValve' }

sub invoke {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    my $freq = $request->getRequest();

    my $application = $self->getContainer();

    # disallow direct access to resources under WEB-INF or META-INF
    my $contextPath = $freq->getContextPath();
    my $requestURI = $freq->getRequestURI();

    my $relativeURI = uc $requestURI;
    $relativeURI =~ s|^$contextPath||;
    if ($relativeURI =~ m|^/META-INF| ||
        $relativeURI =~ m|^/WEB-INF|) {
        my $status = Servlet::Http::HttpServletResponse::SC_NOT_FOUND;
        $response->getResponse()->sendError($status);

        $application->handleError($request, $response);
        return 1;
    }

    # set up the session for the request
    my $session;
    my $manager = $application->getSessionManager();
    if ($manager) {
        # sessions are supported
        my $id = $request->getRequestedSessionId();
        if ($id) {
            # request contained a session id
            eval {
                $session = $manager->getSession($id);
            };
            if ($@) {
                my $msg = "invoke: problem getting session [id $id]";
                $self->log($msg, $@, 'ERROR');
            }

            if ($session) {
                # the session has already been created; check validity.
                my $interval = $session->getMaxInactiveInterval();
                my $lastAccessed = $session->getLastAccessedTime();
                if (time - $lastAccessed >= $interval) {
                    $session->expire();
                    $session->recycle();
                    undef $session;
                    $self->log("expired session [id $id]", $@, 'DEBUG');
                } else {
                    # update the session's last accessed time
                    $session->access();

#                    Wombat::Globals::DEBUG &&
#                     $self->log("got session " . $session->getId(),
#                                undef, 'DEBUG');
                }
            }
        }

        unless ($session) {
            # either no session was requested, or the session doesn't
            # exist or is invalid; create a new one.
            eval {
                $session = $manager->createSession();
            };
            if ($@) {
                my $msg = "invoke: problem creating session";
                $self->log($msg, $@, 'ERROR');
            }

#            Wombat::Globals::DEBUG &&
#                $self->log("created session " . $session->getId(),
#                           undef, 'DEBUG');
        }

        # set the session in the request so that it doesn't have to be
        # fetched from the session cache again in this request
        $request->setSession($session);
    }

    my $wrapper = $application->map($request);
    unless ($wrapper) {
        my $status = Servlet::Http::HttpServletResponse::SC_NOT_FOUND;
        $response->getResponse()->sendError($status);

        $application->handleError($request, $response);
        return 1;
    }

    $response->setApplication($application);

    $wrapper->invoke($request, $response);

    if ($session) {
        if ($session->isNew()) {
            # allow $session->access() to work next time around
            $response->flushBuffer() unless $response->isCommitted();
            $session->setNew(undef) if $session->isNew();
        }

        # write the updated session state, if any, to the session
        # cache
        $manager->save($session) if $manager;
    }

    return 1;
}

1;
__END__
