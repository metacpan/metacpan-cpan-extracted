
package Tree::Simple::View::Exceptions;

use strict;
use warnings;

our $VERSION = '0.19';

use Class::Throwable qw(
    Tree::Simple::View::InsufficientArguments
    Tree::Simple::View::AbstractMethod
    Tree::Simple::View::AbstractClass
    Tree::Simple::View::CompilationFailed
);

1;

__END__

=pod

=head1 NAME

Tree::Simple::View::Exceptions - A set of exceptions for Tree::Simple::View

=head1 SYNOPSIS

  use Tree::Simple::View::Exceptions;

=head1 DESCRIPTION

This just creates and loads a few exceptions for use by the Tree::Simple::View classes.
Nothing else to see really.

=head1 EXCEPTIONS

=over 4

=item B<Tree::Simple::View::InsufficientArguments>

=item B<Tree::Simple::View::AbstractMethod>

=item B<Tree::Simple::View::AbstractClass>

=item B<Tree::Simple::View::CompilationFailed>

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it.

=head1 CODE COVERAGE

See the CODE COVERAGE section of Tree::Simple::View for details.

=head1 SEE ALSO

=over 4

=item L<Class::Throwable>

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
