package WWW::Hetzner::CLI::Cmd::Server::Cmd::Rescue;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Enable or disable rescue mode

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl server rescue <id> [--disable] [--type linux64|linux32]';
use JSON::MaybeXS qw(encode_json);

option disable => (
    is      => 'ro',
    doc     => 'Disable rescue mode instead of enabling',
    default => 0,
);

option type => (
    is      => 'ro',
    format  => 's',
    doc     => 'Rescue system type: linux64, linux32 (default: linux64)',
    default => 'linux64',
);

option ssh_key => (
    is        => 'ro',
    format    => 's@',
    doc       => 'SSH key name or ID (repeatable)',
    autosplit => ',',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl server rescue <id> [--disable]\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    if ($self->disable) {
        print "Disabling rescue mode for server $id...\n";
        $cloud->servers->disable_rescue($id);
        print "Rescue mode disabled.\n";
    } else {
        print "Enabling rescue mode for server $id...\n";
        my $result = $cloud->servers->enable_rescue($id,
            type     => $self->type,
            ssh_keys => $self->ssh_key,
        );

        if ($main->output eq 'json') {
            print encode_json($result), "\n";
        } else {
            print "Rescue mode enabled.\n";
            if ($result->{root_password}) {
                print "Root password: $result->{root_password}\n";
            }
            print "Reboot the server to enter rescue mode.\n";
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Server::Cmd::Rescue - Enable or disable rescue mode

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
