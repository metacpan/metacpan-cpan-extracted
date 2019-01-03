=head1 NAME

PPIx::Regexp::Structure::Assertion - Represent a parenthesized assertion

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?<=foo)bar}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Assertion> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Assertion> has no descendants.

=head1 DESCRIPTION

This class represents one of the parenthesized assertions, either look
ahead or look behind, and either positive or negative.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

our $VERSION = '0.063';

use PPIx::Regexp::Constant qw{
    LITERAL_LEFT_CURLY_ALLOWED
    @CARP_NOT
};

# An un-escaped literal left curly bracket can always follow this
# element.
sub __following_literal_left_curly_disallowed_in {
    return LITERAL_LEFT_CURLY_ALLOWED;
}

1;

__END__

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
