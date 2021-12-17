package Util::Medley::Roles::Attributes::Hash;
$Util::Medley::Roles::Attributes::Hash::VERSION = '0.061';
use Modern::Perl;
use Moose::Role;
use Util::Medley::Hash;

=head1 NAME

Util::Medley::Roles::Attributes::Hash

=head1 VERSION

version 0.061

=cut

has Hash => (
	is      => 'ro',
	isa     => 'Util::Medley::Hash',
	lazy    => 1,
	default => sub { return Util::Medley::Hash->new },
);

1;
