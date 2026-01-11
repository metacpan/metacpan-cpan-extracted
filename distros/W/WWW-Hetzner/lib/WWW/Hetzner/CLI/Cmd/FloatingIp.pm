package WWW::Hetzner::CLI::Cmd::FloatingIp;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Cloud Floating IP commands

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl floating-ip <subcommand>';

sub execute {
    my ($self) = @_;
    print "Usage: hcloud.pl floating-ip <subcommand>\n\n";
    print "Subcommands:\n";
    print "  list       List all floating IPs\n";
    print "  describe   Show floating IP details\n";
    print "  create     Create a floating IP\n";
    print "  delete     Delete a floating IP\n";
    print "  assign     Assign to a server\n";
    print "  unassign   Unassign from server\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::FloatingIp - Hetzner Cloud Floating IP commands

=head1 VERSION

version 0.002

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

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
