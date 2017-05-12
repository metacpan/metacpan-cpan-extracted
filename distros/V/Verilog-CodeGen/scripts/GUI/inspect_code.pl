#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

use strict;

#This script is a simple glue between the GUI and v2html.

#modify this if you're using a different browser
my $browser="/usr/bin/galeon --geometry=400x600+10+10";

#dillo is very fast, but no CSS support :-(
#$browser="/usr/X11R6/bin/dillo";


my $current='';

if(@ARGV){
$current=$ARGV[0];
}

my $design=$ARGV[@ARGV-1];
if(($design=~/^\-/)||($design eq $current)){$design=''}
my $up=($design)?'../':'';

$current=~s/\.pl//;

chdir "TestObj/$design";


my @objs=`ls -1 -t *$current*.v`;
if(@objs>0) {
if($current ne '' ) {
print "Found ",@objs," files matching $current:\n";
foreach my $item (@objs) {
print "$item";
}
}
 $current=shift @objs;
chomp $current;
} 

print '-' x 60,"\n","\tConverting $current to HTML ...\n",'-' x 60,"\n";
if( $current=~/\.v/) {

#warn("v2html -njshier -ncookies -nsigpopup -o HTML $current");
#system("v2html -njshier -ncookies -nsigpopup -o HTML $current ");
  if (not -e "HTML") {
system("mkdir HTML");
}
system("v2html -o HTML $current ");
print '-' x 60,"\n","\tLaunching browser ...\n",'-' x 60,"\n";

#system("gnome-terminal -e 'lynx HTML/$current.html' &");
system("$browser HTML/$current.html &");


} else {
print "No such file \n";
}
print "\n ... Done\n";
