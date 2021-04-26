package Util::Medley::Roles::Attributes::Hostname;
$Util::Medley::Roles::Attributes::Hostname::VERSION = '0.060';
use Modern::Perl;
use Moose::Role;
use Util::Medley::Hostname;

=head1 NAME

Util::Medley::Roles::Attributes::Hostname

=head1 VERSION

version 0.060

=cut

has Hostname => (
	is      => 'ro',
	isa     => 'Util::Medley::Hostname',
	lazy    => 1,
	default => sub { return Util::Medley::Hostname->new },
);

1;
