#!/usr/local/bin/perl
    eval 'exec perl -S $0 "$@"'
	if 0;

###############################################################################
#
#        May be distributed under the terms of the Artistic License
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: upload.pl,v 1.1 1999/08/08 23:19:35 randyr Exp $
#
#   Description:    Post and process the form for upload of distribution
#                   bundles from external (contract) groups to HP servers.
#
#   Functions:      primary_form            Post the main upload form.
#                   process_form            Manage the results of the user
#                                             input.
#                   read_user_config        Read the config file for user/email
#                                             information.
#                   error_splash            Report an error both to the
#                                             browser and to the error log
#                                             (via CGI::Carp::croak).
#
#   Libraries:      CGI
#                   CGI::Carp
#                   IO::File
#                   IMS::ReleaseMgr
#                   IMS::ReleaseMgr::Utils
#
#   Global Consts:  $cmd                    This tool's name
#                   $Q                      Used to instantiate an object from
#                                             the CGI class.
#
###############################################################################
use vars qw($cmd);
($cmd = $0) =~ s|.*/||;

use 5.004;

use strict;
use vars qw($Q $revision $user %staging_area %config $running_under_browser
            $config_dir $config_file $rc_file $fh $logfile $tmp_conf);
use subs qw(primary_form process_form make_rlsmgr_ticket error_splash
            error_by_http read_user_config unsafe_tar);
use CGI;
use CGI::Carp qw(croak);
require IO::File;

use IMS::ReleaseMgr::Utils qw(DBI_mirror_specification DBI_error
                              file_mirror_specification
                              write_log_line);

$revision = q{$Id: upload.pl,v 1.1 1999/08/08 23:19:35 randyr Exp $ };
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /bad free/oi; };

umask 02;
$ENV{TZ} = 'PST8PDT';

$Q = new CGI;

#
# These specifiy the name and location of the configuration file that
# holds the information on users and their allowable upload destinations
#
# If you do not explicitly set either of these, they will default to
# pre-determined values:
#
#   $config_file will be this script's name, .pl removed and .dat added
#   $config_dir  will be the same directory as this script resides in
#
$config_dir  = '';
$config_file = '';

unless ($config_file)
{
    ($config_file = $cmd) =~ s/\.pl$//oi;
    $config_file .= '.dat';
}
($config_dir) = $0 =~ m|(.*)/|o unless ($config_dir);
$config_dir = '.' unless ($config_dir);

$running_under_browser = 0;
$running_under_browser = 1 if ($Q->user_agent =~ /netscape|microsoft/);

$user = $Q->remote_user;
unless (defined $user)
{
    if ($running_under_browser)
    {
        error_splash('Unknown/invalid user',
                     "There was no authenticated user name provided. $cmd ",
                     "must run under access control restrictions.");
    }
    else
    {
        error_by_http('No authentication user name found');
    }
}

my $mirror = $Q->server_name;
$mirror =~ s/^www\d+/www/o;
# On some systems, if this fails then the failure kills the process
eval { $tmp_conf = DBI_mirror_specification(mirror => $mirror); };

$logfile = "/tmp/upload-$$.err";
if (! defined($tmp_conf))
{
    #
    # Look for a config file under this mirror host name
    #
    my $conf_file = "/opt/ims/ahp-bin/$mirror";
    if (-e $conf_file)
    {
        $tmp_conf = file_mirror_specification(-file => $conf_file);
    }
}

# Better now?
if (! defined($tmp_conf))
{
    # ...guess not
    if ($running_under_browser)
    {
        error_splash('Unable to read mirror pool configuration',
                     'The application was unable to read the configuration ',
                     'for this mirror pool ($mirror). The database system ',
                     'reported: ', DBI_error, '.',
                     'There was no configuration file to fall back on.');
    }
    else
    {
        error_by_http("Unable to read mirror specification for $mirror");
    }
}

