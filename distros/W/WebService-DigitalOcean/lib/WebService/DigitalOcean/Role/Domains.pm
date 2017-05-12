package WebService::DigitalOcean::Role::Domains;
# ABSTRACT: Domains role for DigitalOcean WebService
use utf8;
use Moo::Role;
use feature 'state';
use Types::Standard qw/Str Object Dict/;
use Type::Utils;
use Type::Params qw/compile/;

requires 'make_request';

our $VERSION = '0.026'; # VERSION

sub domain_create {
    state $check = compile(Object,
        Dict[
            name       => Str,
            ip_address => Str,
        ],
    );
    my ($self, $opts) = $check->(@_);

    return $self->make_request(POST => '/domains', $opts);
}

sub domain_list {
    state $check = compile(Object);
    my ($self) = $check->(@_);

    return $self->make_request(GET => '/domains');
}

sub domain_get {
    state $check = compile(Object, Str);
    my ($self, $domain) = $check->(@_);

    return $self->make_request(GET => "/domains/$domain");
}

sub domain_delete {
    state $check = compile(Object, Str);
    my ($self, $domain) = $check->(@_);

    return $self->make_request(DELETE => "/domains/$domain");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::DigitalOcean::Role::Domains - Domains role for DigitalOcean WebService

=head1 VERSION

version 0.026

=head1 DESCRIPTION

Implements the domain methods.

=head1 METHODS

=head2 domain_create

=head2 domain_delete

=head2 domain_get

=head2 domain_list

See main documentation in L<WebService::DigitalOcean>.

=head1 AUTHOR

André Walker <andre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by André Walker.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
