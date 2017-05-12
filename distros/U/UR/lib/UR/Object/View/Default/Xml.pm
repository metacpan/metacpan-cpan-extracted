package UR::Object::View::Default::Xml;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;
use IO::File;
use XML::Dumper;
use XML::LibXML;

class UR::Object::View::Default::Xml {
    is => 'UR::Object::View::Default::Text',
    has_constant => [
        toolkit     => { value => 'xml' },
    ],
    has_optional_transient => [
        _xml_doc    => { is => 'XML::LibXML::Document', doc => 'The LibXML document used to create the content for this view', },
    ],
};

sub xsl_template_files {
    my $self = shift;  #usually this is a view without a subject attached
    my $output_format = shift;
    my $root_path = shift;
    my $perspective = shift || lc($self->perspective);

    my @xsl_names = map {
       $_ =~ s/::/_/g;
       my $pf = "/$output_format/$perspective/" . lc($_) . '.xsl';
       my $df = "/$output_format/default/" . lc($_) . '.xsl';

       -e $root_path . $pf ? $pf : (-e $root_path . $df ? $df : undef)
    } $self->all_subject_classes_ancestry;

    my @found_xsl_names = grep {
        defined
    } @xsl_names;

    return @found_xsl_names;
}

sub _generate_xml_doc {
    my $self = shift;

    my $subject = $self->subject();
    return unless $subject;

    my $xml_doc = XML::LibXML->createDocument();
    $self->_xml_doc($xml_doc);

    # the header line is the class followed by the id
    my $object = $xml_doc->createElement('object');
    $xml_doc->setDocumentElement($object);

    $object->addChild( $xml_doc->createAttribute('type', $self->subject_class_name) );

    $object->addChild( $xml_doc->createAttribute('id', $subject->id ) );

    my $display_name = $object->addChild( $xml_doc->createElement('display_name') );
    $display_name->addChild( $xml_doc->createTextNode($subject->__display_name__) );

    my $label_name = $object->addChild( $xml_doc->createElement('label_name' ));
    $label_name->addChild( $xml_doc->createTextNode($subject->__label_name__) );

    my $types = $object->addChild( $xml_doc->createElement('types') );
    foreach my $c ($self->subject_class_name,$subject->__meta__->ancestry_class_names) {
        my $isa = $types->addChild( $xml_doc->createElement('isa') );
        $isa->addChild( $xml_doc->createAttribute('type', $c) );
    }

    unless ($self->_subject_is_used_in_an_encompassing_view()) {
        # the content for any given aspect is handled separately
        my @aspects = $self->aspects;
        if (@aspects) {
            my @sorted_aspects = map { $_->[1] }
                                 sort { $a->[0] <=> $b->[0] }
                                 map { [ $_->number, $_ ] }
                                 @aspects;
            for my $aspect (@sorted_aspects) {
                next if $aspect->name eq 'id';

                my $aspect_node = $self->_generate_content_for_aspect($aspect);

                $object->addChild( $aspect_node ) if $aspect_node; #If aspect has no values, it won't be included
            }
        }
    }

    #From the XML::LibXML documentation:
    #If $format is 1, libxml2 will add ignorable white spaces, so the nodes content is easier to read. Existing text nodes will not be altered
    #If $format is 2 (or higher), libxml2 will act as $format == 1 but it add a leading and a trailing line break to each text node.

    return $xml_doc;
}

sub _generate_content {
    my $self = shift;

    my $xml_doc = $self->_generate_xml_doc;
    return '' unless $xml_doc;

    my $doc_string = $xml_doc->toString(1);

    # remove invalid XML entities
    $doc_string =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;

    return $doc_string;
}

sub _add_perl_data_to_node {
    my $self = shift;
    my $perlref = shift;
    my $node = shift;

    my $xml_doc = $self->_xml_doc;
    $node ||= $xml_doc->documentElement;

    my $d = XML::Dumper->new;
    my $perldata = $d->pl2xml($perlref);

    my $parser = XML::LibXML->new;
    my $ref_xml_doc = $parser->parse_string($perldata);
    my $ref_root = $ref_xml_doc->documentElement;
    $xml_doc->adoptNode( $ref_root );
    $node->addChild( $ref_root );

    return 1;
}

