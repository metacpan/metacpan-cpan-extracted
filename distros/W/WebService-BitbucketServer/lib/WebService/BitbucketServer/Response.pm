package WebService::BitbucketServer::Response;
# ABSTRACT: A response object for Bitbucket Server REST APIs


use warnings;
use strict;

our $VERSION = '0.604'; # VERSION

use Clone qw(clone);
use Types::Standard qw(HashRef Object);

use Moo;
use namespace::clean;

sub _croak { require Carp; Carp::croak(@_) }
sub _usage { _croak("Usage: @_\n") }


has context => (
    is          => 'ro',
    isa         => Object,
    required    => 1,
);


has request_args => (
    is          => 'ro',
    isa         => HashRef,
    required    => 1,
);


has raw => (
    is          => 'ro',
    isa         => HashRef,
    required    => 1,
);


has decoded_content => (
    is  => 'lazy',
);

sub _build_decoded_content {
    my $self = shift;
    my $body = $self->raw->{content};

    if (($self->raw->{headers}{'content-type'} || '') =~ /json/) {
        $body = $self->json->decode($body);
    }

    return $body;
}


has json => (
    is      => 'lazy',
    isa     => Object,
    default => sub {
        shift->context->json || do {
            require JSON;
            JSON->new->utf8(1);
        };
    },
);


sub is_success  { shift->raw->{success} }
sub status      { shift->raw->{status}  }


sub error {
    my $self = shift;

    return if $self->is_success;

    return $self->decoded_content;
}


sub data {
    my $self = shift;

    return $self->decoded_content->{values} if $self->is_paged;
    return $self->decoded_content;
}

sub info    { shift->data(@_) }
sub value   { shift->data(@_) }
sub values  { shift->data(@_) }


sub is_paged { !!shift->page_info }


has page_info => (
    is  => 'lazy',
);

sub _build_page_info {
    my $self = shift;

    my $content = $self->decoded_content;

    my @envelope_keys = qw(isLastPage limit size start values);
    return if $self->request_args->{method} ne 'GET' ||
        ref($content) ne 'HASH' || @envelope_keys != grep { exists $content->{$_} } @envelope_keys;

    return {
        filter          => $content->{filter},
        is_last_page    => $content->{isLastPage},
        limit           => $content->{limit},
        next_page_start => $content->{nextPageStart},
        size            => $content->{size},
        start           => $content->{start},
    };
}


sub next {
    my $self = shift;

    return if not my $page_info = $self->page_info;

    return if $page_info->{is_last_page} || !$page_info->{next_page_start};

    my $args = clone($self->request_args);
    $args->{data}{start} = $page_info->{next_page_start};

    return $self->context->call($args);
}


sub wrap {
    my $self    = shift;
    my $field   = shift or _usage(qw{$response->wrap($field)});

    return __PACKAGE__->new(
        context         => $self->context,
        request_args    => $self->request_args,
        raw             => $self->raw,
        decoded_content => $self->data->{$field},
        json            => $self->json,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::BitbucketServer::Response - A response object for Bitbucket Server REST APIs

=head1 VERSION

version 0.604

=head1 SYNOPSIS

    # Normal response with blocking user agent:

    my $response = $core->get_application_properties;
    my $app_info = $response->data;
    print "Making API calls to: $app_info->{displayName} $app_info->{version}\n";

    # Normal reponse with non-blocking user agent:

    my $future = $core->get_application_properties;
    $future->on_done(sub {
        my $response = shift;

        my $app_info = $response->data;
        print "Making API calls to: $app_info->{displayName} $app_info->{version}\n";
    });

    # Paged response with blocking user agent:

    my $response = $core->get_projects;
    do {
        last if $response->error;

        for my $project_info (@{ $response->values }) {
            print "$project_info->{key}\t$project_info->{name}\n"
        }
    } while ($response = $response->next);

    # Paged response with non-blocking user agent:

    my $future;
    my $print_projects;

    $print_projects = sub {
        my $response = shift;

        for my $project_info (@{ $response->values }) {
            print "$project_info->{key}\t$project_info->{name}\n"
        }

        $future = $response->next;      # get more projects
        $future->on_done($print_projects) if $future;
    };

    $future = $core->get_projects;      # get first page of projects
    $future->on_done($print_projects);

=head1 DESCRIPTION

This module represents a response from a Bitbucket Server API call. It has various convenient
accessors and provides a mechanism to handle paging.

=head1 ATTRIBUTES

=head2 context

A L<WebService::BitbucketServer> object.

=head2 request_args

A hashref of the request arguments originally provided to L<WebService::BitbucketServer/call>.

=head2 raw

The raw L<response|HTTP::AnyUA/The Response> from the server in a hashref structure similar to an
L<HTTP::Tiny> response (regardless of which user agent was used to get the response).

=head2 decoded_content

Get the decoded response content which may include page info if this is a paged response. Consider
using L</data>, L</page_data>, etc. before this.

=head2 json

Get the L<JSON> (or compatible) object used for encoding and decoding documents.

=head1 METHODS

=head2 new

    $response = WebService::BitbucketServer::Response->new(
        context         => $webservice_bitbucketserver_obj,
        request_args    => $data,
        raw             => $response,
    );

Create a new response.

=head2 is_success

Get whether or not the response is a success.

=head2 status

Get the HTTP status code.

=head2 error

Get the error message or structure if this response represents an error (i.e. L</is_success> is
false), or undef if this response is not an error.

=head2 data

=head2 info

=head2 value

=head2 values

Get the decoded response content. If this is a paged response (see L</is_paged>), this will be an
arrayref of values.

=head2 is_paged

Get whether or not the response is a page of values.

=head2 page_info

Get a hashref of page info or undef if this is not a paged response.

=over 4

=item *

filter

=item *

is_last_page

=item *

limit

=item *

next_page_start

=item *

size

=item *

start

=back

=head2 next

    $next_response = $response->next;

Get the next page of results or undef if no more results. As with
L<WebService::BitbucketServer/call>, the returned response may be
a L<WebService::BitbucketServer::Response> or a L<Future>.

=head2 wrap

    $subresponse = $response->wrap($field);

Sometimes the response doesn't include the page information in the root object, typically when the
response has an envelope with other non-repeated information. In such cases, L</is_paged> is false
and L</page_info> is undef. You can use this method to easily create a paged response by specifying
the field name of the object that contains the page info.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/WebService-BitbucketServer/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
