#!/usr/bin/perl -w -I../blib/lib/
#      /\
#     /  \		(C) Copyright 2016 Parliament Hill Computers Ltd.
#     \  /		All rights reserved.
#      \/
#       .		Author: Alain Williams, July 2016
#       .		addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: ?????
#
# Test program for the module Text::ReadConditionally
# This also serves as a demonstration program on how to use the module.
#
# May want to run as:
#	PERL5LIB=blib/lib t/test.t
#	PERL5LIB=../blib/lib test.t

# How this works
# When this is run by 'make test' the CWD is the directory above the one containing this script.
# Two directories:
# * Tests - this contains the test files and expected results
# * TestOut - where test output will be generated
#	files will have names like ggg_www_sss.out
# The directory Tests contains files named like: ggg_www_sss.suf
# ggg & sss are variable length numbers; the tests will be run in numeric order:
# by group (ggg) - www alphanumeric & '-' description
# by sequence (sss) within the group
# suf is:
#  .input - text input
#  .want - what should be generated on output


# You can also set environment variables:
#  TRACE	1	print out expression and result
#		2	also print out the parse tree
# eg:
#	TRACE=1 perl -Iblib/lib t/test.t

#  ERR_TREE	1	Print out the parse tree on error
# eg:
#	ERR_TREE=1 perl -Iblib/lib t/test.t

# Copyright (c) 2016 Parliament Hill Computers Ltd/Alain D D Williams. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. You must preserve this entire copyright
# notice in any use or distribution.
# The author makes no warranty what so ever that this code works or is fit
# for purpose: you are free to use this code on the understanding that any problems
# are your responsibility.

# Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is
# hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and
# this permission notice appear in supporting documentation.

use strict;
use IO::File;
use Math::Expression;
use Text::ReadConditionally;
use POSIX qw(strftime mktime);
use DirHandle;
use Cwd;

my $TestDir = 't/Tests';
my $TestOutDir = 'TestOut';	# Generated files go here

# Values of variables in here.
# This is made the hash that stores variables by the use of SetOpt() below.
# These variables may be used in expressions, see 'Test variables defined elsewhere' below.
my %Vars = (
	'var'		=>	[42],
	'foo'		=>	[6],
	'bar'		=>	['bar'],
	'variable'	=>	[9],
);

# Return the value of a variable - return an array
# 0	Magic value to Math::Expression
# 1	Variable name
# See SetOpt() below.
sub VarValue {
	my ($self, $name) = @_;

	my @nil;
	return @nil unless(exists($Vars{$name}));

	return @{$Vars{$name}};
}

# Return 1 if a variable is defined - ie has been assigned to
# 0	Magic value to Math::Expression
# 1	Variable name
# See SetOpt() below.
sub VarIsDef {
	my ($self, $name) = @_;

	return exists($Vars{$name}) ? 1 : 0;
}

my $NumFails = 0;
my $ExprError;
my $RunError;
my $errtree = 0;
my $verbose = 0;
my $var=0;
my @arr = (1,2,3);

my $OriginalExpression;
my $Operation;

my $pwd = cwd();

sub MyPrintError {
	printf "#Error in $Operation '%s': ", $OriginalExpression;
	printf @_;
	print "\n";

	if($Operation eq 'parsing') {
		$ExprError = 1;
	} else {
		$RunError = 1;
	}
}

sub printv {
	return unless($verbose > 1);

	if($#_ > 0) {
		my $fmt = shift @_;
		printf $fmt, @_;
	} else {
		print $_[0];
	}
}

my @TestFiles = ();
sub FindTests {
	my $d = DirHandle->new($TestDir) or die("Cannot read directory $TestDir as: $!\n");
	my @T = ();
	while(defined($_ = $d->read)) {
	    push @T, $1 if(/^(\d+_[-\w]+_\d+)\.input$/i);
        }

	@TestFiles = sort {my ($an, $as) = $a=~ /(\d+)_.*_(\d+)/; my ($bn, $bs) = $b =~ /(\d+)_.*_(\d+)/; $an != $bn ? $an <=> $bn : $as <=> $bs } @T;
}

# **** Start here ****

# Debug/trace options from the environment:
$verbose = $ENV{TRACE}    if(exists($ENV{TRACE}));
$errtree = $ENV{ERR_TREE} if(exists($ENV{ERR_TREE}));

# So that print does not complain when Unicode characters are output:
binmode(STDOUT, ":utf8");
# So that UTF8 encoded strings below are handled properly:
use utf8;

#print STDERR "\nPWD=\n";
#system("pwd >&2");
#print STDERR "\n";

printf "Text::ReadConditionally Version '%s'\n", $Text::ReadConditionally::VERSION if($verbose);

my $ArithEnv = new Math::Expression;

