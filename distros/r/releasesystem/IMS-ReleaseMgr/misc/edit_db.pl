#!/usr/local/bin/perl

###############################################################################
#
#          May be distributed under the terms of the artistic license
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: edit_db.pl,v 1.6 1999/06/12 00:25:30 randyr Exp $
#
#   Description:    Browse and edit mirror database records in a web browser
#
#                   Tread lightly through here. I'm calling upon 5+ years of
#                   Perl stunts and tricks in this application. I'll try my
#                   best to keep it reasonably well-documented, but I can't
#                   guarantee it will be understandable to just anyone.
#
#   Functions:      signal_caught
#                   server_loop
#                   main_page
#                   edit_field
#                   toplevel_add
#                   toplevel_del
#                   toplevel_edit
#                   mew_mirror_setup
#
#   Libraries:      DBI
#                   CGI
#                   HTTP::Daemon
#                   HTTP::Request
#                   HTTP::Response
#
#   Global Consts:  $cmd                    This tool's name
#                   $VERSION                Version number
#                   $revision               Full RCS revision line
#                   $magic                  A random number used in the
#                                             session cookie
#                   $dbh                    A DBI handle
#
#   Environment:    None.
#
###############################################################################
use vars qw($cmd);
($cmd = $0) =~ s|.*/||o;

use 5.004;

BEGIN
{
    $ENV{ORACLE_HOME} = '/opt/oracle/product/7.3.3';
    $ENV{PATH} = "$ENV{ORACLE_HOME}/bin:$ENV{PATH}";
}

use strict;
use vars qw($VERSION $revision $DEBUG $LOGFILE $DAEMON_PROCESS
            $CGI $daemon $dbh $user $password $dBase $fork_pid $magic %SIGNAL);
use subs qw(signal_caught server_loop tables_fill main_page edit_field
            toplevel_add toplevel_del toplevel_edit new_mirror_setup
            execute_SQL);

use Config;
use SelfLoader;
use CGI;
use DBI;
use HTTP::Status;
use HTTP::Daemon;
use IMS::ReleaseMgr::Utils qw(fork_as_daemon write_log_line);

