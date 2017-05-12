#!/usr/bin/perl
#
# (C) Copyright 2011-2014 Sergey A. Babkin.
# This file is a part of Triceps.
# See the file COPYRIGHT for the copyright notice and license information
#
# Generate the makefile dependencies for the XML files by xinclude

use strict;

# instead of catalogs, set the hardwired rewrites here
my %rewrites = (
	"file:///EXAMPLES/" => "../ex/exxml/",
	"file:///SEQS/" => "seq/",
	"file:///DOCS/" => "docsrc/",
);

# for the images that differ between PDF and HTML, refer through the refs list
my @pdfimgs; # images for PDF version
my @htmlimgs; # images for HTML version
open(REFS, "<", "figrefs/refs") or die "Can not read figrefs/refs: $!\n";
while(<REFS>) {
	chomp;
	next if (/\s*#/);
	next if (/^\s*$/);
	my ($file, $width, $pdfsuf) = split(/\s+/);

	push @pdfimgs, "$file.$pdfsuf";
	push @htmlimgs, "$file.lowres.png";
}
close(REFS);

#
my @topfiles = @ARGV;
my $topf;
foreach $topf (@topfiles) {
	my %seen;
	my @deps;
	my @imgs; # images common for pdf and html (probably aren't any)
	my @workf; # working files

	print STDERR "Processing top-level file '$topf'\n"; #SBDBG
	push @workf, $topf;
	while (scalar @workf > 0) {
		my $fname = shift @workf;
		print STDERR "Reading file '$fname'\n"; #SBDBG

		next if (exists $seen{$fname});
		$seen{$fname} = 1;

		die "Can not read '$fname': $!\n"
			unless open FILE, "<", $fname;

		my $comment = 0;
		while(<FILE>) {
			if ($comment) {
				if (s/^.*?-->//) {
					$comment = 0;
				}
			} 
			if (!$comment) {
				s/<!--.*?-->//g;
				if (s/<!--.*?$//) {
					$comment = 1;
				}
				if (/<xi:include.*href="([^"]*)"/) {
					my $f = $1;
					my ($pat, $res);
					print STDERR "found xinclude '$f'\n"; #SBDBG

					# this will be a special rewrite for both PDF and HTML, for now just skip
					$pat = "file:///FIGS/";
					if ($f =~ /^\Q$pat\E/) {
						next;
					}

					foreach $pat (keys %rewrites) {
						$res = $rewrites{$pat};
						$f =~ s/^\Q$pat\E/$res/;
					}
					push @workf, $f;
					push @deps, $f;
				} if (/<graphic.*fileref="([^"]*)"/) {
					my $f = $1;
					my ($pat, $res);
					print STDERR "found image '$f'\n"; #SBDBG
					foreach $pat (keys %rewrites) {
						$res = $rewrites{$pat};
						$f =~ s/^\Q$pat\E/$res/;
					}
					push @imgs, $f;
				}
			}
		}

		close FILE;
	}
	my $f;
	my $ff;
	my $fofile = $topf;
	my $htmlfile = $topf;
	my $pdffile = $topf;

	# the files will actually be pre-processed from docsrc/ to ./ first,
	# so adjust for it
	$topf =~ s/^docsrc\///;

	$fofile =~ s/\.xml$/\.fo/;
	$fofile =~ s/^docsrc\///;
	$htmlfile =~ s/\.xml$/\.html/;
	$htmlfile =~ s/^docsrc\//..\/html\//;
	$pdffile =~ s/\.xml$/\.pdf/;
	$pdffile =~ s/^docsrc\//..\/pdf\//;

	print "$fofile : $topf \\\n";
	print "  figrefs/refs \\\n";
	foreach $f (@deps) {
		$ff = $f;
		$ff =~ s/^docsrc\///;
		print "  $ff \\\n";
	}
	print "\n";

	print "$pdffile : $fofile \\\n";
	foreach $f (@imgs) {
		print "  $f \\\n";
	}
	foreach $f (@pdfimgs) {
		print "  $f \\\n";
	}
	print "\n";

	print "$htmlfile : $topf \\\n";
	print "  figrefs/refs \\\n";
	foreach $f (@deps) {
		print "  $f \\\n";
	}
	# images themselves aren't required for the HTML file but they need to be built
	foreach $f (@imgs) {
		print "  $f \\\n";
	}
	foreach $f (@htmlimgs) {
		print "  ../html/$f \\\n";
	}
	print "\n";
}
