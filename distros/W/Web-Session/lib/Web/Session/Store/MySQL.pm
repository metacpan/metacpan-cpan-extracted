package Web::Session::Store::MySQL;

use strict;

use Web::Session::Store::DBI;
use Apache::Session::Store::MySQL;

our @ISA =
  qw(Web::Session::Store::DBI Apache::Session::Store::MySQL);
our $VERSION = '1.0.0';

sub connection {
    my ( $self, $session ) = @_;

    # AutoCommit on: see "Why AutoCommit differs" in Store/DBI.pm
    $self->_connection( $session, 'Apache::Session::Store::MySQL',
        { RaiseError => 1, AutoCommit => 1 } );
    if ( $self->{dbh}->{Driver}->{Name} eq "mysql" ) {
        $self->{dbh}->{mysql_enable_utf8} = 1;
    }
}

1;

