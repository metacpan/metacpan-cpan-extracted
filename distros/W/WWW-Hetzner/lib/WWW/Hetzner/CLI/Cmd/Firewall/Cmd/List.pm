package WWW::Hetzner::CLI::Cmd::Firewall::Cmd::List;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List firewalls

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl firewall list';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $firewalls = $cloud->firewalls->list;

    if ($main->output eq 'json') {
        print encode_json([ map { $_->data } @$firewalls ]), "\n";
        return;
    }

    if (!@$firewalls) {
        print "No firewalls found.\n";
        return;
    }

    printf "%-8s %-30s %-8s %-12s\n", 'ID', 'NAME', 'RULES', 'APPLIED_TO';
    printf "%-8s %-30s %-8s %-12s\n", '-' x 8, '-' x 30, '-' x 8, '-' x 12;

    for my $fw (@$firewalls) {
        printf "%-8s %-30s %-8d %-12d\n",
            $fw->id,
            $fw->name // '-',
            scalar(@{ $fw->rules // [] }),
            scalar(@{ $fw->applied_to // [] });
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Firewall::Cmd::List - List firewalls

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
