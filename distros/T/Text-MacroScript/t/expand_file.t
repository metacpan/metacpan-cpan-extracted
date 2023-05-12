#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.
#
# test expand_file

use strict;
use warnings;
use Capture::Tiny 'capture';
use Path::Tiny;
use Test::More;

use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

sub void(&) { $_[0]->(); () }

my $ms;
my $fh;
my($out,$err,@res);
my $file = "test~";

#------------------------------------------------------------------------------
# create object
$ms = new_ok('Text::MacroScript');

#------------------------------------------------------------------------------
# error messages: unclosed %DEFINE, %DEFINE_SCRIPT
for my $define (qw( DEFINE DEFINE_SCRIPT )) {
	t_spew($file, "\n\n%$define xx\nyy\nzz\n");
	$ms = new_ok('Text::MacroScript');
	@res = $ms->expand_file($file);
	eval { $ms->DESTROY };
	is $@, "Error at file $file line 3: Unbalanced open structure at end of file\n";
	path($file)->remove;
}

#------------------------------------------------------------------------------
# error messages: %CASE inside %DEFINE...
for my $define (qw( DEFINE DEFINE_SCRIPT )) {
	for my $case ('CASE[0]', 'CASE[1]', 'END_CASE') {
		t_spew($file, "\n\n%$define xx\nyy\nzz\n%$case");
		$ms = new_ok('Text::MacroScript');
		@res = $ms->expand_file($file);
		eval { $ms->DESTROY };
		is $@, "Error at file $file line 3: Unbalanced open structure at end of file\n";
		path($file)->remove;
	}
}

#------------------------------------------------------------------------------
# error messages: evaluation error within script
t_spew($file, norm_nl(<<'END'));
%DEFINE_SCRIPT xx [+]
xx
END
$ms = new_ok('Text::MacroScript');
eval { @res = $ms->expand_file($file); };
is $@, "Error at file test~ line 2: Eval error: syntax error\n";
path($file)->remove;

#------------------------------------------------------------------------------
# error messages: undefine non-existent item
t_spew($file, norm_nl(<<'END'));
%UNDEFINE          x1
%UNDEFINE_SCRIPT   x2
%UNDEFINE_VARIABLE x3
END
$ms = new_ok('Text::MacroScript');
t_capture(__LINE__, sub { void { $ms->expand_file($file) } }, "", norm_nl(<<ERR), 0 );
ERR
path($file)->remove;

for my $which (qw( macro script variable )) {
	t_capture(__LINE__, sub { $ms->undefine("-$which", "x1") }, "", 
			  "",
			  0 );
}

#------------------------------------------------------------------------------
# error messages: missing parameter
t_spew($file, "%DEFINE_SCRIPT xx [\"#0#1\"]\nxx\nxx[a]\nxx[a|b]\n");
$ms = new_ok('Text::MacroScript');
eval { $ms->expand_file($file) };
is $@, "Error at file $file line 2: Missing parameters\n";
path($file)->remove;

t_spew($file, "%DEFINE xx [#0#1]\nxx\nxx[a]\nxx[a|b]\n");
$ms = new_ok('Text::MacroScript');
eval { $ms->expand_file($file) };
is $@, "Error at file $file line 2: Missing parameters\n";
path($file)->remove;

done_testing;
