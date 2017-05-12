package WWW::Mechanize::XML;

use vars qw( $VERSION );
$VERSION = '0.02';

use strict;
use warnings;

use base qw( WWW::Mechanize );

use XML::LibXML;
use File::Temp qw( tempfile );

=head1 NAME

WWW::Mechanize::XML - adds an XML DOM accessor to L<WWW::Mechanize>.

=head1 VERSION

This document describes WWW::Mechanize::XML version 0.02

=head1 SYNOPSIS

    use WWW::Mechanize::XML;
    use Test::More;
    my $mech = WWW::Mechanize::XML->new();
    
    ok($mech->get('http://flickr.com/service/?method=getPhotos'), 'got photo list');
    lives_ok {
        $dom = $mech->xml();
    } 'got xml dom object';
    $root = $dom->domumentElement();
    my @photos = $root->findnodes('/rsp/photos/photo');
    is(scalar @photos, 23, 'got 23 photos');

=head1 DESCRIPTION

This is a subclass of L<WWW::Mechanize> that provides an XML DOM accessor which
parses the contents of the response and returns it as a 
L<XML::LibXML::Document>. The motivation for developing this module was to 
facilitate testing of XML APIs and XHTML web pages.

=head1 METHODS 

=head2 new( %options )

Creates a new C<WWW::Mechanize::XML> object with the specified options. This 
constructor method accepts all of the arguments accepted by L<WWW::Mechanize> - 
see L<WWW::Mechanize> for further details. Other optional arguments accepted by 
this method are C<xml_parser_options> and C<xml_error_options>:

=head3 xml_parser_options

This argument, if specified, must be a hashref of valid L<XML::LibXML::Parser> 
options which will be used to instantiate the XML parser. If no parser options 
are specified defaults are used. Please see the documentation for 
L<XML::LibXML::Parser> for option descriptions and default values. Valid parser 
options accepted are:

=over

=item validation

=item recover

=item recover_silently

=item expand_entities

=item keep_blanks

=item pedantic_parser

=item line_numbers

=item load_ext_dtd

=item complete_attributes

=item expand_xinclude

=item clean_namespaces

=back

=head3 xml_error_options

This argument, if specified, must be a hashref containing at least the 
C<trigger_xpath> key. If there is a value for the given xpath expression it will
cause the call to C<xml()> to die with that value. If a C<trigger_value> key is
specified the call will only die if the value at C<trigger_xpath> equals 
C<trigger_value>. If a C<message_xpath> key is specified the call to C<xml()> 
will die with the value at that path.

=cut

my @valid_parser_options = qw(
    validation
    recover
    recover_silently
    expand_entities
    keep_blanks
    pedantic_parser
    line_numbers
    load_ext_dtd
    complete_attributes
    expand_xinclude
    clean_namespaces
);

sub new {
  my ( $class, %args ) = @_;
  
  # check for 'parser_options' for backwards compatability
  my $parser_options = 
    delete $args{xml_parser_options} || delete $args{parser_options} || {};
  unless (ref $parser_options eq 'HASH') {
    die "'xml_parser_options' must be a hash-ref" ;
  }
  
  my $error_options = delete $args{xml_error_options} || {};
  unless (ref $error_options eq 'HASH') {
    die "'xml_error_options' must be a hash-ref" ;
  }
  
  # use catalog to speed up parsing if DTD is loaded 
  my ( $catalog_fh, $catalog_file ) = tempfile();
  my $parser = XML::LibXML->new();
  $parser->load_catalog( $catalog_file );
  
  # set each parser option is valid
  foreach my $option (keys %$parser_options) {
    if (grep { $_ =~ $option } @valid_parser_options) {
      $parser->$option( $parser_options->{$option} );
    } else {
      die "Invalid parser option: $option";
    }
  }
  
  my $self = bless WWW::Mechanize->SUPER::new( %args ), $class;
  $self->{xml_parser} = $parser;
  $self->{xml_error_options} = $error_options;
  return $self;
}

=head2 xml( )

Returns a L<XML::LibXML::Document> object created from the response content by
calling the L<XML::LibXML::Parser> parse_string() method. Any parsing errors 
will propogate up. If C<xml_error_options> were specified for this instance
the response document is check for errors accordingly - this method will die
if errors are found in the document as specified by the options.

=cut

sub xml {
  my $self = shift;
  
  my $dom = $self->{xml_parser}->parse_string( $self->content() );
  $dom->indexElements(); # speed up XPath queries for static documents
  
  # if a trigger_xpath is set check for error
  if ($self->{xml_error_options}->{trigger_xpath}) {
    my $root = $dom->documentElement();
    my $error = $root->findvalue($self->{xml_error_options}->{trigger_xpath});
    
    # if error found at trigger_xpath...
    if ($error) {
      
      # if trigger_value is specified only die if the error has that value
      my $tv = $self->{xml_error_options}->{trigger_value};
      return $dom if ($tv && $tv ne $error);
      
      # if message_xpath is specified die with the value at that location
      if ($self->{xml_error_options}->{message_xpath}) {
        die $root->findvalue($self->{xml_error_options}->{message_xpath});
      }
      
      die $error;
    }
  }
  
  return $dom;
}

=head1 DEPENDENCIES

L<WWW::Mechanize>
L<XML::LibXML>
L<File::Temp>

=head1 BUGS

Please report any bugs you find via the CPAN RT system.

=head1 COPYRIGHT

Copyright Fotango 2006. All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Barry White <bwhite@fotango.com>

=cut

1;

__END__