sub _generate_content_for_aspect {
    # This does two odd things:
    # 1. It gets the value(s) for an aspect, then expects to just print them
    #    unless there is a delegate view.  In which case, it replaces them
    #    with the delegate's content.
    # 2. In cases where more than one value is returned, it recycles the same
    #    view and keeps the content.
    #
    # These shortcuts make it hard to abstract out logic from toolkit-specifics

    my $self = shift;
    my $aspect = shift;

    my $subject = $self->subject;
    my $xml_doc = $self->_xml_doc;
    my $aspect_name = $aspect->name;

    my $aspect_node = $xml_doc->createElement('aspect');
    $aspect_node->addChild( $xml_doc->createAttribute('name', $aspect_name) );

    my @value;
    eval {
        @value = $subject->$aspect_name;
    };
    if ($@) {
        my ($file,$line) = ($@ =~ /at (.*?) line (\d+)$/m);

        my $exception = $aspect_node->addChild( $xml_doc->createElement('exception') );
        $exception->addChild( $xml_doc->createAttribute('file', $file) );
        $exception->addChild( $xml_doc->createAttribute('line', $line) );
        $exception->addChild( $xml_doc->createCDATASection($@) );

        return $aspect_node;
    }

    if (not Scalar::Util::blessed($value[0])) {
        # shortcut to optimize for simple scalar values without delegate views
        for my $value ( @value ) {
            my $value_node = $aspect_node->addChild( $xml_doc->createElement('value') );
            $value = '' if not defined $value;
            $value_node->addChild( $xml_doc->createTextNode($value) );
        }
        return $aspect_node;
    }

    unless ($aspect->delegate_view) {
        $aspect->generate_delegate_view;
    }

    # Delegate to a subordinate view if needed.
    # This means we replace the value(s) with their
    # subordinate widget content.
    my $delegate_view = $aspect->delegate_view;
    unless ($delegate_view) {
        Carp::confess("No delegate view???");
    }

    foreach my $value ( @value ) {
        if (Scalar::Util::blessed($value)) {
            $delegate_view->subject($value);
        } else {
            $delegate_view->subject_id($value);
        }
        $delegate_view->_update_view_from_subject();

        # merge the delegate view's XML into this one
        if ($delegate_view->can('_xml_doc') and $delegate_view->_xml_doc) {
            # the delegate has XML
            my $delegate_xml_doc = $delegate_view->_xml_doc;
            my $delegate_root = $delegate_xml_doc->documentElement;
            #cloneNode($deep = 1)
            $aspect_node->addChild( $delegate_root->cloneNode(1) );
        }
        elsif (ref($value) and not $value->isa("UR::Value")) {
            # Note: Let UR::Values display content below
            # Otherwise, the delegate view has no XML object, and the value is a reference
            $self->_add_perl_data_to_node($value, $aspect_node);
        }
        elsif (ref($value) and $value->isa("UR::Value")) {
            # For a UR::Value return both a formatted value and a raw value.
            my $display_value_node = $aspect_node->addChild( $xml_doc->createElement('display_value') );
            my $content = $delegate_view->content;
            $content = '' if not defined $content;
            $display_value_node->addChild( $xml_doc->createTextNode($content) );

            my $value_node = $aspect_node->addChild( $xml_doc->createElement('value') );
            $content = $value->id;
            $value_node->addChild( $xml_doc->createTextNode($content) );
        }
        else {
            # no delegate view has no XML object, and the value is a non-reference
            # (this is the old logic for non-delegate views when we didn't have delegate views for primitives)
            my $value_node = $aspect_node->addChild( $xml_doc->createElement('value') );
            unless(defined $value) {
                $value = '';
            }
            my $content = $delegate_view->content;
            $content = '' if not defined $content;
            $value_node->addChild( $xml_doc->createTextNode($content) );
            
            ## old logic for delegate views with no xml doc (unused now) 
            ## the delegate view may not be XML at all--wrap it in our aspect tag so that it parses
            ## (assuming that whatever delegate was selected properly escapes anything that needs escaping)

            # my $delegate_text = $delegate_view->content() ? $delegate_view->content() : '';
            # my $aspect_text = "<aspect name=\"$aspect_name\">\n$delegate_text\n</aspect>";
            # my $parser = XML::LibXML->new;
            # my $delegate_xml_doc = $parser->parse_string($aspect_text);
            # $aspect_node = $delegate_xml_doc->documentElement;
            # $xml_doc->adoptNode( $aspect_node );
        }
    }

    return $aspect_node;
}

# Do not return any aspects by default if we're embedded in another view
# The creator of the view will have to specify them manually
sub _resolve_default_aspects {
    my $self = shift;
    unless ($self->parent_view) {
        return $self->SUPER::_resolve_default_aspects;
    }
    return;
}

1;


=pod

=head1 NAME

UR::Object::View::Default::Xml - represent object state in XML format

=head1 SYNOPSIS

  $o = Acme::Product->get(1234);

  $v = $o->create_view(
      toolkit => 'xml',
      aspects => [
        'id',
        'name',
        'qty_on_hand',
        'outstanding_orders' => [
          'id',
          'status',
          'customer' => [
            'id',
            'name',
          ]
        ],
      ],
  );

  $xml1 = $v->content;

  $o->qty_on_hand(200);

  $xml2 = $v->content;

=head1 DESCRIPTION

This class implements basic XML views of objects.  It has standard behavior for all text views.

=head1 SEE ALSO

UR::Object::View::Default::Text, UR::Object::View, UR::Object::View::Toolkit::XML, UR::Object::View::Toolkit::Text, UR::Object

=cut

