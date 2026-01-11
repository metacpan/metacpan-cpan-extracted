package WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Describe a floating IP

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl floating-ip describe <id>';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl floating-ip describe <id>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $fip = $cloud->floating_ips->get($id);

    if ($main->output eq 'json') {
        print encode_json($fip->data), "\n";
        return;
    }

    printf "ID:          %s\n", $fip->id;
    printf "Name:        %s\n", $fip->name // '-';
    printf "Description: %s\n", $fip->description // '-';
    printf "IP:          %s\n", $fip->ip;
    printf "Type:        %s\n", $fip->type;
    printf "Location:    %s\n", $fip->location // '-';
    printf "Server:      %s\n", $fip->server // 'not assigned';
    printf "Blocked:     %s\n", $fip->blocked ? 'yes' : 'no';
    printf "Created:     %s\n", $fip->created // '-';

    my $dns_ptr = $fip->dns_ptr;
    if ($dns_ptr && @$dns_ptr) {
        print "DNS PTR:\n";
        for my $ptr (@$dns_ptr) {
            printf "  %s -> %s\n", $ptr->{ip}, $ptr->{dns_ptr};
        }
    }

    my $labels = $fip->labels;
    if ($labels && %$labels) {
        print "Labels:\n";
        for my $k (sort keys %$labels) {
            printf "  %s: %s\n", $k, $labels->{$k};
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Describe - Describe a floating IP

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
