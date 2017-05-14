#!/usr/bin/perl -w
print "please enter your string to search in file here --- = ";
chomp($str=<STDIN>);

while(defined($filedata=<>))
{
while($filedata =~ m/$str/g )
{
print "string exist in file \n ";
}
# print "no data here \n";
}
