package Util::Medley::Roles::Attributes::Spawn;
$Util::Medley::Roles::Attributes::Spawn::VERSION = '0.037';
use Modern::Perl;
use Moose::Role;
use Util::Medley::Spawn;

=head1 NAME

Util::Medley::Roles::Attributes::Spawn

=head1 VERSION

version 0.037

=cut

has Spawn => (
	is      => 'ro',
	isa     => 'Util::Medley::Spawn',
	lazy    => 1,
	default => sub { return Util::Medley::Spawn->new },
);

1;
