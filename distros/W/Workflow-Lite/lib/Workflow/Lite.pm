package Workflow::Lite;

use namespace::autoclean;
use Moose qw();
use Moose::Exporter;
use Workflow::Lite::Role::Workflow;


our $VERSION = '0.08';


Moose::Exporter->setup_import_methods(
  with_caller => [qw( steps step )],
  also        => [qw( Moose )],
);


sub init_meta {
  my ( $class, %args ) = @_;

  Moose->init_meta( %args );

  my $meta = $args{for_class}->meta;
  Workflow::Lite::Role::Workflow->meta->apply( $meta );

  $meta
}

sub steps {
  my ( $class, @args ) = @_;

  my $args = @args == 1 ? $args[0] : { @args };
  step( $class, $_, $args->{$_} )
    for keys %$args;
}

sub step { $_[0]->_steps->{$_[1]} = $_[2] }


1
__END__

=pod

=head1 NAME

Workflow::Lite - A very simplistic workflow framework

=head1 SYNOPSIS

  package MyWorkflow;

  use namespace::clean;
  use Workflow::Lite;

  steps
    START => sub {
      my ( $self, $text ) = @_;

      print 'This is the START step: ', $text, "\n";
      $self->flow( 'foo' );

      reverse $text
    },

    foo => sub {
      my ( $self, $text ) = @_;

      print 'This is the foo step: ', $text, "\n";
      $self->flow( 'bar' );

      reverse $text
    },
  ;

  step bar => sub {
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

Workflow::Lite is a very simple framework for defining and
implementing workflows.  This module is actually just a wrapper
that provides helpers for implementing a workflow object.

Workflows are simply collections of steps that are able to
flow to each other as necessary.  They are implemented as
L<Moose|Moose> objects so that attributes can be defined
to preserve stateful information between steps.  The
main functionality for workflows is implemented as a
L<Moose|Moose> role which is installed automatically when
C<use>ing C<Workflow::Lite>.  This module also exports
L<Moose|Moose> for convenience.

Steps are simply named CodeRefs that perform the actions
necessary when a workflow needs to execute a particular step.
This module provides helpers to make it easy to define
workflow steps.  Steps are purposely not implemented as
object methods to keep from cluttering up the class's
method namespace.

When a workflow object is instantiated, it's initialized to
work from the start step (the default is named 'START'). Calls
to the C<work()> method will execute step handlers which may
call the C<flow()> method to move to another step.  The C<end()>
method is used to terminate a workflow.  Subsequent calls to
C<work()> will result in an exception being thrown if a workflow
has ended.  The C<is_flowing()> method can be used to check if
a workflow is still active or not.

Arguments can be passed to individual step handlers by simply
passing them to the C<work()> method.  The return from a step
handler is passed through C<work()> to the caller as-is.

=head1 EXPORTED FUNCTIONS

=head2 step $name =E<gt> $code

Used to define a step named C<$name> with the handler C<$code>.

=head2 steps $name =E<gt> $code, [...]

Same as above, but allows multiple steps to be defined at once.

=head1 BUGS

None are known at this time, but if you find one, please feel free
to submit a report to the author.

=head1 AUTHOR

jason hord E<lt>pravus@cpan.orgE<gt>

=head1 SEE ALSO

=over 4

=item L<Workflow::Lite::Registry>

=item L<Workflow::Lite::Role::Workflow>

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
