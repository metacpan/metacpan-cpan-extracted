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
 'base_url=s',
 'help',
 'home_page=s',
 'host=s',
 'port=i',
 'verbose=i',
) )
{
	pod2usage(1) if ($option{'help'});

	exit WWW::Scraper::Typo3 -> new(%option) -> report_files;
}
else
{
	pod2usage(2);
}

__END__

=pod

=head1 NAME

report.files.pl - Clean up Typo3-based web site files.

=head1 SYNOPSIS

report.files.pl [options]

    Options:
	-base_url aURL
	-help
	-home_page aPageName
	-host aHostOrIP
	-port aPort
	-verbose #

All switches can be reduced to a single letter.

Exit value: 0 (no error) or 1 (error).

Sample code:

    use WWW::Scraper::Typo3;

    WWW::Scraper::Typo3 -> new
    (
        url     => 'http://127.0.0.1/index.html',
        verbose => 1,
    ) -> run;

=head1 OPTIONS

=over 4

=item -base_url aURL

The url to start with. A leading and trailing / is mandatory.

The default value is '/'.

This parameter is optional.

=item -help

Print help and exit.

=item -home_page aPageName

The home page name.

The default value is 'index.html'.

The parameter is optional.

=item -host aHostOrIP

The host name to use.

The default value is 127.0.0.1.

This parameter is optional.

=item -port aPort

The port number.

The default value is 80.

This parameter is optional.

=item -verbose #

Display more (1) or less (0) output.

The default value is 0.

This parameter is optional.

=back

=head1 DESCRIPTION

report.files.pl - Clean up Typo3-based web site files.

=cut
