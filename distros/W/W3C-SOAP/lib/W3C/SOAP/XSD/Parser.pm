package W3C::SOAP::XSD::Parser;

# Created on: 2012-05-28 08:11:37
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
use List::MoreUtils qw/all/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;
use W3C::SOAP::XSD::Document;
use File::ShareDir qw/dist_dir/;
use Moose::Util::TypeConstraints;
use W3C::SOAP::Utils qw/split_ns/;
use W3C::SOAP::XSD;

Moose::Exporter->setup_import_methods(
    as_is => ['load_xsd'],
);

extends 'W3C::SOAP::Parser';

our $VERSION = 0.14;

subtype xsd_documents =>
    as 'ArrayRef[W3C::SOAP::XSD::Document]';
coerce xsd_documents =>
    from 'W3C::SOAP::XSD::Document',
    via {[$_]};
has '+document' => (
    isa      => 'xsd_documents',
    coerce   => 1,
);
has ns_module_map => (
    is       => 'rw',
    isa      => 'HashRef[Str]',
    required => 1,
);

sub write_modules {
    my ($self) = @_;
    confess "No lib directory setup" if !$self->has_lib;
    confess "No template object set" if !$self->has_template;

    my @xsds     = $self->get_schemas;
    my $template = $self->template;
    my @schemas;
    my $self_module;
    my @parents;
    my @xsd_modules;

    # process the schemas
    for my $xsd (@xsds) {
        my $module = $xsd->module;
        push @xsd_modules, $module;
        $self_module ||= $module;
        my $file   = $self->lib . '/' . $module;
        $file =~ s{::}{/}gxms;
        $file = path($file);
        my $parent = $file->parent;
        my @missing;
        while ( !-d $parent ) {
            push @missing, $parent;
            $parent = $parent->parent;
        }
        mkdir $_ for reverse @missing;

        for my $type ( @{ $xsd->complex_types } ) {
            my $type_name = $type->name || $type->parent_node->name;
            warn  "me          = ".(ref $type).
                "\nnode        = ".($type->node->nodeName).
                "\nparent      = ".(ref $type->parent_node).
                "\nparent node = ".($type->node->parentNode->nodeName).
                "\ndocument    = ".(ref $type->document)."\n"
                if !$type_name;
            confess "No name found for ",
                $type->node->toString,
                "\nin :\n",
                $type->document->string,"\n"
                if !$type_name;
            my $type_module = $module . '::' . $type_name;
            push @parents, $type_module;
            my $type_file = $self->lib . '/' . $type_module;
            $type_file =~ s{::}{/}gxms;
            $type_file = path($type_file);
            mkdir $type_file->parent if !-d $type_file->parent;

            my %modules;
            for my $el (@{ $type->sequence }) {
                $modules{ $el->type_module }++
                    if ! $el->simple_type && $el->module ne $module
            }
            for my $element (@{ $type->sequence }) {
                next if $element->simple_type;
                my ($ns) = split_ns($element->type);
                $ns ||= $element->document->target_namespace;
                my $ns_uri = $element->document->get_ns_uri($ns, $element->node);
                $modules{ $type->document->get_module_name($ns_uri) }++
                    if $ns_uri && $ns_uri ne $type->document->target_namespace;
            }

            # write the complex type module
            $self->write_module(
                'xsd/complex_type.pm.tt',
                {
                    xsd     => $xsd,
                    module  => $type_module,
                    modules => [ keys %modules ],
                    node    => $type
                },
                "$type_file.pm"
            );
        }

        # write the simple types library
        $self->write_module(
            'xsd/base.pm.tt',
            {
                xsd => $xsd,
            },
            "$file/Base.pm"
        );

        # write the "XSD" elements module
        $self->write_module(
            'xsd/pm.tt',
            {
                xsd         => $xsd,
                parents     => \@parents,
                w3c_version => $VERSION,
                config      => { xsd => { parent_module => $xsd->module . '::Base'}},
            },
            "$file.pm"
        );

    }

    #warn Dumper \@xsd_modules, $self_module;
    return wantarray ? @xsd_modules : $self_module;
}

my %written;
sub write_module {
    my ($self, $tt, $template_data, $file) = @_;
    my $template = $self->template;

     if ($written{$file}++) {
         #warn "Already written $file!\n";
        return;
    }

    $template->process($tt, $template_data, "$file");
    confess "Error in creating $file (via $tt): ". $template->error."\n"
        if $template->error;

    return;
}

sub written_modules {
    return keys %written;
}

