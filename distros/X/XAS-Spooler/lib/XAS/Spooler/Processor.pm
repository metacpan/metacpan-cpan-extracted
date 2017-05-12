package XAS::Spooler::Processor;

our $VERSION = '0.02';

use POE;
use Try::Tiny;
use XAS::Factory;
use POE::Component::Cron;
use XAS::Lib::POE::PubSub;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::POE::Service',
  mixin      => 'XAS::Lib::Mixins::Handlers',
  accessors  => 'spooler spooldir cron events',
  mutators   => 'paused',
  filesystem => 'Dir File',
  vars => {
    PARAMS => {
      -queue       => 1,
      -connector   => 1,
      -directory   => 1,
      -packet_type => 1,
      -tasks       => { optional => 1, default => 1 },
      -schedule    => { optional => 1, default => '*/1 * * * *' },
    }
  }
;

# ---------------------------------------------------------------------
# Event Handlers
# ---------------------------------------------------------------------

sub scan {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering scan()");

    try {

        $self->{'files'} = ();

        if (my $dh = $self->spooldir->open) {

            $poe_kernel->post($alias, 'scan_dir', $dh);

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

    $self->log->debug("$alias: leaving scan()");

}

sub scan_dir {
    my ($self, $dh) = @_[OBJECT,ARG0];

    my $alias = $self->alias;
    my $regex = $self->spooler->extension;
    my $pattern = qr/$regex/i;

    $self->log->debug("$alias: entering scan_dir()");

    try {

        unless ($self->paused) {

            if (my $file = $dh->read()) {

                my $temp = File($self->spooldir->path, $file);

                if ($temp->path =~ /$pattern/) {

                    push(@{$self->{'files'}}, $temp);

                }

                $poe_kernel->post($alias, 'scan_dir', $dh);

            } else {

                $poe_kernel->post($alias, 'scan_dir_stop', $dh);

            }

        } else {

            $poe_kernel->post($alias, 'scan_dir_stop', $dh);

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

    $self->log->debug("$alias: leaving scan_dir()");

}

sub scan_dir_stop {
    my ($self, $dh) = @_[OBJECT, ARG0];

    my $alias = $self->alias;
    
    $self->log->debug("$alias: entering scan_dir_stop()");

    try {

        $dh->close();

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };
    
    $self->log->debug("$alias: leaving scan_dir_stop()");

}

sub unlink_file {
    my ($self, $file) = @_[OBJECT,ARG0];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering unlink_file()");

    try {

        my $path = File($self->spooldir, $file);
        $self->log->info_msg('spooler_unlinking', $alias, $path);
        $self->spooler->delete($path);
        
    } catch {

        my $ex = $_;

        $self->log->error_msg('spooler_unexpected', $alias, $ex);

    };

    $poe_kernel->post($alias, 'process_files');

    $self->log->debug("$alias: leaving unlink_file()");

}

sub process_files {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;
    my $queue = $self->queue;
    my $type  = $self->packet_type;
    my $connector = $self->connector;

    $self->log->debug("$alias: entering process_files()");

    $self->{'count'} -= 1;
    $self->{'count'} = 1 if ($self->{'count'} < 0);

    $self->log->debug("$alias: task count: " . $self->{'count'});

    try {

        unless ($self->paused) {

            if (my $file = shift(@{$self->{'files'}})) {

                if ($file->exists) {

                    if (my $data = $self->spooler->read($file)) {

                        $self->log->info_msg('spooler_found', $alias, $file->path);
                        $poe_kernel->post($connector, 'send_packet', $alias, $type, $queue, $data, $file);

                    }

                }

            }

        }

    } catch {

        my $ex = $_;

        $self->exception_handler($ex);

    };

    $self->log->debug("$alias: entering process_files()");

}

sub pause_processing {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering pause_processing");

    unless ($self->paused) {

        $self->log->warn("$alias: pausing processing");

        $poe_kernel->alarm_remove_all();

        if (my $cron = $self->cron) {

            $cron->delete();

        }

        $self->paused(1);

    }

    $self->log->debug("alias: leaving pause_processing()");

}

sub resume_processing {
    my ($self) = $_[OBJECT];

    my $alias = $self->alias;

    $self->log->debug("$alias: entering resume_processing()");

    if ($self->paused) {

        $self->log->warn("$alias: resume processing");

        $self->{'cron'} = POE::Component::Cron->from_cron(
            $self->schedule => $alias => 'scan'
        );

        $self->paused(0);

    }

    $self->log->debug("$alias: leaving resume_processing()");

}

# ---------------------------------------------------------------------
# Public Methods
# ---------------------------------------------------------------------

sub session_initialize {
    my $self = shift;

    my $dir;
    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_initialize()");

    $poe_kernel->state('scan', $self);
    $poe_kernel->state('scan_dir', $self);
    $poe_kernel->state('unlink_file', $self);
    $poe_kernel->state('process_files', $self);
    $poe_kernel->state('scan_dir_stop', $self);
    $poe_kernel->state('pause_processing', $self);
    $poe_kernel->state('resume_processing', $self);

    $dir = Dir($self->directory);

    if ($dir->is_relative) {

        $dir  = Dir($self->env->spool, $self->directory);

    }

    $self->{'spooldir'} = $dir;
    $self->{'spooler'} = XAS::Factory->module(
        spool => {
            -lock      => Dir($self->spooldir, 'locked')->path,
            -directory => $self->spooldir,
        }
    );

    $self->events->subscribe($alias);

    # walk the chain

    $self->SUPER::session_initialize();

    $self->log->debug("$alias: leaving session_initialize()");

}

sub session_startup {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_startup()");

    $self->paused(1);

    # walk the chain

    $self->SUPER::session_startup();

    $self->log->debug("$alias: leaving session_startup()");

}

sub session_idle {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_idle()");
    $self->log->debug("$alias: task count: " . $self->{count});

    if ($self->{'count'} <= $self->tasks) {

        $self->{'count'} += 1;
        $poe_kernel->post($alias, 'process_files');

    }

    # walk the chain

    $self->SUPER::session_idle();

    $self->log->debug("$alias: leaving session_idle()");

}

sub session_pause {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_pause()");

    $self->paused(1);
    $self->{'files'} = ();
    $poe_kernel->alarm_remove_all();

    if (my $cron = $self->cron) {

        $cron->delete();

    }

    # walk the chain

    $self->SUPER::session_pause();

    $self->log->debug("$alias: entering session_pause()");

}

sub session_resume {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_resume()");

    $self->paused(0);
    $self->{'cron'} = POE::Component::Cron->from_cron(
        $self->schedule => $alias => 'scan'
    );

    # walk the chain

    $self->SUPER::session_resume();

    $self->log->debug("$alias: entering session_resume()");

}

sub session_shutdown {
    my $self = shift;

    my $alias = $self->alias;

    $self->log->debug("$alias: entering session_cleanup()");

    $poe_kernel->alarm_remove_all();

    if (my $cron = $self->cron) {

        $cron->delete();

    }

    # walk the chain

    $self->SUPER::session_shutdown();

    $self->log->debug("$alias: leaving session_cleanup()");

}

# ---------------------------------------------------------------------
# Private Methods
# ---------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->{'count'}  = 1;
    $self->{'events'} = XAS::Lib::POE::PubSub->new();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Spooler::Processor - Perl extension for the XAS environment

=head1 SYNOPSIS

  use XAS::Spooler::Processor;

  my $processor = XAS::Spooler::Processor->new(
      -schedule    => '*/1 * * * *',
      -connector   => 'connector',
      -alias       => 'nmon',   
      -directory   => 'nmon',     
      -packet_type => 'nmon-data'
  );

=head1 DESCRIPTION

This module scans a spool directory and process any files that are found. 
Discretionary locking is used to coordinate access to the directory. 
Scheduling uses cron semantics.

=head1 METHODS

=head2 new

This module inherits from L<XAS::Lib::POE::Service|XAS::Lib::POE::Service> and 
takes these additional parameters:

=over 4

=item B<-queue>

The queue to send the messages too.

=item B<-connector>

The alias of the connector session.

=item B<-directory>

The directory to scan. The can be relative to $XAS_SPOOL or a fully
qualified path.

=item B<-packet_type>

The name of the message type. 

=item B<-tasks>

The number of sessions processing the internal queue of messages, defaults to 1 session.

=item B<-schedule>

The schedule used to process items in the spool directory. This uses cron
semantics and defaults to this: '*/1 * * * *'

=back

=head1 PUBLIC EVENTS

=head2 scan(OBJECT)

Starts the directory scan process.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head2 scan_dir(OBJECT)

Reads one file from the directory and queues it to the internal processing
queue.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head2 scan_dir_stop(OBJECT)

Stops the directory scan process.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head2 unlink_file(OBJECT, ARG0)

Removes the unneeded file from the directory.

=over 4

=item B<OBJECT>

The handle for the current self.

=item B<ARG0>

The name of the file to remove.

=back

=head2 process_files(OBJECT)

Removes one file from the internal queue and sends the file contents to the 
connector for processing.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head2 pause_processing(OBJECT)

Pauses proccessing because the connection to the message queue server
is down.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head2 resume_processing(OBJECT)

Resumes processing as the connection to the message queue server
is active.

=over 4

=item B<OBJECT>

The handle for the current self.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Spooler::Connector|XAS::Spooler::Connector>

=item L<XAS::Spooler|XAS::Spooler>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
