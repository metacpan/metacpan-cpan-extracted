package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;

sub myWriteMakefile
{
  my %args = @_;
  $args{INC} = '-Iinclude';

  if($^O !~ /^(cygwin|MSWin32|msys)$/)
  {  
    print STDERR "platform not supported\n";
    exit;
  }

  WriteMakefile(%args);
}

1;
