# Additional methods for DBI.

package UR::DBI;

=pod

=head1 NAME

UR::DBI - methods for interacting with a database.

=head1 SYNOPSIS

    ##- use UR::DBI;
    UR::DBI->monitor_sql(1);
    my $dbh = UR::DBI->connect(...);

=head1 DESCRIPTION

This module subclasses DBI, and provides a few extra methods useful when using a database.

=head1 METHODS

=over 4

=cut

# set up package
require 5.006_000;
use warnings;
use strict;
our $VERSION = "0.47"; # UR $VERSION;

# set up module
use base qw(Exporter DBI);
our (@EXPORT, @EXPORT_OK);
@EXPORT = qw();
@EXPORT_OK = qw();

use IO::Handle;
use IO::File;
use Time::HiRes;
# do not use UR::ModuleBase as base class because it does not play nice with DBI

#
# UR::DBI control flags
#

# Build a few class methods to manipulate the environment variables
# that control SQL monitoring

my %sub_env_map = ( monitor_sql => 'UR_DBI_MONITOR_SQL',
                    monitor_dml => 'UR_DBI_MONITOR_DML',
                    explain_sql_if => 'UR_DBI_EXPLAIN_SQL_IF',
                    explain_sql_slow => 'UR_DBI_EXPLAIN_SQL_SLOW',
                    explain_sql_match => 'UR_DBI_EXPLAIN_SQL_MATCH',
                    explain_sql_callstack => 'UR_DBI_EXPLAIN_SQL_CALLSTACK',
                    no_commit => 'UR_DBI_NO_COMMIT',
                    monitor_every_fetch => 'UR_DBI_MONITOR_EVERY_FETCH',
                    dump_stack_on_connect => 'UR_DBI_DUMP_STACK_ON_CONNECT',
                  );

our ($monitor_sql,$monitor_dml,$no_commit,$monitor_every_fetch,$dump_stack_on_connect,
    $explain_sql_slow,$explain_sql_if,$explain_sql_match,$explain_sql_callstack);

while ( my($subname, $envname) = each ( %sub_env_map ) ) {
    no strict 'refs';
    # There's a scalar of the same name as the sub to hold the value, hook them together
    *{$subname} = \$ENV{$envname};
    my $subref = sub {
                      if (@_ > 1) {
                          $$subname = $_[1];
                      }
                      return $$subname;
                  };
    if ($subname =~ /explain/) {
        eval "\$$subname = '' if not defined \$$subname";
    }
    else {
        eval "\$$subname = 0 if not defined \$$subname";
    }
    die $@ if $@;
    *$subname = $subref;
}

# by default, monitored SQL goes to STDOUT
# FIXME change this 'our' back to a 'my' after we're transisitioned off of the old App API
our $sql_fh = IO::Handle->new;
$sql_fh->fdopen(fileno(STDERR), 'w');
$sql_fh->autoflush(1);
sub sql_fh
{
    $sql_fh = $_[1] if @_ > 1;
    return $sql_fh;
}

#
# Logging methods
#

our $log_file;
sub log_file {
    $log_file = pop if @_ > 1;
    return $log_file;
}

our $log_fh;
my $create_time=0;
sub start_logging {
    return 1 if(defined($log_fh));
    return 0 if(-e "$log_file");
    $log_fh = new IO::File("> ${log_file}");
    unless(defined($log_fh)) {
	   warn "Logging File $log_file Could not be created\n";
	   return 0;
    }
    $create_time=Time::HiRes::time();
    return 1;
}

sub stop_logging {
    return 1 unless(defined($log_fh));
    $log_fh->close;
    undef $log_fh;
}

sub log_sql {
    return 1 unless(defined($log_fh));
    my $sql=pop;
    my $no_timestamp=pop;
    print $log_fh '=' x 10, "\n" unless($no_timestamp);
    print $log_fh Time::HiRes::time()-$create_time, "\n" unless($no_timestamp);
    print $log_fh $sql;
}

#
# Standard DBI overrides
# 

