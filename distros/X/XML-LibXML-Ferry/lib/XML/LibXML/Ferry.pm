=encoding utf-8

=head1 NAME

XML::LibXML::Ferry - Marshall LibXML nodes and native objects

=head1 SYNOPSIS

	use XML::LibXML::Ferry;  # Implies use XML::LibXML

=head1 DESCRIPTION

Adds higher-level methods to L<XML::LibXML::Element> to very expressively
traverse and create XML fragments to/from your custom objects.

=cut

# Nothing but $VERSION actually goes here
package XML::LibXML::Ferry;

use 5.006;
use strict;
use warnings;
use Scalar::Util qw(blessed);

use XML::LibXML;

BEGIN {
	our $VERSION = 'v0.8.5';
}

=head1 METHODS

=over

=item C<B<XML::LibXML::Element::attr>( [I<%attributes>] )>

If I<C<%attributes>> is not empty: each key/value pair is added/replaced in
the element.  Undefined values are skipped.  Returns the element itself, for
possible chaining.

If I<C<%attributes>> is missing/empty: returns a hashref of all of the
element's attributes (although that is redundant with simply using the element
as a hashref directly, as explained in L<XML::LibXML::Element/OVERLOADING>).

=cut

sub XML::LibXML::Element::attr {
	my ($self, %attrs) = @_;
	if (%attrs) {
		foreach (keys %attrs) {
			$self->setAttribute($_, $attrs{$_}) if defined $attrs{$_};
		};
		return $self;
	} else {
		return \%$self;
	};
}

=item C<B<XML::LibXML::Element::create>( I<$name>, [I<$text>], [I<%attributes>] )>

Create a stand-alone element named I<C<$name>> with I<C<%attributes>> set, in
the same document as the current element.

To create an element with attributes but no text content, specify an undefined
I<C<$text>>.

Returns the new element.

=cut

sub XML::LibXML::Element::create {
	my ($self, $name, $text, %attrs) = @_;
	my $el = $self->ownerDocument->createElement($name);
	$el->appendTextNode($text) if defined $text;
	return %attrs ? $el->attr(%attrs) : $el;
}

=item C<B<XML::LibXML::Element::add>( I<$name>, [I<$text>], [I<%attributes>] )>

Wrapper around L</XML::LibXML::Element::create()>, which also appends the new
element to the children of the current element.  Returns the new element.

=item C<B<XML::LibXML::Element::add>( I<$node> )>

With an element as its only argument, convenience wrapper for
S<C<<<< $node->appendChild() >>>>>.

=cut

sub XML::LibXML::Element::add {
	my ($self, $name, $text, %attrs) = @_;
	if (ref $name) {
		$self->appendChild($name);
		return $name;
	};
	my $el = $self->create($name, $text, %attrs);
	$self->appendChild($el);
	return $el;
};

=item C<B<XML::LibXML::Node::textNodeContent>()>

Iterate through each of the element's immediate children and create a string
from text nodes found.  The result is stripped of leading and trailing
whitespace.

=cut

sub XML::LibXML::Node::textNodeContent {
	my ($self) = @_;
	my $text = '';
	foreach ($self->childNodes) {
		$text .= $_->textContent if ($_->nodeType == XML_TEXT_NODE);
	};
	$text =~ s/^\s+|\s+$//g;
	return $text;
}

=item C<B<XML::LibXML::Element::ferry>( I<$obj>, [I<$exceptions>] )>

Iterate through each of the element's attributes (including namespaced ones),
then each of its child nodes.

The lowercased attribute or node name is matched against I<C<$obj>>'s methods.
Without a match, a second try is made with an append C<s>.  With still no
match, the same two names are matched against I<C<$obj>>'s hash keys.  With
still no match, the value is ignored.

If we matched a method, it is passed the attribute's text or node's text
content as single argument.  (Or your subroutine results or new class
instance, see below.)  If we matched a direct hash key, it is overwritten with
that new content, or if the existing hash value is an arrayref, the new
content is pushed to it instead.

I<C<$exceptions>> is a hashref associating attributes and child node names
with one of three possible types:

=over

=item B<String property name>

Alternative method/key name to use instead of the lowercased, possibly plural
form of the attribute/node name.  Great for shortening verbose names in your
API.

Since non-existent property names are safely ignored, you can make sure that a
node or attribute will be ignored by specifying an unknown name.  To keep
Ferry-using code consistent and explicit, parts of the DTD you're working
with, but which you are not implementing, should be set to C<__UNIMPLEMENTED>,
parts which are ignored because they are obsolete to C<__OBSOLETE> and parts
which are skipped for any other reason to C<__IGNORE>.

=item B<Arrayref>

Two items are expected:

=over 4

=item B<String property name>

As above, alternative name.

=item B<Subroutine reference> OR B<String class name>

