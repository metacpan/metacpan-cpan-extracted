package XAS::Lib::Batch::Interface::Torque;

our $VERSION = '0.01';

use XAS::Constants 'HASHREF ARRAYREF';
use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation trim',
  mixins  => 'do_job_sub do_job_stat do_job_del do_job_sig do_job_hold 
              do_job_rls do_job_move do_job_msg do_job_rerun do_queue_stat 
              do_queue_stop do_queue_start do_server_stat do_server_enable 
              do_server_disable',
  constant => {
    QSUB     => '/usr/bin/qsub',
    QSTAT    => '/usr/bin/qstat',
    QDEL     => '/usr/bin/qdel',
    QSIG     => '/usr/bin/qsig',
    QHOLD    => '/usr/bin/qhold',
    QRLS     => '/usr/bin/qrls',
    QMSG     => '/usr/bin/qmsg',
    QMOVE    => '/usr/bin/qmove',
    QRERUN   => '/usr/bin/qrerun',
    QALTER   => '/usr/bin/qalter',
    QSTOP    => '/usr/bin/qstop',
    QSTART   => '/usr/bin/qstart',
    QENABLE  => '/usr/bin/qenable',
    QDISABLE => '/usr/bin/qdisable',
  },
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub do_job_sub {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);
    
    my $queue = _create_queue($self, $p->{'queue'}, $p->{'host'});
    my $cmd = sprintf('%s -q %s %s', QSUB, $queue, $p->{'jobfile'});

    _create_jobfile($self, $p);

    my $output = $self->do_cmd($cmd, 'qsub');

    return trim($output->[0]);

}

sub do_job_stat {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd = sprintf('%s -f1 %s', QSTAT, $jobid);
    my $output = $self->do_cmd($cmd, 'qstat');
    my $stat = _parse_output($self, $output);

    return $stat->{$p->{'job'}};

}

sub do_job_del {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd;
    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});

    $cmd  = sprintf('%s', QDEL);
    $cmd .= sprintf(' -p') if (defined($p->{'force'}));
    $cmd .= sprintf(' -m "%s"', $p->{'message'}) if (defined($p->{'message'}));
    $cmd .= sprintf(' %s', $jobid);

    my $output = $self->do_cmd($cmd, 'qdel');

    return 1;

}

sub do_job_sig {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd  = sprintf('%s -s %s %s', QSIG, $p->{'signal'}, $jobid);
    my $output = $self->do_cmd($cmd, 'qsig');

    return 1;

}

sub do_job_hold {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd;
    my $hold;
    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});

    foreach my $x (split(DELIMITER, $p->{'type'})) {

        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');

    }

    $cmd  = sprintf('%s -h %s %s', QHOLD, $hold, $jobid);

    my $output = $self->do_cmd($cmd, 'qhold');

    return 1;

}

sub do_job_rls {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd;
    my $hold;
    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});

    foreach my $x (split(DELIMITER, $p->{'type'})) {

        $hold .= 'u' if ($x eq 'user');
        $hold .= 'o' if ($x eq 'other');
        $hold .= 's' if ($x eq 'system');

    }

    $cmd  = sprintf('%s -h %s %s', QRLS, $hold, $jobid);

    my $output = $self->do_cmd($cmd, 'qrls');

    return 1;

}

sub do_job_move {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $queue = _create_queue($self, $p->{'queue'}, $p->{'dhost'});
    my $cmd = sprintf('%s %s %s', QMOVE, $queue, $jobid);
    my $output = $self->do_cmd($cmd, 'qmove');

    return 1;

}

sub do_job_msg {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd  = sprintf('%s -%s "%s" %s', QMSG, $p->{'output'}, $p->{'message'}, $jobid);
    my $output = $self->do_cmd($cmd, 'qmsg');

    return 1;

}

sub do_job_rerun {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $jobid = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $cmd  = sprintf('%s %s', QRERUN, $jobid);
    my $output = $self->do_cmd($cmd, 'qrerun');

    return 1;

}

