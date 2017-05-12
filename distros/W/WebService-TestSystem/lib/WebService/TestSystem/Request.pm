
=head1 NAME

WebService::TestSystem::Request - Routines for processing a test
request and entering it into the system

=head1 SYNOPSIS

    my $req = new WebService::TestSystem::Request;

=head1 DESCRIPTION

WebService::TestSystem::Request provides the low level routines for
validating, inserting, and deleting test requests and associated
records.

The routines in this module are all considered 'private access', and
should not be exported directly through SOAP.  Instead, they are
called from a higher level routine in WebService::TestSystem.

=head1 FUNCTIONS

=cut

package WebService::TestSystem::Request;

use strict;
use DBI;

use vars qw($VERSION %FIELDS);
our $VERSION = '0.06';

use fields qw(
              _app
              _error_msg
              _debug
              );

=head2 new(%args)

Establishes a new WebService::TestSystem::Request instance. 

You must give it a valid WebService::TestSystem object in the 'app'
argument.

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref($this) || $this;
    my $self = bless [\%FIELDS], $class;

    if (defined $args{'app'}) {
        # TODO:  Check to make sure app can do get_db(), etc.
        $self->{'_app'} = $args{'app'};
    } else {
	return undef;
    }

    return $self;
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

=head2 request_test(%request)

Issues a test request into the system.

Returns undef on error, or the test request ID number on success.  In
case of error, you can retrieve the error message via the get_error()
routine.

=cut

sub request_test { 
    my $self = shift;
    my $request = shift;

    my $test_request_id = $self->add_test_request($request)
	|| return undef;
    
    # Patch tags - delete any existing ones for this test request ID
    # This should be atomic and part of add_test_request_to_patch_tag()
    if (! $self->delete_test_request_to_patch_tag($test_request_id)) {
	return undef;
    }

    # Patch tags - add new patch tags
    if (! $self->add_test_request_to_patch_tag($test_request_id,
					       $request->{patch_tags})) {
	$self->rollback_test_request($test_request_id);
	return undef;
    }
    
    # Parameters - delete any existing ones for this test request ID
    if (! $self->delete_test_request_to_parameter($test_request_id) ) {
	$self->rollback_test_request($test_request_id );
	return undef;
    }

    # Parameters - add the new parameters
    if (! $self->add_test_request_to_parameter($test_request_id,
                                               @{$request->{parameters}}) ) {
        $self->rollback_test_request($test_request_id );
        return undef;
    }
    
    # Queue the test
    if (! $self->queue_test_request($test_request_id)) {
	$self->rollback_test_request($test_request_id );
	return undef;
    }
    
    return $test_request_id;
}


=head2 add_test_request(\%request)

Adds the test request into the system.  No validation is performed.
Only updates the test_request table.  Other attached tables can be
updated separately through other routines in this module.

Returns undef on error, or the test request's ID on success.  Error
messages can be retrieved via the get_error() routine.

=cut
sub add_test_request {
    my $self = shift;
    my $request = shift;

    my $sql = qq|
    INSERT INTO test_request (
                               created_by,
                               created_date,
                               last_updated_by,
                               last_updated_date,
                               distro_tag_uid,
                               test_uid,
                               lilo,
                               environment,
                               sysctl,
                               project_uid,
                               host_type_uid,
                               test_priority,
                               status
    ) VALUES (
               ?,
               NOW(),
               ?,
               NOW(),
               ?,
               ?,
               "?",
               "?",
               "?",
               ?,
               ?,
               ?,
               "Inserting"
              );
    |;
    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);

    $sth->execute($request->{creator_id},
                  $request->{creator_id},
                  $request->{distro_tag_id},
                  $request->{test_id},
                  $request->{lilo},
                  $request->{environment},
                  $request->{sysctl},
                  $request->{project_id},
                  $request->{host_type_id},
                  $request->{test_priority}
                  );

    return $dbh->last_insert_id();
}

