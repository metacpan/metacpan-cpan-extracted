# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::HttpResponseFacade;

=pod

=head1 NAME

Wombat::Connector::HttpResponseFacade - internal http response facade

=head1 SYNOPSIS

=head1 DESCRIPTION

Facade class that wraps an internal HttpResponse object. All methods are
delegated to the wrapped response. The facade is presented to servlet
code so that the servlet code does not have access to internal HttpResponse
methods.

=cut

use base qw(Servlet::Http::HttpServletResponse Wombat::Connector::ResponseFacade);
use strict;
use warnings;

sub addCookie {
    my $self = shift;

    return $self->{response}->addCookie(@_);
}

sub addDateHeader {
    my $self = shift;

    return $self->{response}->addDateHeader(@_);
}

sub addHeader {
    my $self = shift;

    return $self->{response}->addHeader(@_);
}

sub containsHeader {
    my $self = shift;

    return $self->{response}->containsHeader(@_);
}

sub encodeRedirectURL {
    my $self = shift;

    return $self->{response}->encodeRedirectURL(@_);
}

sub encodeURL {
    my $self = shift;

    return $self->{response}->encodeURL(@_);
}

sub sendError {
    my $self = shift;

    return $self->{response}->sendError(@_);
}

sub sendRedirect {
    my $self = shift;

    return $self->{response}->sendRedirect(@_);
}

sub setDateHeader {
    my $self = shift;

    return $self->{response}->setDateHeader(@_);
}

sub setHeader {
    my $self = shift;

    return $self->{response}->setHeader(@_);
}

sub setStatus {
    my $self = shift;

    return $self->{response}->setStatus(@_);
}

1;
__END__

=pod

=head1 SEE ALSO

L<Servlet::Http::HttpServletResponse>,
L<Wombat::Connector::ResponseFacade>,
L<Wombat::HttpResponse>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
