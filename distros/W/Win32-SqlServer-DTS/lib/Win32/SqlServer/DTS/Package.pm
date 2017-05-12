package Win32::SqlServer::DTS::Package;

=head1 NAME

Win32::SqlServer::DTS::Package - a Perl class to access Microsoft SQL Server 2000 DTS Packages 

=head1 SYNOPSIS

  use Win32::SqlServer::DTS::Package;

	# $OLE_package is an already instantied class using Win32::OLE
	my $package = Win32::SqlServer::DTS::Package->new( $OLE_package );

	# prints the custom task name
	print $custom_task->get_name, "\n";

=head1 DESCRIPTION

C<Win32::SqlServer::DTS::Package> is an class created to be used as a layer that represent a package object in DTS packages.

=head2 EXPORT

Nothing.

=cut

use strict;
use warnings;
use Carp qw(confess);
use base qw(Class::Accessor Win32::SqlServer::DTS);
use Win32::SqlServer::DTS::TaskFactory;
use Win32::SqlServer::DTS::Connection;
use Win32::OLE qw(in);
use Win32::SqlServer::DTS::DateTime;
use Win32::SqlServer::DTS::Package::Step;
use Hash::Util qw(lock_keys);
use File::Spec;
use Win32::SqlServer::DTS::TaskTypes;
our $VERSION = '0.13'; # VERSION

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(
    qw(creation_date creator_computer description log_file max_steps name id priority version_id )
);

=head2 METHODS

=head3 execute

Execute all the steps available in the package.

Requires that the C<_sibling> attribute exists and is defined correctly, otherwise method call will abort program 
execution.get_connections

Returns a array reference with C<Win32::SqlServer::DTS::Package::Step::Result> objects for error checking.

=cut

sub execute {

    my $self = shift;

    $self->get_sibling()->Execute();

    my $iterator = $self->get_steps();

    my @results;

    while ( my $step = $iterator->() ) {

        push( @results, $step->get_exec_error_info() );

    }

    return \@results;

}

=head3 get_steps

Returns an iterator to get all steps defined inside the DTS package. Each call to the iterator (that is a code reference) 
will return a C<Win32::SqlServer::DTS::Package::Step> object until all steps are returned.

=cut

sub get_steps {

    my $self = shift;

    my $steps   = $self->get_sibling()->Steps;
    my $total   = scalar( in($steps) );
    my $counter = 0;

    return sub {

        return unless ( $counter < $total );

        my $step = ( in($steps) )[$counter];

        $counter++;

        return Win32::SqlServer::DTS::Package::Step->new($step);

      }

}

=head3 log_to_server

Returns true or false (in Perl terms, this means 1 or 0 respectivally) if the "Log package execution to SQL Server" is 
set.

=cut

sub log_to_server {

    my $self = shift;
    return $self->{log_to_server};

}

=head3 auto_commit

Returns true or false (in Perl terms, this means 1 or 0 respectivally) if the "Auto Commit Transaction property" is set.

=cut

sub auto_commit {

    my $self = shift;
    return $self->{auto_commit};

}

=head3 new

Expects a DTS.Package2 object as a parameter and returns a new C<Win32::SqlServer::DTS::Package> object.

Not all properties from a DTS.Package2 will be available, specially the inner objects inside a DTS package will
be available only at execution of the respective methods. These methods may depend on the C<_sibling> attribute,
so one should not remove it before invoking those methods. The documentation tells where the method depends or
not on C<_sibling> attribute.

=cut

