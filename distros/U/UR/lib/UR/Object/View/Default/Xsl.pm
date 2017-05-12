package UR::Object::View::Default::Xsl;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;
use IO::File;

use XML::LibXML;
use XML::LibXSLT;

class UR::Object::View::Default::Xsl {
    is => 'UR::Object::View::Default::Text',
    has => [
        output_format => { value => 'html' },
        transform => { is => 'Boolean', value => 0 },
        xsl_variables => { is => 'Hash', is_optional => 1 },
        rest_variable => { value => '/rest', is_deprecated => 1 },
        desired_perspective => { },
        xsl_path => {
            is_optional => 1,
            doc => 'web relative path starting with / where the xsl ' .
                   'is located when serving from a web service'
        },
        xsl_root => {
            doc => 'absolute path where xsl files will be found, expected ' .
                   'format is $xsl_path/$output_format/$perspective/' .
                   '$normalized_class_name.xsl'
        },
    ]
};

use Exporter 'import';
our @EXPORT_OK = qw(type_to_url url_to_type);

sub _generate_content {
    my ($self, %params) = @_;

    if (!$self->desired_perspective) {
        $self->desired_perspective($self->perspective);
    }
#    my $subject = $self->subject;
#    return unless $subject;

    unless ($self->xsl_root && -e $self->xsl_root) {
        die 'xsl_root does not exist:' . $self->xsl_root;
    }

    my $xml_view = $self->_get_xml_view(%params);

#    my $xml_content = $xml_view->_generate_content();

    my $doc = $self->_generate_xsl_doc($xml_view);

    if ($self->transform) {
        return $self->transform_xml($xml_view,$doc); #$xsl_template);
    } else {
        return $doc->toString(1); # $xsl_template;
    }
}

sub _get_xml_view {
    my $self = shift;
    my %params = @_;

    # get the xml for the equivalent perspective
    my $xml_view;
    eval {
        $xml_view = UR::Object::View->create(
            subject_class_name => $self->subject_class_name,
            perspective => $self->desired_perspective,
            toolkit => 'xml',
            %params
        );
    };
    if ($@) {
        # try again, for debugging, don't hate me for this $DB::single you're about to crash..
        $DB::single = 1; 
        $xml_view = UR::Object::View->create(
            subject_class_name => $self->subject_class_name,
            perspective => $self->perspective,
            toolkit => 'xml',
            %params
        );
    }

    return $xml_view;
}

