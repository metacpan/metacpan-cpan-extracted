package WebAPI::DBIC::Resource::JSONAPI::Role::Set;
$WebAPI::DBIC::Resource::JSONAPI::Role::Set::VERSION = '0.004002';

use Moo::Role;

use Carp qw(confess);

requires '_build_content_types_provided';
requires 'encode_json';
requires 'set';
requires 'render_jsonapi_response';
requires 'jsonapi_type';


around '_build_content_types_provided' => sub {
    my $orig = shift;
    my $self = shift;
    my $types = $self->$orig();
    unshift @$types, { 'application/vnd.api+json' => 'to_json_as_jsonapi' };
    return $types;
};


sub to_json_as_jsonapi {
    my $self = shift;
    return $self->encode_json( $self->render_jsonapi_response() );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::JSONAPI::Role::Set

=head1 VERSION

version 0.004002

=head1 DESCRIPTION

Handles GET and HEAD requests for requests representing set resources, e.g.
the rows of a database table.

Supports the C<application/vnd.api+json> content type.

=head1 NAME

WebAPI::DBIC::Resource::JSONAPI::Role::Set - add JSON API content type support for set resources

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
