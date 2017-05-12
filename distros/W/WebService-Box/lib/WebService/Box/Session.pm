package WebService::Box::Session;

# ABSTRACT: A session for WebService::Box

use strict;
use warnings;

use Moo;
use OAuth2::Box;
use Types::Standard qw(Str Int InstanceOf);

use WebService::Box::File;
use WebService::Box::Folder;

our $VERSION = 0.01;

has [qw/client_id client_secret redirect_uri/] => (is => 'ro', isa => Str, required => 1);
has refresh_token => (is => 'rwp',  isa => Str, required => 1);
has auth_token    => (is => 'rwp',  isa => Str);
has expires       => (is => 'rwp',  isa => Int, default => sub{ 0 });
has box           => (is => 'ro',   isa => InstanceOf["WebService::Box"], required => 1);
has auth_client   => (is => 'lazy', isa => InstanceOf["OAuth2::Box"]);

sub file {
    my ($self, $id) = @_;

    my %opts;
    $opts{id} = $id if defined $id;

    return WebService::Box::File->new( %opts, session => $self );
}

sub folder {
    my ($self, $id) = @_;

    my %opts;
    $opts{id} = $id if defined $id;

    return WebService::Box::Folder->new( %opts, session => $self );
}

sub check {
    my ($self) = @_;

    if ( time > $self->expires ) {
        $self->refresh;
    }

    return $self->auth_token;
}

sub refresh {
    my ($self) = @_;

    my ($token, $data) = $self->auth_client->refresh_token(
        refresh_token => $self->refresh_token,
    );

    $self->_set_auth_token( $token );

    # we use a buffer of 5 secondes for the expires check
    $self->_set_expires( time + $data->{expires} - 5 );
    $self->_set_refresh_token( $data->{refresh_token} );

    return 1;
}

sub _build_auth_client {
    my ($self) = @_;

    return OAuth2::Box->new(
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        redirect_uri  => $self->redirect_uri,
    );
}

1;

__END__

=pod

=head1 NAME

WebService::Box::Session - A session for WebService::Box

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
