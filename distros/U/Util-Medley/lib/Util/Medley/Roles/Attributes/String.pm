package Util::Medley::Roles::Attributes::String;
$Util::Medley::Roles::Attributes::String::VERSION = '0.007';
use Modern::Perl;
use Moose::Role;
use Method::Signatures;
use Util::Medley::String;

=head1 NAME

Util::Medley::Roles::Attributes::String

=head1 VERSION

version 0.007

=cut

has String => (
	is      => 'ro',
	isa     => 'Util::Medley::String',
	lazy    => 1,
	default => sub { return Util::Medley::String->new },
);

1;
