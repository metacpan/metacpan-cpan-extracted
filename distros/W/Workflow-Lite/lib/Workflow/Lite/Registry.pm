package Workflow::Lite::Registry;

use namespace::autoclean;
use Class::Load;
use Moose;
use MooseX::ClassAttribute;

# FIXME: should dups be allowed?
# FIXME: add ->add_workflow_class() and ->remove_workflow_class()?


class_has _registry => ( is => 'ro', isa => 'HashRef', default => sub { { } } );


sub register {
  my ( $class, @pairs ) = @_;

  while( my ( $id, $workflow_class ) = splice @pairs, 0, 2 ) {
    Class::Load::load_class( $workflow_class );
    $class->_registry->{$id} = $workflow_class;
  }
}

sub workflow_class {
  my ( $class, $id ) = @_;

  my $workflow_class = $class->_registry->{$id};
  die q!No class registered for '!, $id, q!'.!, "\n"
    unless defined $workflow_class;

  $workflow_class
}

sub new_workflow {
  my ( $class, $id, @args ) = @_;

  my $workflow_class = $class->workflow_class( $id );
  $workflow_class->new( @args )
}


__PACKAGE__->meta->make_immutable;

1
__END__

=pod

=head1 NAME

Workflow::Lite::Registry - A workflow registry

=head1 SYNOPSIS

  package MyRegistry;

  use namespace::autoclean;
  use Moose;

  extends qw( Workflow::Lite::Registry );

  __PACKAGE__->register(
    Even => 'MyApp::Workflow::Even',
    Odd  => 'MyApp::Workflow::Odd',
  );

  1

  ...

  use MyRegistry;

  my $wf_name = time % 2 == 0 ? 'Even' : 'Odd';
  my @args    = ( foo => 'Foo', bar => 'Bar' );
  my $wf      = MyRegistry->new_workflow( $wf_name => @args );

=head1 DESCRIPTION

Workflow::Lite::Registry is meant to be used as a base class
to application-specific workflow registries that can be used
to shorten class names.  L<Workflow::Lite|Workflow::Lite> classes
are registered and given a short, unique name that can be referenced
at a later time.  This is probably most advantageous when there are
many different workflow classes being used or if workflows need to
be used based on configuration or user input.

=head1 CLASS ATTRIBUTES

=head2 _registry

A HashRef that contains the workflow registry.

=head1 CLASS METHODS

=head2 register( $id, $workflow_class )

Registers a new workflow class into the registry under the given id.
The workflow class is also loaded for convenience.

=head2 workflow_class( $id )

Returns the workflow class that is associated with the given id in
the registry.

=head2 new_workflow( $id, @args )

Instantiates a new workflow object by looking up the workflow class
associated with the given id and then calling C<new()> with the 
given arguments.

=back

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
