package WSDL::Compile;

=encoding utf8

=head1 NAME

WSDL::Compile - Compile SOAP WSDL from your Moose classes.

=head1 SYNOPSIS

    # Name of your WebService: Example
    # Op stands for Operation
    # Your method is CreateCustomer
    #
    # Request - what you expect to receive
    package Example::Op::CreateCustomer::Request;
    use Moose;
    use MooseX::Types::XMLSchema qw( :all );
    use WSDL::Compile::Meta::Attribute::WSDL;

    has 'FirstName' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'xs:string',
        required => 1,
        xs_minOccurs => 1,
    );
    has 'LastName' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'xs:string',
        required => 1,
        xs_minOccurs => 1,
    );
    has 'Contacts' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'ArrayRef[Example::CT::Contact]',
        xs_maxOccurs => undef,
    );

    # Response - that's what will be sent back
    package Example::Op::CreateCustomer::Response;
    use Moose;
    use MooseX::Types::XMLSchema qw( :all );
    use WSDL::Compile::Meta::Attribute::WSDL;

    has 'CustomerID' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'xs:int',
        required => 1,
        xs_minOccurs => 1,
    );

    # Fault - class that defines faultdetails
    package Example::Op::CreateCustomer::Fault;
    use Moose;
    use MooseX::Types::XMLSchema qw( :all );
    use WSDL::Compile::Meta::Attribute::WSDL;

    has 'Code' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'xs:int',
    );
    has 'Description' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'xs:string',
    );

    # CT stands for ComplexType
    # So you can have more complex data structures
    package Example::CT::Contact;
    use Moose;
    use MooseX::Types::XMLSchema qw( :all );
    use WSDL::Compile::Meta::Attribute::WSDL;

    has 'AddressLine1' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'xs:string',
    );
    has 'AddressLine2' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'Maybe[xs:string]',
    );
    has 'City' => (
        metaclass => 'WSDL',
        is => 'rw',
        isa => 'xs:string',
    );

    # below could be put in a script
    package main;
    use strict;
    use warnings;
    use WSDL::Compile;

    my $gen = WSDL::Compile->new(
        service => {
            name => 'Example',
            tns => 'http://localhost/Example',
            documentation => 'Example Web Service',
        },
        operations => [
            qw/
                CreateCustomer
            /
        ],
    );

    my $wsdl = $gen->generate_wsdl();

    print $wsdl;


Please take a look at example/ directory and/or tests for more details.

=cut

use Moose;

our $VERSION = '0.03';

use Moose::Util::TypeConstraints qw( find_type_constraint );
use XML::LibXML;
use MooseX::Params::Validate qw( pos_validated_list );

use WSDL::Compile::Utils qw( wsdl_attributes parse_attr load_class_for_meta );

=head1 ATTRIBUTES

=head2 namespace

Namespace for SOAP classes.

=cut


has 'namespace' => (
    is => 'rw',
    isa => 'Str',
    default => '%s::Op::%s::%s',
);

=head2 service
 
Hashref with following elements:

=over

=item * name

Name of web service

=item * tns

Target namaspace

=item * documentation

Description of web service

=back

=cut

has 'service' => (
    is => 'rw',
    isa => 'HashRef',
);

=head2 operations

Arrayref of all operations available in web service

=cut

has 'operations' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
);

has '_classes' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { {} },
);
has '_wsdl_messages' => (
    is => 'rw',
    isa => 'ArrayRef[XML::LibXML]',
    default => sub { [] },
);
has '_wsdl_portType' => (
    is => 'rw',
    isa => 'XML::LibXML::Element',
);
has '_wsdl_binding' => (
    is => 'rw',
    isa => 'XML::LibXML::Element',
);
has '_wsdl_service' => (
    is => 'rw',
    isa => 'XML::LibXML::Element',
);
has '_wsdl_definitions' => (
    is => 'rw',
    isa => 'XML::LibXML::Element',
);
has '_wsdl_documentation' => (
    is => 'rw',
    isa => 'XML::LibXML::Element',
);
has '_wsdl_types' => (
    is => 'rw',
    isa => 'XML::LibXML::Element',
);
has '_complexTypes' => (
    is => 'rw',
    isa => 'HashRef[HashRef]',
    default => sub { {} },
);

no Moose;

=head1 FUNCTIONS

=head2 generate_wsdl

Compile a WSDL file based on the classes.
Returns string that you should save as .wsdl file.

=cut

