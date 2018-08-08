package UR::Role::MethodModifier;
use strict;
use warnings;

our $VERSION = "0.47"; # UR $VERSION

use Carp;
use Sub::Install;

my $idx = 1;
UR::Object::Type->define(
    class_name => 'UR::Role::MethodModifier',
    is_abstract => 1,
    id_by => [
        idx => { is => 'Integer' },
    ],
    has => [
        name => { is => 'String' },
        code => { is => 'CODE' },
        role_name => { is => 'String' },
        role => { is => 'UR::Role::Prototype', id_by => 'role_name' },
        type => { is => 'String' },
    ],
    id_generator => sub { $idx++ },
);

sub type {
    my $class = ref(shift);
    Carp::croak("Class $class didn't define sub type");
}

sub apply_to_package {
    my($self, $package) = @_;

    my $original_sub = $self->_get_original_sub($package);

    unless ($original_sub) {
        my $name = $self->name;
        Carp::croak(qq(Cannot apply 'before' modifier to $name: Can't locate method "$name" via package $package));
    }

    my $wrapper = $self->create_wrapper_sub($original_sub);
    my $fully_qualified_sub_name = join('::', $package, $self->name);

    $self->_install_sub($package, $wrapper);
}


sub _get_original_sub {
    my($self, $package) = @_;

    my $fully_qualified_subname = join('::', $package, $self->name);

    my $subref = do { no strict 'refs'; exists &$fully_qualified_subname and \&$fully_qualified_subname }
                 || $package->super_can($self->name);

    return $subref;
}

sub _install_sub {
    my($self, $package, $code) = @_;
    Sub::Install::reinstall_sub({
        into => $package,
        as => $self->name,
        code => $code,
    });
}
        

1;
