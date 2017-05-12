#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");

use Test::More tests => 1;

use XML::Grammar::ProductsSyndication::Mock;

use XML::Grammar::ProductsSyndication;

my $ps = XML::Grammar::ProductsSyndication->new(
    {
        'source' =>
        {
            'file' =>
                File::Spec->catfile(
                    "t", "data", "valid-xmls", "010-disabled-isbn.xml"
                ),
        },
        'data_dir' => File::Spec->catdir("blib", "extradata"),
    },
);

my $images_dir = File::Spec->catdir(File::Spec->curdir(), "t", "output", "images");

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
    \@LWP::UserAgent::got_get_params,
    [
    ],
    "Testing for not fetching the disable URLs.",
);

cleanup();
