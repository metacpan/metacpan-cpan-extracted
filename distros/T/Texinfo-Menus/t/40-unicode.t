#! /usr/bin/perl
#---------------------------------------------------------------------
# 40-unicode.t
#
# Copyright 2010 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Unicode tests for Texinfo::Menus
#---------------------------------------------------------------------

use FindBin '$Bin';
use Test::More 0.88;            # done_testing

BEGIN {
  # RECOMMEND PREREQ: File::Copy
  eval "use File::Copy";
  plan skip_all => "File::Copy required for testing" if $@;

  # RECOMMEND PREREQ: Test::File::Contents 0.03
  eval "use Test::File::Contents 0.03";
  plan skip_all => "Test::File::Contents 0.03 required for testing" if $@;

  plan tests => 3;
  use_ok('Texinfo::Menus');
}

#=====================================================================
my $testDir   = "$Bin/testing";
my $goodDir   = "$Bin/expected";
my $sourceDir = "$Bin/source";

mkdir $testDir or die "Unable to create $testDir directory" unless -d $testDir;
chdir $testDir or die "Unable to cd $testDir";

#---------------------------------------------------------------------
copy("$sourceDir/unicode.texi", $testDir)
    or die "Unable to copy $sourceDir/unicode.texi to $testDir";

update_menus('unicode.texi');
file_contents_identical('unicode.texi', "$goodDir/unicode.texi",
                        'using defaults');

#---------------------------------------------------------------------
copy("$sourceDir/unicode.texi", "$testDir/unicodeND.texi")
    or die "Unable to copy $sourceDir/unicode.texi to $testDir/unicodeND.texi";

update_menus('unicodeND.texi', detailed => 0);
file_contents_identical('unicodeND.texi', "$goodDir/unicodeND.texi",
                        'using detailed => 0');

done_testing;
