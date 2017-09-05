package mymm;

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Copy qw( copy );

sub myWriteMakefile
{
  my(%args) = @_;
  
  if($^O =~ /^(cygwin|MSWin32|msys)$/)
  {
    $args{INC} = '-Ixs';
    my $from = 'xs/Getppid.xs';
    my $to   = 'Getppid.xs';
    unlink $to if -f $to;
    copy($from, $to) || die "unable to copy $from to $to $!";
  }

  WriteMakefile(%args);
}

1;
