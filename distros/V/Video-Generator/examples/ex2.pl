#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Video::Generator;

# Temporary directory.
my $temp_dir = tempdir();

# Object.
my $obj = Video::Generator->new(
        'verbose' => 1,
);

# Create video.
my $video_file = catfile($temp_dir, 'foo.mpg');
$obj->create($video_file);

# Clean.
rmtree $temp_dir;

# Output:
# Video pattern generator created images for video in temporary directory.
# Created video file.
# Removed temporary directory.