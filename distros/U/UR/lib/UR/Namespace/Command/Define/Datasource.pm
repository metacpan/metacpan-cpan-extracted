
# The diff command delegates to sub-commands under the adjoining directory.

package UR::Namespace::Command::Define::Datasource;

use warnings;
use strict;
use UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => "UR::Namespace::Command::Base",
    has_optional => [
        dsid => {
            is => 'Text',
            doc => "The full class name to give this data source.",
        },
        dsname => {
            is => 'Text',
            shell_args_position => 1,
            doc => "The distinctive part of the class name for this data source.  Will be prefixed with the namespace then '::DataSource::'.",
       },
    ],
    doc => 'add a data source to the current namespace'
);

sub _is_hidden_in_docs { 1 }

sub sub_command_sort_position { 2 }

sub data_source_module_pathname {
    my $self = shift;

    my $ns_path = $self->namespace_path;

    my $dsid = $self->dsid;
    my @ds_parts = split(/::/, $dsid);
    shift @ds_parts;  # Get rid of the namespace name

    my $filename = pop @ds_parts;
    $filename .= '.pm';

    my $path = join('/', $ns_path, @ds_parts, $filename);
    return $path;
}

# Overriding these so one can be calculated from the other
sub dsid {
    my $self = shift;

    my $dsid = $self->__dsid;
    unless ($dsid) {
        my $dsname = $self->__dsname;
        my $namespace = $self->namespace_name;
        $dsid = $namespace . '::DataSource::' . $dsname;
        $self->__dsid($dsid);
    }
    return $dsid;
}

sub dsname {
    my $self = shift;

    my $dsname = $self->__dsname;
    unless ($dsname) {
        my $dsid = $self->__dsid;
        # assumme the name is the last portion of the class name
        $dsname = (split(/::/,$dsid))[-1];
        $self->__dsname($dsname);
    }
    return $dsname;
}



1;

