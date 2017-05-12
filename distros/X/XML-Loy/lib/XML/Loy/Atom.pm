package XML::Loy::Atom;
use Carp qw/carp/;
use strict;
use warnings;
use Mojo::ByteStream 'b';
use XML::Loy::Date::RFC3339;

# Todo:
#  - see http://search.cpan.org/dist/XML-Atom-SimpleFeed

our @CARP_NOT;

# Make it an XML::Loy base class
use XML::Loy with => (
  mime      => 'application/atom+xml',
  prefix    => 'atom',
  namespace => 'http://www.w3.org/2005/Atom'
);


# Namespace declaration
state $XHTML_NS = 'http://www.w3.org/1999/xhtml';


# New person construct
sub new_person {
  my $self = shift;
  my $person = ref($self)->SUPER::new('person');

  my %hash = @_;
  $person->set($_ => $hash{$_}) foreach keys %hash;
  return $person;
};


# New text construct
sub new_text {
  my $self = shift;

  return unless $_[0];

  my $class = ref($self);

  # Expect empty html
  unless (defined $_[1]) {
    return $class->SUPER::new(
      text => {
	type  => 'text',
	-type => 'raw'
      } => shift );
  };

  my ($type, $content, %hash);

  # Only textual content
  if (!defined $_[2] && $_[0] =~ m/(?:text|x?html)/) {
    $type = shift;
    $content = shift;
  }

  # Hash definition
  elsif ((@_ % 2) == 0) {
    %hash = @_;

    $type = delete $hash{type} || 'text';

    if (exists $hash{src}) {
      return $class->SUPER::new(
	text => { type => $type, %hash }
      );
    };

    $content = delete $hash{content} or return;
  };

  # Content node
  my $c_node;

  # xhtml
  if ($type eq 'xhtml') {

    # Create new by hash
    $c_node = $class->SUPER::new(
      text => {
	type => $type,
	%hash
      });

    # XHTML content - allowed to be pretty printed
   $c_node->add(
      -div => {
	xmlns => $XHTML_NS
      })->append_content($content);
  }

  # html or text
  elsif ($type eq 'html' || $type =~ /^text/i) {

    # Content is raw and thus nonindented
    $c_node = $class->new(
      text => {
	'type'  => $type,
	'-type' => 'raw',
	'xml:space' => 'preserve',
	%hash
      } => $content . ''
    );
  }

  # xml media type
  elsif ($type =~ /[\/\+]xml(;.+)?$/i) {
    $c_node = $class->new(
      text => {
	type  => $type,
	-type => 'raw',
	%hash
      } => $content);
  }

  # all other media types
  else {
    $c_node = $class->new(
      text => {
	type => $type,
	-type => 'armour',
	%hash
      },
      $content);
  };

  return $c_node;
};


# Add author information
sub author {
  my $self = shift;

  # Add author
  return $self->_add_person(author => @_) if $_[0];

  # Get author information
  return $self->_get_information_array('author');
};


# Add category information
sub category {
  my $self = shift;

  # Set category
  if ($_[0]) {
    if (!defined $_[1]) {
      return $self->add(category => { term => shift });
    };

    return $self->add(category => { @_ } );
  };

  # Get category
  my $coll = $self->_get_information_array('category')
    or return;

  if ($coll->[0]) {
    $coll->map(sub { $_ = $_->{term} });
  };

  return $coll;
};


# Add contributor information
sub contributor {
  my $self = shift;

  # Add contributor
  return $self->_add_person(contributor => @_) if $_[0];

  # Get contributor information
  return $self->_get_information_array('contributor');
};


# Add content information
sub content {
  my $self = shift;

  # Set content
  return $self->_addset_text(set => content => @_) if $_[0];

  # Return content
  return $self->_get_information_single('content');
};


