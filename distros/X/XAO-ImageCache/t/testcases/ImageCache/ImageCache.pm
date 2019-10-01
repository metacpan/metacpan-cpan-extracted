package testcases::ImageCache::ImageCache;
use strict;
use XAO::Utils;
use XAO::ImageCache;
use Data::Dumper;
use Error qw(:try);

use base qw(testcases::ImageCache::base);

my %params = (
    reload         => 1,
    source_path    => 'tmp/cache/source',
    cache_path     => 'tmp/cache/images',
    cache_url      => 'http://localhost/images',
    source_url_key => 'source_image_url',
    dest_url_key   => 'dest_image_url',
    thumbnails     => {
                          source_url_key => 'source_thumbnail_url',
                          cache_path     => "tmp/cache/thumbnails",
                          cache_url      => 'http://localhost/thumbnails',
                          dest_url_key   => 'thumbnail_url',
                          dest_url_key   => 'dest_thumbnail_url',
                          geometry       => "25%",
                      },
);

###############################################################################

sub test_cache {
    my $self      = shift;
    my $odb       = $self->get_odb;
    my $img_cache = XAO::ImageCache->new(
                        %params,
                        list => $odb->fetch('/Products'),
                    );
    $self->assert(defined($img_cache),          'ImageCache object creation failure!');
    $self->assert(defined($img_cache->init()),  'Image Cache initialization failure!');
    $self->assert((-d $params{cache_path}),     'Can\'t create cache directory!');
    $self->assert(defined($img_cache->check()), 'Image Cache checking failure!');

    my $prod = $odb->fetch('/Products')->get('p1');
    $self->assert(defined($prod), 'Can\'t get data object drom XAO FS!');

    my $dest_url   = $prod->get($params{dest_url_key});
    my $cache_file = XAO::ImageCache::get_filename($prod->get($params{source_url_key}));
    $cache_file    = $params{cache_url}."/".$cache_file."_img.jpeg";

    $self->assert(($dest_url eq $cache_file), "Cached image URL ($dest_url) not equal to $cache_file");
}

###############################################################################
1;
