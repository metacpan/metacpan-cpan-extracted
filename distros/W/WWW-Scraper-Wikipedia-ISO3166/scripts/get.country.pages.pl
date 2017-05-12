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
	'help',
	'maxlevel=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Download -> new(%option) -> get_country_pages;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

get.country.pages.pl - Get http://en.wikipedia.org/wiki/ISO_3166-[12].html

=head1 SYNOPSIS

get.country.pages.pl [options]

	Options:
	-help
	-maxlevel $string

All switches can be reduced to a single letter.

Exit value: 0 for success.

1: Input: http://en.wikipedia.org.wiki.ISO_3166-1

Output: data/en.wikipedia.org.wiki.ISO_3166-1.html.

2: Input: http://en.wikipedia.org.wiki.ISO_3166-2.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.html.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -maxlevel => $string

Typical values: 'debug'.

Default: 'notice'.

=back

=cut
