
=head1 NAME

WebService::TestSystem - Web service for implementing a distributed
testing system.

=head1 SYNOPSIS

my $testsys = new WebService::TestSystem;

# Getting a list of tests
foreach my $test (@{$testsys->get_tests()}) {
    print "$test->{id} $test->{descriptor}\n";
}

# Getting a list of hosts
foreach my $host (@{$testsys->get_hosts()}) {
    print "$host->{id} $host->{descriptor}\n";
}

# Submitting tests
my %request;
if (! $testsys->validate_test_request(\%request) ) {
    my %errors = $testsys->get_validation_errors();
} else {
    my $test_request_id = $testsys->request_test(%request);
    print "Test request #$test_request_id submitted\n";
}

# System Metrics
@metrics = $testsys->metrics_test_run_time(2004, 12);
@metrics = $testsys->metrics_requests_per_month(2004, 'all')
@metrics = $testsys->metrics_distros_tested_per_month(2004)
etc.


=head1 DESCRIPTION

B<WebService::TestSystem> presents a programmatic interface (API) for
remote interactions with a software testing service.  In other words,
this provides a set of remote procedure calls (RPCs) for requesting test
runs, monitoring systems under test (SUT), and so forth.

=head1 FUNCTIONS

=cut

package WebService::TestSystem;
@WebService::TestSystem::ISA = qw(WebService::TicketAuth::DBI);

use strict;
use Config::Simple;
use WebService::TicketAuth::DBI;
use WebService::TestSystem::Metrics;
use WebService::TestSystem::Request;
use DBI;

# This is the location of the configuration file.
# You can update this value here if you wish to move it to a 
# different location.
my $config_file = "/etc/webservice_testsystem/testsystem.conf";

use vars qw($VERSION %FIELDS);
our $VERSION = '0.06';

use base 'WebService::TicketAuth::DBI';
use fields qw(
              stpdb_dbh
              stpdb_dbi
              stpdb_user
              stpdb_pass

              metrics
	      request

              _error_msg
              _debug
              );

=head2 new(%args)

Establishes a new WebService::TestSystem instance.  This sets up a database
connection.

=cut

sub new {
    my $class = shift;
    my WebService::TestSystem $self = fields::new($class);

    # Load up configuration parameters from config file
    my %config;
    my $errormsg = '';
    if (! Config::Simple->import_from($config_file, \%config)) {
        $errormsg = "Could not load config file '$config_file': " . 
	    Config::Simple->error()."\n";
    }

    $self->SUPER::new(%config);
    
    foreach my $param (qw(stpdb_dbi stpdb_user stpdb_pass)) {
        if (defined $config{$param}) {
            $self->{$param} = $config{$param};
        }
    }
    $self->{_error_msg} .= $errormsg;

    return $self;
}

# Internal routine for getting the database handle; if it does not
# yet exist, it creates a new one.
sub _get_dbh {
    my $self = shift;

    $self->{'stpdb_dbh'} = 
        DBI->connect_cached($self->{'stpdb_dbi'}, 
                            $self->{'stpdb_user'}, 
                            $self->{'stpdb_pass'}
                            );
    if (! $self->{'stpdb_dbh'}) {
        $self->_set_error("Could not connect to '"
                          .$self->{'stpdb_dbi'}
                          ."' as user '"
                          .$self->{'stpdb_user'}
                          ."':  $! \n$DBI::errstr\n");
    }
    return $self->{'stpdb_dbh'};
}

# Internal routine for setting the error message
sub _set_error {
    my $self = shift;

    $self->{'_error_msg'} = shift;
}

=head2 get_error()

Returns the most recent error message.  If any of this module's routines
return undef, this routine can be called to retrieve a message about
what happened.  If several errors have occurred, this will only return
the most recently encountered one.

=cut

sub get_error {
    my $self = shift;
    return $self->{'_error_msg'};
}

# Gets the WebService::TestSystem::Metrics object (creating it if needed)
sub _metrics {
    my $self = shift;

    if (! defined $self->{metrics}) {
        $self->{metrics} = new WebService::TestSystem::Metrics(app => $self);
    }

    return $self->{metrics};
}

# Gets the WebService::TestSystem::Request object (creating it if needed)
sub _request {
    my $self = shift;

    if (! defined $self->{_request}) {
	$self->{_request} = new WebService::TestSystem::Request(app => $self);
    }

    return $self->{_request};
}

