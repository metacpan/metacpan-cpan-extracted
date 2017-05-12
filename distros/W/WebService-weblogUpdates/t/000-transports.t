use strict;

use Test::More;
plan tests => 1;

my $err = 0;

eval "require LWP::Simple";

if ($@) { 
   diag($@);
   $err ++; 
}

eval "require Frontier::Client";

if ($@) { 
   diag($@);	
   $err ++; 
}

eval "require SOAP::Lite";

if ($@) { 
   diag($@);
   $err ++; 
}

isnt($err,'3',"Has one or more valid transports.\n");
