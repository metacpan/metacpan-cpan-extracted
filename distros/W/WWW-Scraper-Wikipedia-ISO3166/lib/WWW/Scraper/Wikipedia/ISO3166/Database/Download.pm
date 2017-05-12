package WWW::Scraper::Wikipedia::ISO3166::Database::Download;

use parent 'WWW::Scraper::Wikipedia::ISO3166::Database';
use feature 'say';
use strict;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.

use HTTP::Tiny;

use Moo;

use Types::Standard qw/Str/;

has code2 =>
(
	default  => sub{return 'AU'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has url =>
(
	default  => sub{return 'http://en.wikipedia.org/wiki/ISO_3166-1'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '2.00';

# -----------------------------------------------

sub get_1_page
{
	my($self, $url, $data_file) = @_;

	my($response) = HTTP::Tiny -> new -> get($url);

	if (! $$response{success})
	{
		$self -> log(error => "Failed to get $url");
		$self -> log(error => "HTTP status: $$response{status} => $$response{reason}");

		if ($$response{status} == 599)
		{
			$self -> log(error => "Exception message: $$response{content}");
		}

		# Return 0 for success and 1 for failure.

		return 1;
	}

	open(my $fh, '>', $data_file) || die "Can't open file: $data_file: $!\n";
	print $fh $$response{content};
	close $fh;

	$self -> log(debug => "Downloaded '$url' to '$data_file'");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_1_page.

# -----------------------------------------------

sub get_country_pages
{
	my($self) = @_;

	# Firstly, get the page of 3 letter country codes.

	my($url)	= $self -> url;
	my($result)	= $self -> get_1_page($url, $self -> data_file . '.html');

	$self -> log(info => "Result: $result. URL: $url. (0 is success)");

	# Secondly, get the page of country names.

	$url			=~ s/-1/-2/;
	my($data_file)	= $self -> data_file;
	$data_file		=~ s/-1/-2/;

	$result += $self -> get_1_page($url, $data_file . '.html');

	$self -> log(info => "Result: $result. URL: $url. (0 is success)");

	# Return 0 for success and 1 for failure.

	return $result;

} # End of get_country_pages.

# -----------------------------------------------

sub get_subcountry_page
{
	my($self)		= @_;
	my($code2)		= $self -> code2;
	my($url)		= $self -> url . ":$code2";
	$url			=~ s/-1/-2/;
	my($data_file)	= $self -> data_file;
	$data_file		=~ s/-1/-2/;

	my($result) = $self -> get_1_page($url, $self -> data_file . ".$code2.html");

	$self -> log(info => "Result: $result. URL: $url. (0 is success)");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_subcountry_page.

# -----------------------------------------------

sub get_subcountry_pages
{
	my($self) = @_;

	# %downloaded will contain 2-letter codes.

	my(%downloaded);

	my($downloaded)				= $self -> find_subcountry_downloads;
	@downloaded{@$downloaded}	= (1) x @$downloaded;
	my($countries)				= $self -> read_countries_table;
	my($count)					= 0;

	my(%countries);

	for my $id (keys %$countries)
	{
		if (! $downloaded{$$countries{$id}{code2} })
		{
			$count++;

			$self -> code2($$countries{$id}{code2});
			$self -> get_subcountry_page;

			sleep 5;
		}
	}

	$self -> log(info => "Download page count: $count");

	# Return 0 for success and 1 for failure.

	return 0;

} # End of get_subcountry_pages.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166::Database::Download - Download various pages from Wikipedia

=head1 Synopsis

See L<WWW::Scraper::Wikipedia::ISO3166/Synopsis>.

=head1 Description

Downloads these pages:

Input: L<http://en.wikipedia.org/wiki/ISO_3166-1>.

Output: data/en.wikipedia.org.wiki.ISO_3166-1.html.

Input: L<http://en.wikipedia.org/wiki/ISO_3166-2>.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.html.

Downloads each countries' corresponding subcountries page.

Source: http://en.wikipedia.org/wiki/ISO_3166:$code2.html.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

See scripts/get.country.pages.pl, scripts/get.subcountry.page.pl and scripts/get.subcountries.pages.pl.

Note: These pages have been downloaded, and are shipped with the distro.

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166::Database::Download>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166::Database::Download -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o code2 => $2_letter_code

Specifies the code2 of the country whose subcountry page is to be downloaded.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Methods

This module is a sub-class of L<WWW::Scraper::Wikipedia::ISO3166::Database> and consequently
inherits its methods.

=head2 code2($code)

Get or set the 2-letter country code of the country or subcountry being processed.

See L</get_subcountry_page()>.

Also, I<code2> is an option to L</new()>.

=head2 get_1_page($url, $data_file)

Download $url and save it in $data_file. $data_file normally takes the form 'data/*.html'.

=head2 get_country_pages()

Download the 2 country pages:

L<http://en.wikipedia.org/wiki/ISO_3166-1>.

L<http://en.wikipedia.org/wiki/ISO_3166-2>.

See L<WWW::Scraper::Wikipedia::ISO3166/Description>.

=head2 get_subcountry_page()

Download 1 subcountry page, e.g. http://en.wikipedia.org/wiki/ISO_3166:$code2.html.

Warning. The 2-letter code of the subcountry must be set with $self -> code2('XX') before calling this
method.

See L<WWW::Scraper::Wikipedia::ISO3166/Description>.

=head2 get_subcountry_pages()

Download all subcountry pages which have not been downloaded.

See L<WWW::Scraper::Wikipedia::ISO3166/Description>.

=head2 new()

See L</Constructor and initialization>.

=head1 FAQ

For the database schema, etc, see L<WWW::Scraper::Wikipedia::ISO3166/FAQ>.

=head1 References

See L<WWW::Scraper::Wikipedia::ISO3166/References>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=WWW::Scraper::Wikipedia::ISO3166>.

=head1 Author

C<WWW::Scraper::Wikipedia::ISO3166> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
