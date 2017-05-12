#!perl

use strict;

main{
   my $path = shift || './';
   
   my @tests = list_files($path);
   
   for(sort(@tests))
   {
      my $ret = open(SYS, "perl $_ 2>&1 |");
      print "\nTESTING\: $_\n";
      while(<SYS>){print $_}
      close SYS;
      
      print "\<more\>"; <STDIN>;
   }
   
   print "\<Done\>";
}

exit();

sub list_files
{
   my $path = shift;
   
   my @file_list;
   
   unless(opendir(PATH, $path)){die "$path - $!"}
   
   while(defined(my $file = readdir PATH))
   {
      next if $file =~ /^\.\.?$/;
      
      next if -d "$path/$file";
      
      # push(@file_list, $file) unless $file =~ /^control/i;
      push(@file_list, $file) if $file =~ /^\d{2}/i;
   }
   
   closedir PATH;
   
   return(@file_list);
}
