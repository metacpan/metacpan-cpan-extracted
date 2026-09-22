package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Describe;
# ABSTRACT: Describe a Storage Box

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box describe <storage-box>';
use JSON::MaybeXS qw(encode_json);

sub execute {
    my ($self, $args, $chain) = @_;
    my $id = $args->[0] or die "Usage: hcloud.pl storage-box describe <storage-box>\n";
    my $main = $chain->[0];
    my $box = $main->storage->storage_boxes->get($id);

    if ($main->output eq 'json') {
        print encode_json($box->data), "\n";
        return;
    }

    my $type = $box->storage_box_type;
    my $location = $box->location;
    print "Storage Box:\n";
    printf "  ID:       %s\n", $box->id;
    printf "  Name:     %s\n", $box->name;
    printf "  Type:     %s\n", ref $type eq 'HASH' ? ($type->{name} // '-') : ($type // '-');
    printf "  Location: %s\n", ref $location eq 'HASH' ? ($location->{name} // '-') : ($location // '-');
    printf "  Status:   %s\n", $box->status // '-';
    printf "  Username: %s\n", $box->username // '-';
    printf "  Server:   %s\n", $box->server // '-';
    my $labels = $box->labels // {};
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

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::Describe - Describe a Storage Box

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
