######################
# Unix/Win compatible
# fork() function!
######################
#####################################################################

############################################
# Complatable form of FORK for Unix AND Win!
############################################
sub ForkScript
{
 # Apache will try to kill that process, when pipes are closed!
 $SIG{'TERM'} = 'IGNORE';
 
 # flush_print(); -> That must be called before that function!!!

 # Break pipes to browser( Apache flush all data)
 close (STDOUT);
 close (STDIN);
 close (STDERR);

 ###################################
 # Making fork (this may be needful)
 ###################################
 local $sys_PID = 0;
 if(!($^O =~ m/Win/is))
   {
    eval {$sys_PID = fork();};
    if ($@ eq '')
     {
      if ($sys_PID)
        {
         exit;  # All doubts must disapear here!
        }
     }
   }
 
 ############################################
 # Do anything that will take very long time!
 ############################################
 # Don't forget to call: set_script_timeout($wished_timelife_in_seconds);
 return(1);
}
$webtools::loaded_functions = $webtools::loaded_functions | 1024;
1;