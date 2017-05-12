package WebService::DigitalOcean::Role::Droplets;
# ABSTRACT: Droplets role for DigitalOcean WebService
use utf8;
use Moo::Role;
use feature 'state';
use Types::Standard qw/Str Object Dict ArrayRef Optional Bool Int/;
use Type::Utils;
use Type::Params qw/compile/;

requires 'make_request';

our $VERSION = '0.026'; # VERSION

sub droplet_create {
    state $check = compile(Object,
        Dict[
            name               => Str,
            region             => Str,
            size               => Str,
            image              => Str,
            user_data          => Optional[ Str ],
            ssh_keys           => Optional[ ArrayRef ],
            backups            => Optional[ Bool ],
            ipv6               => Optional[ Bool ],
            private_networking => Optional[ Bool ],
        ],
    );
    my ($self, $opts) = $check->(@_);

    return $self->make_request(POST => '/droplets', $opts);
}

sub droplet_list {
    state $check = compile(Object);
    my ($self) = $check->(@_);

    return $self->make_request(GET => '/droplets');
}

sub droplet_get {
    state $check = compile(Object, Int);
    my ($self, $id) = $check->(@_);

    return $self->make_request(GET => "/droplets/$id");
}

sub droplet_delete {
    state $check = compile(Object, Int);
    my ($self, $id) = $check->(@_);

    return $self->make_request(DELETE => "/droplets/$id");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::DigitalOcean::Role::Droplets - Droplets role for DigitalOcean WebService

=head1 VERSION

version 0.026

=head1 DESCRIPTION

Implements the droplets methods.

=head1 METHODS

=head2 droplet_create

=head2 droplet_list

=head2 droplet_get

=head2 droplet_delete

See main documentation in L<WebService::DigitalOcean>.

=head1 AUTHOR

André Walker <andre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by André Walker.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
