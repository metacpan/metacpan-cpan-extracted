# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Realm::DBIRealm;

=pod

=head1 NAME

Wombat::Realm::DBIRealm - internal realm base clas

=head1 SYNOPSIS

=head1 DESCRIPTION

Implementation of B<Wombat::Realm> that works with any DBI supported
database.

=cut

use base qw(Wombat::Realm::RealmBase);
use fields qw(connectionName connectionPassword connectionURL dbConnection);
use fields qw(driverName preparedCredentials preparedRoles roleNameCol);
use fields qw(userCredCol userNameCol userRoleTable userTable);
use strict;
use warnings;

use DBI ();
use Wombat::Exception ();
use Wombat::Realm::GenericPrincipal ();

use constant name => 'DBIRealm';

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Realm::RealmBase> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;
    $self->SUPER::new();

    $self->{connectionName} = undef;
    $self->{connectionPassword} = undef;
    $self->{connectionURL} = undef;
    $self->{dbConnection} = undef;
    $self->{driverName} = undef;
    $self->{roleNameCol} = undef;
    $self->{userCredCol} = undef;
    $self->{userNameCol} = undef;
    $self->{userRoleTable} = undef;
    $self->{userTable} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item setConnectionName($connectionName)

Set the username to use to connect to the database.

B<Parameters:>

=over

=item $connectionName

the database username

=back

=cut

sub setConnectionName {
    my $self = shift;
    my $connectionName = shift;

    $self->{connectionName} = $connectionName;

    return 1;
}

=pod

=item setConnectionPassword($connectionPassword)

Set the password to use to connect to the database.

B<Parameters:>

=over

=item $connectionPassword

the database password

=back

=cut

sub setConnectionPassword {
    my $self = shift;
    my $connectionPassword = shift;

    $self->{connectionPassword} = $connectionPassword;

    return 1;
}

=pod

=item setConnectionURL($connectionURL)

Set the URL to use to connect to the database. The URL is the part of
the DBI data source after the driver name. In this example

  DBI:mysql:hostname=localhost;port=12345;database=hi

the URL is

  hostname=localhost;port=12345;database=hi

B<Parameters:>

=over

=item $connectionURL

the database URL

=back

=cut

sub setConnectionURL {
    my $self = shift;
    my $connectionURL = shift;

    $self->{connectionURL} = $connectionURL;

    return 1;
}

=pod

=item setDriverName($driverName)

Set the DBI driver to use.

B<Parameters:>

=over

=item $driverName

the DBI driver name

=back

=cut

sub setDriverName {
    my $self = shift;
    my $driverName = shift;

    $self->{driverName} = $driverName;

    return 1;
}

=pod

=item setRoleNameCol($roleNameCol)

Set the column in the user role table that names a role.

B<Parameters:>

=over

=item $roleNameCol

the column name

=back

=cut

sub setRoleNameCol {
    my $self = shift;
    my $roleNameCol = shift;

    $self->{roleNameCol} = $roleNameCol;

    return 1;
}

=pod

=item setUserCredCol($userCredCol)

Set the column in the user table that holds the user's credentials.

B<Parameters:>

=over

=item $userCredCol

the column name

=back

=cut

sub setUserCredCol {
    my $self = shift;
    my $userCredCol = shift;

    $self->{userCredCol} = $userCredCol;

    return 1;
}

=pod

=item setUserNameCol($userNameCol)

Set the column in the user table that holds the user's name.

B<Parameters:>

=over

=item $userNameCol

the column name

=back

=cut

sub setUserNameCol {
    my $self = shift;
    my $userNameCol = shift;

    $self->{userNameCol} = $userNameCol;

    return 1;
}

=pod

=item setUserRoleTable($userRoleTable)

Set the table that holds the relation between users and roles.

B<Parameters:>

=over

=item $userRoleTable

the table name

=back

=cut

sub setUserRoleTable {
    my $self = shift;
    my $userRoleTable = shift;

    $self->{userRoleTable} = $userRoleTable;

    return 1;
}

=item setUserTable($userTable)

Set the table that holds user data.

B<Parameters:>

=over

=item $userTable

the table name

=back

=cut

