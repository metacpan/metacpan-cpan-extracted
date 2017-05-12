#!/usr/bin/perl -w
####
#### Scan for non-ascii characters in a file.
####

while(<>){
  my $line = 1;
  my @chars = split(//);
  ## I think this works on all POSIX systems...
  if(/[^[:ascii:]]/){
    print "line $line: non-ascii character\n";
  }
  $line++;
}
