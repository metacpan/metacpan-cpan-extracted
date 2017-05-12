#!/usr/bin/perl

use warnings;
use strict;

use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

my $filename = 'binary_build/dotreader.exe';

my $zip = Archive::Zip->new();
$zip->read($filename) == AZ_OK or
  die("'$filename' is not a valid zip file.");
$zip->updateTree( 'client/data', 'data', sub {-f });
$zip->overwrite( $filename ) == Archive::Zip::AZ_OK or die 'write error';
undef($zip);


rename($filename, "$filename.par") or die;
system('pp', '-o', $filename, "$filename.par") and die;
warn "ok\n";
