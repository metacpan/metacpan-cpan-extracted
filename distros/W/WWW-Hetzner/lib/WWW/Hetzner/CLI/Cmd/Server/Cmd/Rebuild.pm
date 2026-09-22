package WWW::Hetzner::CLI::Cmd::Server::Cmd::Rebuild;
# ABSTRACT: Rebuild a server with a new image

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl server rebuild <id> --image <image>';
use JSON::MaybeXS qw(encode_json);
with 'WWW::Hetzner::CLI::Role::WaitsForAction';

option image => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'Image to rebuild with (e.g., debian-12, ubuntu-24.04)',
);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl server rebuild <id> --image <image>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    print "Rebuilding server $id with image ", $self->image, "...\n";
    my $action = $cloud->servers->rebuild($id, $self->image);
    $self->handle_action($action);

    if ($main->output eq 'json') {
        print encode_json({ %{ $action->data }, %{ $action->result } }), "\n";
    } else {
        print $self->no_wait
            ? "Server rebuild requested. Data on the server will be lost.\n"
            : "Server rebuilt. Data on the server has been lost.\n";
        if (defined $action->root_password) {
            print "Root password: ", $action->root_password, "\n";
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Server::Cmd::Rebuild - Rebuild a server with a new image

=head1 VERSION

version 0.101

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