sub setUserTable {
    my $self = shift;
    my $userTable = shift;

    $self->{userTable} = $userTable;

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item authenticate ($username, $credentials)

Return the Principal associated with the specified username and
credentials, if there is one, or C<undef> otherwise.

If there are any errors with the DBI connection, executing the query
or anything else, do not authenticate and return C<undef>. This event
is also logged, and the connection will be closed so that a subsequent
request will automatically re-open it.

B<Parameters>

=over

=item $username

username of the principal to be looked up

=item $credentials

password or other credentials to use in authenticating this username

=back

=cut

sub authenticate {
    my $self = shift;
    my $username = shift;
    my $credentials = shift;

    my $principal;
    eval {
        $self->open();

        unless ($self->{preparedCredentials}) {
            my $str = sprintf("SELECT %s FROM %s WHERE %s = ?",
                              $self->{userCredCol},
                              $self->{userTable},
                              $self->{userNameCol});
            $self->{preparedCredentials} =
                $self->{dbConnection}->prepare($str);
        }

        my $sth = $self->{preparedCredentials};
        my $rs = $self->{dbConnection}->selectcol_arrayref($sth, {},
                                                           $username);

        my $password = $rs->[0];
        return undef unless defined $password;

        return undef unless $self->digest($credentials) eq $password;

        unless ($self->{preparedRoles}) {
            my $str = sprintf("SELECT %s FROM %s WHERE %s = ?",
                              $self->{roleNameCol},
                              $self->{userRoleTable},
                              $self->{userNameCol});
            $self->{preparedRoles} = $self->{dbConnection}->prepare($str);
        }

        $sth = $self->{preparedRoles};
        $rs = $self->{dbConnection}->selectcol_arrayref($sth, {}, $username);

        $principal = Wombat::Realm::GenericPrincipal->new($self,
                                                          $username,
                                                          $credentials,
                                                          $rs);
    };
    if ($@) {
        $self->log("DBIRealm database exception", $@, 'ERROR');

        # close the connection so that it gets reopened next time
        $self->close();

        return undef;
    }

    return $principal;
}

=pod

=back

=head1 PACKAGE METHODS

=over

=item close()

Close the database connection.

=cut

sub close {
    my $self = shift;

    return 1 unless $self->{dbConnection};

    $self->{dbConnection}->disconnect();
    delete $self->{dbConnection};

    return 1;
}

=pod

=item getName()

Return a short name for this Realm implementation.

=cut

sub getName {
    my $self = shift;

    return name;
}

=pod

=item open()

Open the database connection.

=cut

sub open {
    my $self = shift;

    return 1 if $self->{dbConnection};

    my $dsn = join ':', 'DBI', $self->{driverName}, $self->{connectionURL};
    $self->{dbConnection} = DBI->connect($dsn,
                                         $self->{connectionName},
                                         $self->{connectionPassword},
                                         {RaiseError => 1,
                                          PrintError => 0});
    die $DBI::errstr unless $self->{dbConnection};

    return 1;
}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for active use of this Realm, opening the database
connection. This method should be called before any of the public
methods of the Realm are utilized.

B<Throws:>

=over

=item B<Servlet::Util::Exception>

if the Realm has already been started

=back

=cut

sub start {
    my $self = shift;

    eval {
        $self->open();
    };
    if ($@) {
        $self->{dbConnection}->disconnect() if $self->{dbConnection};

        my $msg = "DBIRealm: database connection error: $@";
        Wombat::LifecycleException->throw($msg);
    }

    $self->SUPER::start();

    return 1;
}

=pod

=item stop()

Gracefully terminate active use of this Realm, closing the database
connection. Once this method has been called, no public methods of the
Realm should be utilized.

B<Throws:>

=over

=item B<Servlet::Util::Exception>

if the Realm is not started

=back

=cut

sub stop {
    my $self = shift;

    $self->SUPER::stop();

    eval {
        $self->close();
    };
    if ($@) {
        my $msg = "DBIRealm: database disconnection error: $@";
        Wombat::LifecycleException->throw($msg);
    }

    return 1;
}

1;
__END__

=pod

=back

=cut

=head1 SEE ALSO

L<DBI>,
L<Wombat::Realm::RealmBase>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
