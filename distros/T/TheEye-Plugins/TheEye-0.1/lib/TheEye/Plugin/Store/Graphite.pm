package TheEye::Plugin::Store::Graphite;

use 5.010;
use Mouse::Role;
use Net::Graphite;
use Carp;

# ABSTRACT: Graphite plugin for TheEye
#
our $VERSION = '0.1'; # VERSION

has 'graphite_host' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'localhost' },
);

has 'graphite_port' => (
    is      => 'rw',
    isa     => 'Int',
    lazy    => 1,
    default => sub { 2003 },
);

has 'graphite_proto' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'tcp' },
);

around 'save' => sub {
    my $orig = shift;
    my ($self, $tests) = @_;

    my $graphite = Net::Graphite->new(
        host            => $self->graphite_host,
        port            => $self->graphite_port,
        proto           => $self->graphite_proto,
        fire_and_forget => 1,
    );

    foreach my $result (@{$tests}) {

        my @path = split(/\//, $result->{file});
        my ($file) = split(/\./, pop(@path));

        my $service = 'tests.' . $self->hostname . '.' . $file;
        eval {
            $graphite->send(
                path  => "$service.ok",
                value => $result->{passed});
        };
        carp "sending metric failed: $@" if $@;
        eval {
            $graphite->send(
                path  => "$service.nok",
                value => $result->{failed});
        };
        carp "sending metric failed: $@" if $@;
        eval {
            $graphite->send(
                path  => "$service.delta",
                value => $result->{delta});
        };
        carp "sending metric failed: $@" if $@;

    }
    return;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Store::Graphite - Graphite plugin for TheEye

=head1 VERSION

version 0.1

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
