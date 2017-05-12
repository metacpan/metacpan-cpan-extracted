#! /usr/bin/perl

# TO DO:  Handle stderr and SOAP::Lite debug better


BEGIN {
       @INC = ( @INC, ".." );
};


use DateTime;
use DateTime::Format::W3CDTF;
use DateTime::Format::Epoch;
use XML::DOM;
use strict;


my $COUNTER = "http://www.sve.man.ac.uk/Counter";
my $CounterNS = "http://www.sve.man.ac.uk/Counter";



my $usage .= "\t\t\tTest script for WSRF::Lite\n\n";
$usage .= "The Script creates various WS-Resources then exercises them: getting Resource\n";
$usage .= "properties, setting them, setting the TerminationTime etc. It can be used to\n";
$usage .= "check a WSRF::Lite installation is working correctly or that modifications to\n";
$usage .= "the software have not broken seomthing. The script checks for a Container on\n";
$usage .= "the local system using port 50000\n\n";
$usage .= "Select which type of Resource you want to test - File, WSRF or MultiSession.\n";
$usage .= "Using the -d option will display the actual SOAP messages.\n\n";
$usage .= "Usage: $0 -[hds] target\n\n";
$usage .= "     -h  prints this message\n";
$usage .= "     -d  turns on SOAP::Lite debug/tracing\n";
$usage .= "     -s  turns on TLS\n";
$usage .= "\ntarget is either File, WSRF or MultiSession.\n";
$usage .= "The script will return a prompt - you type in a number 1-9 to run a particular\n";
$usage .= "test\n";


use Getopt::Std;
our ($opt_h,$opt_d,$opt_s);

getopts("hds");

if($opt_h) {
	print $usage;
	exit 0;
}

if($opt_d) {
  eval "use WSRF::Lite +trace =>  debug => sub{}; ";
}
else {
  eval "use WSRF::Lite;";
}


my $https = $opt_s ? "true" : undef;

#need to point to users certificates - these are only used
#if https protocal is being used.
$ENV{HTTPS_CA_DIR} = "/etc/grid-security/certificates/";
$ENV{HTTPS_CERT_FILE} = $ENV{HOME}."/.globus/usercert.pem";
$ENV{HTTPS_KEY_FILE}  = $ENV{HOME}."/.globus/userkey.pem";


my $COUNTERTYPE = shift;
die "$usage\n" unless $COUNTERTYPE;

my ( $FactoryEndPoint, $COUNTER);

if ( $COUNTERTYPE =~ m/File/ )
{
  $FactoryEndPoint = $https ? "https://localhost:50000/Session/Counter/Counter" : 
                     "http://localhost:50000/Session/Counter/Counter";
  $COUNTER = "http://www.sve.man.ac.uk/Counter";
}
elsif ( $COUNTERTYPE =~ m/WSRF/ )
{
  $FactoryEndPoint = $https ? "https://localhost:50000/Session/CounterFactory/CounterFactory" : 
                          "http://localhost:50000/Session/CounterFactory/CounterFactory" ;
  $COUNTER = "http://www.sve.man.ac.uk/CounterFactory";
}
elsif ( $COUNTERTYPE =~ m/MultiSession/ )
{
  $FactoryEndPoint = $https ? "https://localhost:50000/MultiSession/Counter/Counter" : 
                          "http://localhost:50000/MultiSession/Counter/Counter" ;
  $COUNTER = "http://www.sve.man.ac.uk/Counter";
}
else
{
   die "Do not understand Counter Type $COUNTERTYPE";
}

my $ServiceGroupTarget = $https ? "https://localhost:50000/Session/myServiceGroup/myServiceGroup" :
                            "http://localhost:50000/Session/myServiceGroup/myServiceGroup";


#------------------------------- UTILITIES -----------------------------------------------

my $ConvertEpochTimeToString = sub {
   my ($EpochTime) = @_;

   #use formatter to convert epoch time to W3CDTF TimeString
   my $dt = DateTime->new( year => 1970, month => 1, day => 1 );
   my $formatter = DateTime::Format::Epoch->new(epoch => $dt);

   my $DateTimeObject = $formatter->parse_datetime($EpochTime);

   my $f = DateTime::Format::W3CDTF->new;

   my $TimeString = $f->format_datetime($DateTimeObject);

   return $TimeString;
};



