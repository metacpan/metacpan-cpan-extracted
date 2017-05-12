package XML::Easy::ProceduralWriter;
use base qw(Exporter);

use strict;
use warnings;

our @EXPORT;
our $VERSION = "1.00";

use XML::Easy qw(xml10_write_document);
use Scalar::Util qw(blessed);
use Carp qw(croak);

=head1 NAME

XML::Easy::ProceduralWriter - even easier writing of XML

=head1 SYNOPSIS

  use XML::Easy::ProceduralWriter;

  my $octlets = xml_bytes {
    element "flintstones", contains {
      element "family", surname => "flintstone", contains {
        element "person", hair => "black", contains {
          text "Fred";
        };
        element "person", hair => "blonde", contains {
          text "Wilma";
        };
        element "person", hair => "red", contains {
          text "Pebbles";
        };
      };
      element "family", surname => "rubble", contains {
        my %h = ("Barney" => "blonde", "Betty" => "black", "BamBam" => "white");
        foreach (qw( Barney Betty BamBam )) {
          element "person" hair => $h{$_}, contains { text $_ };
        }
      }
    };
  };

  # outputs
  <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  <flintstones><family surname="flintstone"><person hair="black">Fred</person><person hair="blonde">Wilma</person><person hair="red">Pebbles</person></family><family surname="rubble"><person hair="blonde">Barney</person><person hair="black">Betty</person><person hair="white">BamBam</person></family></flintstones>

=head1 DESCRIPTION

A procedural wrapper around XML::Easy to provide an alternative way of writing XML

=head2 Tutorial

You can use this module to write standard XML.  You start by saying you want some xml_bytes:

  my $octlets = xml_bytes {
    ...
  };

The C<element> command adds a 'tag' to the output.  The simpliest form is:

  xml_bytes {
    element "a";
  };

Which outputs

  <a/>

Note that xml_bytes taks a block - not a data structure - so you can put anything code
you want inside block.

  xml_bytes {
    if ($foo) { element "a"; }
    else      { element "b"; }
  }

(This is what we mean by "Procedural Writer")

You can also use attributes:

  xml_bytes {
    element "a", href => "nojs.html", onclick => "openpopup()";
  }

Which outputs

  <a href="nojs.html" onclick="openpopup()" />

You can use the C<contains> keyword to add content to the XML node.

  element "a", href => "nojs.html", onclick => "openpopup()", contains {
    # ... content here ...
  };

The content can be other tags, text, and any other valid Perl:

  element "a" href => "nojs.html", onclick => "openpopup()", contains {
    text "Click ";
    element "strong", contains { 
      text "Here ";
      element "em", contains { text "NOW" };
    };
    text " please" if $polite;
    text " $name" if $name;
  }

Which outputs

  <a href="nojs.html" onclick="openpopup">Click <strong>Here <em>NOW</em></strong> please Mark</a>

=head2 Functions

This module exports several functions into your namespace by default.  You
can use standard Exporter parameters to control which of these are imported
into your namespace

=over

=item xml_element { ... }

Takes a codeblock.  The code inside the codeblock should call "element" at
least once.  The XML::Easy::Element created by that element command is
returned.

You don't normally want to call this function directly, using either C<xml_bytes>
to create something you can print out or C<element> to create individual xml "tags".
The one occasion that it might make sense to use this function is where you want
to use an encoding other than UTF-8:

  use XML::Easy qq(xml10_write_document);
  print xml10_write_document(xml_element {
    element "song", title => "Green Bottles", contains {
      foreach my $bottles (reverse (1..10)) {
        element "verse", contains {
          element "line", contains {
            text "$bottles green bottle";
            text "s" unless $bottles == 1;
            text " hanging on the wall";
          } for (1..2);
          element "line", contains {
            text "if 1 green bottle should accidentally fall";
          };
          element "line", contains {
            text "then they'd be ".($bottles > 1 ? $bottles-1 : "no")." green bottle";
            text "s" unless $bottles-1 == 1;
            text " hanging on the wall";
          };
        };
      }
    }, "UTF-16BE");

=cut

sub xml_element(&) {

  # create a temporary place to store whatever we're putting
  local @XML::Easy::ProceduralWriter::stuff = ();
  shift->();

  croak "No root node specified"
    unless @XML::Easy::ProceduralWriter::stuff;

  croak "More than one root node specified"
    if @XML::Easy::ProceduralWriter::stuff > 3;

  croak "Text before root node!"
    unless $XML::Easy::ProceduralWriter::stuff[0] eq "";

  croak "Text after root node!"
    if defined($XML::Easy::ProceduralWriter::stuff[2]) && $XML::Easy::ProceduralWriter::stuff[2] ne "";

  return $XML::Easy::ProceduralWriter::stuff[1]
}
push @EXPORT, "xml_element";


=item xml_bytes { ... }

The same as xml_element, but returns a scalar containing octlets that have a UTF-8
encoded representation of the character representation of the string (i.e. this is
what you want to use to create something you can pass to C<print>)

=cut

sub xml_bytes(&) {
  my $data = shift;
  local $Carp::CarpLevel = $Carp::CarpLevel + 1;
  return xml10_write_document(&xml_element($data), "UTF-8"); ## no critic Subroutines::ProhibitAmpersandSigils
}
push @EXPORT, "xml_bytes";

=item element $element_name, $key => $value, $key => $value, $block

Create an XML::Easy::Element element and add it to the enclosing element.

=cut

sub element($;@) {
  my $tag_name = shift;

  my @stuff;
  if (ref $_[-1] && ref $_[-1] eq "CODE") {
    local @XML::Easy::ProceduralWriter::stuff = ();
    (pop)->();
    @stuff = @XML::Easy::ProceduralWriter::stuff;
  }
  push @stuff, "" unless @stuff % 2;
  push @XML::Easy::ProceduralWriter::stuff, "" unless @XML::Easy::ProceduralWriter::stuff % 2;
  push @XML::Easy::ProceduralWriter::stuff, XML::Easy::Element->new($tag_name, {@_}, \@stuff);
  return;
}
push @EXPORT, "element";

=item text $text

Create text and add it to the enclosing element.

=cut

# simply takes it's argument and appends it to @XML::Easy::ProceduralWriter::stuff
sub text($) {
  my $text = shift;
  if (@XML::Easy::ProceduralWriter::stuff % 2)
    { $XML::Easy::ProceduralWriter::stuff[-1] .= $text }
  else
    { push @XML::Easy::ProceduralWriter::stuff, $text }
  return;
}
push @EXPORT, "text";

=item contains { ... }

Syntatic sugar for "sub { ... }"

=cut

# syntatic sugar to allows us to write "contains { ... }" rather than "sub { ... }"
sub contains (&) {
  return $_[0]
}
push @EXPORT, "contains";

=back

=head1 AUTHOR

Mark Fowler <mark@twoshortplanks.com>.  Developed by Photoways whist working
on the Photobox website.

Copyright (C) Photoways Ltd 2008, all rights reserved.

If you send me an email about this module, there's a good chance my overly
agressive spam filter will never let me see it.  Please use http://rt.cpan.org/
to report bugs and request new features instead.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 BUGS

Chucks a lot of stuff into your namespace.

Some people might consider it a bug that this module does not produce
a C<< <?xml ... >> declaration when we convert to bytes.  I consider this
a feature.

=head1 SEE ALSO

L<XML::Easy>

=cut

1;
