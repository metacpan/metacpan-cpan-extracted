package Util::Medley::Roles::Attributes::YAML;
$Util::Medley::Roles::Attributes::YAML::VERSION = '0.062';
use Modern::Perl;
use Moose::Role;
use Util::Medley::YAML;

=head1 NAME

Util::Medley::Roles::Attributes::YAML

=head1 VERSION

version 0.062

=cut

has Yaml => (
	is      => 'ro',
	isa     => 'Util::Medley::Yaml',
	lazy    => 1,
	default => sub { return Util::Medley::YAML->new },
);

1;
