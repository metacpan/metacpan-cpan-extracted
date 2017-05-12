package WebService::NationBuilder;
use Moo;
with 'WebService::NationBuilder::HTTP';

use Carp qw(croak);

our $VERSION = '0.0107'; # VERSION

has access_token => ( is => 'rw'                                 );
has subdomain    => ( is => 'rw'                                 );
has domain       => ( is => 'ro', default => 'nationbuilder.com' );
has version      => ( is => 'ro', default => 'v1'                );

has sites_uri    => ( is => 'ro', default => 'sites'             );
has people_uri   => ( is => 'ro', default => 'people'            );
has tags_uri     => ( is => 'ro', default => 'tags'              );

sub get_sites {
    my ($self, $params) = @_;
    return $self->http_get_all($self->sites_uri, $params);
}

sub create_person {
    my ($self, $params) = @_;
    my $person = $self->http_post($self->people_uri, {
        person => $params });
    return $person ? $person->{person} : 0;
}

sub push_person {
    my ($self, $params) = @_;
    my $person = $self->http_put($self->people_uri . '/push', {
        person => $params });
    return $person ? $person->{person} : 0;
}

sub update_person {
    my ($self, $id, $params) = @_;
    croak 'The id param is missing' unless defined $id;
    my $person = $self->http_put($self->people_uri . "/$id", {
        person => $params });
    return $person ? $person->{person} : 0;
}

sub get_person {
    my ($self, $id) = @_;
    croak 'The id param is missing' unless defined $id;
    my $person = $self->http_get($self->people_uri . "/$id");
    return $person ? $person->{person} : 0;
}

sub delete_person {
    my ($self, $id) = @_;
    croak 'The id param is missing' unless defined $id;
    return $self->http_delete($self->people_uri . "/$id");
}

sub get_person_tags {
    my ($self, $id) = @_;
    croak 'The id param is missing' unless defined $id;
    my $taggings = $self->http_get($self->people_uri . "/$id/taggings");
    return $taggings ? $taggings->{taggings} : 0;
}

sub match_person {
    my ($self, $params) = @_;
    return $self->http_get($self->people_uri . '/match', $params)->{person};
}

sub get_people {
    my ($self, $params) = @_;
    return $self->http_get_all($self->people_uri, $params);
}

sub get_tags {
    my ($self, $params) = @_;
    return $self->http_get_all($self->tags_uri, $params);
}

sub set_tag {
    my ($self, $id, $tag) = @_;
    croak 'The id param is missing' unless defined $id;
    croak 'The tag param is missing' unless defined $tag;
    my $tagging = $self->http_put($self->people_uri . "/$id/taggings", {
        tagging => { tag => $tag },
    });
    return $tagging ? $tagging->{tagging} : 0;
}

sub delete_tag {
    my ($self, $id, $tag) = @_;
    croak 'The id param is missing' unless defined $id;
    croak 'The tag param is missing' unless defined $tag;
    return $self->http_delete($self->people_uri . "/$id/taggings/$tag");
}

# ABSTRACT: NationBuilder API bindings


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::NationBuilder - NationBuilder API bindings

=head1 VERSION

version 0.0107

=head1 SYNOPSIS

    use WebService::NationBuilder;

    my $nb = WebService::NationBuilder->new(
        access_token    => 'abc123',
        subdomain       => 'testing',
    );

    $nb->get_sites();

=head1 DESCRIPTION

This module provides bindings for the
L<NationBuilder|http://www.nationbuilder.com> API.

=head1 METHODS

=head2 new

Instantiates a new WebService::NationBuilder client object.

    my $nb = WebService::NationBuilder->new(
        access_token    => $access_token,
        subdomain       => $subdomain,
        domain          => $domain,     # optional
        version         => $version,    # optional
        retries         => $retries,    # optional
    );

B<Parameters>

=over 4

=item - C<access_token>

I<Required>E<10> E<8>

A valid NationBuilder OAuth 2.0 access token for your nation.

=item - C<subdomain>

I<Required>E<10> E<8>

The NationBuilder subdomain (slug) for your nation.

=item - C<domain>

I<Optional>E<10> E<8>

The NationBuilder top-level domain to make API calls against.  Defaults to L<nationbuilder.com|http://nationbuilder.com>.

=item - C<version>

I<Optional>

The NationBuilder API version to use.  Defaults to C<v1>.

=item - C<retries>

I<Optional>E<10> E<8>

The number of times to retry requests in cases when Balanced returns a 5xx response.  Defaults to C<0>.

=back

=head2 get_sites

Get information about the sites hosted by a nation.

B<Request:>

    get_sites({
        page        =>  1,
        per_page    =>  10,
    });

B<Response:>

    [{
        id          => 1,
        name        => 'Foobar',
        slug        => 'foobar',
        domain      => 'foobarsoftwares.com',
    },
    {
        id          => 2,
        name        => 'Test Site',
        slug        => 'test',
        domain      => undef,
    }]

=head2 get_people

Get a list of the people in a nation.

B<Request:>

    get_people({
        page        => 1,
        per_page    => 10,
    });

B<Response:>

    [{
        id          => 1,
        email       => 'test@gmail.com'
        phone       => '415-123-4567',
        mobile      => '555-123-4567',
        first_name  => 'Firstname',
        last_name   => 'Lastname',
        created_at  => '2013-12-08T04:27:12-08:00',
        updated_at  => '2013-12-24T12:03:51-08:00',
        sex         => undef,
        twitter_id  => '123456789',
        primary_address => {
            address1        => undef,
            address2        => undef,
            zip             => undef,
            city            => 'San Francisco',
            state           => 'CA',
            country_code    => 'US',
            lat             => '37.7749295',
            lng             => '-122.4194155',
        }
    }]

