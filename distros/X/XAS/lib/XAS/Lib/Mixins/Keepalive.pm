package XAS::Lib::Mixins::Keepalive;

our $VERSION = '0.01';

our $TCP_KEEPCNT = 0;
our $TCP_KEEPIDLE = 0;
our $TCP_KEEPINTVL = 0;

use Try::Tiny;
use Socket ':all';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => ':validation',
  accessors => 'tcp_keepidle tcp_keepcnt tcp_keepintvl',
  mixins    => 'init_keepalive enable_keepalive tcp_keepidle tcp_keepcnt tcp_keepintvl',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub enable_keepalive {
    my $self = shift;
    my ($socket) = validate_params(\@_, [1]);

    # turn keepalive on, this should send a keepalive 
    # packet once every 2 hours according to the RFC.

    setsockopt($socket, SOL_SOCKET, SO_KEEPALIVE,  1);

    # adjust the system defaults, all values are in seconds.
    # so this does the following:
    #   every 15 minutes send up to 3 packets at 5 second intervals
    #     if no reply, the connection is down.

    setsockopt($socket, IPPROTO_TCP, $TCP_KEEPINTVL, $self->tcp_keepintvl); 
    setsockopt($socket, IPPROTO_TCP, $TCP_KEEPIDLE,  $self->tcp_keepidle);
    setsockopt($socket, IPPROTO_TCP, $TCP_KEEPCNT,   $self->tcp_keepcnt);

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init_keepalive {
    my $self = shift;
    my $p = validate_params(\@_, {
        -tcp_keepcnt   => { optional => 1, default => 3 },   # number of packets
        -tcp_keepidle  => { optional => 1, default => 900 }, # 15 minutes
        -tcp_keepintvl => { optional => 1, default => 5 },   # interval seconds
    });
    
    $self->{'tcp_keepcnt'}   = $p->{'tcp_keepcnt'};
    $self->{'tcp_keepidle'}  = $p->{'tcp_keepidle'};
    $self->{'tcp_keepintvl'} = $p->{'tcp_keepintvl'};
                                            
    # implement socket level keepalive, what a mess...

    if ( $] < 5.014 ) {               # check perl's version

        # at this point we can only support the below. if you have
        # access to your systems header files, you could provide
        # the following values. I would be happy to include them.

        if ($^O eq "aix") {         # from /usr/include/netinet/tcp.h

            $TCP_KEEPIDLE  = 0x11;
            $TCP_KEEPINTVL = 0x12;
            $TCP_KEEPCNT   = 0x13;

        } elsif ($^O eq "linux") {  # from /usr/include/netinet/tcp.h

            $TCP_KEEPIDLE  = 4;
            $TCP_KEEPINTVL = 5;
            $TCP_KEEPCNT   = 6;

        } elsif ($^O eq 'vms') {    # from TCP in sys$library:decc$rtldef.tlb

            $TCP_KEEPIDLE  = 0x04;
            $TCP_KEEPINTVL = 0x05;
            $TCP_KEEPCNT   = 0x06;

        }

    } else {

        try {

            # hmmm, maybe perl will do it for us. checking to see if the 
            # platform implements these macros.

            $TCP_KEEPCNT   = Socket::TCP_KEEPCNT()   if (UNIVERSAL::can('Socket', 'TCP_KEEPCNT'));
            $TCP_KEEPIDLE  = Socket::TCP_KEEPIDLE()  if (UNIVERSAL::can('Socket', 'TCP_KEEPIDLE'));
            $TCP_KEEPINTVL = Socket::TCP_KEEPINTVL() if (UNIVERSAL::can('Socket', 'TCP_KEEPINTVL'));

        } catch {

            # nope, guess not...

            my $ex = $_;
            my ($err) = m/(.*,)/;
            chop($err);

            $self->log->warn(lcfirst($err));

        };

    }

}

1;

__END__

=head1 NAME

XAS::Lib::Mixin::Keepalive - A mixin to implement TCP keepalive

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Base',
   mixin   => 'XAS::Lib::Mixin::Keepalive'
 ;

=head1 DESCRIPTION

This module is a mixin class to share code for initializing TCP level
keepalives.

=head1 METHODS

=head2 init_keepalive

This will attempt to define the necessary variables to allow TCP keepalive
to function. Not all Perl's and OS's define the necessary values.

=head2 enable_keepalive($socket)

This will enable keepalive on the given socket. By default this will
initialize keepalive to the RFC minimal, i.e. send a keepalive packet
once every 2 hours. If the OS supports it, this will be modified to
send up to 3 keepalive packets once every 15 minutes.

This should fix those pesky firewalls...

=over 4

=item B<$socket>

The socket to enable keepalive on.

=back

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
