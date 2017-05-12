package WWW::Scraper::Wikipedia::ISO3166;

require v5.10.1;
use strict;
use warnings;

use File::ShareDir;
use File::Spec;

use Log::Handler;

use Moo;

use Types::Standard qw/Any Int Str/;

has config_file =>
(
	default  => sub{return '.htwww.scraper.wikipedia.iso3166.conf'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has data_file =>
(
	default  => sub{return 'data/en.wikipedia.org.wiki.ISO_3166-1'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has share_dir =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has sqlite_file =>
(
	default  => sub{return 'www.scraper.wikipedia.iso3166.sqlite'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '2.00';

# -----------------------------------------------

sub BUILD
{
	my($self)		= @_;
	(my $package	= __PACKAGE__) =~ s/::/-/g;
	my($dir_name)	= $ENV{AUTHOR_TESTING} ? 'share' : File::ShareDir::dist_dir($package);

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
				utf8           => 1,
			}
		);
	}

	$self -> config_file(File::Spec -> catfile($dir_name, $self -> config_file) );
	$self -> sqlite_file(File::Spec -> catfile($dir_name, $self -> sqlite_file) );

} # End of BUILD.

# -----------------------------------------------

sub log
{
	my($self, $level, $s) = @_;
	$level = 'notice' if (! defined $level);
	$s     = ''       if (! defined $s);

	$self -> logger -> $level($s) if ($self -> logger);

}	# End of log.

# -----------------------------------------------

1;

=pod

=head1 NAME

WWW::Scraper::Wikipedia::ISO3166 - Gently scrape Wikipedia for ISO3166-2 data

=encoding utf-8

=head1 Synopsis

Wikipedia I<has been scraped>. You do not need to run the scripts which download pages from there.

Just use the SQLite database shipped with this module, share/www.scraper.wikipedia.iso3166.sqlite.

See scripts/export.*.pl and scripts/get.*.pl for sample code.

=head2 Methods which return hashrefs

	use WWW::Scraper::Wikipedia::ISO3166::Database;

	my($database)     = WWW::Scraper::Wikipedia::ISO3166::Database -> new;
	my($countries)    = $database -> read_countries_table;
	my($subcountries) = $database -> read_subcountries_table;
	my($categories)   = $database -> read_subcountry_categories_table;
	my($types)        = $database -> read_subcountry_info_table;
	...

Each key in returned C<hashrefs> points to a hashref of all columns for the given key.

So, $$countries{13} points to this hashref:

	{
		id                => 13,
		code2             => 'AU',
		code3             => '',
		fc_name           => 'australia',
		hash_subcountries => 'Yes',
		name              => 'Australia',
		number            => '036',
		timestamp         => '2012-05-08 04:04:43',
	}

One element of %$subcountries is $$subcountries{941}:

	{
		id                     => 941,
		country_id             => 13,
		code                   => 'AU-VIC',
		fc_name                => 'victoria',
		name                   => 'Victoria',
		sequence               => 7,
		subcountry_category_id => 8,
		timestamp              => '2012-05-08 04:05:27',
	}

=head3 Warnings

These hashrefs use the table's primary key as the hashref's key. In the case of the I<countries>
table, the primary key is the country's id, and is used as subcountries.country_id. But, in the case of
the I<subcountries> table, the id does not have any meaning apart from being a db primary key.
See L</What is the database schema?> for details.

=head2 Scripts which output to a file

Note: Many of these programs respond to the -h command line switch, but not create.tables.pl nor
drop.tables.pl.

Some examples:

	shell> perl scripts/export.as.csv.pl -c countries.csv -s subcountries.csv
	shell> perl scripts/export.as.html.pl -w iso.3166-2.html
	shell> perl -Ilib scripts/populate.countries.pl -maxlevel debug
	shell> perl -Ilib scripts/populate.subcountries.pl -maxlevel debug

The HTML file is on-line at: L<http://savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/iso.3166-2.html>.

	shell>perl scripts/report.statistics.pl

	Output statistics:
	countries_in_db => 249
	has_subcounties => 200
	subcountries_in_db => 5297
	subcountry_files_downloaded => 249
	subcountry_info_in_db => 352

See also scripts/report.*.pl and t/report.t.

=head1 Description

C<WWW::Scraper::Wikipedia::ISO3166> is a pure Perl module.

It is used to download various ISO3166-related pages from Wikipedia, and to then import data
(scraped from those pages) into an SQLite database.

The pages have already been downloaded, so that phase only needs to be run when pages are updated.

Likewise, the data has been imported.

This means you would normally only ever use the database in read-only mode.

Note: Many of these programs respond to the -h command line switch, but not create.tables.pl nor
drop.tables.pl.

Scripts, all shipped in scripts/:

=over 4

=item o build.database.sh

Mainly for use by me. It runs:

=over 4

=item o perl -Ilib scripts/drop.tables.pl

=item o perl -Ilib scripts/create.tables.pl

=item o perl -Ilib scripts/populate.countries.pl -maxlevel debug

=item o perl -Ilib scripts/populate.subcountries.pl -maxlevel debug

=item o perl -Ilib scripts/export.as.html.pl -w data/iso.3166-2.html

=item o cp data/iso.3166-2.html $DR/

$DR is my web site's RAMdisk-based doc root.

=item perl -Ilib scripts/export.as.csv.pl \

=back

=item o check.downloads.pl

Ensure each subcountry file has been downloaded, and report any which haven't been. Also report
and unexpected subcountry files found in data/.

=item o perl -Ilib scripts/create.tables.pl

=item o perl -Ilib scripts/drop.tables.pl

=item o export.as.csv.pl -country_file c.csv -subcountry_file s.csv subcountry_info_file i.csv

Exports the country, subcountry and subcountry info data as CSV.

Input: share/www.scraper.wikipedia.iso3166.sqlite.

Output: data/countries.csv and data/subcountries.csv.

=item o export.as.html -w c.html

Exports the country and subcountry data as HTML.

Input: share/www.scraper.wikipedia.iso3166.sqlite.

Output: data/iso.3166-2.html.

On-line: L<http://savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/iso.3166-2.html>.

=item o find.db.pl

After installation, this will print the path to www.scraper.wikipedia.iso3166.sqlite.

=item o get.country.pages.pl

1: Downloads the ISO3166-1 and ISO3166-2 pages from Wikipedia.

Input: L<https://en.wikipedia.org/wiki/ISO_3166-1> and
<https://en.wikipedia.org/wiki/ISO_3166-2>.

Output: data/en.wikipedia.org.wiki.ISO_3166-1.html and data/en.wikipedia.org.wiki.ISO_3166-2.html.

=item o get.subcountry.page.pl and scripts/get.subcountry.pages.pl

Downloads each countries' corresponding subcountries page.

Source: http://en.wikipedia.org/wiki/ISO_3166:$code2.html.

Output: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

=item o pod2html.sh

For use by the author. It converts each *.pm file into the corresponding *.html file, and outputs
them to my web server's doc root.

=item o populate.countries.pl

Imports country data into an SQLite database.

Input: data/en.wikipedia.org.wiki.ISO_3166-1.html, data/en.wikipedia.org.wiki.ISO_3166-2.html.

Output: share/www.scraper.wikipedia.iso3166.sqlite.

=item o populate.subcountry.pl and scripts/populate.subcountries.pl

Imports subcountry data into the database.

Source: data/en.wikipedia.org.wiki.ISO_3166-2.$code2.html.

Output: share/www.scraper.wikipedia.iso3166.sqlite.

Note: When the distro is installed, this SQLite file is installed too.
See L</Where is the database?> for details.

=item o report.Australian.statistics.pl

A simple test program. See also the next script.

Run it with the '-max info' command line options.

=item o report.statistics.pl

A simple test program. See also the previous script.

Run it with the '-max info' command line options.

=back

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Wikipedia::ISO3166>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Wikipedia::ISO3166 -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options (these are also methods):

=over 4

=item o config_file => $file_name

The name of the file containing config info, such as I<css_url> and I<template_path>.
These are used by L<WWW::Scraper::Wikipedia::ISO3166::Database::Export/as_html()>.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Default: .htwww.scraper.wikipedia.iso3166.conf.

=item o logger => $aLoggerObject

Specify a logger compatible with L<Log::Handler>, for the lexer and parser to use.

Default: A logger of type L<Log::Handler> which writes to the screen.

To disable logging, just set 'logger' to the empty string (not undef).

=item o maxlevel => $logOption1

This option affects L<Log::Handler>.

Possible values for C<maxlevel> and C<minlevel> are:

=over 4

=item o debug

Generates the maximum amount of output.

=item o info

=item o notice

By default, C<notice> is the highest level used.

=item o warning, warn

=item o error, err

By default, C<error> is the lowest level used.

=item o critical, crit

=item o alert

=item o emergency, emerg

=back

See the L<Log::Handler::Levels> docs.

Default: 'notice'.

=item o minlevel => $logOption2

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

Default: 'error'.

No lower levels are used.

=item o sqlite_file => $file_name

The name of the SQLite database of country and subcountry data.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

Default: www.scraper.wikipedia.iso3166.sqlite.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

Install WWW::Scraper::Wikipedia::ISO3166 as you would for any C<Perl> module:

Run:

	cpanm WWW::Scraper::Wikipedia::ISO3166

or run:

	sudo cpan WWW::Scraper::Wikipedia::ISO3166

or unpack the distro, and then run:

	perl Makefile.PL
	make (or dmake)
	make test
	make install

See L<http://savage.net.au/Perl-modules.html> for details.

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing.

=head1 Methods

=head2 config_file($file_name)

Get or set the name of the config file.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

C<config_file> is an option to L</new()>.

=head2 log($level, $s)

If a logger is defined, this logs the message $s at level $level.

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set 'logger' to the empty string (not undef), in the call to L</new()>.

This logger is passed to other modules.

C<logger> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is ceated.
See L<Log::Handler::Levels>.

C<maxlevel> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created.
See L<Log::Handler::Levels>.

C<minlevel> is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 new()

See L</Constructor and initialization>.

=head2 sqlite_file($file_name)

Get or set the name of the database file.

The code prefixes this name with the directory returned by L<File::ShareDir/dist_dir()>.

C<sqlite_file> is an option to L</new()>.

=head1 FAQ

=head2 Design faults in ISO3166

Where ISO3166 uses Country Name, I would have used C<Long Name> and C<Short Name>.

Then we'd have:

	Long Name:  Bolivia (Plurinational State of)
	Short Name: Bolivia

This distro uses the values directly from Wikipedia, which is what I have called C<Long Name> above,
for all country and subcountry names.

=head2 Are any names modified by the code?

Yes. &#39; is converted into a single quote.

=head2 Where is the database?

It is shipped in share/www.scraper.wikipedia.iso3166.sqlite.

It is installed into the distro's shared dir, as returned by L<File::ShareDir/dist_dir()>.
Run scripts/find.db.pl to see what dir it is on your machine.

On my machine it's:

/home/ron/perl5/perlbrew/perls/perl-5.20.2/lib/site_perl/5.20.2/auto/share/dist/WWW-Scraper-Wikipedia-ISO3166/www.scraper.wikipedia.iso3166.sqlite

=head2 What is the database schema?

A single SQLite file holds 4 tables:

	countries           subcountries              subcountry_categories    subcountry_info
	---------           ------------              ---------------------    ---------------
	id                  id                        id                       id
	code2               country_id                name                     country_id
	code3               subcountry_category_id    timestamp                name
	fc_name             fc_name                                            sequence
	has_subcountries    code                                               timestamp
	name                name
	number              sequence
	timestamp           timestamp

An SVG image of the schema is shipped as data/www.scraper.wikipedia.iso3166.schema.svg,
and is L<on-line|http://savage.net.au/assets/images/modules/WWW/Scraper/Wikipedia/ISO3166/www.scraper.wikipedia.iso3166.schema.svg>.

The schema of the C<countries> table is basically taken straight from the big table on
L<ISO_3166-1|https://en.wikipedia.org/wiki/ISO_3166-1>. Likewise for the subcountry_info table,
it's taken from L<ISO_3166-2|https://en.wikipedia.org/wiki/ISO_3166-2>.

I<subcountries.country_id> points to I<countries.id>.

I<fc_name> is output from calling fc($name). It's in UTF-8.

For decode(), see L<Encode/THE PERL ENCODING API>.

For fc(), see L<Unicode::CaseFold/fc($str)>.

$name is from a Wikipedia page.

I<has_subcountries> is 'Yes' or 'No'.

I<name> is in UTF-8.

I<number> is the 3-digit number from the ISO_3166-1 page.

I<sequence> is a number (1 .. N) indicating the order in which records for the same country_id
should be accessed.

See the source code of L<WWW::Scraper::Wikipedia::ISO3166::Database::Create> for details of the SQL
used to create the tables.

Lastly, in L<WWW::Scraper::Wikipedia::ISO3166::Database>, there are 4 methods for reading the 4
tables, as well as various more general methods.

=head2 A Warning about Creating the Database

See also L</What is $ENV{AUTHOR_TESTING} used for?> below.

If you run scripts/drop.tables.pl and scripts/create.tables.pl before running
scripts/populate.countries.pl and scripts/populate.subcountries, then the primary keys in the
tables will start from 1. This is good because it preempts a source of confusion.

Without that step, L<SQLite|sqlite.org> will simply increment the primary keys starting from 1
more than was previously used.

=head2 What do I do if I find a mistake in the data?

What data? What mistake? How do you know it's wrong?

Also, you must decide what exactly you were expecting the data to be.

If the problem is the ISO data, report it to them.

If the problem is the Wikipedia data, get agreement from everyone concerned and update Wikipedia.

If the problem is the output from my code, try to identify the bug in the code and report it via the
usual mechanism. See L</Support>.

If the problem is with your computer's display of the data, consider (in alphabetical order):

=over 4

=item o CSV

Does the file display correctly in 'Emacs'? On the screen using 'less'?

scripts/export.as.csv.pl uses: use open ':utf8';

Is that not working?

=item o DBD::SQLite

Did you set the sqlite_unicode attribute? Use something like:

	my($dsn)        = 'dbi:SQLite:dbname=www.scraper.wikipedia.iso3166.sqlite'; # Sample only.
	my($attributes) = {AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1};
	my($dbh)        = DBI -> connect($dsn, '', '', $attributes);

The SQLite file ships in the share/ directory of the distro, and must be found by File::ShareDir
at run time.

Did you set the foreign_keys pragma (if needed)? Use:

	$dbh -> do('PRAGMA foreign_keys = ON');

=item o HTML

The template htdocs/assets/templates/www/scraper/wikipedia/iso3166/iso3166.report.tx which ships with
this distro contains this line:

	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />

Is that not working?

=item o Locale

Here's my setup:

	shell>locale
	LANG=en_AU.utf8
	LANGUAGE=
	LC_CTYPE="en_AU.utf8"
	LC_NUMERIC="en_AU.utf8"
	LC_TIME="en_AU.utf8"
	LC_COLLATE="en_AU.utf8"
	LC_MONETARY="en_AU.utf8"
	LC_MESSAGES="en_AU.utf8"
	LC_PAPER="en_AU.utf8"
	LC_NAME="en_AU.utf8"
	LC_ADDRESS="en_AU.utf8"
	LC_TELEPHONE="en_AU.utf8"
	LC_MEASUREMENT="en_AU.utf8"
	LC_IDENTIFICATION="en_AU.utf8"
	LC_ALL=

=item o OS

Unicode is a moving target. Perhaps your OS's installed version of unicode files needs updating.

=item o SQLite

Both Oracle and SQLite.org ship a program called sqlite3. They are not compatible.
Which one are you using? I use the one from the SQLite.org.

AFAICT, sqlite3 does not have command line options, or options while running, to set unicode or pragmas.

=back

=head2 Why did you use L<Unicode::Normalize>'s fc() for sorting?

See L<http://www.perl.com/pub/2012/04>, and specifically prescription # 1.

See also section 1.2 Normalization Forms in L<http://www.unicode.org/reports/tr15/>.

See also L<http://www.unicode.org/faq/normalization.html>.

=head2 What is $ENV{AUTHOR_TESTING} used for?

When this env var is 1, scripts output to share/*.sqlite within the distro's dir. That's how I populate the
database tables. After installation, the database is elsewhere, and read-only, so you don't want the scripts
writing to that copy anyway.

At run-time, L<File::ShareDir> is used to find the installed version of *.sqlite.

=head1 Wikipedia's Terms of Use

See L<http://wikimediafoundation.org/wiki/Terms_of_use>.

Also, since I'm distributing copies of Wikipedia-sourced material, reformatted but not changed by editing,
I hereby give notice that their material is released under CC-BY-SA.
See L<http://creativecommons.org/licenses/by-sa/3.0/> for that licence.

=head1 See Also

L<Locale::Codes> by Sullivan Beck.

=head1 References

In no particular order:

L<http://en.wikipedia.org/wiki/ISO_3166-1>

L<http://en.wikipedia.org/wiki/ISO_3166-2>

L<http://savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/iso.3166-2.html>

L<http://www.statoids.com/>

L<http://unicode.org/Public/cldr/latest/core.zip>

This is complex set of XML files concerning currency, postal, etc, formats and other details for various countries
and/or languages.

For Debian etc users: /usr/share/xml/iso-codes/iso_3166_2.xml, as installed from the iso-codes package, with:

	sudo apt-get install iso-codes

L<http://geonames.org>

L<http://www.geonames.de/index.html>

L<http://www.perl.com/pub/2012/04>

Check the Monthly Archives at Perl.com, starting in April 2012, for a series of Unicode-specific articles by
Tom Christiansen.

L<http://www.unicode.org/reports/tr15/>

L<http://www.unicode.org/faq/normalization.html>

=head1 Repository

L<https://github.com/ronsavage/WWW-Scraper-Wikipedia-ISO3166.git>

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
