package WebService::Face::Response::Photo;

use 5.006;
use strict;
use warnings;

use WebService::Face::Response::Tag;

=head1 NAME

WebService::Face::Client::Photo

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

WebService::Face::Response::Photo wraps the data returned by the server for photos

It provides a simple OO interface to access the data

=head1 SUBROUTINES/METHODS

=head2 new ( \%params )

The constructor for the WebService::Face::Client::Photo class

=cut

sub new {
    my $class  = shift;
    my $params = shift;

    my $self = bless {}, $class;

    for my $key ( keys %$params ) {
        $self->{$key} = $params->{$key};
    }

    if ( $params->{tags} ) {
        my @tags;
        for my $tag ( @{ $params->{tags} } ) {

            # Add a reference back to the parent photo
            $tag->{photo} = $self;
            push @tags, WebService::Face::Response::Tag->new($tag);
        }
        @{ $self->{tags} } = @tags;
    }

    return $self;
}

=head2 width ()

Getter for the 'width' attribute

=cut

sub width {
    my $self = shift;

    return $self->{'width'};
}

=head2 height ()

Getter for the 'height' attribute

=cut

sub height {
    my $self = shift;

    return $self->{'height'};
}

=head2 url ()

Getter for the 'url' attribute

=cut

sub url {
    my $self = shift;

    return $self->{'url'};
}

=head2 pid ()

Getter for the 'pid' attribute

=cut

sub pid {
    my $self = shift;

    return $self->{'pid'};
}

=head2 tags ()

Getter for the 'tags' attribute

=cut

sub tags {
    my $self = shift;

    return @{ $self->{'tags'} };
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
