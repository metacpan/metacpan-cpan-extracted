
package Tree::Binary::VisitorFactory;

use strict;
use warnings;

our $VERSION = '1.08';

sub new {
    my ($class) = @_;
    return bless \$class;
}

sub get {
    my ($class, $visitor) = @_;
    (defined($visitor)) || die "Insufficient Arguments : You must specify a Visitor to load";
    $visitor = "Tree::Binary::Visitor::$visitor";
    eval "require $visitor";
    die "Illegal Operation : Could not load Visitor ($visitor) because $@" if $@;
    return $visitor->new();
}

*getVisitor = \&get;

1;

__END__

=head1 NAME

Tree::Binary::VisitorFactory - A factory object for dispensing Visitor objects

=head1 SYNOPSIS

  use Tree::Binary::VisitorFactory;

  my $tf = Tree::Binary::VisitorFactory->new();

  my $visitor = $tf->get('InOrderTraveral');

  # Or call it as a class method:

  my $visitor = Tree::Binary::VisitorFactory->getVisitor('PostOrderTraveral');

=head1 DESCRIPTION

This object is really just a factory for dispensing Tree::Binary::Visitor::* objects. It is not required to use this package in order to use all the Visitors, it is just a somewhat convienient way to avoid having to type thier long class names.

I considered making this a Singleton, but I did not because I thought that some people might not want that. I know that I am very picky about using Singletons, especially in multiprocess environments like mod_perl, so I implemented the smallest instance I knew how to, and made sure all other methods could be called as class methods too.

=head1 METHODS

=over 4

=item B<new>

Returns an minimal instance of this object, basically just a reference back to the package (literally, see the source if you care).

=item B<get ($visitor_type)>

Attempts to load the C<$visitor_type> and returns an instance of it if successfull. If no C<$visitor_type> is specified an exception is thrown, if C<$visitor_type> fails to load, and exception is thrown.

=item B<getVisitor ($visitor_type)>

This is an alias of C<get>.

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