unless (defined $tmp_conf->{INCOMING_DIR} and $tmp_conf->{INCOMING_DIR})
{
    if ($running_under_browser)
    {
        error_splash('No incoming directory defined',
                     'The application was unable to determine the directory ',
                     'in which packages are put for staging. Please contact ',
                     'the site webmaster to verify the configuration.');
    }
    else
    {
        error_by_http('No incoming (upload) directory defined');
    }
}

$config{incoming_dir} = $tmp_conf->{INCOMING_DIR};
$logfile = "$tmp_conf->{LOGGING_DIR}/upload-pl";

#
# Decide which page to present them with, based on what data is present.
#
if (defined $Q->param('input_file') and $Q->param('input_file'))
{
    process_form $user;
}
else
{
    if ($running_under_browser)
    {
        primary_form $user;
    }
    else
    {
        error_by_http('HTML upload form requires full browser support');
    }
}

exit 0;

###############################################################################
#
#   Sub Name:       error_splash
#
#   Description:    Display the error text (and as much other information as
#                   is available) to the browser in reasonable HTML format,
#                   and use CGI::Carp::croak to exit, so that the resulting
#                   error message is properly formatted within the server logs.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $title    in      scalar    Title/one line err description
#                   @err_text in      list      The text of the error at hand.
#                                                 May be $!, $@, etc., or
#                                                 custom-fed.
#
#   Globals:        $Q                   The top-level global query object
#                   $cmd                 This script's name
#                   $revision            This script's RCS/CVS ident string
#
#   Returns:        Doesn't. This is the end of the line, bub.
#
###############################################################################
sub error_splash
{
    my ($title, @err_text) = @_;

    write_log_line($logfile, sprintf("%s [$$] Internal script error: $title",
                                     scalar localtime));
    print $Q->header(-pragma => 'no-cache');
    print $Q->start_html(-title => $title);
    print $Q->h1("Error: $title");
    print $Q->hr;
    print $Q->p("The following error occured:");
    print $Q->p(map { $Q->tt($_), $Q->br } @err_text);
    print $Q->hr;
    print $Q->font({ -size => -1 }, "$revision, on ", scalar localtime);
    print $Q->end_html;

    croak "@err_text,";
    exit -1; # Just in case croak() was overloaded
}

###############################################################################
#
#   Sub Name:       error_by_http
#
#   Description:    Signify an error via HTTP response code rather than by
#                   an HTML page. Needed for non-interactive user agents
#                   such as the release management tools.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $text     in      scalar    Textual message to go with code
#                   $code     in      scalar    If passed, use this instead of
#                                                 the default (408)
#
#   Globals:        $logfile
#                   $Q                   The top-level global query object
#
#   Environment:    None.
#
#   Returns:        exits
#
###############################################################################
sub error_by_http
{
    my ($text, $code) = @_;

    $code = '408' unless (defined $code and $code);
    write_log_line($logfile, sprintf("%s [$$] Internal script error: $text",
                                     scalar localtime));

    print $Q->header(-pragma => 'no-cache',
                     -status => "$code $text");

    exit;
}

