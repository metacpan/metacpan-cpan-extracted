#!/usr/bin/perl 

use egQuery;

print "Please enter the following informaion\n";
print "Enter the term?  ";
(chomp($array[0]=<STDIN>));
print "Enter the file name to be created?  ";
(chomp($array[1]=<STDIN>));
print "Enter the server proxy settings in following format\n";
print "useraccount:password\@proxyserver:portname\n";
print "example - user:password\@proxy.xyz.com:4444\n";
(chomp($array[2]=<STDIN>));

egQuery::query(@array);
print "Script run successfully\n";