##################
# Authentication / Login management 

# Override for how long to allow tickets to last
sub ticket_duration {
    my $self = shift;
    my $username = shift;

    # Give everyone 24 hour logins
    return 24*60*60;
}

sub login {
    my $self = shift;

    return $self->SUPER::login(@_);
}


###################
# These just redirect into the _metrics sub-object.

sub metrics_requests_per_month {
    my $self = shift;
    return $self->_metrics()->metrics_requests_per_month(@_);
}

sub metrics_test_run_time {
    my $self = shift;
    return $self->_metrics()->metrics_test_run_time(@_);
}

sub metrics_distros_tested_per_month {
    my $self = shift;
    return $self->_metrics()->metrics_distros_tested_per_month(@_);
}

sub metrics_test_request_status_totals {
    my $self = shift;
    return $self->_metrics()->metrics_test_request_status_totals(@_);
}

sub metrics_queue_lengths {
    my $self = shift;
    return $self->_metrics()->metrics_queue_lengths(@_);
}

sub metrics_host_type_test_status_totals {
    my $self = shift;
    return $self->_metrics()->metrics_host_type_test_status_totals(@_);
}

sub metrics_queue_age {
    my $self = shift;
    return $self->_metrics()->metrics_queue_age(@_);
}

sub metrics_patches_queued {
    my $self = shift;
    return $self->_metrics()->metrics_patches_queued(@_);
}

sub metrics_monthly_tests_per_host {
    my $self = shift;
    return $self->_metrics()->metrics_monthly_tests_per_host(@_);
}

################
# Test request and validation

=head2 get_validation_errors()

Retrieves a hash of error messages from the last call to 
validate_test_request().

=cut

sub get_validation_errors {
    my $self = shift;
    return $self->_request()->get_validation_errors();
}

=head2 validate_test_request(\%request)

Checks the validity of a given test request.  This routine also converts
string values into ID's as appropriate, and updates %request in the
process.

Returns a true value on successful validation, false if there is a
validation error, or undef if there is a problem.  Validation errors can
be retrieved via the get_validation_errors() routine.  General error
messages can be obtained via the get_error() routine.

=cut

sub validate_test_request {
    my $self = shift;
    
    return $self->_request()->validate_test_request(@_);
}

=head2 request_test(\%request)

Issues a test request into the system.  

Returns undef on error, or the test request ID number on success.  In
case of error, you can retrieve the error message via the get_error()
routine.

This routine calls validate_test_request() to check inputs prior to
submission.  If any errors are found, it will return undef, with the
error message set to 'test request failed validation'.  The errors
themselves can be retrieved via the get_validation_errors() routine.

=cut

sub request_test { 
    my $self = shift;
    my $request = shift;

    # Validate the request
    if (! $self->validate_test_request($request) ) {
        $self->_set_error("Test request failed validation.  "
                          . $self->get_error());
        return undef;
    }

    my $test_request_id = $self->_request()->request_test($request);

    if (! $test_request_id) {
	$self->_set_error($self->_request()->get_error());
	return undef;
    }

    return $test_request_id;
}

sub cancel_test_request {
    my $self = shift;
    my $id = shift;

    # TODO

    return "Unimplemented";
}

sub change_test_request {
    my $self = shift;
    my $request = shift;

    # TODO

    return "Unimplemented";
}

sub get_test_request {
    my $self = shift;
    my $id = shift;

    # TODO

    return "Unimplemented";
}

################
# Eventually, everything after this line should be moved into sub modules

=head2 get_tests()

Returns a list of tests in the system.  Each test object will include
several fields:

 id
 descriptor
 description
 category
 code_location
 configuration_notes
 status
 environment_default
 lilo_default
 repeat_safe

=cut

sub get_tests {
    my $self = shift;

    my $sql = qq|
	SELECT uid as id, descriptor, description, category, code_location, 
	    configuration_notes, status, environment_default, lilo_default,
	    repeat_safe
        FROM test
	|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @tests = ();
    while (my $test = $sth->fetchrow_hashref) {
        push @tests, $test;
    }

    return \@tests;
}

=head2 get_hosts()

Returns a list of host machines registered in the system.

=cut

