package Util::Medley::Roles::Attributes::Crypt;
$Util::Medley::Roles::Attributes::Crypt::VERSION = '0.024';
use Modern::Perl;
use Moose::Role;
use Util::Medley::Crypt;

=head1 NAME

Util::Medley::Roles::Attributes::Crypt

=head1 VERSION

version 0.024

=cut

has Crypt => (
	is      => 'ro',
	isa     => 'Util::Medley::Crypt',
	lazy    => 1,
	default => sub { return Util::Medley::Crypt->new },
);

1;
