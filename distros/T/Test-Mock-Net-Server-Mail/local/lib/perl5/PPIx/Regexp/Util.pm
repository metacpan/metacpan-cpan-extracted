package PPIx::Regexp::Util;

use 5.006;

use strict;
use warnings;

use Carp;
use PPIx::Regexp::Constant qw{ @CARP_NOT };
use Scalar::Util qw{ blessed };

use base qw{ Exporter };

our @EXPORT_OK = qw{
    __choose_tokenizer_class __instance
    __is_ppi_regexp_element
    __ns_can __to_ordinal_en
};

our $VERSION = '0.063';

{

    my @ppi_zoo = (
	[ 'PPI::Token::Regexp::Transliterate' ],

	[ 'PPI::Token::Regexp', 'PPIx::Regexp::Tokenizer' ],
	[ 'PPI::Token::QuoteLike::Regexp', 'PPIx::Regexp::Tokenizer' ],

	[ 'PPI::Token::Quote',
	    'PPIx::Regexp::StringTokenizer' ],
	[ 'PPI::Token::QuoteLike::Command',
	    'PPIx::Regexp::StringTokenizer' ],
	[ 'PPI::Token::QuoteLike::BackTick',
	    'PPIx::Regexp::StringTokenizer' ],
	[ 'PPI::Token::HereDoc',
	    'PPIx::Regexp::StringTokenizer' ],
    );

    sub __is_ppi_regexp_element {
	my ( $elem ) = @_;
	foreach ( @ppi_zoo ) {
	    $elem->isa( $_->[0] )
		or next;
	    return 'PPIx::Regexp::Tokenizer' eq $_->[1];
	}
	return;
    }

    my %parse_type = (
	guess	=> sub {
	    my ( $content ) = @_;
	    if ( __instance( $content, 'PPI::Element' ) ) {
		foreach ( @ppi_zoo ) {
		    $content->isa( $_->[0] )
			and return $_->[1];
		}
		return;
	    } elsif ( ref $content ) {
		return;
	    } else {
		return $content =~ m/ \A \s*
		(?: ["'`] | << | (?: (?: qq | q | qx ) \b ) ) /smx ?
		'PPIx::Regexp::StringTokenizer' :
		'PPIx::Regexp::Tokenizer';
	    }
	},
	regex	=> sub {
	    return 'PPIx::Regexp::Tokenizer';
	},
	string	=> sub {
	    return 'PPIx::Regexp::StringTokenizer';
	},
    );

    sub __choose_tokenizer_class {
	my ( $content, $arg ) = @_;
	if ( defined $arg->{parse} &&
	    warnings::enabled( 'deprecated' )
	) {
	    my $warning = q<The 'parse' argument is deprecated.>;
	    { guess => 1, string => 1 }->{$arg->{parse}}
		and $warning = join ' ', $warning,
		    q<You should use PPIx::QuoteLike on quotish things>;
	    carp $warning;
	}
	my $parse = defined $arg->{parse} ? $arg->{parse} : 'regex';
	my $code = $parse_type{$parse}
	    or return PPIx::Regexp::Tokenizer->__set_errstr(
	    "Unknown parse type '$parse'" );
	return $code->( $content );
    }

}

sub __instance {
    my ( $object, $class ) = @_;
    blessed( $object ) or return;
    return $object->isa( $class );
}

sub __ns_can {
    my ( $class, $name ) = @_;
    my $fqn = join '::', ref $class || $class, $name;
    no strict qw{ refs };
    return defined &$fqn ? \&$fqn : undef;
}

sub __to_ordinal_en {
    my ( $num ) = @_;
    $num += 0;
    1 == $num % 10
	and return "${num}st";
    2 == $num % 10
	and return "${num}nd";
    3 == $num % 10
	and return "${num}rd";
    return "${num}th";
}

1;

__END__

=head1 NAME

PPIx::Regexp::Util - Utility functions for PPIx::Regexp;

=head1 SYNOPSIS

 use PPIx::Regexp::Util qw{ __instance };
     .
     .
     .
 __instance( $foo, 'Bar' )
     or die '$foo is not a Bar';

=head1 DESCRIPTION

This module contains utility functions for L<PPIx::Regexp|PPIx::Regexp>
which it is convenient to centralize.

The contents of this module are B<private> to the
L<PPIx::Regexp|PPIx::Regexp> package. This documentation is provided for
the author's convenience only. Anything in this module is subject to
change without notice. I<Caveat user.>

This module exports nothing by default.

=head1 SUBROUTINES

This module can export the following subroutines:

=head2 __instance

 __instance( $foo, 'Bar' )
     and print '$foo isa Bar', "\n";

This subroutine returns true if its first argument is an instance of the
class specified by its second argument. Unlike C<UNIVERSAL::isa>, the
result is always false unless the first argument is a reference.

=head2 __is_ppi_regexp_element

 __is_ppi_regexp_element( $elem )
   and print "$elem is a regexp of some sort\n";

This subroutine takes as its argument a L<PPI::Element|PPI::Element>. It
returns a true value if the argument represents a regular expression of
some sort, and a false value otherwise.

=head2 __ns_can

This method is analogous to C<can()>, but returns a reference to the
code only if it is actually implemented by the invoking name space.

=head2 __to_ordinal_en

This subroutine takes as its argument an integer and returns a string
representing its ordinal in English. For example

 say __to_ordinal_en( 17 );
 # 17th

=cut


=head1 SEE ALSO

L<Params::Util|Params::Util>, which I recommend, but in the case of
C<PPIx::Regexp> I did not want to introduce a dependency on an XS module
when all I really wanted was the function of that module's
C<_INSTANCE()> subroutine.


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
