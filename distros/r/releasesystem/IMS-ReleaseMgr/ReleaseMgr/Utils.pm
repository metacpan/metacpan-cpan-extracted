###############################################################################
#
#         May be distributed under the terms of the artistic license
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: Utils.pm,v 1.19 2000/05/23 21:25:59 keving Exp $
#
#   Description:    Miscellaneous utility routines shared by the release
#                   manager tools.
#
#   Functions:      write_log_line
#                   SIG_inc_trace
#                   SIG_dec_trace
#                   DBI_mirror_specification
#                   DBI_mirror_host_list
#                   DBI_mirror_phys_host_list
#                   DBI_all_mirrors
#                   DBI_all_hostlists
#                   DBI_match_mirror_to_host
#                   DBI_error
#                   file_mirror_specification
#                   file_mirror_host_list
#                   fork_as_daemon
#                   send_mail
#                   show_version
#                   eval_make_target
#                   named_params
#                   variable_substitution
#
#   Libraries:      None.
#
#   Global Consts:  $VERSION            Version information for this module
#                   $revision           Copy of the RCS revision string
#
#   Environment:    None.
#
###############################################################################
package IMS::ReleaseMgr::Utils;

use 5.002;
use strict;
use vars qw($VERSION $revision @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use subs qw(write_log_line
            SIG_inc_trace SIG_dec_trace
            DBI_mirror_specification DBI_mirror_host_list
            DBI_mirror_phys_host_list
              DBI_all_mirrors DBI_all_hostlists DBI_match_mirror_to_host
              DBI_error
            file_mirror_specification file_mirror_host_list file_error
            fork_as_daemon
            named_params variable_substitution);

use AutoLoader     'AUTOLOAD';
use Fcntl          ':flock';
use File::Path     'mkpath';
use File::Basename 'dirname';
use Net::Domain    'hostfqdn';
use Exporter;
use IO::File;

$VERSION = do {my @r=(q$Revision: 1.19 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$revision = q$Id: Utils.pm,v 1.19 2000/05/23 21:25:59 keving Exp $;

@ISA = qw(Exporter);

@EXPORT = ();
@EXPORT_OK = qw(write_log_line
                SIG_inc_trace SIG_dec_trace
                fork_as_daemon
                eval_make_target
                send_mail
                show_version
                variable_substitution
                DBI_mirror_specification DBI_mirror_host_list
                DBI_mirror_phys_host_list
                  DBI_all_mirrors DBI_all_hostlists DBI_match_mirror_to_host
                  DBI_error
                file_mirror_specification file_mirror_host_list file_error);
%EXPORT_TAGS = (
                'signals' => [qw(SIG_inc_trace SIG_dec_trace)],
                'DBI'     => [qw(DBI_mirror_specification
                                 DBI_mirror_host_list
                                 DBI_mirror_phys_host_list
                                 DBI_all_mirrors
                                 DBI_all_hostlists
                                 DBI_match_mirror_to_host
                                 DBI_error)],
                'file'    => [qw(file_mirror_specification
                                 file_mirror_host_list
                                 file_error)],
                'all'     => [@EXPORT_OK]
               );

$IMS::ReleaseMgr::Utils::DBI_error  = '';
$IMS::ReleaseMgr::Utils::file_error = '';

1;

###############################################################################
#
#   Sub Name:       write_log_line
#
#   Description:    Open the file $file, lock and seek to end, then write
#                   @line + \n chars.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $file     in      scalar    File to write log into
#                   @lines    in      scalar    Text to write
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    dies
#
##############################################################################
sub write_log_line
{
    my ($file, @lines) = @_;

    my ($fh, $needs_unlock);

    if ($file eq '-')
    {
        $fh = \*STDOUT;
        $needs_unlock = 0;
    }
    else
    {
        my $dir = dirname $file;
        mkpath($dir, 0, 0755) or return undef
            if (! -d $dir);
        $fh = new IO::File ((-e $file) ? "+< $file" : "> $file");
        return undef if (! defined $fh);
        flock($fh, LOCK_EX);
        seek($fh, 0, 2);
        $needs_unlock = 1;
    }

    for (@lines) { print $fh "$_\n" }

    flock($fh, LOCK_UN) if $needs_unlock;
    $fh->close;

    1;
}

###############################################################################
#
#   Sub Name:       SIG_inc_trace
#
#   Description:    Increment the value of $main::trace. No high-end check is
#                   done, so don't be a dweeb and send a few thousand signals
#                   to this handler. If $main::trace_file is not set, then
#                   set it to the command-name with a ".trace" suffix. If there
#                   is a LOGGING_DIR environment value set, file goes there,
#                   else it goes in the dir that the calling tool resides in.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $sig      in      scalar    Signal that was caught
#
#   Globals:        $main::trace
#                   $main::tfile
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub SIG_inc_trace
{
    my $sig = shift;

    $SIG{$sig} = \&SIG_inc_trace;

    my $cmd = $0;

    $cmd =~ s|.*/||o;
    $main::trace++;
    # If we ever need more than 8 bits of tracing, our problems far exceed a
    # single hard-coded constant
    $main::trace &= 0xff;

    write_log_line(($main::tfile || "$0.trace"),
                   sprintf("$cmd [$$] [%s] Trace-level changed to $::trace",
                           scalar localtime time));

    1;
}

###############################################################################
#
#   Sub Name:       SIG_dec_trace
#
#   Description:    Decrement the value of $main::trace by 1, but not lower
#                   than 0. If $main::trace is still greater than 0, send a
#                   trace message noting the change.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $sig      in      scalar    Signal that was caught
#
#   Globals:        $main::trace
#                   $main::tfile
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub SIG_dec_trace
{
    my $sig = shift;

    $SIG{$sig} = \&SIG_dec_trace;

    my $cmd = ($main::cmd || $0);

    $cmd =~ s|.*/||o;
    if (defined $main::trace and $main::trace)
    {
        $main::trace--;
    }
    else
    {
        $main::trace = 0;
    }

    write_log_line(($main::tfile || "$0.trace"),
                   sprintf("$cmd [$$] [%s] Trace-level changed to $::trace",
                           scalar localtime time));

    1;
}

__END__

###############################################################################
#
#   Sub Name:       DBI_mirror_specification
#
#   Description:    Query the database and retrieve the full record for the
#                   mirror pool defined in the the named parameter 'mirror'.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Named param list-- each is
#                                                 defined when used
#
#   Globals:        None.
#
#   Environment:    ORACLE_SID (maybe)
#
#   Returns:        Success:    hash table reference
#                   Failure:    undef
#
###############################################################################
sub DBI_mirror_specification
{
    my %opts = named_params(@_);

#    require IMS::DBConnect; import IMS::DBConnect 'GetDBConnect';

    unless (defined $opts{mirror} and $opts{mirror})
    {
        $! = "DBI_mirror_specification must be called with a mirror name";
        return undef;
    }

    my ($dbh, $sth, %results, $labels, $values);

    #
    # application - Specific application to look up connection information for
    # role        - Role (in case of multiple roles with varying access)
    # system      - The database system to which the connection should be made
    #
    $opts{'system'}    = $opts{'system'}    || 'SYSTEM';
    $opts{application} = $opts{application} || 'USERNAME';
    $opts{role}        = $opts{role}        || 'PASSWORD';
    # unless ($dbh = GetDBConnect($opts{application}, $opts{role}, $opts{'system'}))
    unless ($dbh = DBI->connect("dbi:Oracle:$opts{'system'}", $opts{application}, 
	                        $opts{role}))
    {
        DBI_error "Error initializing database connect to $opts{'system'}";
        return undef;
    }

    #
    # Prep, execute and reap data from the handle
    #
    unless ($sth = $dbh->prepare("select * from mirror_specification where " .
                                 "mirror_name = '$opts{mirror}'"))
    {
        DBI_error "Error making SQL statement: " . $dbh->errstring;
        return undef;
    }
    $sth->execute;
    $labels = $sth->{NAME};
    $values = $sth->fetchrow_arrayref;
    unless (defined $labels and defined $values)
    {
        DBI_error "Error executing SQL: " . $dbh->errstring;
        return undef;
    }
    @results{@$labels} = @$values;
    $sth->finish;
    $dbh->disconnect;
    DBI_error ''; #clear

    variable_substitution \%results unless (defined $opts{noexpand} and
                                            $opts{noexpand});

    \%results;
}

###############################################################################
#
#   Sub Name:       DBI_mirror_host_list
#
#   Description:    Retrieve the list of hostnames/ports for all machines that
#                   comprise the mirror pool named in 'mirror'.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Named param list-- each is
#                                                 defined when used
#
#   Globals:        None.
#
#   Environment:    ORACLE_SID (maybe)
#
#   Returns:        Success:    list reference
#                   Failure:    undef
#
###############################################################################
sub DBI_mirror_host_list
{
    my %opts = named_params(@_);

    #require IMS::DBConnect; import IMS::DBConnect 'GetDBConnect';

    unless (defined $opts{mirror} and $opts{mirror})
    {
        DBI_error "DBI_mirror_host_list must be called with a mirror name";
        return undef;
    }

    my ($dbh, $sth, @results, $host, $port);

    #
    # application - Specific application to look up connection information for
    # role        - Role (in case of multiple roles with varying access)
    # system      - The database system to which the connection should be made
    #
    $opts{'system'}    = $opts{'system'}    || 'SYSTEM';
    $opts{application} = $opts{application} || 'USERNAME';
    $opts{role}        = $opts{role}        || 'PASSWORD';
    #unless ($dbh = GetDBConnect($opts{application}, $opts{role}, $opts{'system'}))
    unless ($dbh = DBI->connect("dbi:Oracle:$opts{'system'}", $opts{application}, 
	                        $opts{role}))
    {
        DBI_error "Error initializing database connect to $opts{'system'}";
        return undef;
    }

    #
    # Prep, execute and reap data from the handle
    #
    unless ($sth = $dbh->prepare("select host_name, server_port from " .
                                 "mirror_pool_host_list where mirror_pool = " .
                                 "'$opts{mirror}'"))
    {
        DBI_error "Error making SQL statement: " . $dbh->errstring;
        return undef;
    }
    $sth->execute;
    unless ($sth->bind_columns(undef, \$host, \$port))
    {
        DBI_error "Error binding columns: " . $dbh->errstring;
        return undef;
    }
    while ($sth->fetch)
    {
        $host .= ":$port" if (defined $port and $port and $port != 80);
        push(@results, $host);
    }
    $sth->finish;
    $dbh->disconnect;
    DBI_error ''; #clear

    \@results;
}

###############################################################################
#
#   Sub Name:       DBI_mirror_phys_host_list
#
#   Description:    Retrieve the list of physical hostnames/ports for all
#                   machines that comprise the mirror pool named in 'mirror'.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Named param list-- each is
#                                                 defined when used
#
#   Globals:        None.
#
#   Environment:    ORACLE_SID (maybe)
#
#   Returns:        Success:    list reference
#                   Failure:    undef
#
###############################################################################
sub DBI_mirror_phys_host_list
{
    my %opts = named_params(@_);

    #require IMS::DBConnect; import IMS::DBConnect 'GetDBConnect';

    unless (defined $opts{mirror} and $opts{mirror})
    {
        DBI_error "DBI_mirror_phys_host_list must be called with a mirror name";
        return undef;
    }

    my ($dbh, $sth, @results, $host, $port);

    #
    # application - Specific application to look up connection information for
    # role        - Role (in case of multiple roles with varying access)
    # system      - The database system to which the connection should be made
    #
    $opts{'system'}    = $opts{'system'}    || 'SYSTEM';
    $opts{application} = $opts{application} || 'USERNAME';
    $opts{role}        = $opts{role}        || 'PASSWORD';
    #unless ($dbh = GetDBConnect($opts{application}, $opts{role}, $opts{'system'}))
    unless ($dbh = DBI->connect("dbi:Oracle:$opts{'system'}", $opts{application}, 
	                        $opts{role}))
    {
        DBI_error "Error initializing database connect to $opts{'system'}";
        return undef;
    }

    #
    # Prep, execute and reap data from the handle
    #
    unless ($sth = $dbh->prepare("select physical_host, server_port from " .
                                 "mirror_pool_host_list where mirror_pool = " .
                                 "'$opts{mirror}'"))
    {
        DBI_error "Error making SQL statement: " . $dbh->errstring;
        return undef;
    }
    $sth->execute;
    unless ($sth->bind_columns(undef, \$host, \$port))
    {
        DBI_error "Error binding columns: " . $dbh->errstring;
        return undef;
    }
    while ($sth->fetch)
    {
        $host .= ":$port" if (defined $port and $port and $port != 80);
        push(@results, $host);
    }
    $sth->finish;
    $dbh->disconnect;
    DBI_error ''; #clear

    \@results;
}

###############################################################################
#
#   Sub Name:       DBI_all_mirrors
#
#   Description:    Return a hash table reference keyed by mirror name that
#                   holds the full specifications of all mirrors defined in
#                   the database.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Typical list of optional name/
#                                                 value pairs used as options
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    hash reference
#                   Failure:    undef, sets DBI_error
#
###############################################################################
sub DBI_all_mirrors
{
    my %opts = named_params(@_);

    #require IMS::DBConnect; import IMS::DBConnect 'GetDBConnect';

    my ($dbh, $sth, %results, $labels, $values);

    #
    # application - Specific application to look up connection information for
    # role        - Role (in case of multiple roles with varying access)
    # system      - The database system to which the connection should be made
    #
    $opts{'system'}    = $opts{'system'}    || 'SYSTEM';
    $opts{application} = $opts{application} || 'USERNAME';
    $opts{role}        = $opts{role}        || 'PASSWORD';
    #unless ($dbh = GetDBConnect($opts{application}, $opts{role}, $opts{'system'}))
    unless ($dbh = DBI->connect("dbi:Oracle:$opts{'system'}", $opts{application}, 
	                        $opts{role}))
    {
        DBI_error "Error initializing database connect to $opts{'system'}";
        return undef;
    }

    #
    # Prep, execute and reap data from the handle
    #
    unless ($sth = $dbh->prepare("select * from mirror_specification"))
    {
        DBI_error "Error making SQL statement: " . $dbh->errstring;
        return undef;
    }
    $sth->execute;
    $labels = $sth->{NAME};
    unless (defined $labels)
    {
        DBI_error "Error executing SQL: " . $dbh->errstring;
        return undef;
    }
    while (defined($values = $sth->fetchrow_arrayref))
    {
        my %one_hash;
        @one_hash{@$labels} = @$values;
        variable_substitution \%one_hash unless (defined $opts{noexpand} and
                                                 $opts{noexpand});
        $results{$one_hash{MIRROR_NAME}} = \%one_hash;
    }
    $sth->finish;
    $dbh->disconnect;
    DBI_error ''; #clear

    \%results;
}

###############################################################################
#
#   Sub Name:       DBI_all_hostlists
#
#   Description:    Return a hash table reference keyed by mirror name that
#                   holds the full lists of mirror groups (all ancillary hosts
#                   that comprise a mirror group).
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Typical list of optional name/
#                                                 value pairs used as options
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    list reference of hashrefs
#                   Failure:    undef, sets DBI_error
#
###############################################################################
sub DBI_all_hostlists
{
    my %opts = named_params(@_);

    #require IMS::DBConnect; import IMS::DBConnect 'GetDBConnect';

    my ($dbh, $sth, @results, $labels, $values);
    @results = ();

    #
    # application - Specific application to look up connection information for
    # role        - Role (in case of multiple roles with varying access)
    # system      - The database system to which the connection should be made
    #
    $opts{'system'}    = $opts{'system'}    || 'SYSTEM';
    $opts{application} = $opts{application} || 'USERNAME';
    $opts{role}        = $opts{role}        || 'PASSWORD';
    #unless ($dbh = GetDBConnect($opts{application}, $opts{role}, $opts{'system'}))
    unless ($dbh = DBI->connect("dbi:Oracle:$opts{'system'}", $opts{application}, 
	                        $opts{role}))
    {
        DBI_error "Error initializing database connect to $opts{'system'}";
        return undef;
    }

    #
    # Prep, execute and reap data from the handle
    #
    unless ($sth = $dbh->prepare("select * from mirror_pool_host_list"))
    {
        DBI_error "Error making SQL statement: " . $dbh->errstring;
        return undef;
    }
    $sth->execute;
    $labels = $sth->{NAME};
    unless (defined $labels)
    {
        DBI_error "Error executing SQL: " . $dbh->errstring;
        return undef;
    }
    while (defined($values = $sth->fetchrow_arrayref))
    {
        my %one_hash;
        @one_hash{@$labels} = @$values;
        push(@results, \%one_hash);
    }
    $sth->finish;
    $dbh->disconnect;
    DBI_error ''; #clear

    \@results;
}

###############################################################################
#
#   Sub Name:       DBI_match_mirror_to_host
#
#   Description:    Using the mirror name and the physical host name, deduce
#                   the host's mirror-specific name, i.e.:
#
#                     mirror => 'www.interactive.hp.com'
#                     host   => 'hpcc925.external.hp.com'
#
#                   would return (as of 7/7/99) 'www1.interactive.hp.com'
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Named set of parameters
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    host name
#                   Failure:    undef, sets DBI_error
#
###############################################################################
sub DBI_match_mirror_to_host
{
    my %opts = named_params(@_);

    #require IMS::DBConnect; import IMS::DBConnect 'GetDBConnect';

    my ($dbh, $sth, $results, $result);

    #
    # application - Specific application to look up connection information for
    # role        - Role (in case of multiple roles with varying access)
    # system      - The database system to which the connection should be made
    #
    $opts{'system'}    = $opts{'system'}    || 'SYSTEM';
    $opts{application} = $opts{application} || 'USERNAME';
    $opts{role}        = $opts{role}        || 'PASSWORD';
    #unless ($dbh = GetDBConnect($opts{application}, $opts{role}, $opts{'system'}))
    unless ($dbh = DBI->connect("dbi:Oracle:$opts{'system'}", $opts{application}, 
	                        $opts{role}))
    {
        DBI_error "Error initializing database connect to $opts{'system'}";
        return undef;
    }

    #
    # Prep, execute and reap data from the handle
    #
    unless ($sth = $dbh->prepare("select host_name from " .
                                 "mirror_pool_host_list where " .
                                 "mirror_pool = '$opts{mirror}' and " .
                                 "physical_host = '$opts{host}'"))
    {
        DBI_error "Error making SQL statement: " . $dbh->errstring;
        return undef;
    }
    $sth->execute;

    #
    # Since the HOST_NAME column is unique, There Can, well, Be Only One.
    #
    $results = $sth->fetchrow_arrayref;
    if (! defined($result = $results->[0]))
    {
        DBI_error "No match in DBMS for $opts{mirror}, $opts{host}";
    }
    $sth->finish;
    $dbh->disconnect;

    $result;
}

###############################################################################
#
#   Sub Name:       DBI_error
#
#   Description:    Get/set the error string associated with a failed DB action
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $text     in      scalar    (If passed) Text of new error
#
#   Globals:        $IMS::ReleaseMgr::Utils::DBI_error
#
#   Environment:    None.
#
#   Returns:        text or null
#
###############################################################################
sub DBI_error
{
    my $text = shift;

    $IMS::ReleaseMgr::Utils::DBI_error = $text if (defined $text);

    $IMS::ReleaseMgr::Utils::DBI_error;
}

###############################################################################
#
#   Sub Name:       file_mirror_specification
#
#   Description:    Retrieve the full record for the mirror pool specified in
#                   the parameter 'file'.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Named param list-- each is
#                                                 defined when used
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    hash table reference
#                   Failure:    undef
#
###############################################################################
sub file_mirror_specification
{
    my %opts = named_params(@_);

    require IO::File;

    # clear the error handler
    file_error '';

    unless (defined $opts{file} and $opts{file})
    {
        file_error "file_mirror_specification: must be called with file name";
        return undef;
    }

    my ($fh, %results, $label, $value);

    unless (defined($fh = new IO::File "< $opts{file}"))
    {
        file_error "file_mirror_specification: Error opening file " .
            "$opts{file} for reading: $!";
        return undef;
    }
    while (defined($_ = <$fh>))
    {
        chomp;
        next unless /^[A-Z0-9_]+=/o;

        ($label, $value) = split(/=/, $_, 2);
        $results{$label} = $value;
    }
    $fh->close;
    variable_substitution \%results;

    \%results;
}

###############################################################################
#
#   Sub Name:       file_mirror_host_list
#
#   Description:    Retrieve the list of hostnames/ports for all machines that
#                   comprise the mirror pool from the file 'file'.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Named param list-- each is
#                                                 defined when used
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    list reference
#                   Failure:    undef
#
###############################################################################
sub file_mirror_host_list
{
    my %opts = named_params(@_);

    require IO::File;

    # clear the error handler
    file_error '';

    unless (defined $opts{file} and $opts{file})
    {
        file_error "file_mirror_host_list: must be called with a file name";
        return undef;
    }

    my ($fh, @results, $host, $phost);

    @results = ();
    unless (defined($fh = new IO::File "< $opts{file}"))
    {
        file_error "file_mirror_host_list: Error opening file $opts{file} " .
            "for reading: $!";
        return undef;
    }
    while (defined($_ = <$fh>))
    {
        chomp;
        next if /^\#/o;
        next if /^\s*$/o;

        # Just in case they give the physical host as well, we just want the
        # "alias" hostname
        ($host, $phost) = split(/ /, $_, 2);
        push(@results, $host);
    }
    $fh->close;

    \@results;
}

###############################################################################
#
#   Sub Name:       file_match_mirror_to_host
#
#   Description:    Using the physical host name, deduce the host's
#                   mirror-specific name, i.e.:
#
#                     host   => 'hpcc925.external.hp.com'
#
#                   would return (as of 7/7/99) 'www1.interactive.hp.com'
#
#                   Differs from the DBI version in that it requires a file
#                   be present, and the file might not have the physical host
#                   information. Assuming it does, we also don't need the
#                   actual mirror name. We assume you passed the correct file.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   %opts     in      hash      Named set of parameters
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    host name
#                   Failure:    undef, sets file_error
#
###############################################################################
sub file_match_mirror_to_host
{
    my %opts = named_params(@_);

    require IO::File;

    # clear the error handler
    file_error '';

    unless (defined $opts{file} and $opts{file})
    {
        file_error "file_match_mirror_to_host: must be called with file name";
        return undef;
    }
    unless (defined $opts{host} and $opts{host})
    {
        file_error "file_match_mirror_to_host: no hostname provided for match";
        return undef;
    }

    my ($fh, $result, $host, $phost);

    unless (defined($fh = new IO::File "< $opts{file}"))
    {
        file_error "Error opening file $opts{file} for reading: $!";
        return undef;
    }
    # set this as the fall-through case
    $result = undef;
    while (defined($_ = <$fh>))
    {
        chomp;
        next if /^\#/o;
        next if /^\s*$/o;

        ($host, $phost) = split(/ /, $_, 2);
        if ($phost eq $opts{host})
        {
            $result = $host;
            last;
        }
    }
    $fh->close;
    file_error "file_match_mirror_to_host: no match for $opts{host} found"
        unless (defined $result);

    $result;
}

###############################################################################
#
#   Sub Name:       file_error
#
#   Description:    Retrieve/set the error message for the last failed file
#                   operation.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $text     in      scalar    If defined, set the error to
#                                                 this.
#
#   Globals:        $IMS::ReleaseMgr::Utils::file_error
#
#   Environment:    None.
#
#   Returns:        Current error text
#
###############################################################################
sub file_error
{
    my $text = shift;

    $IMS::ReleaseMgr::Utils::file_error = $text if (defined $text);

    $IMS::ReleaseMgr::Utils::file_error;
}

###############################################################################
#
#   Sub Name:       fork_as_daemon
#
#   Description:    Do the necessary process- and signal-handling for the
#                   running process to act and react properly as a UNIX daemon.
#                   Mostly lifted from Stevens' books.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $dont_die in      scalar    If passed and true, don't die()
#                                                 on errors, return the error
#                                                 message instead.
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    null string
#                   Failure:    dies or returns error string
#
###############################################################################
sub fork_as_daemon
{
    my $dont_die = shift;

    my ($child, $sig);

    $dont_die = 0 unless (defined $dont_die and $dont_die);
    $child = fork;
    if (! defined $child)
    {
        # Uh oh.
        die "$0 died in fork: $!, crashing" unless ($dont_die);
        # Only reached if we skipped the die
        return "Error in fork: $!";
    }
    elsif ($child)
    {
        # Parent process
        exit 0;
    }

    #
    # First-generation child. Close filehandles, clear umask, and set a process
    # group. This will also disassociate us from any control terminal.
    #
    setpgrp;
    close(STDIN);
    close(STDOUT);
    close(STDERR);
    umask 0;
    for $sig (qw(TSTP TTIN TTOU))
    {
        $SIG{$sig} = 'IGNORE' if (exists $SIG{$sig});
    }

    #
    # Since we're on SysV, we could accidentally re-acquire a control terminal,
    # so to avoid that, we'll re-spawn, so that the child is not the pgrp
    # leader. Then *this* parent will exit, and control will continue with the
    # second-generation child. Ignore HUP for now (restore it in the 2nd-gen
    # child) so that the 1st-gen child's HUP doesn't kill the 2nd-gen child.
    #
    $sig = $SIG{HUP};
    $SIG{HUP} = 'IGNORE';

    $child = fork;
    if (! defined $child)
    {
        # Uh oh.
        die "$0 (1st-generation child) died in fork: $!, crashing"
            unless ($dont_die);
        # Only reached if we skipped the die
        return "Error in (1st-generation child) fork: $!";
    }
    elsif ($child)
    {
        # Parent process
        exit 0;
    }

    #
    # We are the second-generation child, and all our file descriptors are
    # taken care of, our umask is set, our process group is set. All we have
    # to do is restore HUP (which will probably be set later on, anyway) and
    # return.

    $SIG{HUP} = $sig;
    return '';
}

##############################################################################
#
#   Sub Name:       send_mail
#
#   Description:    Send the mail message contained in $body (which may be
#                   either a scalar or a list ref) to the list of addresses
#                   in $maillist (also a scalar or lref), with subject of
#                   $subject.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $maillist in      scalar    One or more addresses to mail
#                                                 to, comma-separated
#                   $subject  in      scalar    Subject to attach to mail
#                   $body     in      sc/lref   Message body (could be scalar
#                                                 or lref)
#
#   Globals:        $main::hostname     These are inserted into X-* headers
#                   $main::cmd            if they are defined in the main
#                   $main::webmaster      namespace.
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
##############################################################################
sub send_mail
{
    my ($maillist, $subject, $body) = @_;

    require Mail::Header;
    require Mail::Internet;

    my $hdr = new Mail::Header;

    if (! ref($body))
    {
        $body = [$body];
    }
    #
    # Create the headers
    #
    return 1 unless ($maillist =~ /\@/o); # Empty list unless at least one @
    $hdr->add('To', $maillist);
    # Subject made to refer to what command & hostname we are mailing from
    $hdr->add('Subject', "$subject");
    $hdr->add('From', $main::webmaster) if (defined $main::webmaster);
    # This allows for filtering/processing by giving a unique header
    my $agent;
    if (defined $main::cmd)
    {
        $agent = $main::cmd;
        $agent .= ", $main::VERSION" if (defined $main::VERSION);
    }
    else
    {
        $agent = "IMS::ReleaseMgr::Utils::send_mail, $VERSION";
    }
    $hdr->add('X-Agent', $agent);
    # Ident the host in case they didn't
    $hdr->add('X-Hostname', ((defined $main::hostname) ?
                             $main::hostname : hostfqdn));

    my $msg = Mail::Internet->new(Header => $hdr, Body => $body);
   
    my @addresses;

    eval { @addresses = $msg->smtpsend; };  #if this fails the program dies...so eval

    my $trace = (defined $main::trace) ? $main::trace : 0;

    if ($trace & 2)
    {
	$maillist =~ s/\s//g;                     #remove whitespace
	my $mailsucceed = join ',',@addresses;

        write_log_line($main::tfile,
                   sprintf("$main::cmd [$$] [%s] Mail sent to: %s",
                           (scalar localtime time), $mailsucceed));
        write_log_line($main::tfile,
                   sprintf("$main::cmd [$$] [%s] Warning! Some addresses failed." .
		   " Complete mail list: %s",
                   (scalar localtime time), $maillist)) 
		       if ($mailsucceed ne $$maillist);
    }

    1;
}

###############################################################################
#
#   Sub Name:       show_version
#
#   Description:    Output a simple version identification string to STDERR
#
#   Arguments:      None
#
#   Globals:        $::cmd
#                   $::VERSION
#                   $::revision
#
#   Environment:    None.
#
#   Returns:        Success:    0, was able to display *something*
#                   Failure:    1, nothing found suitable for output
#
###############################################################################
sub show_version
{
    if (defined $::VERSION)
    {
        if (defined $::cmd)
        {
            print STDERR "$::cmd $::VERSION\n";
        }
        else
        {
            print STDERR "$::VERSION\n";
        }
    }
    elsif (defined $::revision)
    {
        print STDERR "$::revision\n";
    }
    else
    {
        return 1;
    }

    0;
}

###############################################################################
#
#   Sub Name:       eval_make_target
#
#   Description:    Execute "make" on the given target, using eval so as to
#                   trap any fatal errors
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $target   in      scalar    target to pass to make
#                   $dir_root in      scalar    If non-null, use this to
#                                                 construct a set of paths to
#                                                 pass as command-line values
#                   $host     in      scalar    Host staging to (or on)
#                                                 for makefile variable
#                   @args     in      list      If present, any additional
#                                                 arguments to make
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    undef
#                   Failure:    reference to list of error text
#
###############################################################################
sub eval_make_target
{
    my $target   = shift;
    my $dir_root = shift || '';
    my $host     = shift || '';
    my @args     = @_;

    return [ 'eval_make_target: Error, must specify a target for make' ]
        unless (defined $target);

    if ($dir_root)
    {
        push(@args,
             "TARGETHOST=$host",
             "WWWDOC=$dir_root/htdocs",
             "WWWBIN=$dir_root/bin",
             "WWWCGI=$dir_root/cgi-bin",
             "WWWFCGI=$dir_root/fcgi-bin",
             "WWWJAVA=$dir_root/applets",
             "WWWLOCAL=$dir_root/local");
    }

    my $args = (scalar @args) ? " @args" : "";
    my @result = ();

    open(PIPE, "make $target$args 2>&1 |");
    @result = <PIPE>;
    close(PIPE);
    $? >>= 8;
    if ($?)
    {
        unless (grep(/no rule to make/oi, @result))
        {
            chomp(@result);
            push(@result,
                 "Error executing make, make returned code $? at " . __FILE__);

            return \@result;
        }
    }

    undef;
}

###############################################################################
#
#   Sub Name:       named_params
#
#   Description:    (Not exported) Take a list in that is intended to be a
#                   hash table of named parameters (name/value pairs), delete
#                   any leading hyphens and force all names to lower-case.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   @opts     in      list      List of name/value pairs
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    hash table (not reference!)
#                   Failure:    undef, undef (to avoid -w noise)
#
###############################################################################
sub named_params
{
    my @opts = @_;

    my (%opts, $name, $value);

    if (scalar(@opts) & 1)
    {
        # Odd one out
        pop(@opts);
        warn "Odd number of parameters passed, ";
    }

    while (@opts)
    {
        $name  = lc shift(@opts);
        $value = shift(@opts);
        $name =~ s/^-//o;
        $opts{$name} = $value;
    }

    %opts;
}

###############################################################################
#
#   Sub Name:       variable_substitution
#
#   Description:    Perform a full-depth variable substition on the contents
#                   of %{$href}. Loop through the keys no more than (n-1)
#                   times, stopping after the first iteration that performs
#                   no substitutions.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $href     in/out  Hash ref  Reference to hash of keys and
#                                                 values. All substitution is
#                                                 within this family tree.
#
#                                                 You aren't the first to make
#                                                 that joke.
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        1
#
###############################################################################
sub variable_substitution
{
    my $href = shift;

    my ($num, $subs_made, $name, $value, $i, $key, @keys, @vars);

    @keys = sort keys %$href;
    $num = scalar @keys;

    for ($i = 0; $i < $num; $i++)
    {
        $subs_made = 0;
        for $key (@keys)
        {
            @vars = ($href->{$key} =~ /\$([A-Z_-]+)/go);
            next unless (@vars);
            for $name (@vars)
            {
                # Don't substitute unless the target is fully-expanded
                next if ($href->{$name} =~ /\$[A-Z_-]+/o);
                $subs_made += $href->{$key} =~ s/\$$name/$href->{$name}/g;
            }
        }
        last if (! $subs_made);
    }

    1;
}

=head1 NAME

IMS::ReleaseMgr::Utils - A collection of utility routines for rlsmgr scripts

=head1 SYNOPSIS

    use IMS::ReleaseMgr::Utils ':all';

    write_log_line($filename, $text);

=head1 DESCRIPTION

Several functional blocks of the different release manager scripts were
identified as essentially identical. To this end, they have been gathered
under the heading of "utilities" and kept here.

=head1 SUBROUTINES

The following routines are made available for explicit import. None are
imported by default, so users of this package need to be specific in terms of
what gets pulled in. There are three tag sets, one for signal-handling
routines, one for database access and the third for accessing configuration
via physical files. The tag "B<:all>" can be used to import all routines.

=over

=item write_log_line($file, $line)

Writes the specified C<$line> (more than one may be passed in a single call)
to the file specified in C<$file>. Performs locking and unlocking, as well as
proper buffer-seeking so as to allow different processes to utilize the same
log file without danger of collision.

=back

The following two routines may be brought in with the tag "B<:signals>":

=over

=item SIG_inc_trace

When assigned as a signal-handler, this routine can be used to automate the
increment of trace levels. It expects a scalar C<$trace> to exist in the
C<MAIN::> namespace. That scalar is then incremented. The application is still
responsible for associating the value of C<$trace> with error logging and/or
tracing.

=item SIG_dec_trace

This is a complement to the above routine. When triggered, it decrements the
global scalar C<$trace>.

=back

The following routines may be brought in with the tag "B<:DBI>":

=over

=item DBI_mirror_specification(-mirror => $mirror)

Contacts the Oracle DBMS that stores the mirror-pool data and fetches the
full specification for the requested mirror name C<$mirror>. The return value
is a hash reference, or the special value C<undef> if there was an error.

=item DBI_mirror_host_list(-mirror => $mirror)

Similar to the previous routine, this call contacts the Oracle DBMS and
retrieves the list of all host names that make up the pool for the specified
pool C<$mirror>. In the case of systems where there is only one host, the list
is generally a single-item list containing the name of the one host. The
return value is a list reference, or C<undef> in case of error. Any of the
hosts in the list that use a port other than the default HTTP port of 80,
then that is appended to the hostname with a separating colon ("C<:>").

=item DBI_all_mirrors

Fetches all mirror specifications from the database and returns them in a
hash reference whose keys are the mirror group names, and whose values are
themselves hash references to the specification for the corresponding group.
Returns C<undef> on error.

=item DBI_all_hostlists

As above, fetches all the hostlists for all mirror groups, returning them in
a hash table keyed by mirror name. Each table value is a list reference
similar to what is returned by B<DBI_mirror_host_list>

=item DBI_match_mirror_to_host(-mirror => $mirror, -host => $host)

In most cases, a physical hostname is not the same as the name the webserver
considers itself to be. This routine matches the I<physical> hostname
C<$host> to the correct I<virtual> hostname in the pool for the mirror group
C<$mirror>. As an example (as of 10 July, 1999), for the mirror group
B<www.buy.hp.com> and physical host B<hpcc950.external.hp.com>, the return
value would be C<www2.buy.hp.com>.

=item DBI_error

Returns the error string from the DBI interface that occurred with the most
recent operation. Each of the other routines in this group sets and clears
this value, so a null string is returned if the most recent operation was
in fact successful.

=back

The following routines may be brought in with the tag "B<:file>". Each is a
file-based counterpart to one of the DBI routines above, except for the
fact that file-based configuration does not have access to the full database
of mirror information, as is available via DBI. Thus, there are no equivalents
to the "all mirrors" or "all hostlists" calls:

=over

=item file_mirror_specification(-file => $file)

Read the specification data from the requested file. The value of C<$file>
should be an absolute path for safety sake, though this is not a strict
requirement. Other lines may be in the file; only those lines that look to be
of the form, "NAME=VALUE" are actually parsed. This allows for configuration
files to include Bourne shell code and double as launch files. See examples
in the C</opt/ims/ahp-bin> directories of hosts B<hpcc925.external.hp.com>
or B<hpcc950.external.hp.com> for how this is currently used in production.
Returns a hash reference just like the DBI counterpart.
The return value is C<undef> on error.

=item file_mirror_host_list(-file => $file)

Read the list of hosts that comprise a mirror pool. Returned as a list
reference as the DBI counterpart does. Unlike the specification file, only
comments, blank lines and data lines may be in this file. A data line has
either a single hostname (such as B<www2.buy.hp.com>) or a hostname with
the physical host name of the machine in question as a second item on the
line, separated by whitespace:
"B<www2.buy.hp.com> <some space> B<hpcc950.external.hp.com>". The second
value is used by the next API hook. This routine only returns the aliases.
The return value is C<undef> on error.

=item file_match_mirror_to_host(-file => $file, -host => $physical_host)

Using the file specified, try to determine which of a set of aliases that
comprise a mirror pool match to the current physical host. This is for
cases when it is necessary to find place within the mirror list of the
running host. If C<$file> has no physical host data, or insufficient, then a
null return is the result. Otherwise, the relevant alias is returned.

=item file_error([ $text ])

All of the B<file_*> routines set their error text via this routine, and
programs using the API can retrieve it using this call. All routines clear
this at the start, so that a stale message is not carried over. Any parameter
present is taken to be a new value for the error message. General external
use should not need to set any errors.

=back

The remaining routines represent a miscellany of assorted functionality
used by both client and server ends of the release process:

=over

=item fork_as_daemon($dont_die)

Causes the running process to background itself, using a strict model as
defined in the W. Richard Stevens book, "Advanced UNIX Programming". In
brief: the process forks (parent exits), sets its own process group, detaches
from the TTY, sets the TTY-related signals to be ignored, and forks again.
It is the grandchild that eventually returns from this call.

If there is an error, the default course of action is to die, reporting the
error in the process. If the routine is passed a single non-null parameter,
the routine will instead return the error message as a string, and not die.
The normal return code (for a successful detachment) is a null string.

=item send_mail($to, $subject, $body)

Sends an e-mail message to all addresses in C<$to> (a comma-separated list).
The parameter C<$subject> is used for the message subject header. The text
is presumed to be in C<$body>. The C<$body> parameter may be a scalar or a
list reference (to allow more than one line of text). No extra formatting
is done to C<$body> before sending.

=item eval_make_target($target, [ $dir_root, $host, @extra_args ])

This routine is used to execute the UNIX B<make> command. The caller is
assumed to be in the directory that contains the B<Makefile>. The value of
C<$target> is given to B<make> as a command-line parameter. If C<$dir_root>
is passed and is non-null, it is used as a base directory for passing the
following variables as command-line arguments to B<make>:

    TARGETHOST=$host
    WWWDOC=$dir_root/htdocs
    WWWBIN=$dir_root/bin
    WWWCGI=$dir_root/cgi-bin
    WWWFCGI=$dir_root/fcgi-bin
    WWWJAVA=$dir_root/applets
    WWWLOCAL=$dir_root/local

Anything passed in C<@extra_args> is added to the end of the B<make>
command-line. If the developer wishes to pass something in C<@extra_args>
without using C<$dir_root>, then the second parameter must be either a
null string (C<"">) or an explicit C<undef>:

    eval_make_target($target, undef, undef, @extra_args);

=item variable_substitution($hashref)

This was intended to be an internal support routine, but after popping up
in several other places, it is now exported. It takes the hash reference
passed in and scans it for nested references in the values part, to keys
of the hash itself. That is, if there is a key called C<SERVER_ROOT>, all
values that contain the sequence "C<$SERVER_ROOT>" will have that substituted
with the value of C<$hashref->{SERVER_ROOT}>.

=head1 AUTHOR

Randy J. Ray <randyr@nafohq.hp.com>

=head1 SEE ALSO

L<IMS::ReleaseMgr>, perl(1).

=cut
