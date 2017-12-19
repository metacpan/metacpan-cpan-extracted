package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;

sub myWriteMakefile
{
  my(%args) = @_;
  $args{PREREQ_PM}->{$^O eq 'MSWin32' ? 'Filesys::DfPortable' : 'Filesys::Df'} = 0;
  WriteMakefile(%args);
}

1;
