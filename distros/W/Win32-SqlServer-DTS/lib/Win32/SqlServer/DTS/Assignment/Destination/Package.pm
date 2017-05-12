package Win32::SqlServer::DTS::Assignment::Destination::Package;

=head1 NAME

Win32::SqlServer::DTS::Assignment::Destination::Package - a subclass of Win32::SqlServer::DTS::Assignment::Destination for a package

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

        my $assign_iterator = $dyn_props->get_assignments();

        while ( my $assignment = $assign_iterator->() ) {

            my $dest = $assignment->get_destination();

		# checking all properties of the Package being handled by Dynamic Properties task
            if ( $dest->changes('Package') ) {

                print $dest->get_string(), "\n";

            }

        }

    }


=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Assignment::Destination::Package> is a subclass of C<Win32::SqlServer::DTS::Assignment::Destination> and represents the 
assignment destination of DTS package own properties.

The string returned by the C<get_string> method has this format: 

C<'Properties';name of the package property>.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use base qw(Win32::SqlServer::DTS::Assignment::Destination);
use Carp qw(confess);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=head3 initialize

C<initialize> method sets the I<destination> attribute as the DTS Package property name.

=cut

sub initialize {

    my $self = shift;

    $self->{destination} = ( split( /;/, $self->get_string() ) )[1];

    confess "'destination' attribute cannot be undefined\n"
      unless ( defined( $self->{destination} ) );

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
