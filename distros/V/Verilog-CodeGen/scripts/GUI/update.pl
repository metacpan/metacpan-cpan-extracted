#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

use strict;

#-adds new objects to the design library

my $show=0;

if(@ARGV){
$show=$ARGV[0];
}
if($show eq '-s') {
$show=1;
} else {
$show=0;
}

my $design=$ARGV[@ARGV-1]||'';
if($design=~/^\-/){$design=''}
my $up=($design ne '')?'../':'';

chdir "DeviceLibs/Objects/$design";

print '-' x 60,"\n","\tUpdating Verilog.pm ...\n",'-' x 60,"\n";
use Verilog::CodeGen;
#system("perl make_module.pl &");
if(!$design){$design='Verilog'}
&make_module('',$design);
if($show==1){
chdir "$up..";
exec("gnuclient  $design.pm &");
}
print "\n ... Done\n";
