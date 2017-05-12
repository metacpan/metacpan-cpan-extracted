package XML::Filter::Sort;

use strict;
use Carp;

require XML::SAX::Base;


##############################################################################
#                     G L O B A L   V A R I A B L E S
##############################################################################

use vars qw($VERSION @ISA);

$VERSION = '1.01';

@ISA = qw(XML::SAX::Base);

use constant DEFAULT_BUFFER_MANAGER_CLASS => 'XML::Filter::Sort::BufferMgr';
use constant DISK_BUFFER_MANAGER_CLASS    => 'XML::Filter::Sort::DiskBufferMgr';


##############################################################################
#                             M E T H O D S
##############################################################################

##############################################################################
# Contructor: new()
#
# Set defaults for required properties and parse 'Keys' value from scalar to
# a list of lists if required.
#

sub new {
  my $proto = shift;

  my $class = ref($proto) || $proto;
  my $self = $class->SUPER::new(@_);

  croak "You must set the 'Record' option" unless($self->{Record});


  # Select memory vs disk buffering (or custom buffering class)
  
  if($self->{TempDir}) {
    $self->{BufferManagerClass} ||= DISK_BUFFER_MANAGER_CLASS;
  }
  unless($self->{BufferManagerClass}) {
    $self->{BufferManagerClass} = DEFAULT_BUFFER_MANAGER_CLASS;
  }
  my $mod_path = join('/', split(/::/, $self->{BufferManagerClass} . '.pm'));
  require $mod_path;


  # Organise sort keys into a list of 3-element lists
  
  $self->{Keys} = '.' unless($self->{Keys});
  unless(ref($self->{Keys})) {     # parse scalar to a list of lists
    my @keys = ();
    foreach (split(/[\r\n;]/, $self->{Keys})) {
      next unless(/\S/);
      s/,/ /g;
      my @key = /(\S+)/g;
      push @keys, \@key;
    }
    $self->{Keys} = \@keys;
  }
  foreach my $key (@{$self->{Keys}}) {
    croak "Keys must be a list of lists" unless(ref($key));
    $key->[1] ||= 'alpha';
    unless(ref($key->[1])) {
      $key->[1] = ($key->[1] =~ /^n/i ? 'num'  : 'alpha');
    }
    $key->[2] = ($key->[2] && $key->[2] =~ /^d/i ? 'desc' : 'asc');
  }


  # Precompile a closure to match each key

  if($self->{BufferManagerClass}->can('compile_matches')) {
    $self->{_match_subs} = [
      $self->{BufferManagerClass}->compile_matches($self->{Keys})
    ];
  }


  # Build up a list of options to be passed to buffers/buffer managers

  if($self->{MaxMem}) {
    if(uc($self->{MaxMem}) =~ /^\s*(\d+)(K|M)?$/) {
      $self->{MaxMem} = $1;
      $self->{MaxMem} *= 1024        if($2 and $2 eq 'K');
      $self->{MaxMem} *= 1024 * 1024 if($2 and $2 eq 'M');
    }
    else {
      croak "Illegal value for 'MaxMem': $self->{MaxMem}";
    }
  }

  $self->{BufferOpts} = {
    Keys              => [ @{$self->{Keys}} ],
    _match_subs       => $self->{_match_subs},
    IgnoreCase        => $self->{IgnoreCase},
    NormaliseKeySpace => $self->{NormaliseKeySpace} ||
                         $self->{NormalizeKeySpace},
    KeyFilterSub      => $self->{KeyFilterSub},
    TempDir           => $self->{TempDir},
    MaxMem            => $self->{MaxMem},
  };


  return(bless($self,$class));
}


##############################################################################
# Method: start_document()
#
# Initialise handler structures and propagate event.
#

