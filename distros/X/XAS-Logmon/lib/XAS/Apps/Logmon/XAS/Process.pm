package XAS::Apps::Logmon::XAS::Process;

our $VERSION = '0.01';

use DateTime;
use DateTime::Span;
use XAS::Logmon::Input::Tail;
use XAS::Logmon::Filter::Merge;
use XAS::Logmon::Output::Spool;
use XAS::Logmon::Format::Logstash;
use XAS::Logmon::Parser::XAS::Logs;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App',
  accessors  => 'filename spooldir ignore process',
  utils      => 'dotid trim level2syslog',
  filesystem => 'Dir File',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub reject {
    my $self = shift;
    my $data = shift;

    my $now  = DateTime->now(time_zone => 'local');
    my $span = DateTime::Span->from_datetimes(
        start => $now->clone->subtract(days => $self->ignore),
        end   => $now
    );

    return 0 if ($span->contains($data->{'datetime'}));
    return 1;

}

sub setup {
    my $self = shift;

    unless (defined($self->{'filename'})) {

        $self->throw_msg(
            dotid($self->class) . '.nofilename',
            'logmon_nofilename'
        );

    }

}

sub main {
    my $self = shift;

    $self->setup();

    my $input = XAS::Logmon::Input::Tail->new(
        -filename => $self->filename
    );

    my $output   = XAS::Logmon::Output::Spool->new();
    my $merge    = XAS::Logmon::Filter::Merge->new();
    my $logstash = XAS::Logmon::Format::Logstash->new();
    my $default  = XAS::Logmon::Parser::XAS::Logs->new();
    my $tasks    = XAS::Logmon::Parser::XAS::Logs->new(format => ':tasks');

    while (my $line = $input->get()) {

        $self->log->debug(sprintf("line: %s", $line));

        if (my $data = $tasks->parse($line)) {

            next if ($self->reject($data));

            $self->log->debug("found tasks");

            $data = $merge->filter($data, {
                '@message' => trim($line),
                hostname   => $self->env->host,
                facility   => $self->env->log_facility,
                priority   => level2syslog(lc($data->{'level'})),
                tid        => $data->{'task'},
                pid        => '0',
                msgid      => '0',
                process    => $self->process,
            });

            my $event = $logstash->format($data);

            $output->put($event);

            next;

        }

        if (my $data = $default->parse($line)) {

            next if ($self->reject($data));

            $self->log->debug("found default");

            $data = $merge->filter($data, {
                '@message' => trim($line),
                hostname   => $self->env->host,
                facility   => $self->env->log_facility,
                priority   => level2syslog(lc($data->{'level'})),
                tid        => '0',
                pid        => '0',
                msgid      => '0',
                process    => $self->process,
            });

            my $event = $logstash->format($data);

            $output->put($event);

            next;

        } 

        $self->log->error_msg('logmon_parserr', trim($line));

    }

}

sub options {
    my $self = shift;

    $self->{'ignore'}   = 300;
    $self->{'process'}  = 'xas-spooler';
    $self->{'spooldir'} = Dir($self->env->spool, 'logs');
    $self->{'filename'} = File($self->env->log, 'xas-spooler.log');

    return {
        'ignore=s' => \$self->{'ignore'},
        'process=s' => \$self->{'process'},
        'spooldir=s' => sub {
            $self->{'spooldir'} = Dir($_[1]);
        },
        'filename=s' => sub {
            $self->{'filename'} = File($_[1]);
        }
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Apps::Logmon::XAS::Process - A class to monitor XAS log files

=head1 SYNOPSIS

 use XAS::Apps::Logmon::XAS::Process;

 my $app = XAS::Apps::Logmon::XAS::Process->new(
     -throws => 'xas-logs'
 );

 exit $app->run;
 
=head1 DESCRIPTION

This procedure will monitor XAS log files. It uses various means, depending on
platform to determine when a file has changed. When a change occurs, this
procedure will read until the end of file, parsing and creating messages as it
goes. A status file is written into the directory of log file. It will have
an extension of '.logmon'. On Linux/Unix this will be a hidden file.

=head1 METHODS

=head2 setup

This method will configure the process.

=head2 main

This method will start the processing. 

=head2 options

This method provides these additonal cli options. 

=over 4

=item B<--ignore>

The number of days prior to today to ignore log lines. Defaults to 300.

=item B<--process>

The name of the process used to create the log file. Defaults to "xas-spooler".

=item B<--spooldir>

The spool director to use. Defaults to $XAS_SPOOL/logs.

=item B<--filename>

The name of the log file. Defaults to $XAS_LOG/xas-spooler.log.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Logmon::Input::Tail|XAS::Logmon::Input::Tail>

=item L<XAS::Logmon::Filter::Merge|XAS::Logmon::Filter::Merge>

=item L<XAS::Logmon::Output::Spool|XAS::Logmon::Output::Spool>

=item L<XAS::Logmon::Format::Logstash|XAS::Logmon::Format::Logstash>

=item L<XAS::Logmon::Parser::XAS::Logs|XAS::Logmon::Parser::XAS::Logs>

=item L<XAS::Logmon::Process|XAS::Logmon::Process>

=item L<XAS::Logmon|XAS::Logmon>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
