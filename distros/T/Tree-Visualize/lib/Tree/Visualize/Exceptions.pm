
package Tree::Visualize::Exceptions;

use strict;
use warnings;

our $VERSION = '0.01';

use Class::Throwable qw(
    Tree::Visualize::InsufficientArguments
    Tree::Visualize::IncorrectObjectType
    Tree::Visualize::IllegalOperation
    Tree::Visualize::OperationFailed
    Tree::Visualize::MethodNotImplemented
    Tree::Visualize::KeyDoesNotExist    
    );
    
$Class::Throwable::DEFAULT_VERBOSITY = 2;     
       
1; 

__END__


=head1 NAME

Tree::Visualize::Exceptions - A set of exception object for the Tree::Visualize module

=head1 SYNOPSIS

    use Tree::Visualize::Exceptions;                                   

=head1 DESCRIPTION

This package just creates a bunch of L<Class::Throwable> exception objects.

=head1 EXCEPTIONS

=over 4

=item B<Tree::Visualize::InsufficientArguments>

=item B<Tree::Visualize::IncorrectObjectType>

=item B<Tree::Visualize::IllegalOperation>

=item B<Tree::Visualize::OperationFailed>

=item B<Tree::Visualize::MethodNotImplemented>

=item B<Tree::Visualize::KeyDoesNotExist>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. 

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

=head1 SEE ALSO

=over 4

=item L<Class::Throwable>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

