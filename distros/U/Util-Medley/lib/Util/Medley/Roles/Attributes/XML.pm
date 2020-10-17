package Util::Medley::Roles::Attributes::XML;
$Util::Medley::Roles::Attributes::XML::VERSION = '0.047';
use Modern::Perl;
use Moose::Role;
use Util::Medley::XML;

=head1 NAME

Util::Medley::Roles::Attributes::XML

=head1 VERSION

version 0.047

=cut

has Xml => (
	is      => 'ro',
	isa     => 'Util::Medley::XML',
	lazy    => 1,
	default => sub { return Util::Medley::XML->new },
);

1;
