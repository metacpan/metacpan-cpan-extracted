package WWW::ARDB::CLI::Cmd::Items;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: List items command

use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.001';

option search => (
    is      => 'ro',
    short   => 's',
    format  => 's',
    doc     => 'Search items by name',
);

option type => (
    is      => 'ro',
    short   => 't',
    format  => 's',
    doc     => 'Filter by type',
);

option rarity => (
    is      => 'ro',
    short   => 'r',
    format  => 's',
    doc     => 'Filter by rarity',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $app = $chain->[0];
    my $items = $app->api->items;

    # Apply filters
    if ($self->search) {
        my $search = lc($self->search);
        $items = [ grep { index(lc($_->name), $search) >= 0 } @$items ];
    }

    if ($self->type) {
        my $type = lc($self->type);
        $items = [ grep { $_->type && lc($_->type) eq $type } @$items ];
    }

    if ($self->rarity) {
        my $rarity = lc($self->rarity);
        $items = [ grep { $_->rarity && lc($_->rarity) eq $rarity } @$items ];
    }

    if ($app->json) {
        $app->output_json([ map { $_->_raw } @$items ]);
        return;
    }

    if (@$items == 0) {
        print "No items found.\n";
        return;
    }

    printf "%-30s %-12s %-15s %8s\n", 'Name', 'Rarity', 'Type', 'Value';
    print "-" x 70 . "\n";

    for my $item (@$items) {
        printf "%-30s %-12s %-15s %8s\n",
            substr($item->name, 0, 30),
            $item->rarity // '-',
            substr($item->type // '-', 0, 15),
            $item->value // '-';
    }

    print "\n" . scalar(@$items) . " items found.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::CLI::Cmd::Items - List items command

=head1 VERSION

version 0.001

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-www-ardb>

  git clone https://github.com/Getty/p5-www-ardb.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
