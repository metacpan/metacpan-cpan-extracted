package WebAPI::DBIC::Resource::GenericItem;
$WebAPI::DBIC::Resource::GenericItem::VERSION = '0.004002';

use Moo;
use namespace::clean;

extends 'WebAPI::DBIC::Resource::GenericCore';
with    'WebAPI::DBIC::Resource::Role::Item',
        'WebAPI::DBIC::Resource::Role::ItemWritable',
        # Enable HAL support:
        'WebAPI::DBIC::Resource::ActiveModel::Role::DBIC',
        'WebAPI::DBIC::Resource::ActiveModel::Role::Item',
        'WebAPI::DBIC::Resource::ActiveModel::Role::ItemWritable',
        # Enable HAL support:
        'WebAPI::DBIC::Resource::HAL::Role::DBIC',
        'WebAPI::DBIC::Resource::HAL::Role::Item',
        'WebAPI::DBIC::Resource::HAL::Role::ItemWritable',
        # Enable JSON API support:
        'WebAPI::DBIC::Resource::JSONAPI::Role::DBIC',
        'WebAPI::DBIC::Resource::JSONAPI::Role::Item',
        'WebAPI::DBIC::Resource::JSONAPI::Role::ItemWritable',
        ;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::GenericItem

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::GenericItem - a set of roles to implement a generic DBIC item resource

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
