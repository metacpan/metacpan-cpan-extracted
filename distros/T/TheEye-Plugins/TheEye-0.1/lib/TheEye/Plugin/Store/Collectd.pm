package TheEye::Plugin::Store::Collectd;

use 5.010;
use Mouse::Role;
use Collectd::Unixsock;

# ABSTRACT: Collectd plugin for TheEye
#
our $VERSION = '0.1'; # VERSION

has 'collectd_socket' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    lazy     => 1,
    default  => '/var/run/collectd-unixsock'
);


around 'save' => sub {
    my $orig = shift;
    my ( $self, $tests ) = @_;

    return unless -S $self->collectd_socket;
    my $sock = Collectd::Unixsock->new( $self->collectd_socket );
    foreach my $result (@{$tests}) {

        my @path = split(/\//, $result->{file});
        my @file = split(/\./, pop(@path));

        $sock->putval(
            host   => $self->hostname,
            plugin => $file[0],
            type   => 'latency',
            time   => $result->{time},
            values => [ $result->{delta}, $result->{passed}, $result->{failed} ],
        );
    }
    return;
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TheEye::Plugin::Store::Collectd - Collectd plugin for TheEye

=head1 VERSION

version 0.1

=head1 AUTHOR

Lenz Gschwendtner <lenz@springtimesoft.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by springtimesoft LTD.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
