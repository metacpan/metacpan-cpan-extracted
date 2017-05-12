
=head1 NAME

WebService::TestSystem::Metrics - Metrics about use of the testing system. 

=head1 SYNOPSIS

    my $metrics = new WebService::TestSystem::Metrics;

=head1 DESCRIPTION

WebService::TestSystem::Metrics provides several routines to extract
info about the testing system including number of users, tests that are
getting run heavily, etc.  These are intended for high level reports
for users, managers, and administrators about the system itself.

The routines in this module are all considered 'public access', thus
no authentication is required for retrieving them.

=head1 FUNCTIONS

=cut

package WebService::TestSystem::Metrics;

use strict;
use DBI;

use vars qw($VERSION %FIELDS);
our $VERSION = '0.06';

use fields qw(
              _app
              _site_domain
              _error_msg
              _debug
              );

=head2 new(%args)

Establishes a new WebService::TestSystem instance.  This sets up a database
connection.

You must give it a valid WebService::TestSystem object in the 'app'
argument.

Optionally, you can also specify the site domain name (default
'osdl.org') in the site_domain argument.  This is used to determine who
the 'external users' are for a given site installation.  Set this to the
domain name for your company to override it.

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

    $self->{'_site_domain'} = $args{'site_domain'} || 'osdl.org';

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


=head2 metrics_requests_per_month([$year][, $user_type])

