#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

use strict;

#This script is called for new designs.
#It creates the directory structure and the design library

my $design=(@ARGV)?$ARGV[0]:'';

if(! -d "DeviceLibs") {
mkdir "DeviceLibs",0755;
mkdir "DeviceLibs/Objects",0755;
mkdir "DeviceLibs/Objects/DeviceLibs",0755;

mkdir "TestObj",0755;
mkdir "Schematics",0755;
mkdir "Diagrams",0755;
}
if($design && !(-d "DeviceLibs/Objects/$design")) {
print "Creating $design design\n";
mkdir "DeviceLibs/Objects/$design",0755;
mkdir "DeviceLibs/Objects/$design/DeviceLibs",0755;
mkdir "TestObj/$design",0755;
mkdir "Schematics/$design",0755;
mkdir "Diagrams/$design",0755;

use Verilog::CodeGen;
chdir "DeviceLibs/Objects/$design";
if(!$design){$design='Verilog'};
&make_module('Empty',$design);
 }

#create .vcgrc file which contains current design
if (!$design) {$design = 'Verilog'}
open(VCG,'>.vcgrc');
print VCG "$design\n";
close VCG;

