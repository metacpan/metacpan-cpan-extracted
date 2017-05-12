#! /usr/bin/perl
#---------------------------------------------------------------------
# 20-includes.t
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
# Test @include files with Texinfo::Menus
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

  plan tests => 11;
  use_ok('Texinfo::Menus');
}

#=====================================================================
my $testDir   = "$Bin/testing";
my $goodDir   = "$Bin/expected";
my $sourceDir = "$Bin/source";

mkdir $testDir or die "Unable to create $testDir directory" unless -d $testDir;
chdir $testDir or die "Unable to cd $testDir";

#---------------------------------------------------------------------
my @subfiles = qw(chapter1.texi chapter2.texi chapter3-4.texi section22.texi);

sub run_tests
{
  my ($fn, $desc, @parms) = @_;

  update_menus($fn, @parms);

  foreach my $file ($fn, @subfiles) {
    file_contents_identical($file, "$goodDir/$file", "$file $desc");
  }
} # end run_tests

#---------------------------------------------------------------------
foreach ('includes.texi', @subfiles) {
  copy("$sourceDir/$_", $testDir)
    or die "Unable to copy $sourceDir/$_ to $testDir";
}

run_tests('includes.texi', 'using defaults');

#---------------------------------------------------------------------
copy("$sourceDir/includes.texi", "$testDir/includesNC.texi")
    or die "Unable to copy $sourceDir/includes.texi to $testDir/includesNC.texi";

run_tests('includesNC.texi', 'using comments => 0', comments => 0);

done_testing;
