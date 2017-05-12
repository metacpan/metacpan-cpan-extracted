###############################################################################
#
#         May be distributed under the terms of the artistic license
#
#                  Copyright @ 1998, Hewlett-Packard, Inc.,
#                            All Rights Reserved
#
###############################################################################
#
#   @(#)$Id: Transfer.pm,v 1.12 2000/02/24 02:04:42 idsweb Exp $
#
#   Description:    Package up the actual transfer mechanism by which released
#                   pacakges are moved around between machines. Currently only
#                   supports the HTTP upload mechanism, but will act as a good
#                   abstraction layer if FTP is ever to be supported.
#
#   Functions:      mirror_upload
#                   ftp_upload
#                   ftp_error
#                   send_and_expect
#
#   Libraries:      IMS::ReleaseMgr::Utils
#                   LWP::UserAgent
#                   HTTP::Request::Common
#                   URI::URL
#
#   Global Consts:  $VERSION            Version information for this module
#                   $revision           Copy of the RCS revision string
#
#   Environment:    None.
#
###############################################################################
package IMS::ReleaseMgr::Transfer;

use 5.004;
use strict;
use subs qw(mirror_upload ftp_upload ftp_error send_and_expect);
use vars qw($VERSION $revision @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
            @ftp_error);
use Carp;
use Cwd 'cwd';
use AutoLoader 'AUTOLOAD';
use Symbol 'gensym';
require Exporter;

use IMS::ReleaseMgr::Utils qw(write_log_line send_mail);
use LWP::UserAgent;
use HTTP::Request::Common  qw(POST $DYNAMIC_FILE_UPLOAD);
use URI::URL;

