#!/usr/dim/perl/5.8/bin/perl

use strict;
use File::Find;
use Data::Dumper;
use File::Basename;

$| = 1;

main: {
	convert_cipp_img();
}

sub convert_cipp_img {
	my @files;
	find (
		sub {
			return if ! /\.cipp-img$/;
			return if /^\./;
			push @files, "$File::Find::dir/$_";
		},
		"."
	);

#	print Dumper (\@files);	
	
	my (@remove, @add);
	
	foreach my $file ( @files ) {
		open (IN, $file)
			or die "can't read $file";
		binmode IN;
		my $image_filename;
		my $in_body;
		my $body = "";
		while (<IN>) {
			if ( /^#\$IMAGE_FILENAME:\s+([^\s]+)/ ) {
				$image_filename = $1;
			}
			if ( /^#\sIDE_HEADER_END/ ) {
				$in_body = 1;
				next;
			}
			$body .= $_ if $in_body;
		}
		close IN;

		$image_filename =~ /\.([^\.]+)$/;
		my $ext = $1;
		my $new_file = $file;
		$new_file =~ s/\.cipp-img$/.$ext/;
		print "$file -> $new_file ", length($body), "\n";

		push @remove, $file;
		push @add, $new_file;
		
		open (OUT, "> $new_file")
			or die "can't write $new_file";
		binmode OUT;
		print OUT $body;
		close OUT;
		
		unlink $file;
	}
	
	my $cvs_remove = "cvs remove ".join(' ', @remove);
	my $cvs_add    = "cvs add ".join(' ', @add);
	my $cvs_commit = "cvs commit -m 'newspirit 2.x Bildkonvertierung' ".join(' ', @remove, @add);

	print "\n", $cvs_remove, "\n\n", $cvs_add, "\n\n", $cvs_commit, "\n\n";
	
#	print "Ausfuehren? (Ctrl+C zum Abbrechen): ";
#	<STDIN>;
	
	system ($cvs_remove)	if @remove;
	system ($cvs_add)	if @add;
	system ($cvs_commit)	if @remove or @add;
}
