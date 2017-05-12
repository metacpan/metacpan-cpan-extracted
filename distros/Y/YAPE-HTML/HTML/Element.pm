package YAPE::HTML::Element;

$VERSION = '1.10';


sub text { $_[0]{TEXT} }
sub string { $_[0]->text }
sub fullstring { $_[0]->string }
sub type { $_[0]{TYPE} }


package YAPE::HTML::tag;

sub new {
  my ($class, $tag, $attr, $text, $closed, $impl) = @_;
  bless {
    TYPE => 'tag',
    TAG => $tag,
    ATTR => $attr || {},
    TEXT => $text || [],
    CLOSED => $closed || 0,
    IMPLIED => $impl || 0,
  }, $class;
}

sub string {
  my $self = shift;
  my $str = "<$self->{TAG}";
  for (sort keys %{ $self->{ATTR} }) {
    $str .= " $_";
    if (defined $self->{ATTR}{$_}) {
      $str .= "=" . YAPE::HTML::quote($self->{ATTR}{$_});
    }
  }
  $str .= " /" if $self->{IMPLIED};
  $str .= ">";
  return $str;
}

sub fullstring {
  my $self = shift;
  my ($taghash, $taglist) = ({}, []);
  @$taghash{@{ $taglist = shift }} = () if ref $_[0];
  my $d = @_ ? $_[0] : -1;
  my $str;

  $str = $self->string if $d and not exists $taghash->{$self->{TAG}};
  $str .= join "", map
    $_->fullstring($taglist, $d > 0 ? $d-1 : $d),
    @{ $self->{TEXT} };
  $str .= "</$self->{TAG}>" if
    $self->{CLOSED} and $d and not exists $taghash->{$self->{TAG}};
  return $str;
}

sub get_attr {
  my $self = shift;
  return %{ $self->{ATTR} } if not @_;
  return $self->{ATTR}{$_[0]} if @_ == 1;
  return @{ $self->{ATTR} }{map lc, @_};
}

sub has_attr {
  my $self = shift;
  return exists $self->{ATTR}{lc $_[0]} if @_ == 1;
  return map exists $self->{ATTR}{lc $_}, @_;
}

sub set_attr {
  my $self = shift;
  while (my $k = shift) { $self->{ATTR}{lc $k} = shift }
}

sub rem_attr {
  my $self = shift;
  delete @{ $self->{ATTR} }{map lc, @_};
}

sub closed { $_[0]{CLOSED} }
sub implied_closed { $_[0]{IMPLIED} }
sub tag { $_[0]{TAG} }



package YAPE::HTML::closetag;

sub new {
  my ($class, $tag) = @_;
  bless { TYPE => 'closetag', TAG => $tag }, $class;
}

sub string { "</$_[0]{TAG}>" }
sub tag { $_[0]{TAG} }



package YAPE::HTML::text;

sub new {
  my ($class, $text) = @_;
  bless { TYPE => 'text', TEXT => $text }, $class;
}



package YAPE::HTML::comment;

sub new {
  my ($class, $comment) = @_;
  bless { TYPE => 'comment', TEXT => $comment }, $class;
}

sub string { "<!--$_[0]{TEXT}-->" }



package YAPE::HTML::dtd;

sub new {
  my ($class, $attr) = @_;
  my $hattr;

  $attr ||= [];
  @{$hattr}{@$attr} = ();
  bless { TYPE => 'dtd', ATTR => $attr, HATTR => $hattr }, $class;
}