sub start_document {
  my $self = shift;


  # Track path to current element

  $self->{path_name} = [];
  $self->{path_ns}   = [];
  $self->{prefixes}  = [];
  $self->{depth}     = 0;


  # Initialise pattern matching for record elements

  my @parts = split(/\//, $self->{Record});
  if($parts[0] eq '') {
    $self->{abs_match} = 1;
    shift @parts;
  }
  else {
    $self->{abs_match} = 0;
  }
  $self->{rec_path_name} = [ ];
  $self->{rec_path_ns}   = [ ];
  foreach (@parts) {
    if(/^(?:\{(.*?)\})?(.*)$/) {
      push @{$self->{rec_path_name}}, $2;
      push @{$self->{rec_path_ns}},   $1;
    }
  }
  $self->{required_depth} = @parts;

  $self->SUPER::start_document(@_);
}


##############################################################################
# Method: start_element()
#
# Marshalls events either to the default handler or to a record buffer. 
# Also handles the creation of buffers as record elements are encountered.
# Two extra considerations increase complexity: contiguous character events
# are being merged; and each 'record' element takes it's leading whitespace
# with it.
#

sub start_element {
  my $self    = shift;
  my $element = shift;


  return $self->start_prefixed_element($element) if($self->{passthru});

  # Add this element's details to the end of the list (for recognising records)

  push @{$self->{path_name}}, $element->{LocalName};
  push @{$self->{path_ns}},
    (defined($element->{NamespaceURI}) ? $element->{NamespaceURI} : '');
  $self->{depth}++;


  # Do we have a record buffer open?

  if($self->{buffer}) {
    $self->{record_depth}++;
    $self->send_characters();
    $self->{buffer}->start_element($element);
    return;
  }


  # Any leading (non-whitespace) text?

  if($self->{buffered_text}) {
    $self->flush_buffers();
    $self->send_characters();
  }

  
  # Is this a record?

  if($self->match_record()) {
    
    $self->{record_depth} = 1;

    unless($self->{buffer_manager}) {
      $self->{buffer_manager} = $self->{BufferManagerClass}->new(
	%{$self->{BufferOpts}}
      );
    }

    $self->{buffer} = $self->{buffer_manager}->new_buffer();

    $self->send_characters();
    $self->{buffer}->start_element($element);
    return;
  }


  # Send buffered data and this event to the downstream handler

  $self->flush_buffers();
  $self->send_characters();
  $self->start_prefixed_element($element);
}


##############################################################################
# Method: end_element()
#
# Marshalls events either to the default handler or to a record buffer. 
# Also handles closing the current buffer object as the end of a record is
# encountered.
#

sub end_element {
  my $self    = shift;
  my $element = shift;


  return $self->end_prefixed_element($element) if($self->{passthru});


  pop @{$self->{path_name}};
  pop @{$self->{path_ns}};
  $self->{depth}--;


  # Do we have a record buffer open?
  
  if($self->{buffer}) {
    $self->send_characters();
    $self->{buffer}->end_element($element);
    $self->{record_depth}--;
    if($self->{record_depth} == 0) {
      $self->{buffer_manager}->close_buffer($self->{buffer});
      delete($self->{buffer});
    }
    return;
  }

  # No, then do we have any complete buffered records?
  
  $self->flush_buffers();

  $self->send_characters();
  $self->end_prefixed_element($element);

}


##############################################################################
# Method: characters()
#
# Buffer character events for two reasons:
# - to merge contiguous character data (simplifies pattern matching logic)
# - to enable 'record' elements to take their leading whitespace with them
#

sub characters {
  my $self = shift;
  my $char = shift;

  return $self->SUPER::characters($char) if($self->{passthru});

  unless(exists($self->{char_buffer})) {
    $self->{char_buffer} = '';
    $self->{buffered_text} = 0;
  }
  $self->{char_buffer} .= $char->{Data};
  $self->{buffered_text} |= ($char->{Data} =~ /\S/); 
}


##############################################################################
# Method: ignorable_whitespace()
#
# Discard ignorable whitespace if required, otherwise send it on as 
# character events.
#
# Yes, this is a dirty hack, but it's getting late and I haven't got a
# parser that generates them anyway.
#

sub ignorable_whitespace {
  my $self = shift;
  my $char = shift;

  $self->characters($char) unless($self->{SkipIgnorableWS});
}


##############################################################################
# Method: start_prefix_mapping()
# Method: end_prefix_mapping()
#
# Suppress these events as they need to remain synchronised with the
# start/end_element events (which may be re-ordered).  Replacement events are
# generated by start/end_prefixed_element().
#

sub start_prefix_mapping { }
sub end_prefix_mapping   { }


##############################################################################
# Method: start_prefixed_element()
#
# Sends a start_element() event to the downstream handler, but re-generates
# start_prefix_mapping() events first.
#

sub start_prefixed_element {
  my $self = shift;
  my $elem = shift;

  my @prefixes;
  foreach my $attr (values %{$elem->{Attributes}}) {
    if($attr->{Name}  and  $attr->{Name} eq 'xmlns') {
      unshift @prefixes, '', $attr->{Value};
    }
    elsif($attr->{Prefix}  and  $attr->{Prefix} eq 'xmlns') {
      push @prefixes, $attr->{LocalName}, $attr->{Value};
    }
  }
  
  if(@prefixes) {
    push @{$self->{prefixes}}, [ @prefixes ];
    while(@prefixes) {
      my $prefix = shift @prefixes;
      my $uri    = shift @prefixes;
      $self->SUPER::start_prefix_mapping({
	Prefix       => $prefix,
	NamespaceURI => $uri,
      });
    }
  }
  else {
    push @{$self->{prefixes}}, undef;
  }
  
  $self->SUPER::start_element($elem);
}


##############################################################################
# Method: end_prefixed_element()
#
# Sends an end_element() event to the downstream handler, and follows it with
# re-generated end_prefix_mapping() events.
#

sub end_prefixed_element {
  my $self = shift;
  my $elem = shift;

  $self->SUPER::end_element($elem);

  my $prefixes = pop @{$self->{prefixes}};

  if($prefixes) {
    while(@$prefixes) {
      my $prefix = shift @$prefixes;
      my $uri    = shift @$prefixes;
      $self->SUPER::end_prefix_mapping({
	Prefix       => $prefix,
	NamespaceURI => $uri,
      });
    }
  }

}


##############################################################################
# Method: comment()
#
# Send comments to buffer if we have one open, otherwise flush any buffered
# records before propagating event.
#

sub comment {
  my $self    = shift;
  my $comment = shift;

  return $self->SUPER::comment($comment) if($self->{passthru});

  if($self->{buffer}) {
    $self->send_characters();
    $self->{buffer}->comment($comment);
    return;
  }

  $self->flush_buffers();
  $self->send_characters();
  $self->SUPER::comment($comment);
}


##############################################################################
# Method: processing_instruction()
#
# Send PIs to downstream handler but flush buffered records & text first.
#

sub processing_instruction {
  my $self = shift;
  my $pi   = shift;

  return $self->SUPER::processing_instruction($pi) if($self->{passthru});

  if($self->{buffer}) {
    $self->send_characters();
    $self->{buffer}->processing_instruction($pi);
    return;
  }

  $self->flush_buffers();
  $self->send_characters();
  $self->SUPER::processing_instruction($pi);
}


##############################################################################
# Method: send_characters()
#
# Contiguous character events are concatenated into a buffer.  This routine
# sends the buffer contents to the open buffer if there is one, or the
# downstream handler otherwise.
#

sub send_characters {
  my $self    = shift;

  return unless(exists $self->{char_buffer});
  if($self->{buffer}) {
    $self->{buffer}->characters({Data => $self->{char_buffer}});
  }
  else {
    $self->SUPER::characters({Data => $self->{char_buffer}});
  }
  delete($self->{char_buffer});
  delete($self->{buffered_text});
}


##############################################################################
# Method: flush_buffers()
#
# If there are any records buffered, sends them to the downstream handler.
#

sub flush_buffers {
  my $self    = shift;

  if($self->{buffer_manager}) {
    $self->{passthru} = 1;
    $self->{buffer_manager}->to_sax($self);
    $self->{passthru} = 0;
    delete($self->{buffer_manager});
  }
}


##############################################################################
# Method: match_record()
#
# Returns true if the path to the current element matches the 'Record' option
# passed to the constructor.
#

sub match_record {
  my $self = shift;


  if($self->{abs_match}) {
    return if($self->{depth} != $self->{required_depth});
  }
  else {
    return if($self->{depth} < $self->{required_depth});
  }

  foreach my $i (1..$self->{required_depth}) {
    return unless($self->{path_name}->[-$i] eq $self->{rec_path_name}->[-$i]);
    if(defined($self->{rec_path_ns}->[-$i])) {
      return unless($self->{path_ns}->[-$i] eq $self->{rec_path_ns}->[-$i]);
    }
  }

  return(1);
}


1;
__END__

=head1 NAME

XML::Filter::Sort - SAX filter for sorting elements in XML

=head1 SYNOPSIS

  use XML::Filter::Sort;
  use XML::SAX::Machines qw( :all );

  my $sorter = XML::Filter::Sort->new(
    Record  => 'person',
    Keys    => [
	         [ 'lastname',  'alpha', 'asc' ],
	         [ 'firstname', 'alpha', 'asc' ],
		 [ '@age',      'num',   'desc']
               ],
  );

  my $filter = Pipeline( $sorter => \*STDOUT );

  $filter->parse_file(\*STDIN);

Or from the command line:

  xmlsort

=head1 DESCRIPTION

This module is a SAX filter for sorting 'records' in XML documents (including
documents larger than available memory).  The C<xmlsort> utility which is
included with this distribution can be used to sort an XML file from the
command line without writing Perl code (see C<perldoc xmlsort>).

=head1 EXAMPLES

These examples assume that you will create an XML::Filter::Sort object and use
it in a SAX::Machines pipeline (as in the synopsis above).  Of course you could
use the object directly by hooking up to a SAX generator and a SAX handler but
such details are omitted from the sample code.

When you create an XML::Filter::Sort object (with the C<new()> method), you
must use the 'Record' option to identify which elements you want sorted.  The
simplest way to do this is to simply use the element name, eg:

  my $sorter = XML::Filter::Sort->new( Record  => 'colour' );

Which could be used to transform this XML:

  <options>
    <colour>red</colour>
    <colour>green</colour>
    <colour>blue</colour>
  <options>

to this:

  <options>
    <colour>blue</colour>
    <colour>green</colour>
    <colour>red</colour>
  </options>

You can define a more specific path to the record by adding a prefix of element
names separated by forward slashes, eg:

  my $sorter = XML::Filter::Sort->new( Record  => 'hair/colour' );

which would only sort <colour> elements contained directly within a <hair>
element (and would therefore leave our sample document above unchanged).  A
path which starts with a slash is an 'absolute' path and must specify all 
intervening elements from the root element to the record elements.

A record element may contain other elements.  The order of the record elements
may be changed by the sorting process but the order of any child elements
within them will not.

The default sort uses the full text of each 'record' element and uses an
alphabetic comparison.  You can use the 'Keys' option to specify a list of
elements within each record whose text content should be used as sort keys.
You can also use this option to specify whether the keys should be compared
alphabetically or numerically and whether the resulting order should be
ascending or descending, eg:

  my $sorter = XML::Filter::Sort->new(
    Record  => 'person',
    Keys    => [
	         [ 'lastname',  'alpha', 'asc'  ],
	         [ 'firstname', 'alpha', 'asc'  ],
	         [ '@age',      'alpha', 'desc' ],
               ]
  );

Given this record ...

    <person age='35'>
      <firstname>Aardvark</firstname>
      <lastname>Zebedee</lastname>
    </person>

The above code would use 'Zebedee' as the first (primary) sort key, 'Aardvark'
as the second sort key and the number 35 as the third sort key.  In this case,
records with the same first and last name would be sorted from oldest to
youngest.

As with the 'record' path, it is possible to specify a path to the sort key
elements (or attributes).  To make a path relative to the record element
itself, use './' at the start of the path.

=head1 OPTIONS

=over 4

=item Record => 'path string'

A simple path string defining which elements should be treated as 'records' to
be sorted (see L<"PATH SYNTAX">).  Elements which do not match this path will
not be altered by the filter.  Elements which do match this path will be
re-ordered depending on their contents and the value of the Keys option.

When a record element is re-ordered, it takes its leading whitespace with it.

Only lists of contiguous record elements will be sorted.  A list of records
which has a 'foreign body' (a non-record element, non-whitespace text, a
comment or a processing instruction) between two elements will be treated as
two separate lists and each will be sorted in isolation of the other.

=item Keys => [ [ 'path string', comparator, order ], ... ]

=item Keys => 'delimited string'

This option specifies which parts of the records should be used as sort keys.
The first form uses a list-of-lists syntax.  Each key is defined using a list
of three elements:

=over 4

=item 1

The 'path string' defines the path to an element or an attribute whose text
contents should be used as the value of the sort key (see L<"PATH SYNTAX">).

=item 2

The 'comparator' defines how these values should be compared.  This can be the
string 'alpha' for alphabetic, the string 'num' for numeric or a reference to a
subroutine taking two parameters and returning -1, 0 or 1 (similar to the
standard Perl sort function but without the $a, $b magic).

This item is optional and defaults to 'alpha'.

=item 3

The 'order' should be 'asc' for ascending or 'desc' for descending and if
omitted, defaults to 'asc'.

=back

You may prefer to define the Keys using a delimited string rather than a
list of lists.  Keys in the string should be separated by either newlines or
semicolons and the components of a key should be separated by whitespace or
commas.  It is not possible to define a subroutine reference comparator using
the string syntax.

=item IgnoreCase => 1

Enabling this option will make sort comparisions case-insensitive (rather than
the default case-sensitive).

=item NormaliseKeySpace => 1

The sort key values for each record will be the text content of the child
elements specified using the Keys option (above).  If you enable this option,
leading and trailing whitespace will be stripped from the keys and each
internal run of spaces will be collapsed to a single space.  The default 
value for this option is off for efficiency.

Note: The contents of the record are not affected by this setting - merely
the copy of the data that is used in the sort comparisons.

=item KeyFilterSub => coderef

You can also supply your own custom 'fix-ups' by passing this option a
reference to a subroutine.  The subroutine will be called once for each record
and will be passed a list of the key values for the record.  The routine must
return the same number of elements each time it is called, but this may be less
than the number of values passed to it.  You might use this option to combine
multiple key values into one (eg: using sprintf).

Note: You can enable both the NormaliseKeySpace and the KeyFilterSub options -
space normalisation will occur first.

=item TempDir => 'directory path'

This option serves two purposes: it enables disk buffering rather than the
default memory buffering and it allows you to specify where on disk the data
should be buffered.  Disk buffering will be slower than memory buffering, so
don't ask for it if you don't need it.  For more details, see
L<"IMPLEMENTATION">.

Note: It is safe to specify the same temporary directory path for multiple
instances since each will create a uniquely named subdirectory (and clean it
up afterwards).

=item MaxMem => bytes

The disk buffering mode actually sorts chunks of records in memory before
saving them to disk.  The default chunk size is 10 megabytes.  You can use this
option to specify an alternative chunk size (in bytes) which is more attuned to
your available resources (more is better).  A suffix of 'K' or 'M' is
recognised as kilobytes or megabytes respectively.

If you have not enabled disk buffering (using 'TempDir'), the MaxMem option has
no effect.  Attempting to sort a large document using only memory buffering
may result in Perl dying with an 'out of memory' error.

=item SkipIgnorableWS

If your SAX parser can do validation and generates ignorable_whitespace()
events, you can enable this option to discard these events.  If you leave this
option at it's default value (implying you want the whitespace), the events
will be translated to characters() events.

=back

=head1 PATH SYNTAX

A simple element path syntax is used in two places:

=over 4

=item 1

with the 'Record' option to define which elements should be sorted

=item 2

with the 'Keys' option to define which parts of each record should be used
as sort keys.

=back

In each case you can use a just an element name, or a list of element names
separated by forward slashes.  eg:

  Record => 'ul/li',
  Keys   => 'name'

If a 'Record' path begins with a '/' then it will be anchored at the document
root.  If a 'Keys' path begins with './' then it is anchored at the current
record element.  Unanchored paths can match at any level.

A 'Keys' path can include an attribute name prefixed with an '@' symbol, eg:

  Keys   => './@href'

Each element or attribute name can include a namespace URI prefix in curly
braces, eg:

  Record => '{http://www.w3.org/1999/xhtml}li'

If you do not include a namespace prefix, all elements with the specified
name will be matched, regardless of any namespace URI association they might
have.

If you include an empty namespace prefix (eg: C<'{}li'>) then only records
which do not have a namespace association will be matched.

=head1 IMPLEMENTATION

In order to arrange records into sorted order, this module uses buffering.  It
does not need to buffer the whole document, but for any sequence of records
within a document, all records must be buffered.  Unless you specify otherwise,
the records will be buffered in memory.  The memory requirements are similar to
DOM implementations - 10 to 50 times the character count of the source XML.  If
your documents are so large that you would not process them with a DOM parser
then you should enable disk buffering.

If you enable disk buffering, sequences of records will be assembled into
'chunks' of approximately 10 megabytes (this value is configurable).  Each
chunk will be sorted and saved to disk.  At the end of the record sequence, all
the sorted chunks will be merged and written out as SAX events.

The memory buffering mode represents each record an a
B<XML::Filter::Sort::Buffer> object and uses B<XML::Filter::Sort::BufferMgr>
objects to manage the buffers.  For details of the internals, see L<XML::Filter::Sort::BufferMgr>.

The disk buffering mode represents each record an a
B<XML::Filter::Sort::DiskBuffer> object and uses
B<XML::Filter::Sort::DiskBufferMgr> objects to manage the buffers.  For details
of the internals, see L<XML::Filter::Sort::DiskBufferMgr>.


=head1 BUGS

ignorable_whitespace() events shouldn't be translated to normal characters()
events - perhaps in a later release they won't be.

=head1 SEE ALSO

B<XML::Filter::Sort> requires L<XML::SAX::Base> and plays nicely with
L<XML::SAX::Machines>.


=head1 COPYRIGHT 

Copyright 2002-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

