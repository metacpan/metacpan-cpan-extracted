package Util::Medley::Roles::Attributes::FileZip;
$Util::Medley::Roles::Attributes::FileZip::VERSION = '0.007';
use Modern::Perl;
use Moose::Role;
use Method::Signatures;
use Util::Medley::FileZip;

=head1 NAME

Util::Medley::Roles::Attributes::FileZip

=head1 VERSION

version 0.007

=cut

has FileZip => (
	is      => 'ro',
	isa     => 'Util::Medley::FileZip',
	lazy    => 1,
	default => sub { return Util::Medley::FileZip->new },
);

1;
