package WWW::Hetzner::CLI::Cmd::Firewall::Cmd::Describe;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Describe a firewall

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl firewall describe <id>';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl firewall describe <id>\n";

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $fw = $cloud->firewalls->get($id);

    if ($main->output eq 'json') {
        print encode_json($fw->data), "\n";
        return;
    }

    printf "ID:      %s\n", $fw->id;
    printf "Name:    %s\n", $fw->name;
    printf "Created: %s\n", $fw->created // '-';

    my $rules = $fw->rules;
    if ($rules && @$rules) {
        print "\nRules:\n";
        for my $r (@$rules) {
            my $port = $r->{port} // 'any';
            my $proto = $r->{protocol} // 'any';
            my $dir = $r->{direction} // 'in';
            my $sources = $r->{source_ips} ? join(', ', @{$r->{source_ips}}) : 'any';
            my $dests = $r->{destination_ips} ? join(', ', @{$r->{destination_ips}}) : 'any';

            if ($dir eq 'in') {
                printf "  - %s %s/%s from %s\n", $dir, $proto, $port, $sources;
            } else {
                printf "  - %s %s/%s to %s\n", $dir, $proto, $port, $dests;
            }
        }
    }

    my $applied = $fw->applied_to;
    if ($applied && @$applied) {
        print "\nApplied to:\n";
        for my $a (@$applied) {
            my $type = $a->{type};
            if ($type eq 'server' && $a->{server}) {
                printf "  - Server %d\n", $a->{server}{id};
            } elsif ($type eq 'label_selector' && $a->{label_selector}) {
                printf "  - Label: %s\n", $a->{label_selector}{selector};
            }
        }
    }

    my $labels = $fw->labels;
    if ($labels && %$labels) {
        print "\nLabels:\n";
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

WWW::Hetzner::CLI::Cmd::Firewall::Cmd::Describe - Describe a firewall

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
