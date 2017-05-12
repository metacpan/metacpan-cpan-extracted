package revphone;

use 5.008003;
use strict;
use warnings;

require Exporter;




our $VERSION = '0.01';


sub revlookup
{

my $lastn;
my $firstn;
my $street;
my $city;
my $state;
my $zip;
my $findit;
my $temp;
my $areac;
my $num;
my $return;
my $hey;
my $fullnum;
use LWP::Simple;
  $fullnum=$_[1];
  
  if ($fullnum eq "" or ( length($fullnum) != 10) )
	{
		return "Invalid Phone Number Format Please use XXXXXXXXXX eg 6019251121\n";
	}	
 $areac=substr($fullnum,0,3);
 $num=substr($fullnum,3,7);
 
 
 $findit = get('http://anywho.com/qry/wp_rl?npa='.$areac.'&telephone='.$num.'&btnsubmit.x=41&btnsubmit.y=12');
        
      $temp= $1;
       
       
       $findit=~ m/(HREF=.*cgi-bin\/amap.*lastname.*&f)/ ;
       $temp= $1;
       $temp=~ m/(lastname=.*)/;
       $lastn=substr($1,9,length($1)-11);
         
	
	$findit=~ m/(HREF=.*cgi-bin\/amap.*firstname.*&n)/ ;
        $temp= $1;
        $temp=~ m/(firstname.*)/;
        $firstn=substr($1,10,length($1)-12);
       
       
       
        $findit=~ m/(HREF=.*cgi-bin\/amap.*streetaddress=.*&city)/ ;
        $temp= $1;
        $temp=~ m/(streetaddress.*)/;
        $street=substr($1,14,length($1)-19);
      
       
        $findit=~ m/(HREF=.*cgi-bin\/amap.*city=.*&s)/ ;
        $temp= $1;
        $temp=~ m/(city.*)/;
        $city=substr($1,5,length($1)-7);
        
       
	$findit=~ m/(HREF=.*cgi-bin\/amap.*state=.*&z)/ ;
        $temp= $1;
        $temp=~ m/(state.*)/;
        $state=substr($1,6,length($1)-8);
       
       
	$findit=~ m/(HREF=.*cgi-bin\/amap.*zip=.*&c)/ ;
        $temp= $1;
        $temp=~ m/(zip.*)/;
        $zip=substr($1,4,length($1)-6);
     
	
	 $return= $lastn.",".$firstn." ".$street." ".$city.",".$state." ".$zip."\n";
         $return=~ s/\+/ /g;

	if ($firstn eq '' && $lastn eq '')
		{
			return "Information Not Found\n";
		}
	else 
		{
			return $return;
	
		}
    }

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

revphone - Perl extension for reverse phone lookups

=head1 SYNOPSIS

use revphone;
my $revlookup = revphone;
$revlookup->revlookup('6016841121');

Return-->  Nobody,is_here 555 milky way ln. Clinton, Ms 39056

=head1 DESCRIPTION

Revphone Uses anywho.com and mines a reverse phone number lookup.



=head2 EXPORT





=head1 SEE ALSO

For usage information please see the README.

Everyone that uses this module, if you would (you dont have to) just send me an email
phocus@madbuddhawisdom.com and let me know... 
I would like to have an idea of how many people actually use it.

this is my 3rd perl program and 1st module, so if you find bugs, let me know!!

-Joseph Ronie
phocus, E<lt>phocus@madbuddhawisdom.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by phocus

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