# Set or get entry
sub entry {
  my $self = shift;

  # Is object
  if (ref $_[0]) {
    return $self->add(@_);
  }

  # Get entry
  elsif ($_[0] && !$_[1]) {

    my $id = shift;

    # Get based on xml:id
    my $entry = $self->at(qq{entry[xml\\:id="$id"]});
    return $entry if $entry;

    # Get based on <entry><id>id</id></entry>
    my $idc = $self->find('entry > id')->grep(sub { $_->text eq $id });

    return unless $idc && $idc->[0];

    return $idc->[0]->parent;
  };

  my %hash = @_;
  my $entry;

  # Set id additionally as xml:id
  if (exists $hash{id}) {
    $entry = $self->add(
      entry => {'xml:id' => $hash{id}}
    );
  }

  # No id given
  else {
    $entry = $self->add('entry');
  };

  # Add information
  foreach (keys %hash) {
    $entry->add($_, $hash{$_});
  };

  return $entry;
};


# Set or get generator information
sub generator {
  shift->_simple_feed_info(generator =>  @_);
};


# Set or get icon information
sub icon {
  shift->_simple_feed_info(icon =>  @_);
};


# Add id
sub id {
  my $self = shift;

  # Get id
  unless ($_[0]) {
    my $id_obj = $self->_get_information_single('id');
    return $id_obj->text if $id_obj;
    return;
  };

  my $id = shift;
  my $element = $self->set(id => $id);
  return unless $element;

  # Add xml:id also
  $element->parent->attr('xml:id' => $id);
  return $self;
};


# Add link information
sub link {
  my $self = shift;

  if ($_[1]) {

    # rel => href
    if (@_ == 2) {
      return $self->add(link => {
	rel  => shift,
	href => shift
      });
    };

    # Parameter
    my %values = @_;
    # href, rel, type, hreflang, title, length
    my $rel = delete $values{rel} || 'related';
    return $self->add(link => {
      rel => $rel,
      %values
    });
  };

  my $rel = shift;

  my $children;
  # Node is root
  unless ($self->parent) {
    $children = $self->at('*')->children('link');
  }

  # Node is under root
  else {
    $children = $self->children('link');
  };

  return $children->grep(sub { $_->attr('rel') eq $rel });
};


# Add logo
sub logo {
  shift->_simple_feed_info(logo =>  @_);
};


# Add publish time information
sub published {
  shift->_date(published => @_);
};


# Add rights information
sub rights {
  my $self = shift;

  # Set rights
  return $self->_addset_text(set => rights => @_) if $_[0];

  # Return rights
  return $self->_get_information_single('rights');
};


# Add source information to entry
sub source {
  my $self = shift;

  # Only valid in entry
  return if !$self->tag || $self->tag ne 'entry';

  # Set source
  return $self->set(source => @_) if $_[0];

  # Return source
  return $self->_get_information_single('source');
};


# Add subtitle
sub subtitle {
  my $self = shift;

  # Only valid in feed or source or something
  return if $self->tag && $self->tag eq 'entry';

  # Set subtitle
  return $self->_addset_text(set => subtitle => @_) if $_[0];

  # Return subtitle
  return $self->_get_information_single('subtitle');
};


# Add summary
sub summary {
  my $self = shift;

  # Only valid in entry
  return if !$self->tag || $self->tag ne 'entry';

  # Set summary
  return $self->_addset_text(set => summary => @_) if $_[0];

  # Return summary
  return $self->_get_information_single('summary');
};


# Add title
sub title {
  my $self = shift;

  # Set title
  return $self->_addset_text(set => title => @_) if $_[0];

  # Return title
  return $self->_get_information_single('title');
};


# Add update time information
sub updated {
  shift->_date(updated => @_);
};


# Add person information
sub _add_person {
  my $self = shift;
  my $type = shift;

  # Person is a defined node
  if (ref($_[0])) {
    my $person = shift;
    $person->root->at('*')->tree->[1] = $type;
    return $self->add($person);
  }

  # Person is a hash
  else {
    my $person = $self->add($type);
    my %data = @_;

    foreach (keys %data) {
      $person->add($_ => $data{$_} ) if $data{$_};
    };
    return $person;
  };
};


