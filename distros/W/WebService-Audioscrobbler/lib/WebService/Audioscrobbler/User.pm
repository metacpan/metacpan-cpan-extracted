package WebService::Audioscrobbler::User;
use warnings FATAL => 'all';
use strict;
use CLASS;

use base 'WebService::Audioscrobbler::Base';

=head1 NAME

WebService::Audioscrobbler::User - An object-oriented interface to the Audioscrobbler WebService API

=cut

our $VERSION = '0.08';

# postfix related accessors
CLASS->mk_classaccessor("base_resource_path"   => "user");

# neighbours related accessors
CLASS->mk_classaccessor("neighbours_postfix" => "neighbours.xml");
CLASS->mk_classaccessor("neighbours_class"   => "WebService::Audioscrobbler::SimilarUser");

# friends related accessors
CLASS->mk_classaccessor("friends_postfix" => "friends.xml");
CLASS->mk_classaccessor("friends_class"   => CLASS);

# different postfix
CLASS->tags_postfix('tags.xml');

# change the field used to sort stuff
CLASS->artists_sort_field('playcount');
CLASS->tracks_sort_field('playcount');

# requiring stuff
CLASS->artists_class->require    or die($@);
CLASS->tracks_class->require     or die($@);
CLASS->tags_class->require       or die($@);
CLASS->neighbours_class->require or die($@);

# object accessors
CLASS->mk_accessors(qw/name picture_url url/);

=head1 SYNOPSIS

This module implements an object oriented abstraction of an user within the
Audioscrobbler database.

    use WebService::Audioscrobbler;

    my $ws = WebService::Audioscrobbler->new;

    # get an object for user named 'foo'
    my $user  = $ws->user('foo');

    # get user's top artists
    my @artists = $user->artists;
    
    # get user's top tags
    my @tags = $user->tags;

    # get user's top tracks
    my @tracks = $user->tracks;
    
    # get user's neighbours
    my @neighbours = $user->neighbours; 


This module inherits from L<WebService::Audioscrobbler::Base>.

=head1 FIELDS

=head2 C<name>

The name of a given user as provided when constructing the object.

=head2 C<picture_url>

URI object pointing to the location of the users's picture, if available.

=head2 C<url>

URI object pointing to the location where's additional info might be available
about the user.

=cut

=head1 METHODS

=cut

=head2 C<new($user_name, $data_fetcher)>

=head2 C<new(\%fields)>

Creates a new object using either the given C<$user_name> or the C<\%fields> 
hashref. The data fetcher object is a mandatory parameter and must
be provided either as the second parameter or inside the C<\%fields> hashref. 

=cut

sub new {
    my $class = shift;
    my ($name_or_fields, $data_fetcher) = @_;

    my $self = $class->SUPER::new( 
        ref $name_or_fields eq 'HASH' ? 
            $name_or_fields : { name => $name_or_fields, data_fetcher => $data_fetcher } 
    );

    $self->croak("No data fetcher provided")
        unless $self->data_fetcher;

    unless (defined $self->name) {
        if (defined $self->{username}) {
            $self->name($self->{username})
        }
        else {
            $self->croak("Can't create user without a name");
        }
    }

    return $self;
}

=head2 C<artists>

Retrieves the user's top artists as available on Audioscrobbler's database.

Returns either a list of artists or a reference to an array of artists when called 
in list context or scalar context, respectively. The artists are returned as 
L<WebService::Audioscrobbler::Artist> objects by default.

=cut

=head2 C<tracks>

Retrieves the user's top tracks as available on Audioscrobbler's database.

Returns either a list of tracks or a reference to an array of tracks when called 
in list context or scalar context, respectively. The tracks are returned as 
L<WebService::Audioscrobbler::Track> objects by default.

=cut

=head2 C<tags>

Retrieves the user's top tags as available on Audioscrobbler's database.

Returns either a list of tags or a reference to an array of tags when called 
in list context or scalar context, respectively. The tags are returned as 
L<WebService::Audioscrobbler::Tag> objects by default.

=cut

=head2 C<neighbours([$filter])>

Retrieves musical neighbours from the Audioscrobbler database. $filter can be used
as a constraint for neighbours with a low similarity index (ie. users which have a 
similarity index lower than $filter won't be returned).

Returns either a list of users or a reference to an array of users when called 
in list context or scalar context, respectively. The users are returned as 
L<WebService::Audioscrobbler::SimilarUser> objects by default.

=cut

sub neighbours {
    my $self = shift;
    my $filter = shift || 1;

    return $self->fetch_users($self->neighbours_postfix, sub {
        my $users = shift;
        map {
            $self->neighbours_class->new({
                name         =>  $_->{username},
                match        =>  $_->{match},
                url          => URI->new($_->{url}),
                picture_url  => URI->new($_->{image}),
                related_to   => $self,
                data_fetcher => $self->data_fetcher
            })
        } grep { $_->{match} >= $filter } @$users;
    });

}

=head2 C<friends>

Retrieves the user's friends from the Audioscrobbler / LastFM database. 

Returns either a list of users or a reference to an array of users when called 
in list context or scalar context, respectively. The users are returned as 
L<WebService::Audioscrobbler::User> objects by default.

=cut

sub friends {
    my $self = shift;

    return $self->fetch_users($self->friends_postfix, sub {
        my $users = shift;
        map {
            $self->friends_class->new({
                name         => $_->{username},
                url          => URI->new($_->{url}),
                picture_url  => URI->new($_->{image}),
                data_fetcher => $self->data_fetcher
            })
        } @$users;
    });
}

=head2 C<fetch_users($postfix, $callback)>

Internal method used to fetch users. $postfix should be the users data feed
postfix and $callback should be a function reference which will be called with
a arrayref of user data as the only parameter and should return user-derived
objects.

It returns either an arrayref or a list of objects depending on the calling
context.

=cut

sub fetch_users {
    my ($self, $postfix, $callback) = @_;

    my $data = $self->fetch_data($postfix);

    my @users;

    # check if we've got any users
    if (ref $data->{user} eq 'ARRAY') {

        shift @{$data->{user}};

        @users = $callback->($data->{user});
    }

    return wantarray ? @users : \@users;
}

=head2 C<resource_path>

Returns the URL from which other URLs used for fetching user info will be 
derived from.

=cut

sub resource_path {
    my $self = shift;
    $self->uri_builder( $self->name );
}

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Audioscrobbler::User