-d $TestOutDir or mkdir 'TestOut' or die "Cannot create $TestOutDir as: $!\n";

FindTests();


# Function that provides extra functions - ie user functions
# numArgs	return # arguments
# sumArgs	numeric sum of arguments
# A user defined function must return a scalar or list; it MUST not return undef.
sub moreFunctions {
	my ($self, $tree, $fname, @arglist) = @_;

	print "moreFunctions fname=$fname\n" if($verbose);

	return scalar @arglist if($fname eq 'numArgs');

	if($fname eq 'sumArgs') {
		my $sum = 0;
		$sum += $_ for @arglist;
		return $sum;
	}

	# Return undef so that in built functions are scanned
	return undef;
}

# MUST put user defined functions here so that it is known as a function - while parsing:
$ArithEnv->{Functions}->{numArgs} = 1;
$ArithEnv->{Functions}->{sumArgs} = 1;

$ArithEnv->SetOpt('VarHash' => \%Vars,
		  'VarGetFun' => \&VarValue,
		  'VarIsDefFun' => \&VarIsDef,
#		  'VarSetValueFunction' => \&VarSet,
		  'PrintErrFunc' => \&MyPrintError,
		  PermitLoops => 1,
		  EnablePrintf => 1,
		  ExtraFuncEval => \&moreFunctions,
		);


# Some of the 'tests' below look tedious/repetitive but they are setting up variables with values
# for subsequent tests, even if this is only checking that they get changed.

# Test return value against a string/number/array or the special values:
# * EmptyArray
# * RunTimeError
# * SyntaxError
# * Undefined		A value is returned but this is undef



use Test::More;

my $Tests = 0;

warn "\n";