# Add date construct
sub _date {
  my $self = shift;
  my $type = shift;

  # Set date
  if ($_[0]) {
    my $date = shift;

    unless (ref($date)) {
      $date = XML::Loy::Date::RFC3339->new($date);
    };

    return $self->set($type, $date->to_string);
  };

  # Get published information
  my $date = $self->_get_information_single($type);

  # Parse date
  return XML::Loy::Date::RFC3339->new($date->text) if $date;

  # No publish information found
  return;
};


# Add text information
sub _addset_text {
  my $self   = shift;
  my $action = shift;

  unless ($action eq 'add' || $action eq 'set') {
    warn 'Action has to be set or add' and return;
  };

  my $type = shift;

  # Text is a defined node
  if (ref $_[0]) {

    my $text = shift;

    # Get root element
    my $root_elem = $text->root->at('*');

    $root_elem->tree->[1] = $type;
    my $root_att = $root_elem->attr;

    # Delete type
    my $c_type = $root_att->{type} || '';
    if ($c_type eq 'text') {
      delete $root_elem->attr->{'type'};
    };

    $text->root->at('*')->tree->[1] = $type;

    my $element = $self->$action($text);

    # Return wrapped div
    return $element->at('div') if $c_type eq 'xhtml';

    # Return node
    return $element;
  };

  my $text;
  # Text is no hash
  unless (defined $_[1]) {
    $text = $self->new_text(
      type => 'text',
      content => shift
    );
  }

  # Text is a hash
  else {
    $text = $self->new_text(@_);
  };

  # Todo: Optimize!
  return $self->_addset_text($action, $type, $text) if ref $text;
  return;
};


# Return information of entries or the feed
sub _get_information_array {
  my $self = shift;
  my $type = shift;

  # Get author objects
  my $children = $self->children($type);

  # Return information of object
  return $children if $children->[0];

  # Return feed information
  return $self->find('feed > ' . $type);
};


# Return information of entries or the feed
sub _get_information_single {
  my $self = shift;
  my $type = shift;

  # Get author objects
  my $children = $self->children($type);

  # Return information of object
  return $children->[0] if $children->[0];

  # Return feed information
  return $self->at('feed > ' . $type);
};


# Get or set simple feed information
# like generator or icon
sub _simple_feed_info {
  my $self = shift;
  my $type = shift;

  my $feed = $self->root->at('feed');
  return unless $feed;

  # Set
  if ($_[0]) {
    return $feed->set($type => @_);
  };

  # Get generator information
  my $gen = $feed->at($type);
  return $gen->all_text if $gen;
  return;
};


1;


__END__

=pod

=head1 NAME

XML::Loy::Atom - Atom Syndication Format Extension


=head1 SYNOPSIS

  # Create new Atom feed
  my $feed = XML::Loy::Atom->new('feed');

  # Add new author
  $feed->author(
    name => 'Sheldon Cooper',
    uri => 'https://en.wikipedia.org/wiki/Sheldon_Cooper'
  );

  # Set title
  $feed->title('Bazinga!');

  # Set current time for publishing
  $feed->published(time);

  # Add new entry
  my $entry = $feed->entry(id => 'first');

  for ($entry) {
    $_->title('Welcome');
    $_->summary('My first post');

    # Add content
    my $content = $_->content(
      xhtml => '<p>First para</p>'
    );

    # Use XML::Loy methods
    $content->add(p => 'Second para')
            ->comment('My second paragraph');
  };

  # Get summary of first entry
  print $feed->entry('first')->summary->all_text;
  # My first post

  # Pretty print
  print $feed->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <feed xmlns="http://www.w3.org/2005/Atom">
  #   <author>
  #     <name>Sheldon Cooper</name>
  #     <uri>https://en.wikipedia.org/wiki/Sheldon_Cooper</uri>
  #   </author>
  #   <title xml:space="preserve">Bazinga!</title>
  #   <published>2013-03-07T17:51:25Z</published>
  #   <entry xml:id="first">
  #     <id>first</id>
  #     <title xml:space="preserve">Welcome</title>
  #     <summary xml:space="preserve">My first post</summary>
  #     <div xmlns="http://www.w3.org/1999/xhtml">
  #       <p>First para</p>
  #
  #       <!-- My second paragraph -->
  #       <p>Second para</p>
  #     </div>
  #   </entry>
  # </feed>

