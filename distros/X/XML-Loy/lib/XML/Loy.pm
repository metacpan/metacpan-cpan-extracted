package XML::Loy;
use Mojo::ByteStream 'b';
use Mojo::Loader qw/load_class/;
use Carp qw/croak carp/;
use Scalar::Util qw/blessed weaken/;
use Mojo::Base 'Mojo::DOM';

our $VERSION = '0.48';

sub DESTROY;

# TODO:
#   - Support Mojolicious version > 7.77
#     - "ns|*" namespace selector
#
#  - Add ->clone
#    (Maybe via JSON serialisation of ->tree or using Storable or Dumper)
#
#   Maybe necessary: *AUTOLOAD = \&XML::Loy::AUTOLOAD;
#
# - sub try_further { };
#     # usage:
#     sub author {
#       return $autor or $self->try_further;
#     };
#
#  - ALERT!
#      Do not allow for namespace islands
#      Search $obj->find('* *[xmlns]') and change prefixing
#      After ->SUPER::new;
#      Or:
#      Do allow for namespace islands and check for the
#      namespace to add instead of the package name before
#      prefixing.
#
# - set() should really try to overwrite.
#
# - add() with -before => '' and -after => ''
#   - maybe possible to save to element
#   - Maybe with small changes a change to the object
#     (encoding, xml etc.) can be done
#
# - closest() (jQuery)

our @CARP_NOT;

# Import routine, run when calling the class properly
sub import {
  my $class = shift;

  return unless my $flag = shift;

  return unless $flag =~ /^-?(?i:base|with)$/;

  # Allow for manipulating the symbol table
  no strict 'refs';
  no warnings 'once';

  # The caller is the calling (inheriting) class
  my $caller = caller;
  push @{"${caller}::ISA"}, __PACKAGE__;

  if (@_) {

    # Get class variables
    my %param = @_;

    # Set class variables
    foreach (qw/namespace prefix mime/) {
      if (exists $param{$_}) {
        ${ "${caller}::" . uc $_ } = delete $param{$_};
      };
    };

    # Set class hook
    if (exists $param{on_init}) {
      *{"${caller}::ON_INIT"} = delete $param{on_init};
    };
  };

  # Make inheriting classes strict and modern
  strict->import;
  warnings->import;
  utf8->import;
  feature->import(':5.10');
};


# Return class variables
{
  no strict 'refs';
  sub _namespace { ${"${_[0]}::NAMESPACE"}   || '' };
  sub _prefix    { ${"${_[0]}::PREFIX"}      || '' };
  sub mime       {
    ${ (blessed $_[0] || $_[0]) . '::MIME'}  || 'application/xml'
  };
  sub _on_init   {
    my $class = shift;
    my $self = $class;

    # Run object method
    if (blessed $class) {
      $class = blessed $class;
    }

    # Run class method
    else {
      $self = shift;
    };

    # Run init hook
    if ($class->can('ON_INIT')) {
      *{"${class}::ON_INIT"}->($self) ;
    };
  };
};


# Construct new XML::Loy object
sub new {
  my $class = shift;

  my $self;

  # Create from parent class
  # Empty constructor
  unless ($_[0]) {
    $self = $class->SUPER::new->xml(1);
  }

  # XML::Loy object
  elsif (ref $_[0]) {
    $self = $class->SUPER::new(@_)->xml(1);
  }

  # XML string
  elsif (index($_[0],'<') >= 0 || index($_[0],' ') >= 0) {
    $self = $class->SUPER::new->xml(1)->parse(@_);
  }

  # Create a new node
  else {
    my $name = shift;
    my $att  = ref( $_[0] ) eq 'HASH' ? shift : +{};
    my ($text, $comment) = @_;

    $att->{'xmlns:loy'} = 'http://sojolicio.us/ns/xml-loy';

    # Transform special attributes
    _special_attributes($att) if $att;

    # Create root
    my $tree = [
      'root',
      [ pi => 'xml version="1.0" encoding="UTF-8" standalone="yes"']
    ];

    # Add comment if given
    push(@$tree, [ comment => $comment ]) if $comment;

    # Create Tag element
    my $element = [ tag => $name, $att, $tree ];

    # Add element
    push(@$tree, $element);

    # Add text if given
    push(@$element, [ text => $text ]) if defined $text;

    # Create root element by parent class
    $self = $class->SUPER::new->xml(1);

    # Add newly created tree
    $self->tree($tree);

    # The class is derived
    if ($class ne __PACKAGE__) {

      # Set namespace if given
      if (my $ns = $class->_namespace) {
	$att->{xmlns} = $ns;
      };

    };
  };

  # Start init hook
  $self->_on_init;

  # Return root node
  return $self;
};


