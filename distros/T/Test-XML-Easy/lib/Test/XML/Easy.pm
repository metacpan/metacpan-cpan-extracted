package Test::XML::Easy;

use strict;
use warnings;

use vars qw(@EXPORT @ISA);
use Exporter;
@ISA = qw(Exporter);

our $VERSION = '0.01';

use Carp qw(croak);

use XML::Easy::Text qw(xml10_read_document xml10_write_document);
use XML::Easy::Classify qw(is_xml_element);
use XML::Easy::Syntax qw($xml10_s_rx);

use Test::Builder;
my $tester = Test::Builder->new();

=head1 NAME

Test::XML::Easy - test XML with XML::Easy

=head1 SYNOPSIS

    use Test::More tests => 2;
    use Test::XML::Easy;

    is_xml $some_xml, <<'ENDOFXML', "a test";
    <?xml version="1.0" encoding="latin-1">
    <foo>
       <bar/>
       <baz buzz="bizz">fuzz</baz>
    </foo>
    ENDOFXML

    is_xml $some_xml, <<'ENDOFXML', { ignore_whitespace => 1, description => "my test" };
    <foo>
       <bar/>
       <baz buzz="bizz">fuzz</baz>
    </foo>
    ENDOFXML

    isnt_xml $some_xml, $some_xml_it_must_not_be;

    is_well_formed_xml $some_xml;

=head1 DESCRIPTION

