package XML::Handler::ExtOn::Element;

#$Id: Element.pm 357 2008-10-17 11:48:11Z zag $

=pod

=head1 NAME

XML::Handler::ExtOn::Element - Class for Element object.

=head1 SYNOPSYS

    use XML::Handler::ExtOn;
    my $buf;
    my $wrt = XML::SAX::Writer->new( Output => \$buf );
    my $ex_parser = new XML::Handler::ExtOn:: Handler => $wrt;
    
    ...
    
    #create Element
    my $elem = $ex_parser->mk_element("Root");
    $elem->add_content( $elem->mk_element("tag1"));
    
    ...
    
    #delete tag from XML
    $elem->delete_element;
    
    ...
    
    #delete tag from XML and skip content
    $elem->delete_element->skip_content;
    
    ...
    
    #set default namespace( scoped in element )
    $elem->add_namespace(''=>"http://example.com/defaultns");
    
    ...
    
    #get attribites by prefix
    my $hash_ref = $elem->attrs_by_prefix('myprefix');
    $hash_ref->{attr1} = 1;

    $ex_parser->start_element($elem)
    $ex_parser->end_element;

=head1 METHODS

=cut

use strict;
use warnings;

use Carp;
use Data::Dumper;
use XML::Handler::ExtOn::TieAttrs;
use XML::Handler::ExtOn::Attributes;
use XML::Handler::ExtOn::Element;
for my $key (qw/ _context attributes _skip_content _delete_element _stack /) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

# new name=>< element name>, context=>< context >[, sax2=><ref to sax2 structure>]
#
#Create Element object
#
#  my $element = new XML::Handler::ExtOn::Element::
#      name    => "p",
#      context => $context,
#      [sax2 => $t1_elemnt ];
#
#

sub new {
    my ( $class, %attr ) = @_;
    my $self = bless {}, $class;
    $self->_context( $attr{context} ) or die "not exists context parametr";
    my $name = $attr{name};
    $self->attributes(
        new XML::Handler::ExtOn::Attributes::
          context => $self->_context,
        sax2 => exists $attr{sax2} ? $attr{sax2}->{Attributes} : {}
    );

    if ( my $sax2 = $attr{sax2} ) {
        $name ||= $sax2->{Name};
        my $prefix = $sax2->{Prefix} || '';
        $self->set_prefix(  );
        $self->set_ns_uri( $self->ns->get_uri( $prefix ) );
    }
    $self->_stack([]);
    $self->_set_name($name);
    return $self;
}

sub _set_name {
    my $self = shift;
    $self->{__name} = shift || return $self->{__name};
}

=head2 add_content <element object1>[, <element object2> ...]

Add commands to contents stack.Return C<$self>

    $elem->add_content( 
        $self->mk_from_xml("<p/>"),
        $self->mk_cdata("TEST CDATA"),
        )

=cut

sub add_content {
    my $self = shift;
    push @{$self->_stack()}, @_;
    return $self
}


=head2 mk_element <tag name>

Create element object  in namespace of element.

=cut

sub mk_element {
    my $self = shift;
    my $name = shift;
    my %args = @_;
    $args{context} ||= $self->ns->sub_context();
    my $elem = new XML::Handler::ExtOn::Element::
      name => $name,
      %args;
    return $elem;
}

sub set_prefix {
    my $self   = shift;
    my $prefix = shift;
    if ( defined $prefix ) {
        $self->{__prefix} = $prefix;
        $self->set_ns_uri( $self->ns->get_uri($prefix) );
    }
    $self->{__prefix};
}

sub ns {
    return $_[0]->_context;
}

=head2 add_namespace <Prefix> => <Namespace_URI>, [ <Prefix1> => <Namespace_URI1>, ... ]

Add Namespace mapping. return C<$self>

If C<Prefix> eq '', this namespace will then apply to all elements 
that have no prefix.

    $elem->add_namespace(
        "myns" => 'http://example.com/myns',
        "myns_test", 'http://example.com/myns_test',
        ''=>'http://example.com/new_default_namespace'
    );

=cut

sub add_namespace {
    my $self = shift;
    my ( $prefix, $ns_uri ) = @_;
    my $default1_uri = $self->ns->get_uri('');
    $self->ns->declare_prefix(@_);
    my $default2_uri = $self->ns->get_uri('');
    unless ( $default1_uri ne $default2_uri ) {
        $self->set_prefix('') unless $self->set_prefix;
    }
    $self
}

sub set_ns_uri {
    my $self = shift;
    $self->{__ns_iri} = shift if @_;
    $self->{__ns_iri};
}

sub default_ns_uri {
    return $_[0]->ns->get_uri('')
}

=head2 default_uri

Return default I<Namespace_URI> for Element scope.

=cut

sub default_uri {
    $_[0]->ns->get_uri('');
}

sub name {
    return $_[0]->_set_name();
}

=head2 local_name

Return localname of elemnt ( without prefix )

=cut

sub local_name {
    return $_[0]->_set_name();
}

# to_sax2
#
# Export elemnt as SAX2 struct

sub to_sax2 {
    my $self = shift;
    my $res  = {
        Prefix     => $self->set_prefix,
        LocalName  => $self->local_name,
        Attributes => $self->attributes->to_sax2,
        Name       => $self->set_prefix
        ? $self->set_prefix() . ":" . $self->local_name
        : $self->local_name,
        NamespaceURI => $self->set_prefix ? $self->set_ns_uri() : '',
    };
    return $res;
}

=head2 attrs_by_prefix <Prefix>

Return reference to hash of attributes for I<Prefix>.

=cut

sub attrs_by_prefix {
    my $self = shift;
    return $self->attributes->by_prefix(@_);
}

=head2 attrs_by_prefix <Namespace_URI>

Return reference to hash of attributes for I<Namespace_URI>.

=cut

sub attrs_by_ns_uri {
    my $self = shift;
    return $self->attributes->by_ns_uri(@_);
}

=head2 attrs_by_name

Return reference to hash of attributes by name.

=cut

sub attrs_by_name {
    my $self = shift;
    return $self->attributes->by_name(@_);
}

=head2 skip_content

Skip entry of element. Return $self

=cut

sub skip_content {
    my $self = shift;
    return 1 if $self->is_skip_content;
    $self->is_skip_content(1);
    $self;
}

=head2 is_skip_content

Return 1 - if element marked to skip content

=cut

sub is_skip_content {
    my $self = shift;
    $self->_skip_content(@_) || 0
}

=head2 delete_element, delete 

Delete start and close element from stream. return C<$self>

=cut

sub delete {
    my $self = shift;
    return $self->delete_element;
}

sub delete_element {
    my $self = shift;
    return 1 if $self->is_delete_element;
    $self->is_delete_element(1);
    $self;
}

=head2 is_delete_element

Return 1 - if element marked to delete

=cut

sub is_delete_element {
    my $self = shift;
    $self->_delete_element(@_) || 0
}

1;
__END__


=head1 SEE ALSO

XML::Handler::ExtOn, XML::SAX::Base

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