my $header = sub {
   my ($URI,$Func,$Proxy,$resourceId) = @_;  
   my $ID  = "<wsa:Action>".$URI."/".$Func."</wsa:Action>";
   $ID .= "<wsa:To>$Proxy</wsa:To>";
   $ID .= "<wsa:MessageID>uuid:".int(rand 10000000000)."</wsa:MessageID>";

   if ( $resourceId ne "" )
   {
     $ID .= $resourceId;
   }
   return SOAP::Header->value($ID)->type('xml');  
};

#-------------------------- END UTILITIES -----------------------------------------------


#-------------------------- METHODS -----------------------------------------------------

my $createService = sub {
   my ($EndPoint,$uri) = @_;

   print "   Trying to create a  service with namespace $uri, endpoint $EndPoint\n";

   my $ans = WSRF::Lite
               ->uri($uri)   
               -> wsaddress(WSRF::WS_Address->new()->Address($EndPoint)) 
	       ->createCounterResource( ); 

   if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

   #Check we got a WS EndPoint back
   my $address = $ans->valueof("//Body//{$WSRF::Constants::WSA}Address") or 
          die "CREATE ERROR:: No Endpoint returned\n";


   print "   Created service, Address= ($address)\n";
   
   return ( $address);
};


my $createServiceGroup = sub {
  my ($target) = @_;
  my $func = "createServiceGroup";
  

  my $ans=  WSRF::Lite
         -> uri($WSRF::Constants::WSSG)
         -> wsaddress(WSRF::WS_Address->new()->Address($target))
         -> createServiceGroup();                                     #function + args to invoke


  if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

  #Check we got a WS-Address EndPoint back
  my $address = $ans->valueof("//Body//{$WSRF::Constants::WSA}Address") or 
       die "CREATE ERROR:: No Endpoint returned\n";

   print "   Created service, Address= ($address)\n";
   
   return ( $address);   
};


my $addServiceToServiceGroup = sub {
   my ($target) = @_;
   
 my $StuffToAdd = '<wssg:MemberEPR xmlns:wssg="'.$WSRF::Constants::WSSG.'" 
                                   xmlns:wsa="'.$WSRF::Constants::WSA.'">
                   <wsa:EndpointReference>
                   <wsa:Address>http://localhost:50000/foobar/29710671045218021111</wsa:Address>
		   </wsa:EndpointReference>
		   </wssg:MemberEPR>
		   <wssg:Content xmlns:wssg="'.$WSRF::Constants::WSSG.'"><foo>bar</foo></wssg:Content>';


 my $ans = WSRF::Lite
         -> uri($WSRF::Constants::WSSG)
#	 -> on_action( sub {sprintf '%s/%s', @_} )             
	 -> wsaddress(WSRF::WS_Address->new()->Address($target)) #location of service
         -> Add(SOAP::Data->value($StuffToAdd)->type('xml'));  #function + args to invoke

 if ($ans->fault) {  die "CREATE ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

 #Check we got a WS-Address EndPoint back
 my $address = $ans->valueof("//Body//{$WSRF::Constants::WSA}Address") or 
       die "CREATE ERROR:: No Endpoint returned\n";

 print "   Created WS-Resource, resource Address ($address)\n";
   
 return ( $address );   

};



my $destroyService = sub {
   my ($WSREndPoint) = @_;

   print "   Trying to destroy a Resource with Address ($WSREndPoint)\n";

   my $ans=  WSRF::Lite         
          -> uri($WSRF::Constants::WSRL)                #set the namespace
          -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))
#	  -> on_action( sub {sprintf '%s/%s', @_} )
          -> Destroy();  

   if ($ans->fault) {  die "DESTROY ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

   print "   Resource destroyed\n";
};

my $add = sub {
  my ($value, $WSREndPoint) = @_;
  
  print "   Trying to add $value to Counter with Address $WSREndPoint\n"; 

   my $ans=  WSRF::Lite
          -> uri($CounterNS)                #set the namespace
          -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))
