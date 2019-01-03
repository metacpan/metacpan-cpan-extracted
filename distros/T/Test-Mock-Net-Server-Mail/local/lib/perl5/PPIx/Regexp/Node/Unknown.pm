package PPIx::Regexp::Node::Unknown;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Node };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';


1;

__END__

=head1 NAME

PPIx::Regexp::Node::Unknown - Represent an unknown node.

=head1 SYNOPSIS

None. Sorry. This class was added to support the C<strict> option, which
was itself an attempt to capture the functionality of
C<use re 'strict'>. It is not known to have any other use, and it cannot
be instantiated in any straightforward manner.

=head1 INHERITANCE

C<PPIx::Regexp::Node::Unknown> is a
L<PPIx::Regexp::Node|PPIx::Regexp::Node>.

C<PPIx::Regexp::Node::Unknown> has no descendants.

=head1 DESCRIPTION

This class is used for a node which the lexer recognizes as being
improperly constructed.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
