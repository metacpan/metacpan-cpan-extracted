###############################################################################
# XML::Template::Document
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Document;
use base (XML::Template::Base);

use strict;


=pod

=head1 NAME

XML::Template::Document - Module to encapsulate a parsed or unparsed XML
document.

=head1 SYNOPSIS

  use XML::Template::Document;

  my $document = XML::Template::Document->new (XML => $xml);
  $document->code ($code) if ! $document->compiled;

=head1 DESCRIPTION

This module defines an object class that represents a parsed or unparsed
XML document.  Typically, in L<XML::Template::Process>, one in a series of
load objects will return a XML::Template::Document object.  If the
document is not parsed (i.e., no code has been generated), the document is
passed to L<XML::Template::Parser> to be parsed.  The parsed
XML::Template::Document object is then passed to each in a series of put
objects to store the document.  If document caching is turned on, the
first object in the load and put lists is a L<XML::Template::Cache>
object.

=head1 CONSTRUCTOR

The constructor returns a reference to a new document object or undef if
an error occurred.  If undef is returned, you can use the method C<error>
to retrieve the error.  For instance:

  my $document = XML::Templatte::Document->new (%config)
    || die XML::Template::Document->error;

A list of named configuration parameters may be passed to the constructor.
The following named configuration parameters are supported by this module:

=over 4

=item XML

The unparsed XML document.

=item Code

The Perl code that will generate the output of the XML document.

=item Source

The original source of the document.  This is used by the file caching
system to check if a document has been updated.  The format is

  C<type>:C<source_info>

Where C<type> can be

=over 4

=item file

Indicates the original source is a file.  C<source_info> is the full 
filespec of the original document.

=item source

Indicates the original document comes from a data source.  
C<source_info> is

  C<sourcename>:C<data_source_info>

where C<sourcename> is the name of the document's data source entry and,
C<data_source_info> is specific to the type of source.  For a DBI
source, it is a table.

=back

=cut

sub new {
  my $proto  = shift;
  my %params = @_;

  my $class = ref ($proto) || $proto;
  my $self  = {};
  bless ($self, $class);

  $self->{_xml}    = $params{XML};
  $self->{_code}   = $params{Code};
  $self->{_source} = $params{Source};

  return $self;
}

=head1 PUBLIC METHODS

=head2 compiled

  my $iscompiled = $document->compiled;

This method returns 1 if the document is compiled (i.e., code is
stored) and 0 if otherwise.

=cut

sub compiled {
  my $self = shift;

  return defined $self->{_code};
}

=pod

=head2 code

  $document->code ($code);
  my $code = $document->code;

This method stores and returns the Perl code that generates the document
output.  The first parameter is a string containg the Perl code to store.

=cut

sub code {
  my $self = shift;
  my $code = shift;

  if (defined $code) {
    $self->{_code} = $code;
    delete $self->{_xml};
  }
  return $self->{_code};
}

=pod

=head2 xml

  $document->xml ($xml);
  my $xml = $document->xml;

This method stores and returns the unparsed XML document.  The first 
parameter is a string containg the XML.

=cut

sub xml {
  my $self = shift;
  my $xml  = shift;

  $self->{_xml} = $xml if defined $xml;
  return $self->{_xml};
}

=pod

=head2 source

  $document->source ($source);
  my $source = $document->source;

This method stores and returns the original document source. The first
argument is a string containing the document source as described above.

=cut

sub source {
  my $self   = shift;
  my $source = shift;

  $self->{_source} = $source if defined $source;
  return $self->{_source};
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
