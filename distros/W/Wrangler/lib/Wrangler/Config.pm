package Wrangler::Config;

use strict;
use warnings;

use Cwd;
use JSON::XS ();
use File::HomeDir;
use Data::Dumper ();
use Digest::MD5 ();
use Path::Tiny;

# Wx::PlatformInfo; # check for unicode build

our %default_settings = (
	'ui.main.width'				=> 1000,
	'ui.main.height'			=> 800,
	'ui.main.maximized'			=> 0,
	'ui.main.centered'			=> 1,
	'ui.language'				=> 'en',
	'ui.foreground_colour'			=> [30, 30, 30],	# font-colour, def, if-undefined = use-system/wx-default
	'ui.layout.menubar'			=> 1,
	'ui.layout.navbar'			=> 1,
	'ui.layout.sidebar'			=> 1,
	'ui.layout.statusbar'			=> 1,
	'ui.sidebar.width'			=> 180,
	'ui.filebrowser.include_updir'		=> 1,			# def:1
	'ui.filebrowser.include_hidden'		=> 0,			# def:0
	'ui.filebrowser.zebra_striping'		=> 1,			# def:1
	'ui.filebrowser.highlight_media'	=> 1,			# def 1
	'ui.filebrowser.highlight_colour.audio'	=> [220, 220, 240],	# def
	'ui.filebrowser.highlight_colour.image'	=> [220, 240, 220],	# def
	'ui.filebrowser.highlight_colour.video'	=> [240, 220, 220],	# def
	'ui.filebrowser.font_size'		=> 9,			# def 9
	'ui.filebrowser.offer.delete'		=> 1,
	'ui.filebrowser.confirm.delete'		=> 1,
	'ui.filebrowser.columns'		=> [
		{ label => 'Name',		value_from => 'Filesystem::Filename',	text_align => 'left',  width => 120 },
		{ label => 'Type-Description',	value_from => 'MIME::Description',	text_align => 'right', width => 100 },
		{ label => 'Modified',		value_from => 'Filesystem::Modified',	text_align => 'left', width => 140 },
		{ label => 'Size',		value_from => 'Filesystem::Size',	text_align => 'right', width => 70 },
	],
	'metadata.extractionTimeout'		=> 1500,		# in ms
	'ui.formeditor.selected'		=> "Photo 'tagging'",
	'ui.formeditor'				=> {
		"Photo 'tagging'"	=> [
			"Filesystem::Filename",
			"Extended Attributes::orientation",
			"Extended Attributes::title",
			"Extended Attributes::description",
			"Extended Attributes::tags",
		]
	},
	'openwith'				=> {
		'image/*'	=> '/usr/bin/eog',
		'audio/*'	=> '/usr/bin/avplay',
		'video/*'	=> '/usr/bin/avplay',
		'text/*'	=> '/usr/bin/gedit',
	},
	'valueshortcuts'			=> {
		'1-49'	=> {
			name	=> "ALT+1",
			key	=> "Extended Attributes::orientation",
			value	=> "Rotate 270 CW",
		},
		'1-50'	=> {
			name	=> "ALT+2",
			key	=> "Extended Attributes::orientation",
			value	=> "Rotate 90 CW",
		},
	},
	'plugins'				=> {
		'ColourLabels'	=> 1,
	},
);
our %settings;
our $digest;
our %env;
if($^O =~ /Win/i){
	$env{HostOS}			= 'Windows';
	$env{PathSeparator}		= '\\';
	$env{CRLF}			= "\n";
	$env{HelperFfmpeg}		= Cwd::getcwd()."/helpers/ffmpeg-shared/ffmpeg.exe";
	$env{HelperMPlayer}		= Cwd::getcwd()."/helpers/mplayer/mplayer.exe";
	$env{UserConfigDir}		= $ENV{APPDATA} . $env{PathSeparator} . 'wrangler';
}elsif($^O =~ /nix$|ux$/i){
	$env{HostOS}			= 'Linux';
	$env{PathSeparator}		= '/';
	$env{CRLF}			= "\n";
	if(-e '/usr/bin/firefox'){
		$env{BrowserStartCommand} = 'firefox';
	}elsif(-e '/usr/bin/chromium-browser'){
		$env{BrowserStartCommand} = 'chromium-browser';
	}elsif(-e '/usr/bin/mozilla'){
		$env{BrowserStartCommand} = 'mozilla';
	}elsif(-e '/usr/bin/konqueror'){
		$env{BrowserStartCommand} = 'konqueror';
	}
	$env{HelperFfmpeg}		= "avconv";
	$env{HelperMPlayer}		= "mplayer";
	if( $ENV{XDG_CONFIG_HOME} ){
		($env{UserConfigDir}) = $ENV{XDG_CONFIG_HOME} =~ /:/ ? split(':', $ENV{XDG_CONFIG_HOME}, 2) : ($ENV{XDG_CONFIG_HOME}); # may hold multiple paths
		$env{UserConfigDir} .= $env{PathSeparator} . 'wrangler';
		# Wrangler::debug("Wrangler::Config::read: XDG_CONFIG_HOME:$ENV{XDG_CONFIG_HOME})");
	}else{
		$env{UserConfigDir} = File::HomeDir->my_home() . $env{PathSeparator} . ".config" . $env{PathSeparator} . 'wrangler';
	}
}elsif($^O =~ /Mac/i){
	$env{HostOS}			= 'Mac';
	$env{PathSeparator}		= ':';
	$env{CRLF}			= "\r";
	if(-e '/usr/bin/firefox'){
		$env{BrowserStartCommand} = 'firefox';
	}else{
		$env{BrowserStartCommand} = 'safari';
	}
	$env{HelperFfmpeg}		= "ffmpeg";
	$env{HelperMPlayer}		= "mplayer";
	$env{UserConfigDir}		= undef;
}
%env = (
	%env,
	'config.file.location'		=> 'home-dir',
);

