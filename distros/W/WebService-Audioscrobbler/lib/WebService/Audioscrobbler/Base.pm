package WebService::Audioscrobbler::Base;
use warnings FATAL => 'all';
use strict;
use CLASS;

use base 'Class::Data::Accessor';
use base 'Class::Accessor::Fast';

require URI;
require URI::Escape;

use WebService::Audioscrobbler;

=head1 NAME

WebService::Audioscrobbler::Base - An object-oriented interface to the Audioscrobbler WebService API

=cut

our $VERSION = '0.08';

# artists related
CLASS->mk_classaccessor("artists_postfix"    => "topartists.xml");
CLASS->mk_classaccessor("artists_class"      => WebService::Audioscrobbler->artist_class );
CLASS->mk_classaccessor("artists_sort_field" => "count");

# tracks related
CLASS->mk_classaccessor("tracks_postfix"    => "toptracks.xml");
CLASS->mk_classaccessor("tracks_class"      => WebService::Audioscrobbler->track_class );
CLASS->mk_classaccessor("tracks_sort_field" => "count");

# tags related
CLASS->mk_classaccessor("tags_postfix"    => "toptags.xml");
CLASS->mk_classaccessor("tags_class"      => WebService::Audioscrobbler->tag_class );
CLASS->mk_classaccessor("tags_sort_field" => "count");

# object accessors
CLASS->mk_accessors(qw/data_fetcher/);

=head1 SYNOPSIS

This module implements the base class for all other L<WebService::Audioscrobbler> modules.

    package WebService::Audioscrobbler::Subclass;
    use base 'WebService::Audioscrobbler::Base';

    ...

    my $self = WebService::Audioscrobbler::Subclass->new;
    
    # retrieves tracks
    my @tracks = $self->tracks;

    # retrieves tags
    my @tags = $self->tags;

    # retrieves arbitrary XML data as a hashref, using XML::Simple
    my $data = $self->fetch_data('resource.xml');


=head1 METHODS

=cut

=head2 C<tracks>

Retrieves the tracks related to the current resource as available on Audioscrobbler's database.

Returns either a list of tracks or a reference to an array of tracks when called 
in list context or scalar context, respectively. The tracks are returned as 
L<WebService::Audioscrobbler::Track> objects by default.

=cut

sub tracks {
    my $self = shift;

    my $data = $self->fetch_data($self->tracks_postfix);

    my @tracks;

    if (ref $data->{track} eq 'HASH') {
        my $tracks = $data->{track};
        my $sort_field = $self->tracks_sort_field;

        @tracks = map {
            my $title = $_;

            my $info = $tracks->{$title};
            $info->{name}   = $title;
            
            if (defined $info->{artist}) {
                $info->{artist}->{data_fetcher} = $self->data_fetcher;
                $info->{artist} = $self->artists_class->new($info->{artist});
            }
            elsif ($self->isa($self->artists_class)) {
                $info->{artist} = $self;
            }
            else {
                $self->croak("Couldn't determine artist for track");
            }

            $info->{data_fetcher} = $self->data_fetcher;

            $self->tracks_class->new($info);

        } sort {$tracks->{$b}->{$sort_field} <=> $tracks->{$a}->{$sort_field}} keys %$tracks;
    }

    return wantarray ? @tracks : \@tracks;

}

=head2 C<tags>

Retrieves the tags related to the current resource as available on Audioscrobbler's database.

Returns either a list of tags or a reference to an array of tags when called 
in list context or scalar context, respectively. The tags are returned as 
L<WebService::Audioscrobbler::Tag> objects by default.

=cut

sub tags {
    my $self = shift;

    my $data = $self->fetch_data($self->tags_postfix);

    my @tags;

    if (ref $data->{tag} eq 'HASH') {
        my $tags = $data->{tag};

        if (exists $tags->{name} && !ref $tags->{name}) {
            @tags = $self->_process_tag( $tags );
        }
        else {
            my $sort_field = $self->tags_sort_field;
            @tags = map {
                $self->_process_tag( $tags->{ $_ }, $_ );
            } sort {$tags->{$b}->{$sort_field} <=> $tags->{$a}->{$sort_field}} keys %$tags;
        }
    }

    return wantarray ? @tags : \@tags;

}

sub _process_tag {
    my ($self, $info, $name) = @_;
    
    $info->{name} = $name if defined $name;

    die "no tag name" unless defined $info->{name};

    $info->{data_fetcher} = $self->data_fetcher;

    $self->tags_class->new($info);

}

=head2 C<artists>

Retrieves the artists related to the current resource as available on Audioscrobbler's database.

Returns either a list of artists or a reference to an array of artists when called 
in list context or scalar context, respectively. The tags are returned as 
L<WebService::Audioscrobbler::Artist> objects by default.

=cut

sub artists {
    my $self = shift;

    my $data = $self->fetch_data($self->artists_postfix);

    my @artists;

    if (ref $data->{artist} eq 'HASH') {
        my $artists = $data->{artist};
        my $sort_field = $self->artists_sort_field;
        @artists = map {
            my $name = $_;

            my $info = $artists->{$name};
            $info->{name} = $name;
            $info->{data_fetcher} = $self->data_fetcher;

            $self->artists_class->new($info);

        } sort {$artists->{$b}->{$sort_field} <=> $artists->{$a}->{$sort_field}} keys %$artists;
    }

    return wantarray ? @artists : \@artists;

}

=head2 C<fetch_data($postfix)>

This method retrieves arbitrary data from this resource using the specified
C<$postfix>. This is accomplished by calling the C<fetch> method of this
object's data fetcher object (usually an instance of L<WebService::Audioscrobbler::DataFetcher>).

=cut

sub fetch_data {
    my ($self, $postfix) = @_;

    my $uri = $self->resource_path->clone;
    $uri->path_segments($uri->path_segments, $postfix);

    # warn "\nFetching resource '$uri'\n";
    
    return $self->data_fetcher->fetch($uri);
}

=head2 C<resource_path>

This method must be overriden by classes which inherit from C<Base>. It should 
return the relative resource URL which will be used for fetching it from 
Audioscrobbler.

=cut

sub resource_path {
    my $class = ref shift;
    croak("$class must override the 'resource_path' method");
}

=head2 C<uri_builder>

Helps classes which inherit from WebService::Audioscrobbler::Base to build
URI objects. Mainly used for keeping C<resource_path> code cleaner in those
classes.

=cut

sub uri_builder {
    my ($self, @bits) = @_;
    URI->new( join '/', $self->base_resource_path, map {URI::Escape::uri_escape($_)} @bits );
}

=head2 C<croak>

Shortcut for C<Carp::croak> which can be called as a method.

=cut

sub croak {
    shift if $_[0]->isa(CLASS);
    require Carp;
    Carp::croak(@_);
}

=head1 AUTHOR

Nilson Santos Figueiredo Junior, C<< <nilsonsfj at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Nilson Santos Figueiredo Junior, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Audioscrobbler::Base
