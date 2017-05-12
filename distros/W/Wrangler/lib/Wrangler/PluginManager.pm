package Wrangler::PluginManager;

use strict;
use warnings;

our @plugins;
our $phase_plugins;
our %enabled;
sub load_plugins {
	my $wrangler = shift;
	die 'Wrangler::PluginManager has a functional interface but needs the $wrangler obj for plugins' unless $wrangler;

	my %seen = ();
	# this is modeled after Padre::PluginManager::load_plugins
	foreach my $inc (@INC) {
		my $dir = File::Spec->catdir( $inc, 'Wrangler', 'Plugin' );
		next unless -d $dir;

		Wrangler::debug("Wrangler::PluginManager::load_plugins: readdir $dir");
		opendir(my $dirh, $dir) or die "Wrangler::PluginManager::load_plugins: opendir $dir failed: $!";
		my @files = readdir($dirh) or die "Wrangler::PluginManager::load_plugins: readdir $dir failed: $!";
		closedir($dirh) or die "Wrangler::PluginManager::load_plugins: closedir $dir failed: $!";

		foreach (@files) {
			next unless s/\.pm$//;
			my $module = "Wrangler::Plugin::$_";
			next if $seen{$module}++;

			Wrangler::debug("Wrangler::PluginManager::load_plugins: module:$module in $dir");
			eval "use $module ();";
			Wrangler::debug(" eval 'use' module failed:\n $@") if $@;

			# Wrangler::debug(' version: '. ${ $module . '::VERSION' }) if ${ $module . '::VERSION' };

			next unless $module->can('plugin_phases');

			my $plugin = $module->new($wrangler) or next;

			next unless ref($plugin) =~ /^Wrangler::Plugin::/;

			push(@plugins,$plugin);
		}
	}

	# call plugins for phase "wrangler_startup"
	if( my $plugins_ref = Wrangler::PluginManager::plugins('wrangler_startup') ){
		for my $plugin (@$plugins_ref){
			# print "PluginManager::load_plugins and call startup: $plugin\n";
			$plugin->wrangler_startup();
		}
	}
}

# loading plugin simply prepares the obj, by calling new, which shouldn't do much
# plugs then are actually 'enabled' later on, by calling enable_plugin(), which
# calls the Plugin's enable_plugin and pushes the pos into @enabled
sub enable_plugin {
	Wrangler::debug("Enable Plugin '$_[0]'");
	$enabled{$_[0]} = 1;
	$Wrangler::Config::settings{'plugins'}{$_[0]} = 1;
	return 1;
}
sub disable_plugin {
	return 0 unless defined($Wrangler::Config::settings{'plugins'}{$_[0]});
	Wrangler::debug("Disable Plugin '$_[0]'");
	$Wrangler::Config::settings{'plugins'}{$_[0]} = 0;
	return 1;
}
sub is_enabled {
	# Wrangler::debug("PluginManager::is_enabled: @_");
	return $Wrangler::Config::settings{'plugins'}{$_[0]};
}


sub plugins {
	my $phase = shift;

	return unless $Wrangler::Config::settings{'plugins'};

	return \@plugins unless $phase;

	# in case we got a phase, return only plugins for this phase
	unless($phase_plugins){
		for(@plugins){
			next unless $Wrangler::Config::settings{'plugins'}{ $_->plugin_name };
			for my $phase (keys %{ $_->plugin_phases() }){
				push(@{ $phase_plugins->{$phase} }, $_);
			}
		}
		# require Data::Dumper;
		# Wrangler::debug("Done building optimisation hash:".Data::Dumper::Dumper(\@plugins, $phase_plugins));
	}

	return $phase_plugins->{$phase};
}

1;
