package WebService::DigitalOcean::Role::Keys;
# ABSTRACT: Keys role for DigitalOcean WebService
use utf8;
use Moo::Role;
use feature 'state';
use Types::Standard qw/Str Int Object Dict Optional/;
use Type::Utils;
use Type::Params qw/compile/;

requires 'make_request';

our $VERSION = '0.026'; # VERSION

sub key_create {
    state $check = compile(Object,
        Dict[
            name       => Str,
            public_key => Str,
        ],
    );
    my ($self, $opts) = $check->(@_);

    return $self->make_request(POST => "/account/keys", $opts);
}

sub key_list {
    state $check = compile(Object);
    my ($self, $opts) = $check->(@_);

    return $self->make_request(GET => "/account/keys");
}

sub key_get {
    state $check = compile(Object,
        Dict[
            fingerprint => Optional[Str],
            id          => Optional[Int],
        ],
    );
    my ($self, $opts) = $check->(@_);

    my $id = $opts->{id} || $opts->{fingerprint};

    return $self->make_request(GET => "/account/keys/$id");
}

sub key_delete {
    state $check = compile(Object,
        Dict[
            fingerprint => Optional[Str],
            id          => Optional[Int],
        ],
    );
    my ($self, $opts) = $check->(@_);

    my $id = $opts->{id} || $opts->{fingerprint};

    return $self->make_request(DELETE => "/account/keys/$id");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::DigitalOcean::Role::Keys - Keys role for DigitalOcean WebService

=head1 VERSION

version 0.026

=head1 DESCRIPTION

Implements the SSH Keys methods.

=head1 METHODS

=head2 key_create

=head2 key_list

=head2 key_get

=head2 key_delete

See main documentation in L<WebService::DigitalOcean>.

=head1 AUTHOR

André Walker <andre@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by André Walker.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
