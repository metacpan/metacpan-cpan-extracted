package ThoriumTestComponent;

use Moose;

extends 'Thorium::Conf';

use Cwd;
use FindBin qw();

has '+_system_directory_root' => (
    'default' => sub { $FindBin::Bin . '/etc' }
);

has '+component_name' => (
    'default' => 'thoriumtestcomponent'
);

has '+component' => ('builder' => '_build_component');

sub _build_component {
     return [ $FindBin::Bin . '/etc/component.yaml', $FindBin::Bin .  '/etc/another.yaml' ]
}

has '+component_root' => ('default' => $FindBin::Bin );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 DESCRIPTION

A sub class demonstrating and extending Thorium::Conf and used for testing
