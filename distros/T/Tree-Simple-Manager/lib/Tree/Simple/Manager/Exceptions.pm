
package Tree::Simple::Manager::Exceptions;

use strict;
use warnings;

our $VERSION = '0.02';

use Class::Throwable qw(
    Tree::Simple::Manager::InsufficientArguments
    Tree::Simple::Manager::IllegalOperation
    Tree::Simple::Manager::KeyDoesNotExist
    Tree::Simple::Manager::DuplicateName
    Tree::Simple::Manager::IncorrectObjectType
    Tree::Simple::Manager::OperationFailed
    Tree::Simple::Manager::IncorrectObjectType
);

$Class::Throwable::DEFAULT_VERBOSITY = 2;

1;

__END__

=pod

=head1 NAME

Tree::Simple::Manager::Exceptions - A set of exception classes for Tree::Simple::Manager

=head1 SYNOPSIS

  use Tree::Simple::Manager::Exceptions;   

=head1 DESCRIPTION

This module just creates a number of exceptions for use with the Tree::Simple::Manager classes. 

=head1 EXCEPTIONS

=over 4

=item B<Tree::Simple::Manager::InsufficientArguments>

=item B<Tree::Simple::Manager::IllegalOperation>

=item B<Tree::Simple::Manager::KeyDoesNotExist>

=item B<Tree::Simple::Manager::DuplicateName>

=item B<Tree::Simple::Manager::IncorrectObjectType>

=item B<Tree::Simple::Manager::OperationFailed>

=item B<Tree::Simple::Manager::IncorrectObjectType>

=back

=head1 SEE ALSO

=over 4

=item L<Class::Throwable>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

