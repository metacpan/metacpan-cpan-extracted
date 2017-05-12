package WebAPI::DBIC::Resource::GenericItemInvoke;
$WebAPI::DBIC::Resource::GenericItemInvoke::VERSION = '0.004002';

use Moo;
use namespace::clean;

extends 'WebAPI::DBIC::Resource::GenericCore';
with    'WebAPI::DBIC::Resource::Role::Item',
        'WebAPI::DBIC::Resource::Role::ItemInvoke',
        ;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::GenericItemInvoke

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::GenericItemInvoke - a set of roles to implement a resource for making method calls on a DBIC item

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
