package XAS::Apps::Logmon::Monitor;

our $VERSION = '0.01';

use XAS::Lib::Process;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Lib::App::Service',
  mixin      => 'XAS::Lib::Mixins::Configs',
  utils      => 'dotid trim :env',
  constants  => 'TRUE FALSE',
  accessors  => 'cfg',
  filesystem => 'File Dir',
  vars => {
    SERVICE_NAME         => 'XAS_Log',
    SERVICE_DISPLAY_NAME => 'XAS Log Monitor',
    SERVICE_DESCRIPTION  => 'XAS log file monitor'
  }
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub setup {
    my $self = shift;

    my @sections = $self->cfg->Sections();

    foreach my $section (@sections) {

        next if ($section !~ /^logmon:/);

        my $env      = {};
        my ($alias)  = $section =~ /^logmon:(.*)/;
        my $ignore   = $self->cfg->val($section, 'ignore', '30');
        my $filename = File($self->cfg->val($section, 'filename', '/var/logs/xas/xas-spooler.log'));
        my $spooldir = Dir($self->cfg->val($section, 'spooldir', '/var/spool/xas/logs'));
        my $cmd      = File($self->cfg->val($section, 'command'));

        my $command = sprintf('%s --filename %s --spooldir %s --ignore %s --process %s --log-type console',
            $cmd,
            $filename,
            $spooldir,
            $ignore,
            $alias
        );

        $alias = trim($alias);

        if (my $e = $self->cfg->val($section, 'environment', undef)) {

            $env = env_parse($e);

        }

        my $process = XAS::Lib::Process->new(
            -alias          => $alias,
            -pty            => 1,
            -command        => $command,
            -auto_start     => 1,
            -auto_restart   => 1,
            -directory      => Dir($self->cfg->val($section, 'directory', "/")),
            -environment    => $env,
            -exit_codes     => $self->cfg->val($section, 'exit-codes', '0,1'),
            -exit_retries   => $self->cfg->val($section, 'exit-retires', -1),
            -group          => $self->cfg->val($section, 'group', 'xas'),
            -priority       => $self->cfg->val($section, 'priority', '0'),
            -umask          => $self->cfg->val($section, 'umask', '0022'),
            -user           => $self->cfg->val($section, 'user', 'xas'),
            -redirect       => 1,
            -output_handler => sub {
                my $output = shift;
                $output = trim($output);
                if (my ($level, $line) = $output =~/\s+(\w+)\s+-\s+(.*)/ ) {
                    $level = lc(trim($level));
                    $line  = trim($line);
                    $self->log->$level(sprintf('%s: %s', $alias, $line));
                } else {
                    $self->log->info(sprintf('%s: -> %s', $alias, $output));
                }
            }
        );

        $self->service->register($alias);

    }

}

sub main {
    my $self = shift;

    $self->log->info_msg('startup');

    $self->setup();
    $self->service->run();

    $self->log->info_msg('shutdown');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->load_config();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Logmon::Monitor - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Logmon::Monitor;

 my $app = XAS::Apps::Logmon::Monitor->new(
     -throws => 'xas-logmon'
 );

 exit $app->run;

=head1 DESCRIPTION

This module will spawn multiple log monitoring processes. It will keep track
of them and restart them if they should die. Any output from the monitoring
processes are written into the log file. 

=head1 CONFIGURATION

The configuration file is the familiar Windows .ini format. It has the 
following stanzas.

 [logmon: xas-spooler]
 command = /usr/sbin/xas-logs
 filename = /var/log/xas/xas-spooler.log

This stanza defines a log file to monitor. There can be multiple stanzas. The
"xas-spooler" in the stanzas name must be unique. Reasonable defaults
have been defined for most of the properties. You really only need to use 
'filename' to start a monitoring process.

The following properties may be used.

=over 4

=item B<command>

This is the command to run. Defaults to /usr/sbin/xas-logs.

=item B<filename>

The file to monitor. Defaults to /var/log/xas/xas-spooler.log.

=item B<spooldir>

The spool directory to write messages. Defaults to /var/spool/xas/logs.

=item B<ignore>

The number of days prior to today to ignore. Defaults to 30.

=back

Please see L<XAS::Lib::Process|XAS::Lib::Process> for more details on the 
following parameters.

=over 4

=item B<directory>

The default directory to set for the process. Defaults to "/".

=item B<environment>

Optional additional environment variables to pass to the process. This should
be in this form "key1=value1;;key2=value2".

=item B<exit-codes>

The possible exit codes that might be returned if the process aborts. These
are used to determine if the process should be restarted. Defaults to "0,1".
This must be a comma delimited list of values.

=item B<exit-retires>

The number of retries for restarting the process. Defaults to "5". If this is
"-1" then retries are unlimited. Use with caution.

=item B<group>

The group to run the process under. Defaults to "xas". Not implemented under
Windows.

=item B<priority>

The priority to run the process under. Defaults to "0". Not implemented under
Windows.

=item B<umask>

The umask to use for the process. Defaults to "0022". Not implemented under
Windows.

=item B<user>

The user to run the process under. Defaults to "xas". Not implemented under
Windows.

=back

=head1 METHODS

=head2 setup

This method will process the config file and spawn the log monitoring 
processes.

=head2 main

This method will start the processing.

=head2 options

No additional command line options are defined.

=head1 SEE ALSO

=over 4


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
