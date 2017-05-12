package Win32::SqlServer::DTS::Task::ExecutePackage;

=head1 NAME

Win32::SqlServer::DTS::Task::ExecutePackage - a subclass of Win32::SqlServer::DTS::Task to represent a DTSExecutePackageTask object

=head1 SYNOPSIS

    use warnings;
    use strict;
    use Win32::SqlServer::DTS::Application;
    use Test::More;
    use XML::Simple;

    my $xml = XML::Simple->new();
    my $config = $xml->XMLin('test-config.xml');

    my $app = Win32::SqlServer::DTS::Application->new($config->{credential});

    my $package =
        $app->get_db_package({ id => '', version_id => '', name => $config->{package}, package_password => '' } );

    my $total_exec_pkgs = $package->count_execute_pkgs;

    plan tests => $total_exec_pkgs;

    SKIP: {

        skip 'The package has no Execute Package task', 1
          unless ( $total_exec_pkgs > 0 );

        my $package_name;

		my $iterator = $package->get_execute_pkgs();

        while ( my $execute_pkg = $iterator->() ) {

            $package_name = 'Execute Package task "' . $execute_pkg->get_name() . '"';

            is( $execute_pkg->get_package_id(),
                '', "$package_name must have Package ID empty" );

            $package_name = '';

        }

    }


=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Task::ExecutePackage> class represents a DTS ExecutePackage task.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use Carp;
use base qw(Win32::SqlServer::DTS::Task Class::Accessor);
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

All methods from L<Win32::SqlServer::DTS::Task|Win32::SqlServer::DTS::Task> are also available.

=cut

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(package_id package_name package_password repository_database_name server_name
      server_password server_username file_name)
);

=head3 new

Overrides the superclass C<Win32::SqlServer::DTS::Task> C<new> method by defining the following attributes:

=over

=item *

package_id

=item *

package_name

=item *

package_password

=item *

repository_database_name

=item *

server_name

=item *

server_password

=item *

server_username

=item *

use_repository

=item *

use_trusted_connection

=item *

file_name

=item *

input_global_variable_names

=back

=cut

sub new {

    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->{package_id}   = $self->get_sibling->Properties->Parent->PackageID;
    $self->{package_name} = $self->get_sibling->Properties->Parent->PackageName;

    $self->{package_password} =
      $self->get_sibling->Properties->Parent->PackagePassword;

    $self->{repository_database_name} =
      $self->get_sibling->Properties->Parent->RepositoryDatabaseName;

    $self->{server_name} = $self->get_sibling->Properties->Parent->ServerName;

    $self->{server_password} =
      $self->get_sibling->Properties->Parent->ServerPassword;

    $self->{server_username} =
      $self->get_sibling->Properties->Parent->ServerUsername;

    $self->{use_repository} =
      $self->get_sibling->Properties->Parent->UseRepository;

    $self->{use_trusted_connection} =
      $self->get_sibling->Properties->Parent->UseTrustedConnection;

    $self->{file_name} = $self->get_sibling->Properties->Parent->FileName;

    $self->{input_global_variable_names} =
      $self->get_sibling->Properties->Parent->InputGlobalVariableNames;

    lock_keys( %{$self} );

    return $self;

}

=head3 get_input_vars

Returns the C<InputGlobalVariableNames> property from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task, which is a string
containing each global variable name separated by a semicolon character (;), optionally double-quoted 
or single-quoted list. Quoting is required only when the name contains an embedded delimiter

=cut

sub get_input_vars {

    my $self = shift;
    return $self->{input_global_variable_names};

}

=head3 get_ref_input_vars

Same as C<get_input_vars>, but returns an array reference instead of a string. Single or double quotes are 
removed too (but only those ones at the start and end of the global variable name).

=cut

sub get_ref_input_vars {

    my $self = shift;
    my @list = split( /\;/, $self->get_input_vars );

    foreach (@list) {

        tr/\"//d;
        tr/\'//d;

    }

    return \@list;

}

=head3 uses_repository

Returns true or false depending if the C<Win32::SqlServer::DTS::Task::ExecutePackage> object uses MS SQL Server 2000 Meta Data
Services. Same thing as C<UseRepository> property of DTS ExecutePackage task.

=cut

sub uses_repository {

    my $self = shift;
    return $self->{use_repository};

}

=head3 use_trusted

Returns true or false whether the C<Win32::SqlServer::DTS::Task::ExecutePackage> object uses a B<trusted connection> to authenticate
against a SQL Server.

=cut

sub use_trusted {

    my $self = shift;

    return $self->{use_trusted_connection};

}

=head3 to_string

Overrides superclass C<Win32::SqlServer::DTS::Task> method C<to_string> to return strings for all defined attributes
of the object.

=cut

sub to_string {

    my $self = shift;

    return "\tTask name: "
      . $self->get_name
      . "\r\n\t"
      . 'Task description: '
      . $self->get_description
      . "\r\n\t"
      . 'Task type: '
      . $self->get_type
      . "\r\n\t"
      . 'Package ID: '
      . $self->get_package_id
      . "\r\n\t"
      . 'Package name: '
      . $self->get_package_name
      . "\r\n\t"
      . 'Package password: '
      . $self->get_package_password
      . "\r\n\t"
      . 'Server name: '
      . $self->get_server_name
      . "\r\n\t"
      . 'Server username: '
      . $self->get_server_username
      . "\r\n\t"
      . 'Server password: '
      . $self->get_server_password
      . "\r\n\t"
      . 'Repository is used? '
      . ( ( $self->uses_repository ) ? 'true' : 'false' )
      . "\r\n\t"
      . 'Filename: '
      . $self->get_file_name
      . "\r\n\t"
      . 'Connection trusted based? '
      . ( ( $self->use_trusted ) ? 'true' : 'false' )
      . "\r\n\t"
      . 'Input global variables: '
      . $self->get_input_vars . "\r\n";

}

1;

__END__

=head3 get_package_id

Returns the C<PackageID> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head3 get_package_name

Returns the C<PackageName> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head3 get_package_password

Returns the C<PackagePassword> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head3 get_repository_database_name

Returns the C<RepositoryDatabaseName> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head3 get_server_name

Returns the C<ServerName> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head3 get_server_password

Returns the C<ServerName> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head3 get_server_username

Returns the C<ServerUserName> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head3 get_file_name

Returns the C<FileName> property as a string from a C<Win32::SqlServer::DTS::Task::ExecutePackage> task.

=head1 SEE ALSO

=over

=item *
L<Win32::SqlServer::DTS::Task|Win32::SqlServer::DTS::Task> superclass from where C<Win32::SqlServer::DTS::Task::ExecutePackage> inherits.

=item *
L<Win32::OLE|Win32::OLE> at Active Perl perldoc.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
