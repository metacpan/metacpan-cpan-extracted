package Util::Medley::Roles::Attributes::PkgManager::RPM;
$Util::Medley::Roles::Attributes::PkgManager::RPM::VERSION = '0.052';
use Modern::Perl;
use Moose::Role;
use Util::Medley::PkgManager::RPM;

=head1 NAME

Util::Medley::Roles::Attributes::PkgManager::RPM

=head1 VERSION

version 0.052

=cut

has PkgManagerRpm => (
	is      => 'ro',
	isa     => 'Util::Medley::PkgManager::RPM',
	lazy    => 1,
	default => sub { return Util::Medley::PkgManager::RPM->new; }
);

1;
