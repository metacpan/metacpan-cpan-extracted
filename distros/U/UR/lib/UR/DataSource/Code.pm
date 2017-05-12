
package UR::DataSource::Code;

use strict;
use warnings;
require UR;
our $VERSION = "0.46"; # UR $VERSION;
use File::Copy qw//;
##- use UR;

UR::Object::Type->define(
    class_name => 'UR::DataSource::Code',
    is => ['UR::DataSource::SQLite'],
);

sub server { 
    my $self = shift->_singleton_object();
    my $path = $self->__meta__->module_path;
    $path =~ s/\.pm$/.db/ or Carp::confess("Bad module path for resolving server!");
    unless (-e $path) {
        # initialize a new database from the one in the base class
        # should this be moved to connect time?
        my $template_database_file = UR::DataSource::Code->server();
        if ($self->class eq __PACKAGE__) {
            Carp::confess("Missing template database file: $path!");
        }
        unless (-e $template_database_file) {
            Carp::confess("Missing template database file: $path!  Cannot initialize database for " . $self->class);
        }
        unless(File::Copy::copy($template_database_file,$path)) {
            Carp::confess("Error copying $path to $template_database_file to initialize database!");
        }
        unless(-e $path) {
            Carp::confess("File $path not found after copy from $template_database_file. Cannot initialize database!");
        }
    }
    return $path;
}

sub resolve_class_name_for_table_name_fixups {
    my $self = shift->_singleton_object;
    print "fixup @_";
    return $self->class . "::", @_;
}

1;