sub generate_wsdl {
    my $self = shift;

    for my $class_name ( @{ $self->operations } ) {
        for my $action (qw/ Request Response Fault /) {
            my $class_action_name = $self->_op2class($class_name, $action);

            my $meta = load_class_for_meta( $class_action_name );
            $self->_classes->{$class_name}->{$action} = $meta;
        };
    };

    $self->build_definitions();
    $self->build_documentation();
    $self->build_types();
    $self->build_messages();
    $self->build_portType();
    $self->build_binding();
    $self->build_service();

    return $self->_build_wsdl();
}

=head2 build_messages

Builds wsdl:message.

=cut

sub build_messages {
    my $self = shift;

    my %op_name_mapping = (
        SoapIn => '',
        SoapOut => 'Response',
        SoapFault => 'Fault',
    );

    for my $class_name ( @{ $self->operations } ) {
        for my $msg_type (qw/ SoapIn SoapOut SoapFault /) {
            my $xml = XML::LibXML->createDocument('1.0','utf-8');
            my $msg = $xml->createElement("wsdl:message");
            $msg->setAttribute('name', "$class_name$msg_type");
            my $part = $xml->createElement('wsdl:part');
            $part->setAttribute('name', "parameters");
            $part->setAttribute('element', sprintf("tns:%s%s",
                    $class_name, $op_name_mapping{$msg_type}
                )
            );
            $msg->appendChild( $part );
            $xml->setDocumentElement( $msg );

            push @{ $self->_wsdl_messages }, $msg;

        };
    };
};

=head2 build_portType

Builds wsdl:portType.

=cut

sub build_portType {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','utf-8');
    my $port = $xml->createElement("wsdl:portType");
    $port->setAttribute('name', sprintf("%sSoap", $self->service->{name}));

    for my $class_name ( @{ $self->operations } ) {
        my $op = $xml->createElement("wsdl:operation");
        $op->setAttribute('name', $class_name);
        { # documentation
            my $meta = $self->_classes->{$class_name}->{Request};
            my $attr = $meta->find_attribute_by_name('_operation_documentation')
                or next;

            my $doc = $xml->createElement('wsdl:documentation');
            $doc->setAttribute(
                'xmlns:wsdl', "http://schemas.xmlsoap.org/wsdl/"
            );
            $doc->appendChild(
                $xml->createCDATASection( $attr->default() )
            );

            $op->appendChild( $doc );
        }

        my $input = $xml->createElement('wsdl:input');
        $input->setAttribute('message', sprintf("tns:%sSoapIn", $class_name));
        $op->appendChild( $input );

        my $output = $xml->createElement('wsdl:output');
        $output->setAttribute('message', sprintf("tns:%sSoapOut", $class_name));
        $op->appendChild( $output );

        my $fault = $xml->createElement('wsdl:fault');
        $fault->setAttribute('name', sprintf("%sFault", $class_name));
        $fault->setAttribute('message', sprintf("tns:%sSoapFault", $class_name));
        $op->appendChild( $fault );

        $port->appendChild( $op );
    };
    $xml->setDocumentElement( $port );

    $self->_wsdl_portType( $port );
};

=head2 build_binding

Builds wsdl:binding.

=cut


sub build_binding {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','utf-8');
    my $binding = $xml->createElement("wsdl:binding");
    $binding->setAttribute('name', sprintf("%sSoap", $self->service->{name}));
    $binding->setAttribute('type', sprintf("tns:%sSoap", $self->service->{name}));

    my $soap_binding = $xml->createElement('soap:binding');
    $soap_binding->setAttribute(
        'transport', 'http://schemas.xmlsoap.org/soap/http'
    );
    $binding->appendChild( $soap_binding );

    for my $class_name ( @{ $self->operations } ) {
        my $op = $xml->createElement("wsdl:operation");
        $op->setAttribute('name', $class_name);

        my $soap_op = $xml->createElement('soap:operation');
        $soap_op->setAttribute('soapAction',
            sprintf('%s#%s', $self->service->{tns}, $class_name)
        );
        $soap_op->setAttribute('style', 'document');
        $op->appendChild( $soap_op );


        my $input = $xml->createElement('wsdl:input');

        my $input_body = $xml->createElement('soap:body');
        $input_body->setAttribute('use', 'literal');

        $input->appendChild( $input_body );

        # TODO headers
        if ( 0 ) { # if has_header
            my $soap_header = $xml->createElement('soap:header');
            $soap_header->setAttribute('message',
                sprintf("tns:%sSoapHeader", $class_name)
            );
            $soap_header->setAttribute('part',
                sprintf("%sSoapHeader", $class_name)
            );
            $input->appendChild( $soap_header );
        }
        $op->appendChild( $input );

        my $output = $xml->createElement('wsdl:output');

        my $output_body = $xml->createElement('soap:body');
        $output_body->setAttribute('use', 'literal');

        $output->appendChild( $output_body );
        $op->appendChild( $output );

        my $fault = $xml->createElement('wsdl:fault');
        $fault->setAttribute('name', sprintf("%sFault", $class_name));
        my $soap_fault = $xml->createElement('soap:fault');
        $soap_fault->setAttribute('name', sprintf("%sFault", $class_name));
        $soap_fault->setAttribute('use', 'literal');
        $fault->appendChild( $soap_fault );
        $op->appendChild( $fault );

        $binding->appendChild( $op );
    };
    $xml->setDocumentElement( $binding );

    $self->_wsdl_binding( $binding );
};