sub connect
{
    my $self = shift;
    my @params = @_;

    if ($monitor_sql or $dump_stack_on_connect) {
        my $time = time;
        my $time_string = join(' ', $time, '[' . localtime($time) . ']');
        $sql_fh->print("DB CONNECT AT: $time_string");    
    }
    if ($dump_stack_on_connect) {
        $sql_fh->print(Carp::longmess());
    }
    
    $params[2] = 'xxx';

    # Param 3 is usually a hashref of connection modifiers
    if (ref($params[3]) and ref($params[3]) =~ m/HASH/) {
        my $string = join(', ',
                          map { $_ . ' => ' . $params[3]->{$_} }
                              keys(%{$params[3]})
                         );
        $params[3] = "{ $string }";
    }
        
    my $params_stringified = join(",", map { defined($_) ? "'$_'" : 'undef' } @params);  
    UR::DBI::before_execute("connecting with params: ($params_stringified)");
    
    my $rv = $self->SUPER::connect(@_);
    UR::DBI::after_execute();
    return $rv;
}

#
# UR::Object hooks
#

sub commit_all_app_db_objects {
    my $this_class = shift;
    my $handle = shift;
        
    my $data_source;
    if ($handle->isa("UR::DBI::db")) {
        $data_source = UR::DataSource::RDBMS->get_for_dbh($handle);
    }
    elsif ($handle->isa("UR::DBI::st")) {
        $data_source = UR::DataSource::RDBMS->get_for_dbh($handle->{Database});
    }
    else {
        Carp::confess("No handle passed to method!?")
    }
    
    unless ($data_source) {
        return;
    }

    return $data_source->_set_all_objects_saved_committed();
}

sub rollback_all_app_db_objects {
    my $this_class = shift;
    my $handle = shift;
    
    my $data_source;
    if ($handle->isa("UR::DBI::db")) {
        $data_source = UR::DataSource::RDBMS->get_for_dbh($handle);
    }
    elsif ($handle->isa("UR::DBI::st")) {
        $data_source = UR::DataSource::RDBMS->get_for_dbh($handle->{Database});
    }
    else {
        Carp::confess("No handle passed to method!?")
    }
    
    unless ($data_source) {
        Carp::confess("No data source found for database handle! $handle")
    }
    
    return $data_source->_set_all_objects_saved_rolled_back();         
}

my @disable_dump_and_explain;
sub _disable_dump_explain 
{
    push @disable_dump_and_explain,
        [$monitor_sql,$explain_sql_slow,$explain_sql_match];
    $monitor_sql = 0;
    $explain_sql_slow = '';
    $explain_sql_match = '';
}

sub _restore_dump_explain 
{
    if (@disable_dump_and_explain) {
        my $vars = pop @disable_dump_and_explain;
        ($monitor_sql,$explain_sql_slow,$explain_sql_match) = @$vars;
    }
    else {
        Carp::confess("No state saved for disabled dump/explain");
    }
}

# The before_execute/after_execute subroutine pair
# are callbacks called by execute() and by other 
# methods which implicitly execute a statement.

# They use these three varaibles to track state,
# presuming that the callback pair cannot be nested. <!!

our ($start_time, $elapsed_time);

# This gets around a bug which prevents variables 
# which are strings internally utf8 encoded from working with DBI
# as execution parameters.
if ($^O eq "MSWin32" || $^O eq 'cygwin') {
    *normalize_parameter = sub { $_[0] = substr($_[0],0) };
}
elsif ($^V le v5.8.0) {
    # perl 5.6.1 utf8 module does not have a downgrade function
    *normalize_parameter = sub { $_[0] = substr($_[0],0) };
}
else {
    require utf8;
    *normalize_parameter = \&utf8::downgrade;
}