sub new {

    my $class = shift;
    my $self = { _sibling => shift };

    bless $self, $class;

    $self->{auto_commit}      = $self->get_sibling()->AutoCommitTransaction;
    $self->{creator_computer} = $self->get_sibling()->CreatorComputerName;
    $self->{description}      = $self->get_sibling()->Description;
    $self->{fail_on_error}    = $self->get_sibling()->FailOnError;
    $self->{log_file}         = $self->get_sibling()->LogFileName;
    $self->{max_steps}        = $self->get_sibling()->MaxConcurrentSteps;
    $self->{name}             = $self->get_sibling()->Name;
    $self->{id}               = $self->get_sibling()->PackageID;
    $self->{version_id}       = $self->get_sibling()->VersionID;
    $self->{nt_event_log} =
      $self->{_sibling}->WriteCompletionStatusToNTEventLog;

    $self->{log_to_server} = $self->get_sibling()->LogToSQLServer;
    $self->{explicit_global_vars} =
      $self->get_sibling()->ExplicitGlobalVariables;

    $self->_set_lineage_opts();
    $self->_set_priority();

    $self->{creation_date} =
      Win32::SqlServer::DTS::DateTime->new( $self->get_sibling()->CreationDate );

    $self->{_known_tasks} = undef;

    lock_keys( %{$self} );

    return $self;

}

=head3 use_explicit_global_vars

Returns true if the property "Explicit Global Variables" is set. Otherwise returns false.

=cut

sub use_explicit_global_vars {

    my $self = shift;
    return $self->{explicit_global_vars};

}

=head3 use_event_log

Returns true if the property "Write completation status to event log" is set. Otherwise returns false.

=cut

sub use_event_log {

    my $self = shift;
    return $self->{nt_event_log};

}

=head3 fail_on_error

Returns true if the property "Fail package on first error" is set. Otherwise returns false.

=cut

sub fail_on_error {

    my $self = shift;
    return $self->{fail_on_error};

}

sub _set_priority {

    my $self         = shift;
    my $numeric_code = $self->get_sibling()->PackagePriorityClass;

  CASE: {

        if ( $numeric_code == 3 ) {

            $self->{priority} = 'High';
            last CASE;

        }

        if ( $numeric_code == 1 ) {

            $self->{priority} = 'Low';
            last CASE;

        }

        if ( $numeric_code == 2 ) {

            $self->{priority} = 'Normal';
            last CASE;

        }

    }

}

sub _set_lineage_opts {

    my $self = shift;

    my $numeric_code = $self->get_sibling()->LineageOptions;

    $self->{add_lineage_vars}       = 0;
    $self->{is_lineage_none}        = 0;
    $self->{is_repository}          = 0;
    $self->{is_repository_required} = 0;

# those values come from DTSLineageOptions in the DTS Programming MS SQL Server documentation
    $self->{add_lineage_vars}       = $numeric_code & 1;
    $self->{is_lineage_none}        = 1 if ( $numeric_code == 0 );
    $self->{is_repository}          = $numeric_code & 2;
    $self->{is_repository_required} = $numeric_code & 3;

}

=head3 add_lineage_vars

Returns true or false (1 or 0 respectivally) if the Add Lineage Variables property is set.

=cut

sub add_lineage_vars {

    my $self = shift;
    return $self->{add_lineage_vars};

}

=head3 is_lineage_none

Returns true if provide no lineage (default) or false otherwise.

=cut

sub is_lineage_none {

    my $self = shift;
    return $self->{is_lineage_none};

}

=head3 is_repository

Returns true or false if the package will write to Meta Data Services if available.

=cut

sub is_repository {

    my $self = shift;
    return $self->{is_repository};

}

=head3 is_repository_required

Returns true or false if writing to Meta Data Services is required.

=cut

sub is_repository_required {

    my $self = shift;
    return $self->{is_repository_required};

}

=head3 to_string

Returns a string will all properties from the package, separated with new line characters. Each property also has
a text with a sort description of the property.

This method will not fetch automatically the properties from objects inside the package, line connections and
tasks. Each object must be fetched first using the apropriated method and them invoking the C<to_string> from each
object.

=cut

