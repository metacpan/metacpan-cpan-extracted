=head1 NAME

PPIx::Regexp::Structure::Switch - Represent a switch

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?(1)foo|bar)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Structure::Switch> is a
L<PPIx::Regexp::Structure|PPIx::Regexp::Structure>.

C<PPIx::Regexp::Structure::Switch> has no descendants.

=head1 DESCRIPTION

This class represents a switch, or conditional expression. The condition
will be the first child.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Structure::Switch;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Structure };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

sub __PPIX_LEXER__finalize {
    my ( $self, $lexer ) = @_;

    # Assume no errors.
    my $rslt = 0;

    # Number of allowed alternations not known yet.
    my $alternations;

    # If we are a valid switch, the first child is the condition. Make
    # sure we have a first child and that it is of the expected class.
    # If it is, determine how many alternations are allowed.
    if ( my $condition = $self->child( 0 ) ) {
	foreach my $class ( qw{
	    PPIx::Regexp::Structure::Assertion
	    PPIx::Regexp::Structure::Code
	    PPIx::Regexp::Token::Condition
	    } ) {
	    $condition->isa( $class ) or next;
	    $alternations = $condition->content() eq '(DEFINE)' ? 0 : 1;
	    last;
	}
    }

    if ( defined $alternations ) {
	# If we figured out how many alternations were allowed, count
	# them, changing surplus ones to the unknown token.
	foreach my $kid ( $self->children () ) {
	    $kid->isa( 'PPIx::Regexp::Token::Operator' ) or next;
	    $kid->content() eq '|' or next;
	    --$alternations >= 0 and next;
	    $kid->__error( 'Too many alternatives for switch' );
	}
    } else {
	# If we could not figure out how many alternations were allowed,
	# it means we did not understand our condition. Rebless
	# ourselves to the unknown structure and count a parse failure.
	$self->__error( 'Switch condition not understood' );
	$rslt++;
    }

    # Delegate to the superclass to finalize our children, now that we
    # have finished messing with them.
    $rslt += $self->SUPER::__PPIX_LEXER__finalize( $lexer );

    return $rslt;
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