# Append a new child node to the XML Node
sub add {
  my $self = shift;

  # Store tag
  my $tag = $_[0];

  # If node is root, use first element
  if (!$self->parent &&
	ref($self->tree->[1]) &&
	  ref($self->tree->[1]) eq 'ARRAY' &&
	    $self->tree->[1]->[0] eq 'pi') {
    $self = $self->at('*');
  };

  # Add element
  my $element = $self->_add_clean(@_) or return;

  my $tree = $element->tree;

  # Prepend with no prefix
  if (index($tag, '-') == 0) {
    $tree->[1] = substr($tag, 1);
    return $element;
  };

  # Element is no tag
  return $element unless $tree->[0] eq 'tag';

  # Prepend prefix if necessary
  my $caller = caller;
  my $class  = ref $self;

  # Caller and class are not the same
  if ($caller ne $class && $caller->can('_prefix')) {
    if ((my $prefix = $caller->_prefix) && $caller->_namespace) {
      $element->tree->[1] = "${prefix}:$tag";
    };
  };

  # Return element
  return $element;
};


# Append a child only once to the XML node.
sub set {
  my $self = shift;

  my $tag;

  # If node is root, use first element
  if (!$self->parent && $self->tree->[1]->[0] eq 'pi') {
    $self = $self->at('*');
  };

  # Get tag from document object
  if (ref $_[0]) {
    $tag = $_[0]->at('*')->tag;
  }

  # Get tag
  else {

    # Store tag
    $tag = shift;

    # No prefix
    if (index($tag, '-') == 0) {
      $tag = substr($tag, 1);
    }

    # Maybe prefix
    else {
      # Prepend prefix if necessary
      my $caller = caller;
      my $class  = ref $self;

      # Caller and class are not the same
      if ($caller ne $class && $caller->can('_prefix')) {
	if ((my $prefix = $caller->_prefix) && $caller->_namespace) {
	  $tag = "${prefix}:$tag";
	};
      };
    };
  };

  my $att = $self->tree->[2];

  # Introduce attribute 'once'
  $att->{'loy:once'} //= '';

  # Check if set to once
  if (index($att->{'loy:once'}, "($tag)") >= 0) {

    # Todo: Maybe escaping - check in extensions
    $self->children("$tag")->map('remove');
  }

  # Set if not already set
  else {
    $att->{'loy:once'} .= "($tag)";
  };

  # Add a ref, not the tag
  unshift(@_, $tag) unless blessed $_[0];

  # Add element (Maybe prefixed)
  return $self->_add_clean(@_);
};


