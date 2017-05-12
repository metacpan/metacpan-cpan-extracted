#!/usr/bin/perl

use XML::DT;
use Data::Dumper;

%handler = ( -default => sub{$c},
	     packages => sub{ [ split(",",$c)] },
             -type    => { vendorinfo => 'MAP',
                           paks       => 'SEQ' }
           ); 

$a = dtstring ("
  <vendorinfo>
    <id> netscape.com </id> 
    <id> netscape.commmm</id>
    <name> Netscape </name> 
    <status> active </status> 
    <packages> communicator-4.07, communicator-4.5, navigator-4.07 </packages> 
  </vendorinfo>",%handler);
    
print Dumper($a);         

$a = dtstring ("
  <vendorinfo>
    <id> netscape.com </id> 
    <id> netscape.commmm</id>
    <name> Netscape </name> 
    <status> active </status> 
    <paks> 
       <item>communicator-4.07 </item>
       <item> communicator-4.5, </item>
       <item> navigator-4.07 </item> 
    </paks> 
  </vendorinfo>",%handler);

print Dumper($a);         
