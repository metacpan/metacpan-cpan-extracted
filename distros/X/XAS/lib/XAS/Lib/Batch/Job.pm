package XAS::Lib::Batch::Job;

our $VERSION = '0.01';

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::Batch',
  utils      => ':validation',
  filesystem => 'Dir',
  constants  => 'DELIMITER',
  constant => {
    TYPES  => qr/user|other|system|none|,|\s/,
    JTYPES => qr/oe|eo|n|,|\s/,
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub qsub {
    my $self = shift;
    my $p = validate_params(\@_, {
        -jobname => 1,
        -queue   => 1,
        -email   => 1,
        -command => 1,
        -jobfile => { isa => 'Badger::Filesystem::File' },
        -logfile => { isa => 'Badger::Filesystem::File' },
        -rerunable   => { optional => 1, default => 'n' },
        -join_path   => { optional => 1, default => 'oe' },
        -account     => { optional => 1, default => undef },
        -attributes  => { optional => 1, default => undef },
        -environment => { optional => 1, default => undef },
        -env_export  => { optional => 1, default => undef },
        -exclusive   => { optional => 1, default => undef },
        -hold        => { optional => 1, default => undef },
        -resources   => { optional => 1, default => undef },
        -user        => { optional => 1, default => undef },
        -host        => { optional => 1, default => undef },
        -mail_points => { optional => 1, default => 'bea' },
        -after       => { optional => 1, isa => 'DateTime' },
        -shell_path  => { optional => 1, default => '/bin/sh' },
        -work_path   => { optional => 1, isa => 'Badger::Filesystem::Directory', default => Dir('/', 'tmp') },
        -priority    => { optional => 1, default => 0, callbacks => {
            'out of priority range' =>
            sub { $_[0] > -1024 && $_[0] < 1024; },
        }}
    });

    return $self->do_job_sub($p);

}

sub qstat {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    return $self->do_job_stat($p);

}

sub qdel {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job     => 1,
        -host    => { optional => 1, default => undef },
        -force   => { optional => 1, default => undef },
        -message => { optional => 1, default => undef },
    });

    return $self->do_job_del($p);

}

sub qsig {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job    => 1,
        -signal => 1,
        -host   => { optional => 1, default => undef },
    });

    return $self->do_job_sig($p);

}

sub qhold {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    return $self->do_job_hold($p);

}

sub qrls {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job  => 1,
        -type => { regex => TYPES }, 
        -host => { optional => 1, default => undef },
    });

    return $self->do_job_rls($p);

}

sub qmove {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job   => 1,
        -queue => 1,
        -host  => { optional => 1, default => undef },
        -dhost => { optional => 1, default => undef },
    });

    return $self->do_job_move($p);

}

sub qmsg {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job     => 1,
        -message => 1,
        -output  => { regex => /E|O/ },
        -host    => { optional => 1, default => undef },
    });

    return $self->do_job_msg($p);

}

sub qrerun {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job  => 1,
        -host => { optional => 1, default => undef },
    });

    return $self->do_job_rerun($p);

}

