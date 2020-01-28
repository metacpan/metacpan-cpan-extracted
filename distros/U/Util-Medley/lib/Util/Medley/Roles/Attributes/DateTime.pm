package Util::Medley::Roles::Attributes::DateTime;
$Util::Medley::Roles::Attributes::DateTime::VERSION = '0.024';
use Modern::Perl;
use Moose::Role;
use Util::Medley::DateTime;

=head1 NAME

Util::Medley::Roles::Attributes::DateTime

=head1 VERSION

version 0.024

=cut

has DateTime => (
	is      => 'ro',
	isa     => 'Util::Medley::DateTime',
	lazy    => 1,
	default => sub { return Util::Medley::DateTime->new },
);

1;
