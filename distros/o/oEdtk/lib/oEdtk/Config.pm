package oEdtk::Config;
use FindBin qw($Bin);
use lib "$Bin";
use strict;
use warnings;

use Config::IniFiles;
use Sys::Hostname;
use oEdtk::logger;

use Exporter;
our $VERSION	= 1.5052;
our @ISA		= qw(Exporter);
our @EXPORT_OK	= qw(config_read get_ini_path);
my  $_INI_PATH;

sub get_ini_path(){
	return $_INI_PATH;
}


sub config_read(@) {
	my ($sections, $app);

	if (ref($_[0]) eq 'ARRAY') {
		$sections = $_[0];
		$app = $_[1];
	} else {
		$sections = \@_;
	}

	my $mod = __PACKAGE__;
	$mod =~ s/::/\//;
	$mod .= '.pm';
	my $dir = $INC{$mod};
	$dir =~ s/\/[^\/]+$//;
	&logger (8, "lib \$Bin = $Bin");


		my $ini;
		if (-e "$Bin/edtk.ini") {
			$ini = "$Bin/edtk.ini";
		} elsif (-e "$dir/iniEdtk/edtk.ini") {
			$ini = "$dir/iniEdtk/edtk.ini";
		} else {
			$ini = "$dir/iniEdtk/tplate.edtk.ini";
			#warn "INFO : accessing $ini\n";
			&logger (6, "Accessing $ini");
		}
		my $uchost= hostname();
		$uchost	  = uc($uchost);

		my %allcfg = ();
		for (;;) {
			die &logger (-1, "Config file not found or unreadable : $ini") unless -r $ini;
			#die "ERROR: config file not found or unreadable: $ini\n" unless -r $ini;
			tie %allcfg, 'Config::IniFiles', (-file => $ini, -default => 'DEFAULT');
			$_INI_PATH = $ini;

			my $ini2 = (tied %allcfg)->val($uchost, 'iniEdtk');
			last if not defined $ini2 or $ini2 eq $ini or $ini2 eq 'local';
			$ini = $ini2;
		}


	# Get the DEFAULT and ENVDESC sections by default, override with the optional
	# sections that we were given, and finally with the hostname section.
	my %cfg = ();
	$cfg{'EDTK_HOST'} = $uchost;
	$cfg{'USERNAME'}  = getlogin || getpwuid($<) || "undef";
	foreach ('DEFAULT', 'ENVDESC', @$sections, $uchost) {
		if (exists $allcfg{$_}) {
			%cfg = ( %cfg, %{$allcfg{$_}} );
		}
	}

	# Get current application name
	if (defined($app)) {
		$cfg{'EDTK_PRGNAME'} = $app;
	} else {
		if ($0 =~ /([\w\-\.]+)\.p[lm]$/i) {
			$cfg{'EDTK_PRGNAME'} = $1;
		} else {
			$cfg{'EDTK_PRGNAME'} = $0;
		}
	}
	$cfg{'EDTK_PRGPATH'} = $Bin;

	# Expand variables inside other variables.
	foreach my $key (keys %cfg) {
		while ($cfg{$key} =~ s/\$(\w+)/$cfg{$1}/ge) {
			;
		}
	}

return \%cfg;
}

1;
