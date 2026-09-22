package WWW::Hetzner::Robot::CLI;

# ABSTRACT: Hetzner Robot CLI

use Moo;
use MooX::Cmd;
use MooX::Options;
use WWW::Hetzner::Robot;

our $VERSION = '0.101';


option user => (
    is     => 'ro',
    format => 's',
    short  => 'u',
    doc    => 'Robot user (default: HETZNER_ROBOT_USER env)',
    default => sub { $ENV{HETZNER_ROBOT_USER} },
);


option password => (
    is     => 'ro',
    format => 's',
    short  => 'p',
    doc    => 'Robot password (default: HETZNER_ROBOT_PASSWORD env)',
    default => sub { $ENV{HETZNER_ROBOT_PASSWORD} },
);


option output => (
    is      => 'ro',
    format  => 's',
    short   => 'o',
    doc     => 'Output format: table, json (default: table)',
    default => 'table',
);


has robot => (
    is      => 'lazy',
    builder => sub {
        my ($self) = @_;
        WWW::Hetzner::Robot->new(
            user     => $self->user,
            password => $self->password,
        );
    },
);


sub execute {
    my ($self, $args, $chain) = @_;

    print "Usage: hrobot.pl [options] <command> [command-options]\n\n";
    print "Global options (must come BEFORE the command):\n";
    print "  -u, --user       Robot webservice user\n";
    print "  -p, --password   Robot webservice password\n";
    print "  -o, --output     Output format: table, json\n";
    print "\nCommands:\n";
    print "  server    Manage dedicated servers\n";
    print "  key       Manage SSH keys\n";
    print "  reset     Reset a server\n";
    print "  wol       Wake-on-LAN\n";
    print "  traffic   Query traffic statistics\n";
    print "  boot      Boot configuration (rescue, linux, vnc, windows)\n";
    print "  rdns      Manage reverse DNS entries\n";
    print "  failover  Manage failover IP routing\n";
    print "\nExamples:\n";
    print "  hrobot.pl server list\n";
    print "  hrobot.pl -u user -p pass server list\n";
    print "  hrobot.pl --output json server describe 123456\n";
    print "  hrobot.pl boot rescue 123456 --enable --os linux\n";
    print "  hrobot.pl failover 203.0.113.60 --to 198.51.100.10\n";
    print "\nEnvironment variables:\n";
    print "  HETZNER_ROBOT_USER      Default for --user\n";
    print "  HETZNER_ROBOT_PASSWORD  Default for --password\n";
    print "\nRun 'hrobot.pl <command> --help' for command-specific options.\n";
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI - Hetzner Robot CLI

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    use WWW::Hetzner::Robot::CLI;
    WWW::Hetzner::Robot::CLI->new_with_cmd;

=head1 DESCRIPTION

CLI for the Hetzner Robot API (dedicated servers).

This is a Perl implementation to manage dedicated servers via the Robot API.

=head1 COMMANDS

=over 4

=item * L<server|WWW::Hetzner::Robot::CLI::Cmd::Server> - Manage dedicated servers

=item * L<key|WWW::Hetzner::Robot::CLI::Cmd::Key> - Manage SSH keys

=item * L<reset|WWW::Hetzner::Robot::CLI::Cmd::Reset> - Reset a server

=item * L<wol|WWW::Hetzner::Robot::CLI::Cmd::Wol> - Send Wake-on-LAN packet

=item * L<traffic|WWW::Hetzner::Robot::CLI::Cmd::Traffic> - Query traffic statistics

=item * L<boot|WWW::Hetzner::Robot::CLI::Cmd::Boot> - Boot configuration (rescue system, installations)

=item * L<rdns|WWW::Hetzner::Robot::CLI::Cmd::Rdns> - Manage reverse DNS entries

=item * L<failover|WWW::Hetzner::Robot::CLI::Cmd::Failover> - Manage failover IP routing

=back

=head2 user

Robot webservice username. Use C<--user> or C<-u> flag, or set via
C<HETZNER_ROBOT_USER> environment variable.

=head2 password

Robot webservice password. Use C<--password> or C<-p> flag, or set via
C<HETZNER_ROBOT_PASSWORD> environment variable.

=head2 output

Output format: C<table> (default) or C<json>. Use C<--output> or C<-o> flag.

=head2 robot

L<WWW::Hetzner::Robot> instance.

=head2 execute

Main entry point. Shows help when no subcommand is given.

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner> - Main umbrella module

=item * L<WWW::Hetzner::Robot> - Robot API client

=item * L<https://robot.hetzner.com/doc/webservice/en.html> - Official Robot API documentation

=back

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
