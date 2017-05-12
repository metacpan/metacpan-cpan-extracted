#!/usr/bin/perl
# Please change shebang if need!
#####################################################################

# Copyright (c) 2001, Julian Lishev, Sofia 2002
# All rights reserved.
# This code is free software; you can redistribute
# it and/or modify it under the same terms 
# as Perl itself.

#####################################################################
BEGIN {
 sub make_script_path
 {
  my $sys_path_engine = $ENV{'SCRIPT_FILENAME'};
  if(($sys_path_engine eq '') && ($ENV{'SERVER_NAME'} eq '') && ($ENV{'SERVER_PORT'} eq ''))
   {
    $sys_path_engine = $0;
   }
  $sys_path_engine =~ s/\\/\//sg;
  $sys_path_engine =~ s/\~//sg;
  $sys_path_engine =~ s/\.\.//sg;
  if($sys_path_engine =~ m/^(.*)\/([^\/]*)$/si)
   {
    return($1.'/');
   }
  else {return('');}
 }
 local $sys_path = &make_script_path();
 if(length($sys_path) > 0) { chdir $sys_path; }
}

use lib './modules/';
use webtools;

RunScript();
DestroyScript();