sub to_string {

    my $self = shift;

    return "\tName: "
      . $self->get_name
      . "\n\tID: "
      . $self->get_id
      . "\n\tVersion ID: "
      . $self->get_version_id
      . "\n\tComputer where the package was created: "
      . $self->get_creator_computer
      . "\n\tDescription: "
      . $self->get_description
      . "\n\tExecution priority: "
      . $self->get_priority
      . "\n\tAuto commit enable? "
      . ( ( $self->auto_commit ) ? 'true' : 'false' )
      . "\n\tCreation date: "
      . $self->get_creation_date->datetime
      . "\n\tFail on error? "
      . ( ( $self->fail_on_error ) ? 'true' : 'false' )
      . "\n\tLog file: "
      . $self->get_log_file
      . "\n\tMaximum number of steps: "
      . $self->get_max_steps
      . "\n\tAdd lineage variables? "
      . ( ( $self->add_lineage_vars ) ? 'true' : 'false' )
      . "\n\tIs lineage none? "
      . ( ( $self->is_lineage_none ) ? 'true' : 'false' )
      . "\n\tWrite to repository if available? "
      . ( ( $self->is_repository ) ? 'true' : 'false' )
      . "\n\tWrite to repository is required? "
      . ( ( $self->is_repository_required ) ? 'true' : 'false' )
      . "\n\tLog to SQL Server? "
      . ( ( $self->log_to_server ) ? 'true' : 'false' )
      . "\n\tUse explicit global variables? "
      . ( ( $self->use_explicit_global_vars ) ? 'true' : 'false' )
      . "\n\tUse event log for logging? "
      . ( ( $self->use_event_log ) ? 'true' : 'false' );

}

=head3 get_connections

Returns an iterator (code reference) that will return a C<Win32::SqlServer::DTS::Connection> object at each invocation until there are no
more objects available.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub get_connections {

    my $self    = shift;
    my $total   = scalar( in( $self->get_sibling()->Connections ) );
    my $counter = 0;

    return sub {

        return unless ( $counter < $total );

        my $conn = ( in( $self->get_sibling()->Connections ) )[$counter];

        $counter++;

        return Win32::SqlServer::DTS::Connection->new($conn);

      }

}

=head3 count_connections

Returns an integer that represents the total amount of connections available in the package object.

Besides the convenience, this method is uses less resources than invoking the respective C<get_> method and 
looping over the references in the array reference.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub count_connections {

    my $self    = shift;
    my $counter = 0;

    foreach my $connection ( in( $self->get_sibling->Connections ) ) {

        $counter++;

    }

    return $counter;

}

=head3 get_tasks

Returns an iterator. At each iterator (which is a code reference) call, one subclass object of C<Win32::SqlServer::DTS::Task> will be 
returned.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

B<Warning:> C<get_tasks> method will abort with an error message if the DTS package has tasks that are not available
as subclasses of C<Win32::SqlServer::DTS::Task> class. In doubt, use the available methods to fetch only the supported tasks. This 
should be "fixed" in future releases with the implementation of the missing classes.

=cut

sub get_tasks {

    my $self    = shift;
    my $tasks   = $self->get_sibling()->Tasks;
    my $total   = scalar( in($tasks) );
    my $counter = 0;

    return sub {

        return unless ( $counter < $total );

        my $task = ( in($tasks) )[$counter];

        $counter++;

        return Win32::SqlServer::DTS::TaskFactory::create($task);

      }

}

=head3 count_tasks

Returns a integer with the number of tasks available inside the package.

Besides the convenience, this method is uses less resources than invoking the respective C<get_> method and 
looping over the references in the array reference.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub count_tasks {

    my $self    = shift;
    my $counter = 0;

    map { $counter++; } ( in( $self->get_sibling->Tasks ) );

    return $counter;

}

=head3 _get_tasks_by_type

C<_get_tasks_by_type> is a "private method". It will return an iterator (which is a code reference) that will return
C<Win32::SqlServer::DTS::Task> subclasses objects at each call depending on the type passed as a parameter. It will not return and will 
complete ignore any Task class that is not returned by C<Win32::SqlServer::DTS::TaskTypes::get_types()>.

This method creates a cache after first call, so don't expect it will find new tasks after first invocation.

=cut

