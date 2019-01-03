=head1 NAME

PPIx::Regexp::Token::Condition - Represent the condition of a switch

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?(1)foo|bar)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Condition> is a
L<PPIx::Regexp::Token::Reference|PPIx::Regexp::Token::Reference>.

C<PPIx::Regexp::Token::Condition> has no descendants.

=head1 DESCRIPTION

This class represents the condition portion of a switch or conditional
expression, provided that condition is reasonably represented as a
token.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Condition;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Reference };

use PPIx::Regexp::Constant qw{ RE_CAPTURE_NAME @CARP_NOT };

our $VERSION = '0.063';

{

    my %explanation = (
	'(DEFINE)'	=> 'Define a group to be recursed into',
	'(R)'	=> 'True if recursing',
    );

    sub explain {
	my ( $self ) = @_;
	my $content = $self->content();
	if ( defined( my $expl = $explanation{$content} ) ) {
	    return $expl;
	}
	if ( $content =~ m/ \A [(] R /smx ) {	# )
	    $self->is_named()
		and return sprintf
		q<True if recursing directly inside capture group '%s'>,
		$self->name();
	    return sprintf
		q<True if recursing directly inside capture group %d>,
		$self->absolute();
	}
	$self->is_named()
	    and return sprintf
	    q<True if capture group '%s' matched>,
	    $self->name();
	return sprintf
	    q<True if capture group %d matched>,
	    $self->absolute();
    }

}

sub perl_version_introduced {
    my ( $self ) = @_;
    $self->content() =~ m/ \A [(] [0-9]+ [)] \z /smx
	and return '5.005';
    return '5.009005';
}

my @recognize = (
    [ qr{ \A \( (?: ( [0-9]+ ) | R ( [0-9]+ ) ) \) }smx,
	{ is_named => 0 } ],
    [ qr{ \A \( R \) }smx,
	{ is_named => 0, capture => '0' } ],
    [ qr{ \A \( (?: < ( @{[ RE_CAPTURE_NAME ]} ) > |
	    ' ( @{[ RE_CAPTURE_NAME ]} ) ' |
	    R & ( @{[ RE_CAPTURE_NAME ]} ) ) \) }smxo,
	{ is_named => 1} ],
    [ qr{ \A \( DEFINE \) }smx,
	{ is_named => 0, capture => '0' } ],
);

# This must be implemented by tokens which do not recognize themselves.
# The return is a list of list references. Each list reference must
# contain a regular expression that recognizes the token, and optionally
# a reference to a hash to pass to make_token as the class-specific
# arguments. The regular expression MUST be anchored to the beginning of
# the string.
sub __PPIX_TOKEN__recognize {
    return @recognize;
}


# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub __PPIX_TOKENIZER__regexp {
    my ( undef, $tokenizer ) = @_;	# Invocant, $character unused

    foreach ( @recognize ) {
	my ( $re, $arg ) = @{ $_ };
	my $accept = $tokenizer->find_regexp( $re ) or next;
	return $tokenizer->make_token( $accept, __PACKAGE__, $arg );
    }

    return;
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
