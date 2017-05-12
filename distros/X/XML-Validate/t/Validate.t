#!/usr/local/bin/perl

#
# unit test for XML::Validate
#

use strict;
use Test::Assertions qw(test);
use Getopt::Std;

#Due to warning about INIT block not being run in XML::Xerces
BEGIN {$^W = 0}

use vars qw($opt_t $opt_T);
getopts("tT");

plan tests => 11;

chdir($1) if ($0 =~ /(.*)(\/|\\)(.*)/);
unshift @INC, "../lib";

require XML::Validate;
ASSERT(1, "compiled version $XML::Validate::VERSION");

# Log::Trace
if($opt_t) { require Log::Trace; import Log::Trace qw(print); }
if($opt_T) { require Log::Trace; deep_import Log::Trace qw(print); }

##########################################################################
# Deduce which libraries are available
##########################################################################

my $have_libxml;
eval {
	require XML::LibXML;
	$have_libxml = 1;
};

my $have_xerces;
eval {
	require XML::Xerces;
	$have_xerces = 1;
};

my $have_msxml;
eval {
		require Win32::OLE;
		my $warn_level = Win32::OLE->Option('Warn');
		Win32::OLE->Option(Warn => 0);
	
		my($doc, $cache);
		foreach my $version ('5.0', '4.0') {
			$doc   = Win32::OLE->new('MSXML2.DOMDocument.' . $version) or next;
			$cache = Win32::OLE->new('MSXML2.XMLSchemaCache.' . $version) or next;
		}
		
		Win32::OLE->Option(Warn => $warn_level);
		$have_msxml = ($doc && $cache);
};

##########################################################################
# Test construction of available validators
##########################################################################

# Construct LibXML validator
my $validator;
if($have_libxml) {
	$validator = new XML::Validate(Type => 'LibXML');
	DUMP("the Validator object", $validator);
	ASSERT(ref($validator) eq 'XML::Validate', "Instantiated a new XML::Validate::LibXML object");
} else {
	ASSERT(1, "skipped as LibXML is not available");
}

# Construct Xerces validator
if($have_xerces) {
	$validator = new XML::Validate(Type => 'Xerces');
	DUMP("the Validator object", $validator);
	ASSERT(ref($validator) eq 'XML::Validate', "Instantiated a new XML::Validate::Xerces object");
} else {
	ASSERT(1, "skipped as Xerces is not available");
}

# Construct Xerces validator
if($have_msxml) {
	$validator = new XML::Validate(Type => 'MSXML');
	DUMP("the Validator object", $validator);
	ASSERT(ref($validator) eq 'XML::Validate', "Instantiated a new XML::Validate::MSXML object");
} else {
	ASSERT(1, "skipped as MSXML is not available");
}

##########################################################################
# Check that calls are being passed through
##########################################################################

if($validator) {
	my $valid_XML = READ_FILE("valid.xml");
	my $invalid_XML = READ_FILE("invalid.xml");

	ASSERT($validator->validate($valid_XML),'Valid XML parsed');
	ASSERT(!$validator->validate($invalid_XML), 'Invalid XML validity checked');
	my $message = $validator->last_error->{message};
	ASSERT(defined $message, 'Invalid XML leaves an error');
	TRACE($message);
} else {
	for(1..3) {
		ASSERT(1, "skipped as you do not have any validators available");
	}
}

##########################################################################
# Test best available functionality
##########################################################################
if($validator) {
	my $best_available = new XML::Validate(Type => 'BestAvailable');
	my $best_type = $best_available->type();
	ASSERT($best_available && ($best_type =~ /^Xerces|LibXML|MSXML$/), "Default best available: $best_type");
	
	my @priorities;
	push(@priorities, "LibXML") if $have_libxml;
	push(@priorities, "Xerces") if $have_xerces;
	push(@priorities, "MSXML") if $have_msxml;
	my $prioritised_best = new XML::Validate(Type => 'BestAvailable', PrioritisedList => \@priorities);
	ASSERT($prioritised_best->type() eq $priorities[0], "User-defined best available: $priorities[0]");
} else {
	for(1..2) {
		ASSERT(1, "skipped as you do not have any validators available");
	}
}

##########################################################################
# Construct nonexistent validator
##########################################################################
eval {
	my $nonexistent_validator = new XML::Validate(Type => 'NonExistent');
};
ASSERT(scalar($@ =~ /Validator XML::Validate::NonExistent not loadable/), "Failed to construct a non-existent validator backend");

##########################################################################
# Construct validator with bad name
##########################################################################
eval {
	my $bad_named_validator = new XML::Validate(Type => '../bad-stuff');
};
ASSERT($@ eq "Validator type name '../bad-stuff' should only contain word characters.\n", "Failed to construct a bad-named validator backend");

##########################################################################

sub TRACE {}
sub DUMP {}

