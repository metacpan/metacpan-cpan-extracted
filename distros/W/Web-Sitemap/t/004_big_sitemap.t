use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More tests => 6;
use Web::Sitemap;
use File::Basename;
use SitemapTesters;

my $index = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<sitemap><loc>/sitemap.t.1.xml.gz</loc></sitemap>
<sitemap><loc>/sitemap.t.2.xml.gz</loc></sitemap>
</sitemapindex>
XML

my @urls = map { "/some/location/$_" } 1 .. 50_037;

my @output_files;
my $per_file = 50_000;

for (0 .. 1) {
	my $files_xml = join "\n",
		map { "<url><loc>$_</loc></url>" }
		grep { defined }
		@urls[$per_file * $_ .. $per_file * ($_ + 1) - 1]
		;

	push @output_files, <<"XML" if $files_xml;
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
$files_xml
</urlset>
XML

}

my $g = Web::Sitemap->new(
	output_dir => '..',    # we don't care
	default_tag => 't',
	move_from_temp_action => sub {
		my ($file, $dest) = @_;
		my $name = basename $dest;

		SitemapTesters::test_file($file, $index) if $name eq 'sitemap.xml';
		if ($name =~ m{sitemap\.t\.(\d+).xml.gz}) {
			my $ind = $1 - 1;

			if (!defined $output_files[$ind]) {
				fail "more files found than expected ($name)";
			}
			else {
				SitemapTesters::test_big_file($file, $output_files[$ind]);
			}
		}
	},
);

# urls got autovivifies with undefs, so we have to grep
$g->add([grep { defined } @urls]);
$g->finish;
