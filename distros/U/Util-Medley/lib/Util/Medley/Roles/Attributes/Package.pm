package Util::Medley::Roles::Attributes::Package;
$Util::Medley::Roles::Attributes::Package::VERSION = '0.059';
use Modern::Perl;
use Moose::Role;
use Util::Medley::Package;

=head1 NAME

Util::Medley::Roles::Attributes::Package

=head1 VERSION

version 0.059

=cut

has Package => (
	is      => 'ro',
	isa     => 'Util::Medley::Package',
	lazy    => 1,
	default => sub { return Util::Medley::Package->new },
);

1;
