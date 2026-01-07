package WWW::ARDB::CLI::Cmd::Enemy;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Show ARC enemy details command

use Moo;
use MooX::Cmd;
use JSON::MaybeXS;

our $VERSION = '0.001';

sub execute {
    my ($self, $args, $chain) = @_;
    my $app = $chain->[0];

    my $id = $args->[0];
    unless ($id) {
        print "Usage: ardb enemy <id>\n";
        print "Example: ardb enemy wasp\n";
        return;
    }

    my $enemy = $app->api->arc_enemy($id);

    unless ($enemy) {
        print "Enemy not found: $id\n";
        return;
    }

    if ($app->json) {
        print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode($enemy->_raw);
        return;
    }

    print "=" x 60 . "\n";
    print $enemy->name . "\n";
    print "=" x 60 . "\n\n";

    print "ID:    " . $enemy->id . "\n";

    if ($enemy->icon) {
        print "Icon:  " . $enemy->icon_url . "\n";
    }

    if ($enemy->image) {
        print "Image: " . $enemy->image_url . "\n";
    }

    if (@{$enemy->drop_table}) {
        print "\nDrop Table:\n";
        printf "  %-25s %-12s %8s\n", 'Item', 'Rarity', 'Value';
        print "  " . "-" x 48 . "\n";

        for my $drop (@{$enemy->drop_table}) {
            printf "  %-25s %-12s %8s\n",
                substr($drop->{name}, 0, 25),
                $drop->{rarity} // '-',
                $drop->{value} // '-';
        }
    }

    if (@{$enemy->related_maps}) {
        print "\nLocations:\n";
        for my $map (@{$enemy->related_maps}) {
            print "  - " . $map->{name} . "\n";
        }
    }

    print "\nLast Updated: " . ($enemy->updated_at // 'unknown') . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::CLI::Cmd::Enemy - Show ARC enemy details command

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
