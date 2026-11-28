package Web::Session::Store::MariaDBJSON;

use strict;

use DBI;
use Apache::Session::Store::MySQL;
use Web::Session::Store::DBI;

# Only id and a_session are written: indexed fields are generated columns
our @ISA     = qw(Apache::Session::Store::MySQL);
our $VERSION = '1.0.0';

# DBD::MariaDB always uses utf8mb4. DBD::mysql only selects the connection
# charset from attributes given to connect(): setting mysql_enable_utf8 on an
# open handle leaves the default charset of the client library (latin1 on
# some builds)
sub connectAttributes {
    my ( $class, $datasource ) = @_;
    my %attr = ( RaiseError => 1, AutoCommit => 1 );
    $attr{mysql_enable_utf8mb4} = 1 if ( $datasource =~ /^dbi:mysql\b/i );
    return \%attr;
}

sub connection {
    my ( $self, $session ) = @_;
    my $args = $session->{args};
    Web::Session::Store::DBI::_forgetInheritedHandle($self);

    # Same as Apache::Session::Store::MySQL, with the right connection
    # attributes
    unless ( defined $self->{dbh} or exists $args->{Handle} ) {
        my $datasource = $args->{DataSource}
          || $Apache::Session::Store::MySQL::DataSource;
        my $username = $args->{UserName}
          || $Apache::Session::Store::MySQL::UserName;
        my $password = $args->{Password}
          || $Apache::Session::Store::MySQL::Password;
        $self->{table_name} =
          $args->{TableName} || $Apache::Session::Store::DBI::TableName;
        my $attr = $self->connectAttributes($datasource);

        # Connection reuse (default), see Web::Session::Store::DBI. This
        # store doesn't inherit from it: it writes only id and a_session
        if ( my $dbh =
            Web::Session::Store::DBI::_reusedHandle( $self, $args,
                $datasource, $username, $password, $attr ) )
        {
            $self->{dbh}        = $dbh;
            $self->{disconnect} = 0;
            return;
        }
        $self->{dbh} =
          DBI->connect( $datasource, $username, $password, $attr )
          || die $DBI::errstr;

        # If we open the connection, we close the connection
        $self->{disconnect} = 1;
        return;
    }
    $self->SUPER::connection($session);
}

# update() and materialize() of Apache::Session::Store::DBI, keeping the
# serialized data that the database holds: update() doesn't rewrite an
# unchanged session, as the stores inheriting from Web::Session::Store::DBI
# (see "Unchanged sessions are not rewritten" there). Generated columns are
# computed from a_session: unchanged too
sub update {
    my ( $self, $session ) = @_;
    return if ( Web::Session::Store::DBI::_unchanged( $self, $session ) );
    $self->SUPER::update($session);
    Web::Session::Store::DBI::_remember( $self, $session );
}

sub materialize {
    my ( $self, $session ) = @_;
    $self->SUPER::materialize($session);
    Web::Session::Store::DBI::_remember( $self, $session );
}

1;
