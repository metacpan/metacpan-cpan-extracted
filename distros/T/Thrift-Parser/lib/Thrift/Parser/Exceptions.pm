package Thrift::Parser::Exceptions;

=head1 NAME

Thrift::Parser::Exceptions

=head1 DESCRIPTION

Subclass of L<Exception::Class> that provides various classes for different types of exceptions.

=head1 SUBCLASSES

=head2 Thrift::Parser::InvalidTypedValue

=head2 Thrift::Parser::InvalidArgument

Has fields 'key' and 'value'

=head2 Thrift::Parser::InvalidSpec

=head2 Thrift::Parser::NotImplemented

=cut

use strict;
use warnings;

use Exception::Class (
    'Thrift::Parser::Exception',

    'Thrift::Parser::InvalidTypedValue' => {
        isa => 'Thrift::Parser::Exception',
    },

    'Thrift::Parser::InvalidArgument' => {
        isa => 'Thrift::Parser::Exception',
        fields => [ 'key', 'value' ],
    },

    'Thrift::Parser::InvalidSpec' => {
        isa => 'Thrift::Parser::Exception',
    },

    'Thrift::Parser::NotImplemented' => {
        isa => 'Thrift::Parser::Exception',
    },
);

1;
