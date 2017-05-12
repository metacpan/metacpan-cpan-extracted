# Copyright (c) 1999-2000 João Pedro Gonçalves <joaop@sl.pt>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package GPS::Serial;

use strict;
use vars qw($VERSION $OS_win $has_serialport $stty_path);

$VERSION = sprintf("%d.%02d", q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/);

BEGIN {
    #Taken from SerialPort/eg/any_os.plx

    #We try to use Device::SerialPort or
    #Win32::SerialPort, if it's not windows
    #and there's no Device::SerialPort installed,
    #then we just use the FileHandle module that
    #comes with perl

    $OS_win = ($^O eq "MSWin32") ? 1 : 0;

    if ($OS_win) {
	eval "use Win32::SerialPort";
	die "Must have Win32::SerialPort correctly installed: $@\n" if ($@);
	$has_serialport++;
    } elsif (eval q{ use Device::SerialPort; 1 }) {
	$has_serialport++;
    } elsif (eval q{ use POSIX qw(:termios_h); use FileHandle; 1}) {
	# NOP
    } elsif (-x "/bin/stty") {
	$stty_path = "/bin/stty";
    } else {
	die "Missing either POSIX, FileHandle, Device::SerialPort or /bin/stty";
    }
}				# End BEGIN

#$|++; # XXX should not be here...

sub _read {
    #$self->_read(length)
    #reads packets from whatever you're listening from.
    #length defaults to 1

    my ($self,$len) = @_;
    $len ||=1;

    $self->serial or die "Read from an uninitialized handle";

    my $buf;

    if ($self->{serialtype} eq 'FileHandle') {
	sysread($self->serial,$buf,$len);
    } else {
	(undef, $buf) = $self->serial->read($len);
    }

    if ($self->{verbose} && $buf) {
	print STDERR "R:(",join(" ", map {$self->Pid_Byte($_)}unpack("C*",$buf)),")\n";
    } else {
	# Strange: this delay is necessary, otherwise nothing works
	# (seen on a slow Debian machine with Garmin Vista)
	# Turning on verbose output also helps
	$self->usleep(1);
    }

    return $buf;
}

sub _readline {
    #$self->_readline()
    #reads until $/ is found
    #NMEA-aware - only lines beginning with $ count
    #if NMEA is the chosen protocol

    my ($self) = @_;
    my $line = '';
    $self->serial or warn "Read from an uninitialized handle";

    local $SIG{ALRM} = sub {die "GPS Device has timed out\n"};
    eval { alarm($self->{timeout}) };

    while (1) {
	$self->usleep(1) unless (length($line) % 32);
	my $buf .= $self->_read;
	$line .= $buf;
	if ($buf eq $/) {
	    eval {alarm(0) };
	    return ( ($self->{protocol} eq 'NMEA' && substr($line,0,1) ne '$')
		     ? $self->_readline
		     : $line );
	}
	eval { alarm($self->{timeout}) }; # set new timeout
    }
}

sub safe_read {
    #Reads one byte, escapes DLE bytes
    #Used by the GRMN Protocol
    my $self = shift;
    my $buf = $self->_read;
    $buf eq "\x10" ? $self->_read : $buf;
}

sub _write {
    #$self->_write(buffer,length)
    #syswrite wrapper for the serial device
    #length defaults to buffer length

    my ($self,$buf,$len,$offset) = @_;
    $self->connect() or die "Write to an uninitialized handle";

    $len ||= length($buf);

    if ($self->{verbose}) {
	print STDERR "W:(",join(" ", map {$self->Pid_Byte($_)}unpack("C*",$buf)),")\n";
    }

    $self->serial or die "Write to an uninitialized handle";

    if ($self->{serialtype} eq 'FileHandle') {
	syswrite($self->serial,$buf,$len,$offset||0);
    } else {
	my $out_len = $self->serial->write($buf);
	warn "Write incomplete ($len != $out_len)\n" if	 ( $len != $out_len );
    }
}

sub connect {
    my $self = shift;
    return $self->serial if $self->serial;

    if ($OS_win || $has_serialport) {
	$self->{serial} = $self->serialport_connect;
    } elsif (defined $stty_path) {
	$self->{serial} = $self->stty_connect;
    } else {
	$self->{serial} = $self->unix_connect;
    }

    print "Using $$self{serialtype}\n" if $self->verbose;
}

