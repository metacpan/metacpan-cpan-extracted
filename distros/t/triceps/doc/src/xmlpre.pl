#!/usr/bin/perl
#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Format the plain text inside <pre> to look like XML and replace
# the tag with <programlisting>.
# Filters from stdin to stdout.

use strict;

# encode the XML-forbidden characters in their XML representation
sub xmlify # (text_line)
{
	my $tl = shift;

	# in XML form set tabs to 2 chars to reduce width
	$tl =~ s/\t/  /g;
	$tl =~ s/ +$//;

	# this is specific to the Triceps examples
	$tl =~ s/\&send\b/print/g;
	$tl =~ s/\&sendf\b/printf/g;
	$tl =~ s/\&readLine\b/<STDIN>/g;
	
	$tl =~ s/\&/\&amp;/g;
	$tl =~ s/</\&lt;/g;
	$tl =~ s/>/\&gt;/g;
	$tl =~ s/"/\&quot;/g;

	return $tl;
}

# split a string into an array of lines no longer than $max,
# trying to break at the spaces
sub splitwords # ($l, $max)
{
	my $l = shift;
	my $max = shift;
	my @res;

	# in XML form set tabs to 2 chars to reduce width
	$l =~ s/\t/  /g;

	# remember the initial indenting of the line
	$l =~ /^(\s*)/;
	my $indent = $1;

	while (length($l) > $max) {
		# the pattern is greedy, so it would find the last space before $max chars
		if ($l =~ s/^(.{1,$max}) +//) {
			push @res, $1;
			$l = $indent . "    " . $l; # indent the wrapped lines
		} else {
			die "Can not break up a line to $max chars, line is:\n$l\n";
		}
	}
	push @res, $l;
	return @res;
}

# length after which the result dump lines should get broken up
my $MAXLEN = 70;

my $pre = 0;
my $dump = 0; # in the results dump from an example
my $lf = ''; # used to drop the extra LFs from inside <pre>
while(<STDIN>) {
	if ($pre) {
		if (/^<\/pre>\s*$/) {
			$pre = 0;
			print "</programlisting>\n";
		} else {
			s/\s+$//; # trim the end spaces and line feeds
			print $lf, &xmlify($_);
			$lf = "\n";
		}
	} elsif ($dump) {
		if (/^<\/exdump>\s*$/) {
			$dump = 0;
			print "</programlisting>\n";
		} else {
			s/\s+$//; # trim the end spaces and line feeds
			my $input = s/^> //; # the input lines start with "> "
			print $lf;
			print("<emphasis role=\"bold\">") if ($input);
			if (length($_) <= $MAXLEN) {
				print &xmlify($_);
			} else {
				print &xmlify(join("\n", &splitwords($_, $MAXLEN)));
			}
			print("</emphasis>") if ($input);
			$lf = "\n";
		}
	} else {
		if (/^<pre>\s*$/) {
			# start of the multi-line block
			$pre = 1;
			$lf = '';
			print "<programlisting>";
		} elsif (/^<exdump>\s*$/) {
			# start of the multi-line block
			$dump = 1;
			$lf = '';
			print "<programlisting>";
		} else {
			# handle the inline blocks
			s/<pre>(.*?)<\/pre>/'<computeroutput>' . &xmlify($1) . '<\/computeroutput>'/ge;
			# process the common emphasis, to make it shorter in the source
			s/<i>/<emphasis>/g;
			s/<\/i>/<\/emphasis>/g;
			s/<b>/<emphasis role="bold">/g;
			s/<\/b>/<\/emphasis>/g;
			s/<br\/>/<computeroutput>\n<\/computeroutput>/g;
			print;
		}
	}
}
