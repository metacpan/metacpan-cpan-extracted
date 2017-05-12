package meon::Web::Data::CategoryProduct;

use Moose;
use 5.010;

use Path::Class 'file';
use meon::Web::env;
use meon::Web::Util;
use XML::LibXML 'XML_TEXT_NODE';
use IO::Any;

has 'ident'        => (is=>'rw',isa=>'Str',required=>1);
has 'data_folder'  => (is=>'rw',isa=>'Path::Class::Dir'      , lazy => 1, builder => '_build_data_folder');
has 'xml'          => (is=>'ro', isa=>'XML::LibXML::Document', lazy => 1, builder => '_build_xml');
has 'xml_filename' => (is=>'ro', isa=>'Path::Class::File',     lazy => 1, builder => '_build_xml_filename');
has 'summary_xml_filename'
                   => (is=>'ro', isa=>'Path::Class::File',     lazy => 1, builder => '_build_summary_xml_filename');

sub _build_data_folder {
    my ($self) = @_;
    my $data_folder = meon::Web::env->include_dir->subdir('category-product');
    $data_folder->mkpath unless -d $data_folder;
    return $data_folder;
}

sub _build_xml_filename {
    my ($self) = @_;
    return $self->data_folder->file($self->ident.'.xml');
}

sub _build_summary_xml_filename {
    my ($self) = @_;
    return $self->xml_filename->dir->parent->file('category-products.xml');
}

sub _build_xml {
    my ($self) = @_;

    my $xml_filename = $self->xml_filename;
    unless (-f $xml_filename) {
        return XML::LibXML->load_xml(
            string => $self->_blank_xml,
        );
    }
    return XML::LibXML->load_xml(
        location => $self->xml_filename
    );
}

sub _blank_xml {
    my ($self) = @_;
    my $ident = $self->ident;
    return << "__DOM__"
<?xml version="1.0" encoding="UTF-8"?>
<w:category-product ident="$ident" xmlns:w="http://web.meon.eu/">
</w:category-product>
__DOM__
    ;
}

sub set_element {
    my ($self, $name, $value) = @_;

    my ($element) = $self->get_element($name);

    if (!defined($value)) {
        return unless $element;
        while (1) {
            my $prev = $element->previousSibling;
            last unless $prev;
            last unless $prev->nodeType == XML_TEXT_NODE;
            $element->parentNode->removeChild($prev);
        }
        $element->parentNode->removeChild($element);
        return;
    }

    if ($element) {
        foreach my $child ($element->childNodes()) {
            $element->removeChild($child);
        }
    }
    else {
        my $xml = $self->xml->documentElement;
        $xml->appendText(q{ }x4);
        $element = $xml->addNewChild($xml->namespaceURI,$name);
        $xml->appendText("\n");
    }

    $element->appendText($value)
        if length($value);
    return $element;
}

sub get_element {
    my ($self, $name) = @_;

    my ($element) = $self->_xc->findnodes('//w:'.$name);
    return $element;
}


sub store {
    my $self = shift;

    my $filename = $self->xml_filename;
    my $xml = $self->xml;
    my $fh = IO::Any->write($filename,{atomic => 1});
    print $fh $xml->toString;
    $fh->close;

    my $element = $xml->documentElement;
    my $summary_xml = XML::LibXML->load_xml(
        location => $self->summary_xml_filename,
    );
    my $xpc = meon::Web::Util->xpc;
    my ($old_element) = $xpc->findnodes('/w:category-products/w:category-product[@ident="'.$self->ident.'"]',$summary_xml);
    if ($old_element) {
        $old_element->replaceNode($element);
    }
    else {
        $summary_xml->documentElement->appendChild($element);
        $summary_xml->documentElement->appendText("\n");
    }
    my $fh2 = IO::Any->write($self->summary_xml_filename,{atomic => 1});
    print $fh2 $summary_xml->toString;
    $fh2->close;
}

sub delete {
    my $self = shift;

    my $filename = $self->xml_filename;
    my $xml = $self->xml;
    unlink($filename);

    my $element = $xml->documentElement;
    my $summary_xml = XML::LibXML->load_xml(
        location => $self->summary_xml_filename,
    );
    my $xpc = meon::Web::Util->xpc;
    my ($old_element) = $xpc->findnodes('/w:category-products/w:category-product[@ident="'.$self->ident.'"]',$summary_xml);
    if ($old_element) {
        while (1) {
            my $prev = $old_element->nextSibling;
            last unless $prev;
            last unless $prev->nodeType == XML_TEXT_NODE;
            $old_element->parentNode->removeChild($prev);
        }
        $old_element->parentNode->removeChild($old_element);
    }
    my $fh2 = IO::Any->write($self->summary_xml_filename,{atomic => 1});
    print $fh2 $summary_xml->toString;
    $fh2->close;
}

sub _xc {
    my ($self) = @_;
    my $xc = XML::LibXML::XPathContext->new($self->xml->documentElement);
    $xc->registerNs('w', 'http://web.meon.eu/');
    return $xc;
}

sub set_sub_category_products_element {
    my ($self, $name, $sub_category_products) = @_;

    my $el = $self->set_element($name, '');
    my $xml = $self->xml->documentElement;
    $el->appendText("\n");
    foreach my $sub (@$sub_category_products) {
        $el->appendText(q{ }x8);
        my $sub_el = $el->addNewChild($self->xml->namespaceURI,'w:category-product');
        $sub_el->setAttribute('ident' => $sub);
        $el->appendText("\n");
    }
    $el->appendText(q{ }x4);

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;
