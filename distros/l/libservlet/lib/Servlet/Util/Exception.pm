# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Util::Exception;

use Exception::Class ();

use base qw(Exception::Class::Base);
use strict;
use warnings;

# for some reason, if i try to declare subclasses via
# Exception::Class::import(), things break. i can't figure out why,
# and it's not really important.

__PACKAGE__->do_trace(1);

sub new {
    my $type = shift;
    my $msg = shift;

    my $class = ref($type) || $type;
    my $self = $class->SUPER::new(error => $msg);

    return $self;
}

sub getMessage {
    my $self = shift;

    return $self->error();
}

sub toString {
    my $self = shift;

    return $self->to_string();
}

1;

package Servlet::Util::IOException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;
package Servlet::Util::IllegalArgumentException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;
package Servlet::Util::IllegalStateException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;
package Servlet::Util::IndexOutOfBoundsException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;
package Servlet::Util::UndefReferenceException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;
package Servlet::Util::UnsupportedEncodingException;

use base qw(Servlet::Util::Exception);

__PACKAGE__->do_trace(1);

1;
__END__

=pod

=head1 NAME

Servlet::Util::Exception - exception base class

=head1 SYNOPSIS

  eval {
      Servlet::Util::Exception->throw("oops");
  };

  if ($@) {
      warn "caught exception: $@\n";
  }

=head1 DESCRIPTION

This is a base class for exceptions. It extends
B<Exception::Class::Base>. See B<Exception::Class> for a full list of
inherited methods.

There is only one exception to the inherited API: tracing is on by
default. This means that a stack trace will be created when an
exception is thrown. By way of comparison to B<java.lang.Throwable>,
it's as if C<fillInStackTrace()> is automatically called inside
C<throw()>. To selectively disable tracing for a subclass, do the
following:

  My::Exception::do_trace(0);

=head1 CONSTRUCTOR

=over

=item new($msg)

Construct an instance with the given error message.

Exceptions are rarely directly constructed. Usually they are
constructed and thrown in one call to C<throw()>.

B<Parameters:>

=over

=item I<$msg>

the error message

=back

=back

=head1 CLASS METHODS

=over

=item throw($msg)

Constructs an instance with the given error essage and then C<die()>s.

B<Parameters:>

=over

=item I<$msg>

the error message

=back

=back

=head1 METHODS

=over

=item getMessage()

Returns the error message.

=item toString()

Returns a short description of the exception, including the stack
trace if the exception has been thrown.

=back

=head1 EXCEPTION SUBCLASSESS

These commonly encountered exceptions are provided as utilities.

=over

=item B<Servlet::Util::IOException>

Thrown to indicate than an I/O exception of some sort has occurred.

=item B<Servlet::Util::IllegalArgumentException>

Thrown to indicate that a method has been passed an illegal or
inappropriate argument.

=item B<Servlet::Util::IllegalStateException>

Thrown to indicate that a method has been invoked at an illegal or
inappropriate time.

=item B<Servlet::Util::IndexOutOfBoundsException>

Thrown to indicate that an index of some sort (such as to an array) is
out of range.

=item B<Servlet::Util::UndefReferenceException>

Thrown to indicate that I<undef> was used in a case where a value is
required.

=item B<Servlet::Util::UnsupportedEncodingException>

Thrown to indicate that the chosen character encoding is unsupported
by the environment (most commonly encountered during character
conversions on byte streams).

=back

=head1 SEE ALSO

L<Exception::Class>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
