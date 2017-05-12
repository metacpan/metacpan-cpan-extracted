use strict;


sub assure_fulltesting {
   if( ! -f './t/wppost' ){
      warn "# ./t/wppost not on disk.\n";
      $ENV{FULLTESTING} = 0;
   }
   if ( exists $ENV{FULLTESTING} and (!$ENV{FULLTESTING}) ){ 
         warn "# FULLTESTING is off.\n$0 skipping.\n";
         warn "# see README for further testing.\n\n";
         exit;
   }
}



sub _conf {
   my $abs = shift;
   require YAML;
   my $conf = YAML::LoadFile($abs);
   $conf->{username} = $conf->{U};
   $conf->{password} = $conf->{P};
   $conf->{proxy} = $conf->{p};
   return $conf;
}

1;