If a subroutine is given, it is called with two arguments: I<C<$obj>> and the
current XML node I<or> attribute string.  If your subroutine returns
something, it will be used as the value to save.  It is thus impossible to
store C<undef> by returning it.  Note that if a subroutine is associated with
an unknown property name (i.e. C<__IGNORE>), it will still be invoked and its
return value ignored, which is useful for cases where you have nothing
meaningful to return.

If a class name is given, a new instance of it is created with:
S<C<<<< $classname->new($val) >>>>>
where I<C<$val>> is either an attribute's string content or a
L<XML::LibXML::Element>.  The created object will be used as the value to
save.  This is key to allow creating various classes representing different
parts of a DTD: with each class creator internally calling
S<C<<<< $node->ferry(...) >>>>>,
one can end up with any arbitrary structure matching that of the XML document.

=back

=item B<Hashref>

Recursion: the hashref will be treated like I<C<$exceptions>> into the
I<current> I<C<$obj>>.  This is useful to flatten small but deep structures
without having to use multiple classes.  An empty hashref still triggers this
behavior.

=back

Optional key C<__text> should contain a property name.  This is necessary for
getting the direct text content of a node along with any attributes.

Optional key C<__meta_name> alters the above behavior slightly: the element
being processed is handled like a key-value tag.  (Like HTML's C<META> or
cXML's C<Extrinsic>.)  The key to search in I<C<$exceptions>> will be the
content of its attribute named in C<__meta_name> instead of its C<nodeName>.
So a hypothetical
S<C<<<< <meta property="foo">bar</meta> >>>>>
with a meta name C<property> would be treated as if it actually were
S<C<<<< <foo>bar</foo> >>>>>
.

Optional key C<__meta_content> works in conjunction with C<__meta_name> above,
and adds that the value will also come from the specified attribute.  For
example, a meta name C<property> and content C<value> would treat
S<C<<<< <meta property="foo" value="bar">ignored</meta> >>>>>
as if it actually were
S<C<<<< <foo>bar</foo> >>>>>
.

See L</EXAMPLES> for a detailed example.

=cut

sub XML::LibXML::Element::ferry {
	my ($self, $obj, $ex) = @_;

	# Reduce various key/value sources down to a single list.
	#
	# Because some targets can be opaque methods or arrayrefs, we allow
	# multiple keys, hence the use of a 2D array instead of a hash.
	#
	# Each item is an ARRAYREF:
	# [0] - Raw input attribute/node name
	# [1] - String content or XML::LibXML::Element child
	my @store;
	if (exists $ex->{__meta_name}) {
		# Process as a single META tag, ignoring other attributes
		push @store, [
			$self->{ $ex->{__meta_name} },
			(defined $ex->{__meta_content} ? $self->{ $ex->{__meta_content} } : $self),
		];
	} else {
		push @store, [ $_,            $self->{$_}            ] foreach (%$self);
		push @store, [ $_->nodeName,  $_                     ] foreach ($self->childNodes);
		push @store, [ $ex->{__text}, $self->textNodeContent ] if exists $ex->{__text};
		# Namespaced attributes we're explicitly looking for
		# (XML::LibXML::AttributeHash uses Clark notation.)
		foreach (grep { /:/ } keys %{ $ex }) {
			push @store, [ $_, $self->getAttribute($_) ] if $self->hasAttribute($_);
		};
	};

	# Process each key/value found
	foreach (@store) {
		my ($key, $val) = @{ $_ };
		my $sub = undef;

		# Rename key, identify SUBREF, recurse HASHREFs
		if (exists $ex->{ $key }) {
			my $e = $ex->{ $key };
			if (ref($e) eq 'ARRAY') {
				$key = $e->[0];  # Override key
				$sub = $e->[1];  # SUBREF or class name string
			} elsif (ref($e) eq 'HASH') {
				# Safely ignore the invalid case of setting a HASHREF on an attribute key
				$val->ferry($obj, $e) if ref($val);  #  <-- RECURSION
				next;
			} else {
				$key = $e;  # Override key
			};
		} else {
			$key = lc($key);
		};

		# Reduce value to a string through SUB or textNodeContent()
		if (ref $sub) {
			$val = $sub->($obj, $val);
		} elsif ($sub) {
			my $file = $sub;
			$file =~ s|::|/|g;
			require "$file.pm";
			$val = $sub->new($val);  # No eval: we want this to fail if the class doesn't exist
		} else {
			$val = $val->textNodeContent if ref($val);
		};

		# Save value if it wasn't eaten up by SUB
		if (defined $val) {
			my $m = $key;
			$m .= 's' unless blessed($obj) && $obj->can($m);
			if (blessed($obj) && $obj->can($m)) {
				$obj->$m($val);
			} else {
				$key .= 's' unless exists $obj->{$key};
				if (exists $obj->{$key}) {
					if (ref($obj->{$key}) eq 'ARRAY') {
						push @{ $obj->{$key} }, $val;
					} else {
						$obj->{$key} = $val;
					};
				};
			};
		};

	};
}

=item C<B<XML::LibXML::Element::toHash>()>

Convert an XML element tree into a recursive hash.  Each attribute is in a key
C<__attributes> and each child node is recursively put in an array in its
name.  Key C<__text> contains the merged text nodes directly in the element,
with intial and trailing whitespace stripped.

The resulting format is a bit verbose, but ideal for using L<Test::Deep> to
compare XML fragments and for quick inspections.  (See L</EXAMPLES>.)

=cut

sub XML::LibXML::Element::toHash {
	my ($self) = @_;
	my $hash = { __attributes => {} };

	# Grab attributes
	$hash->{__attributes}{$_} = $self->{$_} foreach (keys %$self);

	# Grab childNodes
	if ($self->hasChildNodes) {
		foreach ($self->childNodes) { 
			if ($_->nodeType == XML_ELEMENT_NODE) {
				$hash->{$_->nodeName} = [] unless exists $hash->{$_->nodeName};
				my $newhash = $_->toHash;
				push(@{ $hash->{$_->nodeName} }, $newhash);
			};
		};
	};
	$hash->{__text} = $self->textNodeContent;
	return $hash;
}

=item C<B<XML::LibXML::Document::toHash>()>

Convenience wrapper which invokes L<XML::LibXML::Element::toHash()> above on
the document's C<documentElement>.

=cut

sub XML::LibXML::Document::toHash {
	my ($self) = @_;
	return $self->documentElement->toHash;
}

=back

=head1 EXAMPLES

B<ferry():>

Given the following XML fragment as I<C<$root>>, an L<XML::LibXML::Element>:

	<Example weirdName="test-example">
		<Attribute name="location">1234 Main St</Attribute>
		<Attribute name="phone">1-800-555-1212</Attribute>
		<Bars>
			<Bar name="first bar">
				<Description>
					<Text>This is the first bar!</Text>
				</Description>
			</Bar>
			<Bar>
				<Description>
					<Text>The second bar is unnamed.</Text>
				</Description>
			</Bar>
		</Bars>
	</Example>

We could write the following to clearly map C<Example> to a C<Mystuff::Thingy>
also containing some C<Mystuff::Otherthing>s:

	use XML::LibXML::Ferry;

	my $thing = new Mystuff::Thing 'thingy', $root;

	package Mystuff::Thing
	sub new {
		my ($class, $name, $node) = @_;
		my $self = {
			foo          => undef,
			location     => undef,
			phone_number => undef,
			bar          => [],
		};
		bless $self, $class;
		$node->ferry($self, {
			__attributes => {
				weirdName => 'foo',
			},
			Attribute => {
				__meta_name => 'name',
				# 'location' will implicitly match our property
				phone       => 'phone_number',
			},
			Bars => {
				Bar => [ 'bars', 'Mystuff::Otherthing' ],
			},
		});
		return $self;
	}

	package Mystuff::Otherthing;
	sub new {
		my ($class, $name, $node) = @_;
		my $self = {
			name        => undef,
			description => undef,
		};
		bless $self, $class;
		$node->ferry($self, {
			# Attribute 'name' will implicitly match our property
			Description => {
				Text => 'description',
			},
		});
		return $self;
	}

This would make I<C<$thing>> contain:

	$VAR1 = bless( {
		'foo' => 'test-example',
		'location' => '1234 Main St',
		'phone_number' => '1-800-555-1212',
		'bar' => [
			bless( {
				'name' => 'first bar',
				'description' => 'This is the first bar!'
			}, 'Mystuff::Otherthing' ),
			bless( {
				'name' => undef,
				'description' => 'The second bar is unnamed.'
			}, 'Mystuff::Otherthing' )
		],
	}, 'Mystuff::Thing' );







B<toHash():>

Given the following XML fragment:

	<Example weirdName="test-example">
		<Attribute name="location">1234 Main St</Attribute>
		<Attribute name="phone">1-800-555-1212</Attribute>
	</Example>

L</toHash()> would return:

	$VAR1 = {
		'__attributes' => {
			'weirdName' => 'test-example',
		},
		'Attribute' => [
			{
				'__attributes' => {
					'name' => 'location',
				},
				'__text' => '1234 Main St',
			},
			{
				'__attributes' => {
					'name' => 'phone',
				},
				'__text' => '1-800-555-1212',
			},
		],
	};

=head1 AUTHOR

Stéphane Lavergne L<https://github.com/vphantom>

=head1 ACKNOWLEDGEMENTS

Graph X Design Inc. L<https://www.gxd.ca/> sponsored this project.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2017-2018 Stéphane Lavergne L<https://github.com/vphantom>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;
