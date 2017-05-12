
package Tree::Visualize::Factory;

use strict;
use warnings;

our $VERSION = '0.01';

use Tree::Visualize::Exceptions;

sub new {
    my ($_class, $product) = @_;
    my $class = ref($_class) || $_class;
    my $factory = {};
    bless($factory, $class);
    $factory->_init($product);
    return $factory;
}

sub _init {
    my ($self, $product) = @_;
    $self->{product} = $product;
}

sub get {
    my ($self, %path) = @_;
    (%path) || throw Tree::Visualize::InsufficientArguments;
    my $package_name = "Tree::Visualize::";
    $package_name .= $path{output};
    $package_name .= "::";    
    $package_name .= $self->{product};    
    $package_name .= "::";        
    $package_name .= $self->_resolvePackage(%path);   
    eval "use $package_name";     
    throw Tree::Visualize::OperationFailed ($@) if $@;
    my @args;
    @args = @{$path{args}} if exists $path{args};
    my $instance = eval { $package_name->new(@args) };
    throw Tree::Visualize::OperationFailed ($@) if $@;
    return $instance;
}

sub _resolvePackage { throw Tree::Visualize::MethodNotImplemented }

1;

__END__

=head1 NAME

Tree::Visualize::Factory - A Abstract Factory for creating certain components for Tree::Visualize

=head1 SYNOPSIS

  use Tree::Visualize::Factory;

=head1 DESCRIPTION

This module resolves and loads a class package, then creates an instance of it. However, this is an abstract base class, so it is required that the template method C<_resolvePackage> is implemented in order to load the class. There currently exists three implementation of this class:

=over 4

=item L<Tree::Visualize::Node::Factory>

=item L<Tree::Visualize::Layout::Factory>

=item L<Tree::Visualize::Connector::Factory>

=back

=head1 METHODS

=over 4

=item B<new ($product)>

=item B<get (%path)>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

See the B<CODE COVERAGE> section in L<Tree::Visualize> for more inforamtion.

=head1 SEE ALSO

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

