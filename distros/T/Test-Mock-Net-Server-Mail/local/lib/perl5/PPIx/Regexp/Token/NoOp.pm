package PPIx::Regexp::Token::NoOp;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use Carp;
use PPIx::Regexp::Constant qw{ MINIMUM_PERL @CARP_NOT };

our $VERSION = '0.063';

{
    my %when_removed = (
	'\\N{}'	=> '5.027001',
    );

    sub __new {
	my ( $class, $content, %arg ) = @_;

	defined $arg{perl_version_introduced}
	    or $arg{perl_version_introduced} = MINIMUM_PERL;

	exists $arg{perl_version_removed}
	    or $arg{perl_version_removed} = $when_removed{$content};

	return $class->SUPER::__new( $content, %arg );
    }
}

# Return true if the token can be quantified, and false otherwise
sub can_be_quantified { return };

sub explain {
    return 'Not significant';
}

sub significant {
    return;
}


1;

__END__

=head1 NAME

PPIx::Regexp::Token::NoOp - Represent a token that does nothing.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr< \N{} >smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::NoOp> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::NoOp> is the parent of
L<PPIx::Regexp::Token::Whitespace|PPIx::Regexp::Token::Whitespace>.

=head1 DESCRIPTION

This class represents a token the does nothing.

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
