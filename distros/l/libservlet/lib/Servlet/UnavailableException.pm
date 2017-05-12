# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::UnavailableException;

use base qw(Servlet::ServletException);
use strict;
use warnings;

__PACKAGE__->do_trace(1);

sub new {
    my $type = shift;
    my $msg = shift;
    my $seconds = shift;

    my $class = ref($type) || $type;
    my $self = $class->SUPER::new($msg);

    if (defined $seconds) {
        $self->{seconds} = $seconds < 0 ? -1 : $seconds;
        $self->{permanent} = 0;
    } else {
        $self->{seconds} =  -1;
        $self->{permanent} = 1;
    }

    return $self;
}

sub isPermanent {
    my $self = shift;

    return $self->{permanent};
}

sub getUnavailableSeconds {
    my $self = shift;

    return $self->isPermanent() ? -1 : $self->{seconds};
}

1;
__END__

=pod

=head1 NAME

Servlet::UnavailableException - servlet unavailability exception

=head1 SYNOPSIS

  package My::Servlet;

  use base qw(Servlet::GenericServlet);
  use Servlet::UnavailableException ();

  sub service {

      # ...

      Servlet::UnavailableException->throw('db server inaccessible',
                                           seconds => 30);
  }

  package My::ServletContainer;

  # ...

  eval {
      $servlet->service($request, $response);
  };

  if ($@ && $@->isa('Servlet::UnavailableException')) {
      if ($@->isPermanent()) {
          $response->sendError(410) # SC_GONE;
          $servlet->destroy();
      } else {
          $response->sendError(503); # SC_SERVICE_UNAVAILABLE
      }
  };

  # ...

=head1 DESCRIPTION

Defines an exception that a servlet throws to indicate that it is
permanently or temporarily unavailable.

When a servlet is permanently unavailable, something is wrong with the
servlet, and it cannot handle requests until some action is taken. For
example, the servlet might be configured incorrectly, or its state may
be corrupted. A servlet should log both the error and the corrective
action that is needed.

A servlet is temporarily unavailable if it cannot handle requests
momentarily due to some system-wide problem. For example, a third-tier
server might not be accessible, or there may be insufficient memory or
disk storage to handle requests. A system administrator may need to
take corrective action.

Servlet containers can safely treat both types of unavailabile
exceptions in the same way. However, treating termporary
unavailability effectively makes the servlet container more
robust. Specifically, the servlet container might block requests to
the servlet for a period of time suggested by the servlet, rather than
rejecting them until the servlet container restarts.

Extends B<Servlet::ServletException>. See that class for a description
of inherited methods.

=head1 METHODS

=over

=item new($msg, $seconds)

Constructs a new exception. Optional arguments include an error
message, and an estimate of temporary unavailability in seconds. If
I<seconds> is not specified, the indication is that the servlet is
permanently unavailable.

B<Parameters:>

=over

=item I<$msg>

the error message

=item I<$seconds>

the number of seconds that the servlet will be unavailable

=back

=item getUnavailableSeconds()

Returns the number of seconds the servlet expects to be temporarily
unavailable, or -1 if the servlet is permanently unavailable.

=item isPermanent()

Returns a boolean value indicating whether the servlet is permanently
unavailable.

=back

=head1 SEE ALSO

L<Servlet::ServletException>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
