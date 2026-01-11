package WWW::ARDB::CLI::Cmd::Quests;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: List quests command

use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.002';


option search => (
    is      => 'ro',
    short   => 's',
    format  => 's',
    doc     => 'Search quests by title',
);


option trader => (
    is      => 'ro',
    short   => 't',
    format  => 's',
    doc     => 'Filter by trader name',
);


sub execute {
    my ($self, $args, $chain) = @_;

    my $app = $chain->[0];
    my $quests = $app->api->quests;

    # Apply filters
    if ($self->search) {
        my $search = lc($self->search);
        $quests = [ grep { index(lc($_->title), $search) >= 0 } @$quests ];
    }

    if ($self->trader) {
        my $trader = lc($self->trader);
        $quests = [ grep {
            $_->trader_name && index(lc($_->trader_name), $trader) >= 0
        } @$quests ];
    }

    if ($app->json) {
        $app->output_json([ map { $_->_raw } @$quests ]);
        return;
    }

    if (@$quests == 0) {
        print "No quests found.\n";
        return;
    }

    printf "%-35s %-15s %8s\n", 'Title', 'Trader', 'XP';
    print "-" x 60 . "\n";

    for my $quest (@$quests) {
        printf "%-35s %-15s %8s\n",
            substr($quest->title, 0, 35),
            substr($quest->trader_name // '-', 0, 15),
            $quest->xp_reward // '-';
    }

    print "\n" . scalar(@$quests) . " quests found.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::CLI::Cmd::Quests - List quests command

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    ardb quests
    ardb quests --search pieces
    ardb quests --trader shani

=head1 DESCRIPTION

CLI command to list all quests from the ARC Raiders Database with optional
filtering by title or trader name.

=head2 search

    ardb quests --search pieces
    ardb quests -s delivery

Case-insensitive substring search for quests by title.

=head2 trader

    ardb quests --trader shani
    ardb quests -t quinn

Case-insensitive substring search for quests by trader/quest giver name.

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
