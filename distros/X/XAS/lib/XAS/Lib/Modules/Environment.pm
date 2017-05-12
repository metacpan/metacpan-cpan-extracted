package XAS::Lib::Modules::Environment;

our $VERSION = '0.02';

use File::Basename;
use Config::IniFiles;
use Net::Domain qw(hostdomain);

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Singleton',
  utils      => ':validation dir_walk',
  constants  => ':logging :alerts STOMP_LEVELS',
  filesystem => 'File Dir Path Cwd',
  accessors  => 'path host domain username commandline',
  mutators   => 'mqserver mqport mxserver mxport mxtimeout msgs alerts xdebug',
;

# ------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------

sub mxmailer {
    my $self = shift;
    my ($mailer) = validate_params(\@_, [
        { optional => 1, default => undef, regex => qr/sendmail|smtp/ }
    ]);

    $self->{'mxmailer'} = $mailer if (defined($mailer));

    return $self->{'mxmailer'};

}

sub mqlevel {
    my $self = shift;
    my ($level) = validate_params(\@_, [
        { optional => 1, default => undef, regex => STOMP_LEVELS },
    ]);

    $self->{'mqlevel'} = $level if (defined($level));

    return $self->{'mqlevel'};

}

sub log_type {
    my $self = shift;
    my ($type) = validate_params(\@_, [
        { optional => 1, default => undef, regex => LOG_TYPES }
    ]);

    $self->{'log_type'} = $type if (defined($type));

    return $self->{'log_type'};

}

sub log_facility {
    my $self = shift;
    my ($type) = validate_params(\@_, [
        { optional => 1, default => undef, regex => LOG_FACILITY }
    ]);

    $self->{'log_facility'} = $type if (defined($type));

    return $self->{'log_facility'};

}

sub throws {
    my $self = shift;
    my ($throws) = validate_params(\@_, [
        { optional => 1, default => undef }
    ]);

    $self->{'throws'} = $throws if (defined($throws));

    return $self->{'throws'};

}

sub priority {
    my $self = shift;
    my ($level) = validate_params(\@_, [
        { optional => 1, default => undef, regex => ALERT_PRIORITY }
    ]);

    $self->{'priority'} = $level if (defined($level));

    return $self->{'priority'};

}

sub facility {
    my $self = shift;
    my ($level) = validate_params(\@_, [
        { optional => 1, default => undef, regex => ALERT_FACILITY }
    ]);

    $self->{'facility'} = $level if (defined($level));

    return $self->{'facility'};

}

sub script {
    my $self = shift;
    my ($script) = validate_params(\@_, [
        { optional => 1, default => undef }
    ]);
    
    $self->{'script'} = $script if (defined($script));

    return $self->{'script'};

}

sub get_msgs {
    my $self = shift;

    return $self->class->var('MESSAGES');

}

# ------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------

sub _load_msgs {
    my $self = shift;

    my $messages = $self->class->any_var('MESSAGES');

    foreach my $path (@INC) {

        my $dir = Dir($path, 'XAS');

        if ($dir->exists) {

            dir_walk(
                -directory => $dir, 
                -filter    => $self->msgs, 
                -callback  => sub {
                    my $file = shift;

                    my $cfg = Config::IniFiles->new(-file => $file->path);
                    if (my @names = $cfg->Parameters('messages')) {

                        foreach my $name (@names) {

                            $messages->{$name} = $cfg->val('messages', $name);

                        }

                    }

                }
            );

        }

    }

    $self->class->var('MESSAGES', $messages);

}

