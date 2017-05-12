package Verilog::CodeGen;

use vars qw( $VERSION );
$VERSION='0.9.4';

#################################################################################
#                                                                              	#
#  Copyright (C) 2002,2003 Wim Vanderbauwhede. All rights reserved.                  #
#  This program is free software; you can redistribute it and/or modify it      #
#  under the same terms as Perl itself.                                         #
#                                                                              	#
#################################################################################

#print STDOUT "//Package Verilog::CodeGen loaded\n";

use sigtrap qw(die untrapped normal-signals
               stack-trace any error-signals); 

use strict;

################################################################################

 @Verilog::CodeGen::ISA = qw(Exporter);
 @Verilog::CodeGen::EXPORT =qw(
		&make_module
		&create_objtest_code
		&create_code_template
	       );


#Modify this to use different compiler/simulator/viewer
my $compiler="/usr/bin/iverilog";
my $simulator="/usr/bin/vvp";
my $vcdviewer="/usr/local/bin/gtkwave";

# to store the module code for all modules
my %modules;

# for print configuration
my %printcfg=(_fh=>*STDOUT,_fn=>'');

#------------------------------------------------------------------------------
#object constructor
  sub new {
#next 2 lines are fine in general, but for me a fixed class is better (saves typing)
#my $invocant=shift;
#my $class=ref($invocant) || $invocant;
my $class="Verilog::CodeGen";
my @keysvals=@_;
if ($keysvals[0] ne 'type'){unshift @keysvals,'type';unshift @_,'type'}
my @keys=();
my @args=();
while (@keysvals) { 
push @keys, shift @keysvals; 
push @args, shift @keysvals; 
}

#this is extremely redundant: the hash contains an array with its keys and an array with its values, so everything is there twice!!
#but it's convenient

my $self= { '_keys'=>[@keys],'_args'=>[@args],@_ };

my $modulekey=join('_',@args);
$modulekey=~s/\.//g;
$self->{modulename}=$modulekey;

my $sub=$self->{type};
$sub='gen_'.$sub;
SOFTREF: {
no strict "refs";
$self->{code}=&$sub($self);
}
#eval never works as it should for me
#eval('$self->{code}= &'.$sub.'($self);');

bless($self,$class);

$modules{$modulekey}=$self->{code};

return $self;    
  }

#===============================================================================

