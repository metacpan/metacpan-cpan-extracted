#!/usr/bin/perl -w
use strict;
use warnings;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
my $cgi=new CGI;
#get input
my $name= $cgi -> param('name');
my $email= $cgi -> param('email');
my $loc= $cgi -> param('loc');
my $comments = $cgi -> param('comments');

#give output

print $cgi -> header,
$cgi -> start_html('guestbook result'),
$cgi -> h1("guestbook result");
print "<p> $name ,thanks for using this page submission 
program<br> </p>";

print $cgi-> table(
                  $cgi -> Tr($cgi-> td(['Name',"$name"])),
                  $cgi -> Tr($cgi-> td(['email',"$email"])),
                  $cgi -> Tr($cgi-> td(['loc',"$loc"])),
                 $cgi -> Tr($cgi-> td(['comments',"$comments"]))
);

print $cgi-> end_html;


#open guest book file

open(FILE,">>guests.txt") or die "can't open the file \n";
#write the info into file
print FILE "$name came from $loc";
print FILE "E-mail address is  $email";
print FILE "comments : $comments \n";

close(FILE);
