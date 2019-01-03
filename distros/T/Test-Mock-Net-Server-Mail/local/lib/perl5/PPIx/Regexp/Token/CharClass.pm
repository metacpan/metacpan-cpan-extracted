=head1 NAME

PPIx::Regexp::Token::CharClass - Represent a character class

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{\w}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::CharClass> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::CharClass> is the parent of
L<PPIx::Regexp::Token::CharClass::POSIX|PPIx::Regexp::Token::CharClass::POSIX>
and
L<PPIx::Regexp::Token::CharClass::Simple|PPIx::Regexp::Token::CharClass::Simple>.

=head1 DESCRIPTION

This class represents a character class. It is not intended that this
class be instantiated; it simply serves to identify a character class in
the class hierarchy, and provide any common methods that might become
useful.

=head1 METHODS

This class provides the following public methods beyond those provided
by its superclass.

=cut

package PPIx::Regexp::Token::CharClass;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

##=head2 is_case_sensitive
##
##This method returns true if the character class is case-sensitive (that
##is, if it may match or not based on the case of the string being
##matched), false (but defined) if it is not, and simply returns (giving
##C<undef> in scalar context and an empty list in list context) if the
##case-sensitivity can not be determined.
##
##=cut
##
##sub is_case_sensitive {
##    return;
##}

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
