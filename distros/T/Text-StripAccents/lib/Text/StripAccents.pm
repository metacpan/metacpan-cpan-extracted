##############################################################
# Text::StripAccents - remove non a-z chars from a string
#  and replace them with their a-z counterparts
##############################################################
#
# Version information
# ===================
#
# 0.1	CC	Apr 05		New module
#
# 0.11	CC	Jun 05		After feedback in cpanrating,
#				documented that the module is
#				latin1 only, and pp with no
#				prereqs
#
##############################################################


package Text::StripAccents;
use strict;
use vars qw (@ISA $VERSION @EXPORT);
use Exporter ();

@ISA = qw(Exporter);
@EXPORT = qw(stripaccents);
$VERSION="0.11";

##############################################################
=pod

=head1 NAME

 Text::StripAccents - removes accented & special characters from strings

=head1 SYNOPSIS

 use Text::StripAccents;

 my $Stripaccent = Text::StripAccents->new();

 my $convertedString = $StripAccents->strip($unconvertedString);

OR

 use Text::StripAccents;

 stripaccents($string); 

=head1 DESCRIPTION

This simple module takes accented characters and replaces them with their anglicised ASCII counterparts, e.g. Ü becomes U. It currently ONLY supports Latin1. If there are any characters I've missed out that you think should be included, please mail me and I'll add them in.

This is a pure perl module with no prerequisites.

=head1 PREREQS

None.

=head1 SEE ALSO

Text::Unaccent is a much more advanced utility to do the same job, but with a C dependency.

=head1 CHANGES

0.11 - bugfix to clarify the documentation, as per Dobrica Pavlinusic's feedback.

=head1 LICENSE

Copyright 2005 by Charles Colbourn, all rights reserved. This program is free software, you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Charles Colbourn - charlesc@g0n.net

(Character mapping hash supplied by Nigel Currie).

=cut


##############################################################
# Text::Stripaccent::new - constructor
##############################################################
#
# Takes as param the character set you are using. Latin1 
# support only at present
#
# returns a Stripaccent object
##############################################################

sub new
{
	my $class = shift;
	my $charset = shift;

	my %object;
	return bless \%object,$class;
}

###############################################################
# Text::Stripaccent::strip
###############################################################
#
# Removes all accented chars from a string and replaces them
# with their unaccented equivalents.
# 
# takes a string as a param, returns a converted string
#
###############################################################

sub strip
{

	my $object = shift;
	my $string = shift;


	my %IsoLatin1ToASCIITable = ("A" => "A", "À" => "A", "Á" => "A", "Â" => "A",
"Ã" => "A", "Ä" => "A", "Å" => "A",
			     "B" => "B",
    			     "C" => "C", "Ç" => "C",
    			     "D" => "D",
    			     "E" => "E", "È" => "E", "É" => "E", "Ê" => "E",
"Ë" => "E",
    			     "F" => "F",
    			     "G" => "G",
    			     "H" => "H",
    			     "I" => "I", "Ì" => "I", "Í" => "I", "Î" => "I",
"Ï" => "I",
    			     "J" => "J",
    			     "K" => "K",
    			     "L" => "L",
    			     "M" => "M",
    			     "N" => "N", "Ñ" => "N",
    			     "O" => "O", "Ò" => "O", "Ó" => "O", "Ô" => "O",
"Õ" => "O", "Ö" => "O",
    			     "P" => "P",
    			     "Q" => "Q",
    			     "R" => "R",
    			     "S" => "S",
    			     "T" => "T",
    			     "U" => "U", "Ù" => "U", "Ú" => "U", "Û" => "U",
"Ü" => "U",
    			     "V" => "V",
    			     "W" => "W",
    			     "X" => "X",
    			     "Y" => "Y", "Y" => "Y",
    			     "Z" => "Z",
    			     "a" => "a", "à" => "a", "á" => "a", "â" => "a",
"ã" => "a", "ä" => "a", "å" => "a",
    			     "b" => "b",
    			     "c" => "c", "ç" => "c",
    			     "d" => "d",
    			     "e" => "e", "è" => "e", "é" => "e", "ê" => "e",
"ë" => "e",
    			     "f" => "f",
    			     "g" => "g",
    			     "h" => "h",
    			     "i" => "i", "ì" => "i", "í" => "i", "î" => "i",
"ï" => "i",
    			     "j" => "j",
    			     "k" => "k",
    			     "l" => "l",
    			     "m" => "m",
    			     "n" => "n", "ñ" => "n",
    			     "o" => "o", "ò" => "o", "ó" => "o", "ô" => "o",
"õ" => "o", "ö" => "o",
    			     "p" => "p",
    			     "q" => "q",
    			     "r" => "r",
    			     "s" => "s",
    			     "t" => "t",
    			     "u" => "u", "ù" => "u", "ú" => "u", "û" => "u",
"ü" => "u",
    			     "v" => "v",
    			     "w" => "w",
    			     "x" => "x",
    			     "y" => "y", "y" => "y", "ı" => "y",
    			     "z" => "z",
				"ß"=>"ss");

	my @stringArray = split //,$string;
	foreach (@stringArray)
	{
		if ($IsoLatin1ToASCIITable{$_})
		{
			$_ = $IsoLatin1ToASCIITable{$_};
		}
	}

	my $returnString = join '',@stringArray;

	return $returnString;
}

################################################################
# stripaccent - function to call ::strip in non OO mode
################################################################
sub stripaccents
{
	my $string = shift;
	return __PACKAGE__->strip($string);
}



1;