sub read {
	my $path;
	if(-e Cwd::cwd . $env{PathSeparator} . '.wrangler.json' ){
		Wrangler::debug('Wrangler::Config::read: Planning to read settings file from working-dir: .wrangler.yaml');
		$path = Cwd::cwd . $env{PathSeparator} . '.wrangler.json';
		$env{'config.file.location'} = 'working-dir';
	}

	unless($path){
		$path = $env{UserConfigDir};
		$path .= $env{PathSeparator} . '.wrangler.json' if $path;
		if($path){
			$env{'config.file.location'} = 'home-dir';
			Wrangler::debug('Wrangler::Config::read: Planning to read settings file from home-dir: '.$path);
		}
	}

	unless($path){
		# OS specific system config-file locations
		if( $env{HostOS} eq 'Linux' ){
			$path = File::HomeDir->my_home() . $env{PathSeparator} . ".config" . $env{PathSeparator} . 'wrangler';
			$path = '/etc/wrangler/.wrangler.json';
		}elsif( $env{HostOS} eq 'Windows'){
			$path = undef;
		}elsif( $env{HostOS} eq 'Mac'){
			# todo
		}

		if($path){
			$env{'config.file.location'} = 'system-dir';
			Wrangler::debug('Wrangler::Config::read: Planning to read settings file from system-dir: '.$path);
		}
	}

	if($path && -f $path){
		Wrangler::debug('Wrangler::Config::read: reading settings file:'. $path);
		my $json = path($path)->slurp_utf8 or Wrangler::debug("Wrangler::Config::read: error reading config file: $!");
		my $ref = eval { JSON::XS::decode_json( $json ) };
		Wrangler::debug("Wrangler::Config::read: error decoding config file: $@") if $@;
		%settings = %$ref;
	}else{
		%settings = %default_settings;

		Wrangler::debug('Wrangler::Config::read: no config-file found; using default settings; on change, write config to '. $env{'config.file.location'} .': .wrangler.json');
	}

	$digest = Digest::MD5::md5( Data::Dumper::Dumper(\%settings) );

	## is the config file valid? check if show-stopping values are set
	$settings{'ui.main.width'} = $default_settings{'ui.main.width'} unless $settings{'ui.main.width'} && $settings{'ui.main.width'} > 30;
	$settings{'ui.main.height'} = $default_settings{'ui.main.height'} unless $settings{'ui.main.height'} && $settings{'ui.main.height'} > 30;
	$settings{'ui.filebrowser.columns'} = $default_settings{'ui.filebrowser.columns'} unless $settings{'ui.filebrowser.columns'};
}

sub config {
	if($_[1]){
		unless( defined($settings{ $_[1] }) ){
			Wrangler::debug("Wrangler::Config::config: key:$_[1] not defined!");
			return unless $_[2];
		}
		return $settings{ $_[1] } unless $_[2];
		Wrangler::debug("Wrangler::Config::config: $_[1] => $_[2]");
		$settings{ $_[1] } = $_[2];
	}
	return \%settings;
}

sub write {
	unless($digest){
		Wrangler::debug("Wrangler::Config::write: stopped (over-) writing an empty config file. Check your config file for syntax errors");
		return;
	}

	if( Digest::MD5::md5( Data::Dumper::Dumper(\%settings) ) eq $digest ){
		Wrangler::debug("Wrangler::Config::write: settings not changed, write skipped");
	}else{
		my $path;
		if( $env{'config.file.location'} eq 'working-dir' ){
			$path = Cwd::cwd . $env{PathSeparator} . '.wrangler.json';
		}else{	# the default
			$path = File::HomeDir->my_home() . $env{PathSeparator} . ".config";
			unless(-d $path){
				mkdir($path) or Wrangler::debug("Wrangler::Config::write: error creating directory $path");
			}
			$path .= $env{PathSeparator} . 'wrangler';
			unless(-d $path){
				mkdir($path) or Wrangler::debug("Wrangler::Config::write: error creating directory $path");
			}
			$path .= $env{PathSeparator} . '.wrangler.json';
		}

		Wrangler::debug("Wrangler::Config::write: settings from ".$env{'config.file.location'}." changed, write to: ".$path);

		my $json = eval { JSON::XS->new->utf8->pretty->encode( \%settings ) };
		Wrangler::debug("Wrangler::Config::write: error encoding config file: $@") if $@;

		path($path)->spew_utf8($json) or Wrangler::debug("Wrangler::Config::write: error writing config file: $path: $!")
	}
}

1;
