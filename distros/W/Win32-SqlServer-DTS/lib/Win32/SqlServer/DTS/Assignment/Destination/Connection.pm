package Win32::SqlServer::DTS::Assignment::Destination::Connection;

=head1 NAME

Win32::SqlServer::DTS::Assignment::Destination::Connection - a subclass of Win32::SqlServer::DTS::Assignment::Destination for connections

=head1 SYNOPSIS

    use warnings;
    use strict;
    use Win32::SqlServer::DTS::Application;
    my $xml = XML::Simple->new();
    my $config = $xml->XMLin('test-config.xml');

    my $app = Win32::SqlServer::DTS::Application->new($config->{credential});

    my $package =
      $app->get_db_package(
        { id => '', version_id => '', name => $config->{package}, package_password => '' } );

	my $iterator = $package->get_dynamic_props();

    while ( my $dyn_prop = $iterator->() ) {

        my $iterator = $dyn_props->get_assignments();

        while ( my $assignment = $iterator->() ) {

            my $dest = $assignment->get_destination();

            if ( $dest->changes('Connection') ) {

                print $dest->get_string(), "\n";

            }

        }
    
    }


=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Assignment::Destination::Connection> is a subclass of C<Win32::SqlServer::DTS::Assignment::Destination> and represents the 
global variables as the assignments destinations of a DTS package.

The string returned by the C<get_string> method has this format: 

C<'Connections';name of the connection;'Properties';name of the property>.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use Carp qw(confess);
use base qw(Win32::SqlServer::DTS::Assignment::Destination);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=cut

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(conn_name));

=head3 initialize

C<initialize> method sets the I<destination> attribute as a DTS Package connection property. It also sets the 
attribute I<conn_name> with the connection name.

=cut

sub initialize {

    my $self = shift;

    my @values = split( /;/, $self->get_string() );

	$self->{destination} = $values[3];
	$self->{conn_name} = $values[1];

    confess "'destination' attribute cannot be undefined\n"
      unless ( defined( $self->{destination} ) );

    confess "'conn_name' attribute cannot be undefined\n"
      unless ( defined( $self->{conn_name} ) );

}

1;
__END__

=head1 SEE ALSO

=over

=item *
L<Win32::SqlServer::DTS::Assignment> at C<perldoc>.

=item *
L<Win32::SqlServer::DTS::Assignment::Destination> at C<perldoc>.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but one will need to convert examples written in VBScript to Perl code.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
