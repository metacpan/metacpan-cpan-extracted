package Util::Medley::Roles::Attributes::File;
$Util::Medley::Roles::Attributes::File::VERSION = '0.028';
use Modern::Perl;
use Moose::Role;
use Util::Medley::File;

=head1 NAME

Util::Medley::Roles::Attributes::File

=head1 VERSION

version 0.028

=cut

has File => (
	is      => 'ro',
	isa     => 'Util::Medley::File',
	lazy    => 1,
	default => sub { return Util::Medley::File->new },
);

1;
