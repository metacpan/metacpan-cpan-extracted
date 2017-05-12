package WebAPI::DBIC::Resource::ActiveModel::Role::ItemWritable;
$WebAPI::DBIC::Resource::ActiveModel::Role::ItemWritable::VERSION = '0.004002';

use Carp qw(croak confess);
use Devel::Dwarn;

use Moo::Role;


requires 'decode_json';
requires 'request';

requires '_pre_update_resource_method';


around '_build_content_types_accepted' => sub {
    my $orig = shift;
    my $self = shift;
    my $types = $self->$orig();
    unshift @$types, { 'application/json' => 'from_activemodel_json' };
    return $types;
};


sub from_activemodel_json {
    my $self = shift;

    $self->_pre_update_resource_method( "_do_update_embedded_resources_activemodel" );

    my $data = $self->decode_json( $self->request->content );

    $self->update_resource($data, is_put_replace => 0);

    return;
}


sub _do_update_embedded_resources_activemodel {
    my ($self, $item, $activemodel, $result_class) = @_;

    my $embedded = delete $activemodel->{_embedded} || {};

    for my $rel (keys %$embedded) {

        my $rel_info = $result_class->relationship_info($rel)
            or die "$result_class doesn't have a '$rel' relation\n";
        die "$result_class _embedded $rel isn't a 'single' relationship\n"
            if $rel_info->{attrs}{accessor} ne 'single';

        my $rel_activemodel = $embedded->{$rel};
        die "_embedded $rel data is not a hash\n"
            if ref $rel_activemodel ne 'HASH';

        # work out what keys to copy from the subitem we're about to update
        # XXX this isn't required unless updating key fields - optimize
        my %fk_map;
        my $cond = $rel_info->{cond};
        for my $sub_field (keys %$cond) {
            my $our_field = $cond->{$sub_field};
            $our_field =~ s/^self\.//x    or confess "panic $rel $our_field";
            $sub_field =~ s/^foreign\.//x or confess "panic $rel $sub_field";
            $fk_map{$our_field} = $sub_field;

            die "$result_class already contains a value for '$our_field'\n"
                if defined $activemodel->{$our_field}; # null is ok
        }

        # update this subitem (and any resources embedded in it)
        my $subitem = $item->$rel();
        $subitem = $self->_do_update_resource($subitem, $rel_activemodel, $rel_info->{source});

        # copy the keys of the subitem up to the item we're about to update
        warn "$result_class $rel: propagating keys: @{[ %fk_map ]}\n"
            if $ENV{WEBAPI_DBIC_DEBUG};
        while ( my ($ourfield, $subfield) = each %fk_map) {
            $activemodel->{$ourfield} = $subitem->$subfield();
        }

        # XXX perhaps save $subitem to optimise prefetch handling?
    }

    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebAPI::DBIC::Resource::ActiveModel::Role::ItemWritable

=head1 VERSION

version 0.004002

=head1 NAME

WebAPI::DBIC::Resource::ActiveModel::Role::ItemWritable - methods handling JSON API requests to update item resources

=head1 AUTHOR

Tim Bunce <Tim.Bunce@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
