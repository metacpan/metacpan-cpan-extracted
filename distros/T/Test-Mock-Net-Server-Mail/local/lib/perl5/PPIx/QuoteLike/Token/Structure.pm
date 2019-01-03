package PPIx::QuoteLike::Token::Structure;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::QuoteLike::Token };

use PPIx::QuoteLike::Constant qw{ @CARP_NOT };

our $VERSION = '0.006';


1;

__END__

=head1 NAME

PPIx::QuoteLike::Token::Structure - Represent the structure of the
string.

=head1 SYNOPSIS

This class should not be instantiated by the user. See below for public
methods.

=head1 INHERITANCE

C<PPIx::QuoteLike::Token::Structure> is a
L<PPIx::QuoteLike::Token|PPIx::QuoteLike::Token>.

C<PPIx::QuoteLike::Token::Structure> is the parent of
L<PPIx::QuoteLike::Token::Delimiter|PPIx::QuoteLike::Token::Delimiter>.

=head1 DESCRIPTION

This Perl class represents the initial token in the string; that is, the
C<'q'>, C<'qq'>, C<'qx'>, or (for here documents) C< '<<' >, together
with any trailing space. For strings that have no initial token (that
is, those simply enclosed in quotes) this will be the empty string.

=head1 METHODS

This class supports the following public methods:

=head1 SEE ALSO

L<PPIx::QuoteLike::Token|PPIx::QuoteLike::Token>.

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
