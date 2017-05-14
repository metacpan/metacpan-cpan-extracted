#!/usr/bin/perl -w
#use CGI;
print "enter the numbers";
chomp($num=<STDIN>);
sub sum {
 $sumi = 0;
 for(my $i=1,$i<="$num",$i++) 
 {
   $sumi = $sumi + $i ;
  }
    $vv=$sumi  ;
print "summation is : $vv \n";
}
&sum ;
#print "summation is : $tot \n";

