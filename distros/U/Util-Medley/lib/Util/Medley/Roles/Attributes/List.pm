package Util::Medley::Roles::Attributes::List;
$Util::Medley::Roles::Attributes::List::VERSION = '0.020';
use Modern::Perl;
use Moose::Role;
use Util::Medley::List;

=head1 NAME

Util::Medley::Roles::Attributes::List

=head1 VERSION

version 0.020

=cut

has List => (
	is      => 'ro',
	isa     => 'Util::Medley::List',
	lazy    => 1,
	default => sub { return Util::Medley::List->new },
);

1;