=head2 rollback_test_request( $test_request_id )

Removes all components of a failed test insertion
For a first pass, we'll shotgun everything, which means some
of the deletes will fail. This will keep all the rollback in one function

=cut

sub rollback_test_request {
    my $self = shift;
    my $test_request_id = shift || return undef;

    my $sql = qq|
        DELETE FROM test_request WHERE test_request_uid = ?
        |;
    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $test_request_id );

    $sql = qq|
        DELETE FROM test_request_to_patch_tag WHERE test_request_uid = ?
        |;
    $dbh = $self->{_app}->_get_dbh() or return undef;
    $sth = $dbh->prepare($sql);
    $sth->execute( $test_request_id );

    $sql = qq|
        DELETE FROM test_request_to_parameter WHERE test_request_uid = ?
        |;
    $dbh = $self->{_app}->_get_dbh() or return undef;
    $sth = $dbh->prepare($sql);
    $sth->execute( $test_request_id );
    
    return 1;
}


=head2 add_test_request_to_patch_tag($test_request_id, @patch_tags)

Inserts the given patch tags into the database for the indicated
test request ID.

Returns a true value on success, or undef on error.  Error messages can
be retrieved via the get_error() routine.

=cut

sub add_test_request_to_patch_tag {
    my $self = shift;
    my $test_request_id = shift;

    my $sql = qq|
    INSERT INTO test_request_to_patch_tag (
                                           test_request_uid,
                                           patch_tag_uid
    ) VALUES ( ?, ? )
    |;
    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    foreach my $patch_tag (@_) {
        if (! $sth->execute($test_request_id,
                            $patch_tag->{patch_id}))
        {
                $self->_set_error("Could not add patch tag:  "
                                  . $sth->errstr);
                return undef;
            }
    }
    return 1;
}

=head2 add_test_request_to_parameter($test_request_id, @parameters)

Adds one or more parameters associated with the given test request.

Returns a true value on success or undef on error.  Error messages
can be retrieved via the get_errors() routine.

=cut

sub add_test_request_to_parameter {
    my $self = shift;
    my $test_request_id = shift;

    my $sql = qq|
    INSERT INTO test_request_to_parameter (
       test_request_uid,
       parameter_uid,
       parameter_value
    ) VALUES ( ?, ?, "?" )
    |;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);

    foreach my $parameter (@_) {
        if (! $sth->execute($test_request_id,
                            $parameter->{parameter_id},
                            $parameter->{value}
                            ))
        {
            $self->_set_error("Could not insert parameter:  "
                              . $sth->errstr);
        }
    }
    return 1;
}


=head2 queue_test_request($test_request_id)

Puts the test request into 'QUEUED' state so it'll run.

Returns true if operation succeeded, false otherwise.

=cut

sub queue_test_request {
    my $self = shift;
    my $test_request_id = shift;

    return undef unless $test_request_id =~ /^\d+$/;

    my $sql = qq|
        UPDATE test_request SET status='Queued' WHERE uid=$test_request_id
        |;
    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);

    return $sth->execute();        
}

=head2 isint($x)

Returns true if the string is an integer (all decimals)

=cut

sub isint {
    my $x = shift;

    return ($x =~ /^\d+$/)? 1 : 0;
}


=head2 validate_test_request(\%request)

Validates the test request.  The %request hash has the information to be
stored as well as flags to control which sections of the request to
validate.  Define $request{d_store} to cause it to validate the entire 
request.

=cut

