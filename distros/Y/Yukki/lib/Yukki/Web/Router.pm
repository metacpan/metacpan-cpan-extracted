package Yukki::Web::Router;
{
  $Yukki::Web::Router::VERSION = '0.140290';
}
use Moose;

extends 'Path::Router';

use Yukki::Web::Router::Route;

use Moose::Util::TypeConstraints qw( subtype where );
use List::MoreUtils qw( all );

# ABSTRACT: send requests to the correct controllers, yo


# Add support for slurpy variables, inline off because I haven't written the match
# generator function yet.
has '+route_class' => ( default => 'Yukki::Web::Router::Route' );
has '+inline'      => ( default => 0 );


has app => (
    is          => 'ro',
    isa         => 'Yukki',
    required    => 1,
    weak_ref    => 1,
    handles     => 'Yukki::Role::App',
);


sub BUILD {
    my $self = shift;

    $self->add_route('' => (
        defaults => {
            redirect => 'page/view/main',
        },
        acl => [ 
            [ none => { action => sub { 1 } } ],
        ],
        target => $self->controller('Redirect'),
    ));

    $self->add_route('login/?:action' => (
        defaults => {
            action => 'page',
        },
        validations => {
            action => qr/^(?:page|submit|exit)$/,
        },
        acl => [ 
            [ none => { action => sub { 1 } } ],
        ],
        target => $self->controller('Login'),
    ));

    $self->add_route('logout' => (
        defaults => {
            action => 'exit',
        },
        acl => [ 
            [ none => { action => 'exit' } ] 
        ],
        target => $self->controller('Login'),
    ));

    $self->add_route('page/:action/:repository/*:page' => (
        defaults => {
            action     => 'view',
            repository => 'main',
        },
        validations => {
            action     => qr/^(?:view|edit|history|diff|preview|attach|rename|remove)$/,
            repository => qr/^[_a-z0-9]+$/i,
            page       => subtype('ArrayRef[Str]' => where {
                all { /^[_a-z0-9-.]+(?:\.[_a-z0-9-]+)*$/i } @$_
            }),
        },
        acl => [
            [ read  => { action => [ qw( view preview history diff ) ] } ],
            [ write => { action => [ qw( edit attach rename remove ) ]  } ],
        ],
        target => $self->controller('Page'),
    ));

    $self->add_route('attachment/:action/:repository/+:file' => (
        defaults => {
            action     => 'download',
            repository => 'main',
            file       => [ 'untitled.txt' ],
        },
        validations => {
            action     => qr/^(?:view|upload|download|rename|remove)$/,
            repository => qr/^[_a-z0-9]+$/i,
            file       => subtype('ArrayRef[Str]' => where {
                all { /^[_a-z0-9-]+(?:\.[_a-z0-9-]+)*$/i } @$_
            }),
        },
        acl => [
            [ read  => { action => [ qw( view download ) ] } ],
            [ write => { action => [ qw( upload rename remove ) ] } ],
        ],  
        target => $self->controller('Attachment'),
    ));
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Router - send requests to the correct controllers, yo

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

This maps incoming paths to the controllers that should be used to handle them.
This is based on L<Path::Router>, but adds "slurpy" variables.

=head1 EXTENDS

L<Path::Router>

=head1 ATTRIBUTES

=head2 route_class

Defaults to L<Yukki::Web::Router::Route>.

=head2 inline

This is turned off because inline slurpy routing is not implemented.

=head2 app

This is the L<Yukki> handler.

=head1 METHODS

=head2 BUILD

Builds the routing table used by L<Yukki::Web>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
