
use ePod ;

  use strict ;
  
if ( $ARGV[0] =~ /^-+h/i || !@ARGV ) {

  my ($script) = ( $0 =~ /([^\\\/]+)$/s );

print qq`____________________________________________________________________

ePod - $ePod::VERSION
____________________________________________________________________

USAGE:

  $script file.epod file.pod


(C) Copyright 2000-2004, Graciliano M. P. <gm\@virtuasites.com.br>
____________________________________________________________________
`;

exit;
}

  my $epod = ePod->new() ;
  
  my $epod_file = shift ;
  my $pod_file = $ARGV[0] =~ /pod/i ? shift : undef ;

  my $new_file = $epod->to_pod( $epod_file , $pod_file , @ARGV ) ;

  print "File $epod_file converted to $new_file.\n" ;


