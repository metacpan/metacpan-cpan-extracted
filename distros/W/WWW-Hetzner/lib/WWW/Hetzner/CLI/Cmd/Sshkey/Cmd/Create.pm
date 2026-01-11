package WWW::Hetzner::CLI::Cmd::Sshkey::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create an SSH key

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl sshkey create --name <name> --public-key <key>';
use JSON::MaybeXS qw(encode_json);
use Path::Tiny qw(path);

option name => (
    is       => 'ro',
    format   => 's',
    required => 1,
    doc      => 'SSH key name',
);

option public_key => (
    is     => 'ro',
    format => 's',
    doc    => 'Public key string',
);

option public_key_from_file => (
    is     => 'ro',
    format => 's',
    doc    => 'Read public key from file',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my $public_key = $self->public_key;
    if ($self->public_key_from_file) {
        $public_key = path($self->public_key_from_file)->slurp_utf8;
        $public_key =~ s/\s+$//;
    }

    die "Either --public-key or --public-key-from-file required\n"
        unless $public_key;

    my $key = $cloud->ssh_keys->create(
        name       => $self->name,
        public_key => $public_key,
    );

    if ($main->output eq 'json') {
        print encode_json($key->data), "\n";
    } else {
        print "SSH key created:\n";
        printf "  ID:          %s\n", $key->id;
        printf "  Name:        %s\n", $key->name;
        printf "  Fingerprint: %s\n", $key->fingerprint;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Sshkey::Cmd::Create - Create an SSH key

=head1 VERSION

version 0.002

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
