#!/usr/bin/perl

use strict;

die "usage: $0 directory ...\n" unless @ARGV;

foreach my $dir (@ARGV)
{
  my (@subdirs) = split /[\/\\]/, $dir;

  my $dir_to_create = '';

  foreach my $subdir (@subdirs)
  {
    if ($dir_to_create eq '')
    {
      $dir_to_create = '/' if $subdir eq '';
    }
    else
    {
      $dir_to_create .= '/' if $dir_to_create !~ /\/$/;
    }

    $dir_to_create .= $subdir;

    next if -d $dir_to_create;

#print "making directory: $dir_to_create\n";

    # Don't die on file exists, in case make -j was used and another parallel
    # invocation created the directory before we could get to it.
    unless (mkdir $dir_to_create)
    {
      die "Could not create directory $dir_to_create: $!\n"
        if $! ne 'File exists';
    }
  }
}
