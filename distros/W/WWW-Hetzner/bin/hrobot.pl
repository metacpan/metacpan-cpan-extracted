#!/usr/bin/env perl
# PODNAME: hrobot.pl
# ABSTRACT: Hetzner Robot CLI (Perl implementation)

use strict;
use warnings;
use lib 'lib';

our $VERSION = '0.101';

use WWW::Hetzner::Robot::CLI;

WWW::Hetzner::Robot::CLI->new_with_cmd;

__END__

=pod

=encoding UTF-8

=head1 NAME

hrobot.pl - Hetzner Robot CLI (Perl implementation)

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    # List servers
    hrobot.pl server list

    # Show server details
    hrobot.pl server describe 123456

    # Boot the rescue system, then reset into it
    hrobot.pl boot rescue 123456 --enable --os linux
    hrobot.pl reset 123456 --type hw

    # Reset server
    hrobot.pl reset 123456
    hrobot.pl reset 123456 --type hw

    # List SSH keys
    hrobot.pl key list

    # JSON output
    hrobot.pl -o json server list

=head1 DESCRIPTION

Perl implementation of a CLI for the Hetzner Robot API. This is for managing
dedicated servers, unlike hcloud.pl which manages cloud servers.

=head1 OPTIONS

=over 4

=item B<-u>, B<--user>=USER

Robot webservice username. Defaults to C<HETZNER_ROBOT_USER> env.

=item B<-p>, B<--password>=PASSWORD

Robot webservice password. Defaults to C<HETZNER_ROBOT_PASSWORD> env.

=item B<-o>, B<--output>=FORMAT

Output format: C<table> (default) or C<json>.

=back

=head1 COMMANDS

=head2 server

Manage dedicated servers.

    hrobot.pl server list          # List all servers
    hrobot.pl server describe ID   # Show server details

=head2 key

Manage SSH keys.

    hrobot.pl key list             # List all keys

=head2 reset

Reset a server.

    hrobot.pl reset ID             # Software reset
    hrobot.pl reset ID --type hw   # Hardware reset
    hrobot.pl reset ID --type man  # Manual reset (technician)

=head2 wol

Wake-on-LAN.

    hrobot.pl wol ID

=head2 traffic

Query traffic statistics.

    hrobot.pl traffic --ip 1.2.3.4 --type day --from 2024-01-01T00 --to 2024-01-02T00
    hrobot.pl traffic --ip 1.2.3.4 --type month --from 2024-01-01 --to 2024-02-01
    hrobot.pl traffic --ip 1.2.3.4 --type year --from 2024-01 --to 2024-12

=head2 boot

Boot configuration: rescue system and unattended installations. Activating an
option only arms it - the server has to be reset to boot into it. The response
of an activating call carries the generated password.

    hrobot.pl boot ID                      # Status of all boot options
    hrobot.pl boot rescue ID               # Rescue system status
    hrobot.pl boot rescue ID --enable --os linux
    hrobot.pl boot rescue ID --disable
    hrobot.pl boot linux ID --enable --dist 'Debian 12 minimal' --lang en
    hrobot.pl boot vnc ID --enable --dist centOS-5.0 --lang en_US
    hrobot.pl boot windows ID --enable --os 'Windows Server 2022 Standard Edition' --lang en

=head2 rdns

Manage reverse DNS entries.

    hrobot.pl rdns                                     # List all entries
    hrobot.pl rdns 203.0.113.50                        # Show one entry
    hrobot.pl rdns 203.0.113.50 --ptr mail.example.com # Set the PTR record
    hrobot.pl rdns 203.0.113.50 --delete               # Delete the entry

=head2 failover

Manage failover IP routing.

    hrobot.pl failover                                 # List all failover IPs
    hrobot.pl failover 203.0.113.60                    # Show one failover IP
    hrobot.pl failover 203.0.113.60 --to 198.51.100.10 # Route to another server
    hrobot.pl failover 203.0.113.60 --delete           # Delete the routing

=head1 ENVIRONMENT

=over 4

=item C<HETZNER_ROBOT_USER>

Robot webservice username.

=item C<HETZNER_ROBOT_PASSWORD>

Robot webservice password.

=back

=head1 SEE ALSO

L<WWW::Hetzner::Robot>, L<https://robot.hetzner.com/doc/webservice/en.html>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
