package WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::List;
# ABSTRACT: List Storage Boxes

our $VERSION = '0.101';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl storage-box list [options]';
use JSON::MaybeXS qw(encode_json);

option name => ( is => 'ro', format => 's', short => 'n', doc => 'Filter by Storage Box name' );
option selector => ( is => 'ro', format => 's', short => 'l', doc => 'Filter by label selector' );

sub execute {
    my ($self, $args, $chain) = @_;
    my $main = $chain->[0];
    my %params;
    $params{name} = $self->name if defined $self->name;
    $params{label_selector} = $self->selector if defined $self->selector;
    my $boxes = $main->storage->storage_boxes->list_all(%params);

    if ($main->output eq 'json') {
        print encode_json([map { $_->data } @$boxes]), "\n";
        return;
    }
    if (!@$boxes) {
        print "No Storage Boxes found.\n";
        return;
    }
    printf "%-10s %-25s %-12s %-12s %s\n", 'ID', 'NAME', 'TYPE', 'LOCATION', 'STATUS';
    print '-' x 78, "\n";
    for my $box (@$boxes) {
        my $type = $box->storage_box_type;
        my $location = $box->location;
        printf "%-10s %-25s %-12s %-12s %s\n",
            $box->id,
            $box->name,
            ref $type eq 'HASH' ? ($type->{name} // '-') : ($type // '-'),
            ref $location eq 'HASH' ? ($location->{name} // '-') : ($location // '-'),
            $box->status // '-';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::StorageBox::Cmd::List - List Storage Boxes

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
