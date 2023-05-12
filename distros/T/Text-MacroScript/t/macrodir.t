#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Capture::Tiny 'capture';
use Path::Tiny;
use Time::HiRes 'usleep';
use Path::Tiny;
use Test::Differences;
use Test::More;

use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

my $MACRODIR  = "$^X -I../../blib/lib ../../bin/macrodir";
my @PRONOUNS  = ("my", "your", "his", "her");
my @DATA_DIRS = (undef,undef,  "2",   "2");
my $TARGET = "../target";

#------------------------------------------------------------------------------
# make directory and run tests
my $ROOT = path("test~");
my $src = path($ROOT, "src");
$src->mkpath;
path($src, "2")->mkpath;
chdir($src);

run_tests();

chdir("../..");
$ROOT->remove_tree;
done_testing();

#------------------------------------------------------------------------------
# run tests from test~/src directory
sub run_tests {
	
	# expand all files, not verbose
	diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
	run_test({-args => ""});

	# -v|--verbose
	diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
	run_test({-args => "-v"});
	run_test({-args => "--verbose"});

	# source dir argument
	diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
	run_test({-src_dir => "2", -args => "2"});
	run_test({-src_dir => "2", -args => "-v 2"});
	run_test({-src_dir => "2", -args => "-v -- 2"});
	
	# -d, --dir target dir
	diag 'Issue #9: macrodir -d: does not replicate source tree in target directory';
	diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
	#run_test({-target_dir => $TARGET, -args => "-v -d $TARGET"});
	#run_test({-target_dir => $TARGET, -args => "-v --dir $TARGET"});
	
	# -f, --force
	diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
	run_test({-force => 1, -args => "-v -f"});
	run_test({-force => 1, -args => "-v --force"});

	# -F, --file
	diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
	run_test({-macro_file => "newmacros", -args => "-v -F newmacros"});
	run_test({-macro_file => "newmacros", -args => "-v --file newmacros"});
	
	# -p, --prep
	diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
	run_test({-args => "-v -p"});
	run_test({-args => "-v --prep"});

	# -h, --help
	test_help("-h");
	test_help("--help");
}

#------------------------------------------------------------------------------
# run one test
sub run_test {
	my($opts) = @_;
	
	$opts->{caller_line} = (caller)[2];

	# set flags
	for ($opts->{-args}) {
		$opts->{-verbose} = /-v\b|--verbose\b/ ? 1 : 0;
		
		diag 'Issue #10: macrodir always in embedded mode, ignoring -p option';
		#$opts->{-embedded} = /-p\b|--prep\b/ ? 1 : 0;
		$opts->{-embedded} = /-p\b|--prep\b/ ? 0 : 1;
	}
	
	make_src_files($opts);
	run_macrodir($opts);
	check_result_files($opts);
	
	# only update what needed
	if ($opts->{-verbose}) {
		if ($opts->{-force}) {
			run_macrodir($opts);
			check_result_files($opts);
		}
		elsif (! $opts->{-src_dir} && ! $opts->{-target_dir} ) {
			unlink $opts->{txt_file}[0];
			while (-M $opts->{txt_file}[1] <= -M $opts->{m_file}[1]) {
				usleep 250;
				$opts->{m_file}[1]->touch;
			}
			for (@{$opts->{output}}[ 2 .. $#{$opts->{output}} ]) {
				s/Expanding.* to (.+)/$1 is up to date/;
			}

			run_macrodir($opts);
			check_result_files($opts);
		}
	}
}

#------------------------------------------------------------------------------
# build source data
sub make_src_files {
	my($opts) = @_;
	
	# remove and create empty target dir
	my $target = path($TARGET);
	$target->remove_tree;
	$target->mkpath;
	
	# create source files
	$opts->{output} = [];
	for my $id (0 .. $#PRONOUNS) {
		
		$opts->{txt_file}[$id] = path(grep {defined} 
									  $DATA_DIRS[$id],
									  "file$id.txt");
		unlink $opts->{txt_file}[$id];
		
		$opts->{m_file}[$id]   = path($opts->{txt_file}[$id].".m");
		
		if ($opts->{-target_dir}) {
			$opts->{txt_file}[$id] = path($opts->{-target_dir}, 
										  $opts->{txt_file}[$id]);
			unlink $opts->{txt_file}[$id];
		}
		
		$opts->{m_file}[$id]->spew(test_string($opts, $id,
							embed_start($opts)."NAME".embed_end($opts)));
		
		if ( ! $opts->{-src_dir} || 
		     ( $opts->{-src_dir} eq ($DATA_DIRS[$id]||"") ) ) {
			push @{$opts->{output}}, "Expanding macros in ".
									 $opts->{m_file}[$id].
									 " to ".
									 $opts->{txt_file}[$id]."\n";
		}
	}
	
	# create macro file
	unlink "macro", "newmacros";
	$opts->{-macro_file} ||= "macro";
	path($opts->{-macro_file})->spew(
							"%DEFINE NAME[John]\n",
							"Text not output\n");
}

sub embed_start {
	my($opts) = @_;
	return $opts->{-embedded} ? "<:" : "";
}
	
sub embed_end {
	my($opts) = @_;
	return $opts->{-embedded} ? ":>" : "";
}
	
sub test_string {
	my($opts, $id, $name) = @_;
	return $PRONOUNS[$id]." name is ".$name."\n";
}

#------------------------------------------------------------------------------
# run script
sub run_macrodir {
	my($opts) = @_;
	
	my $cmd = "$MACRODIR $opts->{-args}";
	ok 1, "line $opts->{caller_line} - $cmd";
	
	my($out,$err,$res) = capture { system $cmd; };
	is $out, "";
	
	if ($opts->{-verbose}) {
		$err =~ s! \.\/! !g;
		$err =~ s!^\.\/!!mg;
		eq_or_diff $err, join("", @{$opts->{output}});
	}
	else {
		is $err, "";
	}
	is $res, 0;
}

#------------------------------------------------------------------------------
# check result files
sub check_result_files {
	my($opts) = @_;
	
	# check text files
	for my $id (0 .. $#PRONOUNS) {
		if ( ! $opts->{-src_dir} || 
		 ( $opts->{-src_dir} eq ($DATA_DIRS[$id]||"") ) ) {
			is $opts->{txt_file}[$id]->slurp, 
			   test_string($opts, $id, "John");
		}
	}
}
	
#------------------------------------------------------------------------------
# test help
sub test_help {
	my($args) = @_;
	
	my $cmd = "$MACRODIR $args";
	ok 1, "- $cmd";
	
	my $VERSION = $Text::MacroScript::VERSION;
	my $ROOT = Path::Tiny->cwd;

	my($out,$err,$res) = capture { system $cmd; };
	is $out, "";
	eq_or_diff $err, norm_nl(<<END);

macrodir v $VERSION. Copyright (c) Mark Summerfield 1999-2000. 
All rights reserved. May be used/distributed under the GPL.

usage: macrodir [options] <path>

-d --dir       Put output files in <dir> instead of $ROOT
-f --force     Force conversion [0]
-F --file      Take macros from this file [macro]
-h --help      Show this screen and exit
-p --prep      Operate as macro pre-processor instead of an embedded macro
               expander
-v --verbose   Verbose [0]

Loads the macros from file 'macro' in the current directory then expands
macros embedded in <: and :> in every .m file in the current directory and any
subdirectories. 

Text::MacroScript now supplies a function relpath which returns the relative
path. (See html.macro example file for usage and Text::MacroScript.pm and
macropp documentation.)
END
	is $res, 0;
}
