package WWW::Hetzner::Robot::API::IPs;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Hetzner Robot IPs API

our $VERSION = '0.002';

use Moo;
use Carp qw(croak);
use WWW::Hetzner::Robot::IP;
use namespace::clean;


has client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
);

sub _wrap {
    my ($self, $data) = @_;
    return WWW::Hetzner::Robot::IP->new(
        client => $self->client,
        %$data,
    );
}

sub _wrap_list {
    my ($self, $list) = @_;
    return [ map { $self->_wrap($_->{ip}) } @$list ];
}

sub list {
    my ($self) = @_;
    my $result = $self->client->get('/ip');
    return $self->_wrap_list($result // []);
}


sub get {
    my ($self, $ip) = @_;
    croak "IP address required" unless $ip;
    my $result = $self->client->get("/ip/$ip");
    return $self->_wrap($result->{ip});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Robot::API::IPs - Hetzner Robot IPs API

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $robot = WWW::Hetzner::Robot->new(...);

    # List all IPs
    my $ips = $robot->ips->list;

    # Get specific IP
    my $ip = $robot->ips->get('1.2.3.4');

=head2 list

Returns arrayref of L<WWW::Hetzner::Robot::IP> objects.

=head2 get

    my $ip = $robot->ips->get($ip_address);

Returns L<WWW::Hetzner::Robot::IP> object.

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
