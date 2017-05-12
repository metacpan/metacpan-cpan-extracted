package Thrift::Parser::Type::list;

=head1 NAME

Thrift::Parser::Type::list - list type

=head1 DESCRIPTION

This class inherits from L<Thrift::Parser::Type::Container>.  See the docs there for all the usage details.

=cut

use strict;
use warnings;
use base qw(Thrift::Parser::Type::Container);
use Data::Dumper;

sub read {
    my ($self, $parser, $input, $meta) = @_;

    $input->readListBegin(\$meta->{val_type}, \$meta->{size});
    my %val_meta = ( type => $meta->{val_type} );
    $val_meta{idl}{type} = $parser->resolve_idl_type( $meta->{idl}{type} )->val_type if $meta->{idl};
    my @list;
    for (my $i = 0; $i < $meta->{size}; $i++) {
        my $val = $parser->parse_type($input, { %val_meta });
        push @list, $val;
    }
    $input->readListEnd();

    $self->value(\@list);
    $self->val_type($meta->{val_type});
    return $self;
}

sub write {
    my ($self, $output) = @_;

    my @list = @{ $self->value };
    $output->writeListBegin($self->val_type, int @list);
    $_->write($output) foreach @list;
    $output->writeListEnd();
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
