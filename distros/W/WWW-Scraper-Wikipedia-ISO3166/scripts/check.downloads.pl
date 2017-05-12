#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Scraper::Wikipedia::ISO3166::Database::Import;

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

	exit WWW::Scraper::Wikipedia::ISO3166::Database::Import -> new(%option, 'max' => 'info') -> check_downloads;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

check.downloads.pl - Report missing and unexpected files in data/

=head1 Synopsis

check.downloads.pl [options]

	Options:
	-help
	-maxlevel $string

All switches can be reduced to a single letter.

Exit value: 0.

=head1 Description

Report, and log level 'info', any unusual things about files in data/.

If nothing untoward is found, nothing is printed.

=head1 OPTIONS

=over 4

=item -help

Print help and exit.

=item -maxlevel => $string

Typical values: 'debug'.

Default: 'notice'.

=back

=cut
