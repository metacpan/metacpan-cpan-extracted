=head1 NAME

PPIx::Regexp::Token::GroupType::Assertion - Represent a look ahead or look behind assertion

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qr{foo(?=bar)}smx' )
     ->print();

=head1 INHERITANCE

C<PPIx::Regexp::Token::GroupType::Assertion> is a
L<PPIx::Regexp::Token::GroupType|PPIx::Regexp::Token::GroupType>.

C<PPIx::Regexp::Token::GroupType::Assertion> has no descendants.

=head1 DESCRIPTION

This class represents the parenthesized look ahead and look behind
assertions.

=head1 METHODS

This class provides no public methods beyond those provided by its
superclass.

=cut

package PPIx::Regexp::Token::GroupType::Assertion;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Token::GroupType };

use PPIx::Regexp::Constant qw{ @CARP_NOT };

our $VERSION = '0.063';

{
	my $expl_nla	= 'Negative look-ahead assertion';
	my $expl_nlb	= 'Negative look-behind assertion';
	my $expl_pla	= 'Positive look-ahead assertion';
	my $expl_plb	= 'Positive look-behind assertion';

	__PACKAGE__->__setup_class( {

		'?!'	=> {
		    expl	=> $expl_nla,
		},
		'*nla:'	=> {
		    expl	=> $expl_nla,
		    intro	=> '5.027009',
		},
		'*negative_lookahead:'	=> {
		    expl	=> $expl_nla,
		    intro	=> '5.027009',
		},
		'?<!'	=> {
		    expl	=> $expl_nlb,
		    intro	=> '5.005',
		},
		'*nlb:'	=> {
		    expl	=> $expl_nlb,
		    intro	=> '5.027009',
		},
		'*negative_lookbehind:'	=> {
		    expl	=> $expl_nlb,
		    intro	=> '5.027009',
		},
		'?='	=> {
		    expl	=> $expl_pla,
		},
		'*pla:'	=> {
		    expl	=> $expl_pla,
		    intro	=> '5.027009',
		},
		'*positive_lookahead:'	=> {
		    expl	=> $expl_pla,
		    intro	=> '5.027009',
		},
		'?<='	=> {
		    expl	=> $expl_plb,
		    intro	=> '5.005',
		},
		'*plb:'	=> {
		    expl	=> $expl_plb,
		    intro	=> '5.027009',
		},
		'*positive_lookbehind:'	=> {
		    expl	=> $expl_plb,
		    intro	=> '5.027009',
		},
	    },
	);
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
