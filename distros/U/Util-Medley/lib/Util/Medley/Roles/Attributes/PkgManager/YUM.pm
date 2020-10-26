package Util::Medley::Roles::Attributes::PkgManager::YUM;
$Util::Medley::Roles::Attributes::PkgManager::YUM::VERSION = '0.052';
use Modern::Perl;
use Moose::Role;
use Util::Medley::PkgManager::YUM;

=head1 NAME

Util::Medley::Roles::Attributes::PkgManager::YUM

=head1 VERSION

version 0.052

=cut

has PkgManagerYum => (
	is      => 'ro',
	isa     => 'Util::Medley::PkgManager::YUM',
	lazy    => 1,
	default => sub { return Util::Medley::PkgManager::YUM->new; }
);

1;
