package WebService::Toggl::Role::Item;

use strict;
use warnings;

use Package::Variant
    importing => ['Moo::Role'],
    subs      => [qw(has with around)];

use Sub::Quote qw(quote_sub);
use Types::Standard qw(Bool Int Str);

sub make_variant {
    my ($class, $target_pkg, %arguments) = @_;

    with 'WebService::Toggl::Role::Base';

    around '_build_my_url' => sub {
        my $orig = shift;
        my $self = shift;
        my $url = $self->$orig() . '/' . $self->api_id;
        $url =~ s{/$}{};
        return $url;
    };

    has raw => (is => 'ro', lazy => 1, builder => 1);
    install '_build_raw' => sub {
        my ($self) = @_;
        my $response = $self->api_get( $self->my_url, {with_related_data => 1} );
        return $response->data->{data};
    };

    has $_ => (is => 'ro', isa => Bool, lazy => 1, builder => quote_sub(qq| \$_[0]->raw->{$_} |))
        for (@{ $arguments{bools} } );
    has $_ => (is => 'ro', isa => Str,  lazy => 1, builder => quote_sub(qq| \$_[0]->raw->{$_} |))
        for (@{ $arguments{strings} } );
    has $_ => (is => 'ro', isa => Int,  lazy => 1, builder => quote_sub(qq| \$_[0]->raw->{$_} |))
        for (@{ $arguments{integers} });
}


1;
__END__

=encoding utf-8

=head1 NAME

WebService::Toggl::Role::Item - Create roles for all WebService::Toggl::API Items

=head1 SYNOPSIS

 package WebService::Toggl::API::Tag;

 use WebService::Toggl::Role::Item as => 'JsonItem';

 use Moo;
 with 'WebService::Toggl::API';
 use namespace::clean;

 with JsonItem(
     bools    => [ qw()       ],
     strings  => [ qw(name)   ],
     integers => [ qw(id wid) ],
 );

 sub api_path { 'tags' }
 sub api_id   { shift->id }


=head1 DESCRIPTION

This package constructs dynamic roles for WebService::Toggl::API
objects representing individual Items.  The calling class gives it a
list of boolean fields, a list of string fields, and a list of integer
fields.  This package will then construct type-checked accessors for
all the provided attributes to fetch them from the raw response.
Calling the constructed attributes will cause an API request to be
made, unless the raw data already exists in the object.

=head2 Provided Attributes

=head3 raw

The raw data returned from an API request.

=head2 Wrapped Methods

=head3 my_url

Returns the API URL for the object.

=head1 LICENSE

Copyright (C) Fitz Elliott.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Fitz Elliott E<lt>felliott@fiskur.orgE<gt>

=cut
