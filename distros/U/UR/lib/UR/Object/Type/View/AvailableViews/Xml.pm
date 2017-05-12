package UR::Object::Type::View::AvailableViews::Xml;

use strict;
use warnings;

require UR;
our $VERSION = "0.46"; # UR $VERSION;

class UR::Object::Type::View::AvailableViews::Xml {
    is => 'UR::Object::View::Default::Xml',
    has_constant => [
        perspective => { value => 'available-views' },
    ],
};

sub _generate_content {
    my $self = shift;

    my $subject = $self->subject;
    return unless $subject;

    my $xml_doc = XML::LibXML->createDocument();
    $self->_xml_doc($xml_doc);

    my $target_class = $subject->class_name;

    my %perspectives = $self->_find_perspectives($target_class);

    my $perspectives = $xml_doc->createElement('perspectives');
    $xml_doc->setDocumentElement($perspectives);

    for my $key (sort keys %perspectives) {
        my $perspective = $perspectives->addChild( $xml_doc->createElement('perspective') );
        $perspective->addChild( $xml_doc->createAttribute('name', $key) );

        for my $tool_key (sort keys %{$perspectives{$key}}) {
            my $toolkit = $perspective->addChild( $xml_doc->createElement('toolkit'));
            $toolkit->addChild( $xml_doc->createAttribute('name', $tool_key));
        }
    }

    $perspectives->addChild( $xml_doc->createAttribute( 'type', $target_class ));

    return $xml_doc->toString(1);
}

sub _find_perspectives {
    my $self = shift;
    my $target_class = shift;

    my %perspectives;
    for my $class ($target_class, $target_class->inheritance) {
        next unless $class->isa('UR::Object');
        my $namespace = $class->__meta__->namespace;

        my $dir = $class;
        $dir =~ s!::!/!g;
        $dir =~ s!^$namespace/!!;
        $dir .= '/View';
        my @views = $namespace->_get_class_names_under_namespace($dir);

        for my $view (@views) {
            if(my $view_type = UR::Object::Type->get($view)) {
                next unless $view->isa('UR::Object::View');
                my $perspective = $view_type->property_meta_for_name('perspective')->default_value;
                my $toolkit = $view_type->property_meta_for_name('toolkit')->default_value;

                unless($perspective) {
                    $self->error_message('No perspective set on view class: ' . $view_type->class_name);
                    next;
                }
                unless($toolkit) {
                    $self->error_message('No toolkit set on view class: ' . $view_type->class_name);
                    next;
                }

                $perspectives{$perspective}{$toolkit}++;
            }
        }
    }

    return %perspectives;
}

1;
