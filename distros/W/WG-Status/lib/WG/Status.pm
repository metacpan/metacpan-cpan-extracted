package WG::Status;

use 5.022002;
use strict;
use warnings;


our $VERSION    = '0.04';

require Exporter;
our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw(wg_status kernel_module);


# our possible peer attributes: not every peer will have all attributes
#my @attr = ('peer',
#            'endpoint',
#            'allowed ips',
#            'latest handshake',
#            'transfer',
#            'persistent keepalive'
#           );



sub wg_status {
  my $WG = shift;

  open (my $showall, "$WG show all |");
  local $/  = undef;
  my $show  = <$showall>;
  close $showall;

  my @interface = split /interface: /, $show;
  shift @interface;   # lose the first "entry", since it's bogus

  my $wg;     # our data structure

  my $ifcount;
  foreach my $if (@interface) {
    $ifcount++;
    my @stanza    = split /peer: /, $if;
    my $peercount = -1;
    my $ifdef;
    my @peers;
    foreach my $peer (@stanza) {
      $peercount++;
      my $peerdef;
      if ($peercount) {
        $peerdef  = parse_peer($peer);
      } else {
        # special case (not a peer definition, but an interface def)
        $ifdef    = parse_interface($peer);
      }
      push @peers, $peerdef if defined $peerdef;
      $$ifdef{peers} = \@peers;
    }
    push @{$wg}, $ifdef;
  }

  return $wg;
}



sub kernel_module {
  # probably need to look at this once we get to kernel version 5.6
  open (my $grepmod, "lsmod | grep -c wireguard |");
  my $lsmod = <$grepmod>;
  close $grepmod;
  chomp $lsmod;

  return $lsmod;
}


sub parse_interface {
  my $interface = shift;

  my @line  = split /\n/, $interface;
  my %ifdef;
  foreach my $line (@line) {
    $line   =~ s/^\ +//g;
    my @parts = split / /, $line;
    if    ($line =~ /^wg\d+/)             { $ifdef{interface}         = $line }
    elsif ($line =~ /^public\ key:/)      { $ifdef{'public key'}      = $parts[2] }
    elsif ($line =~ /^listening port:/)   { $ifdef{'listening port'}  = $parts[2] }
  }

  return \%ifdef;
}



sub parse_peer {
  my $peer = shift;

  my @line = split /\n/, $peer;
  my %peerdef;
  foreach my $line (@line) {
    $line   =~ s/^\ +//g;
    my @parts = split / /, $line;
    if    ($line =~ /^.{43,}$/)                 { $peerdef{'peer'}                  = $line }

    elsif ($line =~ /^endpoint:/)               { $peerdef{'endpoint'}              = $parts[1] }

    elsif ($line =~ /^allowed ips:/)            { shift @parts;
                                                  shift @parts;
                                                  $peerdef{'allowed ips'}           = join ' ', @parts;
                                                }

    elsif ($line =~ /^latest\ handshake:/)      { shift @parts;
                                                  shift @parts;
                                                  $peerdef{'latest handshake'}      = join ' ', @parts;
                                                }

    elsif ($line =~ /^transfer:/)               { shift @parts;
                                                  $peerdef{'transfer'}              = join ' ', @parts;
                                                }

    elsif ($line =~ /^persistent\ keepalive:/)  { shift @parts;
                                                  shift @parts;
                                                  $peerdef{'persistent keepalive'}  = join ' ', @parts;
                                                }
  }

  return \%peerdef;
}



1;

__END__

=head1 NAME

WG::Status - Perl module to parse WireGuard VPN instances

=head1 DESCRIPTION

WG::Status parses the output of a WireGuard VPN "wg show all" command
and turns it into a Perl data structure.

=head1 SYNOPSIS

*NOTE:* all WireGuard commands must be run as root or via sudo, so execute
accordingly.


use WG::Status qw(wg_status kernel_module);

# where does your Linux distribution put things?
my $WG = '/usr/bin/wg';


# this won't work on BSD or Windows, obviously
my $loadedmodule = kernel_module();
die "WireGuard kernel module not loaded" unless $loadedmodule;

# get our data structure
my $wg = wg_status($WG);

running

  foreach my $instance (@$wg) {
    foreach (keys %$instance) {
      print "$_: $$instance{$_}\n";
    }
  }

gives us

  public key: bbIdn6VAL1bCzbDSgmzH3XcUFN088STLiAB4KvgO1Bo=
  listening port: 9820
  interface: wg0
  peers: ARRAY(0x116dc30)

...and so on.


=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

   none

=head2 EXPORT

wg_status
kernel_module



=head1 SEE ALSO

Tracked at https://gitlab.com/mmlj4/wg-status

=head1 AUTHOR

Joey Kelly, <lt>joey@joeykelly.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Joey Kelly

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as published
by the Free Software Foundation

=cut