sub get_schemas {
    my ($self) = @_;
    my @xsds   = @{ $self->document };
    my %xsd;

    # import all schemas
    while ( my $xsd = shift @xsds ) {
        my $target_namespace = $xsd->target_namespace;
        push @{ $xsd{$target_namespace} }, $xsd;

        for my $import ( @{ $xsd->imports } ) {
            push @xsds, $import;
        }
        for my $include ( @{ $xsd->includes } ) {
            push @xsds, $include;
        }
    }

    # flatten schemas specified more than once
    for my $ns ( keys %xsd ) {
        my $xsd = pop @{ $xsd{$ns} };
        if ( @{ $xsd{$ns} } ) {
            for my $xsd_repeat ( @{ $xsd{$ns} } ) {
                push @{ $xsd->simple_types  }, @{ $xsd_repeat->simple_types  };
                push @{ $xsd->complex_types }, @{ $xsd_repeat->complex_types };
                push @{ $xsd->elements      }, @{ $xsd_repeat->elements      };
            }
        }

        push @xsds, $xsd;
    }

    return @xsds;
}

sub load_xsd {
    my ($location) = @_;
    my $parser = __PACKAGE__->new(
        location      => $location,
        ns_module_map => {},
    );

    return $parser->dynamic_classes;
}

sub dynamic_classes {
    my ($self) = @_;
    my @xsds   = $self->get_schemas;
    my @packages;

    # construct the in memory module names
    for my $xsd (@xsds) {
        $xsd->module_base('Dynamic::XSD');
        $xsd->module;
    }

    my %seen;
    my @ordered_xsds;
    XSD:
    while ( my $xsd = shift @xsds ) {
        my $module = $xsd->module;

        # Complex types
        my @types = @{ $xsd->complex_types };
        my %local_seen;
        TYPE:
        while ( my $type = shift @types ) {
            my $type_name = $type->name || $type->parent_node->name;
            my $type_module = $module . '::' . $type_name;

            if ( $type->extension && !$seen{ $type->extension }++ ) {
                push @xsds, $xsd;
                next XSD;
            }
            $local_seen{ $type_module }++;
        }

        %seen = ( %seen, %local_seen );
        push @ordered_xsds, $xsd;
    }

    my %complex_seen = ( 'W3C::SOAP::XSD' => 1 );
    for my $xsd (@ordered_xsds) {
        my $module = $xsd->module;

        # Create simple types
        $self->simple_type_package($xsd);

        # Complex types
        my @complex_types = @{ $xsd->complex_types };
        my %types;
        while ( my $type = shift @complex_types ) {
            my $type_name = $type->name || $type->parent_node->name;
            my $type_module = $module . '::' . $type_name;
            next if $types{$type_module}++;

            my %modules = ( 'W3C::SOAP::XSD' => 1 );
            for my $el (@{ $type->sequence }) {
                $modules{ $el->type_module }++
                    if ! $el->simple_type && $el->module ne $module
            }
            if ( $type->extension ) {
                $modules{ $type->extension }++
            }

            if ( !all {$complex_seen{$_}} keys %modules ) {
                push @complex_types, $type;
                next;
            }

            $complex_seen{$type_module}++;
            $self->complex_type_package($xsd, $type, $type_module, [ keys %modules ]);
        }

        # elements package
        $self->elements_package($xsd, $module);

        push @packages, $module;
    }

    return @packages;
}

sub simple_type_package {
    my ($self, $xsd) = @_;

    for my $subtype (@{ $xsd->simple_types }) {
        next if !$subtype->name;

        # Setup base simple types
        if ( @{ $subtype->enumeration } ) {
            enum(
                $subtype->moose_type
                => $subtype->enumeration
            );
        }
        else {
            subtype $subtype->moose_type =>
                as $subtype->moose_base_type;
        }

        # Add coercion from XML::LibXML nodes
        coerce $subtype->moose_type =>
            from 'XML::LibXML::Node' =>
            via { $_->textContent };

        if ($subtype->list) {
            coerce $subtype->moose_type =>
                from 'ArrayRef' =>
                via { join ' ', @$_ };
        }
    }

    return;
}

sub complex_type_package {
    my ($self, $xsd, $type, $class_name, $super) = @_;

    my $class = Moose::Meta::Class->create(
        $class_name,
        superclasses => $super,
    );

    $class->add_attribute(
        '+xsd_ns',
        default  => $xsd->target_namespace,
        required => 1,
    );

    for my $node (@{ $type->sequence }) {
        $self->element_attributes($class, $class_name, $node, $xsd, 1);
    }

    return $class;
}

