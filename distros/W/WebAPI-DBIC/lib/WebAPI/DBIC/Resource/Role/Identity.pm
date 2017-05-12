package WebAPI::DBIC::Resource::Role::Identity;
$WebAPI::DBIC::Resource::Role::Identity::VERSION = '0.004002';

use Moo::Role;

use Carp;


sub id_unique_constraint_name { # called as static method
   return 'primary',
}

sub id_column_names_for_item { # local
    my ($self, $item) = @_;
    return $item->result_source->unique_constraint_columns( $self->id_unique_constraint_name );
}

sub id_column_values_for_item { # used by ::Relationship
    my ($self, $item) = @_;
    return map { $item->get_column($_) } $self->id_column_names_for_item($item);
}

sub id_kvs_for_item { # used by path_for_item
    my ($self, $item) = @_;
    my @key_fields = $self->id_column_names_for_item($item);
    my $idn = 0;
    return map { ++$idn => $item->get_column($_) } @key_fields;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::Role::Identity

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::Role::Identity - methods related to the identity of resources

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