=head2 build_service

Builds wsdl:service.

=cut


sub build_service {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','utf-8');
    my $service = $xml->createElement("wsdl:service");
    $service->setAttribute('name', $self->service->{name});

    my $port = $xml->createElement("wsdl:port");
    $port->setAttribute('name', sprintf("%sSoap", $self->service->{name}));
    $port->setAttribute('binding', sprintf("tns:%sSoap", $self->service->{name}));

    my $soap_address = $xml->createElement('soap:address');
    $soap_address->setAttribute('location', $self->service->{tns});
    $port->appendChild( $soap_address );

    $service->appendChild( $port );

    $xml->setDocumentElement( $service );

    $self->_wsdl_service( $service );
};

=head2 build_definitions

Builds wsdl:definitions.

=cut


sub build_definitions {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','utf-8');
    my $def = $xml->createElement("wsdl:definitions");
    $def->setAttribute('xmlns:tns', $self->service->{tns});
    $def->setAttribute('targetNamespace', $self->service->{tns});
    $def->setAttribute('xmlns:soap', "http://schemas.xmlsoap.org/wsdl/soap/");
    $def->setAttribute('xmlns:soapenc', "http://schemas.xmlsoap.org/soap/encoding/");
    $def->setAttribute('xmlns:mime', "http://schemas.xmlsoap.org/wsdl/mime/");
    $def->setAttribute('xmlns:xs', "http://www.w3.org/2001/XMLSchema");
    $def->setAttribute('xmlns:http', "http://schemas.xmlsoap.org/wsdl/http/");
    $def->setAttribute('xmlns:wsdl', "http://schemas.xmlsoap.org/wsdl/");

    $xml->setDocumentElement( $def );

    $self->_wsdl_definitions( $def );
}

=head2 build_documentation

Builds wsdl:documentation.

=cut


sub build_documentation {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','utf-8');
    my $doc = $xml->createElement("wsdl:documentation");
    $doc->appendChild(
        $xml->createCDATASection( $self->service->{documentation} )
    );

    $xml->setDocumentElement( $doc );

    $self->_wsdl_documentation( $doc );
}


=head2 build_types

Builds wsdl:types.

=cut