sub init {
    my $self = shift;

    my $temp;
    my $name;
    my $path;
    my $suffix;
    my $commandline = $0;
    my ($script) = ( $commandline =~ m#([^\\/]+)$# );

    foreach (@ARGV) {
        $commandline .= /\s/
          ? " \'" . $_ . "\'"
          : " "   . $_;
    }

    # set some defaults

    $self->{'alerts'} = 1;
    $self->{'xdebug'} = 0;
    $self->{'mxtimeout'} = 60;
    $self->{'script'} = $script;
    $self->{'path'} = $ENV{'PATH'};
    $self->{'commandline'} = $commandline;
      
    # Initialize variables - these are defaults

    $self->{'mqserver'} = defined($ENV{'XAS_MQSERVER'}) 
        ? $ENV{'XAS_MQSERVER'} 
        : 'localhost';

    $self->{'mqport'} = defined($ENV{'XAS_MQPORT'}) 
        ? $ENV{'XAS_MQPORT'} 
        : '61613';

    $self->{'mqlevel'} = defined ($ENV{'XAS_MQLEVEL'})
        ? $ENV{'XAS_MQLEVEL'}
        : '1.0';

    $self->{'mxserver'} = defined($ENV{'XAS_MXSERVER'}) 
        ? $ENV{'XAS_MXSERVER'} 
        : 'localhost';

    $self->{'mxport'} = defined($ENV{'XAS_MXPORT'}) 
        ? $ENV{'XAS_MXPORT'} 
        : '25';

    $self->{'domain'} = defined($ENV{'XAS_DOMAIN'}) 
        ? $ENV{'XAS_DOMAIN'} 
        : hostdomain();

    $self->{'msgs'} = defined($ENV{'XAS_MSGS'}) 
        ? qr/$ENV{'XAS_MSGS'}/i 
        : qr/.*\.msg$/i;

    $self->{'throws'} = defined($ENV{'XAS_ERR_THROWS'}) 
        ? $ENV{'XAS_ERR_THROWS'} 
        : 'xas';

    $self->{'priority'} = defined($ENV{'XAS_ERR_PRIORITY'}) 
        ? $ENV{'XAS_ERR_PRIORITY'} 
        : 'low';

    $self->{'facility'} = defined($ENV{'XAS_ERR_FACILITY'}) 
        ? $ENV{'XAS_ERR_FACILITY'} 
        : 'systems';

    # platform specific

    my $OS = $^O;

    if ($OS eq "MSWin32") {

        require Win32;

        $self->{'host'} = defined($ENV{'XAS_HOSTNAME'}) 
            ? $ENV{'XAS_HOSTNAME'} 
            : Win32::NodeName();

        $self->{'root'} = Dir(defined($ENV{'XAS_ROOT'}) 
            ? $ENV{'XAS_ROOT'} 
            : ['C:', 'XAS']);

        $self->{'etc'} = Dir(defined($ENV{'XAS_ETC'})   
            ? $ENV{'XAS_ETC'}   
            : [$self->{root}, 'etc']);

        $self->{'tmp'} = Dir(defined($ENV{'XAS_TMP'})   
            ? $ENV{'XAS_TMP'}   
            : [$self->{root}, 'tmp']);

        $self->{'var'} = Dir(defined($ENV{'XAS_VAR'})   
            ? $ENV{'XAS_VAR'}   
            : [$self->{root}, 'var']);

        $self->{'lib'} = Dir(defined($ENV{'XAS_LIB'})   
            ? $ENV{'XAS_LIB'}   
            : [$self->{root}, 'var', 'lib']);

        $self->{'log'} = Dir(defined($ENV{'XAS_LOG'})   
            ? $ENV{'XAS_LOG'}   
            : [$self->{root}, 'var', 'log']);

        $self->{'locks'} = Dir(defined($ENV{'XAS_LOCKS'})   
            ? $ENV{'XAS_LOCKS'}   
            : [$self->{root}, 'var', 'lock']);

        $self->{'run'} = Dir(defined($ENV{'XAS_RUN'})   
            ? $ENV{'XAS_RUN'}   
            : [$self->{root}, 'var', 'run']);

        $self->{'spool'} = Dir(defined($ENV{'XAS_SPOOL'}) 
            ? $ENV{'XAS_SPOOL'} 
            : [$self->{root}, 'var', 'spool']);

        $self->{'mxmailer'}  = defined($ENV{'XAS_MXMAILER'}) 
            ? $ENV{'XAS_MXMAILER'} 
            : 'smtp';

        $self->{'username'} = Win32::LoginName();

    } else {

        # this assumes a unix like working environment

        $self->{'host'} = defined($ENV{'XAS_HOSTNAME'}) 
            ? $ENV{'XAS_HOSTNAME'} 
            : `hostname -s`;

        chomp($self->{'host'});

        $self->{'root'} = Dir(defined($ENV{'XAS_ROOT'}) 
            ? $ENV{'XAS_ROOT'} 
            : ['/']);

        $self->{'etc'} = Dir(defined($ENV{'XAS_ETC'})   
            ? $ENV{'XAS_ETC'}   
            : [$self->{root}, 'etc', 'xas']);

        $self->{'tmp'} = Dir(defined($ENV{'XAS_TMP'})   
            ? $ENV{'XAS_TMP'} 
            : ['/', 'tmp']);

        $self->{'var'} = Dir(defined($ENV{'XAS_VAR'})   
            ? $ENV{'XAS_VAR'}   
            : [$self->{root}, 'var']);

        $self->{'lib'} = Dir(defined($ENV{'XAS_LIB'})   
            ? $ENV{'XAS_LIB'}   
            : [$self->{root}, 'var', 'lib', 'xas']);

        $self->{'log'} = Dir(defined($ENV{'XAS_LOG'})   
            ? $ENV{'XAS_LOG'}   
            : [$self->{root}, 'var', 'log', 'xas']);

        $self->{'locks'} = Dir(defined($ENV{'XAS_LOCKS'})   
            ? $ENV{'XAS_LOCKS'}   
            : [$self->{root}, 'var', 'lock', 'xas']);

        $self->{'run'} = Dir(defined($ENV{'XAS_RUN'})   
            ? $ENV{'XAS_RUN'}   
            : [$self->{root}, 'var', 'run', 'xas']);

        $self->{'spool'} = Dir(defined($ENV{'XAS_SPOOL'}) 
            ? $ENV{'XAS_SPOOL'} 
            : [$self->{root}, 'var', 'spool', 'xas']);

        $self->{'mxmailer'}  = defined($ENV{'XAS_MXMAILER'}) 
          ? $ENV{'XAS_MXMAILER'} 
          : 'sendmail';

        $self->{'username'} = getpwuid($<);

    }

    # build some common paths

    $self->{'sbin'} = Dir(defined($ENV{'XAS_SBIN'})  
        ? $ENV{'XAS_SBIN'}  
        : [$self->{'root'}, 'sbin']);

    $self->{'bin'} = Dir(defined($ENV{'XAS_BIN'})   
        ? $ENV{'XAS_BIN'}   
        : [$self->{'root'}, 'bin']);

    # define some logging options

    $self->{'log_type'} = defined($ENV{'XAS_LOG_TYPE'})
        ? $ENV{'XAS_LOG_TYPE'}
        : 'console';

    $self->{'log_facility'} = defined($ENV{'XAS_LOG_FACILITY'})
        ? $ENV{'XAS_LOG_FACILITY'}
        : 'local6';

    # create some common file names

    ($name, $path, $suffix) = fileparse($0, qr{\..*});

    $self->{'log_file'} = File($self->{'log'}, $name . '.log');
    $self->{'pid_file'} = File($self->{'run'}, $name . '.pid');
    $self->{'cfg_file'} = File($self->{'etc'}, $name . '.ini');

    # build some methods, saves typing

    for my $datum (qw( log_file pid_file cfg_file )) {

        $self->class->methods($datum => sub {
            my $self = shift;
            my ($p) = validate_params(\@_, [
                    {optional => 1, default => undef, isa => 'Badger::Filesystem::File' }
                ],
                "xas.lib.modules.environment.$datum"
            );

            $self->{$datum} = $p if (defined($p));

            return $self->{$datum};

        });

    }

    for my $datum (qw( root etc sbin tmp var bin lib log locks run spool )) {

        $self->class->methods($datum => sub {
            my $self = shift;
            my ($p) = validate_params(\@_, [
                    {optional => 1, default => undef, isa => 'Badger::Filesystem::Directory'}
                ],
                "xas.lib.modules.environment.$datum"
            );

            $self->{$datum} = $p if (defined($p));

            return $self->{$datum};

        });

    }

    $self->_load_msgs();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Modules::Environment - The base environment for the XAS environment

=head1 SYNOPSIS

Your program can use this module in the following fashion:

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Base',
 ;

  $pidfile = $self->env->pid_file;
  $logfile = $self->env->log_file;

  printf("The XAS root is %s\n", $self->env->root);

=head1 DESCRIPTION

This module describes the base environment for XAS. This module is implemented 
as a singleton and will be auto-loaded when invoked.

=head1 METHODS

=head2 new

This method will initialize the base module. It parses the current environment
using the following variables:

=over 4

=item B<XAS_ROOT>

The root of the directory structure. On Unix like boxes this will be 
/ and Windows this will be C:\XAS.

=item B<XAS_LOG>

The path for log files. On Unix like boxes this will be /var/log/xas and on
Windows this will be %XAS_ROOT%\var\log.

=item B<XAS_LOCKS>

The path for lock files. On Unix like boxes this will be /var/lock/xas and on
Windows this will be %XAS_ROOT%\var\lock.

=item B<XAS_RUN>

The path for pid files. On Unix like boxes this will be /var/run/xas and
on Windows this will be %XAS_ROOT%\var\run.

=item B<XAS_SPOOL>

The base path for spool files. On Unix like boxes this will be /var/spool/xas 
and on Windows this will be %XAS_ROOT%\var\spool.

=item B<XAS_LIB>

The path to the lib directory. On Unix like boxes this will be /var/lib/xas 
and on Windows this will be %XAS_ROOT%\var\lib.

=item B<XAS_ETC>

The path to the etc directory. On Unix like boxes this will be /usr/local/etc
and on Windows this will be %XAS_ROOT%\etc

=item B<XAS_BIN>

The path to the bin directory. On Unix like boxes this will be /usr/local/bin
and on Windows this will be %XAS_ROOT%\bin.

=item B<XAS_SBIN>

The path to the sbin directory. On Unix like boxes this will be /usr/local/sbin
and on Windows this will be %XAS_ROOT%\sbin.

=item B<XAS_HOSTNAME>

The host name of the system. If not provided, on Unix the "hostname -s" command
will be used and on Windows Win32::NodeName() will be called. 

=item B<XAS_DOMAIN>

The domain of the system: If not provided, then Net::Domain::hostdomain() will
be used.

=item B<XAS_MQSERVER>

The server where a STOMP enabled message queue server is located. Default
is "localhost".

=item B<XAS_MQPORT>

The port that server is listening on. Default is "61613".

=item B<XAS_MQLEVL>

This sets the STOMP protocol level. The default is v1.0.

=item B<XAS_MXSERVER>

The server where a SMTP based mail server resides. Default is "localhost".

=item B<XAS_MXPORT>

The port it is listening on. Default is "25".

=item B<XAS_MXMAILER>

The mailer to use for sending email. On Unix like boxes this will be "sendmail"
on Windows this will be "smtp".

=item B<XAS_MSGS>

The regex to use when searching for message files. Defaults to /.*\.msg/i.

=item B<XAS_LOG_FACILITY>

The syslog facility class to use. Defaults to 'local6'. It uses the syslog 
conventions.

=item B<XAS_LOG_TYPE>

The log type. This can be "console", "file", "json" or "syslog". Defaults
to "console"

=item B<XAS_ERR_THROWS>

The default error message type. Defaults to 'xas'.

=item B<XAS_ERR_PRIORITY>

The error message priority type. Defaults to "low".

=item B<XAS_ERR_FACILITY>

The error message facility type. Defaults to "systems".

=back

=head2 alerts

This method sets or returns wither to send alerts.

=head2 xdebug

This method sets or returns the status of debug.

=head2 script

This method returns the name of the script.

=head2 commandline

This method returns the complete commandline.

=head2 log_type

This method will return the currently defined log type. By default this is
"console". i.e. all logging will go to the terminal screen. Valid options
are "console", "file", "json" and "syslog'. 

=head2 log_facility

This method will return the log facility class to use when writting to
syslog or json.

Example

    $facility = $xas->log_facility;
    $xas->log_facility('local6');

=head2 log_file

This method will return a pre-generated name for a log file. The name will be 
based on the programs name with a ".log" extension, along with the path to
the XAS log file directory. Or you can store your own self generated log 
file name.

Example

    $logfile = $xas->log_file;
    $xas->log_file("/some/path/mylogfile.log");

=head2 pid_file

This method will return a pre-generated name for a pid file. The name will be 
based on the programs name with a ".pid" extension, along with the path to
the XAS pid file directory. Or you can store your own self generated pid 
file name.

Example

    $pidfile = $xas->pid_file;
    $xas->pid_file("/some/path/myfile.pid");

=head2 cfg_file

This method will return a pre-generated name for a configuration file. The 
name will be based on the programs name with a ".ini" extension, along with 
the path to the XAS configuration file directory. Or you can store your own 
self generated configuration file name.

Example

    $inifile = $xas->cfg_file;
    $xas->cfg_file("/some/path/myfile.cfg");

=head2 mqserver

This method will return the name of the message queue server. Or you can
store a different name for the server.

Example

    $mqserver = $xas->mqserver;
    $xas->mqserver('mq.example.com');

=head2 mqport

This method will return the port for the message queue server, or you store
a different port number for that server.

=head2 mqlevel

This method will returns the STOMP protocol level. or you store
a different level. It can use 1.0, 1.1 or 1.2.

Example

    $mqlevel = $xas->mqlevel;
    $xas->mqlevel('1.0');

=head2 mxserver

This method will return the name of the mail server. Or you can
store a different name for the server.

Example

    $mxserver = $xas->mxserver;
    $xas->mxserver('mail.example.com');

=head2 mxport

This method will return the port for the mail server, or you store
a different port number for that server.

Example

    $mxport = $xas->mxport;
    $xas->mxport('25');

=head2 mxmailer

This method will return the mailer to use for sending email, or you can
change the mailer used.

Example

    $mxmailer = $xas->mxmailer;
    $xas->mxmailer('smtp');

=head1 ACCESSORS

=head2 path

This accessor returns the currently defined path for this program.

=head2 root

This accessor returns the root directory of the XAS environment.

=head2 bin

This accessor returns the bin directory of the XAS environment. The bin
directory is used to place executable commands.

=head2 sbin

This accessor returns the sbin directory of the XAS environment. The sbin
directory is used to place system level commands.

=head2 log

This accessor returns the log directory of the XAS environment. 

=head2 run

This accessor returns the run directory of the XAS environment. The run
directory is used to place pid files and other such files.

=head2 etc

This accessor returns the etc directory of the XAS environment. 
Application configuration files should go into this directory.

=head2 lib

This accessor returns the lib directory of the XAS environment. This
directory is used to store supporting file for the environment.

=head2 spool

This accessor returns the spool directory of the XAS environment. This
directory is used to store spool files generated within the environment.

=head2 tmp

This accessor returns the tmp directory of the XAS environment. This
directory is used to store temporary files. 

=head2 var

This accessor returns the var directory of the XAS environment. 

=head2 host

This accessor returns the local hostname. 

=head2 domain

This access returns the domain name of the local host.

=head2 username

This accessor returns the effective username of the current process.

=head2 msgs

The accessor to return the regex for messages files.

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