sub _get_tasks_by_type {

    my $self             = shift;
    my $type             = shift;
    my $iterator_counter = 0;

    unless ( keys( %{ $self->{_known_tasks} } ) ) {

        my $list = Win32::SqlServer::DTS::TaskTypes::get_types();

        foreach my $item ( @{$list} ) {

            $self->{_known_tasks}->{$item} = [];

        }

        #avoid caching invalid types
        lock_keys( %{ $self->{_known_tasks} } );

        my $counter = 0;

        foreach my $task ( in( $self->get_sibling()->Tasks ) ) {

# :TRICKY:3/11/2008:arfreitas: must avoid completely caching an unimplemeted DTS class in Perldts
            if ( grep { $task->CustomTaskID eq $_ } @{$list} ) {

                push(
                    @{ $self->{_known_tasks}->{ $task->CustomTaskID } },
                    $counter
                );

            }

# counter must be incremented anyway to get the proper indexes returned by in() function
            $counter++;

        }

    }

    return sub {

        my $total = scalar( @{ $self->{_known_tasks}->{$type} } );

        return unless ( $iterator_counter < $total );

#array slash of all tasks using as a index the number provided by known tasks cache
        my $task =
          ( in( $self->get_sibling()->Tasks ) )
          [ $self->{_known_tasks}->{$type}->[$iterator_counter] ];

        $iterator_counter++;

        return Win32::SqlServer::DTS::TaskFactory::create($task);

      }

}

sub _count_tasks_by_type {

    my $self    = shift;
    my $type    = shift;
    my $counter = 0;

    foreach my $task ( in( $self->get_sibling()->Tasks ) ) {

        next unless ( $task->CustomTaskID eq $type );
        $counter++;

    }

    return $counter;

}

=head3 count_datapumps

Returns an integer represents the total amount of C<DataPumpTask> tasks available in the package.

Besides the convenience, this method is uses less resources than invoking the respective C<get_> method and 
looping over the references in the array reference.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub count_datapumps {

    my $self = shift;
    return $self->_count_tasks_by_type('DTSDataPumpTask');

}

=head3 get_datapumps

Returns a iterator (code reference) that will return, at each invocation, a the C<DataPumpTasks> tasks available 
in the package.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub get_datapumps {

    my $self = shift;
    return $self->_get_tasks_by_type('DTSDataPumpTask');

}

=head3 count_dynamic_props

Returns an integer represents the total amount of C<DynamicPropertiesTask> tasks available in the package.

Besides the convenience, this method is uses less resources than invoking the respective C<get_> method and 
looping over the references in the array reference.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub count_dynamic_props {

    my $self = shift;
    return $self->_count_tasks_by_type('DTSDynamicPropertiesTask');

}

=head3 get_dynamic_props

Returns a iterator (code reference) that will return a C<Win32::SqlServer::DTS::Task::DynamicProperty> object at each invocation until
there is no more tasks to return.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub get_dynamic_props {

    my $self = shift;
    return $self->_get_tasks_by_type('DTSDynamicPropertiesTask');

}

=head3 get_execute_pkgs

Returns a iterator (code reference) that will return a C<Win32::SqlServer::DTS::Task::ExecutePackage> object at each invocation until
there is no more tasks to return.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub get_execute_pkgs {

    my $self = shift;
    return $self->_get_tasks_by_type('DTSExecutePackageTask');

}

=head3 count_execute_pkgs

Returns an integer with the total of C<ExecutePackageTask> tasks available in the package.

Besides the convenience, this method is uses less resources than invoking the respective C<get_> method and 
looping over the references in the array reference.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub count_execute_pkgs {

    my $self = shift;
    return $self->_count_tasks_by_type('DTSExecutePackageTask');

}

=head3 get_send_emails

Returns an iterator (code reference) that will return a C<Win32::SqlServer::DTS::Task::SendEmail> at each invocation until there is no
more tasks available.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub get_send_emails {

    my $self = shift;

    return $self->_get_tasks_by_type('DTSSendMailTask');

}

=head3 count_send_emails

Returns an integer with the total of C<SendMailTask> tasks available in the package.

Besides the convenience, this method is uses less resources than invoking the respective C<get_> method and 
looping over the references in the array reference.

