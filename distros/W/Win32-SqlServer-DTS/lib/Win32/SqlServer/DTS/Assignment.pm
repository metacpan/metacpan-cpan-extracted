package Win32::SqlServer::DTS::Assignment;

=head1 NAME

Win32::SqlServer::DTS::Assignment - a Perl base class to represent a DTS Dynamic Properties task Assignment object

=head1 SYNOPSIS

 package Win32::SqlServer::DTS::Assignment::SomethingWeird;
 use base (Win32::SqlServer::DTS::Assignment);

 #and goes on defining the child class

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Assignment> is a base class that should be inherited by a specialized class that defines one type of
Assignment object that is part of a DTS Dynamic Property task.

This class defines some common attributes that a subclass of C<Win32::SqlServer::DTS::Assignment>. Some methods must be override too,
and are explained in the next sections.

=head2 EXPORT

None by default.

=cut

use strict;
use warnings;
use base qw(Win32::SqlServer::DTS);
use Carp qw(confess);
use Win32::SqlServer::DTS::AssignmentTypes;
use Win32::SqlServer::DTS::Assignment::DestinationFactory;
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=head3 new

Instantiates a new C<Win32::SqlServer::DTS::Assigment> object. Expects as parameter a C<DynamicPropertiesTaskAssignment> object. 
Unless you want to extend the C<Win32::SqlServer::DTS::Assignment> class, you will want to fetch C<Win32::SqlServer::DTS::Assignment> objects using 
the C<get_properties> method from L<Win32::SqlServer::DTS::Task::DynamicProperty|Win32::SqlServer::DTS::Task::DynamicProperty> class.

=cut

sub new {

    my $class = shift;
    my $self = { _sibling => shift };

    bless $self, $class;

    my $sibling = $self->get_sibling();

    $self->{destination} = Win32::SqlServer::DTS::Assignment::DestinationFactory->create(
        $sibling->{DestinationPropertyID} );

    # subscribing to the event of changing the destination string in the
    # Win32::SqlServer::DTS::Assignment::Destination object
    $self->{destination}
      ->add_subscriber( 'changed', sub { $self->_set_destination() } );

    $self->{typename} =
      Win32::SqlServer::DTS::AssignmentTypes->get_class_name( $sibling->SourceType() );

    $self->{type} = $sibling->SourceType();

    return $self;

}

=head3 get_type

Returns the type as a numeric code for a instantied object of a subclass of C<Win32::SqlServer::DTS::Assignment>.

=cut

sub get_type {

    my $self = shift;
    return $self->{type};

}

=head3 get_type_name

Returns a type as a string converted from the original numeric code using L<Win32::SqlServer::DTS::AssignmentTypes|Win32::SqlServer::DTS::AssignmentTypes>
abstract class to make the convertion.

=cut

sub get_type_name {

    my $self = shift;
    return $self->{typename};

}

=head3 get_source

This method should be override by any subclass of C<Win32::SqlServer::DTS::Assignment>. If invoked but not overrided, it will abort
program execution with an error message.

=cut

sub get_source {

    confess
"This method should be override by an specialized subclass of Win32::SqlServer::DTS::Assignment\n";

}

=head3 get_destination

Returns a C<Win32::SqlServer::DTS::Assignment::Destination> object. See L<Win32::SqlServer::DTS::Assignment::Destination> for more details about how
to use Destination objects.

A C<Win32::SqlServer::DTS::Assignment::Destination> object is not part of the official MS SQL Server DTS API, but is easier to use and
do not use L<Win32::OLE|Win32::OLE> directly (so there are no great performance penalties).

=cut

sub get_destination {

    my $self = shift;

    return $self->{destination};

}

=head3 set_destination

Sets the Destination string in the assignment (in other words, it writes directly in the DTS package). To be able to
invoke this method, the C<Win32::SqlServer::DTS::Assignment> should not have invoke the C<kill_sibling> method before, since writing
the DTS package requires having the C<_sibling> attribute defined.

The method will check such condition and will abort program execution in such cases.

Once the string is modified successfully in the package, the C<Win32::SqlServer::DTS::Assignment::Destination> will be modified as well
(a new instance will be created).

=cut

sub set_destination {

    my $self       = shift;
    my $new_string = shift;

    # modifying both attributes. set_string does some validation,
    # so it's being called first
    $self->{destination}->set_string($new_string);

    confess "The new string cannot be undefined"
      unless ( defined($new_string) );

    $self->get_sibling()->DestinationPropertyID = $new_string;

}

# destination object is already updated, fetching the
# string value from the object
sub _set_destination {

    my $self = shift;

    $self->get_sibling()->DestinationPropertyID() =
      $self->{destination}->get_raw_string();

}

=head3 get_properties

Returns all properties from an assignment object as a hash reference, having the following keys:

=over

=item *
type

=item *
source

=item *
destination

=back

Since the method C<get_source> must be overrided by subclasses of C<Win32::SqlServer::DTS::Assignment>, C<get_properties> will fail unless invoked 
thru one of those subclasses.

=cut

sub get_properties {

    my $self = shift;

    return {
        type        => $self->get_type(),
        source      => scalar( $self->get_source() ),
        destination => scalar( $self->get_destination() )
      }

}

=head3 to_string 

Returns a string with the type, source and destination of an assignment. Useful for debugging or reporting.

=cut

sub to_string {

    my $self = shift;

    return $self->get_type_name
      . " assignment\n"
      . 'Source: '
      . $self->get_source . "\n"
      . 'Destination: '
      . $self->get_destination . "\n";

}

1;

__END__

=head1 SEE ALSO

=over

=item *
L<Win32::OLE> at C<perldoc>.

=item *
L<Win32::SqlServer::DTS::AssignmentFactory> at C<perldoc>.

=item *
L<Win32::SqlServer::DTS::Assignment::Destination> and all subclasses of it at C<perldoc>.

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
