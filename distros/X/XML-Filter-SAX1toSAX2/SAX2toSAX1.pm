# $Id: SAX2toSAX1.pm,v 1.3 2002/07/08 11:56:04 matt Exp $

package XML::Filter::SAX2toSAX1;

use strict;
use vars qw($VERSION @ISA);

use XML::SAX::Base;

@ISA = qw(XML::SAX::Base);

$VERSION = '0.03';

sub start_element {
    my ($self, $element) = @_;
    
    # warn("start_element: $self->{Handler}\n");
    $self->make_sax1_attribs($element);
    
    my $name = delete($element->{LocalName});
    my $prefix = delete($element->{Prefix});
    delete($element->{NamespaceURI});
    
    $name = "$prefix:$name" if length($prefix);
    
    $element->{Name} = $name;
    
    $self->SUPER::start_element($element);
}

sub end_element {
    my ($self, $element) = @_;
    
    # warn("end_element\n");
    delete($element->{Attributes});
    delete($element->{LocalName});
    delete($element->{Prefix});
    delete($element->{NamespaceURI});

    $self->SUPER::end_element($element);
}

sub make_sax1_attribs {
    my ($self, $element) = @_;
    
    my %attribs;
    
    foreach my $attrib (values %{$element->{Attributes}}) {
        if (length($attrib->{Prefix})) {
            $attribs{"$attrib->{Prefix}:$attrib->{LocalName}"} =
              $attrib->{Value};
        }
        else {
            $attribs{$attrib->{LocalName}} = $attrib->{Value};
        }
    }
    
    $element->{Attributes} = \%attribs;
}

1;
__END__

=head1 NAME

XML::Filter::SAX2toSAX1 - Convert SAX2 events to SAX1

=head1 SYNOPSIS

  use XML::Filter::SAX2toSAX1;
  # create a SAX1 handler
  my $handler = XML::Handler::YAWriter->new();
  # filter from SAX2 to SAX1
  my $filter = XML::Filter::SAX2toSAX1->new(Handler => $handler);
  # SAX2 parser
  my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);
  # parse file
  $parser->parse_uri( "file.xml" );

=head1 DESCRIPTION

This module is a very simple module for creating SAX1 events from
SAX2 events. It is useful in the case where you have a SAX2 parser
but want to use a SAX1 handler or filter of some sort.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

XML::Parser::PerlSAX, XML::SAX::Base, XML::Filter::SAX1toSAX2

=cut
