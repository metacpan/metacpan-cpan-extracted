package XMLNews::HTMLTemplate;

use strict;
use vars qw($VERSION);
use IO::Handle;
use XML::Parser;
use XMLNews::Meta;

$VERSION = '0.01';



########################################################################
# Compiled information from the XML/NITF document.
#
# This class is intended for internal use only.
#
# Information extracted from the NITF document is stored as a series 
# of hash/value pairs, where the hash values are buckets containing 
# zero or more literal values (in document order).
########################################################################

package XMLNews::HTMLTemplate::NITF;
				# Use static variables -- closures would
				# be better, but currently they leak
				# memory very badly.
use vars qw($SELF $DATA @DATA_STACK);
use Carp;


#
# Constructor.
#
sub new {
  my ($class) = (@_);
  my $self = {};
  return bless $self, $class;
}


#
# Return the values of a pseudo-property as an array.
#
sub getValues {
  my ($self, $propname) = (@_);
  if ($self->{$propname}) {
    return @{$self->{$propname}};
  } else {
    return ();
  }
}


#
# Add a value for a pseudo-property.
#
sub addValue {
  my ($self, $propname, $value) = (@_);
  unless ($self->{$propname}) {
    $self->{$propname} = [];
  }
  push @{$self->{$propname}}, $value;
}


#
# Return true if there are any values available for a pseudo-property.
#
sub hasValue {
  my ($self, $propname) = (@_);
  if ($self->{$propname}) {
    my @values = @{$self->{$propname}};
  } else {
    return undef;
  }
}


#
# Direct mappings between NITF and HTML
# TODO: handle tables, media objects, and postaddr.
#
my %html_mappings = ('h1' => 'h1',
		     'h2' => 'h2',
		     'h3' => 'h3',
		     'h4' => 'h4',
		     'p' => 'p',
		     'ol' => 'ol',
		     'ul' => 'ul',
		     'li' => 'li',
		     'dl' => 'dl',
		     'dt' => 'dt',
		     'dd' => 'dd',
		     'em' => 'em',
		     'pre' => 'pre',
                     'table' => 'table',
                     'tr' => 'tr',
		     'th' => 'th',
                     'td' => 'td');


#
# XML event handler for the start of an element.
# This should be a closure, but closures leak memory, so we're using
# static variables instead.
#
sub _start {
  my ($expat, $name, %atts) = (@_);
  my $self = $SELF;
  push @DATA_STACK, $DATA;
  $DATA = '';

  if ($html_mappings{$name}) {
    $DATA .= "<" . $html_mappings{$name} . ">";
  }
}


#
# XML event handler for the end of an element.
# This should be a closure, but closures leak memory, so we're using
# static variables instead.
#
sub _end {
  my ($expat, $name) = (@_);
  my $self = $SELF;

			      # If the element ending has a direct
			      # mapping to an HTML element,
			      # include the appropriate end tag.
  if ($html_mappings{$name}) {
    $DATA .= "</" . $html_mappings{$name} . ">";
  }

			      # If the element ending is one of the
			      # fields we need, save it; otherwise, 
			      # append its data to its parent's.
  if ($name eq 'hl1') {
    $self->addValue('headline', $DATA);
    $DATA = pop @DATA_STACK;
  } elsif ($name eq 'hl2') {
    $self->addValue('subheadline', $DATA);
    $DATA = pop @DATA_STACK;
  } elsif ($name eq 'bytag') {
    $self->addValue('byline', $DATA);
    $DATA = pop @DATA_STACK;
  } elsif ($name eq 'distributor') {
    $self->addValue('distributor', $DATA);
    $DATA = pop @DATA_STACK;
  } elsif ($name eq 'dateline') {
    $self->addValue('dateline', $DATA);
    $DATA = pop @DATA_STACK;
  } elsif ($name eq 'body.content') {
    $self->addValue('body', $DATA);
    $DATA = pop @DATA_STACK;
  } else {
    $DATA = (pop @DATA_STACK) . $DATA;
  }
}


