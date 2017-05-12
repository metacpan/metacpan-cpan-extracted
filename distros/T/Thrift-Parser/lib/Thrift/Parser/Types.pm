package Thrift::Parser::Types;

=head1 NAME

Thrift::Parser::Types - stores some common type ids

=head1 DESCRIPTION

This is not documented, as it's behavior will probably change as more type data is incorporated into this from the L<Thrift> libraries.

=cut

use strict;
use warnings;
use Data::Dumper;

use Thrift::Parser::Type;

use Thrift::Parser::Type::Struct;
use Thrift::Parser::Type::Exception;

use Thrift::Parser::Type::Enum;

use Thrift::Parser::Type::Container;
use Thrift::Parser::Type::list;
use Thrift::Parser::Type::map;
use Thrift::Parser::Type::set;

use Thrift::Parser::Type::Number;
use Thrift::Parser::Type::byte;
use Thrift::Parser::Type::i16;
use Thrift::Parser::Type::i32;
use Thrift::Parser::Type::i64;
use Thrift::Parser::Type::double;

use Thrift::Parser::Type::string;
use Thrift::Parser::Type::binary;
use Thrift::Parser::Type::bool;
use Thrift::Parser::Type::void;

my %types = (
    STOP   => 0,
    VOID   => 1,
    BOOL   => 2,
    BYTE   => 3,
    I08    => 3,
    DOUBLE => 4,
    I16    => 6,
    I32    => 8,
    I64    => 10,
    STRING => 11,
    UTF7   => 11,
    STRUCT => 12,
    EXCEPTION => 12,
    MAP    => 13,
    SET    => 14,
    LIST   => 15,
    UTF8   => 16,
    UTF16  => 17,
);
my %types_by_id = (reverse %types);

sub to_name {
    my ($class, $id) = @_;
    return $types_by_id{$id};
}

sub to_id {
    my ($class, $name) = @_;
    return $types{uc $name};
}

sub read_method {
    my ($class, $id) = @_;

    # Grab the name with proper case ('String')
    my $name = lc $class->to_name($id);
    $name =~ s{^(.+)$}{\u$1};

    return 'read' . $name;
}

sub write_method {
    my ($class, $id) = @_;

    # Grab the name with proper case ('String')
    my $name = lc $class->to_name($id);
    $name =~ s{^(.+)$}{\u$1};

    return 'write' . $name;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;

1;