A simple testing tool, with only pure Perl dependancies, that checks if
two XML documents are "the same".  In particular this module will check if
the documents schemantically equal as defined by the XML 1.0 specification
(i.e. that the two documents would construct the same DOM
model when parsed, so things like character sets and if you've used two tags
or a self closing tags aren't important.)

This modules is a strict superset of B<Test::XML>'s interface, meaning if you
were using that module to check if two identical documents were the same then
this module should function as a drop in replacement.  Be warned, however,
that this module by default is a lot stricter about how the XML documents
are allowed to differ.

=head2 Functions

This module, by default, exports a number of functions into your namespace.

=over

=item is_xml($xml_to_test, $expected_xml[, $options_hashref])

Tests that the passed XML is "the same" as the expected XML.

XML can be passed into this function in one of two ways;  Either you can
provide a string (which the function will parse for you) or you can pass in
B<XML::Easy::Element> objects that you've constructed yourself somehow.

This funtion takes several options as the third argument.  These can be
passed in as a hashref:

=over

=item description

The name of the test that will be used in constructing the C<ok> / C<not ok>
test output.

=item ignore_whitespace

Ignore many whitespace differences in text nodes.  Currently
this has the same effect as turning on C<ignore_surrounding_whitespace>
and C<ignore_different_whitespace>.

=item ignore_surrounding_whitespace

Ignore differences in leading and trailing whitespace
between elements.  This means that

  <p>foo bar baz</p>

Is considered the same as

  <p>
    foo bar baz
  </p>

And even

  <p>
    this is my cat:<img src="http://myfo.to/KsSc.jpg" />
  </p>

Is considered the same as:

  <p>
    this is my cat: <img src="http://myfo.to/KsSc.jpg" />
  </p>

Even though, to a web-browser, that extra space is significant whitespace
and the two documents would be renderd differently.

However, as comments are completely ignored (we treat them as if they were
never even in the document) the following:

  <p>foo<!-- a comment -->bar</p>

would be considered different to

  <p>
    foo
    <!-- a comment -->
    bar
  </p>

As it's the same as comparing the string

  "foobar"

And:

    "foo
    
    bar"

The same is true for processing instructions and DTD declarations.

=item ignore_leading_whitespace

The same as C<ignore_surrounding_whitespace> but only ignore
the whitespace immediately after an element start or end tag not
immedately before.

=item ignore_trailing_whitespace

The same as C<ignore_surrounding_whitespace> but only ignore
the whitespace immediately before an element start or end tag not
immedately after.

=item ignore_different_whitespace

If set to a true value ignores differences in what characters
make up whitespace in text nodes.  In other words, this option
makes the comparison only care that wherever there's whitespace
in the expected XML there's any whitespace in the actual XML
at all, not what that whitespace is made up of.

It means the following

  <p>
    foo bar baz
  </p>

Is the same as

  <p>
    foo
    bar
    baz
  </p>

But not the same as

  <p>
    foobarbaz
  </p>

This setting has no effect on attribute comparisons.

=item verbose

If true, print obsessive amounts of debug info out while
checking things

=item show_xml

This prints out in the diagnostic messages the expected and
actual XML on failure.

=back

If a third argument is passed to this function and that argument
is not a hashref then it will be assumed that this argument is
the the description as passed above.  i.e.

  is_xml $xml, $expected, "my test";

is the same as

  is_xml $xml, $expected, { description => "my test" };

=cut

sub is_xml($$;$) {
  my $got = shift;
  my $expected = shift;

  unless (defined $expected) {
    croak("expected argument must be defined");
  }

  # munge the options

  my $got_original      = $got;
  my $expected_original = $expected;

  my $options = shift;
  $options = { description => $options } unless ref $options eq "HASH";
  $options = { %{$options}, description => "xml test" } unless defined $options->{description};
  unless (is_xml_element($expected)) {
    # throws an exception if there isn't a problem.
    $expected = eval { xml10_read_document($expected) };
    if ($@) {
      croak "Couldn't parse expected XML document: $@";
    }
  }

  # convert into something useful if needed
  unless (is_xml_element($got)) {
    my $parsed = eval { xml10_read_document($got) };
    if ($@) {
      $tester->ok(0, $options->{description});
      $tester->diag("Couldn't parse submitted XML document:");
      $tester->diag("  $@");
      return;
    }

    $got = $parsed;
  }

  if(_is_xml($got,$expected,$options,"", {})) {
    $tester->ok(1,$options->{description});
    return 1;
  }

  if ($options->{show_xml}) {
    $tester->diag("The XML that we expected was:");
    if (is_xml_element($expected_original))
      { $tester->diag(xml10_write_document($expected_original)) }
    else
      { $tester->diag($expected_original) }

    $tester->diag("The XML that we received was:");
    if (is_xml_element($got_original))
      { $tester->diag(xml10_write_document($got_original)) }
    else
      { $tester->diag($got_original) }
  }

  return;
}
push @EXPORT, "is_xml";

sub _is_xml {
  my $got = shift;
  my $expected = shift;
  my $options  = shift;

  # this is the path
  my $path     = shift;

  # the index is used to keep track of how many of a particular
  # typename of a particular element we've seen as previous siblings
  # of the node that just got in.  It's a hashref with type_name and
  # the index.
  my $index    = shift;

  # change where the errors are reported from
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  # work out the details of the node we're looking at
  # nb add one to the index because xpath is weirdly 1-index
  # not 0-indexed like most other modern languages
  my $got_name       = $got->type_name();
  my $got_index      = ($index->{ $got_name } || 0) + 1;

  ### check if we've got a node to compare to

  unless ($expected) {
    $tester->ok(0, $options->{description});
    $tester->diag("Element '$path/$got_name\[$got_index]' was not expected");
    return;
  }

  ### check the node name

  # work out the details of the node we're comparing with
  my $expected_name  = $expected->type_name();
  my $expected_index = ($index->{ $expected_name } || 0) + 1;

  # alter the index hashref to record we've seen another node
  # of this name
  $index->{$got_name}++;

  $tester->diag("comparing '$path/$got_name\[$expected_index]' to '$path/$expected_name\[$expected_index]'...") if $options->{verbose};

  if ($got_name ne $expected_name) {
    $tester->ok(0, $options->{description});
    $tester->diag("Element '$path/$got_name\[$got_index]' does not match '$path/$expected_name\[$expected_index]'");
    return;
  }
  $tester->diag("...matched name") if $options->{verbose};

  ### check the attributes

  # we're not looking at decendents, so burn the path of
  # this node into the path we got passed in
  $path .= "/$got_name\[$got_index]";

  # XML::Easy returns read only data structures
  # we want to modify these to keep track of what
  # we've processed, so we need to copy them
  my %got_attr      = %{ $got->attributes };
  my $expected_attr = $expected->attributes;

  foreach my $attr (keys %{ $expected_attr }) {
    $tester->diag("checking attribute '$path/\@$attr'...") if $options->{verbose};

    if (!exists($got_attr{$attr})) {
      $tester->ok(0, $options->{description});
      $tester->diag("expected attribute '$path/\@$attr' not found");
      return;
    }
    $tester->diag("...found attribute") if $options->{verbose};

    my $expected_string = $expected_attr->{$attr};
    my $got_string      = delete $got_attr{$attr};

    if ($expected_string ne $got_string) {
      $tester->ok(0, $options->{description});
      $tester->diag("attribute value for '$path/\@$attr' didn't match");
      $tester->diag("found value:\n");
      $tester->diag("  '$got_string'\n");
      $tester->diag("expected value:\n");
      $tester->diag("  '$expected_string'\n");
      return;
    }
    $tester->diag("...the attribute contents matched") if $options->{verbose};
  }
  if (keys %got_attr) {
    $tester->ok(0, $options->{description});
    $tester->diag("found extra unexpected attribute".(keys %got_attr>1 ? "s":"").":");
    $tester->diag("  '$path/\@$_'") foreach sort keys %got_attr;
    return;
  }
  $tester->diag("the attributes all matched") if $options->{verbose};

  ### check the child nodes

  # create a new index to pass to our children distint from
  # the index that was passed in to us (as that one was created
  # by our parent for me and my siblings)
  my $child_index = {};

  # grab the child text...element...text...element...text...
  my $got_content      = $got->content;
  my $expected_content = $expected->content;

  # step though the text/elements
  # nb this loop works in steps of two;  The other $i++
  # is half way through the loop below
  for (my $i = 0; $i < @{$got_content}; $i++) {

    ### check the text node

    # extract the text from the object
    my $got_text      = $got_content->[ $i ];
    my $expected_text = $expected_content->[ $i ];
    my $comp_got_text      = $got_text;
    my $comp_expected_text = $expected_text;

    if ($options->{ignore_whitespace} || $options->{ignore_leading_whitespace} || $options->{ignore_surrounding_whitespace}) {
      $comp_got_text =~ s/ \A (?:$xml10_s_rx)* //x;
      $comp_expected_text =~ s/ \A (?:$xml10_s_rx)* //x;
    }

    if ($options->{ignore_whitespace} || $options->{ignore_trailing_whitespace} || $options->{ignore_surrounding_whitespace}) {
      $comp_got_text =~ s/ (?:$xml10_s_rx)* \z//x;
      $comp_expected_text =~ s/ (?:$xml10_s_rx)* \z//x;
    }

    if ($options->{ignore_whitespace} || $options->{ignore_different_whitespace}) {
      $comp_got_text =~ s/ (?:$xml10_s_rx)+ / /gx;
      $comp_expected_text =~ s/ (?:$xml10_s_rx)+ / /gx;
    }

    if ($comp_got_text ne $comp_expected_text) {

      $tester->ok(0, $options->{description});

      # I don't like these error message not being specific with xpath but as
      # far as I know  there's no easy way to express in xpath the text immediatly following
      # a particular element.  The best I could come up with was this mouthful:
      # "$path/following-sibling::text()[ previous-sibling::*[1] == $path ]"

      if ($i == 0) {
        if (@{ $got_content } == 1 && @{ $expected_content } == 1) {
          $tester->diag("text inside '$path' didn't match");
        } else {
          $tester->diag("text immediately inside opening tag of '$path' didn't match");
        }
      } elsif ($i == @{ $got_content} - 1 && $i == @{ $expected_content } - 1 ) {
        $tester->diag("text immediately before closing tag of '$path' didn't match");
      } else {
        my $name = $got_content->[ $i - 1 ]->type_name;
        my $ind = $child_index->{ $name };
        $tester->diag("text immediately after '$path/$name\[$ind]' didn't match");
      }

      $tester->diag("found:\n");
      $tester->diag("  '$got_text'\n");
      $tester->diag("expected:\n");
      $tester->diag("  '$expected_text'\n");

      if ($options->{verbose}) {
        $tester->diag("compared found text:\n");
        $tester->diag("  '$comp_got_text'\n");
        $tester->diag("against text:\n");
        $tester->diag("  '$comp_expected_text'\n");
      }

      return;
    }

    # move onto the next (elemnent) node if we didn't reach the end
    $i++;
    last if $i >= @{$got_content};

    ### check the element node

    # simply recurse for that node
    # (don't bother checking if the expected node is defined or not, the case
    # where it isn't is handled at the start of _is_xml)
    return unless _is_xml(
      $got_content->[$i],
      $expected_content->[$i],
      $options,
      $path,
      $child_index
    );
  }

  # check if we expected more nodes
  if (@{ $expected_content } > @{ $got_content }) {
    my $expected_nom = $expected_content->[ scalar @{ $got_content } ]->type_name;
    my $expected_ind = $child_index->{ $expected_nom } + 1;
    $tester->diag("Couldn't find expected node '$path/$expected_nom\[$expected_ind]'");
    $tester->ok(0, $options->{description});
    return;
  }

  return 1;
}

=item isnt_xml($xml_to_test, $not_expected_xml[, $options_hashref])

Exactly the same as C<is_xml> (taking exactly the same options) but passes
if and only if what is passed is different to the not expected XML.

By different, of course, we mean schematically different according to the
XML 1.0 specification.  For example, this will fail:

  isnt_xml "<foo/>", "<foo></foo>";

as those are schematically the same XML documents.

However, it's worth noting that the first argument doesn't even have to be
valid XML for the test to pass.  Both these pass as they're not schemantically
identical to the not expected XML:

  isnt_xml undef, $not_expecteded_xml;
  isnt_xml "<foo>", $not_expected_xml;

as invalid XML is not ever schemanitcally identical to a valid XML document.

If you want to insist what you pass in is valid XML, but just not the
same as the other xml document you pass in then you can use two tests:

  is_well_formed_xml $xml;
  isnt_xml $xml, $not_expected_xml;

This function accepts the C<verbose> option (just as C<is_xml> does) but
turning it on doesn't actually output anything extra - there's not useful this
function can output that would help you diagnose the failure case.

=cut

sub isnt_xml($$;$) {
  my $got = shift;
  my $expected = shift;
  my $options = shift;

  $options = { description => $options } unless ref $options eq "HASH";
  $options = { %{$options}, description => "not xml test" }
    unless defined $options->{description};

  # temporarly ignore test output and just get the result of running
  # the is_xml function as normal
  $tester = bless {}, "Test::XML::Easy::Ignore";
  my $result = eval { is_xml($got, $expected, $options) ? 0 : 1 };
  $tester = Test::Builder->new();

  # did we get an error?  Note we don't check $@ directly incase
  # it's been reset by a weird DESTROY() eval...
  unless (defined($result) && length $result) { croak $@; }

  if ($result) {
    $tester->ok(1, $options->{description});
    return 1;
  }

  $tester->ok(0, $options->{description});
  $tester->diag("Unexpectedly matched the XML we didn't expect");
  if ($options->{show_xml}) {
    $tester->diag("The XML that we received was:");
    if (is_xml_element($got))
      { $tester->diag(xml10_write_document($got)) }
    else
      { $tester->diag($got) }
  }
  return;
}
push @EXPORT, "isnt_xml";

=item is_well_formed_xml($string_containing_xml[, $description])

Passes if and only if the string passed contains well formed XML.

=cut

sub is_well_formed_xml($;$) {
  my $xml_string = shift;
  my $options = shift;

  $options = { description => $options } unless ref $options eq "HASH";
  $options = { %{$options}, description => "xml well formed test" }
    unless defined $options->{description};

  if(eval { xml10_read_document($xml_string); 1 }) {
    $tester->ok(1, $options->{description});
    return 1;
  }

  $tester->ok(0, $options->{description});
  $tester->diag($@);
  return;
}
push @EXPORT, "is_well_formed_xml";

=item isnt_well_formed_xml($string_not_containing_xml[, $description])

Passes if and only if the string passed does not contain well formed XML.

=cut

sub isnt_well_formed_xml($;$) {
  my $xml_string = shift;
  my $options = shift;

  $options = { description => $options } unless ref $options eq "HASH";
  $options = { %{$options}, description => "xml not well formed test" }
    unless defined $options->{description};

  unless (eval { xml10_read_document($xml_string); 1 }) {
    $tester->ok(1, $options->{description});
    return 1;
  }

  $tester->ok(0, $options->{description});
  $tester->diag("Unexpectedly well formed XML");
  return;
}
push @EXPORT, "isnt_well_formed_xml";

=back

=head2 A note on Character Handling

If you do not pass it an XML::Easy::Element object then these functions will happly parse
XML from the characters contained in whatever scalars you passed in.  They will not
(and cannot) correctly parse data from a scalar that contains binary data (e.g. that
you've sucked in from a raw file handle) as they would have no idea what characters
those octlets would represent

As long as your XML document contains legal characters from the ASCII range (i.e.
chr(1) to chr(127)) this distintion will not matter to you.

However, if you use characters above codepoint 127 then you will probably need to
convert any bytes you have read in into characters.  This is usually done by using
C<Encode::decode>, or by using a PerlIO layer on the filehandle as you read the data
in.

If you don't know what any of this means I suggest you read the Encode::encode manpage
very carefully.  Tom Insam's slides at L<http://jerakeen.org/talks/perl-loves-utf8/>
may or may not help you understand this more (they at the very least contain a
cheatsheet for conversion.)

The author highly recommends those of you using latin-1 characters from a utf-8 source
to use B<Test::utf8> to check the string for common mistakes before handing it C<is_xml>.

=head1 AUTHOR

Mark Fowler, C<< <mark@twoshortplanks.com> >>

Copyright 2009 PhotoBox, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 BUGS

There's a few cavets when using this module:

=over

=item Not a validating parser

Infact, we don't process (or compare) DTDs at all.  These nodes are completely
ignored (it's as if you didn't include them in the string at all.)

=item Comments and processing instructions are ignored

We totally ignore comments and processing instructions, and it's as
if you didn't include them in the string at all either.

=item Limited entity handling

We only support the five "core" named entities (i.e. C<&amp;>,
C<&lt;>, C<&gt;>, C<&apos;> and C<&quot;>) and numerical character references
(in decimal or hex form.)  It is not possible to declare further named
entities and the precence of undeclared named entities will either cause
an exception to be thrown (in the case of the expected string) or the test to
fail (in the case of the string you are testing)

=item No namespace support

Currently this is only an XML 1.0 parser, and not XML Namespaces aware (further
options may be added to later version of this module to enable namespace support)

This means the following document:

  <foo:fred xmlns:foo="http://www.twoshortplanks.com/namespaces/test/fred" />

Is considered to be different to

  <bar:fred xmlns:bar="http://www.twoshortplanks.com/namespaces/test/fred" />

=item XML whitespace handling

This module considers "whitespace" to be what the XML specification considers
to be whitespace.  This is subtily different to what Perl considers to be
whitespace.

=item No node reordering support

Unlike B<Test::XML> this module considers the order of sibling nodes to be
significant, and you cannot tell it to ignore the differring order of nodes
when comparing the expected and actual output.

=back

Please see L<http://twoshortplanks.com/dev/testxmleasy> for
details of how to submit bugs, access the source control for
this project, and contact the author.

=head1 SEE ALSO

L<Test::More> (for instructions on how to test), L<XML::Easy> (for info
on the underlying xml parser) and L<Test::XML> (for a similar module that
tests using XML::SchemanticDiff)

=cut

1; # End of Test::XML::Easy

package Test::XML::Easy::Ignore;

# a handy class you can bless your tester into so we ignore all
# calls and don't actually produce any test output

sub ok { return }
sub diag { return }

1; # End of Test::XML::Easy::Ignore;
