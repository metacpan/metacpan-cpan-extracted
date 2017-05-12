###########################################
package X10::Home;
###########################################
use strict;
use warnings;
use YAML qw(LoadFile);
use Log::Log4perl qw(:easy);
use Device::SerialPort;
use Fcntl qw/:flock/;
use DB_File;

our $VERSION = "0.04";

my @CONF_PATHS = (
    glob("~/.x10.conf"),
    "/etc/x10.conf",
);

my($STATUS_FILE) = glob("~/.x10.status");

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        conf_paths => \@CONF_PATHS,
        conf_file  => undef,
        commands   => {
          on     => "J",
          off    => "K",
          status => undef,
        },
        lockfile   => '/tmp/x10_home.lock',
        db_file    => "/tmp/x10.status",
        db_perm    => 0666,
        probe      => 1,
        %options,
    };

    bless $self, $class;

    $self->init();

    return $self;
}

###########################################
sub init {
###########################################
    my($self) = @_;

    if(defined $self->{conf_file}) {
        $self->{conf} = LoadFile( $self->{conf_file} );
    } else {
        for my $path (@{ $self->{conf_paths} }) {
            if(-f $path) { 
                $self->{conf} = LoadFile( $path );
                last;
            }
        }
    }

    LOGDIE "No configuration file found (searched ", 
           join (", ", @{ $self->{conf_paths} }), 
           ")" unless defined $self->{conf};

    if(ref( $self->{conf} ) ne "HASH") {
        LOGDIE "Configuration file invalid (not a hash)";
    }
        
    $self->{conf}->{device}   ||= "/dev/ttyS0";
    $self->{conf}->{module}   ||= "ControlX10::CM11";
    $self->{conf}->{baudrate} ||= 4800;

    eval "require $self->{conf}->{module}";

    if($self->{probe}) {
        $self->{serial} = Device::SerialPort->new(
            $self->{conf}->{device}, undef);

        $self->{serial}->baudrate($self->{conf}->{baudrate});
    }

    $self->{receivers} = {
        map { $_->{name} => $_ } @{$self->{conf}->{receivers}} };

    $self->db_init() if defined $self->{db_file};

    1;
}

###########################################
sub db_init {
###########################################
    my($self) = @_;

    $self->{dbm} = {};

    dbmopen(%{$self->{dbm}},
        $self->{db_file}, 0666) or
        LOGDIE "Cannot open $self->{db_file}";

    chmod $self->{db_perm}, $self->{db_file};

    for (keys %{$self->{receivers}}) {
        my $receiver = $self->{receivers}->{$_};
        $self->{dbm}->{ $receiver->{name} } ||= "off";
    }

    1;
}

###########################################
sub db_status {
###########################################
    my($self, $field, $value) = @_;

    if(defined $value) {
        $self->{dbm}->{ $field } = $value;
    }

    return $self->{dbm}->{ $field };
}

###########################################
sub send {
###########################################
    my($self, $receiver, $cmd) = @_;

    if(! exists $self->{receivers}->{$receiver}) {
        ERROR "Unknown receiver '$receiver'";
        return undef;
    }

    if(! exists $self->{commands}->{$cmd}) {
        ERROR "Unknown command '$cmd'";
        return undef;
    }

    my($house_code, $unit_code) = split //,
        $self->{receivers}->{$receiver}->{code}, 2;

    my $send = "$self->{conf}->{module}" . "::" . "send";

    $self->lock();

    {
      no strict 'refs';

      DEBUG "Addressing HC=$house_code UC=$unit_code";
      $send->($self->{serial}, $house_code . $unit_code);
  
      DEBUG "Sending command $cmd $self->{commands}->{$cmd}";
      $send->($self->{serial},
                    $house_code .
                    $self->{commands}->{$cmd});
    }

    if(defined $self->{db_file}) {
        DEBUG "Setting db status of $receiver to $cmd";
        $self->db_status($receiver, $cmd);
    }

    $self->unlock();

    1;
}

###########################################
sub lock {
###########################################
    my($self) = @_;

    open my $fh, ">>$self->{lockfile}" or
        LOGDIE "Cannot open lockfile $self->{lockfile} ($!)";
    flock($fh, LOCK_EX);

    $self->{fh} = $fh;
}

###########################################
sub unlock {
###########################################
    my($self) = @_;

    if(! defined $self->{fh}) {
        LOGDIE "Called unlock without previous lock";
    }

    flock($self->{fh}, LOCK_UN);
    close $self->{fh};
    $self->{fh} = undef;
    unlink $self->{lockfile};
}

###########################################
sub receivers {
###########################################
    my($self) = @_;
    return keys %{$self->{receivers}};
}