sub validate_test_request {
    my $self = shift;
    my $request = shift;

    my $errors = $request->{'errors'};
    my $method = \&new_test_request_page_1;
    validate_page_1($request);

    # We ladder our way through the pages in order.  If there are no
    # errors for the current page and the user has requested to go
    # to the next page, we allow them to do so, and scan to see
    # what errors exist for the next page.
    if ($request->{d_store} 
	or (keys(%{$errors}) == 0 && defined $request->{'d_next_to_components'})) {
        $method = \&new_test_request_page_2;
        if (defined $request->{'d_next_to_system_and_options'}) {
            validate_page_2($request);
        }
    }

    if ($request->{d_store} 
	or (keys(%{$errors}) == 0 and $request->{'d_next_to_system_and_options'})) {
        $method = \&new_test_request_page_3;
        if (defined $request->{'d_next_to_confirmation'}) {
            validate_page_3($request);
        }
    }

    if ($request->{d_store} 
	or (keys(%{$errors}) == 0 and $request->{'d_next_to_confirmation'})) {
        $method = \&new_test_request_page_4;
    }

    if (keys(%{$errors}) == 0 and $request->{'d_store'}) {
        $errors->{'store'} = 'ok';
        $method = \&new_test_request_page_5;
    }

    return $method->($request);
}

=head2 validate_page_1

Validates the test selection, user identification, and project.

=cut

sub validate_page_1 {
    my $self = shift;
    my $request = shift;
    my $errors = $request->{'errors'};

    # * test selection - is it in the database and of status=='Available'?
    if (! defined $request->{'d_test_uid'}) {
        $errors->{'test'} = 'Please select one of the tests';
    } else {
        my $test_id = $request->{'d_test_uid'};
        my $test = sql_get_test($test_id);
        if (! $test) {
            $errors->{'test'} = 'Could not find specified test in database';
        } elsif ($test->{'status'} ne 'Available') {
            $errors->{'test'} = 'Selected test is unavailable';
        }
    }

    # * User identification
    if (! defined $request->{'d_user_uid'}) {
        $errors->{'user'} = 'No user id was specified';
    } else {
        my $user_id = $request->{'d_user_uid'};
        my $user = sql_get_user($user_id);
        if (! $user) {
            $errors->{'user'} = 'Could not find user record '.$user_id;
        }
    }

    # * Project selection
    if (! defined $request->{'d_project_uid'}) {
        $errors->{'project'} = 'Please select one of the projects';
    } else {
        my $project_id = $request->{'d_project_uid'};
        my $project = sql_get_project($project_id);
        if (! $project) {
            $errors->{'project'} = "Could not find specified project number '$project_id' in database";
        }
    }
}

=head2 validate_page_2

Validates the distro tag and component patches.

=cut
sub validate_page_2 {
    my $self = shift;
    my $request = shift;
    my $errors = $request->{'errors'};

    # * distro tag - is it in the database with status 'Available'?
    #     and is it in the test_to_distro_tag table?
    if (! $request->{'d_distro_tag_uid'}) {
        $errors->{'distro_tag'} = 'Please select a distro';
    } else {
        my $distro_tag_id = $request->{'d_distro_tag_uid'};
        my $distro_tag = sql_get_distro_tag($distro_tag_id);
        if (! $distro_tag) {
            $errors->{'distro_tag'} = "Could not find specified distro number "
                . "'$distro_tag_id' in database";
        }
    }

    my $patches = $request->{'d_component_patch_id'};
    # * Linux kernel
    if (! $patches or ! defined $patches->{'linux'}) {
        $errors->{'component.linux'} = 'You must specify a Linux kernel patch';
    }

    return unless $patches;

    # * components
    foreach my $patch_type (keys %{$patches}) {
        my $patch_id = $patches->{'patch_type'};
        if ($patch_id) {
            # Do lookups of patch names and replace with patch id's
            if (! isint($patch_id)) {
                # Lookup patch id
                my $real_id = soap_plm_patch_find_by_name($patch_id);
                if (! isint($real_id)) {
                    $errors->{"component.$patch_type"} = 'Could not find patch "' 
                        . $patch_id . '" in the database';
                    return;
                } else {
                    $patch_id = $real_id;
                }
            }

            # Look up the patch name for this patch id number
            my $real_type = soap_plm_patch_get_software_type_from_id($patch_id);
            if (! $real_type or $real_type eq '') {
                $errors->{"component.$patch_type"} = 'Invalid patch id';
            } elsif ($patch_type ne $real_type) {
                $errors->{"component.$patch_type"} = 'This patch is for '
                    .$real_type.', not for '.$patch_type;
            }
        }
    }
}

