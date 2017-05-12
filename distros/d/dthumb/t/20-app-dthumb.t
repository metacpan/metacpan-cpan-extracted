#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use autodie;

use Test::More tests => 18;

use_ok('App::Dthumb');

my $dthumb = App::Dthumb->new();

isa_ok($dthumb, 'App::Dthumb');

isa_ok($dthumb->{data}, 'App::Dthumb::Data');

is($dthumb->{config}->{dir_data}, './.dthumb', 'Data directory is .dthumb');
is($dthumb->{config}->{dir_images}, '.', 'Image directory is .');
is($dthumb->{config}->{dir_thumbs}, './.thumbs',
	'Thumbnail directory is dthumbs');
is($dthumb->{config}->{file_index}, 'index.xhtml', 'index is index.xhtml');

is($dthumb->{config}->{lightbox},   1, 'Lightbox enabled');
is($dthumb->{config}->{names}   ,   1, 'Show image names');
is($dthumb->{config}->{quality} ,  75, 'Default quality');
is($dthumb->{config}->{recreate},   0, 'Do not recreate');
is($dthumb->{config}->{size}    , 200, 'Default size');
is($dthumb->{config}->{spacing} , 1.1, 'Default spacing');

$dthumb = App::Dthumb->new('no-lightbox' => 1);
is($dthumb->{config}->{lightbox}, 0, 'Lightbox disabled');

$dthumb = App::Dthumb->new('no-names' => 1);
is($dthumb->{config}->{names}, 0, 'Image names disabled');

$dthumb = App::Dthumb->new();

@{$dthumb->{files}} = qw(a.png b.png c.png d.jpg);
@{$dthumb->{old_thumbnails}} = 'e.png';

is_deeply($dthumb->{files}, [$dthumb->get_files()], '$dthumb->get_files()');

$dthumb = App::Dthumb->new(dir_images => 't/imgdir');
$dthumb->read_directories();

is_deeply($dthumb->{old_thumbnails}, ['invalid.png'], '{old_thumbnails}');
is_deeply($dthumb->{files}, ['one.png', 'two.png'], '{files}');
