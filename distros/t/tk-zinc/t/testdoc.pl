#!/usr/bin/perl -w
# $Id: testdoc.pl,v 1.4 2002/11/06 09:14:45 mertz Exp $
# This script verifies the conformity of the reference manual with
# some types informations available inside ZincTk
# It has been developped by C. Mertz <mertz@cena.fr>

# limitations: this script makes some very strong assumptions
#              on the latex Zinc reference manual formating!
#              However if the formating changes, it should be
#              simple to modify the &scanDoc function!
#
# What this script currently does:
#  - verifies that all Zinc options are documented
#  - verifies that all items attributes (and their type) are documented
#  - verifies that all field attributes options (and their type) are documented
#  - verifies that all documented options and attributes really exists
#  - verifies that all documented types are refered to in the doc
# It also checks that options, attributes and types are documented in alphabetical order
# It is heavily based on meta information available directly from zinc
#
# How to use it:
#   testdoc.pl path_to_refman.tex

use Tk;
use Tk::Zinc;

use strict;

print "------- Testing conformity of refman.tex and meta-information from zinc Version $Tk::Zinc::VERSION\n";

my $mw = MainWindow->new();

# Creating the zinc widget
# NB: this widget will not be displayed! It is only used for creating items
# and getting some internal information about attributes/options and types.

my $zinc = $mw->Zinc(-width => 1, -height => 1,);

# Creating an instance of every item type
my %itemtypes;

# These Items have fields! So the number of fields must be given at creation time
foreach my $type qw(tabular track waypoint) {
    $itemtypes{$type} = $zinc->add($type, 1, 1);
}

# These items needs no specific initial values
foreach my $type qw(group icon map reticle text window) {
    $itemtypes{$type} = $zinc->add($type, 1);
}

# These items needs some coordinates at creation time
# However curves usually needs more than 2 points.
foreach my $type qw(arc curve rectangle) {
    $itemtypes{$type} = $zinc->add($type, 1, [0,0 , 1,1]);
}
# Triangles item needs at least 3 points for the coordinates 
foreach my $type qw(triangles) {
    $itemtypes{$type} = $zinc->add($type, 1, [0,0 , 1,1 , 2,2]);
}


my %zinc2doc;  # a hash recording every discrepency between attribute/option
               # type between the doc and TkZinc
my %documentedOptions;
my %itemAttributeDoc;
my %documentedTypes;
my %usedTypes; # hash recording all refered types in the doc

die "missing refman.tex path_name as unique argument to this script" unless defined $ARGV[0];


&scanDoc ($ARGV[0]);

sub scanDoc {
    my ($filename) = @_;
    open (DOC, $filename) or die "unable to open " . $filename . "\n";
    my $current_item = 0;
    my $prev_attribute = 0;
    my $prev_type = 0;

    while (<DOC>) {
	if ( /^\\attribute\{(\w+)\}\{(\w+)\}\{(\w+)\}/ ) {
	    my $item = $1;
	    my $attribute = $2;
	    my $type = $3;
	    $itemAttributeDoc{$item}{-$attribute} = $type;
	    if ($item eq $current_item) {
		if ($attribute lt $prev_attribute) {
		    print "W: attributes $prev_attribute and $attribute are not in alphabetical order for $item\n";
		}
	    }
	    else {
		$current_item = $item;
		$prev_attribute = $attribute;
	    }
	}
	elsif ( /^\\option\{(\w+)\}\{(\w+)\}\{(\w+)\}/ ) {
	    my $optionName = $1;
	    my $databaseName = $2;
	    my $databaseClass = $3;
	    $documentedOptions{-$optionName} = $databaseClass;
	}
	elsif ( /^\\attrtype\{(\w+)\}/ ) {
	    my $type = $1;
	    $documentedTypes{$type} = $type;
	    if ($type lt $prev_type) {
		print "W: type $prev_type and $type are not in alphabetical order\n";
	    }
	    $prev_type = $type;
	}
    }
}

sub testAllOptions {
    my @options = $zinc->configure();
    my %options;
    # we use this hashtable to check that all documented options
    # are matching all existing options in TkZinc
    
    for my $elem (@options) {
	my ($optionName, $optionDatabaseName, $optionClass, $default, $optionValue) = @$elem;
	$options{$optionName} = [$optionClass, $default, "", $optionValue];
    }

    foreach my $optionName (sort keys %options) {
	my ($optionType, $readOnly, $empty, $optionValue) = @{$options{$optionName}};
	# $empty is for provision by Zinc

	if (!defined $documentedOptions{$optionName}) {
	    print "E: $optionName ($optionType) of Zinc IS NOT DOCUMENTED!\n";
	    $options{$optionName} = undef;
	    next;
	}
	if ($documentedOptions{$optionName} ne $optionType) {
	    print "W: $optionName has type $optionType inside ZincTk and type $documentedOptions{$optionName} inside Doc\n";
	    $zinc2doc{$optionType}=$documentedOptions{$optionName};
	}
#	$attributes{$attributeName} = undef;
	$documentedOptions{$optionName} = undef;
    }
    
    foreach my $unexistingDocOpt (sort keys %documentedOptions) {
	if (defined $documentedOptions{$unexistingDocOpt}) {
	    print "E: The Documented Option \"$unexistingDocOpt\" DOES NOT EXIST!\n";
	}
    }
}

