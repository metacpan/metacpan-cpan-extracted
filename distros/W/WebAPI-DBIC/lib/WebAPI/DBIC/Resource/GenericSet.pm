package WebAPI::DBIC::Resource::GenericSet;
$WebAPI::DBIC::Resource::GenericSet::VERSION = '0.004002';

use Moo;
use namespace::clean;

extends 'WebAPI::DBIC::Resource::GenericCore';
with    'WebAPI::DBIC::Resource::Role::Set',
        'WebAPI::DBIC::Resource::Role::SetWritable',
        # Enable ActiveModel support:
        'WebAPI::DBIC::Resource::ActiveModel::Role::DBIC', # XXX move out?
        'WebAPI::DBIC::Resource::ActiveModel::Role::Set',
        'WebAPI::DBIC::Resource::ActiveModel::Role::SetWritable',
        # Enable HAL support:
        'WebAPI::DBIC::Resource::HAL::Role::DBIC', # XXX move out?
        'WebAPI::DBIC::Resource::HAL::Role::Set',
        'WebAPI::DBIC::Resource::HAL::Role::SetWritable',
        # Enable JSON API support:
        'WebAPI::DBIC::Resource::JSONAPI::Role::DBIC', # XXX move out?
        'WebAPI::DBIC::Resource::JSONAPI::Role::Set',
        'WebAPI::DBIC::Resource::JSONAPI::Role::SetWritable',
        ;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::GenericSet

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::GenericSet - a set of roles to implement a generic DBIC set resource

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
