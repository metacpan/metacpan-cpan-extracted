package Test::ShellScript;

use 5.008000;
use strict;
use warnings;

our $VERSION = '0.04';

use Test::More;

use Exporter ();
our(@ISA, @EXPORT);
@ISA = qw(Exporter Test::More);
@EXPORT = qw( 	run_ok 
		isCurrentVariable isCurrentValue nextSlot resetTimeline 
		reset_timeline variable_ok variable_ocurrences
	);


=pod

=head1 NAME

Test::ShellScript - Shell script testing module

=head1 SYNOPSIS

  use Test::ShellScript;
  
  run_ok("myScript.sh")
  variable_ok("executed", "false");
  variable_ok("output", "0");
  variable_ok("executed", "true");


=head1 DESCRIPTION

Call me insane, but sometimes a shell script becames too important or
complicated that no one wants to touch it. Then why not to add some
testing to gain some confidence and avoid disrupting its funcitionality ?

=head1 INTRO

The idea behind this module is to make testing simple for shell script writers
and that means :

 * simple testing code addition on shell script
 * minimal knowledge about Perl

This module will parse the output for the program under test, extracting and 
parsing only those devoted to testing. Each line is identified with a header,
followed by a text that must be in the next format :

    variable=value

simply the same format that a properties file line, assigning no meaning to any
value or variable name.

Suppose you have the next script that executes a command passed in the command line

    #!/bin/bash

    ## execute any command
    [[ -z $1 ]] && $*

Unfortunately you don't know why it doesn't work, then you add some testing 
code

    #!/bin/bash

    echo "TEST: executed=false"
    
    ## execute any command
    [[ -z $1 ]] && echo "TEST: executed=true" && $*

Run it again and you'll see the output 

    TEST: executed=false

Too bad, no execution simply because [[ -z $1 ]] is a bad test for a command
passed in the command line it must be  [[ ! -z $1 ]], then the new output
for our script is

    TEST: executed=false
    TEST: executed=true

=head1 Using Test::ShellScript

Testing such a simple script is a piece of cake, but when scripts grow in size
and complexity the game to play is very different. Anyway let me introduce you
to how to use Test::ShellScript with the previous simple script.

Start creating a text file with the next lines and name it run.t :

  #!/usr/bin/perl

  use 5.006;
  use strict;
  use warnings;
  use Test::ShellScript;

This simply instructs to use Perl (version 5.006 and onwards must be used),
tell Perl to be srtict (that means declare all your variables), warn you
about suspicious stuff and finally instruct it to use the shell script testing
module.

Now you must instruct it to run you program and then begin to look for the different
variables and its associated values to show up in the right order. Add the next lines
to run.t

    run_ok( '/path/to/run/command ls', "^TEST:");
    isCurrentVariable("executed");
    isCurrentValue("false");
    nextSlot();
    isCurrentVariable("executed");
    isCurrentValue("true");

run_ok runs your program and parses the output. It expects two parameters, 
the first one is the whole command line to execute and the second is a regular 
expression that is used to identify the lines used for testing. In this case 
the lines begin (^) with the word TEST followed by the character ':' 

Once parsed the whole output devoted to testing is our timeline and each output line 
becomes a time slot. Once run_ok is executed we're at the first one, then if we ask 
for the value of 'executed' it must be false or, in other words, the current variable 
should be 'executed' and its value 'false'.

Once we tested for these values nothing else can be done except for moving to the next 
time slot, then continue testing up to the end.

Great, we have created our first test and if we execute it the output will be something
like this

    ok 1 - command: '/path/to/run/command ls'
    ok 2 - Current variable is 'executed'
    ok 3 - Current value is 'false'
    ok 4 - Current variable is 'executed'
    ok 5 - Current value is 'true'
    1..5

meaning that each test was passed (ok) followed by a test number and a human readable comment.
At the end the tests numbers executed is show. This is fine if you have 5 or so tests
to execute but what if you need to make a hundred tests on tenths of scripts ? 
No way Macaya !