sub qalter {
    my $self = shift;
    my $p = validate_params(\@_, {
        -job         => 1,
        -jobname     => { optional => 1, default => undef },
        -rerunable   => { optional => 1, default => undef },
        -email       => { optional => 1, default => undef },
        -account     => { optional => 1, default => undef },
        -attributes  => { optional => 1, default => undef },
        -exclusive   => { optional => 1, default => undef },
        -resources   => { optional => 1, default => undef },
        -user        => { optional => 1, default => undef },
        -host        => { optional => 1, default => undef },
        -mail_points => { optional => 1, default => undef },
        -shell_path  => { optional => 1, default => undef },
        -hold        => { optional => 1, default => undef, regex => TYPES }, 
        -join_path   => { optional => 1, default => undef, regex => JTYPES },
        -after       => { optional => 1, default => undef, isa => 'DateTime' },
        -out_path    => { optional => 1, default => undef, isa => 'Badger::Filesystem::File' },
        -error_path  => { optional => 1, default => undef, isa => 'Badger::Filesystem::File' },
        -priority    => { optional => 1, default => 0, callbacks => {
            'out of priority range' =>
            sub { $_[0] > -1024 && $_[0] < 1024; },
        }}
    });

    return $self->do_job_alter($p);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Batch::Job - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::Batch::Job;

 my $job = XAS::Lib::Batch::Job->new();

 my $id = $job->qsub(...);
 
 printf("job %s has started\n", $id);

 while (my $stat = $job->qstat(-job => $id)) {

     if ($stat->{job_state} eq 'C') {

         printf("job %s has finished\n", $id);

     }

     sleep 10;

 }

=head1 DESCRIPTION

This module provides an interface for manipulating jobs in a Batch System. 
Each available method is a wrapper around a given command. A command line
is built, executed, and the return code is checked. If the return code is
non-zero an exception is thrown. The exception will include the return code
and the first line from stderr.

Since each method is a wrapper, there is a corresponding man page for the 
actual command. They should also be checked when problems arise.

=head1 METHODS

=head2 new

This method initializes the module and takes these parameters:

=over 4

=item B<-interface>

The command line interface to use. This defaults to 'XAS::Lib::Batch::Interface::Torque'.

=back

=head2 qsub(...)

This method will submit a job to the batch system and returns the jobs ID. It 
takes the following parameters:

=over 4

=item B<-jobname>

The name of the job.

=item B<-queue>

The queue to run the job on.

=item B<-email>

The email address to send status reports too. There can be more then one
address or this can be a mailing list.

=item B<-command>

The command to run.

=item B<-jobfile>

The name of the job file to use. This needs to be a Badger::Filesystem::File
object.

=item B<-logfile>

The log file to use. This needs to be a Badger::Filesystem::File object.

=item B<-rerunable>

Wither the job is rerunnable, this is optional and default to no.

=item B<-join_path>

Wither to join stdout and stderr into one log file, this is optional
and defaults to 'oe'.

=item B<-account>

The optional account to run under.

=item B<-attributes>

The optinal attributes that may be applied to this job. This should be a
comma seperated list of name value pairs.

=item B<-environment>

The optional environment variables that may be defined for the job. This
should be a comma sperated list of name value pairs.

=item B<-env_export>

Wither to export the users environment.

=item B<-exclusive>

The option to run this job exclusivily. Default is no.

=item B<-hold> 

The option to submit this job in a hold state.

=item B<-resources>

Optional resources to associate with this job. This should be a comma
seperated list of name value pairs.

=item B<-user>

The optional user account to run this job under.

=item B<-host>

The optional host to run this job on.

=item B<-mail_points>

The optional mail points that the user will be notified at. Defaults to 'bea'.

=item B<-after>

The optional time to run the job after. This must be a DateTime object.

=item B<-shell_path>

The optional path to the jobs shell. Defaults to /bin/sh.

=item B<-work_path>

The optional path to put work files. This must be a Badger::Filesystem::Directory. 
Defaults to /tmp.

=item B<-priority>

The optional priority to run the job at. Defaults to 0.

=back

=head2 qstat(...)

This method returns that status of a job. This status will be a hash reference
of the parsed output on stdout. It takes the following paramters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=back

=head2 qdel(...)

This method will delete a job. It takes the following parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=item B<-force>

Wither to force the jobs deletion. Defaults to no.

=item B<-message>

The optional message to be placed into the log file.

=back

=head2 qsig(...)

This method will send a signal to a job. It takes the following parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=item B<-signal>

The signal to send to the job. 

=back

=head2 qhold(...)

This method will place a job into a hold status. It takes the following 
parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=item B<-type>

The type of hold to place on the job. They can be any of the following:

   user, other, system, none
 
If more then one type is used, they need to be comma seperated.

=back

=head2 qrls(...)

This method will release a job that was placed into a hold status. It takes 
the following parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=item B<-type>

The type of hold to place on the job. They can be any of the following:

   user, other, system, none
 
If more then one type is used, they need to be comma seperated.

=back

=head2 qmove(...)

This method will move a job from one queue to another. That queue may exist on
another host. It takes the following parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-queue>

The queue to move the job too.

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=item B<-dhost>

The optional destination host that the queue is on.

=back

=head2 qmsg(...)

This method will place a message into the log file of a job. It takes
the following parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=item B<-message>

The message to be used.

=item B<-output>

The log to place the message, It can be one of the following:

    E - stderr
    O - stdout

=back

=head2 qrerun(...)

This method will attempt to rerun a job. It takes the following parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=back

=head2 qalter(...)

This method will alter the parameters of a job. It takes the following 
parameters:

=over 4

=item B<-job>

The ID of the job, as returned from submit().

=item B<-host>

The optional host that the job may be running on. Defaults to 'localhost'.

=item B<-jobname>

This will change the jobs name.

=item B<-rerunable>

This will change the jobs rerunable status.

=item B<-email>

This will change the jobs email destinations.

=item B<-account>

This will change the jobs account.

=item B<-attributes>

This will change the optional job attributes.

=item B<-exclusive>

This will change wither the job has exclusive access to the server.

=item B<-resources>

This will change the jobs optional resources.

=item B<-user>

This will change the jobs user.

=item B<-mail_points>

This will change the jobs mail points.

=item B<-shell_path>

This will change the jobs shell.

=item B<-hold>

This will hold the job.

=item B<-join_path>

This will change the jobs join path.

=item B<-after>

This will change the time that job will run after.

=item B<-out_path>

This will changes the jobs output path, it must be a Badger::Filesystem::File object.

=item B<-error_path>

This will changes the jobs error path, it must be a Badger::Filesystem::File object.

=item B<-priority>

This will change the jobs priority.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Batch|XAS::Lib::Batch>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
