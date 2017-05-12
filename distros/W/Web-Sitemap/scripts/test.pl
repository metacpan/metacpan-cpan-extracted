#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib $FindBin::Bin. '/../lib';

use Web::Sitemap;


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
			caption_format => sub { my ($iterator_value) = @_; return sprintf('Вася - фото %d', $iterator_value); },
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
				{ loc => 'http://img122.ru/', caption => 'image #1' },
				{ loc => 'http://img133.ru/', caption => 'image #2' },
				{ loc => 'http://img144.ru/', caption => 'image #3' },
				{ loc => 'http://img222.ru', caption => 'image #4' }
			] 
		} 
	}
);

my $g = Web::Sitemap->new(
	output_dir => $FindBin::Bin,
	url_limit => 1,
	file_size_limit => 200
);

$g->add(\@urls, tag => 'test_tag');
$g->add(\@img_urls, tag => 'with_images');
$g->finish;
