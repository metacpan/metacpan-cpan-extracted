package PPIx::Regexp::Token::CharClass::POSIX::Unknown;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::CharClass::POSIX };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL @CARP_NOT };

our $VERSION = '0.063';

sub perl_version_introduced {
#   my ( $self ) = @_;
    return MINIMUM_PERL;
}

# Note that these guys are recognized by PPIx::Regexp::CharClass::POSIX,
# and if one of them becomes supported that is where the change needs to
# be made.

# This is the handiest way to make this object represent a parse error.
sub __PPIX_LEXER__finalize {
    return 1;
}


1;

__END__

=head1 NAME

PPIx::Regexp::Token::CharClass::POSIX::Unknown - Represent an unknown or unsupported POSIX character class

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{ [[=a=]] }smx' )
     -print()

=head1 INHERITANCE

C<PPIx::Regexp::Token::CharClass::POSIX::Unknown> is a
L<PPIx::Regexp::Token::CharClass::POSIX|PPIx::Regexp::Token::CharClass::POSIX>.

C<PPIx::Regexp::Token::CharClass::POSIX::Unknown> has no descendants.

=head1 DESCRIPTION

This class represents POSIX character classes which are recognized but
not supported by Perl. At the moment this means C<[=a=]> (equivalence
classes), and C<[.ch.]> (collating symbols).

B<Caveat:> If any of these becomes supported by Perl in the future, they
will become represented as
L<PPIx::Regexp::Token::CharClass::POSIX|PPIx::Regexp::Token::CharClass::POSIX>
objects, with an appropriate C<perl_version_introduced()> value.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
