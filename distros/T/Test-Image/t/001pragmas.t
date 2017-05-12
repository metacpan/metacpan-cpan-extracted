#!/usr/bin/perl
#
# Make sure every module contains 'use strict' and 'use warnings'

use strict;
use warnings;
use Test::More;
use File::Find::Rule;

my @files = File::Find::Rule->file()->name('*.pm')->in('lib');
plan skip_all => "No modules" unless scalar @files;
plan tests => 2 * scalar @files;

foreach my $file ( @files ) {
  my $fh;
  local $/;
  open $fh, $file;
  my $content = <$fh>;
  ok($content =~ qr/use\s+strict\b/, "$file using strict");
  ok($content =~ qr/use\s+warnings\b/, "$file using warnings");
}
