package W3C::SOAP::XSD;

# Created on: 2012-05-26 23:50:44
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp qw/carp croak cluck confess longmess/;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Moose::Util::TypeConstraints;
use MooseX::Types::XMLSchema;
use W3C::SOAP::XSD::Types qw/:all/;
use W3C::SOAP::XSD::Traits;
use W3C::SOAP::Utils qw/split_ns/;
use Try::Tiny;
use DateTime::Format::Strptime qw/strptime/;

extends 'W3C::SOAP::Base';

our $VERSION = 0.14;

has xsd_ns => (
    is  => 'rw',
    isa => 'Str',
);
has xsd_ns_name => (
    is         => 'rw',
    isa        => 'Str',
    predicate  => 'has_xsd_ns_name',
    clearer    => 'clear_xsd_ns_name',
    builder    => '_xsd_ns_name',
    lazy       => 1,
);

{
    my %required;
    my $require = sub {
        my ($module) = @_;
        return if $required{$module}++;
        return if eval{ $module->can('new') };

        my $file = "$module.pm";
        $file =~ s{::}{/}gxms;
        require $file;
    };
    around BUILDARGS => sub {
        my ($orig, $class, @args) = @_;
        my $args
            = !@args     ? {}
            : @args == 1 ? $args[0]
            :              {@args};

        if ( blessed $args && $args->isa('XML::LibXML::Node') ) {
            my $xml   = $args;
            my $child = $xml->firstChild;
            my $map   = $class->xml2perl_map;
            my ($element)  = $class =~ /::([^:]+)$/xms;
            $args = {};

            while ($child) {
                if ( $child->nodeName !~ /^[#]/xms ) {
                    my ($node_ns, $node) = split_ns($child->nodeName);
                    confess "Could not get node from (".$child->nodeName." via '$node_ns', '$node')\n"
                        if !$map->{$node};
                    my $attrib = $map->{$node};
                    $node = $attrib->name;
                    my $module = $attrib->has_xs_perl_module ? $attrib->xs_perl_module : undef;
                    $require->($module) if $module;
                    my $value  = $module ? $module->new($child) : $child->textContent;

                    $args->{$node}
                        = !exists $args->{$node}        ? $value
                        : ref $args->{$node} ne 'ARRAY' ? [   $args->{$node} , $value ]
                        :                                 [ @{$args->{$node}}, $value ];
                }
                $child = $child->nextSibling;
            }
        }

        return $class->$orig($args);
    };
}

my %ns_map;
my $count = 0;
sub _xsd_ns_name {
    my ($self) = @_;
    return $self->get_xsd_ns_name($self->xsd_ns);
}

sub get_xsd_ns_name {
    my ($self, $ns) = @_;

    return $ns_map{$ns} if $ns_map{$ns};

    return $ns_map{$ns} = 'WSX' . $count++;
}

sub _from_xml {
    my ($class, $type) = @_;
    my $xml = $_;
    confess "Unknown conversion " . ( (ref $xml) || $xml )
        if !$xml || !blessed $xml || !$xml->isa('XML::LibXML::Node');

    my $ret;

    try {
        $ret = $type->new($xml);
    }
    catch  {
        $_ =~ s/\s at \s .*//xms;
        warn "$class Failed in building from $type\->new($xml) : $_\n",
            "Will use :\n\t'",
            $xml->toString,
            "'\n\tor\n\t'",
            $xml->textContent,"'\n",
            '*' x 222,
            "\n";
        $ret = $xml->textContent;
    };

    return $ret;
}

sub xml2perl_map {
    my ($class) = @_;
    my %map;

    for my $attr ($class->get_xml_nodes) {
        $map{$attr->xs_name} = $attr;
    }

    # get super class nodes (if any)
    my $meta = $class->meta;

    for my $super ( $meta->superclasses ) {
        next if !$super->can('xml2perl_map') && $super ne __PACKAGE__;
        %map = ( %{ $super->xml2perl_map }, %map );
    }

    return \%map;
}

sub to_xml {
    my ($self, $xml) = @_;
    confess "No XML document passed to attach nodes to!" if !$xml;
    my $child;
    my $meta = $self->meta;
    my @attributes = $self->get_xml_nodes;

    my @nodes;
    $self->clear_xsd_ns_name;
    my $xsd_ns_name = $self->xsd_ns ? $self->xsd_ns_name : undef;

    for my $att (@attributes) {
        my $name = $att->name;

        # skip attributes that are not XSD attributes
        next if !$att->does('W3C::SOAP::XSD');
        my $has = "has_$name";

        # skip sttributes that are not set
        next if !$self->$has;

        my $xml_name = $att->has_xs_name ? $att->xs_name : $name;
        my $xml_ns   = $att->has_xs_ns   ? $att->xs_ns   : $self->xsd_ns;
        my $xml_ns_name
            = !defined $xml_ns ? $xsd_ns_name
            : $xml_ns          ? $self->get_xsd_ns_name($xml_ns)
            :                    '';

        my $value = ref $self->$name eq 'ARRAY' ? $self->$name : [$self->$name];

        for my $item (@$value) {
            my $tag = $xml->createElement($xml_ns_name ? $xml_ns_name . ':' . $xml_name : $xml_name);
            $tag->setAttribute("xmlns:$xml_ns_name" => $xml_ns) if $xml_ns;

            if ( blessed($item) && $item->can('to_xml') ) {
                #$item->xsd_ns_name( $xsd_ns_name ) if !$item->has_xsd_ns_name;
                my @children = $item->to_xml($xml);
                $tag->appendChild($_) for @children;
            }
            elsif ( ! defined $item && ! $att->has_xs_serialize ) {
                $tag->setAttribute('nil', 'true');
                $tag->setAttribute('null', 'true');
            }
            else {
                local $_ = $item;
                my $text
                    = $att->has_xs_serialize
                    ? $att->xs_serialize->($item)
                    : "$item";
                $tag->appendChild( $xml->createTextNode($text) );
            }

            push @nodes, $tag;
        }
    }

    return @nodes;
}

sub to_data {
    my ($self, %option) = @_;
    my $child;
    my $meta = $self->meta;
    my @attributes = $self->get_xml_nodes;

    my %nodes;

    for my $att (@attributes) {
        my $name = $att->name;

        # skip attributes that are not XSD attributes
        next if !$att->does('W3C::SOAP::XSD');
        my $has = "has_$name";

        # skip sttributes that are not set
        next if !$self->$has;

        my $key_name = $att->has_xs_name && $option{like_xml} ? $att->xs_name : $name;
        my $value = $self->$name;

        if ( ref $value eq 'ARRAY' ) {
            my @elements;
            for my $element (@$value) {
                if ( blessed($element) && $element->can('to_data') ) {
                    push @elements, $element->to_data(%option);
                }
            }
            $nodes{$key_name} = \@elements;
        }
        else {
            if ( blessed($value) && $value->can('to_data') ) {
                $value = $value->to_data(%option);
            }
            elsif ( ! defined $value && ! $att->has_xs_serialize ) {
            }
            elsif ($option{stringify}) {
                local $_ = $value;
                my $text
                    = $att->has_xs_serialize
                    ? $att->xs_serialize->($value)
                    : "$value";
                $value = defined $value ? $text : $value;
            }

            $nodes{$key_name} = $value;
        }
    }

    return \%nodes;
}

sub get_xml_nodes {
    my ($self) = @_;
    my $meta = $self->meta;

    my @parent_nodes;
    my @supers = $meta->superclasses;
    for my $super (@supers) {
        push @parent_nodes, $super->get_xml_nodes if $super ne __PACKAGE__ && eval { $super->can('get_xml_nodes') };
    }

    return @parent_nodes, map {
            $meta->get_attribute($_)
        }
        sort {
            $meta->get_attribute($a)->insertion_order <=> $meta->get_attribute($b)->insertion_order
        }
        grep {
            $meta->get_attribute($_)->does('W3C::SOAP::XSD::Traits')
        }
        $meta->get_attribute_list;
}

my %types;
sub xsd_subtype {
    my ($self, %args) = @_;
    my $parent_type = $args{module} || $args{parent};

    # upgrade types
    $parent_type
        = $parent_type eq 'xs:date'     ? 'xsd:date'
        : $parent_type eq 'xs:dateTime' ? 'xsd:dateTime'
        : $parent_type eq 'xs:boolean'  ? 'xsd:boolean'
        : $parent_type eq 'xs:double'   ? 'xsd:double'
        : $parent_type eq 'xs:decimal'  ? 'xsd:decimal'
        : $parent_type eq 'xs:long'     ? 'xsd:long'
        :                                 $parent_type;

    my $parent_type_name
        = $args{list}     ? "ArrayRef[$parent_type]"
        : $args{nillable} ? "Maybe[$parent_type]"
        :                   $parent_type;

    my $subtype = $parent_type =~ /^xsd:\w/xms && Moose::Util::TypeConstraints::find_type_constraint($parent_type);
    return $subtype if $subtype && !($args{list} || $args{simple_list});

    $subtype = subtype
        as $parent_type_name,
        message {"'$_' failed to validate as a $parent_type"};

    if ( $args{list} ) {
        if ( $args{module} ) {
            coerce $subtype =>
                from 'xml_node' =>
                via { [$parent_type->new($_)] };
            coerce $subtype =>
                from 'HashRef' =>
                via { [$parent_type->new($_)] };
            coerce $subtype =>
                from 'ArrayRef[HashRef]' =>
                via { [ map { $parent_type->new($_) } @$_ ] };
            coerce $subtype =>
                from $parent_type =>
                via { [$_] };
        }
        else {
            coerce $subtype =>
                from 'xml_node' =>
                via { [$_->textContent] };
            coerce $subtype =>
                from 'ArrayRef[xml_node]' =>
                via { [ map { $_->textContent } @$_ ] };
        }
    }
    elsif ( $args{module} ) {
        coerce $subtype =>
            from 'xml_node' =>
            via { $parent_type->new($_) };
        coerce $subtype =>
            from 'HashRef' =>
            via { $parent_type->new($_) };
    }
    else {
        coerce $subtype =>
            from 'xml_node' =>
            via { $_->textContent };
    }

    if ($args{simple_list}) {
        coerce $subtype =>
            from "ArrayRef" =>
            via { join ' ', @$_ };
    }
    # Propogate coercion from Any via parent's type coercion.
    my $this_type = $subtype->parent;
    if ($this_type->has_parent && ref $this_type->parent) {
        coerce $subtype
            => from 'Any'
            => via {
                !defined $_ && $args{nillable} ? undef
                : $args{nillable}              ? Moose::Util::TypeConstraints::find_type_constraint($parent_type)->coerce($_)
                :                                $this_type->parent->coerce($_)
            };
    }

    return $subtype;
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD - The parent module for generated XSD modules.

=head1 VERSION

This documentation refers to W3C::SOAP::XSD version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::XSD;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=over 4

=item C<get_xsd_ns_name ($ns)>

Returns the namespace name for a particular namespace.

=item C<xml2perl_map ()>

Returns a mapping of XML tag elements to perl attributes

=item C<to_xml ($xml)>

Converts the object to an L<XML::LibXML> node.

=item C<to_data (%options)>

Converts this object to a perl data structure. If C<$option{like_xml}> is
specified and true, the keys will be the same as the XML tags otherwise the
keys will be perl names. If C<$option{stringify}> is true and specified
any non XSD objects will be stringified (eg DateTime objects).

=item C<get_xml_nodes ()>

Returns a list of attributes of the current object that have the
C<W3C::SOAP::XSD> trait (which is defined in L<W3C::SOAP::XSD::Traits>)

=item C<xsd_subtype ()>

Helper method to create XSD subtypes that do coercions form L<XML::LibXML>
objects and strings.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
