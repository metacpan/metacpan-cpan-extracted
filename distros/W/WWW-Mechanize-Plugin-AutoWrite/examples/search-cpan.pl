#!/usr/bin/perl

=head1 NAME

search-cpan.pl - Example that browses search CPAN.

=head1 SYNOPSIS

search-cpan.pl

=head1 DESCRIPTION

This example shows how to navigate through a web site while using
L<WWW::Mechanize::Plugin::AutoWrite> in order to automatically save the whole
HTTP session.

=cut

use strict;
use warnings;

use WWW::Mechanize;

# Load the plugin AutoWrite
use WWW::Mechanize::Plugin::AutoWrite;


exit main();


sub main {

	# Create an instance of mechanize and set it up to our liking.
	# For this example a vanilla mechanize is fine.
	my $mech = WWW::Mechanize->new(autocheck => 1);

	
	# The site is browsed two times each time the session is saved in a different
	# folder.
	my $tmp = "tmp/cpan";
	browse_section($mech, "$tmp/www", 'World Wide Web', 'WWW::');
	browse_section($mech, "$tmp/graphics", 'Graphics', 'VRML::');


	# Keep on surfing from the last session (Graphics / VRML)
	print "Following link 'VRML'\n";
	$mech->follow_link(text => 'VRML');
	if ($mech->content =~ /No matches/) {
		print "Funny there's no VMRL module, but there's a section for it!\n";
	}

	return 0;
}


#
# Method that browses the CPAN sections. This method saves the HTTP session in a
# dedicated folder. The session counter is reseted at each main section thus the
# session files will all start a 001.
#
sub browse_section {
	my ($mech, $folder, $section, $sub_section) = @_;

	# Save the HTTP session in a folder as we browse through the site.
	$mech->autowrite->dir($folder);
	print "Saving session to $folder\n";

	# Reset the counter this way each folder has it's file starting at 001. If
	# this line is commented then the session numbering will keep going no matter
	# in which folder the files are saved.
	$mech->autowrite->counter(0);

	
	print "Going to search CPAN\n";
	$mech->get('http://search.cpan.org/');
	if ($mech->content !~ m,<title>The CPAN Search Site - search.cpan.org</title>,) {
		die "Not browsing search CPAN";
	}

	print "Following link '$section'\n";
	$mech->follow_link(text => $section);
	if ($mech->content !~ /<title>$section/) {
		die "This is not the section '$section'?";
	}

	print "Following link '$sub_section'\n";
	$mech->follow_link(text => $sub_section);
	if ($mech->content !~ m,<title>$section / $sub_section,) {
		die "This is not the sub section '$sub_section'?";
	}
}
