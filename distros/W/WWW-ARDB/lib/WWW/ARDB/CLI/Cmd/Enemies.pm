package WWW::ARDB::CLI::Cmd::Enemies;
our $AUTHORITY = 'cpan:GETTY';

# ABSTRACT: List ARC enemies command

use Moo;
use MooX::Cmd;
use MooX::Options;

our $VERSION = '0.002';


option search => (
    is      => 'ro',
    short   => 's',
    format  => 's',
    doc     => 'Search enemies by name',
);


sub execute {
    my ($self, $args, $chain) = @_;

    my $app = $chain->[0];
    my $enemies = $app->api->arc_enemies;

    # Apply filters
    if ($self->search) {
        my $search = lc($self->search);
        $enemies = [ grep { index(lc($_->name), $search) >= 0 } @$enemies ];
    }

    if ($app->json) {
        $app->output_json([ map { $_->_raw } @$enemies ]);
        return;
    }

    if (@$enemies == 0) {
        print "No enemies found.\n";
        return;
    }

    printf "%-25s %-30s\n", 'Name', 'ID';
    print "-" x 55 . "\n";

    for my $enemy (@$enemies) {
        printf "%-25s %-30s\n",
            $enemy->name,
            $enemy->id;
    }

    print "\n" . scalar(@$enemies) . " enemies found.\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::ARDB::CLI::Cmd::Enemies - List ARC enemies command

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    ardb enemies
    ardb enemies --search wasp

=head1 DESCRIPTION

CLI command to list all ARC enemies from the ARC Raiders Database with optional
filtering by name.

=head2 search

    ardb enemies --search wasp
    ardb enemies -s drone

Case-insensitive substring search for enemies by name.

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
