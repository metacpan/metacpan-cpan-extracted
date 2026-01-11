package WWW::Hetzner::CLI::Cmd::Zone::Cmd::List;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: List DNS zones

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl zone list [options]';
use JSON::MaybeXS qw(encode_json);

option selector => (
    is     => 'ro',
    format => 's',
    short  => 'l',
    doc    => 'Label selector (e.g., env=prod)',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my %params;
    $params{label_selector} = $self->selector if $self->selector;

    my $zones = $cloud->zones->list(%params);

    if ($main->output eq 'json') {
        print encode_json([map { $_->data } @$zones]), "\n";
        return;
    }

    if (!@$zones) {
        print "No zones found.\n";
        return;
    }

    printf "%-15s %-30s %-10s %-8s %s\n",
        'ID', 'NAME', 'STATUS', 'TTL', 'LABELS';
    print "-" x 80, "\n";

    for my $z (@$zones) {
        my $labels = $z->labels;
        my $label_str = join(', ', map { "$_=$labels->{$_}" } keys %$labels);
        printf "%-15s %-30s %-10s %-8s %s\n",
            $z->id,
            $z->name,
            $z->status // '-',
            $z->ttl // '-',
            $label_str || '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Zone::Cmd::List - List DNS zones

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
