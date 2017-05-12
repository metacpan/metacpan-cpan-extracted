package UR::Namespace::Command::Test::Callcount::List;

use strict;
use warnings;

use UR;
our $VERSION = "0.46"; # UR $VERSION;

# Transient class that represents the file as a datasource
our $TheFile = '/dev/null';  # This will be filled in during create() below
UR::DataSource::FileMux->create(
    id => 'Test::Callcount::List::DataSource',
    column_order => ['count','subname','subloc','callers'],
    delimiter => "\t",
    file_resolver => sub { return $TheFile },
    required_for_get => [],
    constant_values => [],
);
    
#class Test::Callcount::List::DataSource {
#    is => 'UR::DataSource::File',
#    column_order => ['count','subname','subloc','callers'],
#    delimiter => "\t",
#};

# Transient class that represents the data in the callcount files
class Test::Callcount::List::Items {
    id_by => 'subname',
    has => [
        count => { is => 'Integer' },
        subname => { is => 'String' },
        subloc => { is => 'String' },
        callers => { is => 'String' },
    ],
    data_source => 'Test::Callcount::List::DataSource',
};

# Class for this command
class UR::Namespace::Command::Test::Callcount::List {
    is => 'UR::Object::Command::List',
    has => [
        file => { is => 'String', doc => 'Specify the .callcount file', default_value => '/dev/null' },
        subject_class_name => { is_constant => 1, value => 'Test::Callcount::List::Items' },
        show => { default_value => 'count,subname,subloc,callers' },
#        filter => { default_value => '' },

    ],
    doc => 'Filter and list Callcount items',
};


sub _resolve_boolexpr {
    my $self = shift;

    my $filename = $self->file;
    unless (-r $filename ) {
        $self->error_message("File $filename does not exist or is not readable");
        return;
    }
    $TheFile = $filename;

    $self->SUPER::_resolve_boolexpr(@_);
}


1;
