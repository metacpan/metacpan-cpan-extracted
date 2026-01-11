package WWW::Hetzner::Robot::CLI::Cmd::Key;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Robot SSH key commands

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hrobot.pl key [options]';


sub execute {
    my ($self, $args, $chain) = @_;
    my $root = $chain->[0];
    my $robot = $root->robot;

    # Default: list keys
    my $keys = $robot->keys->list;

    if ($root->output eq 'json') {
        require JSON::MaybeXS;
        print JSON::MaybeXS::encode_json([map { +{
            name        => $_->name,
            fingerprint => $_->fingerprint,
            type        => $_->type,
            size        => $_->size,
        } } @$keys]);
        print "\n";
    } else {
        printf "%-20s %-50s %-10s %s\n", 'NAME', 'FINGERPRINT', 'TYPE', 'SIZE';
        for my $k (@$keys) {
            printf "%-20s %-50s %-10s %s\n",
                $k->name // '',
                $k->fingerprint // '',
                $k->type // '',
                $k->size // '';
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::CLI::Cmd::Key - Robot SSH key commands

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    hrobot.pl key
    hrobot.pl key -o json

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

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
