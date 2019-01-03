=head1 NAME

PPIx::Regexp::Token - Base class for PPIx::Regexp tokens.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo}' )->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token> is a
L<PPIx::Regexp::Element|PPIx::Regexp::Element>.

C<PPIx::Regexp::Token> is the parent of
L<PPIx::Regexp::Token::Assertion|PPIx::Regexp::Token::Assertion>,
L<PPIx::Regexp::Token::Backtrack|PPIx::Regexp::Token::Backtrack>,
L<PPIx::Regexp::Token::CharClass|PPIx::Regexp::Token::CharClass>,
L<PPIx::Regexp::Token::Code|PPIx::Regexp::Token::Code>,
L<PPIx::Regexp::Token::Comment|PPIx::Regexp::Token::Comment>,
L<PPIx::Regexp::Token::Control|PPIx::Regexp::Token::Control>,
L<PPIx::Regexp::Token::Greediness|PPIx::Regexp::Token::Greediness>,
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>,
L<PPIx::Regexp::Token::Literal|PPIx::Regexp::Token::Literal>,
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier>,
L<PPIx::Regexp::Token::NoOp|PPIx::Regexp::Token::NoOp>,
L<PPIx::Regexp::Token::Operator|PPIx::Regexp::Token::Operator>,
L<PPIx::Regexp::Token::Quantifier|PPIx::Regexp::Token::Quantifier>,
L<PPIx::Regexp::Token::Reference|PPIx::Regexp::Token::Reference>,
L<PPIx::Regexp::Token::Structure|PPIx::Regexp::Token::Structure>,
L<PPIx::Regexp::Token::Unknown|PPIx::Regexp::Token::Unknown> and
L<PPIx::Regexp::Token::Unmatched|PPIx::Regexp::Token::Unmatched>.

=head1 DESCRIPTION

This class represents the base of the class hierarchy for tokens in the
L<PPIx::Regexp|PPIx::Regexp> package.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token;

use strict;
use warnings;

use base qw{PPIx::Regexp::Element};

use Carp qw{ confess };
use PPIx::Regexp::Constant qw{ MINIMUM_PERL @CARP_NOT };

our $VERSION = '0.063';

use constant TOKENIZER_ARGUMENT_REQUIRED => 0;

sub __new {
    my ( $class, $content, %arg ) = @_;

    not $class->TOKENIZER_ARGUMENT_REQUIRED()
	or $arg{tokenizer}
	or confess 'Programming error - tokenizer not provided';

    my $self = {
	content => $content,
    };

    foreach my $key ( qw{ perl_version_introduced perl_version_removed } ) {
	defined $arg{$key}
	    and $self->{$key} = $arg{$key};
    }

    bless $self, ref $class || $class;
    return $self;
}

sub content {
    my ( $self ) = @_;
    return $self->{content};
}

sub perl_version_introduced {
    my ( $self ) = @_;
    return defined $self->{perl_version_introduced} ?
	$self->{perl_version_introduced} :
	MINIMUM_PERL;
}

sub perl_version_removed {
    my ( $self ) = @_;
    return $self->{perl_version_removed};
}

sub unescaped_content {
    my ( $self ) = @_;
    my $content = $self->content();
    $content =~ s/ \\ (?= . ) //smxg;
    return $content;
}

sub scontent {
    my ( $self ) = @_;
    $self->significant()
	and return $self->{content};
    return;
}

# Called by the lexer once it has done its worst to all the tokens.
# Called as a method with the lexer as argument. The return is the
# number of parse failures discovered when finalizing.
sub __PPIX_LEXER__finalize {
    return 0;
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
