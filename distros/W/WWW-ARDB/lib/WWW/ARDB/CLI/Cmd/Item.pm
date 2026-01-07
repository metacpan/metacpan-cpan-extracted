package WWW::ARDB::CLI::Cmd::Item;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Show item details command

use Moo;
use MooX::Cmd;
use JSON::MaybeXS;

our $VERSION = '0.001';

sub execute {
    my ($self, $args, $chain) = @_;
    my $app = $chain->[0];

    my $id = $args->[0];
    unless ($id) {
        print "Usage: ardb item <id>\n";
        print "Example: ardb item acoustic_guitar\n";
        return;
    }

    my $item = $app->api->item($id);

    unless ($item) {
        print "Item not found: $id\n";
        return;
    }

    if ($app->json) {
        print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode($item->_raw);
        return;
    }

    print "=" x 60 . "\n";
    print $item->name . "\n";
    print "=" x 60 . "\n\n";

    _print_field("ID",          $item->id);
    _print_field("Type",        $item->type);
    _print_field("Rarity",      $item->rarity);
    _print_field("Value",       $item->value);
    _print_field("Weight",      $item->weight);
    _print_field("Stack Size",  $item->stack_size);

    if ($item->description) {
        print "\nDescription:\n";
        print "  " . $item->description . "\n";
    }

    if (@{$item->found_in}) {
        print "\nFound In:\n";
        for my $loc (@{$item->found_in}) {
            print "  - $loc\n";
        }
    }

    if (@{$item->breakdown}) {
        print "\nBreakdown Components:\n";
        for my $comp (@{$item->breakdown}) {
            printf "  - %dx %s (%s)\n",
                $comp->{amount} // 1,
                $comp->{name},
                $comp->{rarity} // 'common';
        }
    }

    if (@{$item->crafting}) {
        print "\nCrafting Requirements:\n";
        for my $req (@{$item->crafting}) {
            printf "  - %dx %s\n",
                $req->{amount} // 1,
                $req->{name} // $req->{id};
        }
    }

    print "\nLast Updated: " . ($item->updated_at // 'unknown') . "\n";
}

sub _print_field {
    my ($label, $value) = @_;
    return unless defined $value;
    printf "%-15s %s\n", "$label:", $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::CLI::Cmd::Item - Show item details command

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
