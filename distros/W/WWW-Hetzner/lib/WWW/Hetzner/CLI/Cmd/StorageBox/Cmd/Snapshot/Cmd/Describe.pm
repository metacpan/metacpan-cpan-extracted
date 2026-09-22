package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Describe;
# ABSTRACT: Describe a Storage Box snapshot

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box snapshot describe <storage-box> <snapshot>';
use JSON::MaybeXS qw(encode_json);
use WWW::Hetzner::Storage::API::Snapshots;


sub execute {
    my ($self, $args, $chain) = @_;
    my $id   = $args->[0] or die "Usage: hcloud.pl storage-box snapshot describe <storage-box> <snapshot>\n";
    my $snap = $args->[1] or die "Usage: hcloud.pl storage-box snapshot describe <storage-box> <snapshot>\n";
    my $main = $chain->[0];
    my $snapshots = WWW::Hetzner::Storage::API::Snapshots->new(
        client         => $main->storage,
        storage_box_id => $id,
    );
    my $snapshot = $snapshots->get($snap);

    if ($main->output eq 'json') {
        print encode_json($snapshot->data), "\n";
        return;
    }

    print "Snapshot:\n";
    printf "  ID:          %s\n", $snapshot->id;
    printf "  Name:        %s\n", $snapshot->name // '-';
    printf "  Description: %s\n", ($snapshot->description // '') ne '' ? $snapshot->description : '-';
    printf "  Created:     %s\n", $snapshot->created // '-';
    my $labels = $snapshot->labels // {};
    if (%$labels) {
        print "  Labels:\n";
        printf "    %s: %s\n", $_, $labels->{$_} for sort keys %$labels;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Snapshot::Cmd::Describe - Describe a Storage Box snapshot

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box snapshot describe 42 1
    hcloud.pl --output json storage-box snapshot describe 42 1

=head1 DESCRIPTION

Shows a single snapshot of a Storage Box.

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
