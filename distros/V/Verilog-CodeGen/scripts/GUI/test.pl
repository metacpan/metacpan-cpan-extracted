#!/usr/bin/perl -w

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.             #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################


use strict;
use Cwd;

### -Creates a testbench if none exists
### -Otherwise runs the testbench

my $current='';
# by default, just open the tb for editing or create from template
my $force=0; 
my $show=0; 
my $run=0; 
my $plot=0;
my $parse=0; 


if(@ARGV){
$current=$ARGV[0];
}
if($current eq '-f') {
$current=$ARGV[1]||'';
$force=1;
}
if($current eq '-yes') {
$current=$ARGV[3]||'';
$parse=1;
$show=1;
if($ARGV[1] eq '-on'){$plot=1}
if($ARGV[2] eq '-on'){$run=1}
}
if($current eq '-no') {
$current=$ARGV[3]||'';
$parse=1;
$show=0;
if($ARGV[1] eq '-on'){$plot=1}
if($ARGV[2] eq '-on'){$run=1}
}

my $design=$ARGV[@ARGV-1]||'';
if($design=~/^\-/){$design=''};
#if($design eq $current){$current=''};
if($design eq $current){$design=''};
my $up=($design ne '' )?'../':'';

#===============================================================================
#
# Get the perl object file 
#

chdir "DeviceLibs/Objects/$design";

my @objs=();
if($current=~/test_.*\.pl/){
push @objs,$current;
} else {
$current=~s/test_//;
@objs=`ls -1 -t *$current*.pl`;
}

if(@objs>0) {
if($current ne '') {
print "Found ",scalar(@objs)," file(s) matching $current:\n";
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

$current=~s/\.pl//;
$current=~s/test_//;

my $tb_template='';
if ($force or (not -e "$up../../TestObj/$design/test_$current.pl")) {
print '-' x 60,"\n","\tCreating test_$current testbench ...\n",'-' x 60,"\n";

my $paramlist='';
my @paramlist=`egrep -e '\=\ *.objref->' $current.pl`;
my %par0val=();
foreach  (@paramlist) {
chomp ;
/^\#|modulename|pins/ && next;
s/^.*{//;
s/}\s*\|\|\s*/=>/;
s/\;.*$//;
my $par0tmp=$_;
my ($par0key,$par0val)=split('=>',$par0tmp);
if($par0key=~/^n/){

$par0val{"${par0key}0"}=$par0val-1;
}
$paramlist.="$_,";

}

my $par0list='';
my $outputs='';
my $regs='';
my $assigns='';
my @pins=`egrep -e 'parameter|input|output|inout' $up../../TestObj/$design/${current}_default.v`;
foreach  (@pins) {
  s/\/\/.*$//;
  if(/output/) {
    my $out=$_;
    chomp $out;
    $out=~s/output\s+//;
    $out=~s/\[.*\]\s+//;
    $out=~s/;.*$//;
    $outputs.=",$out";
  } # if output
  if(/input/) {
    # use to create registers
    my $in=$_;
    chomp $in;
    $in=lc($in);
    $in=~s/input\s+/reg /;
    $regs.="$in\n";
    my $inps=$in;
    $inps=~s/reg\ //;
    $inps=~s/\s*;.*//;
    my @regs=split(',',$inps);
    foreach my $reg (@regs) {
$reg=~s/\[.*\]//;
      my $inp=uc($reg);
      $assigns.="assign $inp=$reg;\n";
    }
  } # if input
s/input|output|inout/wire/;

} # foreach pin
my $pinlist=join('',@pins);

my $b='';
$outputs=~s/^\,//;
my @outputs=split(/\,/,$outputs);
 $outputs='';
my $title='';
foreach my $out (@outputs) {
# build the $display line
$b.=' \%b';
$outputs.=',$x.'.$out;
$title.=" $out";
}
my $defaultdesign='Verilog';
if($design){$defaultdesign=$design};
#if(!$design){$design='Verilog'}

$tb_template='#!/usr/bin/perl -w
use strict;
use lib "'.$up.'..";

use DeviceLibs::'.$defaultdesign.';

################################################################################

my $device=new("'.$current.'",'.$paramlist.');

open (VER,">test_'.$current.'.v");

output(*VER);

modules();

print VER "
module test_'.$current.';
'.$pinlist.'
'.$regs.'
'.$assigns.'
reg _ck;
";
$device->instance();
my $x=$device->{""};

print VER "
// clock generator
always begin: clock_wave
   #10 _ck = 0;
   #10 _ck = 1;

end

always @(posedge _ck)
begin
\$display(\" \%0d '.$b.' \",\$time'.$outputs.');
end

initial 
begin
\$display(\"Time '.$title.'\");

//      \$dumpfile(\"test_'.$current.'.vcd\");
//      \$dumpvars(2,test_'.$current.');

#25;

\$finish;
end
endmodule
";
close VER;
run("test_'.$current.'.v");
#plot("test_'.$current.'.v");

';
} # created testbench

chdir "$up../.."; #to root
chdir "TestObj/$design" or die "$!: TestObj/$design";
#Create testbench code
if ($force or (not -e "test_$current.pl")) { # force overwrite or file did not exits
open(TB,">test_$current.pl");
print TB $tb_template;
close TB;
}  

if($parse) {
  print "\n",'-' x 60,"\n","\tParsing test_$current.pl testbench ...\n",'-' x 60,"\n";
  if($run) {#run
    if ($plot) {# plot
      system("perl -p -i -e 'if(/dump/){s/^\\/+//};s/^\\#plot/plot/;s/^\\#run/run/;' test_$current.pl");
    } else {# no plot
      system("perl -p -i -e 'if(/dump/){s/^/\\/\\//};s/^plot/\\#plot/;s/^\\#run/run/;' test_$current.pl");
    }
  } else {#don't run
    system("perl -p -i -e 'if(/dump/){s/^/\\/\\//};s/^plot/\\#plot/;s/^run/\\#run/;' test_$current.pl");
  }
  system("perl test_$current.pl");
  
  if($show) {
    system("gnuclient test_$current.v &");
  } elsif(!$run) {
print `cat test_$current.v`; #cheap!
}
} else {
#print '-' x 60,"\n","\tDisplaying test_$current.pl testbench ...\n",'-' x 60,"\n";
system("gnuclient -q test_$current.pl &");
}

print "\n ... Done\n";