sub do_job_alter {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd;
    my $after   = _create_after($self, $p->{'after'});
    my $jobid   = _create_jobid($self, $p->{'job'}, $p->{'host'});
    my $outpath = _create_path($self, $p->{'out_path'}, $p->{'host'});
    my $errpath = _create_path($self, $p->{'error_path'}, $p->{'host'});

    $cmd .= sprintf('%s ', QALTER);
    $cmd .= sprintf('-a %s ', $after)            if (defined($p->{'after'}));
    $cmd .= sprintf('-A %s ', $p->{'account'})   if (defined($p->{'account'}));
    $cmd .= sprintf('-e "%s" ', $errpath)        if (defined($p->{'error_path'}));
    $cmd .= sprintf('-h ')                       if (defined($p->{'hold'}));
    $cmd .= sprintf('-l "%s" ', $p->{'resources'}) if (defined($p->{'resources'}));
    $cmd .= sprintf('-m %s ', $p->{'mail_points'}) if (defined($p->{'mail_points'}));
    $cmd .= sprintf('-M "%s" ', $p->{'email'})   if (defined($p->{'email'}));
    $cmd .= sprintf('-n ')                       if (defined($p->{'exclusive'}));
    $cmd .= sprintf('-N %s ', $p->{'jobname'})   if (defined($p->{'jobname'}));
    $cmd .= sprintf('-o "%s" ', $outpath)        if (defined($p->{'out_path'}));
    $cmd .= sprintf('-p %s ', $p->{'priority'})  if (defined($p->{'priority'}));
    $cmd .= sprintf('-r %s ', $p->{'rerunable'}) if (defined($p->{'rerunnable'}));
    $cmd .= sprintf('-S "%s" ', $p->{'shell_path'}) if (defined($p->{'shell_path'}));
    $cmd .= sprintf('-u "%s" ', $p->{'user'})    if (defined($p->{'user'}));
    $cmd .= sprintf('-W "%s" ', $p->{'attributes'}) if (defined($p->{'attributes'}));
    $cmd .= sprintf('%s', $jobid);

    my $output = $self->do_cmd($cmd, 'qalter');

    return 1;

}

sub do_queue_stat {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $queue = _create_queue($self, $p->{'queue'}, $p->{'host'});
    my $cmd = sprintf('%s -Q -f1 %s', QSTAT, $queue);
    my $output = $self->do_cmd($cmd, 'qstat');
    my $stat = _parse_output($self, $output);

    return $stat;

}

sub do_queue_stop {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $queue = _create_queue($self, $p->{'queue'}, $p->{'host'});
    my $cmd = sprintf('%s -Q -f1 %s', QSTOP, $queue);
    my $output = $self->do_cmd($cmd, 'qstop');
    my $stat = _parse_output($self, $output);

    return $stat;

}

sub do_queue_start {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $queue = _create_queue($self, $p->{'queue'}, $p->{'host'});
    my $cmd = sprintf('%s -Q -f1 %s', QSTART, $queue);
    my $output = $self->do_cmd($cmd, 'qstart');
    my $stat = _parse_output($self, $output);

    return $stat;

}

sub do_server_stat {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $cmd = sprintf('%s -B -f1 %s', QSTAT, $p->{'host'});
    my $output = $self->do_cmd($cmd, 'qstat');
    my $stat = _parse_output($self, $output);

    return $stat;

}

sub do_server_disable {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $queue = _create_queue($self, $p->{'queue'}, $p->{'host'});
    my $cmd = sprintf('%s %s', QDISABLE, $queue);
    my $output = $self->do_cmd($cmd, 'qdisable');
    my $stat = _parse_output($self, $output);

    return $stat;

}

