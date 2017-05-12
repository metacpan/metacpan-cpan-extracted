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
my $obj = Video::Generator->new;

# Create video.
my $video_file = catfile($temp_dir, 'foo.mpg');
$obj->create($video_file);

# Print out type.
system "ffprobe -hide_banner $video_file";

# Clean.
rmtree $temp_dir;

# Output:
# Input #0, mpeg, from '/tmp/GoCCk50JSO/foo.mpg':
#   Duration: 00:00:09.98, start: 0.516667, bitrate: 1626 kb/s
#     Stream #0:0[0x1e0]: Video: mpeg1video, yuv420p(tv), 1920x1080 [SAR 1:1 DAR 16:9], 104857 kb/s, 60 fps, 60 tbr, 90k tbn, 60 tbc