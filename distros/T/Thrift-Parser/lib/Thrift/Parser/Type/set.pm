package Thrift::Parser::Type::set;

=head1 NAME

Thrift::Parser::Type::set - set type

=head1 DESCRIPTION

This class inherits from L<Thrift::Parser::Type::Container>.  See the docs there for all the usage details.

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);
use base qw(Thrift::Parser::Type::Container);

=head1 USAGE

=cut

sub read {
    my ($self, $parser, $input, $meta) = @_;

    $input->readSetBegin(\$meta->{val_type}, \$meta->{size});
    my %val_meta = ( type => $meta->{val_type} );
    $val_meta{idl}{type} = $parser->resolve_idl_type( $meta->{idl}{type} )->val_type if $meta->{idl};
    my @list;
    for (my $i = 0; $i < $meta->{size}; $i++) {
        my $val = $parser->parse_type($input, { %val_meta });
        push @list, $val;
    }
    $input->readSetEnd();

    $self->value(\@list);
    $self->val_type($meta->{val_type});
    return $self;
}

sub write {
    my ($self, $output) = @_;

    my @list = @{ $self->value };
    $output->writeSetBegin($self->val_type, int @list);
    $_->write($output) foreach @list;
    $output->writeSetEnd();
}

=head2 is_set

  if ($string_set->is_set($string)) { .. }

Pass a blessed object that matches the $val_type of this object, or at least a perl scalar that can be C<compose()>'ed into the class.  Returns boolean value if the value is present in this set.  Throws L<Thrift::Parser::InvalidArgument>.

=cut

sub is_set {
    my ($self, $test) = @_;

    if (! blessed $test) {
        $test = $self->{val_type_class}->compose($test);
    }
    elsif (! $test->isa( $self->{val_type_class} )) {
        Thrift::Parser::InvalidArgument->throw("is_set() must be called with a $$self{val_type_class} object");
    }

    foreach my $value (@{ $self->value }) {
        if ($value->equal_to($test)) {
            return 1;
        }
    }
    return 0;
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
