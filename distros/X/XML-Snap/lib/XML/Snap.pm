package XML::Snap;

use 5.006;
use strict;
use warnings FATAL => 'all';

use XML::Parser;
use Scalar::Util qw(reftype refaddr);
use Carp;
#use Data::Dumper;

=head1 NAME

XML::Snap - Makes simple XML tasks a snap!

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

XML::Snap is a quick and relatively modern way to work with XML. If, like me, you have little patience for the endless reams of standards
the XML community burdens you with, maybe this is the module for you. If you want to maintain compatibility with normal people, though, and you want
to avoid scaling problems later, you're probably better off sitting down and understanding XML::LibXML and the SAX ecosystem.

The other large omission from the model at present is namespaces. If you use namespaces (and honestly, most applications do) then again, you
should be using libxml or one of the SAX parsers.

Still here? Cool. XML::Snap is my personal way of dealing with XML when I can't avoid it. It's roughly based on my experiences with my ANSI C
library "xmlapi", which I wrote back in 2000 to wrap the Expat parser. Along the way, I ended up building a lot of handy functionality into the
library that made C programming palatable - and a lot of that was string and list manipulation that Perl renders superfluous. So after working
with a port for a while, I tossed it. This is what I ended up with.

XML::Snap works in DOM mode. That is, it reads in XML from a string or file and puts it into a tree for you to manipulate, then allows
you to write it back out. The tree is pretty minimalistic. The children of a node can be either plain text (as strings) or elements (as XML::Snap
objects or a subclass), and each element can have a hash of attributes. Order of attributes is maintained, as this is actually significant in XML.
There is also a clear distinction between content and tags. So some of the drawbacks to XML::Simple are averted with this setup.

Right at the moment, comments in the XML are not preserved. If you need to work with XML comments, XML::Snap is not your module.

Right at the moment, a streaming mode (like SAX) is also not provided, but it's something I want to get to soon. In streaming mode, comments
I<will> be preserved, but not available to the user until further notice. But since streaming has not yet been implemented, that's kind of moot.
Streaming will be implemented in a separate module, probably to be named XML::Skim.

Some examples!

   use XML::Snap;
   
   XML::Snap->load ('myfile.xml');
   my $query = XML::Snap->search ('mynode');
   while (my $hit = <$query>) {
       ... do things with $hit ...
   }
   
=head1 CREATING AND LOADING XML ELEMENTS

=head2 new (name, [attribute, value, ...])

The C<new> function just creates a new, empty XML node, simple as that. It has a name and optional attributes with values.
Note that the order of attributes will be retained. Duplicates are not permitted (storage is in a hash); this departs from the XML
model so it might cause you troubles - but I know I've never personally encountered XML where it would make a difference.

=cut

sub new {
   my ($class, $name) = @_;
   
   bless ({
      name=>$name,
	  parent=>undef,
	  attrs=>[],
	  attrval=>{},
	  children=>[]}, $class);
}

=head2 parse (string), parse_with_refs (string)

