package WWW::Hetzner::CLI::Cmd::Record::Cmd::Create;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Create a DNS record

our $VERSION = '0.002';

use Moo;
use MooX::Cmd;
use MooX::Options usage_string => 'USAGE: hcloud.pl record create --zone <zone-id> --name <name> --type <type> --value <value>';
use JSON::MaybeXS qw(encode_json);

option zone => (
    is       => 'ro',
    format   => 's',
    short    => 'z',
    required => 1,
    doc      => 'Zone ID',
);

option name => (
    is       => 'ro',
    format   => 's',
    short    => 'n',
    required => 1,
    doc      => 'Record name (e.g., www, @, mail)',
);

option type => (
    is       => 'ro',
    format   => 's',
    short    => 't',
    required => 1,
    doc      => 'Record type (A, AAAA, CNAME, MX, TXT, etc.)',
);

option value => (
    is       => 'ro',
    format   => 's@',
    short    => 'v',
    required => 1,
    autosplit => ',',
    doc      => 'Record value(s), comma-separated for multiple',
);

option ttl => (
    is     => 'ro',
    format => 'i',
    doc    => 'TTL in seconds',
);

sub execute {
    my ($self, $args, $chain) = @_;

    my $main = $chain->[0];
    my $cloud = $main->cloud;

    my @records = map { { value => $_ } } @{$self->value};

    my %params = (
        name    => $self->name,
        type    => uc($self->type),
        records => \@records,
    );
    $params{ttl} = $self->ttl if $self->ttl;

    my $rrsets = $cloud->zones->rrsets($self->zone);
    my $record = $rrsets->create(%params);

    if ($main->output eq 'json') {
        print encode_json($record->data), "\n";
        return;
    }

    print "Record created:\n";
    printf "  Name: %s\n", $record->name;
    printf "  Type: %s\n", $record->type;
    printf "  TTL:  %s\n", $record->ttl // '-';
    print "  Values:\n";
    for my $v (@{$record->records}) {
        print "    - $v->{value}\n";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::CLI::Cmd::Record::Cmd::Create - Create a DNS record

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
