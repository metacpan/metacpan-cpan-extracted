package WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::List;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List dedicated servers

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hrobot.pl server list [options]';


sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    my $servers = $robot->servers->list;

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json([map { +{
            server_number => $_->server_number,
            server_name   => $_->server_name,
            server_ip     => $_->server_ip,
            product       => $_->product,
            dc            => $_->dc,
            status        => $_->status,
        } } @$servers]);
        print "\n";
    } else {
        printf "%-12s %-20s %-15s %-20s %s\n",
            'NUMBER', 'NAME', 'IP', 'PRODUCT', 'DC';
        for my $s (@$servers) {
            printf "%-12s %-20s %-15s %-20s %s\n",
                $s->server_number // '',
                $s->server_name // '',
                $s->server_ip // '',
                $s->product // '',
                $s->dc // '';
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::List - List dedicated servers

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    hrobot.pl server list
    hrobot.pl server list -o json

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
