package Win32::SqlServer::DTS::Application;

=head1 NAME

Win32::SqlServer::DTS::Application - a Perl class to emulate Microsoft SQL Server 2000 DTS Application object

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

    # fetchs a list of packages
    my @list = qw( LoadData ChangeData ExportData);

    foreach my $name ( @list ) {

        my $package = $self->get_db_package( { name => $name } ) );
        print $package->to_string;

    }


=head1 DESCRIPTION

This Perl class represents the Application object from the MS SQL Server 2000 API.
Before fetching any package from a server one must instantiate a C<Win32::SqlServer::DTS::Application> object that will provide
methods to fetch packages without having to provide autentication each time.

=head2 EXPORT

None by default.

=cut

use strict;
use warnings;
use Carp qw(confess cluck);
use base qw(Class::Accessor Win32::SqlServer::DTS);
use Win32::OLE 0.1704 qw(in);
use Win32::SqlServer::DTS::Package;
use Win32::SqlServer::DTS::Credential;
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(credential));

=head2 METHODS

=head3 new

Instantiate a new object from C<Win32::SqlServer::DTS::Application> class. The expected parameter is a hash reference with the 
following keys:

=over

=item *
server: the name of a database server already configured in the Enterprise Manager.

=item *
user: a string of the user used to authenticate against the database server. Not necessary to specify 
if C<use_trusted_connection> is true.

=item *
password: a string of the password used to authenticate against the database server. Not necessary to specify 
if C<use_trusted_connection> is true.

=item *
use_trusted_connection: a true/false value (1 or 0, respectivally) to specify if a Trusted Connection will be the
authentication method to be used.

=back

See L<SYNOPSIS|/SYNOPSIS> for an example.

=cut

sub new {

    my $class      = shift;
    my $properties = shift;

    confess "expects an hash reference as a parameter"
      unless ( ref($properties) eq 'HASH' );

    my $self;

    $self->{credential} = Win32::SqlServer::DTS::Credential->new($properties);

    $self->{_sibling} = Win32::OLE->new('DTS.Application');

    bless $self, $class;
    lock_keys( %{$self} );
    return $self;

}

=head3 get_db_package

Fetchs a single package from a MS SQL server and returns a respective C<Win32::SqlServer::DTS::Package> object. Expects a hash 
reference as a parameter, having the following keys defined:

=over

=item * 
id: the uniq package ID. Obligatory if a package C<name> is not provided.

=item *
version_id: the version ID of the package. If not provided, the last version of the package will be fetched.

=item *
name: the name of the package. Obligatory if a package C<id> is not provided.

=item *
package_password: the password used to restrict access to the package. Not obligatory if no password is used.

=back

=cut

sub get_db_package {

    my $self        = shift;
    my $options_ref = shift;

    # validates if the parameters are valid
    confess "Package name or ID must be informed\n"
      unless (
        (
                ( exists( $options_ref->{id} ) )
            and ( defined( $options_ref->{id} ) )
        )
        or (    ( exists( $options_ref->{name} ) )
            and ( defined( $options_ref->{name} ) ) )
      );

    $options_ref->{id}   = '' unless ( defined( $options_ref->{id} ) );
    $options_ref->{name} = '' unless ( defined( $options_ref->{name} ) );

    foreach my $attribute (qw(package_password version_id)) {

        $options_ref->{$attribute} = ''
          unless (
            (
                exists( $options_ref->{$attribute} )
                and ( defined( $options_ref->{$attribute} ) )
            )
          );

    }

    my $sql_package = Win32::OLE->new('DTS.Package2');

    my ( $server, $user, $password, $auth_code ) =
      $self->get_credential->to_list;

  #the last parameter is not even available for use, but the DTS API demands it:
    $sql_package->LoadFromSQLServer(
        $server,                          $user,
        $password,                        $auth_code,
        $options_ref->{package_password}, $options_ref->{id},
        $options_ref->{version_id},       $options_ref->{name},
        ''
    );

    confess "Could not fetch package information: "
      . Win32::OLE->LastError() . "\n"
      if ( Win32::OLE->LastError() );

    return Win32::SqlServer::DTS::Package->new($sql_package);

}

=head3 get_db_package_regex

Expect an regular expression as a parameter. The regular expression is case sensitive.

Returns a L<Win32::SqlServer::DTS::Package|Win32::SqlServer::DTS::Package> object which name matches the regular expression passed as 
an argument. Only one object is returned (the first one in a sorted list) even if there are more packages 
names that matches.

=cut

sub get_db_package_regex {

    my $self  = shift;
    my $regex = shift;

    my $package_name = @{ $self->regex_pkgs_names($regex) }[0];

    unless ( defined($package_name) ) {

        cluck "Could not find any package with regex like $regex";
        return undef;

    }
    else {

        return $self->get_db_package( { name => $package_name } );

    }

}

=head3 regex_pkgs_names

Expect an string, as regular expression, as a parameter. The parameter is case insensitive and the string is compiled
internally in the method, so there is not need to use L<qr|qr> or something like that to increase performance.

Returns an array reference with all the packages names that matched the regular expression passed as an argument.

=cut

sub regex_pkgs_names {

    my $self  = shift;
    my $regex = shift;

    my $list_ref = $self->list_pkgs_names();
    my @new_list;

    my $compiled_regex = qr/$regex/i;

    foreach my $name ( @{$list_ref} ) {

        push( @new_list, $name ) if ( $name =~ $compiled_regex );

    }

    return \@new_list;

}

=head3 list_pkgs_names

Returns an array reference with all the packages names available in the database of the MS SQL Server. The
items in the array are sorted for convenience.

=cut

sub list_pkgs_names {

    my $self = shift;

    my $sql_pkg =
      $self->get_sibling()
      ->GetPackageSQLServer( $self->get_credential->to_list() );

    confess "Could not connect to server: ", Win32::OLE->LastError(), "\n"
      if ( Win32::OLE->LastError() );

    my @list;

    foreach my $pkg_info ( in( $sql_pkg->EnumPackageInfos( '', 1, '' ) ) ) {

        push( @list, $pkg_info->Name );

    }

    @list = sort(@list);

    return \@list;

}

1;

__END__

=head1 CAVEATS

Several methods from MS SQL Server DTS Application class were not implemented, specially those available in
C<PackageSQLServer> and C<PackageRepository> classes.

=head1 SEE ALSO

=over

=item *
L<Win32::OLE> at C<perldoc>.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
