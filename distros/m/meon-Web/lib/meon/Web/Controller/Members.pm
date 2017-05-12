package meon::Web::Controller::Members;
use Moose;
use 5.010;
use utf8;
use namespace::autoclean;

use File::MimeInfo 'mimetype';

BEGIN {extends 'Catalyst::Controller'; }

sub auto : Private {
    my ( $self, $c ) = @_;
}

sub base : Chained('/') PathPart('members') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->detach('/login',[])
        unless $c->user_exists;
}

sub default : Chained('base') PathPart('') {
    my ( $self, $c, @args ) = @_;

    # private area, restricted to user him self
    if (($args[0] eq 'profile') && ($args[2] eq 'private')) {
        my $username = $args[1] // '';
        $c->detach('/status_forbidden', [])
            unless $username eq $c->user->username;
    }

    $c->forward('/resolve_xml', []);
}

__PACKAGE__->meta->make_immutable;

1;
