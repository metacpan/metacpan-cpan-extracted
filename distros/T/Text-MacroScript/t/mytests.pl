#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Path::Tiny;
use Capture::Tiny 'capture';
use Test::Differences;

# normalize output and expected strings before eq test
sub _normalize_expected {
	my($text, $line_nr) = @_;
	$text =~ s/__LOC__/at $0 line $line_nr/g;
	return $text;
}

sub _normalize_output {
	local($_) = @_;
	s/\\/\//g;
	s/\.$//gm;		# remove end "." from eval error message as it differs in perl versions
	s/\S+(Text\/MacroScript\.pm line) \d+/$1 99/g;
	s/(Open .*? failed: ).*( at.*)?/ $1."ERROR".($2 || "") /ge;
	return $_;
}

#------------------------------------------------------------------------------
# check $@ for the given error message, replace __LOC__ by the 
# standard "at 'FILE' line DDD", normalize slashes for pathnames
sub check_error {
	my($line_nr, $eval, $exp_err) = @_;
	my $where = "at line $line_nr";
	
	ok defined($eval), "error defined $where";
	$eval //= "";
	
	$exp_err = _normalize_expected($exp_err, $line_nr);
	for ($eval, $exp_err) {
		$_ = _normalize_output($_);
	}
	
	eq_or_diff $eval, $exp_err, "error ok $where";
}

#------------------------------------------------------------------------------
# Normalize newline CR-LF --> LF, to be used for HERE-documents,
# as script is read in :raw mode, Win32 HERE-documents (<<END) have CR-LF
sub norm_nl {
	local($_) = @_;
	s/\r\n/\n/g;
	return $_;
}

#------------------------------------------------------------------------------
# run a command, capture exit value, stdout and stderr and check
sub t_capture {
	my($line_nr, $sub, $exp_out, $exp_err, $exp_ret) = @_;
	
	my $where = "[line ".(caller)[2]."]";
	
	my($out,$err,$ret) = capture { $sub->() };

	$exp_err = _normalize_expected($exp_err, $line_nr);
	for ($err, $exp_err) {
		$_ = _normalize_output($_);
	}
	
	eq_or_diff $out, $exp_out, "check stdout $where";
	eq_or_diff $err, $exp_err, "check stderr $where";
	is !!$ret, !!$exp_ret, "check exit value $where";
}

#------------------------------------------------------------------------------
# write out a test file, output it with note for easier test failure detection
sub t_spew {
	my($file, @lines) = @_;
	unlink $file;
	path($file)->spew(@lines);
	note "File $file:";
	note path($file)->lines;
}

1;