sub before_execute
{
    #my ($dbh,$sql,@params) = @_;
    # $dbh is optional
    
    my $dbh;
    $dbh = shift if ref($_[0]);
    
    my $sql = shift;

    # Odd errors occur sometimes with values which have not gone through
    # updgrade, downgrade or $_ = substr($_,0).  The query fails w/o error.
    # This has some connection to a language/encoding problem, and has so
    # far only been seen with Tk, Gtk2, and XML parser derived data.
    # Note: when this error occurs it happens with a seeminly normal Perl variable.
    for (@_) {
        normalize_parameter($_);
    }
    
    if ($dbh and length($explain_sql_match)) {
        for my $val ($sql,@_) {
            if ($val =~ /$explain_sql_match/gi) {                
                $sql_fh->print("\nEXPLAIN QUERY MATCHING /$explain_sql_match/gi"
                    . ($val ne $sql ? " (on value '$val') " : "")                    
                );
                if ($monitor_sql) {
                    $sql_fh->print("\n");
                }
                else {
                    _print_sql_and_params($sql,@_);
                }                
                if ($explain_sql_callstack) {
                    $sql_fh->print(Carp::longmess("callstack begins"),"\n");
                }
                if ($UR::DBI::explained_queries{$sql}) {
                    $sql_fh->print("(query explained above)\n");
                }
                else {
                    UR::DBI::_print_query_plan($sql,$dbh);
                    $UR::DBI::explained_queries{$sql} = 1;
                }
                last;
            }
        }
    }
    
    my $start_time = _set_start_time();
    if ($monitor_sql){
	_print_sql_and_params($sql,@_);
        if ($monitor_sql > 1) {
            $sql_fh->print(Carp::longmess("callstack begins"),"\n");
        }
	_print_monitor_label("EXECUTE");        
    }
    elsif($monitor_dml && $sql !~ /^\s*select/i){
	_print_sql_and_params($sql,@_);
	_print_monitor_label("EXECUTE");        
	$monitor_dml=2;
    }
    no warnings;            
    
    UR::DBI::log_sql_for_summary($sql);    # $ENV{UR_DBI_SUMMARIZE_SQL}

    my $log_sql_str = _generate_sql_and_params_log_entry($sql, @_);
    UR::DBI::log_sql($log_sql_str);
    return $start_time;
}

sub after_execute
{    
    #my ($sql,@params) = @_;
    my $elapsed_time = _set_elapsed_time();
    if ($monitor_sql){
        _print_elapsed_time();
    }
    elsif($monitor_dml == 2){
        _print_elapsed_time();
	$monitor_dml = 1;
    }
    UR::DBI::log_sql(1, ($elapsed_time)."\n");
    return $elapsed_time;
}

# The before_fetch/after_fetch pair are callback
# called by fetch() and by other methods which implicitly
# fetch data w/o explicitly calling fetch().

our $_fetching = 0;

sub before_fetch {
    my $sth = shift;
    return if @disable_dump_and_explain;
    if ($_fetching) {        
        Carp::cluck("before_fetch called after another before_fetch w/o intervening after_fetch!");
    }
    $_fetching = 1;
    my $fetch_timing_arrayref = $sth->fetch_timing_arrayref;
    if ($monitor_sql) {
        if ($fetch_timing_arrayref and @$fetch_timing_arrayref == 0) {
            UR::DBI::_print_monitor_label('FIRST FETCH');
        }
        elsif ($monitor_every_fetch) {
            UR::DBI::_print_monitor_label('NTH FETCH');
        }
    }
    return UR::DBI::_set_start_time();
}

sub after_fetch {
    my $sth = shift;
    return if @disable_dump_and_explain;
    $_fetching = 0;
    my $fetch_timing_arrayref = $sth->fetch_timing_arrayref;
    my $time;
    push @$fetch_timing_arrayref, UR::DBI::_set_elapsed_time();
    if ($monitor_sql) {
        if ($monitor_every_fetch || @$fetch_timing_arrayref == 1) {
            $time = UR::DBI::_print_elapsed_time();
        }
    }
    if (@$fetch_timing_arrayref == 1) {
        my $time = $sth->execute_time + $fetch_timing_arrayref->[0];
        UR::DBI::_check_query_timing($sth->{Statement},$time,$sth->{Database},$sth->last_params);
    }
    return $time;
}

