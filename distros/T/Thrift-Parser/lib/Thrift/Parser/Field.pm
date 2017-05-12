package Thrift::Parser::Field;

=head1 NAME

Thrift::Parser::Field - A single field in a structure

=cut

use strict;
use warnings;
use base qw(Class::Accessor::Grouped);
__PACKAGE__->mk_group_accessors(inherited => qw(id name value));

=head1 USAGE

=head2 id

Returns the id of this field in the structure.

=head2 name

Returns the name of the field.

=head2 value

Returns the L<Thrift::Parser::Type> object representing the value of this field.

=cut

sub new {
    my ($class, $self) = @_;
    $self ||= {};
    return bless $self, $class;
}

sub write {
    my ($self, $output) = @_;

    $output->writeFieldBegin($self->name, $self->value->type_id, $self->id);
    $self->value->write($output);
    $output->writeFieldEnd();
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