sub get_hosts {
    my $self = shift;

    my $sql = qq|
	SELECT host.uid as id, 
	       host.descriptor as host, 
	       host_type.descriptor as host_type,
	       host_type.cpu as cpu,
	       host_type.ram_qty as ram_qty,
	       host_type.storage_space as storage_space,
               host_type.spindle_qty as spindle_qty,
	       host_type.eth100 as eth100,
	       host_type.eth1000 as eth1000,
	       host_state.descriptor as host_state,
               host_state.available as available,
	       host_state.schedulable as schedulable
	FROM host, host_type, host_state
	WHERE host.host_type_uid = host_type.uid
	AND host.host_state_uid = host_state.uid
	ORDER BY host.uid
	|;

    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @hosts = ();
    while (my $host = $sth->fetchrow_hashref) {
        push @hosts, $host;
    }

    return \@hosts;
}

=head2 get_images()

This routine returns a list of distro images that are available in
the system.  Each image record includes its descriptor, id, and status.

=cut

sub get_images {
    my $self = shift;

    my $sql = qq|
        SELECT uid as id, descriptor, status 
        FROM distro_tag 
	WHERE status='Available'
	|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @images = ();
    while (my $image = $sth->fetchrow_hashref) {
        push @images, $image;
    }

    return \@images;
}

=head2 get_software_types()

Returns a list of software packages available in the system for doing
testing against.  

=cut

sub get_software_types {
    my $self = shift;

    my $sql = qq|
	SELECT DISTINCT software_type
	FROM patch_tag
	|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @packages = ();
    while (my $package = $sth->fetchrow_hashref) {
        push @packages, $package;
    }

    return \@packages;
}

=head2 get_requests(%args)

This routine permits searching against the test requests in the system.
Arguments can be provided via the %args hash.  Accepted arguments
include:

    limit           - the number of records to return
    order_by        - the fieldname to order the records by

    distro          - search condition (supports % wildcards)
    test            - search condition (supports % wildcards)
    host            - search condition (supports % wildcards)
    host_type       - search condition (supports % wildcards)
    project         - search condition (supports % wildcards)
    priority        - search condition (must match exactly)
    status          - search condition (must match exactly)
    patch_id        - search condition (must be a valid patch id number)
    patch           - search condition (must match a valid patch name)
    created_by      - user id number for requestor
    username        - username of requestor
    

Each test request record returned includes the following info:

    id              - the test request's id
    created_by      - user id# of the requestor
    username        - username of the requestor
    project         - project associated with the request
    status          - the state the test request is currently in
    priority        - priority

    created_date    - date it was created
    started_date    - datetime the test run began
    completion_date - date it was completed

    distro          - distro image name
    test            - test name
    host            - host name
    host_type       - host class
    patch           - patch name

    distro_tag_id   - id# of distro image
    test_id         - id# of test
    host_id         - id# of host
    host_type_id    - id# of host type
    project_id      - id# of project
    patch_tag_id    - id# of patch

=cut