# this is a class method to set the print options
sub output {
my $invocant=shift;
my $arg=$invocant;
if($invocant=~/=HASH\(0x/) {
     $arg=shift;
   } 
  my $fh;
  my $filename;
if(!$arg || $arg!~/\n|\s/m) { # store the attributes

  if(!$arg) {
    $fh=*STDOUT;
  } elsif (scalar($arg)!~/^\*/ ) {
    $filename=$arg;
    $fh=*_VER;
  } else { 
    $fh=$arg;
  }
$printcfg{_fh}=$fh;
  if($filename){
$printcfg{_fn}=$filename;
unlink $filename;
}
} else { # print the string
my $fh=$printcfg{_fh}||*STDOUT;
my $filename=$printcfg{_fn};

  if($filename) {
    open $fh,">>$filename";
  }

  print $fh $arg;

  if($filename) {
    close $fh;
  }

}
return $arg;
}
#===============================================================================
#this is a class method to print all currently used modules
sub modules {
my $fh=$printcfg{_fh}||*STDOUT;
my $filename=$printcfg{_fn};

  if($filename) {
    open $fh,">>$filename";
  }
foreach my $key (keys %modules) {
print $fh "
//
// $key
//
";
  print $fh $modules{$key};
print $fh "

//============================================================================== 

";
}
 if($filename) {
    close $fh;
  }
}

#===============================================================================

sub module {
my $objref=shift;
$objref->output($objref->{code});
}

#===============================================================================
# this is what the enduser uses to print instances
sub instance {
my $objref=shift;

my $suffix=shift ; # throw away 'suffix'

if($suffix) {
if($suffix eq 'suffix'){
$suffix=shift;
}
} else {$suffix=''}

# get module pins
my $modpins=$objref->{pins};
$modpins=~s/[)(]//g;
$modpins=~s/\s+//g;
my @modpins=split(',',$modpins);
my %pinlist=();
# assign to nets with same name as default
foreach my $modpin (@modpins) {
$pinlist{$modpin}='.'.$modpin.'('.$modpin.')';
}

# override defaults 
while (@_) {
my $pin=shift;
my $net=shift;
$pinlist{$pin}='.'.$pin.'('.$net.')';
}

my @pinlist=();
foreach my $key (keys %pinlist) {
push @pinlist,$pinlist{$key};
}

my $pins;
if(@pinlist>1) {
$pins=join(',',@pinlist)
} else {$pins=$pinlist[0]}
my @args=@{$objref->{'_args'}};
my $args=join('_',@args);
$args=~s/\.//g;

my $instlabel="x_${args}_$suffix";
my $instline= "$args $instlabel ($pins);\n";
# this is fancy and unnecessary, but anyway
# all instances of a given object
$objref->{_instances}->{$suffix}=$instline;
$objref->{$suffix}=$instlabel;
# we need: $objname->{$suffix} => $instlabel
$objref->output($instline);
}
#===============================================================================
# this is for use inside modules
# no print, just return the string
sub inst {
my $objref=shift;

my $suffix=shift ; # throw away 'suffix'
if($suffix) {
if($suffix eq 'suffix'){
$suffix=shift;
}
}else {$suffix=''}
# get module pins
my $modpins=$objref->{pins};
$modpins=~s/[)(]//g;
$modpins=~s/\s+//g;
my @modpins=split(',',$modpins);
my %pinlist=();
# assign to nets with same name as default
foreach my $modpin (@modpins) {
$pinlist{$modpin}='.'.$modpin.'('.$modpin.')';
}

# override defaults 
while (@_) {
my $pin=shift;
my $net=shift;
$pinlist{$pin}='.'.$pin.'('.$net.')';
}

my @pinlist=();
foreach my $key (keys %pinlist) {
push @pinlist,$pinlist{$key};
}

my $pins;
if(@pinlist>1) {
$pins=join(',',@pinlist)
} else {$pins=$pinlist[0]}
my @args=@{$objref->{'_args'}};
my $args=join('_',@args);
$args=~s/\.//g;

my $instlabel="x_${args}_$suffix";
my $instline= "$args $instlabel ($pins);\n";
# this is fancy and unnecessary, but anyway
$objref->{_instances}->{$suffix}=$instline;
$objref->{$suffix}=$instlabel;
return $instline;

}

#===============================================================================

sub search {
my $objref=shift;
my $pattern=shift;
my $result='';
my @code=split("\n",$objref->{code});
foreach my $line (@code){
  if($line=~/$pattern/){
#print STDOUT "$line\n";
$result.= "$line\n";
}
}
return $result;
}
#===============================================================================

sub find_inst { # returns an array ref if multiple instances!
my $objref=shift;
my $pattern=shift;
my @result=();
my @code=split("\n",$objref->{code});
foreach my $line (@code){

  if($line=~/$pattern.*$pattern/) {
my $instlabel=$line;
$instlabel=~s/^.*?\s+//;
$instlabel=~s/\s.*$//;
push @result, $instlabel;
}
}
  if (@result>1){
return [@result];
} else {
return $result[0];
}


}
#===============================================================================
# a class method to run the netlist through Icarus Verilog
sub run {
my $netlist=shift;
if(scalar($netlist)=~/=HASH\(0x/){
$netlist=shift;
}

if(!$netlist) {
$netlist=$printcfg{_fn};
}
#$netlist=~/\.v$/ || $netlist.='.v';
if ($netlist){
system("$compiler -o${netlist}vp $netlist");
system("$simulator ${netlist}vp");
} else {print STDERR "The run() method only works if the netlist is printed to a file.\n"}
}
#===============================================================================
# a class method to plot the results with GTKWave
sub plot {
my $netlist=shift;
if(scalar($netlist)=~/=HASH\(0x/){
$netlist=shift;
}

if(!$netlist) {
$netlist=$printcfg{_fn};
}
#$netlist=~/\.v$/ || $netlist.='.v';
if (-e "${netlist}cd"){
# send output to /dev/null to avoid blocking the socket!
system("$vcdviewer ${netlist}cd >& /dev/null &");

} else {print STDERR "The plot() method only works if the netlist is printed to a file.\n"}
}

################################################################################ 

#function to convert decimal to binary
sub dec2bin {

    my $dec=shift;
    my $nbits=shift;
    my @Q=();
	for my $nr (0..$nbits-1) {
	    my $n=$nbits-1-$nr;
		if(($dec-2**$n)<0) {
#MSB=left		    unshift @Q,'0';
		    push @Q,'0';
		}
	    else
	    {
#		unshift @Q, '1';
		push @Q, '1';
		$dec=$dec-2**$n;
		}
	}
    return [@Q];
  } # END of dec2bin


#===============================================================================
sub splitbus {
# bus[n0:0] => a[n0a:0],b[n0b:0],...
# busname, width
# sum of all widths=width of original bus
my @nets=@_;
my $busname=shift @nets;
my $buswidth=shift @nets;

my $fullwidth=0;

# an addition for the frequent case of equidistant split:
if(@nets==1) {
my $n=shift(@nets);
foreach my $i (0..$n-1) {
  $nets[2*$i+1]=$buswidth/$n;
  $nets[2*$i]=$busname.$i;
}
 $fullwidth=$buswidth;
} else {
foreach my $i (0..@nets/2-1) {
$fullwidth+=$nets[2*$i+1];
}
}
my $code="//generated with splitbus() function\n";

if($fullwidth>$buswidth){
  $code="//sum of width exceeds original bus width\n";
  return $code;
}
if($fullwidth<$buswidth){
  $code="//sum of width is smaller than original bus width\n";
}

my $begin=$fullwidth;
foreach my $i (0..@nets/2-1) {
  my $width=$nets[2*$i+1];
  my $name=$nets[2*$i];
  foreach my $b (1 ..$width) {
#    my $i=$width-$b;
    my $i=$b-1;
#    my $bb=$begin-$b;
    my $bb=$buswidth-($begin-$b)-1;
    $code .="buf xBUF$name$b ($name\[$i\],$busname\[$bb\]);\n";
  }
  $begin-=$width;
}
return $code;
} # END of splitbus

#===============================================================================
sub combinebus {
# bus[n0:0] => a[n0a:0],b[n0b:0],...
# busname, width
# sum of all widths=width of original bus
my @nets=@_;
my $busname=shift @nets;
my $buswidth=shift @nets;
my $fullwidth=0;

# an addition for the frequent case of equidistant split:
if(@nets==1) {
my $n=shift(@nets);
foreach my $i (0..$n-1) {
  $nets[2*$i+1]=$buswidth/$n;
  $nets[2*$i]=$busname.$i;
}
 $fullwidth=$buswidth;
} else {
foreach my $i (0..@nets/2-1) {
$fullwidth+=$nets[2*$i+1];
}
}

my $code="//generated with combinebus() function\n";

if($fullwidth>$buswidth){
  $code="//sum of width exceeds destination bus width\n";
  return $code;
}
if($fullwidth<$buswidth){
  $code="//sum of width is smaller than destination bus width\n";
}

my $begin=$fullwidth;
foreach my $i (0..@nets/2-1) {
  my $width=$nets[2*$i+1];
  my $name=$nets[2*$i];
  foreach my $b (1 ..$width) {
#    my $i=$width-$b;
    my $i=$b-1;
#    my $bb=$begin-$b;    
my $bb=$buswidth-($begin-$b)-1;

    $code .="buf xBUF$name$b ($busname\[$bb\],$name\[$i\]);\n";
  }
  $begin-=$width;
}
return $code;
} # END of combinebus

#===============================================================================
sub make_module {
my $skip=shift||'';
my $design=shift||'Verilog';

my $up='';
if($design eq 'Verilog') {
use Cwd;
my $dir=cwd();
$dir=~s/.*\///;
#we assume that a chdir to the design dir has been done
if($dir ne 'Objects') {$design=$dir; $up='../'}
} else {  $up='../' }

my $moduledir='DeviceLibs';

if($skip eq ''){
$moduledir=($design ne 'Verilog')?'../..':'../';
} else {
my @v=<$up../*.v>;
if(@v) {
system("cp $up../*.v ../DeviceLibs");
}
}
my $date=`date`;
chomp $date;
my $me=`whoami`;
chomp $me;

my $header="
#
# Generated using Verilog::CodeGen::make_module
# from Objects/*.pl
#
# by $me on $date
#
";
if (($moduledir!~/\.\./)&& (not -d "$moduledir")){mkdir  "$moduledir", 0755;}
open(OUT,">$moduledir/$design.pm"); # .. ,../.. or DeviceLibs
my $modulepath=$INC{'Verilog/CodeGen.pm'};
open(IN,"<$modulepath");
while(<IN>) { 
s/Verilog::CodeGen/DeviceLibs::$design/;
/\s+\&make_module/ && next;
/\s+\&create_objtest_code/ && next;
/\s+\&create_code_template/ && do {
print OUT '
		%modules
		%printcfg
		&new
		&output
		&instance
		&inst
		&module
		&modules
		&run
		&plot
		&dec2bin
		&splitbus
		&combinebus
';
next;
};
print OUT $_;
if(/use\ strict;/){
print OUT $header;
}

}
close IN;

my @objects=<*.pl>;

foreach my $obj (@objects) {
$obj=~/R_/ && next;
  if($obj ne "$skip.pl"){
open(IN,"<$obj");
my $ok=0;
print OUT "
#===============================================================================
# $obj
";
while(<IN>){
  if(/^sub/){$ok=1}
  if($ok==1){
print OUT $_;
}
}
close IN;
}
}
close OUT;

} # END of make_module()

#===============================================================================
sub create_code_template {
my $objname=shift;
my $design=shift||'Verilog';

if($design eq 'Verilog') {
use Cwd;
my $dir=cwd();
$dir=~s/.*\///;
if($dir ne 'Objects') {$design=$dir; }
} 

#-------------------------------------------------------------------------------
my $templ=<<'ENDTEMPL';
sub gen_code_template {

#purpose

#args: varname

my $objref=shift;
my $varname=$objref->{varname}||'DEFAULT';

my $pins="(P1,...,Pn)";
my $modname=$objref->{modulename};
my $code = "
module $modname $pins;
";
$code.='//module code';
$code .="
endmodule // $modname
";

$objref->{pins}=$pins;
return $code;

} # END of gen_code_template

ENDTEMPL
#-------------------------------------------------------------------------------

 $templ=~s/code_template/$objname/gms;
 $templ=~s/DesignName/$design/gms;

open(OBJ,">$objname.pl");
print OBJ $templ;
close OBJ;

} # END of create_code_template
#===============================================================================
sub create_objtest_code {
my $objname=shift;
my $design=shift||'Verilog';

if($design eq 'Verilog') {
use Cwd;
my $dir=cwd();
$dir=~s/.*\///;
if($dir ne 'Objects') {$design=$dir; }
} 

#-------------------------------------------------------------------------------
my $templ=<<'ENDHEADER';
#!/usr/bin/perl -w
use strict;

###############################################################################
### This part makes it possible to test the object. ###
my $obj='code_template';
my $design='DesignName';
my $up='';
if(-d "../$design"){$up='../'}
BEGIN {
use Verilog::CodeGen;
&make_module('code_template','DesignName');
}
use lib '.';
use DeviceLibs::DesignName;

my $test=new("$obj");
my $code= $test->{code};

print $code;
($design eq 'Verilog') && ($design='');
chdir("$up../../TestObj/$design");

open (VER,">${obj}_default.v");
print VER $code;
close VER;

package DeviceLibs::DesignName;

###############################################################################
### The actual object code starts here ###

ENDHEADER
#-------------------------------------------------------------------------------

 $templ=~s/code_template/$objname/gms;
 $templ=~s/DesignName/$design/gms;

open(OBJ,"<$objname.pl");
while(<OBJ>){
$templ.=$_;
}
close OBJ;

open(OBJ,">$objname.tb");
print OBJ $templ;
close OBJ;

} # END of create_objtest_code
#===============================================================================
################################################################################
=head1 NAME

B<Verilog::CodeGen> - Verilog code generator

=head1 SYNOPSIS

  use Verilog::CodeGen;

  mkdir 'DeviceLibs/Objects/YourDesign', 0755;
  chdir 'DeviceLibs/Objects/YourDesign';
  
  # if the directory YourDesign exists, the second argument can be omitted 
  # create YourModule.pl in YourDesign 
  &create_template_file('YourModule','YourDesign'); 

  # create a device library for testing in DeviceLibs/Objects/DeviceLibs
  &make_module('YourModule','YourDesign');

  # create the final device library in DeviceLibs (once YourModule code is clean)
  &make_module('','YourDesign');

=head1 USAGE

The most efficient way to use the code generator is using the GUI (L<scripts/gui.pl> in the distribution). Read the documentation in L<Verilog::CodeGen::Gui.pm>). Alternatively, you can use the scripts that the GUI uses to do the work (in the scripts/GUI folder). If you want to make your own, follow the L<SYNOPSIS>.

Then edit the file YourModule.pl in the folder DeviceLibs/Objects/YourDesign. 

For example:

	sub gen_YourModule {	
	my $objref=shift;
	my $par=$objref->{parname}||1;

	# Create Objects

	my $submodule=new('SubModule',parname1=>$par);

	# Instantiate
	
	my $pins="(A,Z)";
	my $modname=$objref->{modulename};
	my $code = "
	module $modname $pins;
	input A;
	output Z;
	";
	$code.=$submodule->inst('suffix',P1=>'A');
	$code .="
	endmodule // $modname
	";
	$objref->{pins}=$pins;
	return $code;
	} # END of gen_YourModule


Then run C<perl YourModule.pl> to check if the code produces valid a Verilog module.

If this is the case, add YourModule to the device library with C<&make_module()>

Next, create a testbench test_YourModule.pl in a directory on the same level as DeviceLibs (TestObj if you use the GUI):
	
	use lib '..';
	use DeviceLibs::YourDesign;

	my $device=new("S_buffer_demux",depth=>7,);

	open (VER,">test_S_buffer_demux.v");

	output(*VER);

	modules();

	print VER "
	module test_S_buffer_demux;
	   wire A;
	   wire [7:0] S;
	   wire [6:0] Z;
	   wire D;
	
	   reg a;
	   reg [7:0] s;
	
	assign    A=   a;
	assign     S=    s;
	
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
	\$display(\" \%0d  \%b \%b \",\$time,$x.   Z,$x.   D);
	end

	initial 
	begin
	\$display(\"Time     Z    D\");
	a<=1;
	#25;
	a<=0;
	#25;
	\$finish;
	end
	endmodule
	";
	close VER;
	run("test_S_buffer_demux.v");
	#plot("test_S_buffer_demux.v");

Execute the testbench script with C<perl test_YourModule.pl>.

=head1 DESCRIPTION

Provides an  object-oriented environment to generate Verilog code for modules and testbenches. The Verilog::CodeGen module provides two functions, one to create a code template and another to create a Perl module which contains the device library. This module , DeviceLibs::YourDesign, provides the class methods and contains the objects for every Verilog module; the objects are created based on a fixed template.
The purpose of this module is to allow the generation of customized Verilog modules. A Verilog module can have a large number of parameters like input and output bus width, buffer depth, signal delay etc. The code generator allows to create an object that will generate the Verilog module code for arbitraty values of the parameters.

=head1 UTILITY SCRIPTS

With the Perl module distribution come a number of utility scripts. The most important one is gui.pl, a GUI frontend for Verilog development using the code generator.

=head1 MAIN METHODS

=head2 B<new>(I<$object_name>[,%attributes]);

Create a new Verilog module object. The object attributes are optional, the object should provide reasonable defaults.

=head2 B<output([*filehandle_ref||$filename])>

output() takes a reference to a filehandle or a filename as argument. These are stored in the global %printcfg. Without arguments, this defaults to STDOUT.
If output() is called with as argument a string containing \n and/or \s, this string is printed on the current filehandle.

=head2 B<modules>

The code generator stores all submodules of a given module in the global %modules. Calling modules() prints the code for these modules on the current filehandle.

=head2 B<instance([$instance_suffix,%connectivity])>

The instance() method will print the code for the instantiation of the object on the current filehandle. An optional instance suffix can be specified (to distinguish between different instances of the same module), as well as the pin connectivity. If the connectivity for a pin is not specified, it defaults to the pin name. 

=head2 B<inst([$instance_suffix,%connectivity])>

The inst() method will return the code for the instantiation of the object as a string. An optional instance suffix can be specified (to distinguish between different instances of the same module), as well as the pin connectivity. If the connectivity for a pin is not specified, it defaults to the pin name. 

=head2 B<run([$filename])>

Run the netlist through the Icarus Verilog (http://www.icarus.com) open source verilog simulator. The filename is optional if it was specified with the output() method.

=head2 B<plot([$filename])>

Plot the result of the simulation with gtkwave. For this purpose, the \$dumpvar and \$dumpfile compiler directives must be present in the testbench code. The filename is optional if it was specified with the output() method.

=head2 B<module('modulename')>

This method can be used to print the code for a specified module on the current filehandle.

=head2 B<search(/pattern/)>

Search the verilog code for a given pattern.

=head2 B<find_inst(/pattern/)>

Find all instances matching /pattern/ in the netlist.

=head1 MAIN ATTRIBUTES

=head2 B<{$instance_suffix}>

Returns the full instance name of the object. 
$x=$object->{$instance_suffix};

=head1 TODO

=over

=item *

Convert the utility scripts to functions to be called from Verilog::CodeGen.

=item *

Put the GUI scripts in a module Gui.pm.

=item *

Separate the code for testing purposes from the module object code.

=back

=head1 SEE ALSO

Icarus Verilog L<http://icarus.com/eda/verilog/index.html>

=head1 AUTHOR

W. Vanderbauwhede B<wim@motherearth.org>.

L<http://www.comms.eee.strath.ac.uk/~wim>

=head1 COPYRIGHT

Copyright (c) 2002 Wim Vanderbauwhede. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
