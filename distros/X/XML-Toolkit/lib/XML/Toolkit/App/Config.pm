package XML::Toolkit::App::Config;
{
  $XML::Toolkit::App::Config::VERSION = '0.15';
}
use Moose::Role;
use namespace::autoclean;

use XML::Toolkit::Config::Container;

with qw( XML::Toolkit::Builder::NamespaceRegistry );

has _config => (
    does     => 'XML::Toolkit::Config',
    handles  => 'XML::Toolkit::Config',
    lazy     => 1,
    init_arg => 'config',
    builder  => '_build_config_container',
);

sub _build_config_container {
    my ($self) = @_;
    XML::Toolkit::Config::Container->new( xmlns => $self->xmlns ),;
}

1;
__END__