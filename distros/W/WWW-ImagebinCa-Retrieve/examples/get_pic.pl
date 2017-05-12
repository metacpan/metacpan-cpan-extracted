#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: perl get_pic.pl <page_id_or_uri>\n"
    unless @ARGV;

my $What = shift;

use lib '../lib';

use WWW::ImagebinCa::Retrieve;

my $bin = WWW::ImagebinCa::Retrieve->new;

my $full_info_ref = $bin->retrieve( what => $What, 
where => '/home/zoffix/Desktop/' )
    or die "Error: " . $bin->error;

printf "Page ID:%s\nImage located on: %s\nImage URI: %s\n"
        . "Image Description: %s\nSaved image locally as: %s\n",
            @$full_info_ref{ qw(
                page_id      page_uri  image_uri
                description  where
            )};
