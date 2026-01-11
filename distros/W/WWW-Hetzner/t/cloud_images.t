#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

subtest 'list images' => sub {
    my $fixture = load_fixture('images_list');

    my $cloud = mock_cloud(
        'GET /images' => $fixture,
    );

    my $images = $cloud->images->list;

    is(ref $images, 'ARRAY', 'returns array');
    is(scalar @$images, 3, 'three images');
    is($images->[0]{name}, 'debian-12', 'first image name');
    is($images->[1]{name}, 'debian-13', 'second image name');
    is($images->[1]{os_flavor}, 'debian', 'os flavor');
};

subtest 'get image by id' => sub {
    my $fixture = load_fixture('images_get');

    my $cloud = mock_cloud(
        'GET /images/2' => $fixture,
    );

    my $image = $cloud->images->get(2);

    is($image->{id}, 2, 'image id');
    is($image->{name}, 'debian-13', 'image name');
    is($image->{os_version}, '13', 'os version');
};

subtest 'get image by name' => sub {
    my $fixture = load_fixture('images_list');

    my $cloud = mock_cloud(
        'GET /images' => $fixture,
    );

    my $image = $cloud->images->get_by_name('debian-13');

    is($image->{name}, 'debian-13', 'image name');
    is($image->{os_flavor}, 'debian', 'os flavor');
};

subtest 'get image by name - not found' => sub {
    my $fixture = load_fixture('images_list');

    my $cloud = mock_cloud(
        'GET /images' => $fixture,
    );

    my $image = $cloud->images->get_by_name('nonexistent');

    ok(!defined $image, 'returns undef for not found');
};

done_testing;