#	  -> on_action( sub {sprintf '%s/%s', @_} )
          -> add($value);  

   if ($ans->fault) {  die "DESTROY ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

   print "   Added $value, returned ".$ans->result."\n";

};

my $subtract = sub {
  my ($value, $WSREndPoint) = @_;
  
  print "   Trying to subtract $value to Counter with endpoint $WSREndPoint\n"; 

   my $ans=  WSRF::Lite
          -> uri($CounterNS)                #set the namespace
          -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))       #location of service
#	  -> on_action( sub {sprintf '%s/%s', @_} )
          -> subtract($value);  

   if ($ans->fault) {  die "DESTROY ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

   print "   Subtracted $value , returned ".$ans->result."\n";

};


my $getValue = sub {
  my ($WSREndPoint) = @_;
  
  print "   Trying to getValue from Counter with Address $WSREndPoint\n"; 

   my $ans=  WSRF::Lite
          -> uri($CounterNS)                #set the namespace
          -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))
#	  -> on_action( sub {sprintf '%s/%s', @_} )
          -> getValue();  

   if ($ans->fault) {  die "DESTROY ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

   print  "   getValue returned ".$ans->result."\n";

};


my $setTerminationTime = sub {
   my ($new_time, $WSREndPoint) = @_;

   my $TermTime = WSRF::Time::ConvertEpochTimeToString($new_time);

   print "   Trying to set Termination time on $WSREndPoint to $TermTime\n";

   my $param = "<wsrl:RequestedTerminationTime>$TermTime</wsrl:RequestedTerminationTime>";
   
   my   $ans=  WSRF::Lite
            -> uri($WSRF::Constants::WSRL)                #set the namespace
            -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))        #location of service
#	    ->on_action( sub {sprintf '%s/%s', @_} )
            -> SetTerminationTime(SOAP::Data->value( $param )->type('xml')) ;  

   if ($ans->fault) {  die "SETTT ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }
   my $newTerminationTime = $ans->valueof('//NewTerminationTime');

   print "   New Termination time: $newTerminationTime (Current time ".$ans->valueof('//CurrentTime').")\n";

   return $newTerminationTime;
};

my $getResourceProperty = sub {
   my ($prop,$WSREndPoint ) = @_;
   
   print "   Trying to getResource Property $prop from $WSREndPoint\n";


   my   $ans=  WSRF::Lite
            -> uri($WSRF::Constants::WSRP)                #set the namespace
            -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))       #location of service
#	    ->on_action( sub {sprintf '%s/%s', @_} )
            -> GetResourceProperty(SOAP::Data->value( $prop )->type('xml')) ;  

   if ($ans->fault) {  die "GETRP ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

#   my ($ns,$prop_name) = split /:/, $prop;   # props always have a ns!
   my $prop_name = $prop;
   $prop_name =~ s/\w*://;

   if( defined($ans->valueof("//$prop_name")) ) 
   {
      my $i = 0;
      foreach my $item ($ans->valueof("//$prop_name")) 
      {	
        if ( $prop_name eq "Entry" )
        {
           print "     wssg:Entry - warning Entry's are repeated\n";
           print "         ServiceGroupEntryEPR  Address= ".$ans->valueof("//Entry/ServiceGroupEntryEPR//Address")."\n";
           print "         MemeberServiceEPR     Address= ".$ans->valueof("//Entry/MemberServiceEPR//Address")."\n";		      		      
           my $content = $ans->valueof("//Entry/Content");
	   if ( ref $content eq 'HASH' )
	   {
	     foreach my $key ( keys %{$content} )
	     {
                print "         Content key: $key value: ".$content->{$key}."\n";
             }  
           }
           else
           {
             print "         Content = ".$content."\n\n";  
           }
	}
        else
        {
           print "   Returned value <$item>\n"; 
	}
        $i++		  
     }
     print "GetResourceProperty: $i items returned for ResourceProperty $prop_name.\n";	  
   }
   else 
   {
     print "   No <$prop_name> returned\n";
   }

};

