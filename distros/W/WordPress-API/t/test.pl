use strict;


sub tconf {
   -f './t/wppost' or return;
   require YAML;
   my $c = YAML::LoadFile('./t/wppost');
   return $c;
}



sub skiptest {
   if( my $c = tconf() ){
      return $c;
   }

   print STDERR " # Will not continue testing. Missing ./t/wppost
You may want to see README and install manually.\n";
   ok(1," skipping $0");
   exit;
}





1;