sub serialport_connect {
    my $self= shift;
    my $PortObj = ( $OS_win ?
		    (new Win32::SerialPort ($self->{port})) :
		    (new Device::SerialPort ($self->{port})) )
	|| die "Can't open $$self{port}: $!\n";

    $PortObj->baudrate($self->{baud});
    $PortObj->parity("none");
    $PortObj->databits(8);
    $PortObj->stopbits(1);
    $PortObj->read_interval(5) if $OS_win;
    $PortObj->write_settings;
    $self->{serialtype} = 'SerialPort';
    $PortObj;
}

sub unix_connect {
    #This was adapted from a script on connecting to a sony DSS, credits to its author (lost his email)
    my $self = shift;
    my $port = $self->{'port'};
    my $baud = $self->{'baud'};
    my($termios,$cflag,$lflag,$iflag,$oflag,$voice);

    my $serial = new FileHandle("+>$port") || die "Could not open $port: $!\n";

    $termios = POSIX::Termios->new();
    $termios->getattr($serial->fileno()) || die "getattr: $!\n";
    $cflag = 0 | CS8() | CREAD() |CLOCAL();
    $lflag = 0;
    $iflag = 0 | IGNBRK() |IGNPAR();
    $oflag = 0;

    $termios->setcflag($cflag);
    $termios->setlflag($lflag);
    $termios->setiflag($iflag);
    $termios->setoflag($oflag);
    $termios->setattr($serial->fileno(),TCSANOW()) || die "setattr: $!\n";
    eval qq[
				  \$termios->setospeed(POSIX::B$baud) || die "setospeed: \$!\n";
				  \$termios->setispeed(POSIX::B$baud) || die "setispeed: \$!\n";
		];

    die $@ if $@;

    $termios->setattr($serial->fileno(),TCSANOW()) || die "setattr: $!\n";

    $termios->getattr($serial->fileno()) || die "getattr: $!\n";
    for (0..NCCS()) {
	if ($_ == NCCS()) {
	    last;
	}
	if ($_ == VSTART() || $_ == VSTOP()) {
	    next;
	}
	$termios->setcc($_,0);
    }
    $termios->setattr($serial->fileno(),TCSANOW()) || die "setattr: $!\n";

    $self->{serialtype} = 'FileHandle';
    $serial;
}

sub stty_connect {
    my $self = shift;
    my $port = $self->{'port'};
    my $baud = $self->{'baud'};
    my($termios,$cflag,$lflag,$iflag,$oflag,$voice);

    if ($^O eq 'freebsd') {
	my $cc = join(" ", map { "$_ undef" } qw(eof eol eol2 erase erase2 werase kill quit susp dsusp lnext reprint status));
	system("$stty_path <$port cs8 cread clocal ignbrk ignpar ospeed $baud ispeed $baud $cc");
	warn "$stty_path failed" if $?;
	system("$stty_path <$port -e");
    } else { # linux
	my $cc = join(" ", map { "$_ undef" } qw(eof eol eol2 erase werase kill intr quit susp start stop lnext rprnt flush));
	system("$stty_path <$port cs8 clocal -hupcl ignbrk ignpar ispeed $baud ospeed $baud $cc");
	die "$stty_path failed" if $?;
	system("$stty_path <$port -a");
    }

    open(FH, "+>$port") or die "Could not open $port: $!\n";
    $self->{serialtype} = 'FileHandle';
    \*FH;
}

sub usleep {
    my $l = shift;
    $l = ref($l) && shift;
    select( undef,undef,undef,($l/1000));
}

sub serial { shift->{serial} }

sub verbose { shift->{verbose} }


1;


__END__

=head1 NAME

GPS::Serial - Access to the Serial port for the GPS::* modules

=head1 SYNOPSIS

  use GPS::Serial;


=head1 DESCRIPTION

	Used internally

=over

=head1 AUTHOR

Joao Pedro B Gonçalves , joaop@sl.pt

=head1 SEE ALSO

Peter Bennett's GPS www and ftp directory:

	ftp://sundae.triumf.ca/pub/peter/index.html.
	http://vancouver-webpages.com/peter/idx_garmin.html

Official Garmin Communication Protocol Reference

	http://www.garmin.com/support/protocol.html

=cut
