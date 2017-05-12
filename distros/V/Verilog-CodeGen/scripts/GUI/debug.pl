#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

use strict;

#-creates Perl object code if none exists
#-otherwise parses code

use Verilog::CodeGen;

my $current='';
my $s=0;
my $d=0;
if(@ARGV){
$current=$ARGV[0];
}

if($current eq '-s') {
$current=$ARGV[1]||'';
$s=1;
$d=0;
}
if($current eq '-sd') {
$current=$ARGV[1]||'';
$s=0;
$d=1;
}
my $design=$ARGV[@ARGV-1];
if($design=~/^\-/){$design=''}
#my $up=($design)?'../':'';

#if($design eq $current){$current=''};
if($design eq $current){$design=''};
my $up=($design)?'../':'';

chdir "DeviceLibs/Objects/$design"; 

my @objs=();
if($current=~/\w_*.*\.pl/){
push @objs,$current;
} else {
@objs=`ls -1 -t *$current*.pl`;
}

if(@objs>0) {
if($current ne '' ) {
print "Found ",scalar(@objs)," files matching $current:\n";
foreach my $item (@objs) {
print "$item";
}
}
 $current=shift @objs;
chomp $current;
} 
if($current eq 'make_module.pl') {
chomp( $current=shift @objs);
}


print '-' x 60,"\n","\tParsing $current for debugging ...\n",'-' x 60,"\n";
if( $current=~/\.pl/) {
my $objname=$current;
$objname=~s/\.pl//;
if(not (-e $current)) {
&create_code_template($objname);
} else {
&create_objtest_code($objname);
system("perl ${objname}.tb");
unlink "${objname}.tb";
}

if($s) {
system("gnuclient -q $current");
}

if($d) {
chdir "$up../../TestObj/$design" or die "$!", `pwd`; 
$current=~s/\.pl//;
system("gnuclient ${current}_default.v");
}
} else {
print "No such file \n";
}
print "\n ... Done\n";