###############################################################################
#
#   Sub Name:       primary_form
#
#   Description:    Create the main page for user input/interface
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $user     in      scalar    Authenticated user name
#
#   Globals:        $Q
#                   $cmd
#                   $revision
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub primary_form
{
    my $user = shift;

    # This returns a list of the projects that the validated user can upload to
    my ($projects, $emails) = read_user_config $user;
    # This sequence number is tagged on to keep Netscape caching from choking
    my $seq = $Q->path_info =~ /(\d+)/o; $seq++;

    #
    # A project value of "*" is used to note that the user ID can upload
    # to any top-level. This should only be used for the ID that manages
    # mirror propagation, so don't include it on a form.
    #
    my @projects = grep($_ ne '*', @$projects);

    #
    # Basic start-of-HTML-page stuff
    #
    print $Q->header(-expires => '+8h');
    print $Q->start_html(-title => 'Main upload form for external developers');
    print $Q->center($Q->h1('External Development Group Upload Facility'),
                     $Q->hr({ -width => '80%', -size => '3' }));
    print $Q->p("Upload to server ", $Q->server_name,
                " for group/user $user:");
    #
    # Start a MIME-compliant multipart/mixed form
    #
    print $Q->start_multipart_form(-action => $Q->script_name . "/$seq");
    print $Q->table({ -border => 2, -cellpadding => 4, -width => '100%' },
                    # Project selection
                    $Q->TR({ -valign => 'middle' },
                           $Q->td({ -width => '25%' },
                                  $Q->b('Select into which area to upload:')),
                           $Q->td($Q->popup_menu(-name => 'project',
                                                 '-values' => \@projects,
                                                 -default => '-'))),
                    # File upload box
                    $Q->TR({ -valign => 'middle' },
                           $Q->td({ -width => '25%' },
                                  $Q->b('Upload which file:')),
                           $Q->td($Q->filefield(-name => 'input_file',
                                                -size => 40,
                                                -maxlength => 256))),
                    # Additional e-mail addresses to notify
                    $Q->TR({ -valgin => 'middle' },
                           $Q->td({ -width => '25%' },
                                  $Q->b('E-mail address(es) to notify upon ',
                                        'successful deployment (optional):')),
                           $Q->td($Q->textfield(-name => 'email',
                                                -size => 40,
                                                -maxlength => 80))));
    #
    # Send the e-mail and projects lists from the configuration file as
    # hidden elements within the encoding. The process routine can check for
    # their existance and possibly skip the step of reading the config
    #
    print $Q->hidden(-name => 'email_default', '-values' => $emails)
        if (scalar(@$emails) != 0);
    print $Q->hidden(-name => 'projects_default', '-values' => $projects);
    print $Q->p();
    # Submit and reset buttons
    print $Q->table({ -border => 0, -width => '100%' },
                    $Q->TR($Q->td($Q->submit(-name => 'submit',
                                             -value => 'Submit'), $Q->br,
                                  "this information"),
                           $Q->td({ -align => 'right' },
                                  $Q->reset, $Q->br, "this form")));
    print $Q->endform;
    print $Q->br, $Q->hr;
    print $Q->p($Q->font({ -size => -1 },
                         "$revision, on " . scalar localtime));
    print $Q->end_html;

    1;
}

