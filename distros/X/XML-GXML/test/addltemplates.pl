#!/usr/bin/perl

# GXML test suite - addltemplates.pl
# by Josh Carter <josh@multipart-mixed.com>
#
# Tests the dynamic template feature

use strict;
use XML::GXML;

my $xml = '<base><dyna-template/></base>';

#######################################################################
# old-style way of doing it (gets ugly if you have more than about
# three dynamic templates)
#######################################################################

my $gxml = new XML::GXML(
		{'addlTempExists'  => \&CheckAddlTemplate,
		 'addlTemplate'    => \&AddlTemplate});

print "\nold-style template subroutines:\n";
print "before:\n$xml";
print "\nafter:\n" . $gxml->Process($xml) . "\n";
undef $gxml;

#######################################################################
# new-style way of doing it -- much more scalable
#######################################################################

my %templates = ('dyna-template' => \&DynaTemplate);
my $gxml = new XML::GXML({'addlTemplates' => \%templates});

print "\nnew-style template hash:\n";
print "before:\n$xml";
print "\nafter:\n" . $gxml->Process($xml) . "\n";

exit;

#######################################################################
# subroutines from here down
#######################################################################

# old style
sub CheckAddlTemplate
{
	my $name = shift;

	if ($name eq 'dyna-template') { return 1; }
	else                          { return 0; }
}

# old style
sub AddlTemplate
{
	my $name = shift;

	if ($name eq 'dyna-template')
		# remember: return value is a reference
		{ return \'<p>hello there</p>'; }
	else
		{ return undef; }
}

# new style: no more if-elsif-else junk!
sub DynaTemplate
{
	# remember: return value is a reference
	return \'<p>hello there 2</p>';
}

