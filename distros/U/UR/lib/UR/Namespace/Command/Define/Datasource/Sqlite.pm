package UR::Namespace::Command::Define::Datasource::Sqlite;

use strict;
use warnings;
use UR;
our $VERSION = "0.47"; # UR $VERSION;

use IO::File;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => [ 'UR::Namespace::Command::Define::Datasource::Rdbms' ],
);

sub help_brief {
   "Add a SQLite data source to the current namespace."
}

sub help_synopsis {
    return <<EOS
  cd Acme

  ur define datasource sqlite --dsname MyDB1 
  # writes Acme::DataSource::MyDB1 to work with Acme/DataSource/MyDB1.sqlite3
  
  ur define datasource sqlite --dsname MyDB2 --server /var/lib/acmeapp/mydb2.sqlite3
  # writes Acme::DataSource::MyDB2 to work with the specified sqlite file
EOS
}

sub _data_source_sub_class_name {
    "UR::DataSource::SQLite"
}

sub server {
    my $self = shift;

    my $super_server = $self->super_can('server');
    if (@_) {
        # unusual case, setting the server
        return $super_server($self,@_);
    }

    my $server = $super_server->($self);
    unless ($server) {
        $server = $self->data_source_module_pathname();
        $server =~ s/\.pm$/.sqlite3/;
        $super_server->($self,$server);
    }
    return $server;
}

sub _post_module_written {
    my $self = shift;

    # Create a new, empty DB if it dosen't exist yet
    my $pathname = $self->server;
    $pathname =~ s/\.pm$/.sqlite3/;
    IO::File->new($pathname, O_WRONLY | O_CREAT) unless (-f $pathname);
    $self->status_message("A   $pathname (empty database schame)");

    return 1;
}


1;

