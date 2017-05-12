package XML::Filter::CharacterChunk;

# $Id: CharacterChunk.pm,v 1.6 2002/03/14 09:29:23 cb13108 Exp $

use strict;
use warnings;

require XML::Filter::GenericChunk;

@XML::Filter::CharacterChunk::ISA = qw(XML::Filter::GenericChunk);

$XML::Filter::CharacterChunk::VERSION = '0.03';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    $self->{Warnings} ||= 0;
    return $self;
}

sub characters {
    my $self = shift;
    my $data = shift;

    if ( $self->is_tag() ) {
        $self->add_data($data->{Data});
        return;
    }

    return $self->SUPER::characters($data);
}

sub end_element {
    my $self = shift;
    if ( $self->is_tag() ) {
        eval { $self->flush_chunk(); };
        if ( $@
             and $self->{Warnings} == 1 ) {
            warn "chunk is not wellballanced or has a brocken encoding";
            warn "> " , $@;
        }
    }
    return $self->SUPER::end_element(@_);
}

1;
__END__

=head1 NAME

XML::Filter::CharacterChunk - SAX Filter for Wellballanced Chunks

=head1 SYNOPSIS

  use XML::Filter::CharacterChunk;

  my $filter = XML::Filter::CharacterChunk->new();

=head1 DESCRIPTION

From time to time it happens that there are XML informations in a SAX
stream, that are not available as events, but as a string. This filter
offers an interface to transfrom such strings into ordinary SAX
events. It will collect all charaters() calls within a element and
build a data string from it. As soon the element ends, this data
string will be processed as it would be well balanced XML data: the
following handler will recive the appropriate SAX events instead of
simple characters() calls.

The following example could be produced as a result of database -> XML
transformation:

   <foo>
      <expand>
         expand the &lt;bar value="foobar"/&gt;
      </expand>
      <other>
         data
      </other>
   </foo>

While data in databases usually is stored as strings, this string will
appear as a XML encoded string instead of structured XML data. When
processed with SAX, this filter can do the expansion for the tag that
should contain XML data rather that Text data. Because not all data
may be expanded, the filter can be configured only to attend to
certain tags.

For our example the filter would be set up as following:

   $filter = XML::Filter::CharacterChunk->new( TagName=>["expand"] );

This will cause the filter to wait for B<expand>-elements to be
started before it collects the data. Therefore the filter will leave
the data inside the B<other>-element untouched. The result a SAX chain
would be the same as if the following document was processed:

   <foo>
      <expand>
         expand the <bar value="foobar"/>
      </expand>
      <other>
         data
      </other>
   </foo>

In our example one a single tag is expanded by the filter. It is
possible to defined as many tag names as required for expansion. If in
our example the other-element should be processed as well, it has to
be added to the observed tag names. Either

  $filter = XML::Filter::CharacterChunk->new( TagName=>["expand", "other"] );

or

  $filter->set_tagnames("other");

set_tagnames() will add a list of additional tag names to the TagNames
specified with the constructor.

Another thing is to observe a special namespace. This lets the filter
wait for tags within this namespace. Currently the filter allows only
to test a single namespace.

  $filter = XML::Filter::CharacterChunk->new(
                   TagName=>["expand", "other"],
                   NamespaceURI=>"foo" );

will cause that the example will not be processed at all. If a
namespace uri is set, the filter will only attend to that namespace
and will ignore any global tags (or prefixes, if set).

=head2 Constructor Extensions

XML::LibXML's parse_xml_chunk() will throw exceptions if the parsing
fails. By default XML::Filter::CharacterChunk will note this, but
generate any warnings. This can be changed if
XML::Filter::CharacterChunk->new() will recieve the extra parameter
Warnings => 1. This will cause the class to warn() some information
about the failure.

   my $filter = XML::Filter::CharacterChunk->new(Handler => $some_handler, Warnings => 1);

As shown this flag can get passed to the filter as ordinary XML::SAX
construction parameters are passed.

=head2 General Pitfalls

XML::Filter::CharacterChunk will B<only> collect the data from
characters() calls. It is not designed for mixed data. The collected
information will be processed if the containing element ends. The
filter assumes silently that the containing element has only text
data. Therefore the document

   <foo>
      <expand>
         this &lt;bar&gt; is <tag/> wrong &lt/bar&gt;
      </expand>
   </foo>

will B<not> result

  <foo>
     <expand>
        this <bar> is <tag/> wrong </bar>
     </expand>
  </foo>

but

  <foo>
     <expand>
        <tag/>this <bar> is wrong </bar>
     <expand>
  </foo>

because the tag-element is not processed by the filter but imediatly
passed to the filters handler. XML::Filter::CharacterChunk will
process the data at the last possible point, which is right before the
element is closed. With mixed content this will lead to data
restructuring and may cause some confusion. There is only one solution:
B<Do not use XML::Filter::CharacterChunk for mixed data!>

Another problem appears with nested tags of the same name, such as

  <foo>
    <expand>
        test <expand>this &lt;foobar/&gt;</expand> extra &lt;foobar/&gt;
    </expand>
  </foo>

It will cause the filter to find all data until the B<first> closing
tag. Doing so, the result will be unexpected:

 <foo>
    <expand>
        <expand>test this <foobar/></expand>  extra &lt;foobar/&gt;
    </expand>
 </foo>

I am not shure if this is bad behaviour or just bad data design.
Actually, this will cause loss of data, if the chunk is not well
balanced when the first end_element() is caugth.

  <foo>
      <expand>
          &lt;foobar/&gt;<expand> test this </expand> extra &lt;foobar/&gt;
      </expand>
  </foo>

will result as a side effect of this problem:

  <foo>
     <expand>
          <expand/> extra &lt;foobar/&gt;
     </expand>
  </foo>

=head1 BUGS

Namespaces used in the chunk are not expanded properly.

=head1 AUTHOR

Christian Glahn, christian.glahn@uibk.ac.at,
Innsbruck University

=head1 SEE ALSO

XML::Filter::GenericChunk

=cut
