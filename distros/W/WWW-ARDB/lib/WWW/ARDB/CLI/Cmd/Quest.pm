package WWW::ARDB::CLI::Cmd::Quest;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: Show quest details command

use Moo;
use MooX::Cmd;
use JSON::MaybeXS;

our $VERSION = '0.002';


sub execute {
    my ($self, $args, $chain) = @_;
    my $app = $chain->[0];

    my $id = $args->[0];
    unless ($id) {
        print "Usage: ardb quest <id>\n";
        print "Example: ardb quest picking_up_the_pieces\n";
        return;
    }

    my $quest = $app->api->quest($id);

    unless ($quest) {
        print "Quest not found: $id\n";
        return;
    }

    if ($app->json) {
        print JSON::MaybeXS->new(utf8 => 1, pretty => 1)->encode($quest->_raw);
        return;
    }

    print "=" x 60 . "\n";
    print $quest->title . "\n";
    print "=" x 60 . "\n\n";

    print "ID:      " . $quest->id . "\n";

    if ($quest->trader) {
        print "Trader:  " . $quest->trader_name;
        print " (" . $quest->trader_type . ")" if $quest->trader_type;
        print "\n";
    }

    print "XP:      " . ($quest->xp_reward // 0) . "\n";

    if ($quest->description) {
        print "\nDescription:\n";
        print "  " . $quest->description . "\n";
    }

    if (@{$quest->steps}) {
        print "\nObjectives:\n";
        for my $step (@{$quest->steps}) {
            if ($step->{amount} && $step->{amount} > 1) {
                printf "  [ ] %s (x%d)\n", $step->{title}, $step->{amount};
            } else {
                print "  [ ] " . $step->{title} . "\n";
            }
        }
    }

    if (@{$quest->maps}) {
        print "\nAvailable Maps:\n";
        for my $map (@{$quest->maps}) {
            print "  - " . $map->{name} . "\n";
        }
    }

    if (@{$quest->required_items}) {
        print "\nRequired Items:\n";
        for my $req (@{$quest->required_items}) {
            my $item = $req->{item} // $req;
            printf "  - %dx %s\n",
                $req->{amount} // 1,
                $item->{name} // $req->{name} // $req->{id};
        }
    }

    if (@{$quest->rewards}) {
        print "\nRewards:\n";
        for my $reward (@{$quest->rewards}) {
            my $item = $reward->{item} // $reward;
            my $note = $reward->{grantedOnAccept} ? ' (on accept)' : '';
            printf "  - %dx %s%s\n",
                $reward->{amount} // 1,
                $item->{name} // $reward->{name} // $reward->{id},
                $note;
        }
    }

    print "\nLast Updated: " . ($quest->updated_at // 'unknown') . "\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::CLI::Cmd::Quest - Show quest details command

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    ardb quest picking_up_the_pieces
    ardb quest first_delivery --json

=head1 DESCRIPTION

CLI command to show detailed information for a specific quest from the ARC
Raiders Database, including objectives, rewards, and required items.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-ardb/issues>.

=head2 IRC

You can reach Getty on C<irc.perl.org> for questions and support.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