# TODO:  I think this returns one row per patch_tag record...  
#        Perhaps it should return this info as a nested structure?
sub get_requests {
    my ($self, %args) = @_;

    if ($self->{_debug} >1) {
	while (my ($key, $value) = each %args) {
	    warn " '$key' = '$value'\n";
	}
    }

    # limit can only be between 0-1000 and must be a number.
    my $limit = $args{limit} || 20;
    if ($limit !~ /^\d+$/ || $limit > 1000) {
        $self->set_error("Invalid limit '$limit'.  ".
                         "Must be a number in the range 0-1000.");
        return undef;
    } else {
        delete $args{limit};
    }

    # Order field must be alphanumeric
    my $order_by = $args{order_by} || 'test_request.uid';
    if ($order_by !~ /^[\.\w]+$/) {
        $self->_set_error("Invalid order_by field '$order_by'.  ".
                          "Must be an alphanumeric field name.");
        return undef;
    } else {
        delete $args{order_by};
    }

    # Rest of the arguments can only be alphanumeric values
    foreach my $key (keys %args) {
        if ($key !~ m/^\w+$/) {
            my $err = "Invalid key '$key' specified.  ".
                "Only alphanumeric characters may be used.";
            warn "Error:  $err\n" if ($self->{_debug} > 1);
            $self->_set_error($err);
            return undef;
        } elsif ($args{$key} !~ m/^\w+$/) {
            my $err = "Invalid value '$args{'$key'}' specified for '$key'.  "
                ."Only alphanumeric characters may be used.";
            $self->_set_error($err);
            warn "Error:  $err\n" if ($self->{_debug} > 1);
            return undef;
        }
    }

    my $sql = qq|
SELECT 
    test_request.uid AS id,
    test_request.created_by AS created_by,
    DATE_FORMAT(test_request.created_date, '%Y-%m-%d') AS created_date,
    test_request.status AS status,
    DATE_FORMAT(test_request.completion_date, '%Y-%m-%d') AS completion_date,
    test_request.test_priority AS priority,
    test_request.started_date AS started_date,

    test_request.distro_tag_uid AS distro_tag_id,
    test_request.test_uid AS test_id,
    test_request.host_uid AS host_id,
    test_request.host_type_uid AS host_type_id,
    test_request.project_uid AS project_id,

    distro_tag.descriptor AS distro,
    test.descriptor AS test,
    host.descriptor AS host,
    host_type.descriptor AS host_type,
    EIDETIC.user.descriptor AS username,
    EIDETIC.project.descriptor AS project,

    test_request_to_patch_tag.patch_tag_uid AS patch_tag_id,
    patch_tag.descriptor AS patch
FROM 
    test_request, 
    distro_tag, 
    test, 
    host, 
    host_type, 
    test_request_to_patch_tag, 
    patch_tag, 
    EIDETIC.user, 
    EIDETIC.project
WHERE 1
    AND test_request.distro_tag_uid = distro_tag.uid
    AND test_request.test_uid = test.uid
    AND (test_request.host_uid = host.uid OR (test_request.host_uid=0 AND host.uid=1))
    AND test_request.host_type_uid = host_type.uid
    AND test_request.project_uid = EIDETIC.project.uid
    AND test_request.uid = test_request_to_patch_tag.test_request_uid
    AND test_request_to_patch_tag.patch_tag_uid = patch_tag.uid
    AND test_request.created_by = EIDETIC.user.uid
|;

    if (defined $args{'distro'}) {
        $sql .= qq|    AND distro_tag.descriptor LIKE "$args{'distro'}"\n|;
    }
    if (defined $args{'test'}) {
        $sql .= qq|    AND test.descriptor LIKE "$args{'test'}"\n|;
    }
    if (defined $args{'host'}) {
        $sql .= qq|    AND host.descriptor LIKE "$args{'host'}"\n|;
    }
    if (defined $args{'host_type'}) {
        $sql .= qq|    AND host.descriptor LIKE "$args{'host_type'}"\n|;
    }
    if (defined $args{'project'}) {
        $sql .= qq|    AND EIDETIC.project.descriptor LIKE "$args{'project'}"\n|;
    }
    if (defined $args{'priority'}) {
        $sql .= qq|    AND test_request.test_priority = $args{'priority'}\n|;
    }
    if (defined $args{'status'}) {
        $sql .= qq|    AND test_request.status = "$args{'status'}"\n|;
    }
    if (defined $args{'patch_id'}) {
        if ($args{'patch_id'} !~ m/^\d+$/) {
            $self->_set_error("Invalid patch ID '$args{'patch_id'}' specified.  ".
                              "Must be a positive integer.");
            return undef;
        }
        $sql .= qq|    AND test_request_to_patch_tag.patch_tag_uid = $args{'patch_id'}\n|;
    }
    if (defined $args{'patch'}) {
        $sql .= qq|    AND patch_tag.descriptor LIKE '$args{'patch'}'|;
    }
    if (defined $args{'created_by'}) {
        if ($args{'created_by'} !~ m/^\d+$/) {
            $self->_set_error("Invalid created_by ID '$args{'created_by'}'.  ".
                              "Must be a positive integer.");
            return undef;
        }
        $sql .= qq|    AND test_request.created_by=$args{'created_by'}\n|;
    }
    if (defined $args{'username'}) {
        $sql .= qq|    AND EIDETIC.user.descriptor LIKE "$args{'username'}"\n|;
    }

    $sql .= qq|ORDER BY $order_by DESC\n|;
    $sql .= qq|LIMIT $limit\n|;

    warn "sql = '$sql'\n" if ($self->{_debug} > 2);

    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @test_requests = ();
    while (my $tr = $sth->fetchrow_hashref) {
        push @test_requests, $tr;
    }

    return \@test_requests;
}

=head2 get_request_queue([$host])

Returns a list of queued tests for a given host name or id, or all hosts
if $host is not defined.

=cut