This method depends on having the C<_sibling> attribute available, therefore is not possible to invoke this method
after invoking the C<kill_sibling> method.

=cut

sub count_send_emails {

    my $self = shift;
    return $self->_count_tasks_by_type('DTSSendMailTask');

}

=head3 save_to_server

Saves the package to a SQL Server. This method must be called if the Win32::SqlServer::DTS::Package was modified (or it's inner object 
were).

Expectes a L<Win32::SqlServer::DTS::Credential|Win32::SqlServer::DTS::Credential> object as a parameter. If the Package will be saved in the same server
from where it was fetched it's useful to use the method C<get_credential> from the L<Win32::SqlServer::DTS::Application|Win32::SqlServer::DTS::Application> 
object.

The optional parameters:

=over

=item *
PackageOwnerPassword

=item *
PackageOperatorPassword

=item *
PackageCategoryID

=item *
pVarPersistStgOfHost

=item *
bReusePasswords

=back

from the original DTS API are not implemented.

=cut

sub save_to_server {

    my $self       = shift;
    my $credential = shift;

    confess "invalid credential parameter"
      unless ( $credential->isa('Win32::SqlServer::DTS::Credential') );

    $self->get_sibling()->SaveToSQLServer( $credential->to_list() );

    confess 'could not save the packate to a SQL Server: '
      . Win32::OLE->LastError()
      if ( Win32::OLE->LastError() );

}

=head3 save_to_file

Saves the package to a structured file.

Expects a complete pathname as a parameter. If a DTS structure filename is not passed together with the path,
the method will use the package name followed by a '.dts' extension.

The optional parameters:

=over

=item *
OwnerPassword

=item *
OperatorPassword

=item *
pVarPersistStgOfHost

=item *
bReusePasswords

=back

from the original DTS API are not implemented.

=cut

sub save_to_file {

    my $self = shift;
    my $path = shift;
    my $file = shift;

    confess "invalid complete pathname parameter" unless ( defined($path) );

    $file = $self->get_name() . '.dts' unless ( defined($file) );

    $path = File::Spec->catfile( $path, $file );
    $self->get_sibling()->SaveToStorageFile($path);

    confess "could not save '$path': " . Win32::OLE->LastError()
      if ( Win32::OLE->LastError() );

}

1;
__END__

=head3 get_creation_date

Returns a L<DataTime|DataTime> object with the timestamp of the creation date of the package. When used the
C<to_string> method, it will be returned the equivalent result of the method C<datetime> from L<DateTime|DateTime>
class.

The timezone of the L<DateTime|DateTime> object is the float one. See L<DateTime|DateTime/Floating DateTimes> for 
more information.

=head3 get_creator_computer

Returns a string with the machine name from where the package was created.

=head3 get_description

Returns a string with the description of the package.

=head3 get_log_file

Returns a string with the filename of the file used to store the log messages from the package execution.

=head3 get_max_steps

Returns a integer the maximum number of steps allowed to be executed simultaneously in the package.

=head3 get_name

Returns a string with the name of the package

=head3 get_id

Returns a string with the unique ID in the database of the package.

=head3 get_priority

Returns a string with the priority of the package ('High', 'Low' or 'Normal').

=head3 get_version_id

Returns a string with the version ID of the package.

=head2 CAVEATS

This API is incomplete. There are much more properties defined in the SQL Server API.

=head1 SEE ALSO

=over

=item *
L<Win32::SqlServer::DTS::Application> at C<perldoc>. 

=item *
L<Win32::OLE> at C<perldoc>.

=item *
L<Win32::SqlServer::DTS::DateTime>, L<DateTime> and L<DateTime::TimeZone::Floating> at C<perldoc> for details about the implementation of 
C<creation_date> attribute.

=item *
MSDN on Microsoft website and MS SQL Server 2000 Books Online are a reference about using DTS'
object hierarchy, but you will need to convert examples written in VBScript to Perl code.

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Alceu Rodrigues de Freitas Junior

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