Returns usage details of number of tests run and number users per month
for the given year (or the current year if $year is not defined.  By
default returns data for all users.  Specify 'external' for $user_type to
limit it to only users with non-'@osdl.org' email addresses.

Returns undef if $year or $user_type are not properly defined, or if it
could not obtain a database handle.

Fields returned:
    month
    year
    total_requests
    requestors
=cut

sub metrics_requests_per_month {
    my $self = shift;
    my $year = shift;
    my $user_type = shift;

    if (!$year) {
        $year = (localtime)[5] + 1900;
    }
    return undef unless ($year =~ /^\d\d\d\d$/);

    my $addy = $self->{_site_domain};

    my $sql;
    if (! $user_type || $user_type eq 'all') {
        $sql = qq|
	    SELECT MONTH(test_request.completion_date) AS month , 
            YEAR(test_request.completion_date) AS year, 
            COUNT(test_request.completion_date) AS total_requests,
            COUNT(distinct(test_request.created_by)) AS requestors
        FROM test_request, EIDETIC.user 
	WHERE YEAR(test_request.completion_date)=$year
        AND test_request.created_by=EIDETIC.user.uid
        GROUP BY MONTH(test_request.completion_date)|;
    } elsif ($user_type eq 'external') {
        $sql = qq|SELECT month(test_request.completion_date) AS month , 
            YEAR(test_request.completion_date) AS year, 
            COUNT(test_request.completion_date) AS total_requests,
            COUNT(distinct(test_request.created_by)) AS requestors
        FROM test_request, EIDETIC.user 
	WHERE year(test_request.completion_date)=$year

        AND test_request.created_by=EIDETIC.user.uid
        AND EIDETIC.user.Real_email NOT LIKE '%$addy'
        GROUP BY MONTH(test_request.completion_date)|;
        
    }

    my $dbh = $self->{_app}->_get_dbh() or return undef;

    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

=head2 metrics_test_run_time($year, $month)

Returns the total hours per test for a given month

Fields returned:
    id
    test
    count
    total_run_time
    ave_run_time

=cut

sub metrics_test_run_time {
    my $self = shift;
    my $year = shift;
    my $month = shift;

    if (! $year) {
	$year = (localtime)[5] + 1900;
    }
    return undef unless ($year =~ /^\d\d\d\d$/);

    if (! $month) {
	$month = (localtime)[4] + 1;
    }
    return undef unless ($month =~ /^\d+$/);

    my $sql = qq|
	SELECT test.uid as id, test.descriptor AS test, 
        COUNT(test_request.completion_date) AS count, 
        TRUNCATE(SUM(time_to_sec(test_request.completion_date)
                     - time_to_sec(test_request.started_date))/3600,1) 
            AS total_run_time, 
        TRUNCATE(avg(time_to_sec(test_request.completion_date)
                     - time_to_sec(test_request.started_date))/3600,1) 
            AS ave_run_time 
        from test_request, test 
        where test.uid=test_request.test_uid 
        and test_request.started_date is not null 
        and test_request.completion_date is not null 
        and time_to_sec(started_date)<time_to_sec(completion_date)
        and year(test_request.completion_date)=$year
        and month(test_request.completion_date)=$month
        group by test_uid|;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

=head2 metrics_distros_tested_per_month([$year])

Returns listing of different distros tested each month.

Fields returned:
    month
    count

=cut
sub metrics_distros_tested_per_month {
    my $self = shift;
    my $year = shift;

    if (!$year) {
        $year = (localtime)[5] + 1900;
    }
    return undef unless ($year =~ /^\d\d\d\d$/);

    my $sql = qq| 
	SELECT MONTH(completion_date) as month, 
        COUNT(DISTINCT(distro_tag_uid)) as count 
        FROM test_request 
	WHERE YEAR(completion_date)=$year 
	GROUP BY month 
	|;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

# Detail of a particular test
#
# select test_uid, started_date, completion_date,
# truncate((time_to_sec(completion_date)-time_to_sec(started_date))/3600,2)
# as run_time from test_request where test_uid=53 and
# month(completion_date)=9 and year(completion_date)=2004

# Distro breakdown:
#
# select month(completion_date) as month,
# count(distinct(distro_tag_uid)) as distros from test_request where
# year(completion_date)=2004 group by month(completion_date);


=head2 metrics_test_request_status_totals()

Returns a list of total requests in each status.

Fields returned:
    status
    total

=cut

sub metrics_test_request_status_totals {
    my $self = shift;

    my $sql = qq|
	SELECT status, COUNT(uid) as total 
	FROM test_request 
	GROUP BY status
	|;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

=head2 metrics_queue_lengths()

Returns the number of queued test requests for each host type

=cut

sub metrics_queue_lengths {
    my $self = shift;

    my $sql = qq|
	SELECT host_type.uid as id, host_type.descriptor, test_request.status, 
	COUNT(test_request.status='Queued') AS queue_length 
	FROM test_request 
	LEFT JOIN host_type ON test_request.host_type_uid=host_type.uid 
	GROUP BY host_type.uid, test_request.status 
	ORDER BY host_type.descriptor
	|;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}


=head2

Returns the number of test requests for the given host type, for
each status type.

=cut

sub metrics_host_type_test_status_totals {
    my $self = shift;

    my $sql = qq|
	SELECT host_type.descriptor AS host_type, test_request.status, 
	COUNT(test_request.uid) AS total_tests, 
	test_request.completion_date AS last_completed, 
	test.descriptor AS test FROM test_request, host_type, test 
	WHERE test_request.test_uid=test.uid 
	AND test_request.host_type_uid=host_type.uid 
	GROUP BY host_type_uid, test_request.status 
	ORDER BY test_request.status, test_request.completion_date 
	DESC
	|;
    
    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

=head2 metrics_queue_age([$age])

Returns the number of test requests of different states for the past
$age (default 60) days.

=cut

sub metrics_queue_age {
    my $self = shift;
    my $age = shift || '60';
    return undef unless ($age =~ /^\d+$/);

    my $sql = qq|
	SELECT YEAR(created_date) AS year, MONTH(created_date) AS month, 
	DAYOFMONTH(created_date) AS day, status, COUNT(uid) AS count 
	FROM test_request 
	WHERE TO_DAYS(NOW())-TO_DAYS(created_date)<$age
	GROUP BY DAYOFMONTH(created_date), status 
	ORDER BY created_date DESC
	|;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

=head2 metrics_patches_queued()

=cut

sub metrics_patches_queued {
    my $self = shift;

    my $sql = qq|
	SELECT p.uid AS patch_id, p.descriptor AS patch_name, 
	COUNT(t.uid) AS num_queued,  h.descriptor AS host_type 
	FROM test_request as t, patch_tag p, test_request_to_patch_tag trp, host_type as h 
	WHERE t.status='Queued' 
	AND trp.test_request_uid = t.uid 
	AND h.uid = t.host_type_uid 
	AND trp.patch_tag_uid = p.uid and p.software_type = 'linux' 
	GROUP BY p.uid, h.descriptor 
	ORDER BY h.uid, t.test_priority, t.uid
	|;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

=head2 metrics_monthly_tests_per_host()

Returns the number of test requests per host per month for the last 
90 days.

=cut

sub metrics_monthly_tests_per_host {
    my $self = shift;
    my $sql = qq|
        SELECT MONTH(completion_date) as month, host.descriptor AS host, 
        COUNT(test_request.uid) AS count 
        FROM test_request, host 
        WHERE test_request.host_uid=host.uid 
        AND (TO_DAYS(NOW())-TO_DAYS(completion_date))<90 
	GROUP BY host_uid, MONTH(completion_date) 
        ORDER BY host, month DESC |;

    my $dbh = $self->{_app}->_get_dbh() or return undef;
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my @usage = ();
    while (my $row = $sth->fetchrow_hashref) {
        push @usage, $row;
    }
    $sth->finish;

    return \@usage;
}

1;
