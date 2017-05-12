#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#
#----------------------------------------------------------------------------
#
# CronJob execution script.
#
# ------------------------------------------------------------------------

BEGIN {
    $| = 1;                     # Auto flush for command line
    $0 = 'ePortal-cron.pl';     # to show in ps -ax
    # add lib path in source tree
    push @INC, '../lib' if (-d '../lib') and ! grep {$_ eq '../lib'} @INC;
}

# ------------------------------------------------------------------------
# Modules and global variables
#
    our $VERSION = '4.3';
use ePortal::Global;
use ePortal::Utils;
use ePortal::Server;
use HTML::Mason;
use Getopt::Long qw//;
use Date::Calc;
use List::Util;

use ePortal::Exception;
use Error qw/:try/;

# ------------------------------------------------------------------------
# Command line parameters
my $opt_help;
my $opt_verbose;
my $opt_force;
my ($opt_mysql_host, $opt_mysql_database, $opt_mysql_user, $opt_mysql_password, 
    $opt_jobserver);

Getopt::Long::GetOptions(
    'database|D=s' => \$opt_mysql_database,
    'force|f=s' => \$opt_force,
    'help|?!' => \$opt_help,
    'jobserver|j=s' => \$opt_jobserver,
    'password|p=s' => $opt_mysql_password,
    'host|h=s' => \$opt_mysql_host,
    'user|u=s' => \$opt_mysql_user,
    'verbose|v!' => \$opt_verbose,
    );

if ($opt_help or $opt_verbose) {
    print
        "\nePortal cron command line utility v.$VERSION\n",
        "Copyright (c) 2001-2004 Sergey Rusakov <rusakov_sa\@users.sourceforge.net>\n\n";
}

if ($opt_help) {
    print $0, " [options]\n\n",
        "Options:\n",
        " -?, --help             This help screen\n",
        " -v, --verbose          Be verbose\n",
        " -f, --force=[daily|hourly|all]\n",
        "                        Force this type of job to run\n",
        " -j, --jobserver=name   Name the server running this job\n",
        " -h, --host=name        MySQL host name\n",
        " -D, --database=name    MySQL database name\n",
        " -u, --user=name        MySQL user name\n",
        " -p, --password=xxx     MySQL user password\n",
        "\n";
    exit 1;
}


# ------------------------------------------------------------------------
# Create Server and Interp objects
#
$ePortal = new ePortal::Server( 
                dbi_host => $opt_mysql_host, dbi_username => $opt_mysql_user,
                dbi_password => $opt_mysql_password, dbi_database => $opt_mysql_database);
$ePortal->initialize();

our $outbuf;
our $Interp = HTML::Mason::Interp->new
            (comp_root  => $ePortal->comp_root,
             autohandler_name => 'autohandler.mc',
             allow_globals => [qw/ $ePortal %session/],
             escape_flags => {h => \&HTML::Mason::Escapes::basic_html_escape},
             out_method => \$outbuf
            );

# ------------------------------------------------------------------------
# Check for required parameters
# Construct administrator's email address
throw ePortal::Exception::Fatal(-text => 'mail_domain parameter of ePortal is not set.')
    if ! $ePortal->mail_domain;
throw ePortal::Exception::Fatal(-text => 'www_server parameter of ePortal is not set.')
    if ! $ePortal->www_server;


my @admins_email;
foreach my $admin_name ( @{ $ePortal->admin }) {
    my $uo = new ePortal::epUser;
    $uo->restore_where(username => $admin_name);
    next if ! $uo->restore_next;
    if ($uo->email) {
        push @admins_email, $uo->email;
    } elsif ( ! $ePortal->mail_domain) {
        print STDERR "mail_domain parameter of ePortal is not defined\n";
    } else {
        push @admins_email, $admin_name . '@' . $ePortal->mail_domain;
    }
}

# ------------------------------------------------------------------------
# Discover a time when I run last time
#
my $last_run_sql = $ePortal->Config("last_run_$0");
my $this_run_sql = $ePortal->dbh->selectrow_array('select now()');
$ePortal->Config("last_run_$0", $this_run_sql);
print "This utility was last executed at: $last_run_sql\n"
    if $opt_verbose;
print "Will run only jobs for jobserver=$opt_jobserver\n"
    if $opt_verbose and $opt_jobserver;

my @last_run = split('\D+', $last_run_sql);
@last_run = (1970,1,1, 0,0,0) if ! Date::Calc::check_date(@last_run[0..2]);
my @this_run = split('\D+', $this_run_sql);