###########################################
sub command_valid {
###########################################
    my($self, $command) = @_;

    return exists $self->{commands}->{$command};
}

###########################################
sub DESTROY {
###########################################
    my($self) = @_;

    dbmclose(%{$self->{dbm}});
}

1;

__END__

=head1 NAME

X10::Home - Configure X10 for your Home

=head1 SYNOPSIS

    # System-wide /etc/x10.conf Configuration File

    module: ControlX10::CM11
    device: /dev/ttyS0
    receivers:  
      - name: bedroom_lights
        code: K15
        desc: Bedroom Lights
      - name: dsl_router
        code: ...

    # In your application:

    use X10::Home;
    my $x10 = X10::Home->new();
      # Address services by name
    $x10->send("bedroom_lights", "on");

=head1 DESCRIPTION

C<X10::Home> lets you set parameters of all your home X10 devices in a
single configuration file. After that's done, applications can access
them by name and without worrying about details like "house codes",
"unit codes", "serial ports", X10 commands and other low-level details.

C<X10::Home> also maintains a status database to remember the assumed
status of cheap X10 devices without a feedback mechanism.

=head2 Usage

After a one-time setup of the C<x10.conf> file, to switch the bedroom
lights on, simply use

    use X10::Home;
    my $x10->X10::Home->new();
    $x10->send("bedroom_lights", "on");

and

    $x10->send("bedroom_lights", "off");

to switch them off again.

C<X10::Home> uses the C<ControlX10::CM11> or C<ControlX10::CM17> CPAN
modules under the hood to send actual X10 commands via the
computer's serial port.

=head2 Configuration File

Upon initialization, C<X10::Home> will search a configuration file
in the following locations (in the order listed):

=over 4

=item *

If C<X10::Home::new()> gets called with the C<conf_file> parameter
set, the configuration will be read from C<conf_file>.

=item * 

C<~/.x10.conf> (in the user's local home directory) if present

=item *

C</etc/x10.conf> if present

=back

The configuration file is written in YAML format and looks like this:

    # /etc/x10.conf Configuration File

    module:   ControlX10::CM11
    device:   /dev/ttyS0
    baudrate: 4800

    receivers:  
      - name: bedroom_lights
        code: K15
        desc: Bedroom Lights
      - name: dsl_router
        code: K16
        desc: DSL Router

The C<module> parameter specifies which X10 low-level module
to use, C<ControlX10::CM11> or C<ControlX10::CM17>, it defaults
to C<ControlX10::CM11>.

The C<device> parameter specifies the device entry of the serial port 
to use, it defaults to C</dev/ttyS0>. This can be C</dev/ttyS4> or
C</dev/ttyS5> if a serial PCI card gets plugged into the computer.

The C<baudrate> is the baud rate to be used to communicate over the serial 
port. It defaults to 4800.

The C<receivers> parameter specifies an array of receivers. The reason
why this is an array an not a hash is that certain applications like to
display all available receivers in a predefined order. Receivers are
hashed internally by C<X10::Home> by their C<name> entries for quick 
lookups, though.

=head2 METHODS

=over 4

=item C<new()>

Constructor. Optional parameters are 

=over 4

=item C<conf_file>

to specify the path to a special x10.conf file instead of the natural
search order of system x10.conf files.

=item C<db_file>

to indicate that C<X10::Home> should be maintaining a persistent data
store with assumed device status. Defaults to C</tmp/x10.status>.
To check/manipulate the maintained status, see C<db_status> below.

=back

=item C<send($name, $action)>

Sends a message to the specified X10 receiver. Uses locking 
(see C<lock/unlock> below)
internally
to make sure that no other X10 commands are sent over the wire by this
sender at the same time, which would confuse the receivers.

=item C<lock()>

Aquire an exclusive lock.

=item C<unlock()>

Release the previously acquired exclusive lock.

=item C<db_status($field, [$value])>

For persistent storage of assumed device status, C<X10::Home> maintains
a file-based data store (if the constructor is called with the C<db_file>
parameter set to a persistent datastore location). 
If a device gets switched on or off,
C<X10::Home> will make a note of that in the data store. To query the
(assumed) status of a device, use

    my $x10 = X10::Home( db_file => "/tmp/x10.status" );

    if( $x10->db_status("bedroom_lights") eq "on" ) {
        print "Bedroom lights are on!\n";
    }

=head1 Sample Applications

The C<eg> directory contains a command line application C<x10> which 
allows you to run X10 commands from the command line, e.g.

    $ x10 office_lights on

or 

    $ x10 office_lights status
    on

The C<eg> directory also contains an AJAXed X10 web application, check
out C<x10.cgi> and read the installation instructions at the top of
the file.

=back

=head1 LEGALESE

Copyright 2007 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2007, Mike Schilli <m@perlmeister.com>
