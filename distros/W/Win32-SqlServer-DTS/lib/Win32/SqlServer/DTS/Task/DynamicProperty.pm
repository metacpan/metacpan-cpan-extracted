package Win32::SqlServer::DTS::Task::DynamicProperty;

=head1 NAME

Win32::SqlServer::DTS::Task::DynamicProperty - a subclass of Win32::SqlServer::DTS::Task to represent a DTSDynamicPropertiesTask object

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
      $app->get_db_package(
        { id => '', version_id => '', name => $config->{package}, package_password => '' } );

	my $iterator = $package->get_dynamic_props();

    while ( my $dyn_prop = $iterator->() ) {

        print $dyn_prop->to_string(), "\n";    

	}

    my $assign_iterator = $dyn_props->get_assignments;

    while ( my $assignment = $assign_iterator->() ) {

        print $assignment->to_string, "\n";

    }


=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Task::DynamicProperty> represents a DTS C<DynamicPropertiesTask> task.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use base qw(Win32::SqlServer::DTS::Task);
use Carp;
use Win32::OLE qw(in);
use Win32::SqlServer::DTS::AssignmentFactory;
use Hash::Util qw(lock_keys);
our $VERSION = '0.13'; # VERSION

=head2 METHODS

C<Win32::SqlServer::DTS::Task::DynamicProperty> inherits all methods from C<Win32::SqlServer::DTS::Task>, overriding those that are necessary.

=head3 count_assignments

Returns a integer with the number of assignments the DynamicPropertiesTask object has.

=cut

sub count_assignments {

    my $self = shift;

    my $assignments = $self->get_sibling->Assignments;
    my $counter;

    foreach ( in($assignments) ) {

        $counter++;

    }

    return $counter;

}

=head3 get_assignments

Returns a iterator, that, at each call, will return an C<Win32::SqlServer::DTS::Assignment> object until there are no more
assignments in the C<Win32::SqlServer::DTS::Task::DynamicProperty>.

See L</SYNOPSIS> to see an example of usage.

=cut

sub get_assignments {

    my $self = shift;

    my $assignments = $self->get_sibling->Assignments;
    my $total       = scalar( in($assignments) );
    my $counter     = 0;

    return sub {

        return unless ( $counter < $total );

        my $assignment = ( in($assignments) )[$counter];
        $counter++;

        return Win32::SqlServer::DTS::AssignmentFactory->create($assignment);

      }

}

=head3 to_string

Returns a string with all attributes of an C<Win32::SqlServer::DTS::Task::DynamicProperty> class. All attributes will have a
short description and will be separated by a new line character.

=cut

sub to_string {

    my $self = shift;

    my $properties_string;

    foreach my $item ( @{ $self->get_properties } ) {

        $properties_string = $properties_string . "\tType = $item->{type}\r\n";
        $properties_string =
          $properties_string . "\t\tSource = $item->{source}\r\n";
        $properties_string =
          $properties_string . "\t\tDestination = $item->{destination}\r\n";

    }

    return $properties_string;

}

1;

__END__

=head1 SEE ALSO

=over

=item *
L<Win32::SqlServer::DTS::Task> at C<perldoc>.

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
