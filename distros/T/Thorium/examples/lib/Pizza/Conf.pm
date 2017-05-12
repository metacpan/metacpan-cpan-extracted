package Pizza::Conf;

use Moose;

extends 'Thorium::Conf';

# core
use File::Spec;

# CPAN
use Dir::Self;

has '+component_name' => ('default' => 'pizza-maker');

has '+component_root' => ('default' => File::Spec->catdir(__DIR__, '..', '..'));

__PACKAGE__->meta->make_immutable;
no Moose;