sub build_types {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','utf-8');
    my $types = $xml->createElement("wsdl:types");
    $types->setAttribute('xmlns', $self->service->{tns}); 
    $xml->setDocumentElement( $types );

    my $schema = $xml->createElement('xs:schema');
    $schema->setAttribute('elementFormDefault', 'qualified');
    $schema->setAttribute('targetNamespace', $self->service->{tns});

    $types->appendChild( $schema );

    my %op_name_mapping = (
        Request => '',
        Response => 'Response',
        Fault => 'Fault',
    );
    for my $class_name ( @{ $self->operations } ) {
        for my $action (qw/ Request Response Fault /) {
            my $op = $xml->createElement('xs:element');
            my ($opType, $opTypeSeq);
            if ( $action ne 'Request') {
                $opType = $xml->createElement('xs:complexType');
                $opType->setAttribute('name',
                    sprintf('%s%sType', $class_name, $op_name_mapping{$action})
                );
                $schema->appendChild( $opType );
                $opTypeSeq = $xml->createElement('xs:sequence');
                $opType->appendChild( $opTypeSeq );
            }
            $schema->appendChild( $op );
            $op->setAttribute('name',
                sprintf('%s%s', $class_name, $op_name_mapping{$action})
            );
            my $ct = $xml->createElement('xs:complexType');
            $op->appendChild( $ct );
            my $seq = $xml->createElement('xs:sequence');
            $ct->appendChild( $seq );
            if ( $action ne 'Request') {
                my $elem_attr = $xml->createElement('xs:element');
                $seq->appendChild( $elem_attr );
                $elem_attr->setAttribute( 'name', lc $class_name);
                $elem_attr->setAttribute( 'type',
                    sprintf('tns:%s%sType', $class_name, $op_name_mapping{$action})
                );
            }

            my $meta = $self->_classes->{$class_name}->{$action};

            for my $attr ( wsdl_attributes($meta) ) {
                my $attr_data = parse_attr( $attr );
                if (my $ct = delete $attr_data->{complexType}) {
                    $self->_complexTypes->{$ct->{name}} = $ct;
                };

                my $elem_attr = $xml->createElement('xs:element');
                $elem_attr->setAttribute( $_, $attr_data->{$_})
                    for sort keys %$attr_data;

                if ( $action ne 'Request') {
                    $opTypeSeq->appendChild( $elem_attr );
                } else {
                    $seq->appendChild( $elem_attr );
                }
            }
        };
    };

    my $ctschema = $xml->createElement('xs:schema');
    $ctschema->setAttribute('elementFormDefault', 'qualified');
    $ctschema->setAttribute('targetNamespace', $self->service->{tns});

    $types->appendChild( $ctschema );


    my %seen;
    my %seen_by_type_constraint;
    while (my ($name, $ctdef) = each %{$self->_complexTypes} ) {
        my $attr = $ctdef->{attr};
        delete $self->_complexTypes->{$name};
        my $name_by_type_constraint = $name . " isa " . $attr->type_constraint->name;
        if (exists $seen{$name}) {
            if (exists $seen_by_type_constraint{$name_by_type_constraint} ) {
                next;
            }
            die "Cannot redefine complex type " , $name , " as a " , $attr->type_constraint->name , "; conflicts with ", $seen{$name} , " in ", $attr->associated_class->name;
        }
        
        $seen{$name} = $name . " which isa " . $attr->type_constraint->name;
        $seen_by_type_constraint{$name_by_type_constraint} = $attr->name;

        my $type = $xml->createElement('xs:element');
        $ctschema->appendChild( $type );
        $type->setAttribute('name', $ctdef->{name});
        my $ct = $xml->createElement('xs:complexType');
        $type->appendChild( $ct );
        my $seq = $xml->createElement('xs:sequence');
        $ct->appendChild( $seq );

        if ( $ctdef->{type} eq 'ArrayRef') {
            my %opts = (
                is => 'ro',
                isa => $attr->type_constraint->type_parameter->name,
                required => $attr->is_required ? 1 : 0,
                xs_minOccurs => $attr->xs_minOccurs,
                xs_maxOccurs => $attr->xs_maxOccurs,
            );
            my $tmpattr = WSDL::Compile::Meta::Attribute::WSDL->new(
                $attr->name,
                %opts
            );
            my $attr_data = parse_attr( $tmpattr );
            if (my $ct = delete $attr_data->{complexType}) {
                $self->_complexTypes->{$ct->{name}} = $ct;
            };

            my $elem_attr = $xml->createElement('xs:element');
            $elem_attr->setAttribute( $_, $attr_data->{$_})
                for sort keys %$attr_data;

            $seq->appendChild( $elem_attr );
        } else { # $ctdef->{defined_in}->{class}
            for my $attr ( wsdl_attributes($ctdef->{defined_in}->{class}) ) {
                my $attr_data = parse_attr( $attr );
                if (my $ct = delete $attr_data->{complexType}) {
                    $self->_complexTypes->{$ct->{name}} = $ct;
                };

                my $elem_attr = $xml->createElement('xs:element');
                $elem_attr->setAttribute( $_, $attr_data->{$_})
                    for sort keys %$attr_data;

                $seq->appendChild( $elem_attr );
            }
        }
        keys %{$self->_complexTypes};
    };

    
    $self->_wsdl_types( $types );

}

# private subroutines

sub _build_wsdl {
    my $self = shift;

    my $xml = XML::LibXML->createDocument('1.0','utf-8');
    my $root = $self->_wsdl_definitions();
    $xml->setDocumentElement( $root );

    $root->appendChild( $self->_wsdl_documentation);
    $root->appendChild( $self->_wsdl_types);
    $root->appendChild( $_ ) for @{ $self->_wsdl_messages };
    $root->appendChild( $self->_wsdl_portType);
    $root->appendChild( $self->_wsdl_binding);
    $root->appendChild( $self->_wsdl_service);

    return $xml->toString(2);
}

sub _op2class {
    my $self = shift;
    my ( $op_name, $op_type ) = pos_validated_list( \@_, 
        { isa => 'Str' },
        { isa => 'Str' },
    );
    
    return sprintf($self->namespace,
        ucfirst lc $self->service->{name}, $op_name, $op_type
    );
}

=head1 AUTHOR

Alex J. G. Burzyński, C<< <ajgb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-wsdl-compile at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WSDL-Compile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 COPYRIGHT & LICENSE

Copyright 2009 Alex J. G. Burzyński.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License.

=cut

1; # End of WSDL::Compile
