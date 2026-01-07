package Thunderhorse::Config;
$Thunderhorse::Config::VERSION = '0.001';
use v5.40;
use Mooish::Base -standard;

use Path::Tiny qw(path);

extends 'Gears::Config';

sub load_from_files ($self, $conf_dir, $env)
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