my $getMultipleResourceProperties = sub {
   my $WSREndPoint = shift;
   my @props = @_;

   my $searchTerm  = "";

   print "   Trying to get multiple Resource Properties <";
   foreach my $item (@props) {
     print "$item ";
     $searchTerm .= "<wsrp:ResourceProperty>$item</wsrp:ResourceProperty>"; 
   }
   print "> from  $WSREndPoint\n";

   my   $ans=  WSRF::Lite
          -> uri($WSRF::Constants::WSRP)                #set the namespace
          -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint)) #location of service
#	  ->on_action( sub {sprintf '%s/%s', @_} )
          -> GetMultipleResourceProperties(SOAP::Data->value( $searchTerm )->type('xml')) ;  

   if ($ans->fault) {  die "GETMRP ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

   foreach my $prop_name (@props) { 
     $prop_name =~ s/\w*://;
     #my ($ns,$prop_name) = split /:/, $property;   # props always have a ns!
     if(defined($ans->valueof("//$prop_name"))) {
            my $i=0;
   	    foreach my $item ($ans->valueof("//$prop_name")) {
		  if ( $prop_name eq "Entry" )
		  {
                      print "      wssg:Entry\n";
		      #print "         ServiceGroupEntryEPR  Address= ".$ans->valueof("//Entry/ServiceGroupEntryEPR//{$WSRF::Constants::WSA}Address")."\n";
		      #print "         MemeberServiceEPR     Address= ".$ans->valueof("//Entry/MemberServiceEPR//{$WSRF::Constants::WSA}Address")."\n";
		      print "         ServiceGroupEntryEPR  Address= ".$ans->valueof("//Entry/ServiceGroupEntryEPR//Address")."\n";
		      print "         MemeberServiceEPR     Address= ".$ans->valueof("//Entry/MemberServiceEPR//Address")."\n";		      		      
		      my $content = $ans->valueof("//Entry/Content");
		      if ( ref $content eq 'HASH' )
		      {
		         foreach my $key ( keys %{$content} )
			 {
		              print "         Content key: $key value: ".$content->{$key}."\n";
			 }  
		      }
		      else
		      {
		        print "         Content = ".$content."\n\n"; 
		      }
		  }
		  else
		  {
		   print "   Returned value <$item> for <$prop_name>\n";  
		  }
	        $i++;		  
	    }
	    print "  GetMultipleResourceProperty: $i items returned for ResourceProperty $prop_name.\n";
     }
     else {
       print "   No <$prop_name> returned\n";
     }
   }

};

my $queryResourceProperties = sub {
   my ($query,$WSREndPoint) = @_;

   print "   Trying to query Resource Properties from $WSREndPoint with $query\n";

   my $queryTerm = "<wsrp:QueryExpression \ 
	                xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\
		            dialect=\"http://www.w3.org/TR/1999/REC-xpath-19991116\">\
			        boolean(/*/*[namespace-uri()='".$WSRF::Constants::WSRL."' and local-name()='$query']) \
				      </wsrp:QueryExpression> ";

   my   $ans=  WSRF::Lite
          -> uri($WSRF::Constants::WSRP)                #set the namespace
          -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))         #location of service
#	  ->on_action( sub {sprintf '%s/%s', @_} )
          -> QueryResourceProperties(SOAP::Data->value( $queryTerm )->type('xml')) ;  

   if ($ans->fault) {  die "QUERYMRP ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

  
   print "   Query result <".
             $ans->valueof('/Envelope/Body/[1]').">\n";

};

my $setResourceProperties = sub {
   my $WSREndPoint = shift;
   my $command     = shift;
   my $prop_name   = shift;
   my @values      = @_;

   my $string;
   if($command =~ m/Delete/) {
     print "   Trying to $command set Resource Properties $prop_name of $WSREndPoint\n";
     $string = "<wsrp:Delete resourceProperty=\"$prop_name\"/>";
   }
   else {
     print "   Trying to $command set Resource Properties $prop_name of $WSREndPoint with";

     $string = "<wsrp:$command>";
     foreach my $item (@values) {
       print " $item";
       $string .= "<$prop_name>$item</$prop_name>"; 
     }
     $string .= "</wsrp:$command>";
     print "\n";
   }
   
   my  $ans=  WSRF::Lite
          -> uri($WSRF::Constants::WSRP)                #set the namespace
          -> wsaddress(WSRF::WS_Address->new()->Address($WSREndPoint))         #location of service
#	  ->on_action( sub {sprintf '%s/%s', @_} )
          -> SetResourceProperties(SOAP::Data->value( $string )->type('xml')) ;  

   if ($ans->fault) {  die "SETRPS ERROR:: ".$ans->faultcode." ".$ans->faultstring."\n"; }

   print "   OK\n";

};