#
# XML event handler for character data.
# This should be a closure, but closures leak memory, so we're using
# static variables instead.
#
sub _char {
  my ($expat, $data) = (@_);

  $DATA .= $data;
}


#
# Read an XML/NITF document and fill in the object's fields.
# TODO: add parse error handling.
#
sub readNITF {
  my ($self, $input) = (@_);

  unless (ref($input)) {
    $input = new IO::File("<$input") || croak "Cannot read NITF file $input";
  }

				# Create a new parser object.
  my $parser = new XML::Parser(Handlers => {Start => \&_start,
					    End => \&_end,
					    Char => \&_char});
  
				# Parse the XML/NITF file using the
				# handlers (closures) defined above.
  $SELF = $self;
  $DATA = '';
  @DATA_STACK = ();
  $parser->parse($input);
  $SELF = $DATA = @DATA_STACK = undef;
}



########################################################################
# Compiled HTML template file.
#
# This is stored as a tree of array references: the first element of
# each array is a tag giving the node type.  The nodes take the
# following format:
#
# template node (root): ['template', CHILDREN...]
# text node (leaf): ['text', STRING]
# insert node (leaf): ['insert', PROPNAME]
# if node: ['if', [TRUE-CHILDREN], [ELSE-CHILDREN]]
# foreach node: ['foreach', CHILDREN...]
########################################################################

package XMLNews::HTMLTemplate;
use strict;
use vars qw($START_TEXT
	    $START_PATTERN
	    $END_TEXT
	    $END_PATTERN
	    $MODE_TOP
	    $MODE_IF
	    $MODE_ELSE
	    $MODE_FOREACH
	    $OUT
	    $META
	    $NITF);
use Carp;

#
# Constants
#
				# PATTERNS:

$START_TEXT = "<?XNews";	# start-of-command pattern
$START_PATTERN = "\\<\\?XNews";
$END_TEXT = ">";		# end-of-command pattern
$END_PATTERN = "\\??\\>";

				# PARSING STATES:

$MODE_TOP = 0;			# top-level
$MODE_IF = 1;			# in main part of 'if' block
$MODE_ELSE = 2;			# in 'else' part of 'if' block
$MODE_FOREACH = 3;		# in 'foreach' block


#
# Constructor.
#
sub new {
  my ($class) = (@_);
  my $self = [['template']];
  return bless $self, $class;
}


