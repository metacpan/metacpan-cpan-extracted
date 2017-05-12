package XMLNews::Meta;

use strict;
				# The second row consists of static
				# variables used during XML import.
				# These variables prevent the module
				# from being thread-safe or reentrant.
use vars qw($VERSION $XNNS $RDFNS $DCNS %NS_PREFIX_MAP
	    $SELF $DATA @DATA_STACK $READINGPROPS);
use XML::Parser;
use Carp;
use IO;

$VERSION = '0.01';

#
# Static class variables
#

				# Some well-known namespaces...
$XNNS = "http://www.xmlnews.org/namespaces/meta#";
$RDFNS = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
$DCNS = "http://www.purl.org/dc#";

				# Namespace/prefix map for exporting
				# some commonly-known namespaces
				# (all others will have auto-generated
				# prefixes).
%NS_PREFIX_MAP = ($XNNS => "xn",
		  $RDFNS => "rdf",
		  $DCNS => "dc");


#
# Constructor.
#
sub new {
  my $class = shift;

				# The namespaces will be the top-level
				# keys, mapped to buckets containing
				# the names in each namespace
  return bless {}, $class;
}


#
# Return an array of namespaces used in the metadata.
#
sub getNamespaces {
  my $self = shift;
  my @ns = keys(%{$self});
  my $ns;
  foreach $ns (@ns) {
    if ($ns eq $RDFNS) {
      return @ns;
    }
  }
  push @ns, $RDFNS;
  return @ns;
}


#
# Return an array of property names used in a namespace.
#
sub getProperties {
  my ($self, $namespace) = (@_);
  my $ns = $self->{$namespace};
  return () unless $ns;
  return keys(%{$ns});
}


#
# Assign a value to a property in a namespace.
#
sub addValue {
  my ($self, $namespace, $property, $value) = (@_);

				# Get the namespace.
  my $ns = $self->{$namespace};
  unless ($ns) {		# Create a new namespace if necessary.
    $ns = {};
    $self->{$namespace} = $ns;
  }

				# Get the bucket.
  my $bucket = $ns->{$property};
  unless ($bucket) {		# Create a new bucket if necessary.
    $bucket = [];
    $ns->{$property} = $bucket;
  }

				# Add the value to the bucket.
  push @{$bucket}, $value;
}


#
# Return an array of values for a property in a namespace.
#
sub getValues {
  my ($self, $namespace, $property) = (@_);

				# Get the namespace.
  my $ns = $self->{$namespace};
  return () unless $ns;

				# Get the bucket.
  my $bucket = $ns->{$property};
  if ($bucket) {
    return @{$bucket};
  } else {
    return ();
  }
}


#
# Return a single value for a property in a namespace.
# This method will croak if the property has more than one value.
#
sub getValue {
  my ($self, $namespace, $property) = (@_);

				# Get the values for this property
  my @values = $self->getValues($namespace, $property);

				# Enforce maximum of one value.
  if ($#values < 1) {
    return $values[0];
  } else {
    croak "Multiple values for $property in $namespace namespace";
  }
}


#
# Return true if the specified property has at least one value.
#
sub hasValue {
  my ($self, $namespace, $property) = (@_);
  my @values = $self->getValues($namespace, $property);

				# This is probably a little inefficient
				# for now, but it will do.
  if ($#values > -1) {
    return 1;
  } else {
    return undef;
  }
}


#
# Remove the first occurrence of a value from a property in a namespace.
# Carp (don't croak) if we don't find it.
#
sub removeValue {
  my ($self, $namespace, $property, $value);

				# Try to find the namespace
  my $ns = $self->{$namespace};
  unless ($ns) {
    return;
  }

				# Try to find the property
  my $bucket = $ns->{$property};
  unless ($bucket) {
    return;
  }

				# Remove the first
  my ($i, $len);
  LOOP: for ($i = 0, $len = $#{$bucket}; $i <= $len; $i++) {
      if ($bucket->[$i] eq $value) {
	splice(@{$bucket}, $i, 1);
	last LOOP;
      }
    }


				# Remove an empty bucket.
  if ($#{keys(%{$bucket})} == -1) {
    delete $ns->{$property};
  }

				# Remove an empty namespace.
  if ($#{keys(%{$ns})} == -1) {
    delete $self->{$namespace};
  }
}


