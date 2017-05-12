package UR::Value::View::Default::Xml;
use strict;
use warnings;
use UR;

class UR::Value::View::Default::Xml {
    is => ['UR::Object::View::Default::Xml', 'UR::Value::View::Default::Text'],
};

sub _generate_xml_doc {
    my $self = shift;

    my $xml_doc = $self->SUPER::_generate_xml_doc(@_);

    if ($self->subject_class_name->isa('UR::Value::PerlReference')) {
        $self->_add_perl_data_to_node($self->subject_id);
    }

    return $xml_doc;
}

sub _generate_content {
    my $self = shift;

    my $content;
    if ($self->subject_class_name->isa('UR::Value::PerlReference')) {
        $content = $self->UR::Object::View::Default::Xml::_generate_content(@_);
    }
    else {
        $content = $self->UR::Value::View::Default::Text::_generate_content(@_);
    }

    return $content; 
}

1;
