#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Scraper::Wikipedia::ISO3166::Database::Download;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'code2=s',
	'help',
	'maxlevel=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Download -> new(%option) -> get_subcountry_page;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

get.subcountry.page.pl - Get http://en.wikipedia.org.wiki.ISO_3166-2.$code2.html

=head1 SYNOPSIS

populate.subcountry.pl [options]

	Options:
	-code2 $a_2_letter_country_code
	-help
	-maxlevel $string

All switches can be reduced to a single letter.

Exit value: 0.

Default input: http://en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

Default output: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

=head1 OPTIONS

=over 4

=item -code2 $a_2_letter_country_code

Specify the code of the country to process.

=item -help

Print help and exit.

=item -maxlevel => $string

Typical values: 'debug'.

Default: 'notice'.

=back

=cut
