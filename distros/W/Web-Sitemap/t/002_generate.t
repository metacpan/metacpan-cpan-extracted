use strict;
use warnings;
use utf8;
use lib 't/lib';

use Test::More tests => 16;
use Web::Sitemap;
use File::Basename;
use SitemapTesters;

# try a carriage return - we should not care, so this should pass
my $index = <<"XML";
<?xml version="1.0" encoding="UTF-8"?>\r
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<sitemap><loc>/sitemap.test_tag.1.xml.gz</loc></sitemap>
<sitemap><loc>/sitemap.test_tag.2.xml.gz</loc></sitemap>
<sitemap><loc>/sitemap.test_tag.3.xml.gz</loc></sitemap>
<sitemap><loc>/sitemap.test_tag.4.xml.gz</loc></sitemap>
<sitemap><loc>/sitemap.with_images.1.xml.gz</loc></sitemap>
<sitemap><loc>/sitemap.with_images.2.xml.gz</loc></sitemap>
<sitemap><loc>/sitemap.with_images.3.xml.gz</loc></sitemap>
</sitemapindex>
XML

my $test_tag_1 = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://test.ru/</loc></url>
</urlset>
XML

my $test_tag_2 = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://test2.ru/</loc></url>
</urlset>
XML

my $test_tag_3 = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://test3.ru/</loc></url>
</urlset>
XML

my $test_tag_4 = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://test4.ru/</loc></url>
</urlset>
XML

my $with_images_1 = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://test1.ru/</loc>
<image:image><loc>http://img1.ru/</loc><caption><![CDATA[Вася - фото 1]]></caption></image:image>
<image:image><loc>http://img2.ru</loc><caption><![CDATA[Вася - фото 2]]></caption></image:image></url>
</urlset>
XML

my $with_images_2 = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://test11.ru/</loc>
<image:image><loc>http://img11.ru/</loc><caption><![CDATA[Вася - фото 1]]></caption></image:image>
<image:image><loc>http://img21.ru</loc><caption><![CDATA[Вася - фото 2]]></caption></image:image></url>
</urlset>
XML

my $with_images_3 = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
<url><loc>http://test122.ru/</loc>
<image:image><loc>http://img122.ru/</loc><caption><![CDATA[image #1]]></caption></image:image>
<image:image><loc>http://img133.ru/</loc><caption><![CDATA[image #2]]></caption></image:image>
<image:image><loc>http://img144.ru/</loc><caption><![CDATA[image #3]]></caption></image:image>
<image:image><loc>http://img222.ru</loc><caption><![CDATA[image #4]]></caption></image:image></url>
</urlset>
XML

my @urls = (
	'http://test.ru/',
	'http://test2.ru/',
	'http://test3.ru/',
	'http://test4.ru/'
);

my @img_urls = (
	{
		loc => 'http://test1.ru/',
		images => {
			caption_format =>
				sub { my ($iterator_value) = @_; return sprintf('Вася - фото %d', $iterator_value); },
			loc_list => ['http://img1.ru/', 'http://img2.ru']
		}
	},
	{
		loc => 'http://test11.ru/',
		images => {
			caption_format_simple => 'Вася - фото',
			loc_list => ['http://img11.ru/', 'http://img21.ru']
		}
	},
	{
		loc => 'http://test122.ru/',
		images => {
			loc_list => [
				{loc => 'http://img122.ru/', caption => 'image #1'},
				{loc => 'http://img133.ru/', caption => 'image #2'},
				{loc => 'http://img144.ru/', caption => 'image #3'},
				{loc => 'http://img222.ru', caption => 'image #4'}
			]
		}
	}
);

my $g = Web::Sitemap->new(
	output_dir => '..',    # we don't care
	url_limit => 1,
	file_size_limit => 200,
	move_from_temp_action => sub {
		my ($file, $dest) = @_;
		my $name = basename $dest;

		SitemapTesters::test_file($file, $index) if $name eq 'sitemap.xml';
		SitemapTesters::test_file($file, $test_tag_1) if $name eq 'sitemap.test_tag.1.xml.gz';
		SitemapTesters::test_file($file, $test_tag_2) if $name eq 'sitemap.test_tag.2.xml.gz';
		SitemapTesters::test_file($file, $test_tag_3) if $name eq 'sitemap.test_tag.3.xml.gz';
		SitemapTesters::test_file($file, $test_tag_4) if $name eq 'sitemap.test_tag.4.xml.gz';
		SitemapTesters::test_file($file, $with_images_1) if $name eq 'sitemap.with_images.1.xml.gz';
		SitemapTesters::test_file($file, $with_images_2) if $name eq 'sitemap.with_images.2.xml.gz';
		SitemapTesters::test_file($file, $with_images_3) if $name eq 'sitemap.with_images.3.xml.gz';
	},
);

$g->add(\@urls, tag => 'test_tag');
$g->add(\@img_urls, tag => 'with_images');
$g->finish;
