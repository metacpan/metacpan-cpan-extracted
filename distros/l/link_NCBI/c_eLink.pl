#!/usr/bin/perl 

use eLink;

print "Please enter the following informaion\n";
print "Enter the Database name from where to link?  ";
(chomp($array[0]=<STDIN>));
print "Enter the Database ID?  ";
(chomp($array[1]=<STDIN>));
print "Enter the file name to be created?  ";
(chomp($array[2]=<STDIN>));
print "Enter the server proxy settings in following format\n";
print "useraccount:password\@proxyserver:portname\n";
print "example - user:password\@proxy.xyz.com:4444\n";
(chomp($array[3]=<STDIN>));
print "Link to which database?  ";
(chomp($array[4]=<STDIN>));

eLink::link(@array);
print "Script run successfully\n";