###############################################################################
#
#   Sub Name:       process_form
#
#   Description:    Process the data from the primary form
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $user     in      scalar    Authenticated user ID
#
#   Globals:        $Q
#                   $revision
#                   %config
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0
#
###############################################################################
sub process_form
{
    my $user = shift;

    #
    # Delay the loading/compiling of this code so as not to slow down the
    # form posting. Plus, since it's a class that doesn't export anything,
    # it works fine with require.
    #
    require IMS::ReleaseMgr;

    my $file       = $Q->param('input_file');
    my $mail       = $Q->param('email')      || '';
    my $proj       = $Q->param('project')    || undef;
    my $compressed = $Q->param('compressed') || 'no';
    my (@projects, @emails, $p, $e, %extra_opts, $no_upload);
    my $DEBUG      = 1;

    if (defined($p = $Q->param('projects_default')) and ref $p)
    {
        $e = $Q->param('email_default');
        $e = [$e] unless ref $e;
    }
    else
    {
        #
        # Might as well read both while we're at it
        #
        ($p, $e) = read_user_config $user;
    }
    @projects = @$p;
    @emails   = @$e;

    unless (defined $file and defined $proj)
    {
        if ($running_under_browser)
        {
            error_splash('Missing required fields in form',
                         'Both the file and the project/topic fields must ',
                         'be filled in.');
        }
        else
        {
            error_by_http('Missing one or both required form fields');
        }
    }

    if (@projects)
    {
        unless (grep(/^(\Q$proj\E|\*)$/o, @projects))
        {
            if ($running_under_browser)
            {
                error_splash('User not authorized',
                             "$user is not authorized to release to $proj.");
            }
            else
            {
                error_by_http("$user not authorized for release to $proj");
            }
        }
    }
    else
    {
        if ($running_under_browser)
        {
            error_splash 'No project list found',
                "User $user does not appear to have any projects authorized.";
        }
        else
        {
            error_by_http("$user has no list of authorized projects");
        }
    }

    #
    # Massage the e-mail field and merge in any defaults
    #
    if (defined $mail and $mail)
    {
        $mail =~ tr/, /,/;
        push(@emails, split(/,/, $mail));
    }

    my $temp_file = "/tmp/$cmd-$$-upl";
    my $fh = new IO::File "> $temp_file";
    my $size = 4096;
    my $buf = '';
    for (;;)
    {
        my ($r, $w, $t);

        $r = sysread($file, $buf, $size);
        last unless $r;
        for ($w = 0; $w < $r; $w += $t)
        {
            $t = syswrite($fh, $buf, $r - $w, $w);
        }
    }
    $fh->close;

    #
    # Important new step: There will be parameters passed in that didn't
    # require special attention, so they haven't been dealt with yet. Rather
    # than hard-code such a list, delete the known parameters and build a
    # hash table from the remaining ones (or at least those with scalar values)
    #
    %extra_opts = ();
    grep($Q->delete($_), qw(input_file project email compressed));
    for ($Q->param())
    {
        # Skip list-based items
        next if ref($e = $Q->param($_));
        $extra_opts{$_} = $e;
    }

    my $package = new IMS::ReleaseMgr(name => $proj,
                                      directory => $config{incoming_dir},
                                      email => join(',', @emails),
                                      compressed => $compressed,
                                      %extra_opts,
                                      file => $temp_file);
    if (! defined $package)
    {
        if ($running_under_browser)
        {
            error_splash('Unable to initialize upload package handler',
                         'The IMS::ReleaseMgr system was unable to process ',
                         'the input data.');
        }
        else
        {
            error_by_http('Error initializing input data at line ' . __LINE__);
        }
    }
    write_log_line $logfile,
        sprintf("%s [$$] Started for project $proj, user $user",
                scalar localtime);

    if (! defined $package->validate)
    {
        my ($err, $file, $line) = $package->error;
        $package->abort;

        if ($running_under_browser)
        {
            error_splash 'Insecure archive contents detected',
                "The following error was detected at $file, line $line:",
                $Q->code($err);
        }
        else
        {
            error_by_http('Insecure content detected in upload data');
        }
    }

    $no_upload = $Q->param('noupload') || 0;
    if (! $package->commit(noupload => $no_upload))
    {
        my ($err, $file, $line) = $package->error;
        $package->abort;
        if ($running_under_browser)
        {
            error_splash 'Error committing archive contents',
                "The following error occurred at $file, line $line, while ",
                'committing to disk:', $Q->code($err);
        }
        else
        {
            error_by_http("Error committing to disk: $err");
        }
    }

    #
    # Successfully processed
    #
    my $outfile = $package->{tarfile};
    my $rlstkt  = $package->{infofile};
    if (defined $DEBUG and $DEBUG)
    {
        write_log_line $logfile,
            sprintf("%s [$$] --> Archive file: %s (%d bytes)",
                    scalar localtime, $outfile, (stat $outfile)[7]),
            sprintf("%s [$$] --> Manager file: %s (%d bytes)",
                    scalar localtime, $rlstkt, (stat $rlstkt)[7]);
    }
    $package->close;
    undef $package; # Force destructor now, rather than at exit

    if ($running_under_browser)
    {
        print $Q->header(-pragma => 'no-cache');
        print $Q->start_html(-title => 'Upload successful');
        print $Q->center($Q->h1('Package Upload Successfully Processed'),
                         $Q->hr({ -width => '80%', -size => 4 }));
        print $Q->table({ -border => 0, -cellpadding => 4 },
                        $Q->TR({ -valign => '25%' },
                               $Q->td({ -width => '25%', -align => 'right' },
                                      $Q->b('File:')),
                               $Q->td($Q->code($Q->param('input_file')))),
                        $Q->TR({ -valign => '25%' },
                               $Q->td({ -width => '25%', -align => 'right' },
                                      $Q->b('Saved as:')),
                               $Q->td($Q->code($outfile))),
                        $Q->TR({ -valign => '25%' },
                               $Q->td({ -width => '25%', -align => 'right' },
                                      $Q->b('Release manager ticket file:')),
                               $Q->td($Q->code($rlstkt))),
                        $Q->TR({ -valign => '25%' },
                               $Q->td({ -width => '25%', -align => 'right' },
                                      $Q->b('Uploaded to:')),
                               $Q->td($Q->code($proj))),
                        ((scalar @emails) ?
                         $Q->TR({ -valign => '25%' },
                                $Q->td({ -width => '25%', -align => 'right' },
                                       $Q->b('Notification to:')),
                                $Q->td($Q->code(join(', ', sort @emails)))) :
                         $Q->TR($Q->td({ -align => 'center', -colspan => 2 },
                                       $Q->i('No e-mail address specified ',
                                             'for notification')))));
        print $Q->p();
        print $Q->br, $Q->hr;
        print $Q->p($Q->font({ -size => -1 },
                             "$revision, on " . scalar localtime));
        print $Q->end_html;
    }
    else
    {
        print $Q->header(-pragma        => 'no-cache',
                         -status        => '200 Upload successful',
                         -X_upload_to   => $proj,
                         -X_upload_file => $outfile,
                         -X_upload_info => $rlstkt,
                         -X_processed   => $revision);
    }

    unlink $temp_file;
    write_log_line $logfile,
        sprintf("%s [$$] Finished", scalar localtime);
    1;
}

