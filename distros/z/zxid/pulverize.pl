#!/usr/bin/perl
# Copyright (c) 2006 Sampo Kellomaki (sampo@iki.fi), All Rights Reserved.
# This is confidential unpublished proprietary source code of the author.
# NO WARRANTY, not even implied warranties. Contains trade secrets.
# Distribution prohibited unless authorized in writing. See file COPYING.
# $Id: pulverize.pl,v 1.2 2009-08-30 15:09:26 sampo Exp $
# 17.8.2006, created --Sampo
#
# Split input files so that each function is in its own file.
#
# Such splitting is necessary to achieve dead function elimination at
# link time, i.e. goal is to reduce executable size by removing
# unused functions at link time.
#
# Unfortunately GNU ld does not have a flag for doing this. As of 2006
# it seems the -Wl,-O -Wl,2 or -ffunction-sections with --gc-sections
# approaches suggested by some on the net (see google) do not accomplish
# the purpose. Many other linkers such as Solaris, AIX, and Microsoft
# know to do this.
#
# Worse, it seems open source folks are showing their worst side
# and are intransigent that this is not a short coming and as such
# there is no desire to fix it and everybody who even dares
# to suggest it as shortcoming gets flamed.
#
# They claim that GNU ld's ability to eliminate unused object files
# is sufficient when combined with one-function-per-file approach.
# While that approach technically achieves the goal, IMNSHO they are
# still wrong in claiming that one-file-per-function is a good
# solution as this effectively limits the expression of programmer
# to acommodate a silly technical shortcoming. It is awkward when you can't
# group your functions logically by files.
#
# pulverize.pl hopes to make one-file-per-function approach
# tractable, by allowing programmer to edit functions in files
# of their choosing and then splits them automatically to atoms.
# You be judge whether it would be desireable to add linker feature
# or understand the resulting build process.
#
# Usage: perl pulverize.pl dir foo.c >make.include
#
# The first argument, dir, is the directory where the pulverized files
# should be placed.
#
# The make.include file allows you to define dependencies
# in your Makefile so that all the pulverized files get pulled in
# (so that linker can then ignore some of them ;-).
#
# For pulverize.pl to work, you need to indicate each split point by
# putting a comments like /* FUNC(func_name) */ in your source.
# The func_name is used to construct the name for the pulverized file.

undef $/;

$dir = shift;

for $orig (@ARGV) {
    open F, $orig or die "Can't read($orig): $!";
    $x = <F>;
    close F;

    $deps = '';
    @p = split m{/\*\s*FUNC\((\w+)\)\s*\*/}, $x;
    $preamble = shift @p;
    if ($p[-2] eq 'POSTAMBLE') {
	$postamble = pop @p;
	pop @p;
    } else {
	$postamble = "\n/* EOF */\n";
    }
    while (@p) {
	$func = shift @p;
	$body = shift @p;
	open F, ">$dir/$func.c" or die "Can't write($dir/$func.c): $!";
	print F "/* $dir/$func.c  -  WARNING: This file was pulverized. DO NOT EDIT!*/\n";
	print F $preamble;
	print F $body;
	print F $postamble;
	close F;
	$deps .= "$dir/$func.o ";
    }
    chop $deps;
    print $deps;
    #($x = $orig) =~ tr[A-Za-z0-9][_]c;
    #print "${x}_o=$deps\n\n";
    #print "\$(${x}_o:.o=.c): $orig\n\t\$(PULVERIZE) $dir $orig >$dir/$x.deps\n\n";
}

#EOF
