package Text::Names::GB;

use warnings;
use strict;

# our @ISA = ('Text::Names');
use Text::Names qw/
    abbreviationOf
    reverseName
    cleanParseName
    parseName
    parseName2
    normalizeNameWhitespace
    samePerson
    sameAuthors
    parseNames
    parseNameList
    cleanNames
    cleanName
    weakenings
    composeName
    abbreviationOf
    setNameAbbreviations
    getNameAbbreviations
    isCommonSurname
    isCommonFirstname
    firstnamePrevalence
    surnamePrevalence
    isMisparsed
    isLikelyMisparsed
/;
    # guessGender

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	@NAME_PREFIXES
    abbreviationOf
    reverseName
    cleanParseName
    parseName
    parseName2
    normalizeNameWhitespace
    samePerson
    sameAuthors
    parseNames
    parseNameList
    cleanNames
    cleanName
    weakenings
    composeName
    abbreviationOf
    setNameAbbreviations
    getNameAbbreviations
    isCommonSurname
    isCommonFirstname
    guessGender
    firstnamePrevalence
    surnamePrevalence
    isMisparsed
    isLikelyMisparsed
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ();

=head1 NAME

Text::Names::GB - Perl extension for proper name parsing, normalization, recognition, and classification

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

The documentation for Text::Names doesn't make this clear, that module is specific to the US.
This module fixes that for the UK.
Unfortunately because of the nature of Text::Names other countries will also have
to be implemented as subclasses.

=head1 SUBROUTINES/METHODS

=head2 guessGender

Overrides the US tests with UK tests,
that's probably true in most other countries as well.

=cut

sub guessGender {
	my $name = uc(shift);

	my %gender_map = (
		'BERTIE'  => 'M',
		'BARRIE'  => 'M',
		'KAI'     => 'M',
		'REECE'   => 'M',
		'RITCHIE' => 'M',
		'OLLIE'   => 'M',
		'BEATON'  => 'M',
		'CALLUM'  => 'M',
		'STACEY'  => 'F',
		'ZARA'    => 'F'
	);

	return $gender_map{$name} if exists $gender_map{$name};

	# Fallback to guessGender if the name is not in the map
	# return $self->SUPER::guessGender($name);
	return Text::Names::guessGender($name);
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

I need to work out how to make ISA and Exporter play nicely with each other.

=head1 SEE ALSO

L<Text::Names>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Names::GB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Names-GB>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Names-GB/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2024 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