sub after_all_fetches_with_sth {
    my $sth = shift;
    
    my $fetch_timing_arrayref = $sth->fetch_timing_arrayref;
    
    # This arrayref is set when it goes through the subclass' execute(),
    # and is removed when we finish all fetches().  
    
    # Since a variety of things attempt to call this from the various "final" 
    # positions of an $sth we delete this so the final callback operates only once.
    # Also, internally generated $sths which do not get executed() normally
    # will be skipped by this check.
    
    if (!$fetch_timing_arrayref) {
        # internal sth which did not go through prepare()
        #print $sql_fh "SKIP STH\n";
        return;
    }
    $sth->fetch_timing_arrayref(undef);
    
    my $print_fetch_summary;
    if ($monitor_sql and $sth->{Statement} =~ /select/i) {
        $print_fetch_summary = 1;
        UR::DBI::_print_monitor_label('TOTAL EXECUTE-FETCH');
    }
    
    my $time = $sth->execute_time;    
    
    if (@$fetch_timing_arrayref) {
        for my $fetch_time (@$fetch_timing_arrayref ) {
            $time += $fetch_time;
        }
        if ($print_fetch_summary) {
            UR::DBI::_print_monitor_time($time);    
        }
        # since there WERE fetches, we already checked query timing
    }
    else {
        if ($print_fetch_summary) {
            UR::DBI::_print_monitor_time($time);
        }
        # since there were NOT fetches, we check query timing now
        UR::DBI::_check_query_timing($sth->{Statement},$time,$sth->{Database},$sth->last_params);
    }
    return $time;
}

sub after_all_fetches_no_sth {
    my ($sql, $time, $dbh, @params) = @_;
    $time = _set_elapsed_time() unless defined $time;
    if ($monitor_sql and $sql =~ /select/i) {
        UR::DBI::_print_monitor_label('TOTAL EXECUTE-FETCH');
        UR::DBI::_print_monitor_time($time);
    }
    # no sth = no fetches = no query timing check done yet...
    UR::DBI::_check_query_timing($sql,$time,$dbh,@params);
    return $time;
}


my $__SQL_SUMMARY__ = {};
sub log_sql_for_summary {
    my ($sql) = @_;
    $__SQL_SUMMARY__->{$sql}++; 
}

sub print_sql_summary {
    for my $sql (sort {$__SQL_SUMMARY__->{$b} <=> $__SQL_SUMMARY__->{$a}} keys %$__SQL_SUMMARY__) {
        print STDERR join('',"********************\n", $__SQL_SUMMARY__->{$sql}, " instances of query: $sql\n");
    }
}

# These methods are called by the above.