The C<parse> function uses the Expat parser wrapped in XML::Parse to parse the string supplied, building a tree from it.
If you want text to be blessed scalar refs instead of just strings, use C<parse_with_refs>. (This can be easier, depending
on what you're going to do with the data structure later.)

=cut

sub _prepare_parser {
   my $s = shift;
   XML::Parser->new (
      Handlers => {
	     Start => sub {
	        my $p = shift;
            my $elem = XML::Snap->new (shift);
            $elem->set (@_);
            $s->{output}->add ($elem) if defined $s->{output};
            $s->{output} = $elem;
         },
		 End => sub {
		    my ($p, $el) = @_;
            my $parent = $s->{output}->parent;
            $s->{output} = $parent if defined $parent and ref($parent);
	     },
		 Char => sub {
            my ($p, $str) = @_;
            $s->{output}->add($s->{refs} ? \$str : $str) if defined $s->{output}; # Note that plain text not enclosed in nodes will be lost. I'm OK with that.
		 }
	 }
   );
}

sub parse {
   my ($whatever, $string) = @_;
   
   my $stash = {refs=>0};
   my $parser = _prepare_parser($stash);
   $parser->parse ($string);
   return $stash->{output};
}
sub parse_with_refs {
   my ($whatever, $string) = @_;
   
   my $stash = {refs=>1};
   my $parser = _prepare_parser($stash);
   $parser->parse ($string);
   return $stash->{output};
}

=head2 load (filename)

The C<load> function does the same as C<parse> but takes a filename instead.

=cut

sub load {
   my ($whatever, $string) = @_;
   
   my $stash = {};
   my $parser = _prepare_parser($stash);
   $parser->parsefile ($string);
   return $stash->{output};
}

=head2 name, is

The C<name> method returns the name of the node, that is, the tag used to create it, while
the C<is> method tests for equality to a given string (it's just a convenience function).

=cut

sub name { reftype($_[0]) eq 'HASH' ? $_[0]->{name} : '' }
sub is   { reftype($_[0]) eq 'HASH' ? $_[0]->{name} eq $_[1] : 0 }

use overload ('""' => sub { $_[0]->name . '(' . ref($_[0]) . ':' . refaddr($_[0]) . ')' },
              '==' => sub { defined(refaddr($_[0])) and defined(refaddr($_[1])) and refaddr($_[0]) eq refaddr($_[1]) },
              'eq' => sub { refaddr($_[0]) eq refaddr($_[1]) },
              '!=' => sub { refaddr($_[0]) ne refaddr($_[1]) });
              
=head2 oob(key, value), unoob(key)

Sets/gets an out-of-band (OOB) value on a node. This isn't anything special, just a hash
attached to each node, but it can be used by a template output for parameterization,
and it doesn't affect the output or actions of the XML in any other way.

If a value isn't set in a given node, it will ask its parent.

Call C<unoob($key)> to remove an OOB value, or C<unoob()> to remove all OOB values on a node.

=cut

sub oob {
   my ($self, $key, $value) = @_;

   $self->{oob}->{$key} = $value if defined $value;
   $value = $self->{oob}->{$key};
   return $value if defined $value;
   return undef unless defined $self->{parent};
   return $self->{parent}->oob($key);
}
sub unoob {
   my ($self, $key) = @_;
   if (defined $key) {
      undef $self->{oob}->{$key};
   } else {
      undef $self->{oob};
   }
}

=head2 parent, ancestor, root

C<parent> returns the node's parent, if it has been attached to a parent, while C<ancestor> finds the ancestor with the tag you supply, or the root if you
don't give a tag. C<root> is provided as a shorthand for ancestor().

=cut
sub parent { reftype($_[0]) eq 'HASH' ? $_[0]->{parent} : undef }
sub root { $_[0]->ancestor }
sub ancestor {
   my ($self, $name) = @_;
   my $p = $self->parent;
   if (not defined $p) {
      return $self if not defined $name;
      return undef;
   }
   return $p if defined $name and $p->is($name);
   return $p->ancestor($name);
}

=head2 delete

Deletes a child from a node. Pass the actual reference to the child - or if you're using non-referenced text, the text itself.
(In this case, duplicate text will all be deleted.)

=cut

sub delete {
   my $self = shift;
   my $child = shift;
   my @children = $self->children;
   my @new_list = grep {$_ != $child} $self->children;
   $self->{children} = \@new_list;
}

=head2 detach

Detaches the node from its parent, if it is attached. This not only removes the parent reference, but also removes the child
from its parent's list of children.

=cut

sub detach {
   my $self = shift;
   return unless $self->{parent};
   $self->{parent}->delete($self);
   $self->{parent} = undef;
}


=head1 WORKING WITH ATTRIBUTES

Each tag in XML can have zero or more attributes, each of which has a value. Order is significant and preserved.

=head2 set, unset

The C<set> method sets one or more attributes; its parameter list is considered to be key, value, key, value, etc.
The C<unset> method removes one or more attributes from the list.

=cut
sub set {
   my $self = shift;

   my $value;
   while (@_) {
      my $key = shift;
      $value = shift;
      return $self->get($key) unless defined $value;
      push @{$self->{attrs}}, $key if !grep {$_ eq $key} @{$self->{attrs}};
      $self->{attrval}->{$key} = $value;
   }
   return $value;
}
sub unset {
   my ($self, $key) = @_;
   return unless defined $key;
   my @attributes = grep {$_ ne $key} @{$self->{attrs}};
   $self->{attrs} = \@attributes;
   $self->{attrval}->{$key} = undef;
}


=head2 get (attribute, default), attr_eq (attribute, value)

Obviously, C<get> retrieves an attribute value - specify a default value to be used if the attribute is not found,
otherwise returns undef.

Since it's inconvenient to test attributes that can be undefined, there's a C<attr_eq> method that checks that
the given attribute is defined I<and> equal to the value given.

=cut

sub get {
   my $self = shift;
   my $key  = shift;
   my $value = $self->{attrval}->{$key};
   return $value if defined $value;
   return shift;
}

sub attr_eq {
   my $self = shift;
   my $key = shift;
   my $value = $self->{attrval}->{$key};
   return undef unless defined $value;
   return 1 if $value eq shift;
}

=head2 attrs (attribute list)

The C<attrs> method retrieves a list of the attributes set.

=cut

sub attrs { reftype($_[0]) eq 'HASH' ? @{$_[0]->{attrs}} : () }

=head2 getlist (attribute list)

The C<getlist> method retrieves a list of attribute values given a list of attributes.
(It's just a map.)

=cut

sub getlist {
   my $self = shift;
   map { $self->get($_) } @_;
}

=head2 getctx (attribute, default)

The C<getctx> method looks at an attribute in the given node, but if it's not found, looks in the parent instead.
If there is no parent, the default value is returned.

=cut

sub getctx {
   my $self = shift;
   my $key = shift;
   my $default = shift;
   
   my $value = $self->get($key);
   return $value if defined $value;
   return $default unless defined $self->{parent};
   $self->{parent}->getctx($key, $default);
}

=head2 attr_order (attribute list)

Moves the named attributes to the front of the list; if any appear that aren't set, they stay unset.

=cut

sub attr_order {
   my $self = shift;
   
   my @list = @_;
   foreach my $a (@{$self->{attrs}}) {
      push @list, $a unless grep { $a eq $_ } @list;
   }
   $self->{attrs} = \@list;
}

=head1 WORKING WITH PLAIN TEXT CONTENT

Depending on your needs, XML::Snap can store plain text embedded in an XML structure as simple strings,
or as scalar references blessed to XML::Snap. Since text may therefore I<not> be blessed, you need
to handle it with care unless you're sure it's all references (by parsing with C<parse_with_refs>,
for instance).

=head2 istext

Returns a flag whether a given thing is text or not. "Text" means a scalar or a scalar reference; 
anything else will not be considered text.

This is a class method or an instance method - note that if you're using it as an instance method
and you try to call it on a string, your call will die.

=cut

sub istext {
   my $thing = shift;
   my $text = shift || $thing;
   return 1 unless ref($text);
   reftype ($text) eq 'SCALAR';
}

=head2 gettext

Returns the actual text of either a string (which is obviously just the string) or a scalar reference.
Again, can be called as an instance method if you're sure it's an instance.

=cut

sub gettext {
   my $thing = shift;
   my $text = shift || $thing;
   return $text unless ref $text;
   return undef unless reftype ($text) eq 'SCALAR';
   return $$text;
}

=head2 bless_text

Iterates through the node given, and converts all plain texts into referenced texts.

=cut

sub _bless_text {
   my $thing = shift;
   return $thing if ref($thing);
   my $r = \$thing;
   bless $r, 'XML::Snap';
   return $r;
}
sub bless_text {
   my $self = shift;
   my @children = map {_bless_text($_)} @{$self->{children}};
   $self->{children} = \@children;
   foreach my $child ($self->elements) {
      $child->bless_text;
   }
}

=head2 unbless_text

Iterates through the node given, and converts all referenced texts into plain texts.

=cut

sub _unbless_text {
   my $thing = shift;
   return $thing if not ref $thing;
   return $thing unless reftype($thing) eq 'SCALAR';
   return $$thing;
}
sub unbless_text {
   my $self = shift;
   my @children = map {_unbless_text($_)} @{$self->{children}};
   $self->{children} = \@children;
   foreach my $child ($self->elements) {
      $child->bless_text;
   }
}

=head1 WORKING WITH XML STRUCTURE

=head2 add, add_pretty

The C<add> method adds nodes and text as children to the current node. The C<add_pretty> method is a convenience
method that ensures that there is a line break if a node is inserted directly at the beginning of its parent
(this makes building human-readable XML easier).

In addition to nodes and text, you can also add a coderef. This will have no effect on normal operations except
for appearing in the list of children for the node, but during writing operations (either for string output or
to streams) the coderef will be called to retrieve an iterator that delivers XML snippets. Those snippets will be
inserted into the output as though they appeared at the point in the structure where the coderef appears.
Extraction from the iterator stops when it returns undef.

The next time the writer is used, the original coderef will be called again to retrieve a new iterator.

The writer functions (string, stringcontent, write, etc.) can be called with optional parameters that will be passed
to each coderef in the structure, if any. This allows an XML::Snap structure to be used as a generic template,
for example for writing XML structures extracted from database queries.

When adding a node that is already a child of another node, the source node will be copied into the target, not just
added.  (Otherwise confusion could ensue!)

Text is normally added as a simple string, but this can cause problems for consumers, as the output of an
iterator might then return a mixture of unblessed strings and blessed nodes, so you end up having to test for
blessedness when processing them. For ease of use, you can also add a I<reference> to a string; it will work
the same in terms of neighboring strings being coalesced, but they'll be stored as blessed string references.
Then, use istext or is_node to determine what each element is when iterating through structure.

=cut

sub add {
   my $self = shift;
   foreach my $child (@_) {
      my $r = ref $child;
      if (!$r) {
         my $last = ${$self->{children}}[-1];
         if (defined $last and istext($last)) {
            if (ref $last eq '') {
               ${$self->{children}}[-1] = $last . $child;
            } else {
               $$last .= $child;
            }
         } else {
            push @{$self->{children}}, $child;
         }
      } elsif ($r eq 'CODE') {
         push @{$self->{children}}, $child;
      } elsif ($r eq 'SCALAR') {
         my $copy = $child;
         bless $copy, ref $self;
         my $last = ${$self->{children}}[-1];
         if (defined $last and istext($last)) {
            $$copy = gettext($last) . $$copy;
            ${$self->{children}}[-1] = $copy;
         } else {
            push @{$self->{children}}, $copy;
         }
      } elsif ($child->can('parent')) {
         $child = $child->copy if defined $child->parent;
         $child->{parent} = $self;
         push @{$self->{children}}, $child;
      }
   }
}
sub add_pretty {
   my $self = shift;
   $self->add ("\n") if (!@{$self->{children}});
   foreach my $child (@_) {
      $self->add ($child, "\n");
   }
}

=head2 prepend, prepend_pretty

These do the same as C<add> and C<add_pretty> except at the beginning of the child list.

=cut
sub prepend {
   my $self = shift;
   foreach my $child (reverse @_) {
      my $r = ref $child;
      if (!$r) {
         my $first = ${$self->{children}}[0];
         if (defined $first and istext($first)) {
            if (ref $first eq '') {
               ${$self->{children}}[0] = $child . $first;
            } else {
               $$first = $child . $$first;
            }
         } else {
            unshift @{$self->{children}}, $child;
         }
      } elsif ($r eq 'CODE') {
         unshift @{$self->{children}}, $child;
      } elsif ($r eq 'SCALAR') {
         my $copy = $child;
         bless $copy, ref $self;
         my $first = ${$self->{children}}[0];
         if (defined $first and istext($first)) {
            $$copy = $$copy . gettext($first);
            ${$self->{children}}[0] = $copy;
         } else {
            unshift @{$self->{children}}, $copy;
         }
      } elsif ($child->can('parent')) {
         $child = $child->copy if defined $child->parent;
         $child->{parent} = $self;
         unshift @{$self->{children}}, $child;
      }
   }
}
sub prepend_pretty {
   my $self = shift;
   $self->prepend ("\n") if (!@{$self->{children}});
   foreach my $child (reverse @_) {
      $self->prepend ("\n", $child);
   }
}

=head2 replacecontent, replacecontent_from

The C<replacecontent> method first deletes the node's children, then calls C<add> to add its parameters.
Use C<replacecontent_from> to use the I<children> of the first parameter, with optional matches to effect
filtration as the rest of the parameters.

These are holdovers from my old xmlapi C library, where I was using in-memory XML structures as
"bags of data". Since Perl is basically built on bags of data to start with, I'm not sure these will
ever get used in a real situation (certainly I've never needed them yet in Perl).

=cut

sub replacecontent {
   my $self = shift;
   $self->{children} = [];
   $self->add(@_);
}
sub replacecontent_from {
   my $self = shift;
   my $from = shift;
   $self->{children} = [];
   $self->copy_from ($from, @_);
}

=head2 replace

The C<replace> method is a little odd; it actually acts on the given node's I<parent>, by replacing the callee
with the passed parameters. In other words, the parent's children list is modified directly. If there's nothing
provided as a replacement, this simply deletes the callee from its parent's child list.

=cut

sub replace {
   my $self = shift;
   my $parent = $self->{parent};
   return unless $parent;
   my @children = @{$parent->{children}};
   my $index = 0;
   my $count = scalar @children;
   $index++ until $children[$index] == $self or $index == $count;
   return if $index == $count;
   splice @children, $index, 1, @_;
   $parent->{children} = \@children;
}
         

=head2 children, elements

The C<children> method just returns the list of children added with C<add> (or the other addition-type methods).
The C<elements> method returns only those children that are elements, omitting text, comments, and generators.

=cut

sub children { reftype($_[0]) eq 'HASH' ? @{$_[0]->{children}} : () }
sub elements { return () unless reftype($_[0]) eq 'HASH';
               defined $_[1] ? grep { ref $_ && reftype($_) ne 'SCALAR' && $_->can('is') && $_->is($_[1]) } @{$_[0]->{children}}
                             : grep { ref $_ && reftype($_) ne 'SCALAR' && $_->can('parent') }              @{$_[0]->{children}}
             }

=head1 COPYING AND TRANSFORMATION

=head2 copy, copy_from, filter

The C<copy> method copies out a new node (recursively) that is independent, i.e. has no parent.
If you give it some matches of the form [name, key, value, coderef], then the coderef will be
called on the copy before it gets added, if the copy matches the match.
If a match is just a coderef, it'll apply to all text instead.

C<filter> is just an alias that's a little more self-documenting.

Note that the transformations specified will I<not> fire for the root node you're copying,
just its children.

=cut

sub filter { my $self = shift; $self->copy(@_); }
sub copy {
   my $self = shift;

   my $ret = XML::Snap->new ($self->name);
   foreach my $key ($self->attrs) {
      $ret->set ($key, $self->get ($key));
   }
   
   $ret->copy_from ($self, @_);
   return $ret;
}
sub copy_from {
   my $self = shift;
   my $other = shift;
   
   foreach my $child ($other->children) {
      if (ref $child eq 'CODE') {
         $self->add ($child);
      } elsif (not ref $child) {
         my $child_copy = $child;
         foreach (@_) {
            if (ref $_ eq 'CODE') {
               $child_copy = $_->($child_copy);
            }
         }
         $self->add ($child_copy);
      } elsif (reftype $child eq 'SCALAR') {
         my $child_copy = $$child;
         foreach (@_) {
            if (ref $_ eq 'CODE') {
               $child_copy = $_->($child_copy);
            }
         }
         $self->add (\$child_copy);
      } else {
         my $child_copy = $child->copy(@_);
         foreach (@_) {
            if (ref $_ eq 'ARRAY') {
               my @match = @$_;
               if (not defined $match[0] or $child_copy->is($match[0])) {
                  if (not defined $match[1] or $child->copy->get($match[1]) eq $match[2]) {
                     $child_copy = $match[3]->($child_copy);
                  }
               }
            }
         }
         $self->add ($child_copy);
      }
   }

   return $self;
}


=head1 STRING/FILE OUTPUT

The obvious thing to do with an XML structure once constructed is of course to write it to a file or extract a
string from it.  XML::Snap gives you one powerful option, which is the use of embedded generators to act as a
live template.

=head2 string, rawstring

Extracts a string from the XML node passed in; C<string> gives you an escaped string that can be parsed back
into an equivalent XML structure, while C<rawstring> does not escape anything, so you can't count on equivalence
or even legal XML. This is useful if your XML structure is being used to build strings, otherwise it's the wrong
tool to use.

=cut

sub _stringchild {
   my $self = shift;
   my $child = shift;
   
   return $self->escape ($child) unless ref $child;
   if (reftype ($child) eq 'SCALAR') {
      return $self->escape ($$child);
   }
   if (ref $child eq 'CODE') {
      my $generator = $child->($self);
      my @genreturn;
      my $ret = '';
      do {
         @genreturn = grep { defined $_ } ($generator->($self));
         foreach my $return (@genreturn) {
            $ret .= $self->_stringchild($return);
         }
      } while (@genreturn);
      return $ret;
   }
   return $child->string;
}

sub string {
   my $self = shift;
   return $$self if reftype($self) eq 'SCALAR';
   my $ret = '';

   $ret .= "<" . $self->name;
   foreach ($self->attrs) {
      $ret .= " $_=\"" . $self->escape($self->get($_)) . "\"";
   }

   my @children = $self->children;
   if (!@children) {
      $ret .= "/>";
   } else {
      $ret .= ">";
      foreach my $child (@children) {
         $ret .= $self->_stringchild ($child);
      }
      $ret .= "</" . $self->name . ">";
   }

   return $ret;
}


sub _rawstringchild {
   my $self = shift;
   my $child = shift;
   
   return $child unless ref $child;
   if (reftype ($child) eq 'SCALAR') {
      return $$child;
   }
   if (ref $child eq 'CODE') {
      my $generator = $child->($self);
      my @genreturn = ();
      my $ret = '';
      do {
         @genreturn = grep { defined $_ } ($generator->($self));
         foreach my $return (@genreturn) {
            $ret .= $self->_rawstringchild($return);
         }
      } while (@genreturn);
      return $ret;
   }
   return $child->string;
}
sub rawstring {
   my $self = shift;
   return $$self if reftype($self) eq 'SCALAR';

   my $ret = '';

   $ret .= "<" . $self->name;
   foreach ($self->attrs) {
      $ret .= " $_=\"" . $self->get($_) . "\"";
   }

   my @children = $self->children;
   if (!@children) {
      $ret .= "/>";
   } else {
      $ret .= ">";
      foreach my $child (@children) {
         $ret .= $self->_rawstringchild ($child);
      }
      $ret .= "</" . $self->name . ">";
   }

   return $ret;
}

=head2 content, rawcontent

These do the same, but don't include the parent tag or its closing tag in the string.

=cut

sub content {
   my $self = shift;
   return $$self if reftype($self) eq 'SCALAR';
   
   my $ret = '';
   foreach my $child ($self->children) {
      $ret .= $self->_stringchild ($child);
   }
   return $ret;
} # Boy, that's simpler than in the xmlapi version...
sub rawcontent {
   my $self = shift;
   return $$self if reftype($self) eq 'SCALAR';
   
   my $ret = '';
   foreach my $child ($self->children) {
      $ret .= $self->_rawstringchild ($child);
   }
   return $ret;
}


=head2 write

Given a filename, an optional prefix to write to the file, writes the XML
to a file.

=cut

sub write {
   my ($self, $f, $prefix) = @_;
   
   my $file;
   open $file, ">:utf8", $f or croak $!;
   print $file $prefix if defined $prefix;
   $self->writestream($file);
   close $file;
}


=head2 writestream

Writes the XML to an open stream.

=cut

sub _streamchild {
   my $self = shift;
   my $child = shift;
   my $file = shift;
   
   if (not ref $child) {
      print $file $self->escape ($child);
      return;
   }
   if (ref $child eq 'CODE') {
      my $generator = $child->($self);
      my @genreturn = ();
      my $ret = '';
      do {
         @genreturn = grep { defined $_ } ($generator->($self));
         foreach my $return (@genreturn) {
            $self->_streamchild($return, $file);
         }
      } while (@genreturn);
      return;
   }
   $child->writestream($file);
}

sub writestream {
   my $self = shift;
   my $file = shift;

   if ($self->istext) {
      print $file $self->escape ($self->gettext);
      return;
   }
   print $file "<" . $self->name;
   foreach ($self->attrs) {
      print $file " $_=\"" . $self->escape($self->get($_)) . "\"";
   }

   my @children = $self->children;
   if (!@children) {
      print $file "/>";
   } else {
      print $file ">";
      foreach my $child (@children) {
         $self->_streamchild ($child, $file);
      }
      print $file "</" . $self->name . ">";
   }
}


=head2 escape/unescape

These are convenience functions that escape a string for use in XML, or unescape the escaped string for non-XML use.

=cut

sub escape {
   my ($whatever, $str) = @_;

   $str =~ s/&/&amp;/g;
   $str =~ s/</&lt;/g;
   $str =~ s/>/&gt;/g;
   $str =~ s/\"/&quot;/g;
   return $str;
}
sub unescape {
   my ($whatever, $ret) = @_;
   
   $ret =~ s/&lt;/</g;
   $ret =~ s/&gt;/>/g;
   $ret =~ s/&quot;/"/g;
   $ret =~ s/&amp;/&/g;
   return $ret;
}

=head1 BOOKMARKING AND SEARCHING

Finally, there are searching and bookmarking functions for finding and locating given XML in a tree.

=head2 getloc

Retrieves a location for a given node in its tree, effectively a bookmark. The rules are simple.
The bookmark consists of a set of dotted pairs, each being the name of the tag plus a disambiguator
if necessary. If the tag is the first of its sibs with its own tag, no disambiguator is necessary.
If the tag has an attribute named 'id' that doesn't have a dot or square brackets in it, then
square brackets surrounding that value are used as the disambiguator. Otherwise, a number in
parentheses identifies the sequence of the tag within the list of siblings with its own tag name.

So C<mytag[one]> matches C<mytag id="one"> and C<mytag(1)> matches the second 'mytag' in its
parent's list of elements. C<mytag[one].next(3)> matches the fourth 'next' in C<mytag id="one">.

This is essentially a much simplified XMLpath (I may be wrong, but I think I came up with it
before XMLpaths had been defined). It's quick and dirty, but works.

=cut

sub getloc {
   my $self = shift;
   my $parent = $self->parent;
   return '' unless $parent;
   my $ploc = $self->parent->getloc;
   $ploc .= '.' if $ploc;

   my $name = $self->name;
   my $id = $self->get('id');
   if (defined $id and not $id =~ /[\.\[\]]/) {
      my $t = $name . "[$id]";
      my $try = $parent->loc($t);
      return $ploc . $t if $try == $self;
   }
   my $try = $parent->first($name);
   return $ploc . $name if $try == $self;
   my $count = 0;
   foreach my $try ($parent->elements($name)) {
      return $ploc . "$name($count)" if $try == $self;
      $count++;
   }
   # We shouldn't ever get here; returns undef but we might consider croaking.
}


=head2 loc

Given such a bookmark and the tree it pertains to, finds the bookmarked node.

=cut

sub loc {
   my $self = shift;
   my $l = shift;
   return $self unless $l;
   if ($l =~ /\./) {
      @_ = (split (/\s*\.\s*/, $l), @_);
      $l = shift;
   }
   my $target;
   if ($l =~ /\s*(.*)\s*\[(.*)\]\s*/) {
      my ($tag, $id) = ($1, $2);
      foreach my $child ($self->elements($tag)) {
         if ($child->attr_eq ('id', $id)) {
            $target = $child;
            last;
         }
      }
   } elsif ($l =~ /(.*)\((\d*)\)\s*/) {
      my ($tag, $count) = ($1, $2);
      foreach my $child ($self->elements($tag)) {
         $target = $child unless $count;
         $count--;
      }
   } else {
      my @children = $self->elements($l);
      $target = $children[0] if @children;
   }
   return undef unless defined $target;
   return $target unless @_;
   $target->loc(@_);
}

=head2 all

Returns a list of XML snippets that meet the search criteria.

=cut

sub _test_item {
   my ($self, $name, $attr, $val) = @_;
   return 0 unless not defined $name or $self->is($name);
   return 1 unless defined $attr;
   return $self->attr_eq ($attr, $val);
}

sub all {
   my ($self, $name, $attr, $val) = @_;
   my @retlist = ();
   foreach my $child ($self->elements) {
      push @retlist, $child if $child->_test_item($name, $attr, $val);
      push @retlist, $child->all ($name, $attr, $val);
   }
   return @retlist;
}

=head1 WALKING THE TREE

XML is a tree structure, and what do we do with trees? We walk them!

A walker is an iterator that visits each node in turn, then its children, one by one. Walkers come in two flavors:
full walk or element walk; the element walk ignores text.

The walker constructor optionally takes a closure that will be called on each node before it's returned; the return
from that closure will be what's returned. If it returns undef, the walk will skip that node and go on with the
walk in the same order that it otherwise would have; if it returns a list of C<(value, 'prune')> then the walk will
not visit that node's children, and "value" will be taken as the return value (and it can obviously be undef as well).

=cut

=head2 walk

C<walk> is the complete walk. It returns an iterator.  Pass it a closure to be called on each node as it's visited.
Modifying the tree's structure is entirely fine as long as you're just manipulating the children of the current node;
if you do other things, the walker might get confused.

=cut

sub walk {
    my $xml = shift;
    my @coord = ('-');
    my @stack = ($xml);
    my $process = shift;

    return sub {
        my $retval;
        my $action;
        AGAIN:
        return undef unless @stack;
        if ($coord[-1] eq '-') {
            ($retval, $action) = $process ? $process->($stack[-1]) : $stack[-1];
            $coord[-1] = 0;
            if (defined $action and $action eq 'prune') {
               $coord[-1] = '*';
            }
        } else {
            my @c = ref $stack[-1] ? $stack[-1]->children : ();
            if ($coord[-1] eq '*' or $coord[-1] >= @c) {
                pop @coord;
                pop @stack;
                return undef unless @stack;
                $coord[-1]++;
                goto AGAIN;
            }
            push @stack, $c[$coord[-1]];
            push @coord, '-';
            goto AGAIN;
        }
        goto AGAIN unless defined $retval;
        $retval;
    }
}

=head2 walk_elem

For the sake of convenience, C<walk_elem> does the same thing, except it only visits nodes, not text.

=cut

sub walk_elem {
    my $xml = shift;
    my @coord = ('-');
    my @stack = ($xml);
    my $process = shift;

    return sub {
        my $retval;
        my $action;
        AGAIN:
        return undef unless @stack;
        if ($coord[-1] eq '-') {
            ($retval, $action) = $process ? $process->($stack[-1]) : $stack[-1];
            $coord[-1] = 0;
            if (defined $action and $action eq 'prune') {
               $coord[-1] = '*';
            }
        } else {
            my @c = ref $stack[-1] ? $stack[-1]->elements : ();
            if ($coord[-1] eq '*' or $coord[-1] >= @c) {
                pop @coord;
                pop @stack;
                return undef unless @stack;
                $coord[-1]++;
                goto AGAIN;
            }
            push @stack, $c[$coord[-1]];
            push @coord, '-';
            goto AGAIN;
        }
        goto AGAIN unless defined $retval;
        $retval;
    }
}

=head2 walk_all

A simplified walk that simply returns matching nodes.

    my $w = $self->{body}->walk(sub {
        my $node = shift;
        return ($node, 'prune') if $node->is('trans-unit'); # Segments are returned whole.
        return undef; # We don't want the details for anything else, but still walk into its children if it has any.
    });



=head2 first

Returns the first XML element (i.e. non-node thing) that meets the search criteria.

=cut

sub first {
   my ($self, $name, $attr, $val) = @_;
   foreach my $child ($self->children) {
      next unless ref($child) and reftype($child) ne 'SCALAR';
      next if ref($child) eq 'CODE';
      return $child if $child->_test_item($name, $attr, $val);
      my $ret = $child->first ($name, $attr, $val);
      return $ret if defined $ret;
   }
   return;
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-snap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Snap>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Snap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Snap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Snap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Snap>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Snap/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of XML::Snap
