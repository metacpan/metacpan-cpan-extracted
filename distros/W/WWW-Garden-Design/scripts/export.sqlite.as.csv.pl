#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Garden::Design::Export::SQLite;

use Pod::Usage;

# -----------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
	\%option,
	'all=s',
	'help',
	'output_file=s',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Garden::Design::Export::SQLite -> new(%option) -> as_csv;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.as.csv.pl - Output flowers db to CSV

=head1 SYNOPSIS

export.as.csv.pl [options]

	Options:
	-all Yes or No
	-help
	-output_file aCSVFileName

All switches can be reduced to a single letter.

Exit value: 0.

=head1 OPTIONS

=over 4

=item o all => Yes or No

=over 4

=item o Yes

Export everything.

=item o No

Respect property/garden/flower-level publish flag.

=back

=item o help

Print help and exit.

=item o output_file => aCSVFileName

The name of a CSV file to write.

By default, nothing is written.

Default: ''.

=back

=cut