#-------------------------- END METHODS -------------------------------------------------

my $prompt = "> ";
print $prompt;

my ($WSREndPoint, $new_termination_time,$ServiceGroupEntryEPR, 
    $SGEID);
while(<>) {

   my @to_execute;
   IN_SWITCH: {
                        /^$/ && do {
                          last IN_SWITCH;
                           };

			/^1$/ && do {
			   push(@to_execute,"create");
			   last IN_SWITCH;
			};

			/^2$/ && do {
			   push(@to_execute,"create");
			   push(@to_execute,"destroy");
			   last IN_SWITCH;
			};

			/^3$/ && do {
			   push(@to_execute,"create");
			   push(@to_execute,"settt 45");
			   last IN_SWITCH;
			};

			/^4$/ && do {
			   push(@to_execute,"create");
			   push(@to_execute,"settt 45");
			   push(@to_execute,"grp wsrl:TerminationTime");
			   last IN_SWITCH;
			};

			/^5$/ && do {
			   push(@to_execute,"create");
			   push(@to_execute,"settt 45");
			   push(@to_execute,"gmrp wsrl:TerminationTime wsrl:CurrentTime");
			   last IN_SWITCH;
			};


			/^6$/ && do {
			   my $rpname = "foo";
			   push(@to_execute,"create");
			   push(@to_execute,"grp $rpname");
			   push(@to_execute,"srp Insert $rpname string1");
			   push(@to_execute,"grp $rpname");
			   push(@to_execute,"srp Update $rpname string2 string3");
			   push(@to_execute,"grp $rpname");
			   push(@to_execute,"srp Delete $rpname");
			   push(@to_execute,"grp $rpname");
			   last IN_SWITCH;
			};
			
			
			/^7$/ && do {
			   my $rpname = "foo";
			   push(@to_execute,"create");
			   push(@to_execute,"grp count");
			   push(@to_execute,"add 45");
			   push(@to_execute,"subtract 4");
			   push(@to_execute,"getValue");
			   push(@to_execute,"grp count");
			   push(@to_execute,"srp Delete count");
			   push(@to_execute,"srp Update $rpname string2 string3");
			   push(@to_execute,"settt 115");
			   push(@to_execute,"add 45");
			   push(@to_execute,"add 25");
			   last IN_SWITCH;
			};
			
			
			/^8$/ && do {
			   push(@to_execute,"create");
			   push(@to_execute,"settt 15");
			   push(@to_execute,"sleep 30");
			   push(@to_execute,"gmrp wsrl:TerminationTime wsrl:CurrentTime");
			   last IN_SWITCH;
			};
			
			
			/^9$/ && do {
		  push(@to_execute, "serviceGroupCreate");
		  push(@to_execute, "grp wssg:Entry");
		  push(@to_execute, "serviceGroupAdd");
		  push(@to_execute, "grp wssg:Entry");
		  push(@to_execute, "gmrp wssg:Entry");
		  push(@to_execute, "sgedestroy");
		  push(@to_execute, "grp wssg:Entry");
		  push(@to_execute, "gmrp wssg:Entry");
                  push(@to_execute, "serviceGroupAdd");
                  push(@to_execute, "grp wssg:Entry");
                  push(@to_execute, "sgettt 15");
                  push(@to_execute, "grp wssg:Entry");
                  push(@to_execute, "sgegrp wsrl:TerminationTime");
                  push(@to_execute, "sgemgrp wsrl:TerminationTime wsrf:CurrentTime");
                  push(@to_execute, "sgegrp wsrl:CurrentTime");
                  push(@to_execute, "sgemgrp wsrl:CurrentTime");
                  push(@to_execute, "sleep 20");
                  #push(@to_execute, "sgemgrp wsrl:TerminationTime");
                  push(@to_execute, "grp wssg:Entry");
		  push(@to_execute, "serviceGroupAdd");
		  push(@to_execute, "serviceGroupAdd");
		  push(@to_execute, "grp wssg:Entry");
		  push(@to_execute, "destroy");
		  push(@to_execute, "grp wssg:Entry");
			};			

			/^10$/ && do {
			   push(@to_execute,"serviceGroupCreate");
			   push(@to_execute,"serviceGroupAdd");
			   push(@to_execute,"sgegrp wssg:Entry");
			   push(@to_execute,"sgesrp Update Content <p>mantoo</p>");
                           push(@to_execute,"sgegrp wssg:Entry");
			   last IN_SWITCH;
			};
			push(@to_execute,$_);  # allow a command from below as input too
   }


	eval {
	foreach (@to_execute) {

    	SWITCH: {

			/^quit/ && do {
                print "OK\n";
				exit 0;
			};

			/^create/ && do {
                ($WSREndPoint) = $createService->($FactoryEndPoint,$COUNTER);
				last SWITCH;
			};

			/^destroy/ && do {
                $destroyService->($WSREndPoint);
				last SWITCH;
			};

			/^settt/ && do {
		        my ($junk,$tt) = split;
				my $ntt = time + $tt;
                $new_termination_time = $setTerminationTime->($ntt,$WSREndPoint);
				last SWITCH;
			};

                        /^sgettt/ && do {
                        my ($junk, $tt) = split;
                               my $ntt = time + $tt;
                $new_termination_time = $setTerminationTime->($ntt,$ServiceGroupEntryEPR);
                                last SWITCH;
                         };

			/^grp/ && do {
		        my ($junk,$prop) = split;
                $getResourceProperty->($prop,$WSREndPoint);
				last SWITCH;
			};

			/^sgemgrp/ && do {
		        my ($junk,@prop) = split;
                $getMultipleResourceProperties->($ServiceGroupEntryEPR, @prop);
				last SWITCH;
			};
			
                        /^sgegrp/ && do {
		        my ($junk,$prop) = split;
                $getResourceProperty->($prop, $ServiceGroupEntryEPR);
				last SWITCH;
			};

			/^gmrp/ && do {
		        my ($junk,@props) = split;
                $getMultipleResourceProperties->($WSREndPoint,@props);
				last SWITCH;
			};

			/^qrp/ && do {
		        my ($junk,$query) = split;
                $queryResourceProperties->($query,$WSREndPoint);
				last SWITCH;
			};

			/^srp/ && do {
		        my ($junk,$command, $prop_name, @values) = split;
                $setResourceProperties->($WSREndPoint, $command, $prop_name, @values);
				last SWITCH;
			};

			/^sgesrp/ && do {
		        my ($junk,$command, $prop_name, @values) = split;
      $setResourceProperties->($ServiceGroupEntryEPR, $command, $prop_name, @values);
				last SWITCH;
			};
			
			/^add/ && do {
		        my ($junk, $value) = split;
                $add->($value, $WSREndPoint);
				last SWITCH;
			};
			
			/^subtract/ && do {
		        my ($junk, $value) = split;
                $subtract->($value, $WSREndPoint);
				last SWITCH;
			};
						
			/^getValue/ && do {
		        my ($junk) = split;
                $getValue->($WSREndPoint);
				last SWITCH;
			};
			
						
			/^sleep/ && do {
		        my ($junk,$value) = split;
                        sleep $value;
				last SWITCH;
			};
			
			/^serviceGroupCreate/ && do {
		($WSREndPoint) = $createServiceGroup->($ServiceGroupTarget);
		            last SWITCH; 	 
			};
			
			/^serviceGroupAdd/ && do {
      ($ServiceGroupEntryEPR, $SGEID) = $addServiceToServiceGroup->($WSREndPoint);		                                                      
			    last SWITCH;
			};
						


                      /^sgedestroy/ && do { 
		       $destroyService->($ServiceGroupEntryEPR, $SGEID);
		           last SWITCH; 
		      };						
			
		   print "Can't understand: $_";
		}

	}
	}; warn $@ if $@;

    print $prompt;

}

print "end\n";