There's a wonderful module called Test::Harness that parses this output and shows us tests
statistics on success and failure. To run our humble test just type the command  
'perl -MTest::Harness -e 'runtests(@ARGV);' t/run.t' and lets the magic begin :

 # perl -MTest::Harness -e 'runtests(@ARGV);' t/run.t
 t/run.t .. ok    
 All tests successful.
 Files=1, Tests=5,  0 wallclock secs ( 0.03 usr  0.00 sys +  0.02 cusr  0.01 csys =  0.06 CPU)
 Result: PASS


=head1 Continuos mode

What we've been using in the previous section is called Step-by-step mode, where
you can do testing one slot at a time.

Now suppose you need to look for a variable content then you'll need to do it inside
a loop, search for it and once it's found look at it's value. Just to save errors, time,
resources and everything-else-you-want-to the continuous mode will help you.  

Let's continue with the previous example. Add the next lines to run.t

    reset_timeline();
    variable_ocurrences("executed",2);
    reset_timeline();
    variable_ocurrences("non_exisent_variable",0);

What they do is to reset the timeline, count how many times the variable 'executed'
is shown, resets the timeline again and now counts how many times the 'non_exisent_variable'
variable is shown.  

=head1 using Test::More

As a side effect a compatbility with Test::More has been added meaning that you can
mix Test::More and Test::ShellScript testing in the same test.

e.g.

  use 5.006;
  use strict;
  use warnings;
  use Test::ShellScript;
  use Test::More;
  
  my $testNUmber = 1;
  run_ok( '/path/to/run/command ls', "^TEST:");
  
  ### --- step by step mode
  $testNUmber++;
  isCurrentVariable("executed");
  
  ### using Test::More
  ok( $testNUmber == 2 );

  ### Back again to Test::ShellScript !!!
  isCurrentValue("ls");
  isCurrentValue("false");
  

=head1 METHODS

=cut


use constant   OK => "ok";
use constant   NOT_OK => "not ok";

use constant TRUE => 1;
use constant FALSE  => 0;

use constant VAR => 0;
use constant VALUE => 1;

use constant NOT_FOUND => "__NOT_FOUND__";
use constant UNKNOWN_VALUE => "UNKNOWN VALUE";

my @cmdOutput;

## Timeline storage. 
## Each array entry contains a refernce to an array whose first element is the
## variable name for this time slot, and the second one is the variable value
my @timeLine;
my $timeIndex = 0;


## Always runs with no plan, it's simpler for script programmers
END {
	done_testing();
}


=pod

=head1 Step-by-step mode

=head2 run_ok

  run_ok("myScript.sh argument1 argument2", "TEST");

Runs the command passed in the first argument and parses the command output. 
Accept as testing lines for output the ones with the regexp passed as second argument.

=cut

sub run_ok($$) {
	my $cmdLine = shift;
	my $acceptLines = shift;
	my $fh;
	my $runOK = FALSE;
	
	@cmdOutput = ();
	## Not redirects or similar allowed in the command line
	## TODO : error is shown if the command to run doesn't exist
	if ( $cmdLine && open( $fh , "$cmdLine |") ) {
		while( my $line = <$fh>) {
			push @cmdOutput, $line;
		};
		close $fh;
		
		@timeLine = ();
		resetTimeline();
		_parseOutput($acceptLines);
		resetTimeline();
		$runOK = TRUE;
	} else {
		$runOK = FALSE;
	};
	ok($runOK, "command: '$cmdLine'");	
};

=pod

=head2 isCurrentVariable

  isCurrentVariable("Variable_name");

test if the variable passed as argument exists in the current time slot

=cut

sub isCurrentVariable($) {
	my $variable = shift;
	
	
	## TODO check these vlidations
	return if ! _check($variable, "Undefined passed variable name");
	my $timelineVariable = $timeLine[$timeIndex]->[VAR];
	return if ! _check($timelineVariable, "Undefined variable name in timeline" );

	ok( $timelineVariable eq $variable,
	     "Current variable is '$timelineVariable'" );

}