#
# Export properties.
#
sub exportRDF {
  my ($self, $output) = (@_);
  my $counter = 0;
  my %nsmap = (%NS_PREFIX_MAP);	# local copy

				# If the $output argument is a string,
				# open a file and invoke this method
				# recursively.
  unless (ref($output)) {
    $output = new IO::File(">$output") || croak "Cannot write to file $output";
    $self->exportRDF($output);
    $output->close();
    return;
  }

				# Loop up all of the namespaces in use.
  my @namespaces = $self->getNamespaces();
  $output->print("<?xml version=\"1.0\">\n\n<rdf:RDF");

				# Make certain that we have a prefix
				# for every namespace.
  my $ns;
  foreach $ns (@namespaces) {
    if (!$nsmap{$ns}) {
      $nsmap{$ns} = "p" . $counter++;
    }
    $output->print("\n  xmlns:" . $nsmap{$ns} . "=\"$ns\"");
  }
  $output->print(">\n<rdf:Description>\n");

  foreach $ns (@namespaces) {
    my @properties = $self->getProperties($ns);
    my $prop;
    foreach $prop (@properties) {
      my $name = $nsmap{$ns} . ':' . $prop;
      my @values = $self->getValues($ns, $prop);
      my $value;
      foreach $value (@values) {
	$output->print("<$name>$value</$name>\n");
      }
    }
  }

  $output->print("</rdf:Description>\n<rdf:RDF>\n");
}


#
# Import literal properties from an RDF document.
# This method is not thread-safe or reentrant.
#
sub importRDF {
  my ($self, $input) = (@_);
  my $parser = $self->_make_parser();

				# Initialise static variables used
				# during the parse.  It would be
				# better to use closures, but they
				# are causing serious memory leaks.
  $DATA = '';
  @DATA_STACK = ();
  $READINGPROPS = 0;
  
  unless (ref($input)) {
    $input = new IO::File("<$input") || croak "Cannot read file $input";
    $self->importRDF($input);
    $input->close();
    return;
  }
  $SELF = $self;
  $parser->parse($input);
  $SELF = undef;
}


#
# Internal method: handle the start of an element during import.
# (This should be a closure, but closures leak badly.)
#
sub _start {
  my ($expat, $name) = (@_);
  my $self = $SELF;
  my $ns = $expat->namespace($name);

			      # Start capturing data.
  push @DATA_STACK, $DATA;
  $DATA = "";

			      # Oops!  There is no namespace!
  unless (defined($ns)) {
    $expat->xpcarp ("Element $name has no declared namespace\n");
  }

  unless ($READINGPROPS) {
    if ($ns eq $RDFNS && $name eq 'RDF') {
      # no op!
    } elsif ($ns eq $RDFNS && $name eq 'Description') {
      $READINGPROPS = 1;
    } else {
      $READINGPROPS = 1;
      $self->addValue($RDFNS, "type", $ns . $name);
    }
  }
}


#
# Internal method: handle the end of an element during import.
# (This should be a closure, but closures leak badly.)
#
sub _end {
  my ($expat, $name) = (@_);
  my $self = $SELF;
  my $ns = $expat->namespace($name);

  if (!defined($ns)) {
    $expat->xpcarp("Element $name has no declared namespace\n");
  } elsif (($ns eq $XNNS && $name eq "Resource") ||
	   ($ns eq $RDFNS && $name eq "Description")){
    $READINGPROPS = 0;
  } elsif ($READINGPROPS) {
    $self->addValue($ns, $name, $DATA);
  }

			      # Finish capturing data.
  $DATA = pop @DATA_STACK;
}


#
# Internal method: handle character data during import.
# (This should be a closure, but closures leak badly.)
#
sub _char {
  my ($expat, $data) = (@_);
  my $self = $SELF;
  $DATA .= $data;
}


