package Test::Routine::Meta::Attribute::Trait::AutoClear;
{
  $Test::Routine::Meta::Attribute::Trait::AutoClear::VERSION = '0.004';
}
# ABSTRACT: The attribute trait that does T::R::AutoClear's work
use Moose::Role;

Moose::Util::meta_attribute_alias('AutoClear');
has initial_value => (
    is        => 'rw',
    predicate => '_has_initial_value',
);

around set_initial_value => sub {
    my ($orig, $self, $instance, $value) = @_;

    $self->initial_value($value);
    $self->$orig($instance, _unpack_initial_value($value, $instance));
};

around clear_value => sub {
    my ($clear_value, $self, $instance) = @_;

    if ($self->_has_initial_value) {
        $self->set_value(
            $instance,
            _unpack_initial_value($self->initial_value, $instance)
        );
    }
    else {
        $self->$clear_value($instance);
    }
};

sub _inline_clear_value {
    my $self = shift;
    my $instance = shift;
    my $slot_name = $self->name;
    "\$_[0]->meta->get_attribute('$slot_name')->clear_value(\$_[0]);";
}

sub _unpack_initial_value {
    my ($val, $instance) = @_;

    if (blessed $val && $val->isa('Test::Routine::Meta::Builder')) {
        return $val->($instance);
    }
    else {
        return $val;
    }
}


1;

__END__

=pod

=head1 NAME

Test::Routine::Meta::Attribute::Trait::AutoClear - The attribute trait that does T::R::AutoClear's work

=head1 VERSION

version 0.004

=head1 AUTHOR

Piers Cawley <pdcawley@bofh.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Piers Cawley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
