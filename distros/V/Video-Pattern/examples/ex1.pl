#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Path qw(rmtree);
use Video::Pattern;

# Object.
my $obj = Video::Pattern->new(
       'duration' => 10000,
       'fps' => 2,
);

# Temporary directory.
my $temp_dir = tempdir();

# Create frames.
$obj->create($temp_dir);

# List and print files in temporary directory.
system "ls -l $temp_dir";

# Remove temporary directory.
rmtree $temp_dir;

# Output on system supporting links like:
# celkem 66968
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 000.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 001.bmp -> 000.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 002.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 003.bmp -> 002.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 004.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 005.bmp -> 004.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 006.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 007.bmp -> 006.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 008.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 009.bmp -> 008.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 010.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 011.bmp -> 010.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 012.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 013.bmp -> 012.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 014.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 015.bmp -> 014.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 016.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 017.bmp -> 016.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 018.bmp
# lrwxrwxrwx 1 foobar foobar       7 20. čen 12.09 019.bmp -> 018.bmp
# -rw-r--r-- 1 foobar foobar 6220854 20. čen 12.09 020.bmp