sub do_server_enable {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $queue = _create_queue($self, $p->{'queue'}, $p->{'host'});
    my $cmd = sprintf('%s %s', QENABLE, $queue);
    my $output = $self->do_cmd($cmd, 'qenable');
    my $stat = _parse_output($self, $output);

    return $stat;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _create_jobid {
    my $self = shift;
    my ($id, $host) = validate_params(\@_, [
        1,
        { optional => 1, default => undef }
    ]);

    my $jobid;

    if (defined($host)) {

        $jobid = sprintf("%s\@%s", $id, $host);

    } else {

        $jobid = $id;

    }

    return $jobid;

}

sub _create_queue {
    my $self = shift;
    my ($queue, $host) = validate_params(\@_, [
        { optional => 1, default => undef },
        { optional => 1, default => undef },
    ]);

    my $que;

    if (defined($host) && defined($queue)) {

        $que = sprintf("%s\@%s", $queue, $host);

    } elsif (defined($host)) {

        $que = sprintf("@%s", $host);

    } else {

        $que = $queue || '';

    }

    return $que;

}

sub _create_path {
    my $self = shift;
    my $path = shift || undef;
    my $host = shift || undef;

    my $fqpath;

    if (defined($host)) {

        $fqpath = sprintf("%s:%s", $host, $path);

    } else {

        $fqpath = $path;

    }

    return $fqpath;

}

sub _create_after {
    my $self = shift;
    my $after = shift || undef;

    if (defined($after)) {

        $after = $after->strftime('%Y%m%d%H%M');

    }

    return $after;

}

sub _parse_output {
    my $self = shift;
    my ($output) = validate_params(\@_, [
        { type => ARRAYREF }
    ]);

    my $id;
    my $stat;

    foreach my $line (@$output) {

        next if ($line eq '');

        $line = trim($line);

        if ($line =~ /^Job Id/) {

            ($id) = ($line =~ m/^Job Id\:\s(.*)/);
            $id = trim($id);
            next;

        }

        if ($line =~ /^Queue/) {

            ($id) = ($line =~ m/^Queue\:\s(.*)/);
            $id = trim($id);
            next;

        }

        if ($line =~ /^Server/) {

            ($id) = ($line =~ m/^Server\:\s(.*)/);
            $id = trim($id);
            next;

        }

        next if (index($line, '=') < 0);

        my ($key, $value) = split('=', $line, 2);

        $key = trim(lc($key));
        $key =~ s/\./_/;

        $stat->{$id}->{$key} = trim($value);

    }

    return $stat;

}

sub _create_jobfile {
    my $self = shift;
    my ($p) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    my $job = $p->{'jobfile'};
    my $fh  = $job->open('w');
    my $after   = _create_after($self, $p->{'after'});
    my $logfile = _create_path($self, $p->{'logfile'}, $p->{'host'});

    $fh->printf("#!/bin/sh\n");
    $fh->printf("#\n");
    $fh->printf("#PBS -N \"%s\"\n", $p->{'jobname'});
    $fh->printf("#PBS -j \"%s\"\n", $p->{'join_path'});
    $fh->printf("#PBS -e \"%s\"\n", $logfile);
    $fh->printf("#PBS -o \"%s\"\n", $logfile);
    $fh->printf("#PBS -m \"%s\"\n", $p->{'mail_points'});
    $fh->printf("#PBS -M \"%s\"\n", $p->{'email'});
    $fh->printf("#PBS -S \"%s\"\n", $p->{'shell_path'});
    $fh->printf("#PBS -w %s\n", $p->{'work_path'});
    $fh->printf("#PBS -d %s\n", $p->{'work_path'});
    $fh->printf("#PBS -p %s\n", $p->{'priority'});
    $fh->printf("#PBS -r %s\n", $p->{'rerunable'});
    $fh->printf("#PBS -u \"%s\"\n", $p->{'user'}) if (defined($p->{'user'}));
    $fh->printf("#PBS -A %s\n", $p->{'account'}) if (defined($p->{'account'}));
    $fh->printf("#PBS -a %s\n", $after) if (defined($p->{'after'}));
    $fh->printf("#PBS -l \"%s\"\n", $p->{'resources'}) if (defined($p->{'resources'}));
    $fh->printf("#PBS -W \"%s\"\n", $p->{'attributes'}) if (defined($p->{'attributes'}));
    $fh->printf("#PBS -v \"%s\"\n", $p->{'environment'}) if (defined($p->{'environment'}));
    $fh->printf("#PBS -n \n") if (defined($p->{'exclusive'}));
    $fh->printf("#PBS -h \n") if (defined($p->{'hold'}));
    $fh->printf("#PBS -V \n") if (defined($p->{'env_export'}));
    $fh->printf("#\n");
    $fh->printf("%s\n", $p->{'command'});
    $fh->printf("#\n");
    $fh->printf("exit \$?\n");

    $fh->close;

}

1;

__END__

=head1 NAME

XAS::Lib::Batch::Interface::Torque - A mixin for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   debug   => 0,
   version => '0.01',
   base    => 'XAS::Lib::Batch',
   mixin   => 'XAS::Lib::Batch::Interface::Torque'
;

=head1 DESCRIPTION

In the Unix world, there is a standardized interface for Batch Systems. In
honor of this standard, each implementation has a slightly different command
line syntax. This mixin implements the PBS/Torque command line. 

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