###############################################################################
#
#   Sub Name:       read_user_config
#
#   Description:    Read the configuration file that identifies which projects
#                   the specified user is permitted to release to. Return that
#                   list, or undef. If the file cannot be found in the same
#                   directory as this script, it is expected to be specified in
#                   an input param called "config_file".
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $user     in      scalar    Authenticated user name.
#
#   Globals:        $config_dir
#                   $config_file
#
#   Environment:    None.
#
#   Returns:        Success:    list
#                   Failure:    undef
#
###############################################################################
sub read_user_config
{
    my $user = shift;

    my ($file, $fh, @lines, $name, $proj, $email, @projs, @emails);

    $file = "$config_dir/$config_file";
    if (-e $file)
    {
        $fh = new IO::File "< $file";
        if (! defined $fh)
        {
            if ($running_under_browser)
            {
                error_splash('Could not open file',
                             "Error opening $file for reading:", "$!");
            }
            else
            {
                error_by_http('Failed to open user config file');
            }
        }
    }
    else
    {
        if ($running_under_browser)
        {
            error_splash 'No configuration file',
                'No configuration file found in ' . $config_dir;
        }
        else
        {
            error_by_http('No user configuration file found');
        }
    }

    @lines = grep(/^\Q$user\E:/, <$fh>);
    if ($#lines == -1)
    {
        if ($running_under_browser)
        {
            error_splash 'No projects found for user',
                "No projects were found for ``$user'' in the config file.";
        }
        else
        {
            error_by_http("No projects found for $user to release to");
        }
    }
    @projs = @emails = ();
    for (@lines)
    {
        chomp;
        ($name, $proj, $email) = split(/:/);
        push(@projs, split(/,/, $proj));
        push(@emails, split(/,/, $email)) if (defined $email and $email);
    }

    #
    # Return two list references
    #
    ([@projs], [@emails]);
}
