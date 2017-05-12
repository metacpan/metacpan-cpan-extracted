package WebService::Face::Response;

use 5.006;
use strict;
use warnings;

use WebService::Face::Response::Photo;
use WebService::Face::Response::Account;

=head1 NAME

WebService::Face::Response

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

WebService::Face::Response wraps the data returned by the server response

It provides a simple OO interface to access the data

=head1 SUBROUTINES/METHODS

=head2 new ( \%params )

The WebService::Face::Response constructor

Valid %params keys are currently :
    photos
    saved_tags
    usage
    limits
    users
    namespaces

=cut

sub new {
    my $class  = shift;
    my $params = shift;

    my $self = bless {}, $class;

    for my $key ( keys %$params ) {
        $self->{$key} = $params->{$key};
    }

    if ( $params->{'photos'} ) {
        my @photos;
        for my $photo ( @{ $params->{photos} } ) {
            push @photos, WebService::Face::Response::Photo->new($photo);
        }
        @{ $self->{photos} } = @photos;
    }
    if ( $params->{'saved_tags'} ) {
        my @saved_tags;
        for my $saved_tag ( @{ $params->{saved_tags} } ) {
            push @saved_tags, $saved_tag;
        }
        @{ $self->{saved_tags} } = @saved_tags;
    }

    if ( $params->{'usage'} ) {
        $self->{'account'} = WebService::Face::Response::Account->new( $params->{'usage'} );
        delete $self->{'usage'};
    }

    if ( $params->{'users'} ) {
        $self->{'account'} = WebService::Face::Response::Account->new($params);
        delete $self->{'usage'};
    }

    if ( $params->{'limits'} ) {
        $self->{'account'} = WebService::Face::Response::Account->new( $params->{'limits'} );
        delete $self->{'usage'};
    }

    if ( $params->{'namespaces'} ) {
        $self->{'account'} = WebService::Face::Response::Account->new($params);
        delete $self->{'namespaces'};
    }
    return $self;
}

=head2 status ()

Getter for the 'status' attribute

=cut

sub status {
    my $self = shift;

    return $self->{'status'};
}

=head2 error_code ()

Getter for the 'error_code' attribute

=cut

sub error_code {
    my $self = shift;

    return $self->{'error_code'};
}

=head2 error_message ()

Getter for the 'error_message' attribute

=cut

sub error_message {
    my $self = shift;

    return $self->{'error_message'};
}

=head2 message ()

Getter for the 'message' attribute

=cut

sub message {
    my $self = shift;

    return $self->{'message'};
}

=head2 photos ()

Getter for the 'photos' attribute

=cut

sub photos {
    my $self = shift;
    $self->{'photos'} = [] unless $self->{'photos'};

    return @{ $self->{'photos'} };
}

=head2 saved_tags ()

Getter for the 'saved_tags' attribute

=cut

sub saved_tags {
    my $self = shift;
    $self->{'saved_tags'} = [] unless $self->{'saved_tags'};

    return @{ $self->{'saved_tags'} };
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

=head2 tags ()

Getter for the 'tags' attribute

=cut

sub tags {
    my $self = shift;

    return $self->{'tags'};
}

=head2 groups ()

Getter for the 'groups' attribute

=cut

sub groups {
    my $self = shift;

    return $self->{'groups'};
}

=head2 tid ()

Getter for the 'tid' attribute

=cut

sub tid {
    my $self = shift;

    return $self->{'tid'};
}

=head2 recognizable ()

Getter for the 'recognizable' attribute

=cut

sub recognizable {
    my $self = shift;

    return $self->{'recognizable'};
}

=head2 threshold ()

Getter for the 'threshold' attribute

=cut

sub threshold {
    my $self = shift;

    return $self->{'threshold'};
}

=head2 uids ()

Getter for the 'uids' attribute

=cut

sub uids {
    my $self = shift;

    return $self->{'uids'};
}

=head2 label ()

Getter for the 'label' attribute

=cut

sub label {
    my $self = shift;

    return $self->{'label'};
}

=head2 confirmed ()

Getter for the 'confirmed' attribute

=cut

sub confirmed {
    my $self = shift;

    return $self->{'confirmed'};
}

=head2 manual ()

Getter for the 'manual' attribute

=cut

sub manual {
    my $self = shift;

    return $self->{'manual'};
}

=head2 limits ()

Getter for the 'limits' attribute

=cut

sub limits {
    my $self = shift;

    return $self->account->limits;
}

=head2 users ()

Getter for the 'users' attribute

=cut

sub users {
    my $self = shift;

    return $self->{'users'};
}

=head2 account ()

Getter for the 'account' attribute

=cut

sub account {
    my $self = shift;

    return $self->{'account'};
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
