#!/usr/bin/perl

use common::sense;

use Getopt::Long;

use Pod::Usage;

use WWW::Scraper::Typo3;

# ------------------------------------------------

my($option_parser) = Getopt::Long::Parser -> new();

my(%option);

if ($option_parser -> getoptions
(
 \%option,
 'dir=s',
 'help',
 'verbose=i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Scraper::Typo3 -> new(%option) -> rename_files;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

rename.files.pl - Rename Typo3-based web site files.

=head1 SYNOPSIS

rename.files.pl [options]

    Options:
	-dir aDirName
	-help
	-verbose #

All switches can be reduced to a single letter.

Exit value: 0 (no error) or 1 (error).

Sample code:

    use WWW::Scraper::Typo3;

    WWW::Scraper::Typo3 -> new
    (
        dir     => '/dev/shm/homepage/a_project/',
        verbose => 1,
    ) -> rename_files;

=head1 OPTIONS

=over 4

=item -dir aDirName

The directory to work in.

The default value is ''.

This parameter is mandatory.

=item -help

Print help and exit.

=item -verbose #

Display more or less output.

This parameter is optional.

=back

=head1 DESCRIPTION

rename.files.pl - Rename Typo3-based web site files.

=cut
