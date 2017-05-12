#!/usr/bin/perl


use BugMeNot;
my $url = "http://www.the-times.co.uk";
my @username_and_password = password($url);
print "Username = $username_and_password[0]\n";
print "Password = $username_and_password[1]\n";