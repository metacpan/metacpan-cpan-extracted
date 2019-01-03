=head1 NAME

PPIx::Regexp::Token::GroupType::Modifier - Represent the modifiers in a modifier group.

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{(?i:foo)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::Modifier> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType> and a
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier>.

C<PPIx::Regexp::Token::GroupType::Modifier> has no descendants.

=head1 DESCRIPTION

This class represents the modifiers in a modifier group. The useful
functionality comes from
L<PPIx::Regexp::Token::Modifier|PPIx::Regexp::Token::Modifier>.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclasses.

=cut

package PPIx::Regexp::Token::GroupType::Modifier;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::Modifier PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ MINIMUM_PERL @CARP_NOT };

our $VERSION = '0.063';

{

    my %perl_version_introduced = (
	'?:'	=> MINIMUM_PERL,
    );

    sub perl_version_introduced {
	my ( $self ) = @_;
	my $content = $self->unescaped_content();
	exists $perl_version_introduced{$content}
	    and return $perl_version_introduced{$content};
	my $ver = $self->SUPER::perl_version_introduced();
	$ver > 5.005 and return $ver;
	return '5.005';
    }

}

=begin comment

# Return true if the token can be quantified, and false otherwise
# sub can_be_quantified { return };

sub __PPIX_TOKENIZER__regexp {
    my ( $class, $tokenizer, $character, $char_type ) = @_;

    # Note that the optional escapes are because any of the
    # non-open-bracket punctuation characters might be our delimiter.
    my $accept;
    $accept = $tokenizer->find_regexp(
	qr{ \A \\? [?] [[:lower:]]* \\? -? [[:lower:]]* \\? : }smx )
	and return $accept;
    $accept = $tokenizer->find_regexp(
	qr{ \A \\? [?] \^ [[:lower:]]* \\? : }smx )
	and return $accept;

    return;
}

=end comment

=cut

sub __make_group_type_matcher {
    return {
	''	=> [
	    qr{ \A [?] [[:lower:]]* -? [[:lower:]]* : }smx,
	    qr{ \A [?] \^ [[:lower:]]* : }smx,
	],
	'?'	=> [
	    qr{ \A \\ [?] [[:lower:]]* -? [[:lower:]]* : }smx,
	    qr{ \A \\ [?] \^ [[:lower:]]* : }smx,
	],
	'-'	=> [
	    qr{ \A [?] [[:lower:]]* (?: \\ - )? [[:lower:]]* : }smx,
	    qr{ \A [?] \^ [[:lower:]]* : }smx,
	],
	':'	=> [
	    qr{ \A [?] [[:lower:]]*  -? [[:lower:]]* \\ : }smx,
	    qr{ \A [?] \^ [[:lower:]]* \\ : }smx,
	],
    };
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
