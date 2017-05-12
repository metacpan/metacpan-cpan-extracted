#!/usr/bin/perl -w
use DBI;
use CGI;
#print "Content-type:test/html";
#print "enter the string value -- ";
#chomp($str=<STDIN>);
@array=(111,33,manish,hello,nas,6633);
#push(@array,$str);
#my $str = "hi friends how";
#print length($str) . "\n";
$data=scalar(@array);
foreach my $name(@array)
{
print "$name\n";
}
print "number of count is $data times\n" ;

