#!/usr/bin/perl -w

# increment the version number in all the files on the command line (and do it
# recursively for directories on the command line)

use strict;

use File::Find;

sub executable
{
  my $file = shift;
  open F, "<", $file or die;
  my $line = <F>;
  close F;
  if (defined $line) {
    if ($line =~ m{\#!.*perl}) {
      return 1;
    } else {
      return 0;
    }
  } else {
    return 0;
  }
}

sub process
{
  my $file = $_;

  if (-f $file) {
    if ($file =~ /\.pm$/ ||
        executable($file) && $file !~ /~$|\.svn/) {
      rename $file, $file . ".old~";
      open IN, '<', $file . ".old~" or die;
      open OUT, '>', $file or die;
      while (<IN>) {
        s/(\$VERSION\s*=\s')([\d\.\_]+)'/$1 . ($2 + 0.01) . "'"/e;
        print OUT;
      }
      close IN;
      close OUT;
    }
  }

}

find({ wanted => \&process, follow => 1 }, @ARGV);

__END__