#
# Create an XML parser.
#
sub _make_parser {
  my $self = shift;

				# Create the actual parser.
  return new XML::Parser(Handlers => {Start => \&_start,
				      End => \&_end,
				      Char => \&_char},
				Namespaces => 1);
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XMLNews::Meta - A module for reading and writing XMLNews metadata files.


=head1 SYNOPSIS

  use XMLNews::Meta;

  my $namespace = "http://www.xmlnews.org/namespaces/meta#";

				# Create a Meta object.
  my $meta = new XMLNews::Meta();

				# Read in the metadata file.
  $meta->importRDF("data.rdf");

				# Look up a singleton value.
  my $expireTime = $meta->getValue($namespace, "expireTime");

				# Add a new value to a property.
  $meta->addValue($namespace, "companyCode", "WAVO");

				# Write the metadata back out.
  $meta->exportRDF("data.rdf");


=head1 DESCRIPTION

NOTE: This module requires the XML::Parser module, version 2.19 or higher.

WARNING: This module is not re-entrant or thread-safe due to the use
of static variables while importing XML.

The XMLNews::Meta module handles the import, export, and programmatic
manipulation of metadata for XMLNews resources.  You can read or write
a metadata file using a single method call, and can easily add or
remove values.

Traditionally, resource files consist of simple pairs of the form

  NAME = VALUE

XMLNews metadata, which is based on the W3C's Resource Description
Format (RDF), allows richer metadata in two ways:

=over 4

=item 1

Property names are partitioned into namespaces, so that two different
providers can use the same property name without fear of collision (a
namespaces is simply a URI (URL or URN); following RDF practice, the
URI should end with the fragment separator "#".  To look up a
property, you always need to use both the namespace and the property
name:

  $xn_ns = "http://www.xmlnews.org/namespaces/meta#";

				# Use getValue only for 
				# singleton values!!!
  $title = $meta->getValue($xn_ns, "title");
  $creator = $meta->getValue($xn_ns, "creator");

=item 2

The same property can have more than one value, which the getValues
method will deliver as an array:

  $xn_ns = "http://www.xmlnews.org/namespaces/meta#";
  @companyCodes = $meta->getValues($xn_ns, 'companyCodes');

=back


=head1 METHODS

=over 4

=item new()

Create a new (empty) metadata collection:

  use XMLNews::Meta;
  my $meta = new XMLNews::Meta();

Once you have created the collection, you can add values manually
using the addValue() method, or import one or more files into the
collection using the importRDF() method.


=item importRDF(INPUT)

Read an RDF file from the IO::Handle input stream provided, and add
its properties to this metadata collection:

  $meta->importRDF($handle);

If INPUT is a string, it will be treated as a file name; otherwise, it
will be treated as an instance of IO::Handle.

Note that duplicate properties will not be filtered out, so it is
possible to have the same property with the same value more than once.
Importing a file does not remove any properties already in the
collection.

=item exportRDF(OUTPUT)

Export all of the properties in the collection to an IO::Handle output
stream of some sort:

  $meta->exportRDF($output);

If OUTPUT is a string, it will be treated as a file name; otherwise, it
will be treated as an instance of IO::Handle.

The XML::Meta module will create its own namespace prefixes for the
different namespaces in the document, but the namespaces themselves
will not be changed.

=item getValues(NAMESPACE, PROPERTY)

Return all of the values for a property in a namespace as an array.
If the property does not exist, return an empty array:

  my $namespace = "http://www.xmlnews.org/namespaces/meta#";
  my @people = $meta->getValues($namespace, 'personName');
  foreach $person (@people) {
    print "This resource mentions $person\n";
  }

Note that it is always necessary to provide a namespace as well as a
property name; the property 'personName' might have a different
meaning in another namespace.

(When you know for certain that a property will never have more than
one value, you can use the getValue() method instead to avoid dealing
with an array.)

=item getValue(NAMESPACE, PROPERTY)

Return a single value (or undef) for a property in a namespace:

  my $resourceId = $meta->getValue($namespace, 'resourceId');

This method is convenient for properties (like XMLNews's 'resourceId')
which should never have more than one value.  

NOTE: If there is more than one value present for the resource, the
getValue() method will croak().


=item hasValue(NAMESPACE, PROPERTY)

Return true if the specified property has one or more values, and
false otherwise:

  unless ($meta->hasValue($namespace, 'provider')) {
    print "No provider information available\n";
  }

=item getNamespaces()

Return an array containing all of the namespaces used in the metadata
collection:

  my @namespaces = $meta->getNamespaces();

Each namespace is a URI (URL or URN) represented as a string.

=item getProperties(NAMESPACE)

Return an array containing all of the properties defined for a
specific namespace in the metadata collection:

  my @properties = $meta->getProperties($namespace);

If the namespace does not exist, this method will croak().

=item addValue(NAMESPACE, PROPERTY, VALUE)

Add a value for a property in a namespace:

  $meta->addValue($namespace, "locationName", "Salt Lake City");

=item removeValue(NAMESPACE, PROPERTY, VALUE)

Remove a value for a property in a namespace:

  $meta->removeValue($namespace, "locationName", "Dallas");

If the namespace, property, or value does not exist, this method will
croak().

=back

=head1 CONFORMANCE NOTE

The XMLNews metadata format is based on RDF, but this tool is not
a general RDF processor; instead, it relies on a particular usage
profile and a particular abbreviated syntax, like the following:

  <?xml version="1.0"?>
  <xn:Resource xmlns:xn="http://www.xmlnews.org/namespaces/meta#">
   <xn:resourceId>12345</xn:resourceId>
   <xn:title>Sample</xn:title>
   <xn:description>Sample resource.</xn:description>
   <xn:rendition>12345.xml</xn:rendition>
   <xn:rendition>12345.html</xn:rendition>
  </xn:Resource>

=head1 AUTHOR

This module was originally written for WavePhore by David Megginson
(david@megginson.com).

=cut


=cut
