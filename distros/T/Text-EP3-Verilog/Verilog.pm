package Text::EP3::Verilog;

=head1 NAME

Text::EP3::Verilog - Verilog extension for the EP3 preprocessor.

=head1 SYNOPSIS

  use Text::EP3;
  use Text::EP3::Verilog;

=head1 DESCRIPTION

This module is an EP3 extension for the Verilog Hardware Description Language.

=over 4 

=item The signal directive

@signal key definition
Take a list of signals and generate signal lists in the differing formats
that Verilog uses.
This is accomplished by formatting a list of new defines and then calling
the EP3 define method
For example, the following command: 

	@signal KEY a[3:0], b, c[width:0], etc.

will cause the following to be done:

	Define KEY with the list as it appears (can be used in further signal defs)
	Define KEY{SIG} with the signal list (can be used in port lists)
   	e.g. replace KEY{SIG} with  a[3:0], b, c[width:0]
	Define KEY{EVENT} with the reg list  (To be used in event lists)
   	e.g. replace KEY{EVENT} with a or b or c
	Define KEY{IN}  with the input list (you supply the first input and the trailing ';'
   	e.g. replace KEY{INPUT} with [3:0] a;\ninput b;\ninput[width:0] c
   	or ... make the line 
   	input KEY{INPUT}; become ..
   	input [3:0] a;
   	input b;
   	input [width:0] c;
	Define KEY{OUT} with the output list (output [] sig).
   	e.g. like KEY{IN}
	Define KEY{INOUT}  with the inout list (inout [] sig).
   	e.g. like KEY{IN}
	Define KEY{WIRE} with the wire list (wire [] sig).
   	e.g. like KEY{IN}
	Define KEY{REG} with the reg list (reg [] sig).
   	e.g. like KEY{IN}
	Define KEY{DSP} with the printf list (sig=%0[b|x] depending on width).
   	e.g. replace KEY{DSP} with a=%0x, b=%0b, c=%0x
   	This can be used in the $display task
      	$display("KEY{DSP}",KEY{SIG});

If the module and the test bench default is set up properly, the user needs
only enter the signals in one place in the module file. This section can be
included conditionally (e.g. @include "file" PORT) in the test bench and the
signals can be automatically generated in the correct format in whichever
header they are used. This means that a user can produce a module and its test
bench by simply filling in the port list, the behavioral code, and the
stimulus (which is of course, the real work). All of the signal header crud
can be taken care of automagically.

=item The step directive 

@step number [command]
The step directive is useful to save verbage in test benches. @step 5 command;
generates the following code:

	repeat 5 @ (posedge tclk); command;

The posdege can be changed to '' or negedge (or whatever) using the edgetype
directive. The tclk can be changed using the edgename directive.

=item The edgename directive

@edgename name
The edgename directive allows the user to change the name used in the step
directive. The default is 'tclk'.

=item The edgetype directive

@edgetype type
The edgetype directive allows the user to change the type used in the step
directive. The default is 'posedge'.

=item The denum directive

@denum key, key, [value], key, ...
denum works like the ep3 enum, except that it generates
verilog define statements. It also replaces KEY anywhere
in the text with `KEY so that the verilog defines will work.
(e.g. @denum orange, blue, green     will generate:

	`define orange 0
	`define blue 0
	`define green 0
	@define orange `orange
	@define blue `blue
	@define green `green


=back

=head1 AUTHOR

Gary Spivey, 
Dept. of Defense, Ft. Meade, MD.
spivey@romulus.ncsc.mil

=head1 SEE ALSO

perl(1).

=cut
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use AutoLoader;
use Carp;

use Exporter;

@ISA = qw(Exporter AutoLoader);
# ************  IMPORTANT FOR ALL EP3 MODULES ***********
# Tell EP3 to inherit methods from this module ...
# This is necessary to let EP3 know about the methods ...
push (@Text::EP3::ISA, qw(Text::EP3::Verilog));
# *******************************************************
# Set up default values



@EXPORT = qw(
);
$VERSION = '1.00';

sub edgename;
sub edgetype;
sub denum;
sub signal;
sub step;
1;

__END__
sub signal {
# Signal replacement method.
# usage: @signal signame | signame[width1:width2], etc. 
# Take a list of signals and generate signal lists in the differing formats
# that Verilog uses.
# This is accomplished by formatting a list of new defines and then calling
# the EP3 define method
#   @signal KEY a[3:0], b, c[width:0], etc.
# and 
# Replace KEY with the list as it appears (can be used in further signal defs)
# Replace KEY{SIG} with the signal list (can be used in port lists)
#    e.g. replace KEY{SIG} with  a[3:0], b, c[width:0]
# Replace KEY{EVENT} with the reg list  (To be used in event lists)
#    e.g. replace KEY{EVENT} with a or b or c
# Replace KEY{IN}  with the input list (you supply the first input and the trailing ';'
#    e.g. replace KEY{INPUT} with [3:0] a;\ninput b;\ninput[width:0] c
#    or ... make the line 
#    input KEY{INPUT}; become ..
#    input [3:0] a;
#    input b;
#    input [width:0] c;
# Replace KEY{OUT} with the output list (output [] sig).
#    e.g. like KEY{IN}
# Replace KEY{INOUT}  with the inout list (inout [] sig).
#    e.g. like KEY{IN}
# Replace KEY{WIRE} with the wire list (wire [] sig).
#    e.g. like KEY{IN}
# Replace KEY{REG} with the reg list (reg [] sig).
#    e.g. like KEY{IN}
# Replace KEY{DSP} with the printf list (sig=%0[b|x] depending on width).
#    e.g. replace KEY{DSP} with a=%0x, b=%0b, c=%0x
#    This can be used in the $display task
#       $display("KEY{DSP}",KEY{SIG});
#
    my $self  = shift;
    my @input_string = @_;
    my ($inline, $directive, $key);
    my ($busstring , $sigstring , $dspstring , $instring , $outstring , $inoutstring , $wirestring , $regstring , $eventstring );
    my (@string, $signals, $reg, $input, $output, $inout, $event, @siglist, $sig, $bus, $newkey);
 
    $busstring = $sigstring = $dspstring = $instring = $outstring = $inoutstring = $wirestring = $regstring = $eventstring  = '';
 
    $inline = $input_string[0];
    @string = split(' ',$inline);
 
    print "$self->{Line_Comment}EP3->signal: Entered signal.  Line $Text::EP3::line of $Text::EP3::filename  The key is $string[1]\n"	if $self->{Debug} & 1;
 
    # parse key string
    $directive = shift @string;
    $key = shift @string;
    $signals =  join(' ',@string);
 
    my $wire = $reg = $input = $output = $inout =  $event = ''; #Empty the first time through
  
    $signals =~ s/ //g;
    @siglist = split(',',$signals);
    foreach $sig (@siglist)
    {
        next if ($sig =~/^\s*$/); # skip it if it is a blank - could have been preprocessed away
        if ($sig =~ /(\[.*\])/)    # if it is a bus
        {
            $bus = $1;
            $bus =~ s/ //g;
            $sig  =~ s/\[.*\]//;
            $dspstring.="$sig=%0x,";
            $wirestring.="$wire$bus $sig;\n";
            $regstring.="$reg$bus $sig;\n";
            $instring.="$input$bus $sig;\n";
            $inoutstring.="$inout$bus $sig;\n";
            $outstring.="$output$bus $sig;\n";
        }
        else
        {
            $dspstring.="$sig=%0b,";
            $wirestring.="$wire$sig;\n";
            $regstring.="$reg$sig;\n";
            $instring.="$input$sig;\n";
            $inoutstring.="$inout$sig;\n";
            $outstring.="$output$sig;\n";
        }
  
        $sigstring.="$sig,";
        $eventstring.="$event$sig";
  
        $input = 'input ';
        $output = 'output ';
        $inout = 'inout ';
        $wire = 'wire ';
        $reg = 'reg ';
        $event = ' or ';
    }
 
    #remove trailing semicolon
    $sigstring =~ s/,$//;
    $dspstring =~ s/,$//;
    $instring =~ s/;\n$//;
    $inoutstring =~ s/;\n$//;
    $outstring =~ s/;\n$//;
    $wirestring =~ s/;\n$//;
    $regstring =~ s/;\n$//;
 
    $directive = $self->{Delimeter} . "define";
    
    $newkey = $key."{SIG}";
    $sigstring = $directive.' '.$newkey.' '.$sigstring;
    $self->define($sigstring);
 
    $newkey = $key."{DSP}";
    $dspstring = $directive.' '.$newkey.' '.$dspstring;
    $self->define($dspstring);
 
    $newkey = $key."{IN}";
    $instring = $directive.' '.$newkey.' '.$instring;
    $self->define($instring);
 
    $newkey = $key."{OUT}";
    $outstring = $directive.' '.$newkey.' '.$outstring;
    $self->define($outstring);
 
    $newkey = $key."{INOUT}";
    $inoutstring = $directive.' '.$newkey.' '.$inoutstring;
    $self->define($inoutstring);
 
    $newkey = $key."{WIRE}";
    $wirestring = $directive.' '.$newkey.' '.$wirestring;
    $self->define($wirestring);
 
    $newkey = $key."{REG}";
    $regstring = $directive.' '.$newkey.' '.$regstring;
    $self->define($regstring);
 
    $newkey = $key."{EVENT}";
    $eventstring = $directive.' '.$newkey.' '.$eventstring;
    $self->define($eventstring);
 
    # Define the key as the list with the define directive
    # Do this last to avoid conflicts with the preceding defines.
    $self->define($directive.' '.$key.' '.$signals);
}


sub edgetype {
# change the edgetype used in the step directive
# usage: @edgetype type
    my $self = shift;
    return $self->{Edgetype} if (! @_);
    my @string = split(' ',$_[0]);
    print "$self->{Line_Comment}EP3->edgetype: Entered edgetype.  Line $Text::EP3::line of $Text::EP3::filename\n" if $self->{Debug} & 1;
 
    shift @string;
    $self->{Edgetype} =  join(' ',@string);
    chomp $self->{Edgetype};
    $self->{Edgetype};
}

sub edgename {
# change the edgename used in the step directive
# usage: @edgename name
    my $self = shift;
    return $self->{Edgename} if (! @_);
    my @string = split(' ',$_[0]);
    print "$self->{Line_Comment}EP3->edgename: Entered edgename.  Line $Text::EP3::line of $Text::EP3::filename\n" if $self->{Debug} & 1;
 
    shift @string;
    $self->{Edgename} =  join(' ',@string);
    chomp $self->{Edgename};
    $self->{Edgename};
}

sub step {
# provide a simple command to advance simulation n steps in a test bench
# usage: @step value [command;] 
# step will replace the directive line with one like the following
#  repeat value @ posedge Edgename; command;
#  in my test benches, I use a tclk which is formed an offset from the clock.
#  I step some number of tclks and then do set whatever things I want to
#  change.
    my $self = shift;
    my @string = split(' ',$_[0]);
    my ($directive, $steps, $command);
    print "$self->{Line_Comment}EP3->step: Entered step.  Line  $Text::EP3::line of $Text::EP3::filename\n"	if $self->{Debug} & 1;
 
    # Set up default values
    $self->{Edgename} ||= 'tclk';
    $self->{Edgetype} ||= 'posedge';

    $directive = shift @string;
    $steps = shift @string;
    chop ($steps) if ($steps =~ /;$/);
    print "$self->{Indent}repeat ($steps) @ ($self->{Edgetype} $self->{Edgename}); ";
    $command =  join(' ',@string);
    if (@string) {
        chomp $command;
        # Don't print hanging semi-colons
        if ($command =~ /^\s*;\s*$/) {
            print "\n";
        }
        else {
            print "$command\n"
        }
    }
    else {
        print "\n";
    }
	
}



sub denum
# usage: @denum a,b,c,d,...
#    As enum, but emits `define and replaces the args with `defs
# Funky enumerated lists by generating multiple define
{
    my $self = shift;
    my ($inline) = @_;		# Single arg: Cmd line
    my (@string,@dlist,$count);
    my ($directive, $key);
    my ($sigstring);
    my ($nbits,$emax,$cntmax, $signals);

    $sigstring = '';

    @string = split(' ',$inline);	# Split at spaces
    print "$self->{Line_Comment}EP3->denum: Entered step.  Line  $Text::EP3::line of $Text::EP3::filename\n"	if $self->{Debug} & 1;
    $directive = shift @string;		# Pop off the @enum
    $signals =  join(' ',@string);	# Put together
    $signals =~ s/ //g;			# Elim spaces
    @dlist = split(',',$signals);	# Split into list at commas
 
 
    # Find The max # bits required...
    $emax = 0;				# default initial value
    foreach $key (@dlist)
    {
	if ( $key =~ /^[0-9]*$/){
	    # We can reinitialize the count at any point
	    if ( $key < $emax){
		croak("Enumerated value can not be LESS than previous value.");
	    }
	    $emax = $key;
	}
	else {
	    $emax++;
	}
    }
    $cntmax=2;
    for($nbits=1; $cntmax <= $emax; $nbits++){
        $cntmax <<= 1;
    }
 
    $count = 0;				# default initial value
    foreach $key (@dlist)
    {
	 if ( $key =~ /^[0-9]*$/){
	     # We can reinitialize the count at any point
	     $count = $key;
	 }
	 else {
	     print "`define ${key}\t${nbits}'d${count}\n";
             # Replace the key with the verilog key
	     $sigstring = "$self->{Delimeter}define $key `$key";
	     $self->define($sigstring);
	     $count++;
	 }
    }    
}
