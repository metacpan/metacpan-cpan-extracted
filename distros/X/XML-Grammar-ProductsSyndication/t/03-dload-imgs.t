#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);

use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");

use Test::More tests => 5;

use XML::Grammar::ProductsSyndication::Mock;

use XML::Grammar::ProductsSyndication;

my $ps = XML::Grammar::ProductsSyndication->new(
    {
        'source' =>
        {
            'file' =>
                File::Spec->catfile(
                    "t", "data", "valid-xmls", "images-test.xml"
                ),
        },
        'data_dir' => File::Spec->catdir("blib", "extradata"),
    },
);

# Fails on some places due to "t" being read-only sometimes.
#
# my $images_dir = File::Spec->catdir(File::Spec->curdir(), "t", "output", "images");
#
# This should work better.
my $images_dir = tempdir ( CLEANUP => 1);

sub get_jpgs
{
    my $images_fh;
    opendir $images_fh, $images_dir;
    my @files = (grep { !(($_ eq ".") || ($_ eq "..")) } readdir($images_fh));
    closedir ($images_fh);
    return [sort { $a cmp $b } grep { /\.jpg$/ } @files];
}

sub cleanup
{
    foreach my $f (@{get_jpgs()})
    {
        unlink File::Spec->catfile($images_dir, $f);
    }
}

sub name_file
{
    my $args = shift;

    return File::Spec->catfile($images_dir, $args->{'id'} . ".jpg");
}

cleanup();

$ps->update_cover_images(
    {
        'size' => "l",
        'resize_to' => { 'width' => 100, 'height' => 100 },
        'name_cb' => \&name_file,
        'amazon_token' => "Foobar",
        'amazon_associate' => "shlomifishhom-20",
    }
);

# TEST
is_deeply (
    \@XML::Amazon::got_new_params,
    [
        [ token => "Foobar", associate => "shlomifishhom-20", ],
    ],
    "Testing for init of XML::Amazon",
);

# TEST
is_deeply (
    \@LWP::UserAgent::got_get_params,
    [
        [ "http://www.amazon.com/image-for/size=l/asin=0451529308/" ],
        [ "http://www.amazon.com/image-for/size=l/asin=014036711X/"],
        [ "http://www.amazon.com/image-for/size=l/asin=0596000278/"],
    ],
    "Testing for fetching the URLs.",
);

# TEST
is_deeply(
    get_jpgs(),
    [ qw(
        around_the_world_in_80_days.jpg
        little_women.jpg
        programming_perl.jpg
        ) 
    ],
    "Testing for the existence of the jpegs",
);

@LWP::UserAgent::got_get_params = ();

$ps->update_cover_images(
    {
        'size' => "l",
        'resize_to' => { 'width' => 100, 'height' => 100 },
        'name_cb' => \&name_file,
        'amazon_token' => "Foobar",
        'amazon_associate' => "shlomifishhom-20",
    }
);


# TEST
is_deeply (
    \@LWP::UserAgent::got_get_params,
    [
    ],
    "Testing for not fetching the URLs upon update.",
);


$ps->update_cover_images(
    {
        'size' => "l",
        'resize_to' => { 'width' => 100, 'height' => 100 },
        'name_cb' => \&name_file,
        'amazon_token' => "Foobar",
        'amazon_associate' => "shlomifishhom-20",
        'overwrite' => 1,
    }
);

# TEST
is_deeply (
    \@LWP::UserAgent::got_get_params,
    [
        [ "http://www.amazon.com/image-for/size=l/asin=0451529308/" ],
        [ "http://www.amazon.com/image-for/size=l/asin=014036711X/"],
        [ "http://www.amazon.com/image-for/size=l/asin=0596000278/"],
    ],
    "Testing for overwriting the files.",
);

cleanup();