#
# Read a template file and parse it into a tree structure.
#
# This uses simple regular-expression matching for the parse; it does
# not attempt to read the template as a proper SGML/HTML or XML/HTML
# document, because it is unlikely that the template was written that
# way (even though it could be).
#
sub readTemplate {
  my ($self, $input) = (@_);

  my $oldRS = $/;

				# Erase any old compiled tree, in case
				# this object is being reused.
  $self->[0] = ['template'];

				# If the input argument is a file name,
				# attempt to open the file; otherwise,
				# treat it as a handle.
  unless (ref($input)) {
    $input = new IO::File("<$input")
      || croak "Cannot read HTML template file $input";
    $self->readTemplate($input);
    $input->close();
    return;
  }

  #
  # Variables to hold parse state.
  #
  my @node = ();		# node stack
  my $node = $self->[0];	# current node (start at top level)

  my @container = ();		# container stack
  my $container = $node;	# current container (not always the
				# same as current node, since 'if'
				# nodes have two containers)

  my @mode = ();		# mode stack
  my $mode = $MODE_TOP;		# current mode (see constants above)

  my $data = '';
  my %namespaces;		# declared namespaces

  #
  # Main parsing loop
  #
  # Keep looping until we do not find the start of a command.
  #
  $/ = $START_TEXT;		# set the delimiter to "<?XNews"
  LOOP: while (defined($data = <$input>)) {

				# Did we find "<?XNews"?
      if ($data =~ /^(.*)($START_PATTERN)$/s) {
				# ...yes
	if ($1) {
	  push @{$container}, ['text', $1];
	}
      } else {
				# ...no, end the document
	if ($data) {
	  push @{$container}, ['text', $data];
	}
	last LOOP;
      }

  
				# Now, try to read to the end of the
				# command, and report an error if
				# there is something wrong (there's no
				# graceful way to recover from an
				# unterminated command)
      $/ = $END_TEXT;
      unless (defined($data = <$input>) &&
	      ($data =~ /^([^\>\?]*)($END_PATTERN)$/m)) {
	croak "Template: unterminated command: $data (line $.)";
      }
    
				# Split up the command into the keyword
				# and the optional parameter
      my $command = $1;
      unless ($command =~ m/^\s*(\S+)\s*(\S+|\S+\s*=\s*\S+)?\s*$/) {
	croak "Malformed template command: $command (line $.)";
      }
      my ($key, $param) = ($1, $2);

				# Deal with the known command types;
				# print a warning for an unknown command,
				# but don't actually stop processing,
				# since we can probably recover
    SWITCH: {

				# 'namespace' declares a namespace
				# prefix for later use; it does not
				# generate a node in the final tree
	($key eq 'namespace') && do {
	  unless (defined($param) && $param =~ /^(\S+)\s*=\s*(\S+)$/) {
	    croak "Template: malformed namespace assignment: $param (line $.)";
	  }
	  my ($prefix, $uri) = ($1, $2);
	  if ($uri =~ /^([\'\"])/) {
	    my $delim = $1;
	    $uri = $';
	    if ($uri =~ /$delim$/) {
	      $uri = $`;
	    } else {
	      croak "Template: unterminated namespace URI starting with $delim (line $.)";
	    }
	  }
	  if ($uri =~ /^[\'\"](.*)[\'\"]$/) {
	    $uri = $1;
	  }
	  $namespaces{$prefix} = $uri;
	  last SWITCH;
	};

				# At this point, everything else
				# will need namespace processing.
	my $prop;
	if (defined($param) && $param =~ /^([^:]+):([^:]+)$/) {
	  $prop = [$namespaces{$1}, $2];
	  unless ($prop->[0]) {
	    carp "Unrecognised namespace prefix: $1";
	  }
	} else {
	  $prop = [undef, $param];
	}

				# 'insert' is a leaf node, so we don't
				# have to mess with the state or the
				# stacks
	($key eq 'insert') && do {
	  push @{$container}, ['insert', $prop];
	  last SWITCH;
	};
				# 'if' is a branch node, so we have to
				# push a new state and a new container
				# ('if' branches have two containers;
				# we always start with the first one)
	($key eq 'if') && do {
	  push @mode, $mode;
	  $mode = $MODE_IF;
	  push @node, $node;
	  push @container, $container;
	  $node = ['if', $prop, [], []];
	  $container = $node->[2];
	  last SWITCH;
	};

				# 'else' is just a continuation of
				# an 'if' node, so simply switch from
				# the first 'if' container to the
				# second and set a new mode
	($key eq 'else') && do {
	  if ($mode eq $MODE_IF) {
	    $mode = $MODE_ELSE;
	    $container = $node->[3];
	  } else {
	    carp "'else' outside of 'if' block";
	  }
	  last SWITCH;
	};

				# 'end' means finish up the current
				# container and pop up a level
	($key eq 'end') && do {
	  if ($mode eq $MODE_TOP) {
	    carp "'end' outside of 'if' or 'foreach' block";
	  } else {
	    $mode = pop @mode;
	    $container = pop @container;
	    push @{$container}, $node;
	    $node = pop @node;
	  }
	  last SWITCH;
	};

				# 'foreach' is a branch node, so we
				# have to change the state and push
				# a new container
	($key eq 'foreach') && do {
	  push @mode, $mode;
	  $mode = $MODE_FOREACH;
	  push @node, $node;
	  push @container, $container;
	  $node = ['foreach', $prop];
	  $container = $node;
	  last SWITCH;
	};
	
				# Unrecognised command: whine a bit
	carp "Unrecognised XNews template command: $key $param";
      }

      $/ = $START_TEXT;
    }

  # end of loop.

				# OK, now the parse loop is finished,
				# and it's time to clean up.

				# Check that any 'if' or 'foreach'
				# blocks have been ended correctly
  if ($mode eq $MODE_IF || $mode eq $MODE_ELSE) {
    croak("Template finished before end of 'if' block");
  } elsif ($mode eq $MODE_FOREACH) {
    croak("Template finished before end of 'foreach' block");
  }

				# Restore the former record separator.
  $/ = $oldRS;
}


#
# Apply a compiled template to an NITF file and an RDF file.
#
sub applyTemplate {
  my ($self, $out, $nitf, $meta) = (@_);
  my @openHandles = ();

  #
  # If the 'out' argument is a string, try to open it as a file.
  #
  unless (ref($out)) {
    $out = new IO::File(">$out") || croak "Cannot write to file $out";
    push @openHandles, $out;
  }
  
  #
  # Ensure that we have an NITF object to work with
  #
  if ($nitf && (ref($nitf) ne 'XMLNews::HTMLTemplate::NITF')) {
    my $input = $nitf;
    $nitf = new XMLNews::HTMLTemplate::NITF();
    $nitf->readNITF($input);
  }
  
  #
  # Ensure that we have a meta object to work with.
  #
  if ($meta && (ref($meta) ne 'XMLNews::Meta')) {
    my $input = $meta;
    $meta = new XMLNews::Meta();
    $meta->importRDF($input);
  }
				# Recursively walk the template tree
  $META = $meta;
  $NITF = $nitf;
  $OUT = $out;
  _writeNode($self->[0]);
  $META = $NITF = $OUT = undef;

				# Close any handles that we opened
				# ourselves.
  my $handle;
  foreach $handle (@openHandles) {
    $handle->close();
  }
}


#
# Closure: write out a node in the HTML file.
#
# This is an internal subroutine that has access to all of
# the local variables in the context where it was defined.
#
# Scheme programmers love this sort of thing; it's still pretty
# new to Perl, though.
#
sub _writeNode {
  my ($node, $foreachProp, $foreachValue) = (@_);

			      # Copy the node...
  my $type = $node->[0];

SWITCH: {

			      # top-level template: process
			      # the children
    ($type eq 'template') && do {
      my ($type, @children) = (@{$node});
      my $child;
      foreach $child (@children) {
	_writeNode($child);
      }
      last SWITCH;
    };

			      # literal text: just dump it out
    ($type eq 'text') && do {
      my $text = $node->[1];
      $OUT->print($text);
      last SWITCH;
    };

			      # insertion: look up the value
			      # or values for the property (and
			      # check whether we're in a foreach)
    ($type eq 'insert') && do {
      my $prop = $node->[1];
      if (defined($foreachProp) &&
	  $prop->[0] eq $foreachProp->[0] &&
	  $prop->[1] eq $foreachProp->[1]) {
	$OUT->print($foreachValue);
      } else {
	my @values = _getValues($prop);
	$OUT->print("@values");
      }
      last SWITCH;
    };

			      # if: execute the appropriate block,
			      # depending on whether the property
			      # has any values
    ($type eq 'if') && do {
      my ($type, $prop, $mainblock, $altblock) = (@{$node});
      if (_hasValue($prop)) {
	foreach $node (@{$mainblock}) {
	  _writeNode($node);
	}
      } else {
	foreach $node (@{$altblock}) {
	  _writeNode($node);
	}
      }
      last SWITCH;
    };

			      # foreach: iterate through all of the
			      # values for the property, processing
			      # the block with a different value
			      # bound each time
    ($type eq 'foreach') && do {
      my ($type, $prop, @block) = (@{$node});
      my @values = _getValues($prop);
      my $value;
      foreach $value (@values) {
	foreach $node (@block) {
	  _writeNode($node, $prop, $value);
	}
      }
      last SWITCH;
    };

    carp "Unknown template node type: $type";
  }
}


#
# Closure: return all NITF and/or RDF values for a property.
#
sub _getValues {
  my ($prop) = shift;
  my ($uripart, $localpart) = (@{$prop});
  my @values = ();

			      # If there's a URI part, look in the
			      # RDF; otherwise, look in the NITF.
  if ($uripart) {
    @values = $META->getValues($uripart, $localpart) if $META;
  } else {
    @values = $NITF->getValues($localpart) if $NITF;
  }

  return @values;
}


#
# Closure: return true if there are values available for a property.
#
sub _hasValue {
  my ($prop) = (@_);
  my ($uripart, $localpart) = (@{$prop});

  if ($uripart) {
    return $META && $META->hasValue($uripart, $localpart);
  } else {
    return $NITF && $NITF->hasValue($localpart);
  }
}


1;
# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

XMLNews::HTMLTemplate - A module for converting NITF to HTML.


=head1 SYNOPSIS

  use XMLNews::HTMLTemplate;

  my $template = new XMLNews::HTMLTemplate();
  $template->readTemplate("mytemplate.html");

  $template->applyTemplate("output.html", "story.xml", "story.rdf");


=head1 DESCRIPTION

NOTE: this module requires the XML::Parser and XMLNews::Meta modules.

WARNING: this module is not thread-safe or re-entrant.

The XMLNews::HTMLTemplate module provides a simple mechanism for
creating HTML pages from XML/NITF news stories and/or XML/RDF metadata
files based on a user-supplied template file.  The template is a
simple HTML file (SGML or XML flavour) using special template
commands, which the user includes as processing instructions, as in
the following example:

  <h1><?XNews insert headline?></h1>

To create an HTML page, you must first create an empty HTMLTemplate
object:

  my $template = new XMLNews::HTMLTemplate();

Next, you load the HTML template into the object:

  $template->readTemplate("mytemplate.html");

Now, you can apply the same compiled template object repeatedly to
different XML/NITF and/or XML/RDF documents to generate HTML pages:

  $template->applyTemplate("outfile.html", "newsstory.xml", "newsstory.rdf");

In this example, the module will read the XML/NITF news story in
newstory.xml and the XML/RDF metadata in newstory.rdf, and write an
HTML page at outfile.html.


=head1 METHODS

=over 4

=item new ()

Construct a new, empty instance of an XMLNews::HTMLTemplate object:

  my $template = new XMLNews::HTMLTemplate();


=item readTemplate(TEMPLATE)

Compile a template file into the current object, discarding any
existing compiled template:

  $template->readTemplate("news-template.htm");

The TEMPLATE argument may be either a string containing a file name or
an IO::Handle object.

You must compile a template before you can use it, but once you have
compiled the template, you may use it to create many different HTML
pages.


=item applyTemplate(OUT_FILE, NITF_FILE, RDF_FILE)

Apply the compiled template to an NITF-format news story and/or and
RDF-format metadata file, filling in the fields in the template
commands using the properties found in these files:

  $template->applyTemplate("story999.html", "story999.xml", "story999.rdf");

The three arguments may be either strings containing file names or
IO::Handle objects.  If the file specified by OUT_FILE already exists,
this method will overwrite its contents.

Either or both of the NITF_FILE or the RDF_FILE parameters may be
omitted if desired.

=back


=head1 HTML TEMPLATE FORMAT

An XMLNews template file is an HTML file containing special processing
instructions, beginning with "<?XNews " and ending with ">" or "?>".
Following the word "XNews", each processing instruction contains
whitespace and a command word, followed optionally by command
parameters, as in the following example:

  <?XNews insert headline?>

Typically, the template would include this processing instruction
within an HTML element:

  <h1><?XNews insert headline?></h1>

All processing instructions beginning with characters other than
"XNews" will be ignored and passed through as-is (they may be used for
other sorts of processing).


=head2 Template Commands

Any of the following six command words may follow the word "XNews" in
a processing instruction (all commands are case-sensitive):

=over 4

=item namespace PREFIX=URI

Declare a prefix representing a namespace:

  <?XNews namespace xn=http://www.xmlnews.org/namespaces/meta#?>

Once the prefix is declared, you can use it to point to properties in
the RDF file:

  <?XNews insert xn:person?>

Note that it is the namespace URIs rather than the prefixes that are
matched against RDF; the following would work identically with the
same RDF file:

  <?XNews namespace aBcDe=http://www.xmlnews.org/namespaces/meta#?>
  <?XNews insert aBcDe:person?>

All namespace declarations have global scope from the point of
declaration forward; it is usually best to include all of the
declarations at the top of the template.


=item insert PROPERTY

Insert the value of PROPERTY at this point in the generated document:

  <?XNews insert dateline?>

If there is more than one value available for the property, all of the
values will be inserted in random order, separated by spaces, unless
this processing instruction occurs within a "foreach" block (see
below).


=item if PROPERTY

Begin a conditional statement: 

  <?XNews if byline?>
   <h2><?XNews insert byline?></h2>
  <?XNews end?>

Everything between this processing instruction and the matching
"end" instruction will be included only if [property] has a
non-null value.

"if" commands may be nested.


=item else

Specify the default action for when an "if" command fails:

  <?XNews if date?>
   <p>Date: <?XNews insert date?></p>
  <?XNews else?>
   <p>Undated.</p>
  <?XNews end?>


=item foreach PROPERTY

Iterate over multiple values for a property:

  <?XNews foreach http://www.inews.org/props/CompanyCode?>
  <p>Ticker: <?XNews insert http://www.inews.org/props/CompanyCode?></p>
  <?XNews end?>

These instructions will create a separate <p> element for every
CompanyCode (ticker) value available.


=item end

Terminate an "if" or "foreach" statement:

  <?XNews if dateline?>
  <p>Dateline: <?XNews insert dateline?></p>
  <?XNews end?>


=back


=head2 Property Names

Property names consist of two parts: a namespace and a base name.
Properties derived from the NITF document have null namespace parts;
properties derived from the RDF metadata have non-null namespace
parts.  To specify a property with a non-null namespace part, you must
first declare a namespace prefix, and then include the prefix before
the property name separated with a colon:

  <?XNews namespace xn=http://www.xmlnews.org/namespaces/meta#?>

  <?XNews insert xn:companyCode?>

These commands insert the value of the property "companyCode" in the
http://www.xmlnews.org/namespaces/meta# namespace, as found in the RDF
metadata file.  You may access any property specified in the news
story's RDF metadata file in this way (such as ticker symbols, dates,
and the language of the resource).

In addition to the metadata properties in the RDF file, there are nine
special pseudo-properties that have a NULL namespace (most of these
duplicate properties in the RDF, but their values are also given in
the news story):

=over 4

=item headline

   The text of the story's headline, if any.

=item subheadline

   The text of the story's subheadline(s), if any.  There may be more
   than one value for this property, so it is best to include it in a
   "foreach" block.

=item byline

   The text of the story's byline(s), if any.  There may be more than
   one value for this property, so it is best to include it in a
   "foreach" block.

=item distributor

   The text of the distributor's name, if any.

=item dateline

   The text of the story's dateline, if any.

=item series.name

   The name of the series to which this story belongs, if any.

=item series.part

   The position of this story in a series, if any.

=item series.totalpart

   The total number of stories in this series, if any.

=item body

   HTML markup for the body of the story, divided into paragraphs.

=back



=head2 Sample Template

Here is a simple sample template for a news story (using XML/HTML
syntax); it does not use any RDF properties:

  <?xml version="1.0"?>

  <html>
  <head>
  <title>News Story: <?XNews insert headline?></title>
  </head>
  <body>
  <h1><?XNews insert headline?></h1>

  <?XNews foreach subheadline?>
  <h2><?XNews insert subheadline?></h2>
  <?XNews end?>

  <?XNews foreach byline?>
  <p><em><?XNews insert byline?></em></p>
  <?XNews end?>

  <p>(Dateline: <?XNews insert dateline?>)</p>

  <?XNews insert body?>

  </body>
  </html>


=head1 CONFORMANCE NOTE

The processing instruction target is "XNews" rather than XMLNews so
that template files can be well-formed XML if desired (XML reserves
all processing-instruction targets beginning with [xX][mM][lL]).

Given the wide variations in common HTML usage, this module uses
pattern matching on the HTML templates rather than trying to parse
them as SGML or XML documents.  As a result, it will recognise
template commands even within comments and attribute values, places
where they are not properly recognised in SGML or XML.


=head1 AUTHOR

This module was originally written by David Megginson (david@megginson.com).

=cut


