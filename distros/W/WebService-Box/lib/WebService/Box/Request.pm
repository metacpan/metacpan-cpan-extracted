package WebService::Box::Request;

use strict;
use warnings;

use Moo;
use Types::Standard qw(InstanceOf Dict Str);
use HTTP::Tiny;
use HTTP::Tiny::Multipart;
use JSON;

use WebService::Box::Types::Library qw(OptionalStr);

our $VERSION = 0.01;

has session     => (is => 'ro',  isa => InstanceOf["WebService::Box::Session"], required => 1);
has agent       => (is => 'ro',  isa => InstanceOf["HTTP::Tiny"], lazy => 1, builder => sub { HTTP::Tiny->new } );
has error       => (is => 'rwp', isa => OptionalStr );
has jsonp       => (is => 'ro',  isa => InstanceOf["JSON"], lazy => 1, builder => sub { JSON->new->allow_nonref } );
has auth_header => (
    is      => 'ro',
    isa     => Dict[
        Authorization => Str,
    ],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        { Authorization => 'Bearer ' . $self->session->auth_token };
    },
);

sub do {
    my $self   = shift;
    my %params = @_;

    $self->_check_token;
    my $method = sprintf "_%s_%s", delete $params{qw/ressource action/};
    return $self->$method( %params );
}

sub _check_token {
    my $self = shift;

    if ( $self->session->expires < time ) {
        $self->session->refresh;
    }
}

sub _files_get {
    my ($self, %params) = @_;

    $self->_set_error( undef );

    if ( !$params{id} ) {
        $self->session->box->error( 'Need id for request' );
        $self->_set_error( 'Need id for request' );
        return;
    }

    my $url = sprintf "%sfiles/%s/",
        $self->session->box->api_url,
        $params{id};

    my $result = $self->agent->get( $url, { headers => $self->auth_header } );

    if ( !$result->{success} ) {
        $self->_set_error( $result->{content} );
        return;
    }

    my %data = %{ $self->jsonp->decode( $result->{content} || "{}" ) || {} };
    return %data;
}

sub _files_upload {
    my ($self, %params) = @_;

    $self->_set_error( undef );

    if ( !$params{file} || !$params{parent_id} ) {
        $self->session->box->error( 'Need file and parent id for request' );
        $self->_set_error( 'Need file and parent id for request' );
        return;
    }

    my %opt_param;
    for my $key ( qw/content_created_at content_modified_at/ ) {
        $opt_param{$key} = $params{$key} if $params{$key} and $params{$key} =~ m{
            \A
            [0-9]{4} - [0-9]{2} - [0-9]{2}
            T
            [0-9]{2} : [0-9]{2} : [0-9]{2}
            (?:[+-] [0-9]{2} : [0-9]{2})?
            \z
        }xms;
    }

    my $url = sprintf "%sfiles/content", $self->session->box->upload_url;

    my $result = $self->agent->post_multipart(
        $url,
        {
            file      => $params{file},
            parent_id => $params{parent_id},
            %opt_param,
        },
        { headers => $self->auth_header }
    );

    if ( !$result->{success} ) {
        $self->_set_error( $result->{content} );
        return;
    }

    my %data = %{ $self->jsonp->decode( $result->{content} || "{}" ) || {} };
    return %data;
}

1;

__END__

=pod

=head1 NAME

WebService::Box::Request

=head1 VERSION

version 0.02

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
