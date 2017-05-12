#!/usr/bin/perl -w
print "please enter your name here --- = ";
chomp($name=<STDIN>);

while(defined($filedata=<>))
{
print "$filedata ";
}

print "thanks $name \n";
