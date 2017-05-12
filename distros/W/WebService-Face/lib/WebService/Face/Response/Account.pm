package WebService::Face::Response::Account;

use 5.006;
use strict;
use warnings;

=head1 NAME

WebService::Face::Response::Account

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

WebService::Face::Response::Account wraps the data returned by the server for account data
(limits, users, namespacs)

It provides a simple OO interface to access the data

For a better understanding of the data structure you can read :

=over 4

=item * L<http://developers.face.com/docs/api/account-limits/>

=item * L<http://developers.face.com/docs/api/account-users/>

=item * L<http://developers.face.com/docs/api/account-namespaces/>

=back

=head1 SUBROUTINES/METHODS

=head2 new ( \%params )

The constructor for the WebService::Face::Response::Account class

=cut

sub new {
    my $class  = shift;
    my $params = shift;

    my $self = {};

    for my $key ( keys %$params ) {
        $self->{$key} = $params->{$key};
    }

    return bless( $self, $class );
}

=head2 used ()

Getter for the 'used' attribute

=cut

sub used {
    my $self = shift;

    return $self->{'used'};
}

=head2 remaining ()

Getter for the 'remaining' attribute

=cut

sub remaining {
    my $self = shift;

    return $self->{'remaining'};
}

=head2 limit ()

Getter for the 'limit' attribute

=cut

sub limit {
    my $self = shift;

    return $self->{'limit'};
}

=head2 reset_time_text ()

Getter for the 'reset_time_text' attribute

=cut

sub reset_time_text {
    my $self = shift;

    return $self->{'reset_time_text'};
}

=head2 reset_time ()

Getter for the 'reset_time' attribute

=cut

sub reset_time {
    my $self = shift;

    return $self->{'reset_time'};
}

=head2 namespace_limit ()

Getter for the 'namespace_limit' attribute

=cut

sub namespace_limit {
    my $self = shift;

    return $self->{'namespace_limit'};
}

=head2 namespace_used ()

Getter for the 'namespace_used' attribute

=cut

sub namespace_used {
    my $self = shift;

    return $self->{'namespace_used'};
}

=head2 namespace_remaining ()

Getter for the 'namespace_remaining' attribute

=cut

sub namespace_remaining {
    my $self = shift;

    return $self->{'namespace_remaining'};
}

=head2 users ()

Getter for the 'users' attribute

=cut

sub users {
    my $self = shift;
    my @users;

    for my $ns ( keys %{ $self->{'users'} } ) {
        push @users, @{ $self->{'users'}{$ns} };
    }

    return @users;
}

=head2 namespaces ()

Getter for the 'namespaces' attribute

=cut

sub namespaces {
    my $self = shift;

    return @{ $self->{'namespaces'} };
}

=head2 limits ()

Getter for the 'limits' attribute

=cut

sub limits {
    my $self = shift;

    return (
        used                => $self->used,
        remaining           => $self->remaining,
        limit               => $self->limit,
        reset_time_text     => $self->reset_time_text,
        reset_time          => $self->reset_time,
        namespace_limit     => $self->namespace_limit,
        namespace_used      => $self->namespace_used,
        namespace_remaining => $self->namespace_remaining
    );
}

=head1 AUTHOR

Arnaud (Arhuman) ASSAD, C<< <arhuman at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C< arhuman at gmail.com>, or through
the web interface at L<https://github.com/arhuman/WebService-Face/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Face::Client

You can also look for information at:

=over 4

=item * Github repository

L<https://github.com/arhuman/WebService-Face>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Face>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Face>

=back

More information about Face.com service :

L<http://developers.face.com/docs/api>

=head1 ACKNOWLEDGEMENTS

Thanks to Face.com for the service they provide.
Thanks to Jaguar Network for allowing me to publish my work.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Arnaud (Arhuman) ASSAD.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
