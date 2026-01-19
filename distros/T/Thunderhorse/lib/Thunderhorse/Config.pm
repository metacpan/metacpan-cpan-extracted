package Thunderhorse::Config;
$Thunderhorse::Config::VERSION = '0.102';
use v5.40;
use Mooish::Base -standard;

use Path::Tiny qw(path);

extends 'Gears::Config';

sub load_from_files ($self, $conf_dir, $env = undef)
{
	$conf_dir = path($conf_dir);
	return unless -d $conf_dir;

	my @extensions = map { $_->handled_extensions } $self->readers->@*;

	foreach my $base_name ('config', $env // ()) {
		foreach my $ext (@extensions) {
			my $file = $conf_dir->child("$base_name.$ext");
			$self->add(file => "$file")
				if -f $file;
		}
	}

	return;
}

__END__

=head1 NAME

Thunderhorse::Config - Configuration handling for Thunderhorse

=head1 SYNOPSIS

	my $config_obj = $app->config;

=head1 DESCRIPTION

This class represents Thunderhorse app configuration. Most of the logic is
implemented in L<Gears::Config>, which this class extends.

=head1 INTERFACE

Inherits all interface from L<Gears::Config>, and adds the interface documented
below.

=head2 Methods

=head3 load_from_files

	$obj->load_from_files($conf_dir, $env = undef)

Loads configurations from files in C<$conf_dir>. Reads file C<config.*> and
C<$env.*>, where the extensions are determined by declared readers (C<.pl> by
default, via L<Gears::Config::Reader::PerlScript>). Reads all files in can
find, but will silently skip loading anything if it finds nothing.

=head1 SEE ALSO

L<Gears::Config>

