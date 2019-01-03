=head1 NAME

PPIx::Regexp::Token::Control - Case and quote control.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{\Ufoo\E}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::Control> is a
L<PPIx::Regexp::Token|PPIx::Regexp::Token>.

C<PPIx::Regexp::Token::Control> has no descendants.

=head1 DESCRIPTION

This class represents the case and quote controls. These apply when the
regular expression is compiled, changing the actual expression
generated. For example

 print qr{\Ufoo\E}, "\n"

prints

 (?-xism:FOO)

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::Control;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token };

use PPIx::Regexp::Constant qw{
    COOKIE_QUOTE
    MINIMUM_PERL
    TOKEN_LITERAL
    TOKEN_UNKNOWN
    @CARP_NOT
};

our $VERSION = '0.063';

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

{

    my %explanation = (
	'\\E'	=> 'End of interpolation control',
	'\\F'	=> 'Fold case until \\E',
	'\\L'	=> 'Lowercase until \\E',
	'\\Q'	=> 'Quote metacharacters until \\E',
	'\\U'	=> 'Uppercase until \\E',
	'\\l'	=> 'Lowercase next character',
	'\\u'	=> 'Uppercase next character',
    );

    sub __explanation {
	return \%explanation;
    }

}

{
    my %version_introduced = (
	'\\F'	=> '5.015008',
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	my $content = $self->content();
	defined $version_introduced{$content}
	    and return $version_introduced{$content};
	return MINIMUM_PERL;
    }
}

my %is_control = map { $_ => 1 } qw{ l u L U Q E F };

my %cookie_slot = (
    Q	=> 'quote',
    E	=> 'end',
    U	=> 'case',
    L	=> 'case',
    F	=> 'case',
);

use constant CONTROL_MASK_QUOTE	=> 1 << 1;

my %cookie_mask = (
    case	=> 1 << 0,
    end		=> 0,		# must be 0.
    quote	=> CONTROL_MASK_QUOTE,
);

sub __PPIX_TOKENIZER__regexp {
    my ( undef, $tokenizer, $character ) = @_;

    # If we are inside a quote sequence, we want to make literals out of
    # all the characters we reject; otherwise we just want to return
    # nothing.
    my $in_quote = $tokenizer->cookie( COOKIE_QUOTE ) || do {
	my @stack = ( { mask => 0, reject => sub { return; } } );
	$tokenizer->cookie( COOKIE_QUOTE, sub { return \@stack } );
    };
    my $cookie_stack = $in_quote->( $tokenizer );
    my $reject = $cookie_stack->[-1]{reject};

    # We are not interested in anything that is not escaped.
    $character eq '\\' or return $reject->( 1 );

    # We need to see what the next character is to figure out what to
    # do. If there is no next character, we do not know what to call the
    # back slash.
    my $control = $tokenizer->peek( 1 )
	or return $reject->( 1, TOKEN_UNKNOWN, {
		error => 'Trailing back slash'
	    },
	);

    # We reject any escapes that do not represent controls.
    $is_control{$control} or return $reject->( 2 );

    # Anything left gets made into a token now, to avoid its processing
    # by the cookie we may make.
    my $token = $tokenizer->make_token( 2 );

    # \U, \L, and \F supersede each other, but they stack with \Q. So we
    # need to track that behavior, so that we know what to do when we
    # hit a \E.
    # TODO if we wanted we could actually track which (if any) of \U, \L
    # and \F is in effect, and make that an attribute of any literals
    # made.
    if ( my $slot = $cookie_slot{$control} ) {
	if ( my $mask = $cookie_mask{$slot} ) {
	    # We need another stack entry only if the current slot
	    # ('case' or 'quote') is not occupied
	    unless ( $mask & $cookie_stack->[-1]{mask} ) {
		# Clone the previous entry.
		push @{ $cookie_stack }, { %{ $cookie_stack->[-1] } };
		# Set the mask to show this slot is occupied
		$cookie_stack->[-1]{mask} |= $mask;
		# Code to call when this tokenizer rejects a token
		$cookie_stack->[-1]{reject} =
		    ( $mask & CONTROL_MASK_QUOTE ) ?
		    sub {
			my ( $size, $class ) = @_;
			return $tokenizer->make_token(
			    $size, $class || TOKEN_LITERAL );
		    } : $cookie_stack->[0]{reject};
	    }
	    # TODO if I want to try to track what controls are in effect
	    # where.
	    # Record the specific content of the current slot
	    # $cookie_stack->[-1]{$slot} = $control;
	} else {
	    # \E - pop data, but don't leave empty.
	    @{ $cookie_stack } > 1
		and pop @{ $cookie_stack };
	}
    }

    # Return our token.
    return $token;
}

sub __PPIX_TOKENIZER__repl {
    my ( undef, $tokenizer ) = @_;	# Invocant, $character unused

    $tokenizer->interpolates() and goto &__PPIX_TOKENIZER__regexp;

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
