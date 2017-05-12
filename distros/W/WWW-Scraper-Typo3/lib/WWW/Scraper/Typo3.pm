package WWW::Scraper::Typo3;

use common::sense;

use File::chdir;
use File::Copy;  # For move.
use File::Slurp; # For read_dir and read_file.
use File::Temp;

use HTML::TreeBuilder;

use LWP::Simple;

use Moose;

has base_url =>
(
 is => 'rw',
 isa => 'Str',
 required => 0,
 default => '/',
);

has dir =>
(
 is => 'rw',
 isa => 'Str',
 required => 0,
 default => '',
);

has home_page =>
(
 is => 'rw',
 isa => 'Str',
 required => 0,
 default => 'index.html',
);

has host =>
(
 is => 'rw',
 isa => 'Str',
 required => 0,
 default => '127.0.0.1',
);

has port =>
(
 is => 'rw',
 isa => 'Int',
 required => 0,
 default => 80,
);

has verbose =>
(
 is => 'ro',
 isa => 'Int',
 required => 0,
 default => 0,
);

our %image;
our %link;
our %seen;

our $VERSION = '1.01';

# -----------------------------------------------

sub build_url
{
	my($self, $host, $port, $base_url) = @_;

	return "http://$host:$port$base_url";

} # End of build_url.

# -----------------------------------------------
# Return $href for success and '' for failure.

sub get_attributes
{
	my($self, $base, $key, $a) = @_;
	my($href) = $a -> attr('href');

	# The '@' picks up mailto:..@.. which has been transformed.

	return '' if ( ($href =~ /@/) || $seen{$href});

	$seen{$href} = 1;

	if (! $link{$base})
	{
		$link{$base} = {};
	}

	my($text)          = $self -> transform_text($a -> as_text);
	$link{$key}{$text} = "$base$href";

	return $href;

} # End of get_attributes.

# -----------------------------------------------
# Return $tree for success and 1 for failure.

sub get_page
{
	my($self, $url) = @_;
	my($store)      = File::Temp -> new -> filename;
	my($response)   = LWP::Simple::getstore($url, $store);

	if ($response ne '200')
	{
		$self -> log('Unable to retrieve url ' . $url);

		return 0;
	}

	return HTML::TreeBuilder -> new -> parse_file($store);

} # End of get_page.

# -----------------------------------------------

sub log
{
	my($self, $message) = @_;
	$message ||= '';

	if ($self -> verbose)
	{
		print "$message\n";
	}

} # End of log.

# -----------------------------------------------

sub parse
{
	my($self, $base, $page, $doc, $tree, $level) = @_;

	$self -> parse_tbody($base, $page, $doc, $tree, $level);
	$self -> parse_img($base, $page, $doc, $tree);
 
} # End of parse.

# -----------------------------------------------

sub parse_img
{
	my($self, $base, $page, $doc, $tree) = @_;
	my(@image) = $tree -> find_by_tag_name('img');

	my($dt);
	my($href);
	my($path);
	my($s);

	for my $image (@image)
	{
		$href = $image -> attr('src');

		next if ($seen{$href} || ($href !~ /typo3temp/) );

		$seen{$href}        = 1;
		$image{$doc}{$href} = '-';
		$dt                 = $image -> look_up(_tag => 'dt');

		if ($dt)
		{
			$s = $dt -> find_by_tag_name(a => 'href');

			if ($s)
			{
				$path = $s -> attr('onclick');

				if ($path)
				{
					$path               =~ s|.+file=(uploads.+?)&.+|$1|;
					$path               =~ s|%2F|/|g;
					$image{$doc}{$href} = "$base$path";
				}
			}
		}
	}

} # End of parse_img.

# -----------------------------------------------

sub parse_tbody
{
	my($self, $base, $page, $doc, $tree, $level)  = @_;
	my(@tbody) = $tree -> find_by_tag_name('tbody');

	my(@a, $a);
	my($href);
	my($sub_tree, $sub_url);

	for my $tbody (@tbody)
	{
		@a = $tbody -> find_by_tag_name('a');

		for $a (@a)
		{
			$href = $self -> get_attributes($base, $doc, $a);

			next if ($href eq '');

			$self -> log("Switching to $base$href");

			$sub_url  = $self -> build_url($self -> host, $self -> port, $base);
			$sub_tree = $self -> get_page("$sub_url$href");

			if ($sub_tree)
			{
				$self -> parse($base, $href, "$base$href", $sub_tree, $level + 1);
				$sub_tree -> delete;
			}
		}
	}

} # End of parse_tbody.

# -----------------------------------------------

sub patch_files
{
	my($self)  = @_;
	local $CWD = $self -> dir;

	my(@line, $line);

	for my $file (read_dir('.') )
	{
		next if ( ($file !~ /id\.(?:\d+).html$/) && ($file ne $self -> home_page) );

		@line = read_file($file);

		for $line (@line)
		{
			$line =~ tr/\cM//d;

			next if ($line !~ /tbody/);

			$line =~ s|</a></tr></tr>|</a></td></tr>|g;
			$line =~ s|(index.php\?id=\d+)|$self->transform_href($1)|eg;
		}

		write_file($file, @line);
	}

	return 0;

} # End of patch_files.

# -----------------------------------------------

