package Util::Medley::Roles::Attributes::Logger;
$Util::Medley::Roles::Attributes::Logger::VERSION = '0.007';
use Modern::Perl;
use Moose::Role;
use Method::Signatures;
use Util::Medley::Logger;

=head1 NAME

Util::Medley::Roles::Attributes::Logger

=head1 VERSION

version 0.007

=cut

has Logger => (
	is      => 'ro',
	isa     => 'Util::Medley::Logger',
	lazy    => 1,
	default => sub { return Util::Medley::Logger->new },
);

1;
