
package Tree::Binary::Visitor::Base;

use strict;
use warnings;

our $VERSION = '1.08';

### constructor

sub new {
    my ($_class) = @_;
    my $class = ref($_class) || $_class;
    my $visitor = {};
    bless($visitor, $class);
    $visitor->_init();
    return $visitor;
}

### methods

sub _init {
	my ($self) = @_;
    $self->{_filter_function} = undef;
    $self->{_results} = [];
}

# node filter methods

sub getNodeFilter {
    my ($self) = @_;
	return $self->{_filter_function};
}

sub clearNodeFilter {
    my ($self) = @_;
	$self->{_filter_function} = undef;
}

sub setNodeFilter {
    my ($self, $filter_function) = @_;
	(defined($filter_function) && ref($filter_function) eq "CODE")
		|| die "Insufficient Arguments : filter function argument must be a subroutine reference";
	$self->{_filter_function} = $filter_function;
}

# results methods

sub setResults {
    my ($self, @results) = @_;
    $self->{results} = \@results;
}

sub getResults {
    my ($self) = @_;
    return wantarray ?
             @{$self->{results}}
             :
             $self->{results};
}


# abstract method
sub visit { die "Method Not Implemented" }

1;

__END__

=head1 NAME

Tree::Binary::Visitor::Base - A Visitor base class for Tree::Binary::Visitor::* objects

=head1 SYNOPSIS

  package MyTreeBinaryVisitor;

  use strict;
  use warnings;

  use Tree::Binary::Visitor::Base;

  our @ISA = qw(Tree::Binary::Visitor::Base);

  sub visit {
      my ($self, $tree) = @_;
      # ... implement your visit method
  }

  1;

=head1 DESCRIPTION

This is a base class for Tree::Binary::Visitor objects. If you want to create your own visitor object, just subclass this and create a visit method.

=head1 METHODS

=over 4

=item B<new>

There are no arguments to the constructor the object will be in its default state. You can use the C<setNodeFilter> method to customize its behavior.

=item B<getNodeFilter>

This method returns the CODE reference set with C<setNodeFilter> argument.

=item B<clearNodeFilter>

This method clears node filter field.

=item B<setNodeFilter ($filter_function)>

This method accepts a CODE reference as its C<$filter_function> argument. This code reference is used to filter the tree nodes as they are collected. This can be used to customize output, or to gather specific information from a more complex tree node. The filter function should accept a single argument, which is the current Tree::Binary object.

=item B<getResults>

This method returns the accumulated results of the application of the node filter to the tree.

=item B<setResults>

This method should not really be used outside of this class, as it just would not make any sense to. It is included in this class and in this documenation to facilitate subclassing of this class for your own needs. If you desire to clear the results, then you can simply call C<setResults> with no argument.

=item B<visit ($tree)>

This is an abstract method and if called will throw an exception. This is the only method required when creating your own custom Tree::Binary::Visitor object.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 CODE COVERAGE

See the CODE COVERAGE section of Tree::Binary for details.

=head1 Repository

L<https://github.com/ronsavage/Tree-Binary>

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut