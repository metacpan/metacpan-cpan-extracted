use strict;
use warnings;

if(@ARGV)
{
  print "arg$_=$ARGV[$_]\n" for 0..$#ARGV;
}
else
{
  print "no arguments\n";
}
