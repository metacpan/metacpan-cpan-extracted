use strict;
use warnings;

package UR::DataSource::RDBMS::Entity;

use UR;
our $VERSION = "0.46"; # UR $VERSION;
UR::Object::Type->define(
    class_name => 'UR::DataSource::RDBMS::Entity',
    is => ['UR::Entity'],
    is_abstract => 1,
    data_source => 'UR::DataSource::Meta',
);

1;

=pod

=head1 NAME

UR::DataSource::Meta::RDBMS::Entity - Parent class for all MetaDB-sourced classes

=head1 DESCRIPTION

This class exists as a means for flagging MetaDB objects and handling them
specially by the infrastructure in certain circumstances, such as final
data source determination.

=cut 
