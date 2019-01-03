=head1 NAME

PPIx::Regexp::Node::Range - Represent a character range in a character class

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{[a-z]}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Node::Range> is a
L<PPIx::Regexp::Node|PPIx::Regexp::Node>.

C<PPIx::Regexp::Node::Range> has no descendants.

=head1 DESCRIPTION

This class represents a character range in a character class. It is a
node rather than a structure because there are no delimiters. The
content is simply the two literals with the '-' operator between them.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Node::Range;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Node };

use PPIx::Regexp::Constant qw{
    MSG_PROHIBITED_BY_STRICT
    @CARP_NOT
};

our $VERSION = '0.063';

sub explain {
    my ( $self ) = @_;
    my $first = $self->schild( 0 )
	or return $self->__no_explanation();
    my $last = $self->schild( -1 )
	or return $self->__no_explanation();
    return sprintf q<Characters between '%s' and '%s' inclusive>,
	$first->content(), $last->content();
}

sub __PPIX_LEXER__finalize {
    my ( $self, $lexer ) = @_;

    my $rslt = $self->SUPER::__PPIX_LEXER__finalize( $lexer );

    if ( $lexer->strict() ) {
	# If strict is in effect, we're an error unless both ends of the
	# range are portable.
	my @kids = $self->schildren();
	delete $self->{_range_start};	# Context for compatibility.
	foreach my $inx ( 0, -1 ) {
	    my $kid = $kids[$inx];
	    # If we're not a literal, we can not make the test, so we
	    # blindly accept it.
	    $kid->isa( 'PPIx::Regexp::Token::Literal' )
		or next;
	    my $content = $kid->content();
	    $content =~ m/ \A (?: [[:alnum:]] | \\N\{ .* \} ) \z /smx
		and $self->_range_ends_compatible( $content )
		or return $self->_prohibited_by_strict( $rslt );
	}
    }

    return $rslt;
}

sub _prohibited_by_strict {
    my ( $self, $rslt ) = @_;
    delete $self->{_range_start};
    $rslt += $self->__error(
	join( ' ', 'Non-portable range ends', MSG_PROHIBITED_BY_STRICT ),
	perl_version_introduced	=> '5.023008',
    );
    return $rslt;
}

sub _range_ends_compatible {
    my ( $self, $content ) = @_;
    if ( defined( my $start = $self->{_range_start} ) ) {
	foreach my $re (
	    qr{ \A [[:upper:]] \z }smx,
	    qr{ \A [[:lower:]] \z }smx,
	    qr{ \A [0-9] \z }smx,
	    qr{ \A \\N \{ .* \} }smx,
	) {
	    $start =~ $re
		or next;
	    return $content =~ $re;
	}
	return;
    } else {
	$self->{_range_start} = $content;
	return 1;
    }
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
