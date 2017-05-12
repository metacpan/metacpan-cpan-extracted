#!/usr/bin/perl -w
print "please enter your string to search in file here --- = ";
chomp($str=<STDIN>);
$cnt=0;
while(defined($filedata=<>))
{
while($filedata =~ m/$str/g )
{
$cnt=$cnt+1;
}
}
print "string exist in file $cnt times\n ";

# print "no data here \n";