sub _generate_xsl_doc {
    my $self = shift;
    my $xml_view = shift;

    # subclasses typically have this as a constant value
    # it turns out we don't need it, since the file will be HTML.pm.xsl for xml->html conversion
    # my $toolkit = $self->toolkit;

    my $output_format = $self->output_format;
    my $xsl_path = $self->xsl_root;

    unless ($self->transform) {
        # when not transforming we'll return a relative path
        # suitable for urls
        $xsl_path = $self->xsl_path;
    }

    my $perspective = $self->desired_perspective;

    my @include_files = $self->_resolve_xsl_template_files(
        $xml_view,
        $output_format,
        $xsl_path,
        $perspective
    );

    my $rootxsl = "/$output_format/$perspective/root.xsl";
    if (!-e $xsl_path . $rootxsl) {
        $rootxsl = "/$output_format/default/root.xsl";
    }

    my $commonxsl = "/$output_format/common.xsl";
    if (-e $xsl_path . $commonxsl) {
        push(@include_files, $commonxsl);
    }

    no warnings;

    my $xslns = 'http://www.w3.org/1999/XSL/Transform';

    my $doc = XML::LibXML::Document->new("1.0", "ISO-8859-1");
    my $ss = $doc->createElementNS($xslns, 'stylesheet');
    $ss->setAttribute('version', '1.0');
    $doc->setDocumentElement($ss);
    $ss->setNamespace($xslns, 'xsl', 1);

    my $time = time . "000";

    ## this is the wrong place for this information
    #  since it is already part of the XML document
    #  it shouldn't be hard coded into the transform
    my $display_name = $self->subject->__display_name__;
    my $label_name = $self->subject->__label_name__;

    my $set_var = sub {
        my $e = $doc->createElementNS($xslns, 'param');
        $e->setAttribute('name', $_[0]);
        $e->appendChild( $doc->createTextNode( $_[1] ) );
        $ss->appendChild($e)
    };

    $set_var->('currentPerspective',$perspective);
    $set_var->('currentToolkit',$output_format);
    $set_var->('displayName',$display_name);
    $set_var->('labelName',$label_name);
    $set_var->('currentTime',$time);
    $set_var->('username',$ENV{'REMOTE_USER'});

    if (my $id = $self->subject->id) {
        $set_var->('objectId', $id);
    }

    if (my $class_name = $self->subject->class) {
        $set_var->('objectClassName', $class_name);
    }

    if (my $vars = $self->xsl_variables) {
        while (my ($key,$val) = each %$vars) {
            $set_var->($key, $val);
        }
    } else {
        $set_var->('rest',$self->rest_variable);
    }

    my $rootn = $doc->createElementNS($xslns, 'include');
    $rootn->setAttribute('href',"$xsl_path$rootxsl");
    $ss->appendChild($rootn);

    for (@include_files) {
        my $e = $doc->createElementNS($xslns, 'include');
        $e->setAttribute('href',"$xsl_path$_");
        $ss->appendChild($e)
    }

    return $doc;
}

sub _resolve_xsl_template_files {
    my ($self, $xml_view, $output_format, $xsl_path, $perspective) = @_;

    return $xml_view->xsl_template_files(
        $output_format,
        $xsl_path,
        $perspective,
    );
}

sub transform_xml {
    my ($self,$xml_view,$style_doc) = @_;

    $xml_view->subject($self->subject);
    my $xml_content = $xml_view->_generate_content();

    # remove invalid XML entities
    $xml_content =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;

    my $parser = XML::LibXML->new;
    my $xslt = XML::LibXSLT->new;

    my $source;
    if($xml_view->can('_xml_doc') and $xml_view->_xml_doc) {
        $source = $xml_view->_xml_doc;
    } else {
        $source = $parser->parse_string($xml_content);
    }

    # convert the xml
    my $stylesheet = $xslt->parse_stylesheet($style_doc);
    my $results = $stylesheet->transform($source);
    my $content = $stylesheet->output_string($results);

    return $content;
}

sub type_to_url {
    join(
        '/',
        map {
            s/(?<!^)([[:upper:]]{1})/-$1/g;
            lc;
          } split( '::', $_[0] )
    );
}

sub url_to_type {
    join(
        '::',
        map {
            $_ = ucfirst;
            s/-(\w{1})/\u$1/g;
            $_;
          } split( '/', $_[0] )
    );
}

## register a helper function for xslt
XML::LibXSLT->register_function( 'urn:rest', 'typetourl', \&type_to_url );
XML::LibXSLT->register_function( 'urn:rest', 'urltotype', \&url_to_type );


1;

=pod

=head1 NAME

UR::Object::View::Default::Xsl - base class for views which use XSL on an XML view to generate content

=head1 SYNOPSIS

  #####

  class Acme::Product::View::OrderStatus::Html {
    is => 'UR::Object::View::Default::Xsl',
  }

  #####

  Acme/Product/View/OrderStatus/Html.pm.xsl

  #####

  $o = Acme::Product->get(1234);

  $v = $o->create_view(
      perspective => 'order status',
      toolkit => 'html',
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

This class implements basic HTML views of objects.  It has standard behavior for all text views.

=head1 SEE ALSO

UR::Object::View::Default::Text, UR::Object::View, UR::Object::View::Toolkit::XML, UR::Object::View::Toolkit::Text, UR::Object

=cut

