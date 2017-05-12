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

	exit WWW::Scraper::Typo3 -> new(%option) -> patch_files;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

patch.files.pl - Patch Typo3-based web site files.

=head1 SYNOPSIS

patch.files.pl [options]

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
    ) -> run;

=head1 OPTIONS

=over 4

=item -dir aDirName

The directory to work in.

The default value is ''.

This parameter is mandatory.

=item -help

Print help and exit.

=item -verbose #

Display more (1) or less (0) output.

The default value is 0.

This parameter is optional.

=back

=head1 DESCRIPTION

patch.files.pl - Patch Typo3-based web site files.

=cut