sub elements_package {
    my ($self, $xsd, $class_name) = @_;

    my $class = Moose::Meta::Class->create(
        $class_name,
        superclasses => [ 'W3C::SOAP::XSD' ],
    );

    $class->add_attribute(
        '+xsd_ns',
        default  => $xsd->target_namespace,
        required => 1,
    );

    for my $node (@{ $xsd->elements }) {
        $self->element_attributes($class, $class_name, $node, $xsd);
    }

    return $class;
}

sub element_attributes {
    my ($self, $class, $class_name, $element, $xsd, $complex) = @_;

    my $simple = $element->simple_type;
    my $very_simple = $element->very_simple_type;
    my $is_array = $element->max_occurs eq 'unbounded'
        || ( $element->max_occurs && $element->max_occurs > 1 )
        || ( $element->min_occurs && $element->min_occurs > 1 );
    my $type_name = $simple || $element->type_module;
    my $serialize = '';

    if ( $very_simple ) {
        if ( $very_simple eq 'xs:boolean' ) {
            $serialize = sub { $_ ? 'true' : 'false' };
        }
        elsif ( $very_simple eq 'xs:date' ) {
            $serialize = sub {
                return $_->ymd if $_->time_zone->isa('DateTime::TimeZone::Floating');
                my $d = DateTime::Format::Strptime::strftime('%F%z', $_);
                $d =~ s/([+-]\d\d)(\d\d)$/$1:$2/xms;
                return $d
            };
        }
        elsif ( $very_simple eq 'xs:time' ) {
            $serialize = sub { $_->hms };
        }
    }

    my @extra;
    push @extra, ( xs_perl_module  => $element->type_module  ) if !$simple;
    push @extra, ( xs_choice_group => $element->choice_group ) if $element->choice_group;
    push @extra, ( xs_serialize    => $serialize             ) if $serialize;

    confess "No perl name!\n".$element->node->parentNode->toString if !$element->perl_name;
    $class->add_attribute(
        $element->perl_name,
        is            => 'rw',
        isa           => $class_name->xsd_subtype(
            ($simple ? 'parent' : 'module') => $type_name,
           list     => $is_array,
           nillable => $element->nillable,
        ),
        predicate     => 'has_'. $element->perl_name,
        # TODO handle nillable correctly  should be a Maybe type
        #required      => !$element->nillable,
        coerce        => 1,
    #[%- IF config->alias && element->name.replace('^\w+:', '') != element->perl_name %]
        #alias         => '[% element->name.replace('^\w+:', '') %]',
    #[%- END %]
        traits        => [qw{ W3C::SOAP::XSD }],
        xs_name       => $element->name,
        xs_ns         => !$complex || $xsd->element_form_default eq 'qualified' ? $xsd->target_namespace : '',
        xs_type       => $element->type,
        xs_min_occurs => $element->min_occurs,
        xs_max_occurs => $element->max_occurs  eq 'unbounded' ? 0 : $element->max_occurs,
        @extra,
    );

    if ( $ENV{W3C_SOAP_NAME_STYLE} eq 'both' && $element->name ne $element->perl_name ) {
        my $name = $element->perl_name;
        $class->add_method(
            $element->name => sub { shift->$name(@_) }
        );
    }

    return;
}
1;

__END__

=head1 NAME

W3C::SOAP::XSD::Parser - Parser for XSD documents that generates Perl modules
implementing the object defined.

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Parser version 0.14.

=head1 SYNOPSIS

   use W3C::SOAP::XSD::Parser;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<load_xsd ($schema_location)>

Loads the schema and dynamically generates the Perl/Moose packages that
represent the schema.

=item C<write_modules ()>

Uses the supplied documents to write out perl modules to disk that represent
the XSDs in the documents.

=item C<write_module ($tt, $data, $file)>

Write the template to disk

=item C<written_modules ()>

Returns a list of all XSD modules written by the parser.

=item C<get_schemas ()>

Gets a list of the schemas imported/included from the base XML Schema(s)

=item C<complex_type_package ( $xsd, $type, $class_name, $super)>

Creates the complex types

=item C<<$wsdl->dynamic_classes ()>>

Creates a dynamic XSD objects that represent the XML Schema files imported.

=item C<element_attributes ( $class, $class_name, $element )>

Sets up all the attributes for a single element

=item C<elements_package ( $xsd, $class_name )>

Creates the package that represents top level elements in the XSD

=item C<simple_type_package ( $xsd )>

Creates all the simple types for the C<$xsd>

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
