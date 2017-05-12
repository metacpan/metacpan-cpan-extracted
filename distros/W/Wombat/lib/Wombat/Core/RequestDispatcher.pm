# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Core::RequestDispatcher;

=pod

=head1 NAME

Wombat::Core::RequestDispatcher - request dispatcher implementation

=head1 SYNOPSIS

=head1 DESCRIPTION

Implementation of B<Servlet::RequestDispatcher> that allows a request
to be forwardd to a different resource to create a response, or to
include the output of another resource in the response from this
resource.

=cut

use base qw(Servlet::RequestDispatcher);
use fields qw(application wrapper);
use strict;
use warnings;

=pod

=head1 CONSTRUCTOR

=over

=item new($wrapper)

Construct and return an instance, initializing fields appropriately.

B<Parameters:>

=over

=item $wrapper

the B<Wombat::Core::Wrapper> associated with the resource being
dispatched to

=back

=back

=cut

sub new {
    my $self = shift;
    my $wrapper = shift;

    $self = fields::new($self) unless ref $self;

    $self->{wrapper} = $wrapper;
    $self->{application} = $wrapper->getParent();

    return $self;
}

=pod

=head1 PUBLIC METHODS

=over

=item forward($request, $response)

Forward the specified Request and Response to another resource for
processing. Any exception thrown by the called servlet will be
propagated to the caller.

B<Parameters:>

=over

=item $request

the B<Servlet::ServletRequest> to be forwarded

=item $response

the B<Servlet::ServletResponse> to be forwarded

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if a servlet exception occurs

=item B<Servlet::Util::IllegalStateException>

if the response has already been committed

=item B<Servlet::Util::IOException>

if an input or output exception occurs

=back

=cut

sub forward {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    if ($response->isCommitted()) {
        my $msg = 'forward: response already committed';
        Servlet::Util::IllegalStateException->throw($msg);
    }

    # reset any output that has been buffered, but keep headers and
    # cookies
    $response->resetBuffer();

    $self->invoke($request, $response);

    # commit and close the response
    $response->flushBuffer();

    return 1;
}

=pod

=item include($request, $response)

Include the Response from another resource in the current
Response. Any exception thrown by the called servlet will be
propagated to the caller.

B<Parameters:>

=over

=item $request

the B<Servlet::ServletRequest> to be included

=item $response

the B<Servlet::ServletResponse> to be included

=back

B<Throws:>

=over

=item B<Servlet::ServletException>

if a servlet exception occurs

=item B<Servlet::Util::IOException>

if an input or output exception occurs

=back

=cut

sub include {
    my $self = shift;
    my $request = shift;
    my $response = shift;

    $self->invoke($request, $response, 1);

    return 1;
}

sub invoke {
    my $self = shift;
    my $request = shift;
    my $response = shift;
    my $included = shift;

    my $wreq;
    if ($request->isa('Wombat::HttpRequest')) {
        $wreq = Wombat::Connector::HttpRequestBase->new($request);
    } else {
        $wreq = Wombat::Connector::RequestBase->new($request);
    }

    my $wres;
    if ($response->isa('Wombat::HttpRequest')) {
        $wres = Wombat::Connector::HttpResponseBase->new($response);
    } else {
        $wres = Wombat::Connector::ResponseBase->new($response);
    }

    $wreq->setApplication($self->{application});
    $wreq->setWrapper($self->{wrapper});
    $wreq->setResponse($wres);

    $wres->setApplication($self->{application});
    $wres->setIncluded($included);
    $wres->setRequest($wreq);

    $self->{wrapper}->invoke($wreq, $wres);

    return 1;
}

1;
__END__

=pod

=back

=head1 SEE ALSO

L<Servlet::RequestDispatcher>,
L<Servlet::ServletRequestWrapper>,
L<Servlet::ServletResponseWrapper>,
L<Wombat::Core::Application>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
