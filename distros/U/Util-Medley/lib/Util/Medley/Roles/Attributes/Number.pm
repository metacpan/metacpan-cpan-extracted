package Util::Medley::Roles::Attributes::Number;
$Util::Medley::Roles::Attributes::Number::VERSION = '0.025';
use Modern::Perl;
use Moose::Role;
use Util::Medley::Number;

=head1 NAME

Util::Medley::Roles::Attributes::Number

=head1 VERSION

version 0.025

=cut

has Number => (
	is      => 'ro',
	isa     => 'Util::Medley::Number',
	lazy    => 1,
	default => sub { return Util::Medley::Number->new },
);

1;
