package Win32::SqlServer::DTS::Connection;

=head1 NAME

Win32::SqlServer::DTS::Connection - a Perl class to represent a Microsoft SQL Server 2000 DTS Connection object

=head1 SYNOPSIS

    use Win32::SqlServer::DTS::Application;

    my $app = Win32::SqlServer::DTS::Application->new(
        {
            server                 => $server,
            user                   => $user,
            password               => $password,
            use_trusted_connection => 0
        }
    );

    my $package = $app->get_db_package(
        { id => '', version_id => '', name => 'some_package', package_password => '' } );

    my $iterator = $package->get_connections();

    while ( my $conn = $iterator->() ) {

        print $conn->get_name(), "\n";

    }

    # or if you have $connection as a regular 
    # MS SQL Server Connection object

    my $conn2 = Win32::SqlServer::DTS::Connection->new($connection);
    print $conn2->to_string(), "\n";

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Connection> class represent a DTS Connection object, serving as a layer to fetch properties
from the DTS Connection stored in the C<_sibling> attribute.

Although it's possible to create an C<Win32::SqlServer::DTS::Connection> object directly (once a DTS Connection object is available), one
will probably fetch connections from a package using the C<get_connections> method from the L<Win32::SqlServer::DTS::Package|Win32::SqlServer::DTS::Package> 
module.

=head2 EXPORT

None by default.

=cut

use strict;
use warnings;
use Carp;
use base qw(Class::Accessor Win32::SqlServer::DTS);
use Win32::OLE qw(in);
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(oledb catalog datasource description id name password provider user));

=head2 METHODS

Inherints all methods from L<DTS|DTS> superclass.

=head3 new

The only expected parameter to the C<new> method is an already available DTS Connection object. Returns a 
C<Win32::SqlServer::DTS::Connection> object.

=cut

sub new {

    my $class = shift;
    my $self = { _sibling => shift };

    bless $self, $class;

    my $sibling = $self->get_sibling;

    $self->{catalog}     = $sibling->Catalog;
    $self->{datasource}  = $sibling->DataSource;
    $self->{description} = $sibling->Description;
    $self->{id}          = $sibling->ID;
    $self->{name}        = $sibling->Name;
    $self->{password}    = $sibling->Password;
    $self->{provider}    = $sibling->ProviderID;
    $self->{user}        = $sibling->UserID;

    $self->{oledb} = $self->_init_oledb_props;

    lock_keys( %{$self} );

    return $self;

}

=head3 get_type

Fetchs the I<provider> value of the connection. It is an alias for the C<get_provider> method.

=cut

sub get_type {

    my $self = shift;
    return $self->get_provider();

}

sub _init_oledb_props {

    my $self = shift;
    my %props;

    foreach my $property ( in( $self->get_sibling->ConnectionProperties ) ) {

        my $key = $property->Name;
        $key =~ tr/ //d;

        $props{$key} = {
            name         => $property->Name,
            property_id  => $property->PropertyID,
            property_set => $property->PropertySet,
            value => ( defined( $property->Value ) ) ? $property->Value : ''
        };

    }

    # converting numeric code to string
    if ( exists( $props{FileType} ) ) {

      CASE: {

            if ( $props{FileType}->{value} == 2 ) {

                $props{FileType}->{value} = 'UTF';
                last CASE;

            }

            if ( $props{FileType}->{value} == 1 ) {

                $props{FileType}->{value} = 'ASCII';
                last CASE;

            }

            if ( $props{FileType}->{value} == 4 ) {

                $props{FileType}->{value} = 'OEM';
                last CASE;

            }

        }

    }

    return \%props;

}

=head3 to_string

Returns a string with all properties (but those returned by C<get_oledb> method) from the a C<Win32::SqlServer::DTS::Connection>
object. Each property will have a short description before the value and will be separated by new line characters.

=cut

sub to_string {

    my $self = shift;

    my $string =
        "\tName: "
      . $self->get_name
      . "\n\tDescription: "
      . $self->get_description
      . "\n\tID: "
      . $self->get_id
      . "\n\tCatalog: "
      . $self->get_catalog
      . "\n\tData Source: "
      . $self->get_datasource
      . "\n\tUser: "
      . $self->get_user
      . "\n\tPassword: "
      . $self->get_password
      . "\n\tProvider: "
      . $self->get_provider;

    return $string;

}

1;
__END__

=head3 get_name

Fetchs the name of the connection.

=head3 get_description

Fetchs the description of the connection.

=head3 get_datasource

Fetchs the datasource value of the connection.

=head3 get_catalog

Fetchs the catalog value of the connection, if available.

=head3 get_id

Fetchs the connection ID. This ID is used as an connection reference by the tasks in a DTS package that 
needs a connection.

=head3 get_provider

Fetchs the provider name of the connection. Althought DTS Connection object support various types of connections,
at this version, C<Win32::SqlServer::DTS::Connection> will work only with B<DTSFlatFile> and B<SQLOLEDB> providers.

=head3 get_user

Fetchs the user used in the authentication of the connection.

=head3 get_password

Fetchs the password used in the authentication of the connection.

=head3 get_oledb

Returns an hash reference with all OLEDB properties used by the connection, being each key (a property) value 
a hash reference itself.

Being a property a hash reference, it contaings by default the following keys: C<name>, C<value>, C<property_id> 
and C<property_set>. These keys correspond to the properties C<Name>, C<Value>, C<PropertyID> and C<PropertySet> 
from the original property defined in the DTS API.

Only for the property C<FileType>, that is a convertion from numeric code to the proper string.

=head1 CAVEATS

This class should be subclassed very soon to two new classes: C<Win32::SqlServer::DTS::Connection::FlatFile> and 
C<Win32::SqlServer::DTS::Connection::OLEBD> to enable polymorphic method calls.

=head1 SEE ALSO

=over

=item *
L<DTS> at C<perldoc>.

=item *
L<Win32::SqlServer::DTS::Application> at C<perldoc>.

=item *
L<Win32::SqlServer::DTS::Package> at C<perldoc>.

=item *
L<Win32::OLE> at C<perldoc>.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=back

=head1 CAVEATS

This API is incomplete. There are much more properties defined in the MS SQL Server 2000 DTS API.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
