#! /usr/bin/perl
#---------------------------------------------------------------------
# 30-verbose.t
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
# Test the 'verbose' option of Texinfo::Menus
#---------------------------------------------------------------------

use Config;
use FindBin '$Bin';
use Test::More 0.88;            # done_testing

BEGIN {
  plan skip_all => "Perl was not compiled with PerlIO" unless $Config{useperlio};

  # RECOMMEND PREREQ: File::Copy
  eval "use File::Copy";
  plan skip_all => "File::Copy required for testing" if $@;

  # RECOMMEND PREREQ: Test::File::Contents 0.03
  eval "use Test::File::Contents 0.03";
  plan skip_all => "Test::File::Contents 0.03 required for testing" if $@;

  plan tests => 7;
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

#---------------------------------------------------------------------
foreach ('includes.texi', @subfiles) {
  copy("$sourceDir/$_", $testDir)
    or die "Unable to copy $sourceDir/$_ to $testDir";
}

my $errors = '';

open(OLDERR, '>&STDERR');
close STDERR;
open(STDERR, '>', \$errors) or die "Unable to reopen STDERR";

update_menus('includes.texi', verbose => 1);

close STDERR;
open(STDERR, '>&OLDERR');
close OLDERR;

is($errors, <<'', 'Warning messages');
chapter2.texi:9: Warning: Multiple descriptions for node `Variable names'
    `This came from the Top menu' overrides
    `This gets overridden by the Top menu'
chapter2.texi:35: Warning: Multiple descriptions for node `Scalar values'
    `Scalar values DESC comment' overrides
    `This is overridden by a DESC comment'

foreach my $file ('includes.texi', @subfiles) {
  file_contents_identical($file, "$goodDir/$file", $file);
}

done_testing;