$VERSION = do {my @r=(q$Revision: 1.12 $=~/\d+/g);sprintf "%d."."%02d"x$#r,@r};
$revision = q{$Id: Transfer.pm,v 1.12 2000/02/24 02:04:42 idsweb Exp $ };

@ISA         = qw(Exporter);
@EXPORT      = qw(mirror_upload ftp_upload ftp_error);
@EXPORT_OK   = qw(mirror_upload ftp_upload ftp_error);
%EXPORT_TAGS = ('ftp' => [qw(ftp_upload ftp_error)]);

1;

###############################################################################
#
#   Sub Name:       ftp_upload
#
#   Description:    Transfer a package using an automated FTP session
#
#                   8/1/99: It's time to make the API to this routine match
#                   that of the mirror_upload() routine more closely. This is
#                   now going to be used for more than just backwards-
#                   compatibility with www.hp.com.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $tarfile  in      scalar    Filename for the tar archive
#                   $infofile in      scalar    Filename for the ticket file
#                   $thishost in      scalar    The name this host goes by in
#                                                 mirror terms
#                   $host     in      scalar    Host to FTP to.
#                   $ftp_program  in  scalar    path to socksified ftp program
#                   $config   in      hashref   The relevant host config
#                                                 block for the mirror group
#                   $tarfile_remote  in      scalar    Remote filename for the tar archive (optional)
#                   $infofile_remote in      scalar    Remote filename for the ticket file (optional)
#
#                   Note that this routine does not use the %info block, as
#                   the info file has to already physically exist. That also
#                   means that the caller is responsible for setting the
#                   "upload" and "transfer method" settings correctly.
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0, error text retrievable via ftp_error()
#
###############################################################################
sub ftp_upload
{
    my ($tarfile, $infofile, $thishost, $host, $ftp_program, $config, 
	$tarfile_remote, $infofile_remote) = @_;

    use IPC::Open3;

    my ($user, $password, $ftp_pid, $ftp, $reply, $send, $recv, $perr,
        $xfer_dir, $trace, $tfile, $cmd, $ver, $cwd, $DIR, $TAR, $INFO,%REMOTE);

    # Don't mirror to ourselves
    return 1 if ($host eq $thishost);

    $trace = $main::trace || 0;
    $tfile = $main::tfile || '-';
    $cmd   = $main::cmd   || ($0 =~ m|(.*)/(.*)$|o)[1];
    $ver   = (defined $main::VERSION) ? "/$main::VERSION" : '';
    write_log_line($tfile, "$cmd [$$] FTP-based mirroring to $host")
        if ($trace);

    $user     = $config->{FTP_USER};
    $password = $config->{FTP_PASSWD};
    $ftp      = $ftp_program || $ENV{FTP} || '/opt/ims/bin/ftp';
    $xfer_dir = $config->{FTP_DIR} || $config->{INCOMING_DIR} || undef;

    unless ($user and $password)
    {
        ftp_error('One of the user name, password or host was not configured');
        return 0;
    }

    $cwd = cwd;
    ($DIR, $TAR) = $tarfile =~ m|^(.*)/(.*)$|;
    $REMOTE{$TAR} = ($tarfile_remote =~ m|^(.*)/(.*)$|)[1] || $TAR;
    $INFO = ($infofile =~ m|^(.*)/(.*)$|)[1];
    $REMOTE{$INFO} = ($infofile_remote =~ m|^(.*)/(.*)$|)[1] || $INFO;
    chdir $DIR;

    #
    # Create filehandle-usable objects for the open3 call:
    #
    ($send, $recv, $perr) = (gensym, gensym, gensym);

    $@ = '';   # Clear out before the eval
    eval { $ftp_pid = open3($send, $recv, $perr, "$ftp -v -n") };

    if ($@)
    {
        ftp_error("Error from open of ftp command: $@");
        return 0;
    }

    write_log_line($tfile,
                   sprintf("$cmd [$$] [%s] Attempting ftp mirror to $host",
                           scalar localtime time))
        if ($trace & 2); # bxxxxxx1x

    #
    # Connect to the target host
    #
    $reply = send_and_expect($send, $recv,
                             "open $host\n",
                             '^([245]\d\d )|(.*(unknown)|(refused))');
    if ($reply !~ /^2/)
    {
        ftp_error("Unable to open host '$host': $reply");
        print $send "quit\n";
        close $send;
        close $recv;
        close $perr;
        waitpid($ftp_pid, 0);
        return 0;
    }

    #
    # Log in using the username and password passed in the configuration
    #
    $reply = send_and_expect($send, $recv,
                             "user $user $password\n", '^[245]\d\d ');
    if ($reply !~ /^2/)
    {
        ftp_error("Unable to login as $user to $host: $reply");
        print $send "quit\n";
        close $send;
        close $recv;
        close $perr;
        waitpid($ftp_pid, 0);
        return 0;
    }

    #
    # Ensure that we transfer in binary mode
    #
    $reply = send_and_expect($send, $recv, "binary\n", '^200 ');

    #
    # The FTP session is now established. We have three commands to
    # execute: A cd (change dir), put the tarfile, and put the infofile.
    # The cd command may not be needed.
    #
    if (defined $xfer_dir and $xfer_dir)
    {
        $reply = send_and_expect($send, $recv,
                                 "cd $xfer_dir\n", '^[245]\d\d ');
        if ($reply !~ /^2/)
        {
            ftp_error("Unable to cd to $xfer_dir on $host: $reply");
            print $send "quit\n";
            close $send;
            close $recv;
            close $perr;
            waitpid($ftp_pid, 0);
            return 0;
        }
    }

    #
    # Send the files. Send the tarfile first, as a large-enough tarfile
    # could take just long enough to transfer for the release manager on
    # the other end to see the infofile and commence processing before
    # we've actually finished transferring the content.
    #
    # I speak from experience.
    #
    for my $file ($TAR, $INFO)
    {
        $reply = send_and_expect($send, $recv,
                                 "put $file $REMOTE{$file}.LCK\n", '^[245]\d\d ');
        if ($reply !~ /^2/)
        {
            ftp_error('Error sending file to remote host',
                      "Unable to transfer $file to $host: $reply");
            print $send "quit\n";
            close $send;
            close $recv;
            close $perr;
            waitpid($ftp_pid, 0);
            return 0;
        }
        
        # Give it a bit to clear buffers
        sleep 2;

        $reply = send_and_expect($send, $recv,
                                 "rename $REMOTE{$file}.LCK $REMOTE{$file}\n", '^[245]\d\d ');
        if ($reply !~ /^2/)
        {
            ftp_error('Error sending file to remote host',
                      "Unable to transfer $file to $host: $reply");
            print $send "quit\n";
            close $send;
            close $recv;
            close $perr;
            waitpid($ftp_pid, 0);
            return 0;
        }
    }

    # Give it a bit to clear buffers
    sleep 2;
    $reply = send_and_expect($send, $recv, "close\n", '^[245]\d\d ');
    print $send "quit\n";
    close $send;
    close $recv;
    close $perr;
    waitpid($ftp_pid, 0);

    chdir $cwd;
    1;
}

###############################################################################
#
#   Sub Name:       ftp_error
#
#   Description:    Set/return error text from an ftp attempt
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   @text     in      list      If passed, new text for error
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        void or error text, depending on context
#
###############################################################################
sub ftp_error
{
    my @text = @_;

    if (defined $text[0] and $text[0])
    {
        #
        # Set error text and return a void context
        #
        @IMS::ReleaseMgr::Transfer::ftp_error = @text;
        return;
    }
    else
    {
        return @IMS::ReleaseMgr::Transfer::ftp_error;
    }
}

###############################################################################
#
#   Sub Name:       send_and_expect
#
#   Description:    Send the string $send out along $ofh and wait for a pattern
#                   matching $expect to come in on $ifh.
#
#                   Perl 5.005 will give us regex's as first-class object, and
#                   usage of $expect will become much simpler then.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $ofh      in      globref   Output FH (writer)
#                   $ifh      in      globref   Input FH (reader)
#                   $send     in      scalar    Text to write to $ofh
#                   $expect   in      scalar    Pattern to look for on $ifh
#                   $debug    in      scalar    Flag that tells whether to
#                                                 do any debug output to STDERR
#
#   Globals:        None.
#
#   Environment:    None.
#
#   Returns:        Success:    the text line matched by $expect
#                   Failure:    dunno-- deadlock loop? undef if EOF reached
#
###############################################################################
sub send_and_expect
{
    my ($ofh, $ifh, $send, $expect, $debug) = @_;

    $debug |= 0; # Force a strict-clean testable value

    print STDERR "> $send" if ($debug and $send !~ /user|pass/);
    print $ofh $send;

    my $line;
    while (defined($line = <$ifh>))
    {
        print STDERR "< $line" if $debug;
        return $line if $line =~ /$expect/;
    }

    undef;
}

__END__

###############################################################################
#
#   Sub Name:       mirror_upload
#
#   Description:    Upload a package to the specified hosts using the HTTP
#                   protocol and the relevant bits from the confguration.
#
#   Arguments:      NAME      IN/OUT  TYPE      DESCRIPTION
#                   $file     in      scalar    Full path to file to upload
#                   $project  in      scalar    Name of project that owns this
#                   $thishost in      scalar    Name of the host currently on
#                   $hostlist in      listref   List of hosts to mirror to
#                   $config   in      hashref   Configuration information for
#                                                 this running host/pool
#                   $info     in      hashref   Values from the info file
#
#   Globals:        Looks for $cmd, $hostname, $trace, $tfile
#
#   Environment:    None.
#
#   Returns:        Success:    1
#                   Failure:    0, followed by two listrefs with details
#
###############################################################################
sub mirror_upload
{
    my ($file, $project, $thishost, $hostlist, $config, $info) = @_;

    my (@bad, @err_content, $URI, $UA, $host, $request, $res, $fh, $cmd, %info,
        $trace, $tfile, $email, $MIRROR_RETRIES, $MIRROR_WAIT_PERIOD, $ver);

    $MIRROR_RETRIES     = 3;
    $MIRROR_WAIT_PERIOD = 30;

    $trace = $main::trace || 0;
    $tfile = $main::tfile || '-';
    $cmd   = $main::cmd   || ($0 =~ m|(.*)/(.*)$|o)[1];
    $ver   = (defined $main::VERSION) ? "/$main::VERSION" : '';
    write_log_line($tfile, "$cmd [$$] HTTP-base mirroring starts (@$hostlist)")
        if ($trace);

    #
    # Make a local copy of this so we can delete some of the keys safely
    #
    %info = %{$info};
    $email = $info{email} || '';
    delete $info{email};
    delete $info{project};

    #
    # This prevents a loop -- without it, the package bounces between all
    # servers ad infitum
    #
    $info{upload} = 'no' unless (defined $info{upload});

    #
    # Set to use dyn file uploading for largish files (> 5K)
    #
    $DYNAMIC_FILE_UPLOAD = 1 if ((-s $file) > 5120);
    @bad = (); @err_content = ();
    for $host (@$hostlist)
    {
        # Don't mirror to ourselves
        next if ($host eq $thishost);

        write_log_line($tfile,
                       sprintf("$cmd [$$] [%s] Attempting mirror to $host",
                               scalar localtime time))
            if ($trace & 2); # bxxxxxx1x

        # Creates some kind of magical munging for the URL string given
        $URI = new URI::URL "http://$host$config->{UPLOAD_URL}";
        $UA = new LWP::UserAgent;
        # Set up the user/password for the access realm
        $UA->credentials($URI->netloc,
                         $config->{UPLOAD_REALM},
                         $config->{HTTP_AUTH_USER},
                         $config->{HTTP_AUTH_PASSWD});
        $UA->agent("$cmd$ver " . $UA->agent);
        $UA->proxy('http', $ENV{http_proxy})
            if (defined $ENV{http_proxy} and $ENV{http_proxy});
        # Actual request made to the remote host
        $request = POST($URI,
                        Content_Type => 'form-data',
                        Content => [ project    => $project,
                                     input_file => [$file],
                                     email      => $email,
                                     # Pick up any other ticket file options
                                     %info ]);
        $request->authorization_basic($config->{HTTP_AUTH_USER},
                                      $config->{HTTP_AUTH_PASSWD});
        # Make sure we have a content length
        unless (defined $request->content_length)
        {
            my $code = $request->content;

            # create anonymous temporary file
            my $tmpfile = "/tmp/form-data-content-$$";
            $fh = gensym;
            unless (open($fh, "+>$tmpfile"))
            {
                write_log_line($tfile,
                               sprintf("$cmd [$$] [%s] Cannot create " .
                                       "$tmpfile: $!",
                                       scalar localtime time))
                    if ($trace);
                write_log_line("$config->{LOGGING_DIR}/$cmd",
                               sprintf("%s [$$] Cannot create $tmpfile: $!",
                               scalar localtime time));
                die "Can't create $tmpfile: $!";
            }
            unless (unlink($tmpfile))
            {
                write_log_line($tfile,
                               sprintf("$cmd [$$] [%s] Cannot unlink " .
                                       "$tmpfile: $!",
                                       scalar localtime time))
                    if ($trace);
                write_log_line("$config->{LOGGING_DIR}/$cmd",
                               sprintf("%s [$$] Cannot unlink $tmpfile: $!",
                               scalar localtime time));
                die "Can't unlink $tmpfile";
            }

            # fill it with data
            my $chunk;
            my $size = 0;
            while (defined($chunk = &$code) && length($chunk))
            {
                print $fh $chunk;
                $size += length($chunk);
            }
            unless (seek($fh, 0, 0))
            {
                write_log_line($tfile,
                               sprintf("$cmd [$$] [%s] Cannot rewind: $! ",
                                       scalar localtime time))
                    if ($trace);
                write_log_line("$config->{LOGGING_DIR}/$cmd",
                               sprintf("%s [$$] Cannot rewind: $!",
                               scalar localtime time));
                die "Can't rewind: $!";
            }

            # Update request
            $request->content_length($size);

            # Update content as a closure that reads the file back
            $request->content(sub {
                                  my $buf = "";
                                  my $n = read($fh, $buf, 1024);
                                  unless (length $buf)
                                  {
                                      seek($fh, 0, 0);
                                  }
                                  $buf;
                              });
        }

        #
        # Make $MIRROR_RETRIES attempts at mirroring this package. If there is
        # an error, wait for a period of $MIRROR_WAIT_PERIOD seconds and try
        # again. Drop out of the loop as soon as we have a success.
        #
        for my $loop (1 .. $MIRROR_RETRIES)
        {
            $res = $UA->simple_request($request);
            last if $res->is_success;
            # Sleep unless we're on the last iteration of the loop
            sleep $MIRROR_WAIT_PERIOD unless ($loop == $MIRROR_RETRIES);
        }
        if ($res->is_error)
        {
            #
            # Some sort of an error occured. We don't want to drop out just
            # yet, because there may be more hosts yet to process. So keep a
            # pair of lists with the failed host and corresponding error
            # message. We'll report it all after the loop.
            #
            push(@bad, $host);
            push(@err_content, $res->message);
            if ($trace)
            {
                my @content = Text::Wrap::wrap('', '', $res->status_line);
                send_mail 'randyr@nafohq.hp.com',
                    "Mirror error to $host", [@content];
            }
        }
        else
        {
            write_log_line($tfile,
                           sprintf("$cmd [$$] [%s] Package propagated to " .
                                   "$host", (scalar localtime time)))
                if ($trace & 2);
            write_log_line("$config->{LOGGING_DIR}/$cmd",
                           sprintf("%s [$$] Package propagated to $host",
                                   scalar localtime time));
        }
    }

    return (wantarray) ? (0, \@bad, \@err_content) : 0
        if (scalar @bad);
    1;
}

=head1 NAME

IMS::ReleaseMgr::Transfer - Encapsulate physical transport of packages.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Randy J. Ray <randyr@nafohq.hp.com>

=head1 SEE ALSO

L<IMS::ReleaseMgr>, perl(1).

=cut
