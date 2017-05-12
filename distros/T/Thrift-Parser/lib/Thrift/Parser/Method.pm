package Thrift::Parser::Method;

=head1 NAME

Thrift::Parser::Method - A Method call

=head1 DESCRIPTION

Parser representation of a service method call.  Created from an L<Thrift::IDL::Method> object.  See subclass documentation for specifics.

=cut

use strict;
use warnings;
use base qw(Class::Accessor::Grouped);
__PACKAGE__->mk_group_accessors('inherited', qw(idl idl_doc name return_class throw_classes));

=head1 METHODS

=head2 idl

Returns a reference to the L<Thrift::IDL::Method> that informed the creation of this class.

=head2 idl_doc

Returns a reference to the L<Thrift::IDL> object that this was formed from.

=head2 name

Returns the simple name of the method.

=head2 return_class

Returns the L<Thrift::Parser::Type> subclass that represents the type of value that's an expected return value for this method.

=head2 throw_classes

Returns a hash ref of L<Thrift::Parser::Type::Exception> subclasses that represent available exceptions to this method, keyed on the name in the specification.

=cut

sub new {
    my ($class, $self) = @_;
    $self ||= {};
    return bless $self, $class;
}

=head2 compose_message_call

  my $message = $subclass->compose_message_call(...);

Call with a list of key/value pairs.  See the derived subclass for a list of accepted keys.  The value can either be an object that's strictly typed or simple Perl data structure that is a permissable argument to the C<compose()> call of the given L<Thrift::Parser::Type>.

=cut

sub compose_message_call {
    my ($class, %args) = @_;

    return Thrift::Parser::Message->new({
        method    => $class,
        arguments => Thrift::Parser::FieldSet->compose($class, %args),
        type      => TMessageType::CALL,
    });
}

=head2 docs_as_pod

Returns a POD formatted string that documents a derived class.

=cut

sub docs_as_pod {
    Thrift::Parser::Type::docs_as_pod(@_);
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
