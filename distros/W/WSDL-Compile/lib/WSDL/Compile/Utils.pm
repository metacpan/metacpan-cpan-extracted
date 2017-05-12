package WSDL::Compile::Utils;

=encoding utf8

=head1 NAME

WSDL::Compile::Utils - functions used by L<WSDL::Compile>.

=cut

use strict;
use warnings;

our $VERSION = '0.03';

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(
        wsdl_attributes
        parse_attr
        load_class_for_meta
    );
}

use Class::MOP;
use Moose::Meta::Class;
use MooseX::Params::Validate qw(pos_validated_list);
use Perl6::Junction qw( any );



=head1 EXPORT

=head2 wsdl_attributes

Returns a list of sorted by insertion order attributes with metaclass
L<WSDL::Compile::Meta::Attribute::WSDL> for given class meta.

=cut

sub wsdl_attributes {
    my ( $meta ) = pos_validated_list( \@_, 
        { isa => 'Moose::Meta::Class' },
    );

    my @attrs = ();
    for my $attr ( $meta->get_all_attributes ) {
        next unless $attr->isa('WSDL::Compile::Meta::Attribute::WSDL');
        push @attrs, $attr;
    }
    return sort { $a->insertion_order <=> $b->insertion_order } @attrs;
}

=head2 parse_attr

Returns a information of a L<WSDL::Compile::Meta::Attribute::WSDL> attribute
needed to create xs:element.

=cut

sub parse_attr {
    my ( $attr ) = pos_validated_list( \@_, 
        { isa => 'WSDL::Compile::Meta::Attribute::WSDL' },
    );

    my %data;
    
    my $associated_class = $attr->associated_class ?
        $attr->associated_class->name : 'unknown class';
 
    $data{minOccurs} = $attr->xs_minOccurs;
    die $attr->name, " is required - xs_minOccurs cannot be set to 0"
        if $attr->is_required && $attr->xs_minOccurs == 0;

    $data{maxOccurs} = defined $attr->xs_maxOccurs ? $attr->xs_maxOccurs : 'unbounded';

    if ( $data{maxOccurs} ne 'unbounded' ) {
        die "maxOccurs < minOccurs for ", $attr->name,
            " in ", $associated_class
                if $data{minOccurs} > $data{maxOccurs};
    }
    $data{name} = $attr->has_xsname ? $attr->xs_name : $attr->name;
   
    my $tc = $attr->type_constraint;
    my $tc_orig = $tc;
    if ($tc->parent->name eq 'Maybe') {
        $tc = $tc->type_parameter;
        $data{'nillable'} = 'true';
    }

    my $defined_in = $tc->_package_defined_in || '';
    if ( $defined_in eq 'MooseX::Types::XMLSchema' || $attr->has_xstype) {
        die "xs_ref ", $attr->xs_ref, " is not supported for simple types for ", $attr->name,
            " in ", $associated_class, "\n"
                if $attr->has_xsref;
        $data{type} = $attr->has_xstype ? $attr->xs_type : $tc->name;
    } elsif ( ref $tc->parent eq 'Moose::Meta::TypeConstraint::Parameterizable' ) {
        my %complex_type = ();
        if ($tc->type_parameter->parent->name eq 'Maybe') {
            $tc = $tc->type_parameter->type_parameter;
        }
        die $tc_orig->name, " is not supported - cannot have nillable complex types for ",
            $attr->name, " in ", $associated_class
            if $data{nillable};

        die $tc_orig->name, " is not supported - please use ArrayRef or complex type instead of HashRef for ", $attr->name,
            " in ", $associated_class, "\n"
                if 'HashRef' eq any (
                    $tc->parent->name,
                    $tc_orig->parent->name,
                    defined $tc->can('type_parameter') ? 
                        (
                            $tc->type_parameter->parent->name,
                            $tc->type_parameter->name,
                        ) : (),
                );
        die $tc_orig->name, " too deep nesting for ", $attr->name,
            " in ", $associated_class, "\n"
                if ref $tc eq 'Moose::Meta::TypeConstraint::Parameterizable';

        delete $data{name};
        $data{ref} = $attr->has_xsref ? $attr->xs_ref : 'ArrayOf'. ucfirst $attr->name;
        $data{complexType} = {
            name => $data{ref},
            type => 'ArrayRef',
            attr => $attr,
            %complex_type,
        };
        if ( $tc->can('type_parameter') && ref $tc->type_parameter eq 'Moose::Meta::TypeConstraint::Class' ) {
            $data{complexType}->{defined_in}->{class} = load_class_for_meta(
                $tc->type_parameter->class
            );
        } else {
            $data{complexType}->{defined_in}->{types_xs} = 1;
        }
    } elsif (ref $tc eq 'Moose::Meta::TypeConstraint::Class') {
        die $tc_orig->name, " is not supported - cannot have nillable complex types for ",
            $attr->name, " in ", $associated_class
            if $data{nillable};

        $data{ref} = delete $data{name};
        $data{ref} = $attr->xs_ref if $attr->has_xsref;
        $data{complexType} = {
            name => $data{ref},
            type => 'Class',
            attr => $attr,
        };
        $data{complexType}->{defined_in}->{class} = load_class_for_meta(
            $tc->class
        );
    } else {
        die "Unsupported attribute type ", $tc->name, " for ", $attr->name,
            " in ", $associated_class, "\n"
    }

    return \%data;
}

=head2 load_class_for_meta

Loads class and returns L<Moose::Meta::Class> object for it.

=cut

sub load_class_for_meta {
    my ( $class_name ) = pos_validated_list( \@_, 
        { isa => 'Str' },
    );

    Class::MOP::load_class( $class_name );
    return Moose::Meta::Class->initialize(
        $class_name
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

1; # End of WSDL::Compile::Utils