sub get_request_queue {
    my $self = shift;
    my $host = shift;

    my $sql = qq|
	SELECT test_request.uid as id, 
	patch_tag.descriptor as patch, 
	test_request.status, 
	host_type.descriptor as host_type, 
	test_request.created_date 
	FROM test_request, patch_tag, test_request_to_patch_tag, host_type 
	WHERE test_request.status = 'Queued'
	AND test_request.uid = test_request_to_patch_tag.test_request_uid 
	AND test_request_to_patch_tag.patch_tag_uid = patch_tag.uid 
	AND test_request.host_type_uid = host_type.uid 
        |;
    if ($host) {
	if ($host =~ /^\d+$/) {
	    $sql .= "	AND host_type.uid = $host\n";
	} else {
	    $sql .= "	AND host_type.descriptor = '$host'\n";
	}
    }
    warn "sql = '$sql'\n" if ($self->{_debug} > 2);

    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @queue = ();
    while (my $tr = $sth->fetchrow_hashref) {
        push @queue, $tr;
    }

    return \@queue;
}


=head2 get_patches($patch_regex[, $limit])

Returns a list of patches in the system matching the given regular
expression, up to $limit (default 100) items.

=cut
sub get_patches {
    my $self = shift;
    my $patch_regex = shift;
    my $limit = shift || 100;

    my $sql = qq|
	SELECT uid as id, descriptor, software_type, autotest_state
	FROM patch_tag 
	LIMIT $limit
	ORDER BY descriptor
	|;
    my $dbh = $self->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @patches = ();
    while (my $patch = $sth->fetchrow_hashref) {
        push @patches, $patch;
    }

    return \@patches;
}

=head2 add_test($name, \%properties)

Adds a new test to the system.  This includes all test descriptions,
parameter information, default settings, etc.

If the user is a maintainer for this test, allows update directly, 
otherwise sends an email request to the system admins.

=cut
sub add_test {
    my $self = shift;
    my $name = shift;
    my $properties = shift;

    # Assumptions:
    #  * Test code has already been inserted into bitkeeper
    #  * Test code has been tagged stp_deploy, etc. as per web directions

    # Data structure:
    #   test_name
    #   description
    #   lilo_default
    #   code_location
    #   configuration_notes
    #   environment_default
    #   category
    #   status
    #   repeat_safe
    #   test_parameters (array of hashrefs):
    #     + descriptor
    #     + description
    #     + data_type ('string' or 'int')
    #   distros (array of distro id's)
    #   host_types (array of host_type id's)
    #   software_types (array of software strings 'linux', 'postgresql', etc.)

    # Algorithm:
    #
    #  * Exit if the test name already exists in the database
    #  * Validate information in $properties
    #     + descriptor must be alphanumeric (no default - error if not provided)
    #     + lilo_default (default '')
    #     + environment_default (default '')
    #     + category must be alphanumeric (default General)
    #     + status must be either 'Available' or 'Unavailable' (default Available) 
    #     + repeat_safe must be either 0 or 1 (default 0)
    #     + Validate each test parameter
    #     + Validate distro list - they must exist in the table
    #     + Validate host_type's - they must exist in the table
    #     + Validate software_types - they must be alphanumeric
    #  * Invoke SQL call to insert the information into the test table
    #     + insert it with status='Inserting'
    #     insert into test (
    #          rsf,descriptor,created_by,created_date,description,code_location,category,status,repeat_safe ) VALUES ( 1, 'lhms-regression', 3125, now(),'Linux Hotplug Memory Support Regression Test', 'bk://developer.osdl.org/stp-test/lhms-regression', 'General', 'Available', 0 );
    #     + retrieve the test_uid just inserted
    #  * For each parameter, insert into parameters test_parameter
    #     + test_uid
    #     + descriptor
    #     + description
    #     + data_type ('string' or 'int')
    
    #  * Add test into test_to_distro_tag
    #     distro_tag_uid, test_uid
    #     insert into test_to_distro_tag ( rsf, distro_tag_uid, test_uid ) VALUES ( 1, 4, 87 );
    #  * Add test into test_to_host_type
    #     host_type_uid, test_uid
    #     insert into test_to_host_type ( host_type_uid, test_uid, rsf ) VALUES ( 81, 87, 1 );
    #  * Add test into test_to_software:
    #     test_uid, software_type, install_priority
    #   > INSERT into test_to_software ( rsf, test_uid, software_type, install_priority) VALUES ( 1, 87, 'linux', 0 );
    #   > INSERT into test_to_software ( rsf, test_uid, software_type, install_priority ) VALUES ( 1, 87, 'sysstat', 0 );
    #  * Update test record and change status to 'Available' or 'Unavailable'
    #    as appropriate


    # On failure, back out the test insertion

    return "Not implemented\n";
}