=head2 validate_page_3(\%request)

Validates the host type, priority, lilo, sysctl, environment, and
parameters.

=cut

sub validate_page_3 {
    my $self = shift;
    my $request = shift;
    my $errors = $request->{'errors'};

    # * host_type
    if (! defined $request->{'d_host_type_uid'}) {
        $errors->{'host_type'} = 'You must specify the type of host to use';
    } else {
        my $test_id = $request->{'d_test_uid'};
        my $host_type_id = $request->{'d_host_type_uid'};
        my $host_type = sql_get_host_type($host_type_id);
        if (! $host_type) {
            $errors->{'host_type'} = 'Could not find specified host type in database';
        } else {
            my $v = sql_validate_host_type($test_id, $host_type_id);
            if (keys(%{$v}) < 1) {
                $errors->{'host_type'} = 'This is not a valid host type for this test.';
            }
        }
    }

    # * Priority
    if (! defined $request->{'d_test_priority'}) {
        $errors->{'test_priority'} = 'You must specify a test priority';
    } else {
        my $test_priority = $request->{'d_test_priority'};
        if ($test_priority !~ /^[123]$/) {
            $errors->{'test_priority'} = "Invalid priority '$test_priority' specified";
        }
    }

    # * Lilo
    if (defined $request->{'d_lilo'}) {
        my $lilo = $request->{'d_lilo'};
        my $errmsg = m_validate_lilo($lilo);
        if ($errmsg) {
            $errors->{'lilo'} = $errmsg;
        }
    }

    # * Sysctl
    if (defined $request->{'d_sysctl'}) {
        my $sysctl = $request->{'d_sysctl'};
        my $errmsg = m_validate_sysctl($sysctl);
        if ($errmsg) {
            $errors->{'sysctl'} = $errmsg;
        }
    }

    # * Environment
    if (defined $request->{'d_environment'}) {
        my $environment = $request->{'d_environment'};
        my $errmsg = m_validate_environment($environment);
        if ($errmsg) {
            $errors->{'environment'} = $errmsg;
        }
    }

    # * Parameters
    if (defined $request->{'d_parameter'}) {
        my $params = $request->{'d_parameter'};
        foreach my $param (sql_list_parameters(keys %{$params})) {
            my $value = $params->{$param->{'uid'}};
            if ($param->{'parameter_type'} eq 'pair') {
                if ($param->{'data_type'} eq 'int' && ! isint($value)) {
                    $errors->{'parameter.'.$param->{'uid'}} = 'Must specify an integer';
                } elsif ($param->{'data_type'} eq 'string' && ! $value) {
                    $errors->{'parameter.'+$param->{'uid'}} = 'Must specify a string';
                }
            } elsif ($param->{'parameter_type'} eq 'switch') {
                # No op
            } elsif ($param->{'parameter_type'} eq 'value') {
                if ($param->{'data_type'} eq 'int' && ! isint($value)) {
                    $errors->{'parameter.'.$param->{'uid'}} = 'Must specify an integer';
                } elsif ($param->{'data_type'} eq 'string' && ! $value) {
                    $errors->{'parameter.'.$param->{'uid'}} = 'Must specify a string';
                }
            } else {
                $errors->{'parameter.'.$param->{'uid'}} = 
                    'Unknown parameter type '.$param->{'parameter_type'};
            }
        }
    }
}
                       
1;

__END__


# Optimization ideas:
#  1.  Combine the SOAP calls for all components into one call.
#      This will require adding a new multi-component call to PLM
#      and revising the validation loop below.
#  2.  Create a more all-in-one sql call for doing the sql lookups.
#      Since most just need to check if something's in the DB, these
#      could probably be done in one go.  They're being done individually
#      at this point just for simplicity and clarity.
