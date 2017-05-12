# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::ServletException;

use base qw(Servlet::Util::Exception);
use strict;
use warnings;

__PACKAGE__->do_trace(1);

sub new {
    my $type = shift;
    my $msg = shift;
    my $root = shift;

    my $class = ref($type) || $type;
    my $error = $root && !$msg ?
        $root->getMessage() :
            $msg;
    my $self = $class->SUPER::new($error);

    $self->{root} = $root;

    return $self;
}

sub getRootCause {
    my $self = shift;

    return $self->{root};
}

1;
__END__

=pod

=head1 NAME

Servlet::ServletException - general servlet exception

=head1 SYNOPSIS

  package My::Servlet;

  use base qw(Servlet::GenericServlet);
  use Servlet::ServletException ();

  sub service {

      # ...

      eval {
          # ...
      };

      if ($@) {
          Servlet::ServletException->throw('something broke',
                                           root => $@);
      };

      # ...

  }

=head1 DESCRIPTION

Defines a general exception a servlet can throw when it encounters
difficulty.

=head1 METHODS

=over

=item new($msg, $root)

Constructs a new servlet exception. Optional arguments include an
error message and the "root cause" exception that was encountered by
the servlet.

B<Parameters:>

=over

=item I<$msg>

the error message

=item I<$root>

the exception that is the root cause of this exception

=back

=item getRootCause()

Returns the exception that caused this servlet exception.

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