=pod

=head2 isCurrentValue

  isCurrentValue("Variable_value");

test if the value for the variable in the current time slot is the one passed
as parameter

=cut

sub isCurrentValue($) {
	my $value = shift;
	
	## TODO test these validations
	return if ! _check($value, "Undefined passed variable value" );
	my $timelineValue = $timeLine[$timeIndex]->[VALUE];
	return if ! _check($timelineValue, "Undefined variable value in timeline" );

	ok( $timelineValue eq $value,
		"Current value is '$timelineValue'" );

}


=pod

=head2 nextSlot

  nextSlot()

advances to the next time slot

=cut

sub nextSlot() {
	if ($timeIndex < @timeLine) {
		$timeIndex++
	} else {
		## TODO test this
		_notOK("Can't pass beyond last slot");
	};
}

=pod

=head2 resetTimeline

  resetTimeline()

moves to the first time slot

=cut

sub resetTimeline() {
	$timeIndex = 0;
}


=pod

=head1 Continuos mode

=head2 variable_ok

  variable_ok("VARIALE_NAME", "value");

Looks for the variable value and compares it to the passed value

=cut

sub variable_ok($$) {
	my $var = shift;
	my $value = shift;
	
	## TODO check these vlidations
	return if ! _check($var, "Undefined passed variable name");
	return if ! _check($value, "Undefined passed variable value");
	
	my ($found, $realValue) = _getNextValue($var);
	ok( $found && $realValue eq $value, "'$var' = '$realValue'");
}

=pod

=head2 variable_ok

  variable_ocurrences("VARIALE_NAME", right_number_of_ocurrences);

Counts how many times the variable is shown, and compares it with the passed value

=cut

sub variable_ocurrences($$) {
	my $var = shift;
	my $value = shift;
	
	
	## TODO check these vlidations
	return if ! _check($var, "Undefined passed variable name");
	return if ! _check($value, "Undefined passed variable value");

	my $count = _varOccursTimes($var);
	ok( $count == $value, "Variable '$var' found '$count' times");
}

=pod

=head2 reset_timeline

  reset_timeline()

moves to the first time slot

=cut

sub reset_timeline() {
	resetTimeline()
}

sub _notOK($) {
	my $msg = shift;
	ok( FALSE, $msg );
}

sub _check($$) {
	my $var = shift;
	my $msg = shift;
	if ( ! defined $var ) {
		_notOK( $msg );
		return FALSE;   
	} else {
		return TRUE;
	};
}

sub _getNextValue($) {
	my $variable = shift;
	
	while($timeIndex < @timeLine) {
		next if ($timeLine[$timeIndex++]->[VAR] ne $variable);
		return ( TRUE, $timeLine[$timeIndex - 1]->[VALUE] );
	};
	
	return (FALSE, UNKNOWN_VALUE);
}

sub _varOccursTimes($) {
	my $variable = shift;
	
	my $pc = $timeIndex;
	my $count = 0;
	while($pc < @timeLine) {
		$count++  if ($timeLine[$pc++]->[VAR] eq $variable);
	};
	
	return $count;
}

sub _parseOutput($) {
	
	my $acceptLines = shift;
	foreach my $line (@cmdOutput) {
		next if $line !~ /$acceptLines/;
		$line =~ /$acceptLines\s*(\w*)=(.*)/;

		my @pair;
		push @pair, $1;
		push @pair, $2;
		push @timeLine, \@pair;
		$timeIndex++;
	}
};



1;

=pod

=head1 CONTRIBUTORS

=over 1

=item Matias Palomec <matias.palomec at gmail.com>  

=item Luis Agustin Nieto

=back


=head1 AUTHOR

Copyright (C) 2010 by Victor A. Rodriguez.
                   El bit Fantasma (Bit-Man)
                   http://www.bit-man.com.ar/

=cut
