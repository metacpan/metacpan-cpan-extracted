package Win32::SqlServer::DTS::Task;

=head1 NAME

Win32::SqlServer::DTS::Task - a Perl base class to access Microsoft SQL Server 2000 DTS tasks

=head1 SYNOPSIS

    use Win32::SqlServer::DTS::Task;

    # $task is an already instantied class using Win32::OLE
    my $custom_task = Win32::SqlServer::DTS::Task->new( $task->CustomTaskID, $task->CustomTask );

    # prints the custom task name
    print $custom_task->get_name, "\n";

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Task> is an base class to be subclassed: one should not use it directly (although it may work). See 
L<SEE ALSO|/SEE ALSO> for more information about the classed that uses C<Win32::SqlServer::DTS::Task> as part of their inheritance.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use Carp qw(confess);
use base qw(Win32::SqlServer::DTS);
use Win32::SqlServer::DTS::TaskTypes;
our $VERSION = '0.13'; # VERSION

=head2 METHODS

=head3 new

Creates a new C<Win32::SqlServer::DTS::Task> object. It should be overrided by subclasses, since it defines only general attributes.
Expects a C<DTS Task> object. Returns a new C<Win32::SqlServer::DTS::Task> object.

One should not invoke this method directly, unless wants to extended the C<DTS> API. See L<Win32::SqlServer::DTS::Package> for more
information about how to fetch C<Win32::SqlServer::DTS::Task> objects easialy.

=cut

sub new {
    my $class = shift;
    my $task  = shift;
    my $self = { _sibling => $task->CustomTask };
    bless $self, $class;
    my $sibling = $self->get_sibling;
    $self->{name}        = $sibling->Name;
    $self->{description} = $sibling->Description;
    my $type = Win32::SqlServer::DTS::TaskTypes::convert( $task->CustomTaskID );

    if ( defined($type) ) {
        $self->{type} = $type;
        return $self;
    }
    else {
        confess 'Type '
          . $sibling->CustomTaskID
          . ' is not a implemented Win32::SqlServer::DTS::Task subclasses';
    }

}

=head3 get_name

Returns a string with the name of the task.

=cut

sub get_name {
    my $self = shift;
    return $self->{name};
}

=head3 get_description

Returns a string with the description of the task.

=cut

sub get_description {
    my $self = shift;
    return $self->{description};
}

=head3 get_type

Returns a string of type of the task.

=cut

sub get_type {
    my $self = shift;
    return $self->{type};
}

=head3 get_properties

Deprecated. This method is not as useful as it may be seen, since the to_string method does a better job reporting everything
about the Task.

=head3 to_string

Not implemented. Some tasks fetch their properties in a different manner. Use this method only
in subclasses from C<Win32::SqlServer::DTS::Task>.

If this method is not override in subclasses it will cause the application to die. Once overrided, it will fetch 
and return a string with all properties in a nicely manner for printing.

=cut

sub to_string {
    confess "print_properties must be defined in a specialized Win32::SqlServer::DTS::Task class\n";
}

1;
__END__

=head1 SEE ALSO

=over

=item *
L<Win32::OLE> at C<perldoc>.

=item *
L<Win32::SqlServer::DTS::Package> at C<perldoc> to see how to fetch C<Win32::SqlServer::DTS::Task> objects.

=item *
L<Win32::SqlServer::DTS::TaskFactory> at C<perldoc> to see how to instantiate new objects from C<Win32::SqlServer::DTS::Task> subclasses in a 
polymorphic way.

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
