package Thrift::Parser::Type::map;

=head1 NAME

Thrift::Parser::Type::map - map type

=head1 DESCRIPTION

This class inherits from L<Thrift::Parser::Type::Container>.  See the docs there for all the usage details.

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type::Container);
__PACKAGE__->mk_accessors(qw(key_type));

sub read {
    my ($self, $parser, $input, $meta) = @_;

    my @map;
    $input->readMapBegin(\$meta->{key_type}, \$meta->{val_type}, \$meta->{size});
    my %val_meta = ( type => $meta->{val_type} );
    my %key_meta = ( type => $meta->{key_type} );
    $val_meta{idl}{type} = $parser->resolve_idl_type( $meta->{idl}{type} )->val_type if $meta->{idl};
    $key_meta{idl}{type} = $parser->resolve_idl_type( $meta->{idl}{type} )->key_type if $meta->{idl};
    for (my $i = 0; $i < $meta->{size}; $i++) {
        my $key = $parser->parse_type($input, { %key_meta });
        my $val = $parser->parse_type($input, { %val_meta });
        push @map, [ $key => $val ];
    }
    $input->readMapEnd();

    $self->value(\@map);
    $self->val_type($meta->{val_type});
    $self->key_type($meta->{key_type});
    return $self;
}

sub write {
    my ($self, $output) = @_;

    my @map = @{ $self->value };
    $output->writeMapBegin($self->key_type, $self->val_type, int @map);
    foreach my $pair (@map) {
        $_->write($output) foreach @$pair;
    }
    $output->writeMapEnd();
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
