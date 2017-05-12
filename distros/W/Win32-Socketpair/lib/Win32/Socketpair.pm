package Win32::Socketpair;
use strict;
use warnings;
use Carp qw(croak carp);
use Socket;
use Errno 'EINPROGRESS';

our $VERSION = '0.02';

BEGIN {
    $^O =~ /mswin/i
    or croak __PACKAGE__ . " can be only used on MSWin32 systems";
}

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(winsocketpair winopen2 winopen2_5 ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub winsocketpair {
    my $proto = getprotobyname('tcp');
    my $true = 1;
    my $false = 0;

    for (1..5) {
        carp "winsocketpair failed: $!, retrying" unless $_ == 1;

        socket( my $listener, AF_INET, SOCK_STREAM, $proto ) or return ();
        socket( my $server,   AF_INET, SOCK_STREAM, $proto ) or return ();
        socket( my $client,   AF_INET, SOCK_STREAM, $proto ) or return ();

        ioctl( $client, 0x8004667e, \$true );

        my $addr = sockaddr_in( 0, INADDR_LOOPBACK );
        bind( $listener, $addr ) or return ();
        listen( $listener, 1 ) or return ();
        $addr = getsockname( $listener );

        connect( $client, $addr )
            or $! ==  10035 or $! == EINPROGRESS
            or next;
        my $peer = accept( $server, $listener ) or next;

        ioctl( $client, 0x8004667e, \$false );

        if( $peer eq getsockname( $client ) ) {
            return( $server, $client );
        }
    }
    return ();
}

sub winopen2 {
    my ($pid, $oldin, $oldout);

    my ($server, $client) = winsocketpair
    or return undef;

    open $oldin, '<&', \*STDIN or return ();
    open $oldout, '>&', \*STDOUT or return ();

    if( open( STDIN, '<&', $server )
    and open( STDOUT, '>&', $server )
    ) {
        $pid = eval { system 1, @_ or die "system command failed: $!"};
        # print STDERR "error: $@\n" if $@;
    }
    close STDOUT;
    open STDOUT, '>&', $oldout
        or carp "unable to reestablish STDOUT";

    close STDIN;
    open STDIN, '<&', $oldin
        or carp "unable to reestablish STDIN";

    #printf STDERR "pid %d, fileno %d, stdout %d, stdin %d\n",
    #    $pid, fileno($client), fileno STDOUT, fileno STDIN;

    return ($pid and $pid > 0) ? ($pid, $client) : ();
}

sub winopen2_5 {
    my( $pid, $oldin, $oldout, $olderr );

    my( $server, $client ) = winsocketpair
    or return undef;

    open $oldin,  '<&', \*STDIN  or return ();
    open $oldout, '>&', \*STDOUT or return ();
    open $olderr, '>&', \*STDERR or return ();

    if( open( STDIN,  '<&', $server )
    and open (STDOUT, '>&', $server)
    and open (STDERR, '>&', $server)
    ) {
        $pid = eval{ system 1, @_ or die "system command failed: $!" };
        # print STDERR "error: $@\n" if $@;
    }
    close STDERR;
    open STDERR, '>&', $olderr
        or carp "unable to reestablish STDERR";

    close STDOUT;
    open STDOUT, '>&', $oldout
        or carp "unable to reestablish STDOUT";

    close STDIN;
    open STDIN, '<&', $oldin
        or carp "unable to reestablish STDIN";

    #printf STDERR "pid %d, fileno %d, stdout %d, stdin %d\n",
    #    $pid, fileno($client), fileno STDOUT, fileno STDIN;

    return ( $pid and $pid > 0 ) ? ( $pid, $client ) : ();
}


1;

__END__


=head1 NAME

Win32::Socketpair - Simulate socketpair on Windows

=head1 SYNOPSIS

  use Win32::Socketpair 'winopen2';

  my $socket = winopen2(@cmd);

  my $fn = fileno $socket;
  my $v = '';
  vec($v, $fn, 1) = 1;

  while (1) {
    if (select(my $vin = $v, my $vout = $v, undef, undef) > 0) {
      if (vec($vout, $fn, 1) {
        syswrite($socket, "hello\n") or last;
      }
      if (vec($vin, $fn, 1) {
        sysread($socket, my $buffer, 2048) or last;
        print "read: $buffer";
      }
    }
  }

=head1 DESCRIPTION

This module allows to create a bidirectional pipe on Windows that can
be used inside a C<select> loop. It uses a TCP socket going through the
localhost interface to create the connection.

Also export winopen2() (and winopen2_5()) which use the socketpair to
perform a bidirection "piped open" allowing writing to the subprocess' stdin
and copturing it stdout (and stderr).

=head2 EXPORT

The subroutines that can be imported from this module are:

=over 4

=item ($fd1, $fd2) = winsocketpair()

creates a socket connection through the localhost interface.

It returns a pair of file descriptors representing both sides of the
socket.

=item ($pid, $fd1) = winopen2(@cmd)

creates a socket connection through the localhost interface and
launchs the external command C<@cmd> on the background using one side
of the socket as its STDIN and STDOUT.

It returns the pid of the new process and the file descriptor for the
other side of the socket or an empty list on failure.

=back

=item ($pid, $fd1) = winopen2_5(@cmd)

As above, but also captures stderr as well as stdout.
Effectively the same as doing 2>&1, but avoiding the shell.

=back


=head1 SEE ALSO

L<IPC::Open2>, L<perlipc>, L<perlfunc>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>.
Copyright (C) 2012 by BrowserUk <cpan.20.browseruk@xoxy.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
