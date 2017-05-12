#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw(lib  ../lib);
use WebService::HtmlKitCom::FavIconFromImage;

die "Usage: fav.pl <picture_file_to_make_favicon_from>\n"
    unless @ARGV;

my $Pic = shift;

my $fav = WebService::HtmlKitCom::FavIconFromImage->new;

$fav->favicon( $Pic, file => 'out.zip' )
    or die $fav->error;

print "Done \\o/ I've saved output to out.zip file\n";