# Children of the node
sub children {
  my ($self, $type) = @_;

  # This method is a modified version of
  # the children method of Mojo::DOM
  # It works as written in the documentation,
  # but is also aware of namespace prefixes.

  # If node is root, use first element
  if (!$self->parent &&
	ref($self->tree->[1]) &&
	  ref($self->tree->[1]) eq 'ARRAY' &&
	    $self->tree->[1]->[0] eq 'pi') {
    $self = $self->at('*');
  };

  my @children;
  my $xml     = $self->xml;
  my $tree    = $self->tree;
  my $type_l  = $type ? length $type : 0;
  for my $e (@$tree[($tree->[0] eq 'root' ? 1 : 4) .. $#$tree]) {

    # Make sure child is the right type
    next unless $e->[0] eq 'tag';

    # Type is given
    if (defined $type) {

      # Type is already prefixed or element is not prefixed
      if (index($type, ':') > 0 || index($e->[1], ':') < 0) {
	next if $e->[1] ne $type;
      }

      # Check, if type is valid, and ignore prefixes, cause tag is prefixed
      elsif (index($e->[1], ':') > 0) {
	next if substr($e->[1], (index($e->[1], ':') + 1)) ne $type;

      };
    };

    push(@children, $self->new->tree($e)->xml($xml));
  }

  # Create new Mojo::Collection
  return Mojo::Collection->new( @children );
};


# Append a new child node to the XML Node
sub _add_clean {
  my $self = shift;

  # Node is a node object
  if (ref $_[0]) {

    # Serialize node
    my $node = $self->SUPER::new->xml(1)->tree( shift->tree );

    # Get root attributes
    my $root_attr = $node->_root_element->[2];

    # Push namespaces to new root
    foreach ( grep( index($_, 'xmlns:') == 0, keys %$root_attr ) ) {

      # Strip xmlns prefix
      $_ = substr($_, 6);

      # Add namespace
      $self->namespace( $_ => delete $root_attr->{ "xmlns:$_" } );
    };

    # Delete namespace information, if already set
    if (exists $root_attr->{xmlns}) {

      # Namespace information can be deleted
      if (my $ns = $self->namespace) {
	delete $root_attr->{xmlns} if $root_attr->{xmlns} eq $ns;
      };
    };

    # Get root of parent node
    my $base_root_attr = $self->_root_element->[2];

    # Copy extensions
    if (exists $root_attr->{'loy:ext'}) {
      my $ext = $base_root_attr->{'loy:ext'};

      $base_root_attr->{'loy:ext'} =
	join('; ', $ext, split(/;\s/, delete $root_attr->{'loy:ext'}));
    };


    # Delete pi from node
    my $sec = $node->tree->[1];
    if (ref $sec eq 'ARRAY' && $sec->[0] eq 'pi') {
      splice( @{ $node->tree }, 1,1 );
    };

    # Append new node
    $self->append_content($node);

    # Return first child
    return $self->children->[-1];
  }

  # Node is a string
  else {
    my $name = shift;

    # Pretty sloppy check for valid names
    return unless $name =~ m!^-?[^\s<>]+$!;

    my $att  = shift if ref( $_[0] ) eq 'HASH';
    my ($text, $comment) = @_;

    # Node content with text
    my $string = "<$name";

    if (defined $text) {
      $string .= '>' . b($text)->trim->xml_escape . "</$name>";
    }

    # Empty element
    else {
      $string .= ' />';
    };

    # Append new node
    $self->append_content( $string );

    # Get first child
    my $node = $self->children->[-1];

    # Attributes were given
    if ($att) {

      # Transform special attributes
      _special_attributes($att);

      # Add attributes to node
      $node->attr($att);
    };

    # Add comment
    $node->comment($comment) if $comment;

    return $node;
  };
};


# Transform special attributes
sub _special_attributes {
  my $att = shift;

  foreach ( grep { index($_, '-') == 0 } keys %$att ) {

    # Set special attribute
    $att->{'loy:' . substr($_, 1) } = lc delete $att->{$_};
  };
};


# Prepend a comment to the XML node
sub comment {
  my $self = shift;

  my $parent;

  # If node is root, use first element
  return $self unless $parent = $self->parent;

  # Find previous sibling
  my $previous;

  # Find previous node
  for my $e (@{$parent->tree}) {
    last if $e eq $self->tree;
    $previous = $e;
  };

  # Trim and encode comment text
  my $comment_text = b( shift )->trim->xml_escape;

  # Add to previous comment
  if ($previous && $previous->[0] eq 'comment') {
    $previous->[1] .= '; ' . $comment_text;
  }

  # Create new comment node
  else {
    $self->prepend("<!--$comment_text-->");
  };

  # Return node
  return $self;
};


# Add extension to document
sub extension {
  my $self = shift;

  # Get root element
  my $root = $self->_root_element;

  # No root to associate extension to
  unless ($root) {
    carp 'There is no document to associate the extension with';
    return;
  };

  # Get ext string
  my @ext = split(/;\s/, $root->[2]->{'loy:ext'} || '');

  return @ext unless $_[0];

  # New Loader
  # my $loader = Mojo::Loader->new;

  # Try all given extension names
  while (my $ext = shift( @_ )) {

    next if grep { $ext eq $_ } @ext;

    # Default 'XML::Loy::' prefix
    if (index($ext, '-') == 0) {
      $ext =~ s/^-/XML::Loy::/;
    };

    # Unable to load extension
    if (my $e = load_class $ext) {
      carp "Exception: $e"  if ref $e;
      carp qq{Unable to load extension "$ext"};
      next;
    };

    # Add extension to extensions list
    push(@ext, $ext);

    # Start init hook
    $ext->_on_init($self);

    if ((my $n_ns = $ext->_namespace) &&
	  (my $n_pref = $ext->_prefix)) {
      $root->[2]->{"xmlns:$n_pref"} = $n_ns;
    };
  };

  # Save extension list as attribute
  $root->[2]->{'loy:ext'} = join('; ', @ext);

  return $self;
};


# Get or add namespace to root
sub namespace {
  my $self = shift;

  # Get namespace
  unless ($_[0]) {
    return $self->SUPER::namespace || undef;
  };

  my $ns = pop;
  my $prefix = shift;

  # Get root element
  my $root = $self->_root_element;

  # No warning, but not able to set
  return unless $root;

  # Save namespace as attribute
  $root->[2]->{'xmlns' . ($prefix ? ":$prefix" : '')} = $ns;
  return $prefix;
};


# As another object
sub as {
  my $self = shift;

  # Base object
  my $base = shift;

  # New Loader
  # my $loader = Mojo::Loader->new;

  # Default 'XML::Loy::' prefix
  if (index($base, '-') == 0) {
    for ($base) {

      # Was Loy prefix
      s/^-Loy$/XML::Loy/;
      s/^-/XML::Loy::/;
    };
  };

  # Unable to load extension
  if (my $e = load_class $base) {
    carp "Exception: $e"  if ref $e;
    carp qq{Unable to load base class "$e"};
    return;
  };

  # Create new base document
  my $xml = $base->new( $self->to_string );

  # Start init hook
  $xml->_on_init;

  # Set base namespace
  if ($base->_namespace) {
    $xml->namespace( $base->_namespace );
  };

  # Delete extension information
  $xml->find('*[loy\:ext]')->each(
    sub {
      delete $_->{attrs}->{'loy:ext'}
    }
  );

  # Add extensions
  $xml->extension( @_ );

  # Return XML document
  return $xml;
};


# Render as pretty xml
sub to_pretty_xml {
  my $self = shift;
  return _render_pretty( shift // 0, $self->tree);
};


# Render subtrees with pretty printing
sub _render_pretty {
  my $i    = shift; # Indentation
  my $tree = shift;

  my $e = $tree->[0];

  # No element
  croak('No element') and return unless $e;

  # Element is tag
  if ($e eq 'tag') {
    my $subtree =
      [
	@{ $tree }[ 0 .. 2 ],
	[
	  @{ $tree }[ 4 .. $#$tree ]
	]
      ];

    return _element($i, $subtree);
  }

  # Element is text
  elsif ($e eq 'text') {

    my $escaped = $tree->[1];

    for ($escaped) {
      next unless $_;

      # Escape and trim whitespaces from both ends
      $_ = b($_)->xml_escape->trim;
    };

    return $escaped;
  }

  # Element is comment
  elsif ($e eq 'comment') {

    # Padding for every line
    my $p = '  ' x $i;
    my $comment = join "\n$p     ", split(/;\s+/, $tree->[1]);

    return "\n" . ('  ' x $i) . "<!-- $comment -->\n";

  }

  # Element is processing instruction
  elsif ($e eq 'pi') {
    return ('  ' x $i) . '<?' . $tree->[1] . "?>\n";

  }

  # Element is root
  elsif ($e eq 'root') {

    my $content;

    # Pretty print the content
    $content .= _render_pretty( $i, $tree->[ $_ ] ) for 1 .. $#$tree;

    return $content;
  };
};


# Render element with pretty printing
sub _element {
  my $i = shift;
  my ($type, $qname, $attr, $child) = @{ shift() };

  # Is the qname valid?
  croak "$qname is no valid QName"
    unless $qname =~ /^(?:[a-zA-Z_]+:)?[^\s]+$/;

  # Start start tag
  my $content = ('  ' x $i) . "<$qname";

  # Add attributes
  $content .= _attr(('  ' x $i). (' ' x ( length($qname) + 2)), $attr);

  # Has the element a child?
  if ($child->[0]) {

    # Close start tag
    $content .= '>';

    # There is only a textual child - no indentation
    if (!$child->[1] && ($child->[0] && $child->[0]->[0] eq 'text')) {

      # Special content treatment
      if (exists $attr->{'loy:type'}) {

	# With base64 indentation
	if ($attr->{'loy:type'} =~ /^armour(?::(\d+))?$/i) {
	  my $n = $1 || 60;

	  my $string = $child->[0]->[1];

	  # Delete whitespace
	  $string =~ tr{\t-\x0d }{}d;

	  # Introduce newlines after n characters
	  $content .= "\n" . ('  ' x ($i + 1));
	  $content .= join  "\n" . ( '  ' x ($i + 1) ), (unpack "(A$n)*", $string );
	  $content .= "\n" . ('  ' x $i);
	}

	# No special treatment
	else {

	  # Escape
	  $content .= b($child->[0]->[1])->trim->xml_escape;
	};
      }

      # No special content treatment indentation
      else {

	# Escape
	$content .= b($child->[0]->[1])->trim->xml_escape;
      };
    }

    # Treat children special
    elsif (exists $attr->{'loy:type'}) {

      # Raw
      if ($attr->{'loy:type'} eq 'raw') {

	foreach (@$child) {

	  # Create new dom object
	  my $dom = __PACKAGE__->new;
	  $dom->xml(1);

	  # Print without prettifying
	  $content .= $dom->tree($_)->to_string;
	};
      }

      # Todo:
      elsif ($attr->{'loy:type'} eq 'escape') {
	$content .= "\n";

	foreach (@$child) {

	  # Create new dom object
	  my $dom = __PACKAGE__->new;
	  $dom->xml(1);

	  # Pretty print
	  my $string = $dom->tree($_)->to_pretty_xml($i + 1);

	  # Encode
	  $content .= b($string)->xml_escape;
	};

	# Correct Indent
	$content .= '  ' x $i;
      };
    }

    # There are a couple of children
    else {

      my $offset = 0;

      # First element is unformatted textual
      if (!exists $attr->{'loy:type'} &&
	    $child->[0] &&
	      $child->[0]->[0] eq 'text') {

	# Append directly to the last tag
	$content .= b($child->[0]->[1])->trim->xml_escape;
	$offset = 1;
      };

      # Start on a new line
      $content .= "\n";

      # Loop through all child elements
      foreach (@{$child}[ $offset .. $#$child ]) {

	# Render next element
	$content .= _render_pretty( $i + 1, $_ );
      };

      # Correct Indent
      $content .= ('  ' x $i);
    };

    # End Tag
    $content .= "</$qname>\n";
  }

  # No child - close start element as empty tag
  else {
    $content .= " />\n";
  };

  # Return content
  return $content;
};


# Render attributes with pretty printing
sub _attr {
  my $indent_space = shift;
  my %attr = %{$_[0]};

  # Delete special and namespace attributes
  my @special = grep {
    $_ eq 'xmlns:loy' || index($_, 'loy:') == 0
  } keys %attr;

  # Delete special attributes
  delete $attr{$_} foreach @special;

  # Prepare attribute values
  $_ = b($_)->xml_escape->quote foreach values %attr;

  # Return indented attribute string
  if (keys %attr) {
    return ' ' .
      join "\n$indent_space", map { "$_=" . $attr{$_} } sort keys %attr;
  };

  # Return nothing
  return '';
};


# Get root element (not as an object)
sub _root_element {
  my $self = shift;

  # Todo: Optimize! Often called!

  # Find root (Based on Mojo::DOM::root)
  my $root = $self->tree or return;
  my $tag;

  # Root is root node
  if ($root->[0] eq 'root') {
    my $i = 1;

    # Search for the first tag
    $i++ while $root->[$i] && $root->[$i]->[0] ne 'tag';

    # Tag found
    $tag = $root->[$i];
  }

  # Root is a tag
  else {

    # Tag found
    while ($root->[0] eq 'tag') {
      $tag = $root;

      last unless my $parent = $root->[3];

      $root = $parent;
    };
  };

  # Return root element
  return $tag;
};


# Autoload for extensions
sub AUTOLOAD {
  my $self = shift;
  my @param = @_;

  # Split parameter
  my ($package, $method) = our $AUTOLOAD =~ /^([\w\:]+)\:\:(\w+)$/;

  # Choose root element
  my $root = $self->_root_element;

  # Get extension array
  my @ext = $self->extension;

  {
    no strict 'refs';

    foreach (@ext) {

      # Method does not exist in extension
      next unless $_->can($method);

      # Release method
      return *{ "${_}::$method" }->($self, @param);
    };
  };

  my $errstr = qq{Can't locate "${method}" in "$package"};
  if (@ext) {
    $errstr .= ' with extension' . (@ext > 1 ? 's' : '');
    $errstr .= ' "' . join('", "', @ext) . '"';
  };

  carp $errstr and return;
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

XML::Loy - Extensible XML Reader and Writer


=head1 SYNOPSIS

  use XML::Loy;

  # Create new document with root node
  my $xml = XML::Loy->new('env');

  # Add elements to the document
  my $header = $xml->add('header');

  # Nest elements
  $header->add('greetings')->add(title => 'Hello!');

  # Append elements with attributes and textual data
  $xml->add(body => { date => 'today' })->add(p => "That's all!");

  # Use CSS3 selectors for element traversal
  $xml->at('title')->attr(style => 'color: red');

  # Attach comments
  $xml->at('greetings')->comment('My Greeting');

  # Print with pretty indentation
  print $xml->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <env>
  #   <header>
  #
  #       <!-- My Greeting -->
  #       <greetings>
  #         <title style="color: red">Hello!</title>
  #       </greetings>
  #     </header>
  #     <body date="today">
  #       <p>That&#39;s all!</p>
  #     </body>
  #   </env>


=head1 DESCRIPTION

L<XML::Loy> allows for the simple creation
of small serialized XML documents with
various namespaces.
It focuses on simplicity and extensibility,
while giving you the full power of L<Mojo::DOM>.


=head1 METHODS

L<XML::Loy> inherits all explicit methods from
L<Mojo::DOM> and implements the following new ones.


=head2 new

  my $xml = XML::Loy->new(<<'EOF');
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <entry>
    <fun>Yeah!</fun>
  <entry>
  EOF

  $xml = XML::Loy->new('Document');
  $xml = XML::Loy->new(Document => { foo => 'bar' });
  my $xml_new = $xml->new(Document => {id => 'new'} => 'My Content');

Constructs a new L<XML::Loy> document.
Accepts either all parameters supported by L<Mojo::DOM> or
all parameters supported by L<add|/add>.


=head2 add

  my $xml = XML::Loy->new('Document');

  # Add an empty element
  $xml->add('Element');

  # Add elements with attributes
  my $elem = $xml->add(Element => { type => 'text/plain' });

  # Add nested elements with textual content
  $elem->add(Child => "I'm a child element");

  # Add elements with attributes, textual content, and a comment
  $xml->add(p => { id => 'id_4' }, 'Hello!', 'My Comment!');

  # Add elements with rules for pretty printing
  $xml->add(Data => { -type => 'armour' }, 'PdGzjvj..');

  # Add XML::Loy objects
  $elem = $xml->new(Element => 'Hello World!');
  $xml->add($elem);

Adds a new element to a L<XML::Loy> document, either
as another L<XML::Loy> object or newly defined.
Returns the root node of the added L<XML::Loy>
document.

Parameters to define elements are a tag name,
followed by an optional hash reference
including all attributes of the XML element,
an optional textual content,
and an optional comment on the element
(if the comment should be introduced to an empty element,
text content has to be C<undef>).

For giving directives for rendering element content
with L<pretty printing|/to_pretty_xml>,
a special C<-type> attribute can be defined:

=over 2

=item

C<escape>

XML escape the content of the node.

  my $xml = XML::Loy->new('feed');
  my $html = $xml->add(html => { -type => 'escape' });
  $html->add(h1 => { style => 'color: red' } => 'I start blogging!');
  $html->add(p => 'What a great idea!')->comment('First post');

  print $xml->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <feed>
  #   <html>
  #     &lt;h1 style=&quot;color: red&quot;&gt;I start blogging!&lt;/h1&gt;
  #
  #     &lt;!-- First post --&gt;
  #     &lt;p&gt;What a great idea!&lt;/p&gt;
  #   </html>
  # </feed>

=item

C<raw>

Treat children as raw data (no pretty printing).

  my $plain = XML::Loy->new(<<'PLAIN');
  <entry>There is <b>no</b> pretty printing</entry>
  PLAIN

  my $xml = XML::Loy->new('entry');
  my $text = $xml->add(text => { -type => 'raw' });
  $text->add($plain);

  print $xml->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <entry>
  #   <text><entry>There is <b>no</b> pretty printing</entry>
  # </text>
  # </entry>


=item

C<armour:n>

Indent the content and automatically
introduce linebreaks after every
C<n>th character.
Intended for base64 encoded data.
Defaults to 60 characters line-width after indentation.

  my $xml = XML::Loy->new('entry');

  my $b64_data = <<'B64';
    VGhpcyBpcyBqdXN0IGEgdGVzdCBzdHJpbmcgZm
    9yIHRoZSBhcm1vdXIgdHlwZS4gSXQncyBwcmV0
    dHkgbG9uZyBmb3IgZXhhbXBsZSBpc3N1ZXMu
  B64

  my $data = $xml->add(
    data => { -type => 'armour:30' } => $b64_data
  );

  $data->comment('This is base64 data!');

  print $xml->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <entry>
  #
  #   <!-- This is base64 data! -->
  #   <data>
  #     VGhpcyBpcyBqdXN0IGEgdGVzdCBzdH
  #     JpbmcgZm9yIHRoZSBhcm1vdXIgdHlw
  #     ZS4gSXQncyBwcmV0dHkgbG9uZyBmb3
  #     IgZXhhbXBsZSBpc3N1ZXMu
  #   </data>
  # </entry>

=back


=head2 set

  my $xml = XML::Loy->new('Document');
  $xml->set(Element => { id => 5 });

  # Overwrite
  $xml->set(Element => { id => 6 });

Adds a new element as a child to the node only once.
Accepts all parameters as defined in L<add|/add>.

If one or more elements with the same tag name are
already children of the requesting node,
the old elements will be deleted and
comments will be merged if possible.


=head2 comment

  $node = $node->comment('Resource Descriptor');

Prepends a comment to the current node.
If a node already has a comment, comments will be merged.


=head2 extension

  # Add extensions
  my $xml = $xml->extension('Fun', 'XML::Loy::Atom', -HostMeta);

  # Further additions
  $xml->extension(-Atom::Threading);

  my @extensions = $xml->extension;

Adds or returns an array of extensions.
When adding, returns the document.
When getting, returns the array of associated extensions.

The extensions are associated to the document, they are not associated
to the object. That means, you can't add extensions to documents
without a root node.

With this package the following extensions are bundled:
L<Atom|XML::Loy::Atom>,
L<Atom-Threading|XML::Loy::Atom::Threading>,
L<ActivityStreams|XML::Loy::ActivityStreams>,
L<GeoRSS|XML::Loy::GeoRSS>,
L<OStatus|XML::Loy::OStatus>,
L<XRD|XML::Loy::XRD>,
and L<HostMeta|XML::Loy::HostMeta>.
If an extension has a leading minus symbol, it is assumed
to be located in the C<XML::Loy> namespace, making C<XML::Loy::Atom>
and C<-Atom> equivalent.

See L<Extensions|/EXTENSIONS> for further information.

B<Note:> The return value of the extension method is experimental
and may change without warnings.


=head2 as

  my $xml = XML::Loy->new('<XRD><Subject>akron</Subject></XRD>');
  my $xrd = $xml->as(-XRD, -HostMeta);

  $xrd->alias('acct:akron@sojolicio.us');

  print $xrd->to_pretty_xml;

  # <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"
  #      xmlns:hm="http://host-meta.net/xrd/1.0"
  #      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  #   <Subject>akron</Subject>
  #   <Alias>acct:akron@sojolicio.us</Alias>
  # </XRD>

Convert an L<XML::Loy> based object to another object.
Accepts the base class and optionally a list of extensions.
This only changes the namespace of the base class - extensions
will stay intact.

See L<Extensions|/EXTENSIONS> for further information.

B<Note:> This method is experimental and may change without warnings!


=head2 mime

  print $xml->mime;

The mime type associated with the object class.
See L<Extensions|/EXTENSIONS> for further information.


=head2 namespace

  my $xml = XML::Loy->new('doc');
  $xml->namespace('http://sojolicio.us/ns/global');
  $xml->namespace(fun => 'http://sojolicio.us/ns/fun');
  $xml->add('fun:test' => { foo => 'bar' }, 'Works!');
  print $xml->namespace;

  print $xml->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <doc xmlns="http://sojolicio.us/global"
  #      xmlns:fun="http://sojolicio.us/fun">
  #   <fun:test foo="bar">Works!</fun:test>
  # </doc>

Returns the namespace of the node or
adds namespace information to the node's root.
When adding, the first parameter gives the prefix, the second one
the namespace. The prefix parameter is optional.
Namespaces are always added to the document's root,
that means,
they have to be unique in the scope of the whole document.


=head2 to_pretty_xml

  print $xml->to_pretty_xml;
  print $xml->to_pretty_xml(2);

Returns a stringified, pretty printed XML document.
Optionally accepts a numerical parameter,
defining the start of indentation (defaults to C<0>).


=head1 EXTENSIONS

  package Fun;
  use XML::Loy with => (
    prefix    => 'fun',
    namespace => 'http://sojolicio.us/ns/fun',
    mime      => 'application/fun+xml'
  );

  # Add new methods to the object
  sub add_happy {
    my $self = shift;
    my $word = shift;

    my $cool = $self->add('-Cool');
    my $cry  = uc($word) . '!!! \o/ ';
    $cool->add(Happy => {foo => 'bar'}, $cry);
  };

L<XML::Loy> allows for inheritance
and thus provides two ways of extending the functionality:
By using a derived class as a base class or by extending a
base class with the L<extension|extension> method.

With this package the following extensions are bundled:
L<Atom|XML::Loy::Atom>,
L<Atom-Threading|XML::Loy::Atom::Threading>,
L<ActivityStreams|XML::Loy::ActivityStreams>,
L<GeoRSS|XML::Loy::GeoRSS>,
L<OStatus|XML::Loy::OStatus>,
L<XRD|XML::Loy::XRD>,
and L<HostMeta|XML::Loy::HostMeta>.

For the purpose of extension, three attributes can be set when
L<XML::Loy> is used (introduced with the keyword C<with>).

=over 2

=item

C<namespace> - Namespace of the extension.

=item

C<prefix> - Preferred prefix to associate with the namespace.

=item

C<mime> - Mime type of the base document.

=back

You can use derived objects in your application as you
would do with any other object class.

  package main;
  use Fun;
  my $obj = Fun->new('Fun');
  $obj->add_happy('Yeah!');
  print $obj->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <Fun xmlns="http://sojolicio.us/ns/fun">
  #   <Cool>
  #     <Happy foo="bar">YEAH!!!! \o/ </Happy>
  #   </Cool>
  # </Fun>

The defined namespace is introduced as the document's
namespace. The prefix is not in use for derived classes.

Without any changes to the class, you can use this module as an
extension to another L<XML::Loy> based document as well.

  use XML::Loy;

  my $obj = XML::Loy->new('object');

  # Use XML::Loy based class 'Fun'
  $obj->extension('Fun');

  # Use methods provided by the base class or any extension
  $obj->add_happy('Yeah!');

  # Print with pretty indentation
  print $obj->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <object xmlns:fun="http://sojolicio.us/ns/fun">
  #   <Cool>
  #     <fun:Happy foo="bar">YEAH!!!! \o/ </fun:Happy>
  #   </Cool>
  # </object>

The defined namespace of C<Fun> is introduced with the
prefix C<fun>. The prefix is prepended to all elements
added by the L<add|/add> and L<set|/set> methods in the extension class.
To prevent this prefixing, prepend the element name with
a C<-> (like with C<E<lt>-Cool /E<gt>> in the example
above).

Derived classes are always C<strict> and C<utf8>, use C<warnings>
and import all C<features> of Perl 5.10.


=head1 DEPENDENCIES

L<Mojolicious>, L<Test::Warn> (for testing).


=head1 CAVEATS

L<XML::Loy> focuses on the comfortable handling of small documents of
serialized data and the ease of extensibility.
It is - as well as the underlying parser - written in pure perl and
not intended to be the fastest thing out there
(although I believe there's plenty of space for optimization).
That said - it may not suit all your needs, but there are loads of excellent
XML libraries out there, you can give a try then.
Just to name a few:
For fast parsing of huge documents, try L<XML::Twig>.
For validation and the availability of lots of tools from the XML world,
try L<XML::LibXML>.
For simple deserialization,
try L<XML::Bare> and L<XML::Fast>.
For similar scope, but without dependencies aside the core,
try L<XML::MyXML>.


=head1 CONTRIBUTORS

L<Renée Bäcker|https://github.com/reneeb>


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2018, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