=head1 DESCRIPTION

L<XML::Loy::Atom> is a base class or extension
for L<XML::Loy> and provides several functions
for the work with the
L<Atom Syndication Format|http://tools.ietf.org/html/rfc4287>.

This code may help you to create your own L<XML::Loy> extensions.

B<This module is an early release! There may be significant changes in the future.>

=head1 METHODS

L<XML::Loy::Atom> inherits all methods
from L<XML::Loy> and implements the
following new ones.


=head2 new_person

  my $person = $atom->new_person(
    name => 'Bender',
    uri  => 'acct:bender@example.org'
  );

Creates a new person construction.
Accepts a hash with element descriptions.


=head2 new_text

  my $text = $atom->new_text('This is a test');
  my $text = $atom->new_text( xhtml => 'This is a <strong>test</strong>!');
  my $text = $atom->new_text(
    type    => 'xhtml',
    content => 'This is a <strong>test</strong>!'
  );

Creates a new text construct. Accepts either a simple string
(of type C<text>), a tupel with the first argument being the
media type and the second argument being the content,
or a hash with the parameters C<type>,
C<content> or C<src> (and others). There are three predefined
C<type> values:

=over 2

=item

C<text> for textual data

=item

C<html> for HTML data

=item

C<xhtml> for XHTML data

=back

C<xhtml> data is automatically wrapped in a
namespaced C<div> element (see
L<RFC4287, Section 3.1|http://tools.ietf.org/html/rfc4287.htm#section-3.1>
for further details).


=head2 author

  my $person = $atom->new_person(
    name => 'Bender',
    uri  => 'acct:bender@example.org'
  );
  my $author = $atom->author($person);

  print $atom->author->[0]->at('name')->text;

Adds author information to the Atom object or returns it.
Accepts a person construct (see L<new_person|/new_person>)
or the parameters accepted by L<new_person|/new_person>.

Returns a collection of author nodes.


=head2 category

  $atom->category('world');

  print $atom->category->[0];

Adds category information to the Atom object or returns it.
Accepts either a hash of attributes
(with, e.g., C<term> and C<label>)
or one string representing the category's term.

Returns a collection of category terms.


=head2 content

  my $text = $atom->new_text(
    type    => 'xhtml',
    content => '<p>This is a <strong>test</strong>!</p>'
  );

  my $entry = $atom->entry(id => 'entry_1');

  $entry->content($text);
  $entry->content('This is a test!');

  print $entry->content->all_text;

Sets content information to the Atom object or returns it.
Accepts a text construct (see L<new_text|/new_text>) or the
parameters accepted by L<new_text|/new_text>.

Returns the content node or,
on construction of an C<xhtml> object,
the wrapped div node.


=head2 contributor

  my $person = $atom->new_person(
    name => 'Bender',
    uri  => 'acct:bender@example.org'
  );
  my $contributor = $atom->contributor($person);

  print $atom->contributor->[0]->at('name')->text;

Adds contributor information to the Atom object or returns it.
Accepts a person construct (see L<new_person|/new_person>)
or the parameters accepted by L<new_person|/new_person>.

Returns a collection of contributor nodes.

=head2 entry

  # Add entry as a hash of attributes
  my $entry = $atom->entry(
    id      => 'entry_id_1',
    summary => 'My first entry'
  );

  # Get entry by id
  my $entry = $atom->entry('entry_id_1');

Adds an entry to the Atom feed or returns one.
Accepts a hash of simple entry information
for adding or an id for retrieval.

Returns the entry node.


=head2 generator

  $atom->generator('XML-Loy-Atom');
  print $atom->generator;

Sets generator information of the feed or returns it
as a text string.


=head2 icon

  $atom->icon('http://sojolicio.us/favicon.ico');
  print $atom->icon;

Sets icon url of the feed or returns it as a text string.
The image should be suitable for a small representation size
and have an aspect ratio of 1:1.


=head2 id

  $atom->id('http://sojolicio.us/#12345');
  print $atom->id;

