#!/usr/bin/perl

=head1 NAME

bratislava-pm.pl - Example that browses Bratislava's PM web site.

=head1 SYNOPSIS

bratislava-pm.pl

=head1 DESCRIPTION

This example shows how to navigate through a web site while using
L<WWW::Mechanize::Plugin::AutoWrite> in order to automatically save the last
page visited.

=cut

use strict;
use warnings;

use WWW::Mechanize;
use File::Spec;

# Load the plugin AutoWrite
use WWW::Mechanize::Plugin::AutoWrite;


exit main();


sub main {

	# Create an instance of mechanize and set it up to our liking.
	# For this example a vanilla mechanize is fine.
	my $mech = WWW::Mechanize->new();
	
	
	# Tell the AutoWrite plugin where to save the file. That's the important part.
	my $file = File::Spec->catfile(
		File::Spec->tmpdir(),
		'btv.html'
	);
	$mech->autowrite->file($file);
	

	# Play with mechanize as usual
	$mech->get('http://bratislava.pm.org/');
	my $result = $mech->follow_link(url_regex => qr(other\.html));
	
	if ($mech->content =~ /Gtk2/) {
		print "Got the 'other' page\n";
	}
	else {
		print "Wrong page!\n";
		print $mech->content;
		return 1;
	}

	$mech->follow_link(text => 'color.pl');
	if ($mech->content =~ /'gtk-color-picker'/) {
		print "Got the color.pl file\n";
	}
	else {
		print "Wrong page!\n";
		print $mech->content;
		return 1;
	}

	print "Page contents: $file\n";
	
	return 0;
}
