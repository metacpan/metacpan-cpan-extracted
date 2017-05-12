package WebAPI::DBIC::Resource::GenericCore;
$WebAPI::DBIC::Resource::GenericCore::VERSION = '0.004002';

use Moo;
use MooX::StrictConstructor;

extends 'WebAPI::DBIC::Resource::Base';
with    'WebAPI::DBIC::Role::JsonEncoder',
        'WebAPI::DBIC::Role::JsonParams',
        'WebAPI::DBIC::Resource::Role::Router',
        'WebAPI::DBIC::Resource::Role::Identity',
        'WebAPI::DBIC::Resource::Role::Relationship',
        'WebAPI::DBIC::Resource::Role::DBIC',
        'WebAPI::DBIC::Resource::Role::DBICException',
        'WebAPI::DBIC::Resource::Role::DBICAuth',
        'WebAPI::DBIC::Resource::Role::DBICParams',
        ;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::GenericCore

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::GenericCore - a set of core roles to implement a generic DBIC resources

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
