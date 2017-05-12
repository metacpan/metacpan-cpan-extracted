################################################################################
#
# $Project: /Tk-DataTree $
# $Author: mhx $
# $Date: 2008/04/13 10:59:53 +0200 $
# $Revision: 5 $
# $Snapshot: /Tk-DataTree/0.06 $
# $Source: /Makefile.PL $
#
################################################################################
#
# Copyright (c) 2004-2008 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

require 5.00503;
use strict;

use ExtUtils::MakeMaker;
use Config qw(%Config);

my $no_xs;

for (@ARGV) {
  /^-pm/ and $no_xs = 1;
  /^-xs/ and $no_xs = 0;
}

sub write_makefile
{
  WriteMakefile(
    NAME         => 'Tk::DataTree',
    VERSION_FROM => 'lib/Tk/DataTree.pm',
    PREREQ_PM    => { 'Tk'            => 800.021,
                      'Tk::Tree'      => 3.019,
                      'Tk::ItemStyle' => 3.004,
                      'Tk::widgets'   => 3.009,
                    },
    CONFIGURE    => \&configure,
    clean        => { FILES => 'test.c' },
  );
}

sub configure
{
  my @moreopts;

  if (eval $ExtUtils::MakeMaker::VERSION >= 6) {
    push @moreopts, AUTHOR => 'Marcus Holland-Moritz <mhx@cpan.org>',
                    ABSTRACT_FROM => 'lib/Tk/DataTree.pm';
  }

  if (eval $ExtUtils::MakeMaker::VERSION >= 6.30_01) {
    print "Setting license tag...\n";
    push @moreopts, LICENSE => 'perl';
  }

  if ($no_xs) {
    push @moreopts, XS => {}, C => [];
  }

  return { @moreopts };
}

write_makefile();

defined $no_xs and exit;

sub no_cc
{
  $no_xs = 1;

  print <<"EDQ";

 I cannot determine if you have a C compiler so I will install
 a perl-only implementation with limited functionality.

 You can however force installation of the XS version with:

    $^X Makefile.PL -xs

EDQ

  write_makefile();
  exit;
}

print "Testing if you have a C compiler\n";

open F, ">test.c" or no_cc();
print F "int main() { return 0; }\n";
close F or no_cc();
system "$Config{make} test$Config{obj_ext}" and no_cc();

