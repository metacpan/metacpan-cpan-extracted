package WebAPI::DBIC::Resource::ActiveModel;
$WebAPI::DBIC::Resource::ActiveModel::VERSION = '0.004002';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::ActiveModel

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::ActiveModel - ActiveModel support for WebAPI::DBIC

=head2 Media Type

These roles respond to the C<application/json> media type.
(This is a very common 'default' media type for web data services.)

=head2 ActiveModel

Designed to match the behaviour of the active_model_serializers Ruby gem
and thus be directly usable as a backend for frameworks compatible with it,
including Ember.

See L<http://emberjs.com/api/data/classes/DS.ActiveModelAdapter.html>
for more information.

=head2 Roles

The L<WebAPI::DBIC::Resource::ActiveModel::Role::DBIC> role provides core methods
required to support the other roles listed below.

The L<WebAPI::DBIC::Resource::ActiveModel::Role::Set>
and L<WebAPI::DBIC::Resource::ActiveModel::Role::Item> roles handle GET and HEAD requests
for set (resultset) and item (row) resources.

The L<WebAPI::DBIC::Resource::ActiveModel::Role::SetWritable> role handles POST requests
to set (resultset) resources. It handles the recursive creation of related records.
Related records can be nested to any depth and are created from the bottom up
within a transaction.

The L<WebAPI::DBIC::Resource::ActiveModel::Role::ItemWritable> roles handle PUT and DELETE
requests for item (row) resources. It handles the recursive update of
related records.  Related records can be nested to any depth and are updated
from the bottom up within a transaction.  Handles both 'PUT is replace' and
'PUT is update' logic.

There's no ActiveModel specific handling for invoking methods on resources yet.
You can use the generic L<WebAPI::DBIC::Resource::Role::ItemInvoke> or
L<WebAPI::DBIC::Resource::Role::SetInvoke> role.

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