=head2 get_test($name)

Returns properties for the given test (including a URL where the test
code can be fetched.

=cut
sub get_test {
    my $self = shift;
    my $name = shift;

    return "Not implemented\n";
}

=head2 update_test($name, \%properties)

Updates the info about the given test.  %properties should contain the
list of values to update.  Properties to leave alone should be undef.

If the user is a maintainer for this test, allows update directly, 
otherwise sends an email request to the system admins.

=cut
sub update_test {
    my $self = shift;
    my $name = shift;
    my $properties = shift;

    return "Not implemented\n";
}


#### These API routines need implemented

=head2 activate_host($host_id)

NOT YET IMPLEMENTED

Activates the given host, if it is in maintenance mode.  This routine
can only be called by someone with administrator priv's.

=cut

sub activate_host {
    my $self = shift;
    my $host_id = shift;

    return "Not implemented\n";
}

=head2 checkout_host(\%host_criteria, \%notification, \%preparation)

NOT YET IMPLEMENTED

Requests a machine be 'checked out', as indicated by the %host_criteria
hash.  This hash supports the following fields:

  id     - a regular expression that will resolve to one or more 
           host id's
  type   - a regular expression that resolves to a valid set of
           host_type's

The above criteria are ANDed together, so only hosts that matches
ALL of the criteria will be selected.

If more than one host matches the criteria, then the first available
system will be checked out.  If multiple machines need to be checked
out, call this routine that many times.

The %notification hash provides instructions regarding how the user
should be notified about when the host becomes available.  It supports
the following fields:

  email - an email address to send an email to when the system becomes
          available.
  on_state_change - if set to true, will notify user of ALL changes,
          not just availability.

If no notification info is provided (the %notification hash is left
undefined or empty), then no notification will be performed, and it
will be up to the requestor to check back periodically to determine
when the machine is available, via get_hosts().

When a machine is checked out, it is put on a time-out.  After the time
has expired, the machine will automatically return to the queue.  This
way if someone checks out a machine but isn't around to use it when it
becomes available, it won't sit idly checked out forever.

The %preparation hash allows the user to specify additional custom setup
work that should be completed on the machine prior to marking the
machine 'available' and notifying the user.  This could include waiting
for another machine checkout to complete, installing some user-specific
tools, initiating some instrumentation, etc.

=cut

sub checkout_host {
    my $self = shift;
    my $host_criteria = shift;
    my $notification = shift;
    my $preparation = shift;

    # Use host_criteria to find matching set of systems
    # Store request for checking out those systems
    # TODO:  Need separate routine for reviewing checkout requests
    # Set a time-out for when to return machine to queue

    return "Not implemented\n";
}

=head2 change_host_reservation($host_id, $timeout)

NOT YET IMPLEMENTED

Allows altering the reservation time for a given host.  This allows
extending your checkout request beyond the default, or even to check
a machine back in.

$timeout can be a period of time ("120 min"), or a cut-off time (6:00 pm
Friday).  To check a machine in or cancel the reservation, pass a zero
value for $timeout.  Invalid timeouts (negative times, non-time strings,
dates in the past, etc.) result in an error.

Those with admin privs can check out machines for any length of time.
Regular users will be limited as to the maximum reservation times
they're allowed.

=cut

sub change_host_reservation {
    my $self = shift;
    my $host_id = shift;
    my $timeout = shift;

    # TODO
    return "Not implemented\n";
}

=head2 add_software_type($type, \%properties)

Registers new software for the testing system to track.  This will cause
the system to periodically check for new releases or snapshots of the
code for running tests against.  This allows automating the testing
process, so that certain tests can be run regularly against the code.

The frequency may be limited by the administrator as appropriate to the
resource availability.

=cut

sub add_software_type {
    my $self = shift;
    my $type = shift;

    # TODO
    return "Not implemented\n";
}

=head2 update_software_type($type, \%properties)

Updates information about the given software type

=cut

sub update_software {
    my $self = shift;
    my $type = shift;
    my $properties = shift;

    # TODO
    return "Not implemented\n";
}

1;



