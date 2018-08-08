package UR::Object::Type::View::Default::Xml;

use strict;
use warnings;
require UR;
our $VERSION = "0.47"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is         => 'UR::Object::View::Default::Xml',
    has        => [
        default_aspects => {
            is          => 'ARRAY',
            is_constant => 1,
            value       => [
                'namespace',
                'table_name',
                'data_source_id',
                'is_abstract',
                'is_final',
                'is_singleton',
                'is_transactional',
                'schema_name',
                'meta_class_name',
                'first_sub_classification_method_name',
                'sub_classification_method_name',
                {
                    label              => 'Properties',
                    name               => 'properties',
                    subject_class_name => 'UR::Object::Property',
                    perspective        => 'default',
                    toolkit            => 'xml',
                    aspects            => [
                        'is_id',       'property_name',
                        'column_name', 'data_type',
                        'is_optional'
                    ],
                },
                {
                    label              => 'References',
                    name               => 'all_id_by_property_metas',
                    subject_class_name => 'UR::Object::Property',
                    perspective        => 'default',
                    toolkit            => 'xml',
                    aspects            => [],
                }
            ],
        },
    ],
);

1;

=pod

=head1 NAME

UR::Object::Type::View::Default::Xml - View class for class metaobjects

=head1 DESCRIPTION

This class is used by L<UR::Object::View::Default::Xsl> to build an html
representation.
 
=cut
