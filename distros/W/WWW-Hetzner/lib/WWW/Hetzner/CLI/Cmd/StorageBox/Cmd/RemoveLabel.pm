package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RemoveLabel;
# ABSTRACT: Remove a label from a Storage Box

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options protect_argv => 0, usage_string => 'USAGE: hcloud.pl storage-box remove-label <storage-box> <key>';
use JSON::MaybeXS qw(encode_json);


sub execute {
    my ($self, $args, $chain) = @_;
    my $id  = $args->[0] or die "Usage: hcloud.pl storage-box remove-label <storage-box> <key>\n";
    my $key = $args->[1] or die "Usage: hcloud.pl storage-box remove-label <storage-box> <key>\n";

    my $main = $chain->[0];
    my $box  = $main->storage->storage_boxes->get($id);
    my %labels = %{ $box->labels // {} };
    delete $labels{$key};
    my $updated = $main->storage->storage_boxes->update($id, labels => \%labels);

    if ($main->output eq 'json') {
        print encode_json($updated->data), "\n";
        return;
    }

    print "Storage Box labels updated:\n";
    printf "  ID:   %s\n", $updated->id;
    printf "  Name: %s\n", $updated->name;
    my $new_labels = $updated->labels // {};
    if (%$new_labels) {
        print "  Labels:\n";
        printf "    %s: %s\n", $_, $new_labels->{$_} for sort keys %$new_labels;
    } else {
        print "  Labels: (none)\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::RemoveLabel - Remove a label from a Storage Box

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    hcloud.pl storage-box remove-label 42 team

=head1 DESCRIPTION

Reads the Storage Box, removes the supplied label key from the existing
label set, and writes it back. Other labels are preserved.

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
