#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: perl put_pic.pl <filename_of_pic_to_upload>\n"
    unless @ARGV;

my $Filename = shift;

use lib '../lib';
use WWW::ImagebinCa::Create;

my $bin = WWW::ImagebinCa::Create->new;

$bin->upload( filename => $Filename )
    or die "Failed to upload: " . $bin->error;

printf "Upload ID: %s\nPage URI: %s\nDirect image URI: %s\n",
            $bin->upload_id,
            $bin->page_uri,
            $bin->image_uri;
