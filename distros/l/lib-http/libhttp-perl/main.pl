
  use lib::http 'debug' ;
  use XML::Smart ;

  print "__________________________________________\n" ;

  foreach my $Key (sort keys %INC ) {
    print "$Key = $INC{$Key}\n" ;
  }
  
  print "__________________________________________\n" ;

  print "\nHello World!\n" ;
  
  exit;

