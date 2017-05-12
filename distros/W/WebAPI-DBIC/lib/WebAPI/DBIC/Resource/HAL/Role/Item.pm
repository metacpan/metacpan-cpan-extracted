package WebAPI::DBIC::Resource::HAL::Role::Item;
$WebAPI::DBIC::Resource::HAL::Role::Item::VERSION = '0.004002';

use Moo::Role;


requires '_build_content_types_provided';
requires 'render_item_as_hal_hash';
requires 'encode_json';
requires 'item';


around '_build_content_types_provided' => sub {
    my $orig = shift;
    my $self = shift;
    my $types = $self->$orig();
    unshift @$types, { 'application/hal+json' => 'to_json_as_hal' };
    return $types;
};

sub to_json_as_hal { return $_[0]->encode_json($_[0]->render_item_as_hal_hash($_[0]->item)) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::HAL::Role::Item

=head1 VERSION

version 0.004002

=head1 DESCRIPTION

Provides methods to support the C<application/hal+json> media type
for GET and HEAD requests for requests representing individual resources,
e.g. a single row of a database table.

=head1 NAME

WebAPI::DBIC::Resource::HAL::Role::Item - methods related to handling HAL requests for item resources

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