my ($need_for_daily_jobs, $need_for_hourly_jobs);
if (    $last_run[0] != $this_run[0] or
        $last_run[1] != $this_run[1] or
        $last_run[2] != $this_run[2] ) {
    $need_for_daily_jobs = 1;
    $need_for_hourly_jobs = 1;
}
if (    $last_run[3] != $this_run[3] ) {
    $need_for_hourly_jobs = 1;
}
print "Happy new day! Will execute daily jobs\n" if $opt_verbose and $need_for_daily_jobs;
print "Happy new hour! Will execute hourly jobs\n" if $opt_verbose and $need_for_hourly_jobs;


# ------------------------------------------------------------------------
# Running jobs
#
print "\n" if $opt_verbose;
printf "%-40s %-19s Status\n", "Job", "Last start" if $opt_verbose;
my $cj = new ePortal::CronJob;
$cj->restore_all;
while($cj->restore_next) {
    # Calculate time passed...
    my @last_run = $cj->attribute('LastRun')->array;
    @last_run = (1970,1,1, 0,0,0) if ! Date::Calc::check_date(@last_run[0..2]);
    my @this_run = split('\D+', $ePortal->dbh->selectrow_array('select now()'));

    # Calculate amount of time passed from last job run
    my @delta = Date::Calc::Delta_DHMS(@last_run, @this_run);           # time passed from last run
    my $delta_minutes = 1+ $delta[0]*24*60 + $delta[1]*60 + $delta[2];  # minutes passed so long
                                                                    # 1 extra min for seconds round-up

    printf "%-40s %02d.%02d.%04d %02d:%02d:%02d ", $cj->Title, @last_run[2,1,0, 3..5]
        if $opt_verbose;

    # Skip disabled some jobs
    if ($cj->JobStatus eq 'disabled') {
        print "disabled\n" if $opt_verbose;
        next;
    }

    # Check JobServer
    if ($opt_jobserver ne $cj->JobServer) {
        printf ("js=%s\n", $cj->JobServer) if $opt_verbose;
        next;
    }

    # Check period and force flag
    if ($opt_force eq 'all') {
#         print "forced\n" if $opt_verbose;
        
    } elsif ($cj->ForceRun > 0 ) {
#         print "forced\n" if $opt_verbose;

    } elsif ($cj->Period eq 'daily') {
        if ($opt_force eq 'daily') {
#            print "forced\n" if $opt_verbose;
        } elsif (! $need_for_daily_jobs) {
            print "skipped\n" if $opt_verbose;
            next;
        }

    } elsif ($cj->Period eq 'hourly') {
        if ($opt_force eq 'hourly') {
#            print "forced\n" if $opt_verbose;
        } elsif (! $need_for_hourly_jobs) {
            print "skipped\n" if $opt_verbose;
            next;
        }

    } elsif ($cj->Period eq 'always' ) {
        # Run it on every start of script
#        print "started\n" if $opt_verbose;

    } else {
        if ($cj->Period > $delta_minutes) {
            print "skipped\n" if $opt_verbose;
            next;
        }
    }

    # Starting the job
    $cj->ForceRun(0);
    $cj->LastRun('now');
    $cj->LastResult('running');
    $cj->update;

    $outbuf = undef;
    try {
        $cj->CurrentResult('unknown');
        $Interp->exec($cj->Title, job => $cj);
    } otherwise {
        my $E = shift;
        $outbuf = "<b>Job failed!</b><p>\n<pre>\n$E\n</pre>";
        $cj->CurrentResult('failed');
    };

    # Finish the job
    $cj->LastResultHTML($outbuf);
    $cj->LastResult($cj->CurrentResult);
    $cj->LastResult('no_work') if $cj->LastResult eq 'unknown' or $cj->LastResult eq '';
    $cj->update;
    print $cj->LastResult, "\n" if $opt_verbose;

    # Sending mail report to administrators
    my $send_email_or_not;
    if ($cj->MailResults eq 'never') {
        $send_email_or_not = 0;
    } elsif ($cj->MailResults eq 'on_error') {
        $send_email_or_not = 1 if $cj->LastResult eq 'failed';
    } elsif ($cj->MailResults eq 'on_success') {
        $send_email_or_not = 1 if $cj->LastResult eq 'failed';
        $send_email_or_not = 1 if $cj->LastResult eq 'done';
    } else {
        $send_email_or_not = 1;
    }

    foreach my $mail (@admins_email) {
        last if ! $send_email_or_not;

        print "\tsending report to $mail\n" if $opt_verbose;
        $ePortal->send_email($mail, 'CronJob status: '.$cj->Title,
            '<html><head><style type="text/css">
            body { font-size: x-small; font-family: MS Sans Serif;};
            table { font-size: x-small; font-family: MS Sans Serif; };
            </style></head>',
            '<body bgcolor="#ebd2a5">',
            $cj->LastResultHTML,
            '</body></html>'
        );
    }
}

exit 0;

