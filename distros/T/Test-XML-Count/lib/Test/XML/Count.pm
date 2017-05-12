###################################################
# Text::XML::Count
#
# A module to help test element occurance counts
# in XML documents.
#
# Author: Adam Kaplan <akaplan@nytime dot com>
###################################################
# $Id$
###################################################
package Test::XML::Count;

use 5.006000;
use base 'Test::Builder::Module';
use strict;
use warnings;
use XML::LibXML;
use Test::Builder;
use Test::More;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	xml_node_count
	xml_min_nodes
	xml_max_nodes
);

our $VERSION = '0.02';

my $TEST = Test::Builder->new();
my $PARSER = XML::LibXML->new();
my $LAST_XML = '';
my $LAST_DOC;

sub import {
	my $class = shift @_;
	Test::XML::Count->export_to_level(1, $class);
	$TEST->exported_to(caller);
	$TEST->plan(@_);
}

sub _parse_and_get_nodelist {
	my $xml = shift or fail("XML string is not defined");
	my $xpath = shift or fail("XPath string is not defined");

	# Parsing is slow & probably not needed more than once per test file; Avoid.
	return $LAST_DOC if $xml eq $LAST_XML;
	# don't die if bad/unbalanced xml
	eval {$LAST_DOC = $PARSER->parse_string($xml)}; 
	return ($@) ? $TEST->fail($@) : $LAST_DOC->findnodes($xpath);
}

## Preloaded methods go here.

# boolean xml_node_count : xml string, xpath, number, test name
sub xml_node_count($$$;$) {
	my ($xml, $xpath, $count, $name) = @_;
	$TEST->ok (_parse_and_get_nodelist($xml, $xpath)->size() == $count, $name);
}

# boolean xml_min_nodes : xml string, xpath, number, test name
sub xml_min_nodes($$$;$) {
	my ($xml, $xpath, $count, $name) = @_;
	$TEST->ok (_parse_and_get_nodelist($xml, $xpath)->size() >= $count, $name);
}

# boolean xml_max_nodes : xml string, xpath, number, test name
sub xml_max_nodes($$$;$) {
	my ($xml, $xpath, $count, $name) = @_;
	$TEST->ok (_parse_and_get_nodelist($xml, $xpath)->size() <= $count, $name);
}

1;
__END__
=head1 NAME

Test::XML::Count - Perl extension for testing element count at a certain depth

=head1 SYNOPSIS

 use Test::XML::Count tests => 8;

 my $xml = "<foo><bar/><bar/><bar/></foo>";

 # These will pass
 xml_node_count $xml, '/foo', 1;
 xml_node_count $xml, '/foo/bar', 3;
 xml_max_nodes $xml, '/foo', 1;
 xml_min_nodes $xml, '/foo/bar' 3;

 # These will fail
 xml_node_count $xml, '/foo', 10;
 xml_node_count $xml, '/article', 1; # need an article
 xml_min_nodes $xml, '/foo/bar', 10; # at least 10 <bar>'s in <foo>
 xml_max_nodes $xml, '/foo/bar', 1;  # at MOST 1 <bar> in <foo>

=head1 DESCRIPTION

This test module allows you to check XML element counts.  This is useful in
testing applications which generate XML against known source data.  At The New 
York Times, we use it during development to quickly verify that our RSS feeds 
meet very basic structural standards. For example, every news article needs to have exactly one of each of headline, byline, date and text, and B<at least> 
one image.

This module fills a gap in L<Test::XML::Simple>, which only has facilities to
verify that an element exists (but not how many of it exist as direct siblings).
This is a great way to validate the structure of your XML documents without 
doing any deep (SLOW) comparison.  It also avoids having to hard code fragile 
element values that may change between tests or over time.  Use 
L<Test::XML::Count> in conjunction with your existing XML testing tools -- 
L<"SEE ALSO">.

=head1 SHAMELESS PLUG

This module was developed by the New York Times Company as an internal testing
tool, and graciously donated to the Perl community.  To show your support for
our open source intiative you may send an email to L<mailto://open@nytimes.com> 
and let us know how you are using this module.

Please visit L<http://open.nytimes.com>, our open source blog to see what we    
are up to, L<http://code.nytimes.com> to see some of our open projects and then 
check out L<http://nytimes.com> for the latest news!

=head1 SUBROUTINES

=over 4

=item xml_node_count $xml, $xpath, $count, $name;

Test passes if the XML string in C<$xml> contains C<$count> of the element
specified by the XPath in C<$xpath>.  Optionally name the test with C<$name>.

=item xml_min_nodes $xml, $xpath, $count, $name;

Test passes if the XML string in C<$xml> contains at least C<$count> of the 
element specified by the XPath in C<$xpath>.  Optionally name the test with 
C<$name>.

=item xml_max_nodes $xml, $xpath, $count, $name;

Test passes if the XML string in C<$xml> contains at most C<$count> of the 
element specified by the XPath in C<$xpath>.  Optionally name the test with 
C<$name>.

=back

=head1 EXPORTS

Everything in L<"SUBROUTINES"> by default, as expected.

=head1 SEE ALSO

L<Test::XML>

L<Test::More>

L<Test::Builder>

L<XML::LibXML>

XPath Specification: L<http://www.w3.org/TR/xpath>

XPath For Dummies: L<http://www.w3schools.com/xpath/xpath_syntax.asp>

Our code blog: L<http://open.nytimes.com>

=head1 AUTHOR

Adam J Kaplan, E<lt>akaplan@nytimes dotcom<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Adam J Kaplan and The New York Times

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
