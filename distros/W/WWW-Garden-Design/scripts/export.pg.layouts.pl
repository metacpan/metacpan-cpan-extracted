#!/usr/bin/env perl

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Getopt::Long;

use WWW::Garden::Design::Export::Pg;

use Pod::Usage;

# -------------------------------

my($option_parser) = Getopt::Long::Parser -> new;

my(%option);

if ($option_parser -> getoptions
(
 \%option,
	'all=s',
	'help',
	'property_name=s'
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Garden::Design::Export::Pg -> new(%option) -> export_layouts;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

export.layouts.pl - Export various *.svg and *.html files.

=head1 SYNOPSIS

export.layouts.pl [options]

	Options:
	-all Yes or No
	-help
	-property_name aName

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

=item o property_name => aName

The name of the property for which all gardens will have their layouts exported.

Default: 'Ron'.

=back

=cut
