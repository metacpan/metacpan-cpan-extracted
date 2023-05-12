#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Capture::Tiny 'capture';
use Path::Tiny;
use POSIX 'strftime';
use Test::More;

use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

my $ms;
my $test1 = "test~";
my($out,$err,@res);

path($test1)->spew(norm_nl(<<'END'));
Test text with hello
%DEFINE hello [world]
Test text with hello
END

#------------------------------------------------------------------------------
# new()
eval { Text::MacroScript->new(-no=>0,-such=>0,-option=>0); }; 
check_error(__LINE__-1, $@, "Invalid options -no,-option,-such __LOC__.\n");

#------------------------------------------------------------------------------
# -embedded
$ms = new_ok('Text::MacroScript' => [ -embedded => 1 ]);
is $ms->expand("hello<:%DEFINE *\nHallo\nWelt\n%END_DEFINE:>world<:*:>"),
	"helloworldHallo\nWelt\n";

for ([ [ -embedded => 1 ], 							"<:", ":>" ],
     [ [ -opendelim => "<<", -closedelim => ">>" ], "<<", ">>" ],
     [ [ -opendelim => "!!" ], 						"!!", "!!" ],
	) {
	my($args, $OPEN, $CLOSE) = @$_;
	my @args = @$args;
	note "@args $OPEN $CLOSE";
	
	$ms = new_ok('Text::MacroScript' => [ @args ]);
	is $ms->expand("hello${OPEN}%DEFINE *\n"),	"hello";
	is $ms->expand("Hallo\nWelt\n"),		"";
	is $ms->expand("%END_DEFINE${CLOSE}world${OPEN}"),"world";
	is $ms->expand("*${CLOSE}\n"),				"Hallo\nWelt\n\n";
	
}

ok unlink($test1);

done_testing;
