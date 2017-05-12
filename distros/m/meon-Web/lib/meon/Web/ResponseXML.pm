package meon::Web::ResponseXML;

use strict;
use warnings;

use meon::Web::Util;
use XML::LibXML;
use Scalar::Util 'blessed';
use Moose;
use 5.010;

has 'dom' => (is=>'rw',isa=>'XML::LibXML::Document',lazy_build=>1,trigger=>sub{ $_[0]->clear_xml_libxml; $_[0]->clear_elements; });
has '_xml_libxml' => (is=>'rw',isa=>'XML::LibXML',lazy=>1,default=>sub { XML::LibXML->new },clearer=>'clear_xml_libxml');
has 'elements' => (
    is      => 'rw',
    isa     => 'ArrayRef[Object]',
    lazy_build => 1,
    clearer => 'clear_elements',
	traits  => ['Array'],
	handles => {
		'push_element' => 'push',
		'elements_all' => 'elements',
	},
);

sub _build_elements {
    return [];
}

sub _build_dom {
    my ($self) = @_;

    my $dom = $self->_xml_libxml->createDocument("1.0", "UTF-8");
    my $rxml = $dom->createElement('rxml');
    $rxml->setNamespace('http://www.w3.org/1999/xhtml','xhtml',0);
    $rxml->setNamespace('http://web.meon.eu/','');
    $rxml->setNamespace('http://web.meon.eu/','w');
    $rxml->setNamespace('http://search.cpan.org/perldoc?Data::asXML','d');
    $dom->setDocumentElement($rxml);
    return $dom;
}

sub create_element {
    my ($self, $name, $id) = @_;

    my $element = $self->dom->createElementNS('http://web.meon.eu/',$name);
    $element->setAttribute('id'=>$id)
        if defined $id;

    return $element;
}

sub create_xhtml_element {
    my ($self, $name, $id) = @_;

    my $element = $self->dom->createElementNS('http://www.w3.org/1999/xhtml',$name);
    $element->setAttribute('id'=>$id)
        if defined $id;

    return $element;
}

sub append_xml {
    my ($self, $xml) = @_;

    my $dom    = $self->dom;

    my $ref = ref $xml;
    if ($ref eq '') {
        my $parser = $self->_xml_libxml;
        $dom->getDocumentElement->appendChild(
            $parser->parse_balanced_chunk($xml)
        );
    } elsif ($ref eq 'XML::LibXML::Element') {
        $dom->getDocumentElement->appendChild($xml);
    } else {
        die 'what to do with '.$xml.'?'; 
    }

    return $self;
}

sub parse_xhtml_string {
    my ($self, $xml) = @_;

    my $dom    = $self->dom;

    my $parser  = $self->_xml_libxml;
    my $element = $parser->parse_string(
        '<div xmlns="http://www.w3.org/1999/xhtml">'.$xml.'</div>'
    )->getDocumentElement->firstChild;

    return $element;
}

sub push_new_element {
    my ($self, $name, $id) = @_;

    my $element = $self->create_element($name,$id);
    $self->push_element($element);
    return $element;
}

sub get_element {
    my ($self, $id) = @_;

    foreach my $element ($self->elements_all) {
        my $eid = ($element->can('id') ? $element->id : $element->getAttribute('id'));
        return $element
            if (defined($eid) && ($id eq $eid));
    }

    return undef;
}

sub get_or_create_element {
    my ($self, $id, $name) = @_;

    return
        $self->get_element($id)
        || $self->push_new_element($name)
    ;
}

sub add_xhtml_form {
    my ($self, $xml) = @_;

    my $forms = $self->get_or_create_element('forms', 'forms');

    my $form = $self->parse_xhtml_string($xml);

    # add input like id-s to controll group divs
    my $xpc = meon::Web::Util->xpc;
    my (@inputs) = $xpc->findnodes(q{//x:input[@id!='']|//x:select[@id!='']|//x:textarea[@id!='']},$form);
    foreach my $input (@inputs) {
        my $control_group = $input->parentNode->parentNode;
        next if $control_group->getAttribute('class') ne 'control-group';
        my $control_id = 'control-group-'.$input->getAttribute('id');
        $control_group->setAttribute(id => $control_id);
    }
    $forms->appendChild($form);

    return $self;
}

sub add_xhtml_link {
    my ($self, $link) = @_;

    confess 'is '.$link.' a link?'
        unless blessed($link) && $link->isa('eusahub::Data::Link');

    my $forms = $self->get_or_create_element('links', 'links');
    $forms->appendChild($link->as_xml);

    return $self;
}

sub as_string { return $_[0]->as_xml->toString(1); }

sub as_xml {
    my ($self) = @_;

    my $dom = $self->dom;
    my $root_el = $dom->getDocumentElement;
    foreach my $element ($self->elements_all) {
        $element = $element->as_xml
            if $element->can('as_xml');

        $root_el->addChild($element);
    }

    return $dom;
}

1;
