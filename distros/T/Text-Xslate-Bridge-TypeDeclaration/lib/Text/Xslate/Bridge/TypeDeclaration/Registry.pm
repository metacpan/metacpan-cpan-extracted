package Text::Xslate::Bridge::TypeDeclaration::Registry;
use strict;
use warnings;
use parent qw(Type::Registry);

# override
sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new;
    $self->add_types('Types::Standard');
    return $self;
}

# override
sub simple_lookup {
    my ($self, $name, $flag) = @_;
    my $type = $self->SUPER::simple_lookup($name, $flag);

    # Given 1 to $flag when parsing a name (undocumented)
    return (!defined $type && $flag)
        ? $self->_class_type($name) : $type;
}

# override
sub foreign_lookup {
    my ($self, $name, $flag) = @_;
    my $type = $self->SUPER::foreign_lookup($name, $flag);
    return $type ? $type : $self->_class_type($name);
}

sub _class_type {
    my ($self, $name) = @_;

    my $type = $self->SUPER::simple_lookup($name);
    unless ($type) {
        $type = $self->make_class_type($name);
        $self->add_type($type, $name);
    }

    return $type;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

=head1 DESCRIPTION

The purpose of this package treats a name as a class type when a name is not found in registry.

This behavior works to allow type checking blessed objects when not using type libraries.

This is the default registry for L<Text::Xslate::Bridge::TypeDeclaration>. So you can prevent this when you set "registry" otpion to other L<Type::Registry> class.

=head1 SEE ALSO

L<Text::Xslate::Bridge::TypeDeclaration>.

L<Type::Tiny>, L<Type::Registry>, L<Mouse::Util::TypeConstraints>.
