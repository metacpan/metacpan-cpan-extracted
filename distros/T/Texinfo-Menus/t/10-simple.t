#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-simple.t
#
# Copyright 2006 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Simple tests for Texinfo::Menus
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
copy("$sourceDir/simple.texi", $testDir)
    or die "Unable to copy $sourceDir/simple.texi to $testDir";

update_menus('simple.texi');
file_contents_identical('simple.texi', "$goodDir/simple.texi", 'using defaults');

#---------------------------------------------------------------------
copy("$sourceDir/simple.texi", "$testDir/simpleND.texi")
    or die "Unable to copy $sourceDir/simple.texi to $testDir/simpleND.texi";

update_menus('simpleND.texi', detailed => 0);
file_contents_identical('simpleND.texi', "$goodDir/simpleND.texi",
                        'using detailed => 0');

done_testing;
