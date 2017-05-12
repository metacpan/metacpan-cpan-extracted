use strict;
use warnings;

use Module::Build;

# The horror below ensures that generated bindings get included in the
# distribution, as well as build when someone uses bare Git checkout.

my $build = subclass Module::Build (
code => <<'YOLO'
	sub ACTION_generate {
		my $self = shift;

		$self->depends_on ('build');

		my $protocol = $self->args ('protocol') || [
			$self->base_dir.'/protocol/wayland.xml',
			$self->base_dir.'/protocol/gtk-shell.xml',
			$self->base_dir.'/protocol/xdg-shell.xml',
			$self->base_dir.'/protocol/workspaces.xml',
			$self->base_dir.'/protocol/text.xml',
			$self->base_dir.'/protocol/wayland-test.xml',
			$self->base_dir.'/protocol/desktop-shell.xml',
			$self->base_dir.'/protocol/fullscreen-shell.xml',
			$self->base_dir.'/protocol/text-cursor-position.xml',
			$self->base_dir.'/protocol/input-method.xml',
			$self->base_dir.'/protocol/scaler.xml',
			$self->base_dir.'/protocol/screenshooter.xml',
		];

		foreach my $p (@$protocol) {
			system ($self->perl,
				'-I'.$self->blib.'/lib',
				$self->blib.'/script/wl-scanner.pl',
				$p, $self->base_dir.'/lib');

			die 'Failed to generate protocol module' if $?;
		}
	}

	sub ACTION_dist {
		my $self = shift;

		$self->depends_on ('generate');
		$self->SUPER::ACTION_dist (@_);
	}
YOLO
)->new(
	module_name => 'WL',
	license => 'open_source',
	dist_author => 'Lubomir Rintel <lkundrak@v3.sk>',
	dist_abstract => 'Perl Wayland protocol binding',
	dist_version => 0.92,
	meta_merge => {
		resources => {
			bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=WL',
			repository => 'https://github.com/lkundrak/perl-wayland',
		}
	},
	configure_requires => {
		'Module::Build' => 0.40,
	},
	requires => {
		'File::Temp' => 0,
		'XML::Smart' => 0,
		'IO::Socket::UNIX' => 0,
		'Socket::MsgHdr' => 0,
	},
	build_requires => {
		'XML::Smart' => 0,
	},
	add_to_cleanup => [
		'lib/WL.pm',
	],
	get_options => {
		'protocol' => {
			type => '=s@'
		},
	},
);

$build->create_build_script;