Sets or returns the unique identifier of the Atom object.


=head2 link

  $atom->link(related => 'http://sojolicio.us/#12345');
  $atom->link(
    rel  => 'self',
    href => 'http://sojolicio.us/#12345'
  );

  # Get link elements
  print $atom->link('related')->[0]->attr('href');


Adds link information to the Atom object or returns it.
Accepts for retrieval the relation type and for setting
the relation type followed by the reference,
or multiple pairs as attributes of the link.
If no relation attribute is given, the default relation
is C<related>.

Returns the link element on adding and
a collection of matching link elements on retrieval.


=head2 logo

  $atom->logo('http://sojolicio.us/sojolicious.png');
  print $atom->logo;

Sets logo url of the feed or returns it as a text string.
The image should have an aspect ratio of 2:1.


=head2 published

  $atom->published('1312311456');
  $atom->published('2011-08-30T16:16:40Z');

  # Set current time
  $atom->published(time);

  print $atom->published->to_string;

Sets the publishing date of the Atom object
or returns the publishing date as a
L<XML::Loy::Date::RFC3339> object.
Accepts all valid parameters of
L<XML::Loy::Date::RFC3339::new|XML::Loy::Date::RFC3339/new>.

B<This method is experimental and may return another
object with a different API!>


=head2 rights

  $atom->rights('Public Domain');
  print $atom->rights->all_text;

Sets legal information of the Atom object or returns it.
Accepts a text construct (see L<new_text|/new_text>)
or the parameters accepted by L<new_text|/new_text>.

Returns the rights node or,
on construction of an C<xhtml> object,
the wrapped div node.


=head2 source

  my $source = $atom->entry('my_id')->source({
    'xml:base' => 'http://source.sojolicio.us/'
  });
  $source->author(name => 'Zoidberg');

  print $atom->entry('my_id')
        ->source
        ->author->[0]->at('name')->all_text;

Sets or returns the source information of an atom entry.
Expects for setting a hash reference (at least empty)
of the attributes of the source.

Returns the source node.


=head2 subtitle

  my $text = $atom->new_text(
    type => 'text',
    content => 'This is a subtitle!'
  );

  $atom->subtitle($text);
  $atom->subtitle('This is a subtitle!');

  print $atom->subtitle->all_text;

Sets subtitle information to the Atom feed or returns it.
Accepts a text construct (see L<new_text|/new_text>)
or the parameters accepted by L<new_text|/new_text>.

Returns the subtitle node or,
on construction of an C<xhtml> object,
the wrapped div node.


=head2 summary

  my $text = $atom->new_text(
    type => 'text',
    content => 'This is a summary!'
  );

  $atom->summary($text);
  $atom->summary('This is a summary!');

  print $atom->summary->all_text;

Sets summary information to the Atom entry or returns it.
Accepts a text construct (see L<new_text|/new_text>)
or the parameters accepted by L<new_text|/new_text>.

Returns the summary node or,
on construction of an C<xhtml> object,
the wrapped div node.


=head2 title

  my $text = $atom->new_text(
    type => 'text',
    content => 'This is a title!'
  );

  $atom->title($text);
  $atom->title('This is a title!');

  print $atom->title->all_text;

Sets title information to the Atom object or returns it.
Accepts a text construct (see L<new_text|/new_text>)
or the parameters accepted by L<new_text|/new_text>.

Returns the title node or,
on construction of an C<xhtml> object,
the wrapped div node.


=head2 updated

  $atom->updated('1312311456');
  $atom->updated('2011-08-30T16:16:40Z');

  # Set current time
  $atom->updated(time);

  print $atom->updated->to_string;

Sets the date of the last update of the Atom object
or returns it as a
L<XML::Loy::Date::RFC3339> object.
Accepts all valid parameters of
L<XML::Loy::Date::RFC3339's new|XML::Loy::Date::RFC3339/new>.

B<This method is experimental and may return another
object with a different API!>


=head1 MIME-TYPES

When loaded as a base class, L<XML::Loy::Atom>
makes the mime-type C<application/atom+xml>
available.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2016, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