sub testAllAttributes {
    my ($item) = @_;

    my %documentedAttributes = %{$itemAttributeDoc{$item}}; 
    my @attributes = $zinc->itemconfigure($itemtypes{$item});

    my %attributes;
    # we use this hashtable to check that all documented attributes
    # are matching all existing attributes in TkZinc

    # verifying that all referenced types are defined
    # and storing used types
    foreach my $attribute (sort keys %documentedAttributes) {
	my $type = $documentedAttributes{$attribute};
	$usedTypes{$type} = 1;
	print "E: type $type ($attribute of $item) is not documented\n" unless $documentedTypes{$type};
    }
    
    foreach my $elem (@attributes) {
	my ($attributeName, $attributeType, $readOnly, $empty, $attributeValue) = @$elem;
	$attributes{$attributeName} = [$attributeType, $readOnly, $empty, $attributeValue];
    }

    foreach my $attributeName (keys %attributes) {
	my ($attributeType, $readOnly, $empty, $attributeValue) = @{$attributes{$attributeName}};
	# $empty is for provision by Zinc
	
	if (!defined $documentedAttributes{$attributeName}) {
	    print "E: $attributeName ($attributeType) of item $item IS NOT DOCUMENTED!\n";
	    $attributes{$attributeName} = undef;
	    next;
	}

	if ($documentedAttributes{$attributeName} ne $attributeType) {
	    print "W: $attributeName has type $attributeType inside ZincTk and type $documentedAttributes{$attributeName} inside Doc\n";
	    $zinc2doc{$attributeType}=$documentedAttributes{$attributeName};
	}
#	$attributes{$attributeName} = undef;
	$documentedAttributes{$attributeName} = undef;
    }
    
    foreach my $unexistingDocAttr (sort keys %documentedAttributes) {
	if (defined $documentedAttributes{$unexistingDocAttr}) {
	    print "E: The Documented Attribute \"$unexistingDocAttr\" DOES NOT EXIST!\n";
	}
    }
}


sub testFieldAttributes {
    my %documentedAttributes = %{$itemAttributeDoc{"field"}}; 
    my @attributes = $zinc->itemconfigure($itemtypes{track},0);

    my %attributes;
    # we use this hashtable to check that all documented fields attributes
    # are matching all existing fields attributes in TkZinc
    
    # verifying that all referenced types are defined
    # and storing used types
    foreach my $attribute (sort keys %documentedAttributes) {
	my $type = $documentedAttributes{$attribute};
	$usedTypes{$type} = 1;
	print "E: type $type ($attribute of 'field') is not documented\n" unless $documentedTypes{$type};
    }
    

    foreach my $elem (@attributes) {
	my ($attributeName, $attributeType, $readOnly, $empty, $attributeValue) = @$elem;
	$attributes{$attributeName} = [$attributeType, $readOnly, $empty, $attributeValue];
    }

    foreach my $attributeName (keys %attributes) {
	my ($attributeType, $readOnly, $empty, $attributeValue) = @{$attributes{$attributeName}};
	# $empty is for provision by Zinc
	
	if (!defined $documentedAttributes{$attributeName}) {
	    print "E: $attributeName ($attributeType) of field IS NOT DOCUMENTED!\n";
	    $attributes{$attributeName} = undef;
	    next;
	}

	if ($documentedAttributes{$attributeName} ne $attributeType) {
	    print "W: $attributeName of field has type $attributeType inside ZincTk and type $documentedAttributes{$attributeName} inside Doc\n";
	    $zinc2doc{$attributeType}=$documentedAttributes{$attributeName};
	}
	$documentedAttributes{$attributeName} = undef;
    }
    
    foreach my $unexistingDocAttr (sort keys %documentedAttributes) {
	if (defined $documentedAttributes{$unexistingDocAttr}) {
	    print "E: The Documented Field Attribute \"$unexistingDocAttr\" DOES NOT EXIST!\n";
	}
    }
}

sub verifyingAllDefinedTypesAreUsed {
    foreach my $type (sort keys %documentedTypes) {
	print "W: documented type $type is never refered to in the doc\n" unless $usedTypes{$type};
    }
}

print "--- TkZinc Options -----------------------------------------\n";
&testAllOptions;
print "--- Field Attributes ---------------------------------------\n";

&testFieldAttributes;

foreach my $type (sort keys %itemtypes) {
    print "--- Item $type -------------------------------------------------\n";
    &testAllAttributes($type);
}

&verifyingAllDefinedTypesAreUsed;

print "------- Summary of type discrepencies between Doc and Zinc --------\n";
printf "%15s |%15s\n", "zinctype","doctype";
foreach my $typezinc (sort keys %zinc2doc) {
    printf "%15s |%15s\n", $typezinc,$zinc2doc{$typezinc};
}


# MainLoop();


1;
