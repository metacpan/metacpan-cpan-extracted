package Util::Medley::Roles::Attributes::Logger;
$Util::Medley::Roles::Attributes::Logger::VERSION = '0.030';
use Modern::Perl;
use Moose::Role;
use Util::Medley::Logger;

=head1 NAME

Util::Medley::Roles::Attributes::Logger

=head1 VERSION

version 0.030

=cut

has Logger => (
	is      => 'ro',
	isa     => 'Util::Medley::Logger',
	lazy    => 1,
	default => sub { return Util::Medley::Logger->new },
);

1;
