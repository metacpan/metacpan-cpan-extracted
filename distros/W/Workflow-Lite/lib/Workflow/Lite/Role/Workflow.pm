package Workflow::Lite::Role::Workflow;

use namespace::autoclean;
use Moose::Role;
use MooseX::ClassAttribute;


class_has _steps => ( is => 'ro', isa => 'HashRef', default => sub { { } } );

has _step    => ( is => 'rw', isa => 'Str',  default => 'START' );
has _flowing => ( is => 'rw', isa => 'Bool', default => 1 );


sub work {
  my ( $self, @args ) = @_;

  die q!Cannot work if workflow has ended.!
    unless $self->is_flowing;

  my ( $step, $steps ) = ( $self->_step, $self->_steps );
  die q!No handler defined for step '!, $step, q!'.!
    unless defined $steps->{$step};

  my $code = $steps->{$step};
  $self->$code( @args )
}

sub flow {
  my ( $self, $step ) = @_;

  my $steps = $self->_steps;
  die q!Destination step '!, $step, q!' does not exist.!
    unless exists $steps->{$step};

  $self->_step( $step )
}

sub end { $_[0]->_flowing( 0 ) }

sub is_flowing { $_[0]->_flowing }


1
__END__

=pod

=head1 NAME

Workflow::Lite::Role::Workflow - A role comprising the main functionality for workflows

=head1 SYNOPSIS

  package MyWorkflow;

  use namespace::autoclean;
  use Moose;

  with qw( Workflow::Lite::Role::Workflow );

  __PACKAGE__->_steps->{START} = sub {
    my ( $self, $text ) = @_;

    print 'This is the START step: ', $text, "\n";
    $self->flow( 'foo' );

    reverse $text
  };

  __PACKAGE__->_steps->{foo} = sub {
    my ( $self, $text ) = @_;

    print 'This is the foo step: ', $text, "\n";
    $self->flow( 'bar' );

    reverse $text
  };

  __PACKAGE__->_steps->{bar} = sub {
    my ( $self, $text ) = @_;

    print 'This is the bar step: ', $text, "\n";
    $self->end;

    reverse $text
  };

  1

  ...

  my $wf = MyWorkflow->new;

  my @words = qw( Bar Foo Start );

  while( $wf->is_flowing ) {
    my $rv = $wf->work( pop @words );
    print '  -> ', $rv, "\n";
  }

=head1 DESCRIPTION

Workflow::Lite::Role::Workflow is a role that implements the
functionality necessary for handling workflows.  This role is
applied automatically when C<use>ing L<Workflow::Lite|Workflow::Lite>.

=head1 CLASS ATTRIBUTES

=head2 _steps

A HashRef that contains the defined steps for the class.  Steps
are simply CodeRefs that get called when the named step is
executed in a call to C<work()>.

=head1 OBJECT ATTRIBUTES

=head2 _step

Contains the name of the step to be executed upon the next call
to C<work()>.  This defaults to C<'START'>, but can be overridden
if necessary.

=head2 _flowing

A boolean value that provides the flowing status of the workflow.

=head1 OBJECT METHODS

=head2 work( [@args] )

Runs the handler for the current step.  Any arguments provided
in C<@args> are passed to the handler.  Handlers are run as object
methods so C<$self> is passed as well. The return from the handler
is passed as-is back from C<work()>.  If the workflow is not
currently flowing or the current step does not have a handler,
an exception is thrown.

=head2 flow( $step )

Flows to the step named by C<$step>.  If C<$step> has not been
previously defined, an exception is thrown.

=head2 end()

Halts the workflow.  Further calls to C<work()> will result in
an exception being thrown.

=head2 is_flowing()

Returns true if the workflow is still flowing, false otherwise.

=head1 BUGS

None are known at this time, but if you find one, please feel free
to submit a report to the author.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Workflow::Lite>

=back

=head1 COPYRIGHT

Copyright (c) 2011-2014, jason hord

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