sub get_attr { @{ $_[0]{ATTR} } }
sub set_attr { @{ $_[0]{HATTR} }{ @{ $_[0]{ATTR} } = @_[1..$#_] } = () }
sub string { "<!DOCTYPE @{ $_[0]{ATTR} }>" }



package YAPE::HTML::pi;

sub new {
  my ($class, $name, $attr) = @_;
  bless { TYPE => 'pi', NAME => $name, ATTR => $attr || {} }, $class;
}

sub string {
  my $self = shift;
  my $str = "<?$self->{NAME}";
  for (sort keys %{ $self->{ATTR} }) {
    $str .= " $_";
    if (defined $self->{ATTR}{$_}) {
      $str .= "=" . YAPE::HTML::quote($self->{ATTR}{$_});
    }
  }
  $str .= "?>";
  return $str;
}

sub get_attr {
  my $self = shift;
  return %{ $self->{ATTR} } if not @_;
  return $self->{ATTR}{$_[0]} if @_ == 1;
  return @{ $self->{ATTR} }{map lc, @_};
}

sub has_attr {
  my $self = shift;
  return exists $self->{ATTR}{lc $_[0]} if @_ == 1;
  return map exists $self->{ATTR}{lc $_}, @_;
}

sub set_attr {
  my $self = shift;
  while (my $k = shift) { $self->{ATTR}{lc $k} = shift }
}

sub rem_attr {
  my $self = shift;
  delete @{ $self->{ATTR} }{map lc, @_};
}

sub name { $_[0]{NAME} }



package YAPE::HTML::ssi;

sub new {
  my ($class, $com, $attr) = @_;
  bless { TYPE => 'ssi', COM => $com, ATTR => $attr || {} }, $class;
}

sub string {
  my $self = shift;
  my $str = "<!--#$self->{COM}";
  for (sort keys %{ $self->{ATTR} }) {
    $str .= " $_";
    if (defined $self->{ATTR}{$_}) {
      $str .= "=" . YAPE::HTML::quote($self->{ATTR}{$_});
    }
  }
  $str .= "-->";
  return $str;
}

sub get_attr {
  my $self = shift;
  return %{ $self->{ATTR} } if not @_;
  return $self->{ATTR}{$_[0]} if @_ == 1;
  return @{ $self->{ATTR} }{map lc, @_};
}

sub has_attr {
  my $self = shift;
  return exists $self->{ATTR}{lc $_[0]} if @_ == 1;
  return map exists $self->{ATTR}{lc $_}, @_;
}

sub set_attr {
  my $self = shift;
  while (my $k = shift) { $self->{ATTR}{lc $k} = shift }
}

sub rem_attr {
  my $self = shift;
  delete @{ $self->{ATTR} }{map lc, @_};
}

sub command { $_[0]{COM} }



1;

__END__

=head1 NAME

YAPE::HTML::Element - sub-classes for YAPE::HTML elements

=head1 SYNOPSIS

  use YAPE::HTML 'MyExt::Mod';
  # this sets up inheritence in MyExt::Mod
  # see YAPE::HTML documentation

=head1 C<YAPE> MODULES

The C<YAPE> hierarchy of modules is an attempt at a unified means of parsing
and extracting content.  It attempts to maintain a generic interface, to
promote simplicity and reusability.  The API is powerful, yet simple.  The
modules do tokenization (which can be intercepted) and build trees, so that
extraction of specific nodes is doable.

=head1 DESCRIPTION

This module provides the classes for the C<YAPE::HTML> objects.  The base class
for these objects is C<YAPE::HTML::Element>; the four object classes are
C<YAPE::HTML::opentag>, C<YAPE::HTML::closetag>, C<YAPE::HTML::text>, and
C<YAPE::HTML::comment>.

=head2 Methods for C<YAPE::HTML::Element>

This class contains fallback methods for the other classes.

=over 4

=item * C<my $content = $obj-E<gt>text;>

Returns an array reference of objects between an open and close tag, or a string
of plain text for a block of text or a comment.  This method merely returns the
C<TEXT> value in the object hash.  This returns C<undef> for C<dtd>, C<pi>, and
C<ssi> objects.

=item * C<my $string = $obj-E<gt>string;>

Returns a string representing the single object (for tags, this does not include
the elements found in between the open and close tag).  This method merely calls
the object's C<text> method.

=item * C<my $complete = $obj-E<gt>fullstring;>

Returns a string representing the object (and all objects found within it, in
the case of a tag).  This method merely calls the object's C<string> method.

=item * C<my $type = $obj-E<gt>type;>

Returns the type of the object:  C<tag>, C<closetag>, C<text>, or C<comment>.

=back

=head2 Methods for C<YAPE::HTML::opentag>

This class represents tags.  Object has the following methods:

=over 4

=item * S<C<my $tag = YAPE::HTML::opentag-E<gt>new($name, $attr, $text, $closed, $impl);>>

Creates a C<YAPE::HTML::opentag> object.  Takes five arguments: the name of the
HTML element, a hash reference of attribute-value pairs, an array reference of
objects to be included in between the open and closing tags, whether the tag is
explicitly closed or not, and whether the tag is implicitly closed or not.  The
attribute hash reference must have the keys in lowercase text.

  my $attr = { src => 'foo.png', alt => 'foo' };
  my $img = YAPE::HTML::opentag->new('img', $attr, [], 0, 1);
  
  my $text = [ YAPE::HTML::text->new("Bar!"), $img ];
  my $name = YAPE::HTML::opentag->new('a', { name => 'foo' }, $text);

=item * C<my $str = $tag-E<gt>string;>

Creates a string representation of the I<tag only>.  This means the tag, and any
attributes of the tag I<only>.  No closing tag (if any) is returned.

  print $img->string;
  # <img src="foo.png" alt="foo" />
  
  print $name->string;
  # <a name="foo">

=item * C<my $str = $tag-E<gt>fullstring($exclude, $depth);>

Creates a string representation of the tag, the content enclosed between the open
and closing tags, and the closing tag (if applicable).  The method can take two
arguments: an array reference of tag names B<not> to render, and the depth with
which to render tags.  The C<$exclude> defaults to none, and C<$depth> defaults
to C<-1>, which means there is no depth limit.

  print $img->fullstring;
  # <img src="foo.png" width=20 height=43 />
  
  print $name->fullstring;
  # <a name="foo">Bar!<img src="foo.png" alt="foo" /></a>
  
  print $name->fullstring(0);
  # Bar!
  
  print $name->fullstring(['img']);
  # <a name="foo">Bar!</a>
  
  print $name->fullstring(1);
  # <a name="foo">Bar!</a>

=item * C<my $attr = $tag-E<gt>get_attr($name);>

=item * C<my @attrs = $tag-E<gt>get_attr(@names);>

=item * C<my %attrs = $tag-E<gt>get_attr;>

Fetches any number of attribute values from a tag.  B<Note:> tags which contain
attributes with no value have a value of C<undef> returned for that attribute --
this is indistinguishable from the C<undef> returned for a tag that does not have
an attribute.  This is on the list of things to be fixed.  In the meantime, use
the C<has_attr> method beforehand.

  print $name->get_attr('name');
  # 'foo'
  
  my %list = $img->get_attr;
  # alt => 'foo', src => 'foo.png'

=item * C<my $attr = $tag-E<gt>has_attr($name);>

=item * C<my @attrs = $tag-E<gt>has_attr(@names);>

Returns C<1> or C<""> depending on the existence of the attribute in the tag.

  my @on = $name->has_attr(qw( name href ));  # (1,0)

=item * C<$tag-E<gt>set_attr(%pairs);>

Sets a list of attributes to the associated values for the tag.

  $img->set_attr( width => 40, height => 16 );

=item * C<$tag-E<gt>rem_attr(@names);>

Removes (and returns) the specified attributes from a tag.  See the caveat above
for the C<get_attr> method about C<undef> values.

  my $src = $img->rem_attr('src');

=item * C<my $closed = $tag-E<gt>closed;>

Returns C<1> or C<0>, depending on whether or not the tag is closed.  This means
it has a closing tag -- tags like C<E<lt>hr /E<gt>> are not closed.

=item * C<my $impl = $tag-E<gt>implied_closed;>

Returns C<1> or C<0>, depending on whether or not the tag is implicitly closed
with a C</> at the end of the tag (like C<E<lt>hr /E<gt>>).

=item * C<my $tagname = $tag-E<gt>tag;>

Returns the name of the HTML element.

  print $name->tag;  # 'a'

=back

=head2 Methods for C<YAPE::HTML::closetag>

This class represents closing tags.  Object has the following methods:

=over 4

=item * C<my $tag = YAPE::HTML::closetag-E<gt>new($name);>

Creates a C<YAPE::HTML::closetag> object.  Takes one argument: the name of the
HTML element.  These objects are never included in the HTML tree structure, since
the parser uses the C<CLOSED> attribute of an C<opentag> object to figure out if
there needs to be a closing tag.  However, they are returned in the parsing stage
so that you know when they've been reached.

  my $close = YAPE::HTML::closetag->new('a');

=item * C<my $str = $tag-E<gt>string;>

Creates a string representation of the closing tag.

  print $close->string;  # '</a>'

=item * C<my $tagname = $tag-E<gt>tag;>

Returns the name of the HTML element.

  print $close->tag;  # 'a'

=back

=head2 Methods for C<YAPE::HTML::text>

This class represents blocks of plain text.  Objects have the following methods:

=over 4

=item * C<my $text = YAPE::HTML::text-E<gt>new($content);>

Creates a C<YAPE::HTML::text> object.  Takes one argument: the text of the block.

  my $para = YAPE::HTML::text->new(<< "END");
  Perl is not an acronym -- rather "Practical Extraction
  and Report Language" was developed after the fact.
  END

=back

=head2 Methods for C<YAPE::HTML::comment>

This class represents comments.  Objects have the following methods:

=over 4

=item * C<my $comment = YAPE::HTML::comment-E<gt>new($content);>

Creates a C<YAPE::HTML::comment> object.  Takes one argument: the text of the
comment.

  my $todo = YAPE::HTML::comment->new(<< "END");
  This table should be formatted differently.
  END

=item * C<my $str = $comment-E<gt>string;>

Creates a string representation of the comment, with C<E<lt>!--> before it, and
C<--E<gt>> after it.

  print $todo->string;
  # <!--This table should be formatted differently-->

=back

=head2 Methods for C<YAPE::HTML::dtd>

This class represents C<E<lt>!DOCTYPEE<gt>> tags.  Objects have the following
methods:

=over 4

=item * C<my $dtd = YAPE::HTML::dtd-E<gt>new(\@fields);>

Creates a C<YAPE::HTML::dtd> object.  Takes one argument: an array reference of
the four fields (should be two unquoted strings, and two quoted strings (?)).

  my $dtd = YAPE::HTML::dtd->new([
    'HTML',
    'PUBLIC',
    '"-//W3C//DTD HTML 4.01//EN"',
    '"http://www.w3.org/TR/html4/strict.dtd"'
  ]);

=item * C<my $str = $dtd-E<gt>string;>

Creates a string representation of the DTD.

  print $dtd->string;
  # (line breaks added for readability)
  # <!DOCTYPE HTML PUBLIC
  #   "-//W3C//DTD HTML 4.01//EN"
  #   "http://www.w3.org/TR/html4/strict.dtd">

=item * C<my @attrs = $dtd-E<gt>get_attrs;>

Returns the four attributes of the DTD.

=item * C<$dtd-E<gt>set_attrs(@attrs);>

Sets the four attributes of the DTD (can't be done piecemeal).

=back

=head2 Methods for C<YAPE::HTML::pi>

This class represents process instruction tags.  Objects have the following
methods:

=over 4

=item * S<C<my $pi = YAPE::HTML::pi-E<gt>new($name, $attr);>>

Creates a C<YAPE::HTML::pi> object.  Takes two arguments: the name of the
processing instruction, and a hash reference of attribute-value pairs.  The
attribute hash reference must have the keys in lowercase text.

  my $attr = { order => 'alphabetical', need => 'examples' };
  my $pi = YAPE::HTML::pi->new(sample => $attr);

=item * C<my $str = $pi-E<gt>string;>

Creates a string representation of the processing instruction.

  print $pi->string;
  # <?sample need="examples" order="alphabetical"?>

=item * C<my $attr = $pi-E<gt>get_attr($name);>

=item * C<my @attrs = $pi-E<gt>get_attr(@names);>

=item * C<my %attrs = $pi-E<gt>get_attr;>

=item * C<my $attr = $pi-E<gt>has_attr($name);>

=item * C<my @attrs = $pi-E<gt>has_attr(@names);>

=item * C<$pi-E<gt>set_attr(%pairs);>

=item * C<$pi-E<gt>rem_attr(@names);>

See the identical methods for C<opentag> objects above.

=item * C<my $name = $pi-E<gt>name;>

Returns the name of the processing instruction.

  print $pi->name;  # 'first'

=back

=head2 Methods for C<YAPE::HTML::ssi>

This class represents server-side includes.  Objects have the following methods:

=over 4

=item * S<C<my $ssi = YAPE::HTML::ssi-E<gt>new($name, $attr);>>

Creates a C<YAPE::HTML::ssi> object.  Takes two arguments: the SSI command, and
a hash reference of attribute-value pairs.  The attribute hash reference must
have the keys in lowercase text.

  my $attr = { var => 'REMOTE_HOST' };
  my $ssi = YAPE::HTML::ssi->new(echo => $attr);

=item * C<my $str = $ssi-E<gt>string;>

Creates a string representation of the processing instruction.

  print $ssi->string;
  # <!--#echo var="REMOTE_HOST"-->

=item * C<my $attr = $ssi-E<gt>get_attr($name);>

=item * C<my @attrs = $ssi-E<gt>get_attr(@names);>

=item * C<my %attrs = $ssi-E<gt>get_attr;>

=item * C<my $attr = $ssi-E<gt>has_attr($name);>

=item * C<my @attrs = $ssi-E<gt>has_attr(@names);>

=item * C<$ssi-E<gt>set_attr(%pairs);>

=item * C<$ssi-E<gt>rem_attr(@names);>

See the identical methods for C<opentag> objects above.

=item * C<my $command = $ssi-E<gt>command;>

Returns the SSI command's name.

  print $ssi->command;  # 'echo'

=back

=head1 CAVEATS

The C<E<lt>scriptE<gt>> and C<E<lt>xmpE<gt>> tags are given special treatment.
When they are encountered, all text up to the first occurrence of the appropriate
closing tag is taken as plain text.

Tag attributes are displayed in the default C<sort()> order.

=head1 TO DO

This is a listing of things to add to future versions of this module.

=over 4

=item * SSI commands C<if>, C<elif>, and C<else>

These need to contain content, since the text between them is associated with a
given condition.

=back

=head1 BUGS

Following is a list of known or reported bugs.

=over 4

=item * This documentation might be incomplete.

=back

=head1 SUPPORT

Visit C<YAPE>'s web site at F<http://www.pobox.com/~japhy/YAPE/>.

=head1 SEE ALSO

The C<YAPE::HTML::Element> documentation, for information on the node classes.

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut

=cut
