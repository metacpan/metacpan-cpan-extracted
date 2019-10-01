#!/usr/bin/env perl
use warnings;
use strict;
use blib;
use XAO::Objects;
use XAO::ImageCache;

###############################################################################
# Making test database
my $odb=init_data();

###############################################################################
# XAO ImageCache class creation with cache structure
# autocreate and images downloading into cache.
#
my $img_cache = XAO::ImageCache->new(
    list            => $odb->fetch("/Products"),
    source_path     => "./cache/source",
    cache_path      => "./cache/images",
    cache_url       => "http://localhost/images",
    source_url_key  => "source_image_url",
    dest_url_key    => "dest_image_url",
    autocreate      => 1,
    reload          => 1,
    size            => {
        width             => 320,
        height            => 240,
        save_aspect_ratio => 1,
    },
    thumbnails      => {
            cache_path     => "./cache/thumbnails",
            cache_url      => '/images/products/thumbnails',
           #source_url_key => 'thumbnail_url_source',
            dest_url_key   => 'thumbnail_url',
            geometry => "25%",
    }
) || die "Image cache failure!";

# That's all!
1;

###############################################################################
# Test database creation.
#
# Images from Apache server 'Welcome' page from 'localhost'
# used for download test. Use your own URLs if you have no
# Apache installed on.
#
sub init_data {

    my %d;

    if (open(F,'.config')) {
        local($/);
        my $t=<F>;
        close(F);
        eval $t;
    }
    else {
        print "Can't open configuration file!\n$!";
    }

    my $odb = XAO::Objects->new(
        objname        => 'FS::Glue',
        dsn            => $d{test_dsn},
        user           => $d{test_user},
        password       => $d{test_password},
        empty_database => 'confirm',
    ) || die "Foundation Server initialization failure!";

    my $global = $odb->fetch('/');

    my %global_structure=(
        Products => {
            type      => 'list',
            class     => 'Data::Product',
            key       => 'id',
            structure => {
                name             => {
                        type        => 'text',
                        maxlength   => 50,
                },
                source_image_url => {
                        type        => 'text',
                        maxlength   => 50,
                },
                dest_image_url   => {
                        type        => 'text',
                        maxlength   => 50,
                },
            },
        }
    );

    $global->build_structure(\%global_structure);

    my $plist=$odb->fetch('/Products');

    my $product=$plist->get_new();

    $product->put(name => "Test product 0");
    $product->put(source_image_url => "http://localhost/icons/apache_pb.gif");
    $product->put(dest_image_url => "");
    $plist->put(p0 => $product);

    $product->put(name => "Test product 1");
    $product->put(source_image_url => "http://localhost/icons/medbutton.png");
    $product->put(dest_image_url => "");
    $plist->put(p1 => $product);

    $product->put(name => "Test product 2");
    $product->put(source_image_url => "http://localhost/icons/sgi_performance.gif");
    $product->put(dest_image_url => "");
    $plist->put(p2 => $product);

    $product->put(name => "Test product 3");
    $product->put(source_image_url => "http://localhost/icons/logo.gif");
    $product->put(dest_image_url => "");
    $plist->put(p3 => $product);

    $product->put(name => "Test product 4");
    $product->put(source_image_url => "http://localhost/icons/netmin.gif");
    $product->put(dest_image_url => "");
    $plist->put(p4 => $product);

    return $odb;
}
###############################################################################
