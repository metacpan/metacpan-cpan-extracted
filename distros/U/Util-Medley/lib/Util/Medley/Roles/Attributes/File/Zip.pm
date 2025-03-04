package Util::Medley::Roles::Attributes::File::Zip;
$Util::Medley::Roles::Attributes::File::Zip::VERSION = '0.062';
use Modern::Perl;
use Moose::Role;
use Util::Medley::File::Zip;

=head1 NAME

Util::Medley::Roles::Attributes::File::Zip

=head1 VERSION

version 0.062

=cut

has FileZip => (
	is      => 'ro',
	isa     => 'Util::Medley::File::Zip',
	lazy    => 1,
	default => sub { return Util::Medley::File::Zip->new },
);

1;