sub rename_files
{
	my($self)  = @_;
	local $CWD = $self -> dir;
	my(@file)  = read_dir('.');

	my($new_name);

	for my $file (@file)
	{
		next if ($file !~ /index\.php\?id=(?:\d+)$/);

		$new_name = $self -> transform_href($file);

		if (move $file, $new_name)
		{
			$self -> log("Renamed $file to $new_name");
		}
		else
		{
			$self -> log("Failed to rename $file to $new_name: $!");
		}
	}

	return 0;

} # End of rename_files.

# -----------------------------------------------

sub report
{
	my($self) = @_;

	my($href);
	my($url);

	for $url (sort keys %link)
	{
		for $href (sort keys %{$link{$url} })
		{
			$self -> log("$url '$href' links to $link{$url}{$href}");
		}
	}

	for $url (sort keys %image)
	{
		for $href (sort keys %{$image{$url} })
		{
			$self -> log("$url links to $href");
		}
	}

} # End of report.

# -----------------------------------------------
# Return 0 for success and 1 for failure.

sub report_files
{
	my($self) = @_;

	if ($self -> base_url !~ m|^/|)
	{
		$self -> base_url('/' . $self -> base_url);
	}

	if ($self -> base_url !~ m|/$|)
	{
		$self -> base_url($self -> base_url . '/');
	}

	my($base) = $self -> build_url($self -> host, $self -> port, $self -> base_url);
	my($page) = $self -> home_page;
	my($doc)  = "$base$page";

	$self -> log("Starting from $doc");

	my($tree)   = $self -> get_page($doc);
	my($result) = $tree ? 0 : 1;

	if ($tree)
	{
		$self -> parse($self -> base_url, $page, $doc, $tree, 0);
		$tree -> delete;
		$self -> report;
	}

	return $result;

} # End of report_files.

# -----------------------------------------------

sub transform_href
{
	my($self, $href)     = @_;
	$href                =~ tr/?=/../;
	substr($href, 0, 10) = ''; # Zap /^index.php./.
	$href                .= '.html';

	return $href;

} # End of transform_href.

# -----------------------------------------------

sub transform_text
{
	my($self, $text) = @_;
	$text =~ s/^\s+//;
	$text =~ s/\s+$//;

	return $text;

} # End of transform_text.

# -----------------------------------------------

1;

__END__

=pod

=head1 NAME

C<WWW::Scraper::Typo3> - Clean up files managed by the CMS called Typo3

=head1 Synopsis

Note: The code assumes you are running a web server locally, so the scripts
can both read and write files, and use LWP::Simple::getstore to process files.

	cd ~/misc
	wget -o wget.log --limit-rate=100k -w 4 -r -k -P tewoaf -E -p http://tewoaf.org.au
	cd tewoaf
	rm *eID* # This removes pop-up files generated by clicking on images.
	cd $DR   # This is doc root for your web server.
	rm -rf tewoaf
	cp -r ~/misc/tewoaf
	cd ~/perl.modules/WWW-Scraper-Typo3
	perl scripts/rename.files.pl -d $DR/tewoaf -v 1
	perl scripts/patch.files.pl -d $DR/tewoaf -v 1
	perl scripts/report.files.pl -b /tewoaf -v 1

patch.files.pl is the only program which overwrites files.

=head1 Description

C<WWW::Scraper::Typo3> is a pure Perl module.

It processes the set of files downloaded from a web site whose files are managed by
the CMS called Typo3.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing.

=head1 Constructor and initialization

new(...) returns an object of type C<WWW::Scraper::Typo3>.

This is the class's contructor.

Usage: C<< WWW::Scraper::Typo3 -> new() >>.

This method takes a hash of options.

Call C<new()> as C<< new(option_1 => value_1, option_2 => value_2, ...) >>.

Available options:

=over 4

=item base_url aURL

The script report.files.pl uses "http://$host:$port$base_url$home_page" as the URL
where processing starts.

If necessary, both a leading '/' and a trailing '/' are added to the value you supply.

The default value is '/'.

This parameter is mandatory for the script report.files.pl.

=item dir aDirName

This option is used by the 2 scripts rename.files.pl and patch.files.pl.

It is the directory where these scripts read and write files.

From the synopsis, you can see I suggest you download the site's files to a directory
outside your local web server's doc root, and work on a copy of the files within that
doc root.

The default value is ''.

This parameter is optional.

=item home_page aHTMLFileName

The name of the home page of the site.

The default value is index.html.

This parameter is mandatory for the script report.files.pl.

=item host aHostName

The domain name or IP address of the host.

The default value is 127.0.0.1.

This parameter is mandatory for the script report.files.pl.

=item post aPortNumber

The number of the port to use.

The default value is 80.

This parameter is mandatory for the script report.files.pl.

=item verbose #

Display more (1) or less (0) output.

The default is 0.

This parameter is optional.

=back

=head1 Method: patch_files()

Run the code which patches various aspects of Typo3-managed files.

See scripts/patch.files.pl.

=head1 Method: rename_files()

Run the code which renames Typo3-managed files.

See scripts/rename.files.pl.

=head1 Method: report_files()

Run the code which reports on various aspects of Typo3-managed files.

See scripts/report.files.pl.

=head1 Author

C<WWW::Scraper::Typo3> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 20010 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