ALL_TESTS:
for my $test (@TestFiles) {
    $Tests++;

    my ($if, $out, $want);	# File handles

    my $rc;			# ReadConditionally object
    my $title = $test;		# Test title
    my @require = ();		# Files to require before use
    my @set = ();		# Expressions to set
    my @newopt = ();		# Options to Text::ReadConditionally-new()
    my $fork = 0;		# Fork before running the test, ie subprocess
    my $preopen = 0;		# Preopen the file
    my $lfn = '';		# File name for log messages

#    print STDERR "DO test $test\n";
    my $input = $TestDir . '/' . $test . '.input';

    unless($if = IO::File->new($input, 'r')) {
        ok(0, "$Tests - $test - cannot open (read) $input: $!");
	$NumFails++;
        next;
    }

    # Look for pseudo comment info lines at the start of file:
    while(<$if>) {
        chomp;
	last unless(/^\.#/);
        $title = $1           if(/^\.#\s+Title:\s+(.*\S)\s*$/);
        $preopen = $1         if(/^\.#\s+Preopen:\s+(.*\S)\s*$/);
        push(@require, $1)    if(/^\.#\s+Require:\s+(.*\S)\s*$/);
        push(@set, $1)        if(/^\.#\s+Set:\s+(.*\S)\s*$/);
        push(@newopt, $1, $2) if(/^\.#\s+NewOpt:\s+(\S+)\s+(.*\S)\s*$/);
        $fork = 1 if(/^\.#\s+Fork\s*$/);
    }
    $fork = 1 if(@require);

    # If we have a title the file name is lost, keep elsewhere:
    $lfn = $test . '.input' if($title);

    # Where we put the generated output
    my $outf = $TestOutDir . '/' . $test . '.out';
    unless($out = IO::File->new($outf, 'w')) {
        ok(0, "not ok $Tests - $title: - cannot open (write) $outf: $!");
	$NumFails++;
        next;
    }

    # This is what we want: ie what we expect to generate
    my $wantf = $TestDir . '/' . $test . '.want';
    unless($want = IO::File->new($wantf, 'r')) {
	ok(0, "not ok - $title: - cannot open (read) $wantf: $!");
	$NumFails++;
        next;
    }

    # Pass an already opened FD, use what we have, rewind to start of file first
    if($preopen) {
        seek $if, 0, SEEK_SET;
        $. = 0;
        push(@newopt, 'Fd', $if);
    }

    unless($rc = Text::ReadConditionally->new(File => $input, @newopt)) {
        ok(0, "not ok - $title: - cannot open ReadConditionally '$input' as: $!");
	$NumFails++;
        next;
    }

    # Set for some tests
    $rc->{Math}->VarSetScalar('PWD', $pwd);

    for (@set) {
        warn "evaluating: $_\n" if $verbose;
        my $ex;
        unless($ex = $rc->{Math}->Parse($_)) {
            ok(0, "not ok - $title: Invalid Set: '$_'");
	    $NumFails++;
            next ALL_TESTS;
        }
          
        $rc->{Math}->Eval($ex);
    }

    if($fork) {
        ;
    } else {
        my $lineNo = 0;
        my $err = 0;
        my $wantLine;
        my $rcLine;
        my $genLine;

        while($genLine = <$rc>) {
            $lineNo++;
            print $out $genLine;

            next # On error - copy generated to output file
                if($err);

            unless(defined($wantLine = <$want>)) {
                ok(0, "$Tests: $title: $lfn Line $lineNo too many lines generated");
                $err = 1;

                next;
            }

            if($genLine ne $wantLine) {
                $err = 1;
                ok(0, "$Tests: $title: $lfn Line $lineNo line generated differs from expected");

                next;
            }
        }

        next ALL_TESTS # All generated is copied
            if($err);

        if(defined($wantLine = <$want>)) {
            ok(0, "$Tests: $title: $lfn Line $lineNo not enough generated lines");
            next ALL_TESTS;
        }
    }


    ok(1, $test);
    warn "ok $Tests $title\n";
}

done_testing();

print "\n\n";
print "# $Tests tests run\n";
print $NumFails == 0 ? "# All tests OK\n" : "# $NumFails tests failed\n";

__END__

# Output # tests that we expect to do:
my $NumTests = (scalar @Test) / 2;
print "1..$NumTests\n";

my $Tests = 0;
for(my $inx = 0; $inx < $#Test; $inx += 2 ) {

	my $in = $Test[$inx];
	my $result = $Test[$inx + 1];

	$Tests++;

	$OriginalExpression = $in;
	$RunError = $ExprError = 0;

	print "\nParse: ''$in'' FailsSoFar=$NumFails\n" if($verbose);
	$Operation = 'parsing';
	my $tree = $ArithEnv->Parse($in);

	if($ExprError) {
		if($result eq 'SyntaxError') {
			print "ok $Tests - Parse fail -- as expected: ''$in''\n";
		} else {
			print "not ok $Tests - Parse fail -- unexpectedly: ''$in''\n";

			$NumFails++;
		}
		$ArithEnv->PrintTree($tree) if($errtree);
		next;
	}

	unless(defined($tree)) {
		print "not ok $Tests - Tree undefined for expression ''$in''\n";

		$NumFails++;
		next;
	}

	&printv("parse => $tree\n");

	$ArithEnv->PrintTree($tree) if($verbose > 1);

	$Operation = 'evaluating';
	my @res = $ArithEnv->Eval($tree);

	if($#res == -1 and $result eq 'EmptyArray') {
		if($RunError) {
			printf "not ok $Tests - Failed unexpectedly: ''%s''\n", $in;

			$NumFails++;
			$ArithEnv->PrintTree($tree) if($errtree);
		}
		printf "ok $Tests - Result is empty array, as expected: ''%s''\n", $in;
		next;
	}

	if($#res == -1 or $RunError) {
		my $rterp = $RunError ? "run time error reported" : "run time error not reported";
		if($result eq 'RunTimeError') {
			printf "ok $Tests - Failed at run time - as expected, %s: ''%s''\n", $rterp, $in;
			next;
		}
		printf "not ok $Tests - Failed unexpectedly, %s: ''%s''\n", $rterp, $in;

		$NumFails++;
		next;
	}

	&printv("expr ''$in'' ");
	if($#res == 0) {
		if( !defined($res[0])) {
			# Value returned in element 0 is not defined - as opposed to the test above which is
			# the entire array is not defined, ie undef returned
			if($result eq 'Undefined') {
				# This is what was expected
				printf "ok $Tests - Undefined value - as expected: ''%s'\n", $in;
				next;
			}
			print "not ok $Tests - res=undef Should be '$result' ''$in''\n";
			next;
		}
		# I have written better code:
		printf "%s $Tests - res='%s'%s: ''%s''\n", (($res[0] eq $result) ? 'ok' : "not ok"), $res[0], (($res[0] eq $result) ? '' : " Should be '$result'"), $in;

		unless($res[0] eq $result) {
			$NumFails++;
			$ArithEnv->PrintTree($tree) if($errtree);
		}
	} else {
		my @ref = reverse split /, /, $result;
		my $ok = 'ok';
		my $res = "res=Array #elems=".@res." vals=";
		my $ev = 'Extra val ';
		foreach my $x (@res) {
			 $res .= "'$x' ";
			 my $ref = pop @ref;
			 unless(defined($ref)) {
				$res .= "$ev";
				$ev = '';
				$ok = 'not ok';
				next;
			 }
			 next if($ref eq $x);
			 $res .= "!= '$ref', ";
			 $ok = 'not ok'
		}

		printf "$ok $Tests - %s\n", $res;
		$NumFails++ if($ok ne 'ok');
	}
}

print "\n\n";
print "# $Tests tests run\n";
print $NumFails == 0 ? "# All tests OK\n" : "# $NumFails tests failed\n";

# end