sub _generate_sql_and_params_log_entry 
{

    my $sql = shift;

    no warnings;
    my $sql_log_str =  "\nSQL: $sql\n"; 
    if (@_) {
        $sql_log_str .= "PARAMS: ";
        $sql_log_str .= join(", ",
                              map { defined($_) ? "'$_'" : "NULL" }
                              map { scalar(grep { $_ } map { 128 & ord $_ } split(//, substr($_, 0, 64))) ? '<BLOBISH>' : $_  }
                              @_ )
                        . "\n";
    }

    return $sql_log_str;
}

sub _print_sql_and_params 
{
    my $sql = shift;
    my $entry = _generate_sql_and_params_log_entry($sql, @_);
    no warnings;
    print $sql_fh $entry;
}

sub _set_start_time 
{
    $start_time=&Time::HiRes::time();
}

our $_print_monitor_label_or_time_is_ready_for = "label";
sub _print_monitor_label 
{
    #Carp::cluck() unless $_print_monitor_label_or_time_is_ready_for eq "label";    
    my $time_label = shift;
    $sql_fh->print("$time_label TIME: ");    
    $_print_monitor_label_or_time_is_ready_for = "time";
}

sub _print_monitor_time 
{
    #Carp::cluck() unless $_print_monitor_label_or_time_is_ready_for eq "time";
    $sql_fh->printf( "%.4f s\n", shift);
    $_print_monitor_label_or_time_is_ready_for = "label";
}

sub _set_elapsed_time
{
    $elapsed_time = &Time::HiRes::time()-$start_time;
}

sub _print_elapsed_time 
{
    _print_monitor_time($elapsed_time);
}

our $_print_check_for_slow_query = 0;
sub _check_query_timing 
{
    my ($sql,$time,$dbh,@params) = @_;
    return if @disable_dump_and_explain;
    return unless $sql =~ /select/i;
    print $sql_fh "CHECK FOR SLOW QUERY:\n" if $_print_check_for_slow_query; # used only by a test case
    if (length($explain_sql_slow) and $time >= $explain_sql_slow) {        
        $sql_fh->print("EXPLAIN QUERY SLOWER THAN $explain_sql_slow seconds ($time):");
        if ($monitor_sql
	|| ($monitor_dml && $sql !~ /^\s*select/i)) {        
            $sql_fh->print("\n");
        }
        else {
            _print_sql_and_params($sql,@params);
        }
        if ($explain_sql_callstack) {
            $sql_fh->print(Carp::longmess("callstack begins"),"\n");
        }
        if ($UR::DBI::explained_queries{$sql}) {
            $sql_fh->print("(query explained above)\n");
        } 
        else {
            $UR::DBI::explained_queries{$sql} = 1;
            UR::DBI::_print_query_plan($sql,$dbh);
        }
    }
}

sub _print_query_plan
{    
    my ($sql,$dbh,%params) = @_;
    UR::DBI::_disable_dump_explain();
    $dbh->do($UR::DBI::EXPLAIN_PLAN_CLEANUP_DML);
    
    # placeholders in explain plan queries on windows
    # results in Oracle throwing an ORA-00600 error, 
    # likely due to interaction with DBI.  Replace with
    # literals.

    if ($^O eq "MSWin32" || $^O eq 'cygwin') {
	$sql =~ s/\?/'1'/g;
    }
    
    $dbh->do($UR::DBI::EXPLAIN_PLAN_DML . "\n" . $sql)
        or die "Failed to produce query plan! " . $dbh->errstr;        
    UR::DBI::Report->generate(
        sql => [$UR::DBI::EXPLAIN_PLAN_SQL],
        dbh => $dbh,
        count => 0,
        outfh => $sql_fh,
        %params,
        "explain-sql" => 0,
        "echo" => 0,
    );
    $sql_fh->print("\n");
    $dbh->do($UR::DBI::EXPLAIN_PLAN_CLEANUP_DML);                
    UR::DBI::_restore_dump_explain();
    
    return 1;
}


############
#
# Database handle subclass
#
############


package UR::DBI::db;

use strict;
use warnings;

our @ISA = qw(DBI::db);

sub commit
{
    my $self = shift;        

#    unless ($no_commit) {
#        print "\n\n\n************* FORCIBLY SETTING NO-COMMIT FOR TESTING.  This would have committeed!!!! **********\n\n\n";
#        $no_commit = 1;
#    }
    
    if ($no_commit) 
    {
        # Respect the ->no_commit(1) setting.
        UR::DBI::before_execute("commit (ignored)");        
        UR::DBI::after_execute;        
        return 1;
    }
    else 
    {
        if(UR::DataSource->use_dummy_autogenerated_ids) {
            # Not cool...you shouldn't have dummy-ids on and no-commit off
            # Don't commit, and notify the authorities
            UR::DBI::before_execute("commit (ignored)");
            $UR::Context::current->error_message('Tried to commit with dummy-ids on and no-commit off');
            UR::DBI::after_execute;
            #$UR::Context::current->send_email(
            #    To => 'example@example.edu',
            #    Subject => 'attempt to commit with dummy-ids on and no-commit off '.
            #                "by $ENV{USER} on $ENV{HOST} running ".
            #                UR::Context::Process->original_program_path." as pid $$",
            #    Message => "Call stack:\n" .Carp::longmess()
            #);
        } else {
            # Commit and update the associated objects.
            UR::DBI::before_execute("commit");        
            my $rv = $self->SUPER::commit(@_);
            UR::DBI::after_execute;        
            if ($rv) {
                UR::DBI->commit_all_app_db_objects($self)
            }
            return $rv;
        }
    }
}

sub commit_without_object_update 
{ 
    UR::DBI::before_execute("commit (no object updates)");
    my $rv = shift->SUPER::commit(@_); 
    UR::DBI::after_execute();
    return $rv;
}

sub rollback
{
    my $self = shift;
    UR::DBI::before_execute("rollback");
    my $rv = $self->SUPER::rollback(@_);
    UR::DBI::after_execute();
    if ($rv) {
        UR::DBI->rollback_all_app_db_objects($self)
    }
    return $rv;
}

sub rollback_without_object_update 
{ 
    UR::DBI::before_execute("rollback (w/o object updates)");
    my $rv = shift->SUPER::commit(@_);
    UR::DBI::after_execute();
    return $rv;
}

sub disconnect
{
    my $self = shift;
    # Rollback if AutoCommit is 0.  Oracle commits by default on disconnect.
    # Rolling back when AutoCommit is on will generate a DBI warning.
    if ($self->{'AutoCommit'} == 0) {
        $self->rollback;    
    }
    
    # Msg and disconnect.
    UR::DBI::before_execute("disconnecting");
    my $rv = $self->SUPER::disconnect(@_);
    UR::DBI::after_execute();
    
    # There doesn't seem to be anything less which
    # sets this, but legacy tools did
    if (
        (defined $UR::DBI::common_dbh)
        and
        ($self eq $UR::DBI::common_dbh)
       )
    {
        UR::DBI::before_execute("common dbh removed");
        $UR::DBI::common_dbh = undef;
        UR::DBI::after_execute("common dbh removed");
    }
    return $rv;
}

sub prepare
{
    my $self = shift;
    my $sql = $_[0];        
    my $sth;
    
    #print $sql_fh "PREPARE: $sql\n";
    
    if ($sql =~ /^\s*(commit|rollback)\s*$/i)
    {
        unless ($sql =~ /^(commit|rollback)$/i) {
            Carp::confess("Executing a statement with an embedded commit/rollback?\n$sql\n");
        }
        
        if ($sth = $self->SUPER::prepare(@_))
        {            
            if ($1 =~ /commit/i)
            {
                $UR::DBI::prepared_commit{$sth} = 1;
            }
            elsif ($1 =~  /rollback/)
            {
                $UR::DBI::prepared_rollback{$sth} = 1;
            }
        }
    }    
    else
    {
        $sth = $self->SUPER::prepare(@_) or return;
    }
        
    return $sth;
}

# For newer versions of DBI, some of the $dbh->select* methods do not
# call execute internally, so SQL dumping and logging will not occur.
# These are listed below, and the bad ones are overridden.

# selectall_hashref ok
# selectcol_arrayref ok
# selectrow_hashref ok 

# selectall_arrayref bad
# selectrow_arrayref bad
# selectrow_array bad

sub selectall_arrayref
{
    my $self = shift;
    my @p = ($_[0],@_[2..$#_]);    
    UR::DBI::before_execute($self,@p);
    my $ar = $self->SUPER::selectall_arrayref(@_);
    my $time = UR::DBI::after_execute($self,@p);
    UR::DBI::after_all_fetches_no_sth($_[0],$time,$self,@p);
    return $ar;
}


sub selectcol_arrayref
{
    my $self = shift;
    my @p = ($_[0],@_[2..$#_]);    
    UR::DBI::before_execute($self,@p);
    UR::DBI::_disable_dump_explain();
    my $ar = $self->SUPER::selectcol_arrayref(@_);
    UR::DBI::_restore_dump_explain();
    my $time = UR::DBI::after_execute($self,@p);
    UR::DBI::after_all_fetches_no_sth($_[0],$time,$self,@p);
    return $ar;
}


sub selectall_hashref
{
    my $self = shift;
    my @p = ($_[0],@_[3..$#_]);    
    UR::DBI::before_execute($self,@p);
    UR::DBI::_disable_dump_explain();
    my $ar = $self->SUPER::selectall_hashref(@_);
    UR::DBI::_restore_dump_explain();
    my $time = UR::DBI::after_execute($self,@p);
    UR::DBI::after_all_fetches_no_sth($_[0],$time,$self,@p);
    return $ar;
}

sub selectrow_arrayref
{
    my $self = shift;
    my @p = ($_[0],@_[2..$#_]);
    UR::DBI::before_execute($self,@p);
    my $ar = $self->SUPER::selectrow_arrayref(@_);        
    my $time = UR::DBI::after_execute($self,@p);
    UR::DBI::after_all_fetches_no_sth($_[0],$time,$self,@p);
    return $ar;
}

sub selectrow_array
{
    my $self = shift;
    my @p = ($_[0],@_[2..$#_]);
    UR::DBI::before_execute($self,@p);
    my @a = $self->SUPER::selectrow_array(@_);    
    my $time = UR::DBI::after_execute($self,@p);
    UR::DBI::after_all_fetches_no_sth($_[0],$time,$self,@p);    
    return @a if wantarray;
    return $a[0];
}

sub DESTROY
{
    UR::DBI::before_execute("destroying connection");
    shift->SUPER::DESTROY(@_);
    UR::DBI::after_execute("destroying connection");
}

#########
#
# Statement handle subclass
#
#########

package UR::DBI::st;

use strict;
use warnings;

use Time::HiRes;
use Sys::Hostname;
use Devel::GlobalDestruction;

our @ISA = qw(DBI::st);

sub _mk_mutator {
    my ($class, $method) = @_;

    # Make a more specific key based on the package
    # to try not to conflict with anything else.
    # This must start with 'private_'.  See DBI docs on subclassing.
    my $hash_key = join('_', 'private', lc $class, lc $method);
    $hash_key =~ s/::/_/g;

    my $sub = sub {
        return if Devel::GlobalDestruction::in_global_destruction;
        my $sth = shift;
        if (@_) {
            no warnings 'uninitialized';
            $sth->{$hash_key} = shift;
        }
        no warnings;
        return $sth->{$hash_key};
    };

    no strict;
    *{$class . '::' . $method} = $sub;
}

for my $method (qw(execute_time fetch_timing_arrayref last_params_arrayref)) {
    __PACKAGE__->_mk_mutator($method);
}

sub last_params
{
    my $ret = shift->last_params_arrayref;
    unless (defined $ret) {
        $ret = [];
    }
    @{ $ret };
}

sub execute
{
    my $sth = shift;
    
    # (re)-initialize the timing array
    if (my $a = $sth->fetch_timing_arrayref()) {
        # re-executing on a previously used $sth.
        UR::DBI::after_all_fetches_with_sth($sth);
    } 
    else {
        # initialize the $sth on first execute.
        $sth->fetch_timing_arrayref([]);
    }
    
    $sth->last_params_arrayref([@_]);
    
    UR::DBI::before_execute($sth->{Database},$sth->{Statement},@_);
    my $rv = $sth->SUPER::execute(@_);
    UR::DBI::after_execute($sth->{Database},$sth->{Statement},@_);
    
    # record the elapsed time for execution.
    $sth->execute_time($UR::DBI::elapsed_time);
    
    if ($rv)
    {
        if (my $prev = $UR::DBI::prepared_commit{$sth})
        {
            UR::DBI->commit_all_app_db_objects($sth);
        }
        if (my $prev = $UR::DBI::prepared_rollback{$sth})
        {
            UR::DBI->rollback_all_app_db_objects($sth);
        }

    }    
    return $rv;
}


sub fetchrow_array
{
    my $sth = shift;
    UR::DBI::before_fetch($sth,@_);
    UR::DBI::_disable_dump_explain();
    my @a = $sth->SUPER::fetchrow_array(@_);    
    UR::DBI::_restore_dump_explain();
    UR::DBI::after_fetch($sth,@_);
    return @a if wantarray;
    return $a[0];
}

sub fetchrow_arrayref
{
    my $sth = shift;
    UR::DBI::before_fetch($sth,@_);
    UR::DBI::_disable_dump_explain();
    my $ar = $sth->SUPER::fetchrow_arrayref(@_);        
    UR::DBI::_restore_dump_explain();
    UR::DBI::after_fetch($sth,@_);
    return $ar;
}


sub fetchall_arrayref
{
    my $sth = shift;
    UR::DBI::before_fetch($sth,@_);
    UR::DBI::_disable_dump_explain();
    my $ar = $sth->SUPER::fetchall_arrayref(@_);    
    UR::DBI::_restore_dump_explain();
    UR::DBI::after_fetch($sth,@_);
    UR::DBI::after_all_fetches_with_sth($sth,@_);
    return $ar;
}

sub fetchall_hashref
{
    my $sth = shift;
    my @p = @_[1,$#_];
    UR::DBI::before_fetch($sth,@p);
    UR::DBI::_disable_dump_explain();
    my $ar = $sth->SUPER::fetchall_hashref(@_);        
    UR::DBI::_restore_dump_explain();
    UR::DBI::after_fetch($sth,@p);
    UR::DBI::after_all_fetches_with_sth($sth,@_[1,$#_]);
    return $ar;
}

sub fetchrow_hashref
{
    my $sth = shift;
    UR::DBI::before_fetch($sth,@_);
    UR::DBI::_disable_dump_explain();
    my $ar = $sth->SUPER::fetchrow_hashref(@_);        
    UR::DBI::_restore_dump_explain();
    UR::DBI::after_fetch($sth,@_);
    return $ar;
}


sub fetch {
    my $sth = shift;
    UR::DBI::before_fetch($sth,@_);
    my $rv = $sth->SUPER::fetch(@_);
    UR::DBI::after_fetch($sth,@_);
    return $rv;
}

sub finish {
    my $sth = shift;    
    UR::DBI::after_all_fetches_with_sth($sth);    
    return $sth->SUPER::finish(@_);
}

sub DESTROY
{
    delete $UR::DBI::prepared_commit{$_[0]};
    delete $UR::DBI::prepared_rollback{$_[0]};
    #print $sql_fh "DESTROY1\n";
    UR::DBI::after_all_fetches_with_sth(@_); # does nothing if called previously by finish()
    #print $sql_fh "DESTROY2\n";
    #Carp::cluck();
    shift->SUPER::DESTROY(@_);
}

$UR::DBI::STATEMENT_ID = $$ . '@' . hostname();


$UR::DBI::EXPLAIN_PLAN_DML = "explain plan set statement_id = '$UR::DBI::STATEMENT_ID' into plan_table for ";


$UR::DBI::EXPLAIN_PLAN_SQL = qq/
select
    LPAD(' ',p.LVL-1) || OPERATION OPERATION,
    OPTIONS,
    --(case when p.OBJECT_OWNER is null then '' else p.OBJECT_OWNER || '.' end)
    --    ||
        p.OBJECT_NAME
        ||
        (case when p.OBJECT_TYPE is null then '' else ' (' || p.OBJECT_TYPE || ')' end)
        "OBJECT",
    (case
        when i.table_name is not null then i.table_name
            || '('
            || index_column_names
            || ')'
        else ''
    end) "OBJECT_IS_ON",
    p.COST,
    p.CARDINALITY CARD,
    p.BYTES,
    p.OPTIMIZER,
    p.CPU_COST CPU,
    p.IO_COST IO,
    p.TEMP_SPACE TEMP,
    i.index_type "index_type",
    i.last_analyzed "index_analyzed"
from
(
    SELECT plan_table.*, level lvl
    FROM PLAN_TABLE
    CONNECT BY prior id = parent_id AND prior statement_id = statement_id
    START WITH id = 0
    AND statement_id = '$UR::DBI::STATEMENT_ID'
) p
full join dual on dummy = dummy
left join all_indexes i
    on i.index_name = p.object_name
    and i.owner = p.object_owner
left join
    (
        select
            index_owner,
            index_name,
            LTRIM(MAX(SYS_CONNECT_BY_PATH(ic.column_name,',')) KEEP (DENSE_RANK LAST ORDER BY ic.column_position),',') index_column_names
        from (
            select ic.index_owner, ic.index_name, ic.column_name, ic.column_position
            from all_ind_columns ic
        ) ic
        group by ic.index_owner, ic.index_name
        connect by
                index_owner = prior index_owner
                and index_name = prior index_name
                and column_position = PRIOR column_position + 1
        start with column_position = 1
    ) index_columns_stringified
    on index_columns_stringified.index_owner = i.owner
    and index_columns_stringified.index_name = i.index_name
where p.object_name is not null
ORDER BY p.id
/;

$UR::DBI::EXPLAIN_PLAN_CLEANUP_DML = "delete from plan_table where statement_id = '$UR::DBI::STATEMENT_ID'";


1;
__END__

=pod

=back

=head1 SEE ALSO

UR(3), UR::DataSource::RDBMS(3), UR::Context(3), UR::Object(3)

=cut

#$Header$