$VERSION = do {my @r=(q$Revision: 1.6 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$revision = q{$Id: edit_db.pl,v 1.6 1999/06/12 00:25:30 randyr Exp $ };
$DEBUG = 0; # For now
$LOGFILE = "/tmp/$cmd.log";

###############################################################################
#
#   Description:    This pseudo-module is a subclassing of CGI that allows
#                   for shortcuts within the shortcuts (such as always passing
#                   '-pragma => no-cache' to header).
#
#                   Think of it as "my CGI class". It also allows me to have
#                   a "footer" routine to output a consistently-styled page
#                   footer before end_html() is called (I could even have just
#                   overloaded end_html, but I prefer to leave the programmer
#                   control over that).
#
#   Functions:      new
#                   header
#                   page_footer
#                   error_message
#
#   Libraries:      CGI
#
#   Global Consts:  $cmd                    This tool's name
#                   $VERSION
#
###############################################################################
package mCGI;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use subs qw(header img error_message);
require CGI;

@ISA = qw(CGI);
@EXPORT = ();
@EXPORT_OK = ();

#
# Simple new() overload:
#
sub new
{
    my $self = shift;

    my $class = ref($self) || $self;

    bless $self->SUPER::new(@_), $class;
}

#
# Even simpler overload for header
#
sub header
{
    my $self = shift;

    $self->SUPER::header(@_, -pragma => 'no-cache');
}

#
# Basic page footer
#
sub page_footer
{
    my $self = shift;

    $self->p($self->hr,
             $self->font({ -size => -1 },
                       $self->table({ -BORDER => 0, -WIDTH => '100%' },
                                    $self->TR($self->td("$::cmd, $::VERSION"),
                                              $self->td({ -ALIGN => 'right' },
                                                        scalar localtime)))));
}

##############################################################################
#
#   Sub Name:       error_message
#
#   Description:    (Adapted from error_splash in upload.pl)
#                   Create a complete HTML page to report the error in the
#                   passed-in text. Don't exit-- let the caller do that.
#                   Don't use carp or CGI::Carp, either. This micro-daemon
#                   doesn't have the same logfile format concerns that others
#                   have.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $self     in      mCGI      Reference to mCGI object
#                   $title    in      scalar    Title/one line err description
#                   @err_text in      list      The text of the error at hand.
#                                                 May be $!, $@, etc., or
#                                                 custom-fed.
#
#   Globals:        $cmd                 This script's name
#                   $revision            This script's RCS/CVS ident string
#                   $LOGFILE             The logfile for the daemon
#                   $DEBUG               Whether to send to logfile or not
#
#   Returns:        Huge chunk o' HTML (in bite-sized pieces)
#
##############################################################################
sub error_message
{
    my $self = shift;
    my ($title, @err_text) = @_;

    write_log_line($::LOGFILE, sprintf("%s [$$] Internal script error: $title",
                                       scalar localtime))
        if $::DEBUG;

    return ($self->header(-pragma => 'no-cache'),
            $self->start_html(-title => $title),
            $self->h1("Error: $title"),
            $self->hr,
            $self->p("The following error occured:"),
            $self->p(@err_text),
            $self->page_footer,
            $self->end_html);
}

#
# Return to the main package space
#

package main;

#
# Initially, we create the DBI handle and connect to the database (with
# user and password supplied in the mCGI object, ideally in a POST method in
# the future). Once we've gotten a clean connection, we spawn the temporary
# HTTP daemon and redirect the browser to it. The mCGI object in the future may
# also contain information to select a database to edit (or maybe color
# preferences, if I feel saucy).
#
# (Which, as of mid-June, I haven't yet)
#

$CGI      = new mCGI;
$dBase    = $CGI->param('database') || '';
$user     = $CGI->param('user')     || '';
$password = $CGI->param('password') || '';

unless ($user and $password)
{
    print $CGI->error_message('Must supply user name and password',
                              q(One or both of the user ID and password were
                                missing. These are necessary for establishing
                                a connection to the data source.));

    exit 0;
}

#
# Good, we have what we need. Open a DBI handle
#
unless (defined ($dbh = DBI->connect("dbi:Oracle:$dBase", $user, $password)))
{
    print $CGI->error_message('Connect to datasource failed',
                              'The DBI interface was unable to connect to ',
                              'the datasource',
                              $CGI->b($CGI->code($dBase)),
                              $CGI->br,
                              'Reason: ', $CGI->code($DBI::errstr));

    exit 0;
}

#
# Well, I suppose we're ready to rock, then...
#
# We'll lose the DBI connect when we fork, anyway...
#
$dbh->disconnect;
my $i = 0;

# We need a name-to-number mapping of the signals
for (split(' ', $Config{sig_name}))
{
    $SIGNAL{$_} = ++$i;
}
unless (defined ($daemon = new HTTP::Daemon))
{
    print $CGI->error_message('HTTP Daemon creation failed',
                              q(HTTP::Daemon::new failed to create a temporary
                                HTTP instance for communication.));

    exit 0;
}

$magic = join('.', $$, (time & 0xffff), int(rand(1000)));
$fork_pid = fork;
if ($fork_pid)
{
    #
    # Parent process-- just redirect and exit. The child will be running a
    # subroutine to properly fork as a daemon, so we aren't worried about
    # handling SIGCHLD or properly reaping the process on exit.
    #
    undef $dbh;
    print $CGI->redirect(-url => $daemon->url . $magic);
    exit 0;
}
elsif (undef $fork_pid)
{
    # Crap-- something buggered in fork()
    print $CGI->error_message('Fork forked up',
                              q(The fork system call failed and I feel really
                                bad about it.));

    exit 0;
}
else
{
    my $err = fork_as_daemon 'dont_die';
    if ($err)
    {
        print $CGI->error_message('Fork forked up',
                                  q(The fork system call failed and I feel
                                    really bad about it.));

        exit 0;
    }

    #
    # Re-establish the database connection that was lost when the parent
    # exited (or would have been, had the parent not explicitly disconnected).
    #
    $dbh = DBI->connect("dbi:Oracle:$dBase", $user, $password);
    server_loop $daemon; # never returns
}

exit 0;  # OK, just in case...

###############################################################################
#
#   Sub Name:       signal_caught
#
#   Description:    Handle a signal. SIGALRM means there has been no activity
#                   for at least 5 minutes. SIGHUP would mean we're being
#                   stopped from an outside source, and SIGINT is the signal
#                   we use to manually end the session.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $sig      in      scalar    Type of signal we received
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Doesn't.
#
###############################################################################
sub signal_caught
{
    my $sig = shift;

    if ($sig eq 'ALRM')
    {
        write_log_line($LOGFILE,
                       sprintf("%s [$$] Daemon exiting on SIG$sig: timeout " .
                               "was reached", scalar localtime))
            if $DEBUG;
    }
    elsif ($sig eq 'INT')
    {
        write_log_line($LOGFILE,
                       sprintf("%s [$$] Daemon exiting on SIG$sig: session " .
                               "ended internally", scalar localtime))
            if $DEBUG;
    }
    elsif ($sig eq 'USR1')
    {
        write_log_line($LOGFILE,
                       sprintf("%s [$$] Daemon exiting on SIG$sig: user " .
                               "ended session", scalar localtime))
            if $DEBUG;
    }
    else
    {
        write_log_line($LOGFILE,
                       sprintf("%s [$$] Daemon exiting on SIG$sig (external " .
                               "source)", scalar localtime))
            if $DEBUG;
    }

    exit 0;
}

###############################################################################
#
#   Sub Name:       server_loop
#
#   Description:    This is the event-loop for the temporary daemon. We set
#                   up SIGALRM to make sure we don't stay alive longer than
#                   5 minutes between transactions, and we deal with the
#                   incoming requests.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $D        in      ref       HTTP::Daemon instance
#
#   Globals:        $dbh           DBI handle object
#
#   Environment:    None.
#
#   Returns:        Doesn't-- exits at end
#
###############################################################################
sub server_loop
{
    my $D = shift;

    my $c;                  # For accepting connections
    my $r;                  # Get the request part of the connection
    my $query;              # For parsing the query content of a request
    my $tables = undef;     # Data from the $dbh
    my (@keys, @parts, $button, $action, $host, $context);

    my %actions = (
                   add  => \&toplevel_add,
                   del  => \&toplevel_del,
                   edit => \&toplevel_edit,
                   quit => \&toplevel_exit,
                  );

    $DAEMON_PROCESS = 1;
    #
    # When we first enter this routine, it's after the fork, as the parent
    # is re-directing the browser to the new daemon.
    #
    write_log_line($LOGFILE,
                   sprintf("%s [$$] Daemon started: %s",
                           scalar localtime, $D->url))
        if $DEBUG;
    for (qw(ALRM HUP INT))
    {
        $SIG{$_} = \&signal_caught;
    }

    while (1)
    {
        #
        # So this is what we do: at the top of this loop, we set an alarm
        # for 5 minutes from now. Since we re-signal this at the top of
        # every iteration, as long as they do *something* every 4-5 minutes,
        # everything is fine.
        #
        alarm 300;
        $c = $D->accept;
        alarm 0; # turn it off for now
        $r = $c->get_request;
        $c->send_basic_header;
        $query = new mCGI $r->content;
        unless ($r->url->epath eq "/$magic")
        {
            $c->send_error(RC_FORBIDDEN,
                           "You do not have the token for this session.");
            close $c;
            redo;
        }
        if (! defined $tables)
        {
            $tables = {};
            tables_fill($c, $query, $tables);
        }
        @keys = $query->param();
        #
        # All the parameters will follow a certain naming convention:
        #
        #   <op>:<args>
        #
        #   add:*           A button that triggers data being added to the DB
        #   del:*           A button that triggers deletion
        #   edit:*          A button that triggers changes to 0+ fields
        #   field:*         A datafield, probably an entry (textfield)
        #   quit            Any button starting out like this means to exit
        #
        # Note that the params that actually involve DB changes are linked to
        # "submit"-style buttons. This guarantees that only one will ever be
        # present in the dataspace of a connection/request.
        #
        $button = (grep(/^add|del|edit|quit/oi, @keys))[0];
        @parts = split(/:/, $button);
        #
        # First part is the action, last part is the host, and the context is
        # whatever's left:
        #
        $action  = shift(@parts);
        $host    = pop(@parts);
        $context = join(':', @parts);
        if ($action and exists $actions{$action} and
            &{$actions{$action}}($D, $c, $query, $tables, $host, $context))
        {
            #
            # A return value of true/non-null/non-zero means that the
            # action itself displayed a page and is done with the
            # connection. In those cases, close the connection object and
            # skip the display of the main page.
            #
            close $c;
            redo;
        }
        #
        # Display the main page
        #
        main_page($D, $c, $query, $tables);
        close $c;
    }

    #
    # Shouldn't reach here, but if we do then force the issue with SIGINT
    #
    kill $SIGNAL{INT}, $$;
    exit 0; # Never reached
}

###############################################################################
#
#   Sub Name:       tables_fill
#
#   Description:    Fill the hashref with the elements of the database for
#                   both the mirror_specification and mirror_host_list
#                   tables.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $C        in      ref       HTTP Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   Use this hashref to store
#
#   Globals:        $dbh           Already-open DB handle
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    kills the daemon
#
###############################################################################
sub tables_fill
{
    my ($C, $Q, $T) = @_;

    my ($sth, %mir_spec_results, %mir_spec_res_exp, %mir_list, $row, $all_rows,
        $labels, $values, $mirror);

    #
    # First do the specifications
    #
    $T->{specs} = {};
    unless ($sth = $dbh->prepare_cached('select * from mirror_specification'))
    {
        print $C $Q->error_message('SQL Error on Statement Preparation',
                                   'There was an error attempting to prepare',
                                   'the SQL statement for querying the ',
                                   'database:',
                                   $Q->br,
                                   $Q->code("select * from " .
                                            "mirror_specification"),
                                   $Q->br,
                                   $Q->b($Q->code($DBI::errstr)),
                                   $Q->br,
                                   'By necessity, the admin daemon has been',
                                   'terminated.');

        kill $SIGNAL{INT}, $$;
        exit -1; # Never reached
    }
    $sth->execute;
    $labels = $sth->{NAME};
    %mir_spec_results = ();
    $all_rows = $sth->fetchall_arrayref;
    $sth->finish;
    $T->{order} = [ @$labels ];
    for $row (@$all_rows)
    {
        #
        # For each of the rows returned, make a usable hash, copy it and
        # expand any variables, then assign the two to the apropos parts of
        # the $T->{specs} part of $T.
        #
        next unless defined $row;
        @mir_spec_results{@$labels} = @$row;
        %mir_spec_res_exp = %mir_spec_results;
        # Yeah yeah, I'll fix IMS::ReleaseMgr::Utils to export this function:
        # (99/06/10 Eventually...)
        &IMS::ReleaseMgr::Utils::variable_substitution(\%mir_spec_res_exp);
        $mirror = $mir_spec_results{MIRROR_NAME};
        $T->{specs}->{$mirror} = { %mir_spec_results };
        $T->{specs}->{"$mirror.exp"} = { %mir_spec_res_exp };
    }

    #
    # That was fun. Now let's grab all the mirror host lists.
    #
    $T->{hosts} = {};
    unless ($sth = $dbh->prepare_cached('select * from mirror_pool_host_list'))
    {
        print $C $Q->error_message('SQL Error on Statement Preparation',
                                   'There was an error attempting to prepare',
                                   'the SQL statement for querying the ',
                                   'database:',
                                   $Q->br,
                                   $Q->code("select * from " .
                                            "mirror_pool_host_list"),
                                   $Q->br,
                                   $Q->b($Q->code($DBI::errstr)),
                                   $Q->br,
                                   'By necessity, the admin daemon has been',
                                   'terminated.');

        kill $SIGNAL{INT}, $$;
        exit -1; # Never reached
    }
    $sth->execute;
    $labels = $sth->{NAME};
    %mir_list = ();
    $all_rows = $sth->fetchall_arrayref;
    $sth->finish;
    for $row (@$all_rows)
    {
        #
        # For each of the rows returned, make a usable hash then assign it
        # to the $T->{hosts} part of $T. Make sure that the key we use will
        # match the key used above, so that everything for www.buy.hp.com
        # is easily and obviously related. Unlike above, the mirror name is
        # NOT unique, and thus we must store these refs in a listref.
        #
        next unless defined $row;
        @mir_list{@$labels} = @$row;
        $mirror = $mir_list{MIRROR_POOL};
        $T->{hosts}->{$mirror} = [] unless defined $T->{hosts}->{$mirror};
        push(@{$T->{hosts}->{$mirror}}, { %mir_list });
    }

    #
    # That should be enough database abuse for now...
    #
    1;
}

###############################################################################
#
#   Sub Name:       main_page
#
#   Description:    Present the main page with any current database information
#                   along with form elements to enable editing.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $D        in      ref       HTTP::Daemon object, for form
#                                                 action URLs
#                   $C        in      ref       HTTP::Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   One really ugly data structure
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    if it *can* fail, it'll kill the daemon
#
###############################################################################
sub main_page
{
    my ($D, $C, $Q, $T) = @_;

    my %hosts = ();
    my @hosts;

    write_log_line($LOGFILE,
                   sprintf("%s [$$] Serving main page request",
                           scalar localtime))
        if $DEBUG;
    grep({ ! /\.exp$/io && $hosts{lc $_}++ },
         (keys %{$T->{specs}}, keys %{$T->{hosts}}));
    @hosts = sort keys %hosts;

    print $C $Q->header;
    print $C $Q->start_html(-title => 'Mirror Database Editor Main Page',
                            -bgcolor => 'white');
    print $C $Q->center($Q->h1('Mirror Database Editor Main Page'),
                        $Q->hr({ -WIDTH => '80%' }));
    print $C $Q->center($Q->font({ -SIZE => '-1' }, 'Jump to:'), $Q->br, '[' .
                        join('] [',
                             (map { $Q->a({ -HREF => "#$_" }, $_) } @hosts)) .
                        ']')
        if (scalar @hosts);
    print $C $Q->center($Q->startform('POST', $D->url . $magic),
                        $Q->submit(-name  => "add:newmirror",
                                   -value => 'Create a new mirror pool'),
                        $Q->br,
                        $Q->submit(-name  => 'quit:toplevel',
                                   -value => 'Exit MDE'),
                        $Q->endform);
    for my $host (@hosts)
    {
        #
        # The per-host layout is pretty consistent this way. Put up the actual
        # pool name, along with a hook to some details. Then, if there are any
        # specs for it, spit those out with entry fields (<TEXTFIELD>) and a
        # third column that shows the expanded value of the field if there are
        # any macros inside it (that is, if the raw value != the expanded).
        # Then if there are any hosts in the hosts list, display each one's
        # "true" name along with a button to delete the particular host. If
        # there are no specs, we offer a button to add some. Whether there are
        # hosts or not, we offer a button to add some.
        #
        print $C $Q->center($Q->hr({ -WIDTH => '80%' }));
        print $C $Q->a({ -NAME => $host });
        print $C $Q->table({ -WIDTH => '100%', -BORDER => 0 },
                           $Q->TR({ -VALIGN => 'top' },
                                  $Q->td($Q->b('Name: '),
                                         $Q->font({ -SIZE => '+1' },
                                                  $Q->code($host))),
                                  # This gives me a hook for possible future
                                  # use of a database that contains details of
                                  # a specified mirror group
                                  $Q->td({ -ALIGN => 'right' },
                                         $Q->b('Details: '), '(n/a)')),
                           $Q->TR($Q->td({ -COLSPAN => 2, -ALIGN => 'center' },
                                         $Q->startform('POST',
                                                       $D->url . $magic),
                                         $Q->submit(-name  => "del:all:$host",
                                                    -value =>
                                                    "Completely delete $host"),
                                         $Q->br,
                                         $Q->submit(-name  => "quit:$host",
                                                    -value => 'Exit MDE'),
                                         $Q->endform)));
        if (defined $T->{specs}->{$host})
        {
            my $specs = $T->{specs}->{$host};
            my $exp_specs = $T->{specs}->{"$host.exp"};

            print $C $Q->startform('POST', $D->url . $magic . "#$host");
            print $C $Q->center($Q->table({ -WIDTH => '90%', -BORDER => 1 },
              $Q->TR(map { $Q->th($_) } ('Field Name',
                                         'Value' . $Q->br . '(expanded)')),
              (map
              {
                  $Q->TR({ -VALIGN => 'top', -ALIGN => 'center' },
                         $Q->td({ -WIDTH => '50%' },
                                $Q->code($Q->font({ -SIZE => '+1' }, $_))),
                         $Q->td({ -WIDTH => '50%' },
                                $Q->code(edit_field($Q, $_, $host,
                                                    $specs->{$_}, 30, 256)),
                                $Q->br,
                                (($specs->{$_} ne $exp_specs->{$_}) ?
                                 $Q->code($exp_specs->{$_}) : '')))
              } @{$T->{order}})));
            print $C $Q->table({ -WIDTH => '100%', -BORDER => 0 },
              $Q->TR($Q->td($Q->submit(-name  => "edit:specs:$host",
                                       -value => "Make changes to $host")),
                     $Q->td({ -ALIGN => 'right' },
                            $Q->submit(-name  => "del:specs:$host",
                                       -value => "Delete specs for $host"))));
            print $C $Q->endform;
        }
        else
        {
            print $C $Q->p("No specifications have been set up for $host.",
                           # We're cheating. Since we know we're adding specs
                           # For a particular host, we're pulling two tricks
                           # here: first, the POST URL also contains an anchor
                           # reference, so that the page that gets displayed,
                           # the browser jumps right to this host. The second
                           # trick is that by naming the submit button with
                           # the host name in the context field rather than
                           # "newmirror", we'll jump straight into the part of
                           # that loop that adds the data in, without the
                           # the intermediate page.
                           $Q->startform('POST', $D->url . $magic . "#$host"),
                           $Q->submit(-name  => "add:$host:newmirror",
                                      -value => "Click here"),
                           "to add specifications.", $Q->endform);
        }
        print $C $Q->a({ -NAME => "$host|hosts" });
        if (defined $T->{hosts}->{$host})
        {
            my $hosts = $T->{hosts}->{$host};

            print $C $Q->startform('POST', $D->url . $magic . "#$host|hosts");
            print $C $Q->center($Q->table({ -WIDTH => '80%', -BORDER => 0 },
              $Q->TR($Q->th({ -COLSPAN => 3 }, "Hosts in the $host pool:")),
              $Q->TR(map { $Q->th($_) } ('Name', 'Port', 'Physical Host',
                                         'Delete?')),
              (map
              {
                  $Q->TR({ -ALIGN => 'center' },
                         $Q->td({ -WIDTH => '25%' },
                                $Q->code($_->{HOST_NAME})),
                         $Q->td({ -WIDTH => '17%' },
                                $Q->code($_->{SERVER_PORT})),
                         $Q->td({ -WIDTH => '25%' },
                                $Q->code($_->{PHYSICAL_HOST})),
                         $Q->td({ -WIDTH => '33%' },
                                $Q->submit(-name  =>
                                           "del:host:$_->{HOST_NAME}:$host",
                                           -value => "Delete this mirror")));
              } (sort { $a->{HOST_NAME} cmp $b->{HOST_NAME} } @$hosts)),
              $Q->TR($Q->td({ -ALIGN => 'center', -COLSPAN => 3 },
                            $Q->submit(-name  => "add:hosts:$host",
                                       -value =>"Add hosts to $host pool")))));
            print $C $Q->endform;
        }
        else
        {
            print $C $Q->p("No mirror hosts have been set up for pool $host.",
                           $Q->startform('POST',
                                         $D->url . $magic . "#$host|hosts"),
                           $Q->submit(-name  => "add:hosts:$host",
                                      -value => "Click here"),
                           "to add hosts.", $Q->endform);
        }
        print $C $Q->center($Q->p($Q->font({ -SIZE => -1 },
                                           $Q->a({ -HREF => $D->url . $magic },
                                                 'Return to top of page'))));
    }
    print $C $Q->page_footer;
    print $C $Q->end_html;

    1;
}

###############################################################################
#
#   Sub Name:       edit_field
#
#   Description:    Return a textfield for an HTML form using the passed query
#                   object, the field name, hostname and initial value.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $Q        in      mCGI      Object of class mCGI
#                   $name     in      scalar    field name
#                   $host     in      scalar    Host this field is part of
#                   $value    in      scalar    Current value of the field
#                   $width    in      scalar    If non-null, visual width of
#                                                 textfield
#                   $maxwidth in      scalar    If non-null, maximum width of
#                                                 the data itself.
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    HTML text
#                   Failure:    shouldn't
#
###############################################################################
sub edit_field
{
    my ($Q, $name, $host, $value, $width, $maxwidth) = @_;

    $Q->textfield(-name => "field:$name:$host",
                  -default => $value,
                  ((defined $width and $width) ? (-size => $width) : ()),
                  ((defined $maxwidth and $maxwidth) ?
                   (-maxlength => $maxwidth) : ()));
}

#
# This is the cut-off point. Before now, all the routines seen were guaranteed
# to be called at least once. After this point, they're only called on demand.
# So they only get compiled on demand, as well.
#
__DATA__

###############################################################################
#
#   Sub Name:       toplevel_add
#
#   Description:    Post and/or process pages that are add-function-related.
#                   At least some of the logical branches will fall through to
#                   other routines.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $D        in      ref       HTTP::Daemon object, for form
#                                                 action URLs
#                   $C        in      ref       HTTP::Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   One really ugly data structure
#                   $host     in      scalar    Host/mirror that this operation
#                                                 is affecting
#                   $context  in      scalar    Any additional information that
#                                                 would be relevant to the
#                                                 action.
#
#   Globals:        $magic
#                   $cmd
#                   $VERSION
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub toplevel_add
{
    my ($D, $C, $Q, $T, $host, $context) = @_;

    return new_mirror_setup(@_) if ($host eq 'newmirror');

    if ($context eq 'hosts')
    {
        if (defined $Q->param("field:flag:$host") and
            $Q->param("field:flag:$host"))
        {
            #
            # We're now processing the form itself, assuming that we actually
            # have data to add...
            #
            my (@names, @ports, @reals);
            for (0 .. 3)
            {
                $names[$_] = $Q->param("field:name$_:$host") || '';
                $ports[$_] = $Q->param("field:port$_:$host") || 80;
                $reals[$_] = $Q->param("field:real$_:$host") || '';
            }
            return 0 unless (grep(length > 0, @names));

            # Looks like at least one entry was filled out correctly. Prep
            # some SQL and have a run at it.
            my $sth = $dbh->prepare_cached(qq{
                                              insert into mirror_pool_host_list
                                              values (?, ?, ?, ?)
                                             });
            unless (defined $sth)
            {
                print $C $Q->error_message('Error Preparing SQL Insert',
                                           'There was an error preparing the',
                                           'SQL block for inserting hosts:',
                                           $Q->br,
                                           $Q->code($Q->b($DBI::errstr)),
                                           $Q->br,
                                           'The daemon has been halted.');
                kill $SIGNAL{INT}, $$;
                exit -1; # Just in case
            }
            for (0 .. 3)
            {
                next unless $names[$_];

                unless ($sth->execute($host, $reals[$_],
                                      $names[$_], $ports[$_]))
                {
                    print $C $Q->error_message('Error Executing SQL Insert',
                                               'There was an error executing',
                                               'the SQL block for inserting',
                                               'hosts:',
                                               $Q->br,
                                               $Q->code($Q->b($DBI::errstr)),
                                               $Q->br,
                                               'The daemon has been halted.');
                    kill $SIGNAL{INT}, $$;
                    exit -1; # Just in case
                }
            }

            tables_fill($C, $Q, $T);
            return 0;
        }
        #
        # Otherwise...
        #
        # Offer a form that gives them 4 entries in which to add hosts. 4 per
        # iteration should be enough (I hope).
        #
        write_log_line($LOGFILE,
                       sprintf("%s [$$] Serving add-mirror-hosts page request",
                               scalar localtime))
            if $DEBUG;
        print $C $Q->header;
        print $C $Q->start_html(-title => 'MDE Add Hosts to Mirror Pool',
                                -bgcolor => 'white');
        print $C $Q->center($Q->h1('Add Hosts to Mirror Pool'),
                            $Q->h3("Pool: $host"),
                            $Q->hr({ -WIDTH => '80%' }),
                            $Q->a({ -HREF => $D->url . $magic },
                                  $Q->font({ -SIZE => -1 },
                                           'Return to Main Page, no changes')),
                            $Q->hr({ -WIDTH => '80%' }));
        print $C $Q->p('Enter up to four entries for the mirror pool for this',
                       "($host)", 'mirror group. If the port field is left',
                       'empty, the port defaults to 80 (the standard HTTP',
                       'port). More than four hosts may be added by returning',
                       'to this page after pressing the',
                       $Q->code($Q->b('Add')),
                       'button below.');
        print $C $Q->startform('POST', $D->url . $magic . "#$host|hosts");
        # This hidden field tells us on the next iteration to actually do the
        # database stuff rather than posting the form.
        print $C $Q->hidden(-name => "field:flag:$host", -value => 1);
        print $C $Q->center($Q->table({ -BORDER => 0, -WIDTH => '80%' },
                                      $Q->TR($Q->th('Host name'),
                                             $Q->th('Physical host name'),
                                             $Q->th('Port (default 80)')),
                                      (map {
                                          $Q->TR({ -ALIGN => 'center' },
                                                 $Q->td({ -WIDTH => '40%' },
                                                        edit_field($Q,
                                                                   "name$_",
                                                                   $host, '',
                                                                   25, 50)),
                                                 $Q->td({ -WIDTH => '40%' },
                                                        edit_field($Q,
                                                                   "real$_",
                                                                   $host, '',
                                                                   25, 50)),
                                                 $Q->td({ -WIDTH => '20%' },
                                                        edit_field($Q,
                                                                   "port$_",
                                                                   $host, '',
                                                                   25, 5)))
                                      } (0 .. 3))),
                            $Q->br,
                            $Q->submit(-name  => "add:hosts:$host",
                                       -value => 'Add these hosts'));
        print $C $Q->endform;
        print $C $Q->page_footer;
        print $C $Q->end_html;
    }

    1;
}

###############################################################################
#
#   Sub Name:       toplevel_del
#
#   Description:    Describe function/algorithm.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $D        in      ref       HTTP::Daemon object, for form
#                                                 action URLs
#                   $C        in      ref       HTTP::Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   One really ugly data structure
#                   $host     in      scalar    Host/mirror that this operation
#                                                 is affecting
#                   $context  in      scalar    Any additional information that
#                                                 would be relevant to the
#                                                 action.
#
#   Globals:        $magic
#                   $cmd
#                   $VERSION
#
#   Environment:    None.
#
#   Returns:        0, display main page for us
#                   1, don't display a page, we already have
#
###############################################################################
sub toplevel_del
{
    my ($D, $C, $Q, $T, $host, $context) = @_;

    my $sql;

    if (($context eq 'specs') or ($context eq 'all'))
    {
        #
        # If this is the first time through, show a form asking for
        # confirmation of the delete. Slip a hidden field in there so that
        # if we find the hidden field, we know that it has been confirmed.
        #
        my $confirm;
        $confirm = $Q->param("field:confirm:$context:$host");
        if (defined $confirm and $confirm)
        {
            $sql = qq{
                      delete from mirror_specification where
                      mirror_name = '$host'
                     };
            execute_SQL($C, $Q, $T, $sql, 'die on error');

            if ($context eq 'all')
            {
                $sql = qq{
                          delete from mirror_pool_host_list where
                          mirror_pool = '$host'
                         };
                execute_SQL($C, $Q, $T, $sql, 'die on error');
            }

            tables_fill($C, $Q, $T);
            return 0;
        }
        else
        {
            #
            # Display the form
            #
            write_log_line($LOGFILE,
                           sprintf("%s [$$] Serving delete-confirmation page" .
                                   " request", scalar localtime));
            print $C $Q->header;
            print $C $Q->start_html(-title => 'Confirm Deletion',
                                    -bgcolor => 'white');
            print $C $Q->center($Q->h1('Please confirm deletion'),
                                $Q->hr({ -WIDTH => '80%' }));
            print $C $Q->p('Please confirm the request to delete the',
                           (($context eq 'specs') ?
                            'specifications' : 'entire entry'),
                           "for the host $host:");
            print $C $Q->startform('POST', $D->url . $magic);
            print $C $Q->submit(-name  => "del:$context:$host",
                                -value => 'Yes, delete ' .
                                (($context eq 'specs') ?
                                 'specifications' : 'entire entry'));
            # This hidden field is the key to confirmation. It wasn't present
            # this time through (hence falling through to this branch), but it
            # will be next time, if they click on the button to confirm.
            print $C $Q->hidden(-name  => "field:confirm:$context:$host",
                                -value => 1);
            print $C $Q->endform;
            print $C $Q->a({ -HREF => $D->url . $magic },
                           'Return to main page without deleting');
            print $C $Q->page_footer;
            print $C $Q->end_html;
        }

        return 1;
    }
    elsif (substr($context, 0, 5) eq 'host:')
    {
        # We got host:$name in $context, extrace the $name part of it
        my $host_to_del = (split(/:/, $context))[1];
        $sql = qq{
                  delete from mirror_pool_host_list where
                  mirror_pool = '$host' and host_name = '$host_to_del'
                 };
        execute_SQL($C, $Q, $T, $sql, 'die on error');

        tables_fill($C, $Q, $T);
        return 0;
    }

    #
    # else...
    #
    print $C $Q->error_message('Unknown/Invalid Context for Delete',
                               'The context in which the delete command',
                               'was issued was unknown or invalid. You',
                               'may return to the main page by following',
                               'the link below.',
                               $Q->br,
                               $Q->a({ -HREF => $D->url . $magic },
                                     'Editor Main Page'));

    return 1;
}

###############################################################################
#
#   Sub Name:       toplevel_edit
#
#   Description:    Describe function/algorithm.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $D        in      ref       HTTP::Daemon object, for form
#                                                 action URLs
#                   $C        in      ref       HTTP::Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   One really ugly data structure
#                   $host     in      scalar    Host/mirror that this operation
#                                                 is affecting
#                   $context  in      scalar    Any additional information that
#                                                 would be relevant to the
#                                                 action.
#
#   Globals:        $magic
#                   $cmd
#                   $VERSION
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub toplevel_edit
{
    my ($D, $C, $Q, $T, $host, $context) = @_;

    #
    # Unlike the other core functions, there are (currently) no intermediate
    # forms for editing. The button that led us here was part of the only
    # relevant form.
    #
    # Start by gathering all the parameter names, which we'll then pare down
    # to the field:*:$host subset
    #
    my @keys = $Q->param;
    @keys = grep(/^field:.*:$host$/, @keys);

    # Lose the outer values
    grep(s/^.*?:(.*):.*?$/$1/o, @keys);

    #
    # Now further narrow the list down to just those fields that were changed
    # from their existing values.
    #
    @keys = grep($Q->param("field:$_:$host") ne $T->{specs}->{$host}->{$_},
                 @keys);
    my %vals = map { $_, $Q->param("field:$_:$host") } @keys;

    my $sql = "update mirror_specification set\n" .
        join(",\n", (map {
                         sprintf("%s = %s", $_,
                                 (($vals{$_} =~ /^\d+$/o) ?
                                  $vals{$_} : "'$vals{$_}'"))
                     } @keys)) .
        "\nwhere MIRROR_NAME = '$host'";
    execute_SQL($C, $Q, $T, $sql, 'die on error');
    tables_fill($C, $Q, $T);

    0;
}

###############################################################################
#
#   Sub Name:       toplevel_exit
#
#   Description:    Process the user request to exit the editing session
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $D        in      ref       HTTP::Daemon object, for form
#                                                 action URLs
#                   $C        in      ref       HTTP::Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   One really ugly data structure
#                   $host     in      scalar    Host/mirror that this operation
#                                                 is affecting
#                   $context  in      scalar    Any additional information that
#                                                 would be relevant to the
#                                                 action.
#
#   Globals:        $magic
#                   $cmd
#                   $VERSION
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub toplevel_exit
{
    my ($D, $C, $Q, $T, $host, $context) = @_;

    print $C $Q->header;
    print $C $Q->start_html(-title => 'MDE Session Ended',
                            -bgcolor => 'white');
    print $C $Q->center($Q->h1('Mirror Database Edit Session Closed'),
                        $Q->hr({ -WIDTH => '80%' }));
    print $C $Q->p('The database session has been closed. To make further ',
                   'changes it will be necessary to start a new session.');
    print $C $Q->page_footer;
    print $C $Q->end_html;

    #
    # Close the connection object to force flushing before we shutdown the
    # daemon:
    #
    close $C;

    #
    # Terminate via pre-defined signal:
    #
    kill $$, $SIGNAL{USR1};

    # We really don't make it this far...
    exit 0;
}

###############################################################################
#
#   Sub Name:       new_mirror_setup
#
#   Description:    Prompt for a new mirror pool name or process the add
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $D        in      ref       HTTP::Daemon object, for form
#                                                 action URLs
#                   $C        in      ref       HTTP::Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   One really ugly data structure
#                   $host     in      scalar    Host/mirror that this operation
#                                                 is affecting
#                   $context  in      scalar    Any additional information that
#                                                 would be relevant to the
#                                                 action.
#
#   Globals:        $magic
#                   $cmd
#                   $VERSION
#                   $dbh
#
#   Environment:    None.
#
#   Returns:        0, display main page for us
#                   1, don't display a page, we already have
#
###############################################################################
sub new_mirror_setup
{
    my ($D, $C, $Q, $T, $host, $context) = @_;

    #
    # The add request for a new mirror pool comes to us one of two ways: either
    # as an initial request from the main page, in which case the value of
    # $context is null, or as a result of the form described below, in which
    # case a value has been provided for $context.
    #
    if ($context)
    {
        #
        # Check that we got what appears to be a valid context value
        #
        my $mirror;

        if ($context =~ /^submit/oi)
        {
            #
            # This should be the name of the entry field created in the form
            # described below. It should have the name of the desired new
            # mirror pool.
            #
            $mirror = $Q->param("field:newmirror:$host");
            unless (defined $mirror and $mirror)
            {
                $C->send_error(RC_BAD_REQUEST,
                               'Invalid context for requested operation ' .
                               "(add:$context:$host)");
                return 1;
            }
        }
        elsif ($context =~ /[\w-]\.[\w-]/oi)
        {
            $mirror = $context
        }
        else
        {
            $C->send_error(RC_BAD_REQUEST,
                           'Invalid context for requested operation ' .
                           "(add:$context:$host)");
            return 1;
        }

        my $realm  = (split(/\./, $mirror))[1];
        #
        # Default value for Realm is the mid part of the host name, first char
        # capitalized. I.e., "www.buy.hp.com" => "Buy"
        #
        $realm = ucfirst lc $realm;
        #
        # This is the SQL we prepare for the table insertion. It's just
        # formatted for readability (I hope) here...
        #
        my $sql_stmt = qq{
                          insert into mirror_specification values
                          ('$mirror',
                           'Initial specification for mirror pool $mirror',
                           '/opt/ims/$mirror',
                           '\$SERVER_ROOT/htdocs',
                           '\$SERVER_ROOT/cgi-bin',
                           '\$SERVER_ROOT/fcgi-bin',
                           '\$SERVER_ROOT/scripts',
                           '\$SERVER_ROOT/startup-scripts',
                           '\$SERVER_ROOT/staging',
                           '\$SERVER_ROOT/incoming',
                           '\$SERVER_ROOT/logs',
                           '\$LOGGING_DIR/Pushes',
                           'wesadm',
                           'wesadm',
                           'md5',
                           'webmaster\@nafohq.hp.com',
                           30,
                           10,
                           'weblist',
                           0,
                           'httpu',
                           'CHANGE THIS',
                           '/cgi-bin/upload.pl',
                           'IMS-$realm',
                           'none',
                           '',
                           '',
                           '',
                           0,
                           'rlsmgrd',
                           'deploy_content',
                           'process_content')
                         };
        execute_SQL($C, $Q, $T, $sql_stmt, 'die on error');
        tables_fill($C, $Q, $T);
        return 0;
    }

    #
    # No real need for an "else" clause here...
    #
    write_log_line($LOGFILE,
                   sprintf("%s [$$] Serving add-new-mirror page request",
                           scalar localtime))
        if $DEBUG;
    print $C $Q->header;
    print $C $Q->start_html(-title => 'MDE Add New Mirror',
                            -bgcolor => 'white');
    print $C $Q->center($Q->h1('Create a New Mirror Pool'),
                        $Q->hr({ -WIDTH => '80%' }),
                        $Q->a({ -HREF => $D->url . $magic },
                              $Q->font({ -SIZE => -1 },
                                       'Return to Main Page, no changes')),
                        $Q->hr({ -WIDTH => '80%' }));
    print $C $Q->startform('POST', $D->url . $magic);
    print $C $Q->p('Enter the fully-qualified domain name (FQDN) for the',
                   'new mirror group. This is the top-level name to which',
                   'HTTP requests are answered, not the individual name(s)',
                   'assigned to the members of the pool:');
    print $C $Q->p($Q->code('Name: ',
                            edit_field($Q, 'newmirror', $host, '', 36, 36)),
                   # Dropping this hidden field allows the user to just hit
                   # [return] in the entry field instead of clicking. Pretty
                   # sneaky, huh?
                   $Q->hidden(-name    => 'add:submit0:newmirror',
                              -default => 'add:submit0:newmirror'));
    print $C $Q->p('Press the button below when you are done, and the main',
                   'edit page will return with an entry for this new pool',
                   'included in the contents. The fields will be pre-filled',
                   'will defaults, and can then be tuned as desired. Or you',
                   'may use the link at the top of this page to return to',
                   'the main page without making changes to the database.');
    print $C $Q->center($Q->p($Q->submit(-name  => 'add:submit:newmirror',
                                         -value =>
                                         'Create this new Mirror Group')));
    print $C $Q->page_footer;
    print $C $Q->end_html;

    1;
}

###############################################################################
#
#   Sub Name:       execute_SQL
#
#   Description:    Take the passed-in SQL block, prepare it, and execute it.
#                   handle calls to error routines as needed.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $C        in      ref       HTTP::Connection object
#                   $Q        in      mCGI      mCGI query object
#                   $T        in      hashref   One really ugly data structure
#                   $sql      in      scalar    SQL code to prep/exec
#                   $DIE      in      scalar    If passed and non-null, die
#                                                 on errors.
#
#   Globals:        $dbh
#                   %SIGNAL
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0, and exits if $DIE is non-null
#
###############################################################################
sub execute_SQL
{
    my ($C, $Q, $T, $sql, $DIE) = @_;

    # This will turn undef into 0 and avoid warnings
    $DIE = $DIE || 0;

    my $sth = $dbh->prepare($sql);
    unless (defined $sth)
    {
        print $C $Q->error_message('SQL Statement Preparation Error',
                                   'There was an error attempting to',
                                   'prepare the following SQL statement:',
                                   $Q->br,
                                   $Q->pre($Q->code($sql)),
                                   $Q->br,
                                   $Q->b($Q->code($DBI::errstr)),
                                   $Q->br,
                                   ($DIE ? ('By necessity, the admin daemon',
                                            'has been stopped.') : ()));

        if ($DIE)
        {
            close $C;
            kill $SIGNAL{INT}, $$;
            exit -1; # Never reached
        }
        else
        {
            return 0;
        }
    }
    unless ($sth->execute)
    {
        print $C $Q->error_message('SQL Statement Execution Error',
                                   'There was an error attempting to',
                                   'execute the following SQL statement:',
                                   $Q->br,
                                   $Q->pre($Q->code($sql)),
                                   $Q->br,
                                   $Q->b($Q->code($DBI::errstr)),
                                   $Q->br,
                                   ($DIE ? ('By necessity, the admin daemon',
                                            'has been stopped.') : ()));

        if ($DIE)
        {
            close $C;
            kill $SIGNAL{INT}, $$;
            exit -1; # Never reached
        }
        else
        {
            return 0;
        }
    }
    $sth->finish;
    $dbh->commit;

    1;
}