=head2 get_person

Get a full representation of the person with the provided C<id>.

B<Request:>

    get_person(1);

B<Response:>

    {
        id          => 1,
        email       => 'test@gmail.com'
        phone       => '415-123-4567',
        mobile      => '555-123-4578',
        first_name  => 'Firstname',
        last_name   => 'Lastname',
        created_at  => '2013-12-08T04:27:12-08:00',
        updated_at  => '2013-12-24T12:03:51-08:00',
        sex         => undef,
        twitter_id  => '123456789',
        primary_address => {
            address1        => undef,
            address2        => undef,
            zip             => undef,
            city            => 'San Francisco',
            state           => 'CA',
            country_code    => 'US',
            lat             => '37.7749295',
            lng             => '-122.4194155',
        }
    }

=head2 match_person

Get a full representation of the person with certain attributes.

B<Request:>

    match_person({
        email       => 'test@gmail.com',
        phone       => '415-123-4567',
        mobile      => '555-123-4567',
        first_name  => 'Firstname',
        last_name   => 'Lastname',
    });

B<Response:>

    {
        id          => 1,
        email       => 'test@gmail.com'
        phone       => '415-123-4567',
        mobile      => '555-123-4578',
        first_name  => 'Firstname',
        last_name   => 'Lastname',
        created_at  => '2013-12-08T04:27:12-08:00',
        updated_at  => '2013-12-24T12:03:51-08:00',
        sex         => undef,
        twitter_id  => '123456789',
        primary_address => {
            address1        => undef,
            address2        => undef,
            zip             => undef,
            city            => 'San Francisco',
            state           => 'CA',
            country_code    => 'US',
            lat             => '37.7749295',
            lng             => '-122.4194155',
        }
    }

=head2 create_person

Create a person with the provided data, and return a full representation of the person who was created.

B<Request:>

    create_person({
        email       => 'test@gmail.com',
        phone       => '415-123-4567',
        mobile      => '555-123-4567',
        first_name  => 'Firstname',
        last_name   => 'Lastname',
    });

B<Response:>

    {
        id          => 1,
        email       => 'test@gmail.com'
        phone       => '415-123-4567',
        mobile      => '555-123-4578',
        first_name  => 'Firstname',
        last_name   => 'Lastname',
        created_at  => '2013-12-08T04:27:12-08:00',
        updated_at  => '2013-12-24T12:03:51-08:00',
        sex         => undef,
        twitter_id  => undef,
        primary_address => undef,
    }

=head2 update_person

Update the person with the provided C<id> to have the provided data, and return a full representation of the person who was updated.

B<Request:>

    update_person(1, {
        email       => 'test2@gmail.com',
        phone       => '123-456-7890',
        mobile      => '999-876-5432',
        first_name  => 'Firstname2',
        last_name   => 'Lastname2',
    });

B<Response:>

    {
        id          => 1,
        email       => 'test2@gmail.com'
        phone       => '123-456-7890',
        mobile      => '999-876-5432',
        first_name  => 'Firstname2',
        last_name   => 'Lastname2',
        created_at  => '2013-12-08T04:27:12-08:00',
        updated_at  => '2013-12-24T12:03:51-08:00',
        sex         => undef,
        twitter_id  => undef,
        primary_address => undef,
    }

=head2 push_person

Update a person matched by email address, or create a new person if no match is found, then return a full representation of the person who was created or updated.

B<Request:>

    push_person({
        email       => 'test2@gmail.com',
        sex         => 'M',
        first_name  => 'Firstname3',
        last_name   => 'Lastname3',
    });

B<Response:>

    {
        id          => 1,
        email       => 'test2@gmail.com'
        phone       => '123-456-7890',
        mobile      => '999-876-5432',
        first_name  => 'Firstname3',
        last_name   => 'Lastname3',
        created_at  => '2013-12-08T04:27:12-08:00',
        updated_at  => '2013-12-24T12:03:51-08:00',
        sex         => 'M',
        twitter_id  => undef,
        primary_address => undef,
    }

=head2 delete_person

Removes the person with the provided C<id> from the nation.

B<Request:>

    delete_person(1);

B<Response:>

    1

=head2 get_tags

Get the tags that have been used before in a nation.

B<Request:>

    get_tags({
        page        => 1,
        per_page    => 10,
    });

B<Response:>

    [{
        name    =>  'tag1',
    },
    {
        name    =>  'tag2',
    }]

=head2 get_person_tags

Gets a list of the tags for a given person with the provided C<id>.

B<Request:>

    get_person_tags(1);

B<Response:>

    [{
        person_id   => 1,
        tag         => 'tag1',
    },
    {
        person_id   => 1,
        tag         => 'tag2',
    }]

=head2 set_tag

Associates a tag to a given person with the provided C<id>.

B<Request:>

    set_tag(1, 'tag3');

B<Response:>

    {
        person_id   => 1,
        tag         => 'tag3',
    }

=head2 delete_tag

Removes a tag from a given person with the provided C<id>.

B<Request:>

    delete_tag(1, 'tag3');

B<Response:>

    1

=head1 AUTHOR

Ali Anari <ali@anari.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Crowdtilt, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
