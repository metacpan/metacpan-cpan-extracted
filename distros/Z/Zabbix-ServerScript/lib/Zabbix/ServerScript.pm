package Zabbix::ServerScript;

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use YAML;
use JSON;
use Log::Log4perl;
use Log::Log4perl::Level;
use Proc::PID::File;
use Proc::Daemon;
use File::Basename;
use Exporter;
use Carp;
use Storable;
use Term::ReadLine;
use Term::UI;
use Getopt::Long qw(:config bundling);
use List::MoreUtils qw(uniq);

BEGIN {
	eval {
		require Zabbix::ServerScript::Config;
		1;
	} or eval {
		require Zabbix::ServerScript::DefaultConfig;
		1;
	} or die q(Either Zabbix::ServerScript::DefaultConfig or Zabbix::ServerScript::Config is required);
}

our @ISA = q(Exporter);
our @EXPORT = qw($config $logger $zx_api create_config);
our $VERSION = q(0.13);

our $config = {};
our $logger;
our $zx_api;

sub _get_options {
	my ($opt, @opt_specs) = @_;
	my $default_opt = {
		daemon => 0,
		verbose => 0,
		debug => 0,
		unique => 0,
		debug => 0,
		console => 0,
	};
	
	if (defined $opt){
		croak q($opt must be hashref) unless ref $opt eq q(HASH);
	} else {
		$opt = {};
	}

	map { $opt->{$_} = $default_opt->{$_} unless defined $opt->{$_} } keys %$default_opt;

	my @default_opt_specs = qw(
		verbose|v+
		debug
		daemon
		console
	);
	@opt_specs = uniq (@opt_specs, @default_opt_specs);
	GetOptions($opt, @opt_specs) or croak qq(Cannot get options);
	return $opt;
}

sub _set_basename {
	my @caller = @_;
	$ENV{BASENAME} = basename($caller[1]);
	$ENV{BASENAME} =~ s/\.pl$//;
	$ENV{BASENAME} =~ s/[\0\/]//;
	return;
}

sub _set_binmode {
	binmode(STDOUT, q(utf8:));
	binmode(STDERR, q(utf8:));
	return;
}

sub _set_id {
	my ($id) = @_;
	if (defined $id){
		$ENV{ID} = $id;
	} else {
		$ENV{ID} = $ENV{BASENAME};
	}
	return;
}

sub _set_logger {
	my ($opt) = @_;
	$opt = {} unless defined $opt;

	croak qq(Couldn't find 'log_dir' section in Zabbix::ServerScript::Config) unless defined $Zabbix::ServerScript::Config->{log_dir};
	croak qq(Environment variables BASENAME and ID are not set) unless (defined $ENV{BASENAME} and $ENV{ID});
	if (defined $opt->{log_filename}){
		if ($opt->{log_filename} ne q()){
			$ENV{LOG_FILENAME} = $opt->{log_filename};
		} else {
			$logger->logdie(q(Cannot log to empty filename));
		}
	} else {
		$ENV{LOG_FILENAME} = qq($Zabbix::ServerScript::Config->{log_dir}/$ENV{BASENAME}.log);
	}

	croak qq(Couldn't find 'log' section in Zabbix::ServerScript::Config) unless defined $Zabbix::ServerScript::Config->{log};
	Log::Log4perl->init($Zabbix::ServerScript::Config->{log});

	my $log_category;
	if (defined $opt->{logger}){
		if ($opt->{logger} eq q()){
			$log_category = q(Zabbix.ServerScript.nolog);
		} else {
			$log_category = $opt->{logger};
		}
	} else {
		if (defined $opt->{console} && $opt->{console} == 1){
			$log_category = q(Zabbix.ServerScript.console);
		} else {
			$log_category = q(Zabbix.ServerScript);
		}
	}
	$logger = Log::Log4perl::get_logger($log_category);
	$ENV{LOG_CATEGORY} = $log_category;
	
	if (defined $opt->{verbose} && $opt->{verbose}){
		$logger->more_logging($opt->{verbose});
	}
	if (defined $opt->{debug} && $opt->{debug} == 1){
		$logger->level($DEBUG);
	}

	$SIG{__DIE__} = sub {
		my ($message) = @_;
		if($^S and not (defined $ENV{ZBX_TESTING} and $ENV{ZBX_TESTING} == 1)) {
			# We're in an eval {} and don't want log
			# this message but catch it later
			return;
		}
		$Log::Log4perl::caller_depth++;
		$logger->fatal($message);
	};

	$SIG{__WARN__} = sub {
		my ($message) = @_;
		local $Log::Log4perl::caller_depth;
		$Log::Log4perl::caller_depth++;
		$logger->warn($message);
	};
	return;
}

sub _set_config {
	my ($config_filename) = @_;

	$logger->logcroak(qq(Environment variables BASENAME and ID are not set)) unless (defined $ENV{BASENAME} and $ENV{ID});

	if (not defined $config_filename){
		$config_filename = qq($Zabbix::ServerScript::Config->{config_dir}/$ENV{BASENAME}.yaml);
	}
	if ($config_filename ne q()){
		if (-f $config_filename){
			$logger->debug(qq(Loading local config from file $config_filename));
			$config = YAML::LoadFile($config_filename) or $logger->logdie(qq(Cannot load config from $config_filename));
		} else {
			$logger->debug(qq(Local config $config_filename was not found.)) unless $config_filename eq q();
		}
	}
	$config->{global} = $Zabbix::ServerScript::Config;
	return;
}

sub _set_api {
	my ($api) = @_;
	my $api_config;
	if (defined $api){
		require Zabbix::ServerScript::API;
		$zx_api = Zabbix::ServerScript::API::init($api);
	}
}

sub _get_pid {
	my ($id) = @_;
	my $name = $ENV{BASENAME};
	$name .= qq(_$id) if defined $id;
	$name =~ s/[\0\/]/_/g;
	my $pid = {
		name => $name,
		dir => $Zabbix::ServerScript::Config->{pid_dir},
	};
	$logger->debug(qq(Using PID file $pid->{dir}/$pid->{name}.pid));
	return $pid;
}

sub _set_unique {
	my ($unique, $id) = @_;
	if (defined $unique && $unique){
		my $pid = _get_pid($id);
		if (Proc::PID::File->running($pid)){
			croak(qq($pid->{name} is already running));
		}
	}
}

sub _set_daemon {
	my ($daemon) = @_;
	return Proc::Daemon::Init() if $daemon;
	return;
}

sub retrieve_cache {
	my ($cache_filename) = @_;
	if (not defined $cache_filename){
		$logger->debug(q(Cache filename is not specified, using default filename));
		$cache_filename = qq($Zabbix::ServerScript::Config->{cache_dir}/$ENV{BASENAME}.cache) 
	}
	my $cache;
	if (-f $cache_filename){
		$logger->debug(qq(Loading cache from "$cache_filename"));
		eval {
			$cache = retrieve $cache_filename;
			1;
		} or do {
			$logger->error(qq(Cannot retrieve cache from "$cache_filename": $@));
		};
	} else {
		$logger->info(qq(Cache file "$cache_filename" was not found));
	}
	return $cache;
}

sub store_cache {
	my ($cache, $cache_filename) = @_;
	if (not defined $cache_filename){
		$logger->debug(q(Cache filename is not specified, using default filename));
		$cache_filename = qq($Zabbix::ServerScript::Config->{cache_dir}/$ENV{BASENAME}.cache) 
	}
	$logger->debug(qq(Storing cache to $cache_filename));
	eval {
		store $cache, $cache_filename;
		1;
	} or do {
		$logger->error(qq(Cannot store cache to "$cache_filename"));
		return;
	};
	return 1;
}

sub init {
	my ($opt, @opt_specs) = @_;

	_get_options($opt, @opt_specs);
	_set_basename(caller);
	_set_id($opt->{id});
	_set_daemon($opt->{daemon});
	_set_logger($opt);
	_set_unique($opt->{unique}, $opt->{id});
	_set_config($opt->{config});
	_set_api($opt->{api});
	$logger->debug(q(Initialized Zabbix::ServerScript));
}

sub return_value {
	my ($value) = @_;
	if (defined $value){
		$logger->debug(qq(Return value: $value));
		chomp $value;
		print qq($value\n);
		exit;
	} else {
		$logger->logcroak(q(Return value is not defined));
	}
}

sub connect_to_db {
	my ($dbname, $user, $password, $mode) = @_;
	$logger->logcroak(q(dbname is not defined)) unless defined $dbname;
	my $dbh;
	$logger->debug(qq(Trying to connect to $dbname via ODBC));
	$dbh = DBI->connect(
		qq(dbi:ODBC:DSN=$dbname),
		$user,
		$password,
	) or $logger->logcroak(qq(Failed to connect to $dbname: $DBI::errstr));
	$logger->debug(qq(Connected to $dbname));
	return $dbh;
}

sub _prepare_sender_data {
	my ($request_data) = @_;
	if (ref($request_data) eq q(HASH)){
		$request_data = [ $request_data ];
	} elsif (ref($request_data) ne q(ARRAY)){
		croak(qq(Request is neither arrayref nor hashref: ) . Dumper($request_data));
	}
	$request_data = {
		request => q(sender data),
		data => $request_data,
	};
	# encode_json throws an exception itself, if it cannot encode json.
	# This 'croak' stands here just in case encode_json implementation will be changed.
	my $request_json = encode_json($request_data) or croak(qq(Cannot encode to JSON: ) . Dumper($request_data));
}

sub _proceed_sender_response {
	my ($response_json) = @_;
	$response_json =~ s/^.+(?={)//;
	my $response_data = decode_json($response_json) or croak(qq(Cannon decode JSON));
	return $response_data;
}

sub send {
	my ($request_data, $sender_host, $sender_port) = @_;
	$sender_host = q(localhost) if not defined $sender_host;
	$sender_port = q(10051) if not defined $sender_port;
	$logger->debug(qq(Opening sender socket to $sender_host:$sender_port));
	require IO::Socket::INET;
	my $socket = IO::Socket::INET->new(
		PeerAddr => $sender_host,
		PeerPort => $sender_port,
		Proto => q(tcp),
		Timeout => 10,
	) or croak(qq(Cannot open socket for zabbix sender to "$sender_host:$sender_port": $?));

	my $request_json = _prepare_sender_data($request_data);
	my $request_length = length($request_json);
	my $response_json;

	$logger->debug(qq(Writing $request_length of data to sender socket: $request_json));
	$socket->write($request_json, $request_length) or croak(qq(Cannot write to socket: $!));
	$socket->read($response_json, 2048) or croak(qq(Cannot read from socket: $!));
	$socket->close or croak(qq(Cannot close socket: $!));
	$logger->debug(qq(Server answered to sender: $response_json));
	my $response_data = _proceed_sender_response($response_json);
	return $response_data;
}

sub create_config {
	require Zabbix::ServerScript::DefaultConfig;

	my ($opt) = @_;
	$opt = {
		console => 1,
		verbose => 1,
		(defined $opt ? %$opt : ()),
	};
	print Dumper($opt);
	init($opt);

	my $term = Term::ReadLine->new('Zabbix::ServerScript');
	(my $module_dir = dirname($INC{q(Zabbix/ServerScript/DefaultConfig.pm)})) =~ s|//|/|g;
	$module_dir = $term->get_reply(
		prompt => q(Directory to store Config.pm),
		default => $module_dir,
	);
	die(qq(Wrong directory: $module_dir)) unless (-d $module_dir and -w $module_dir);
	$logger->debug(qq(Will store Config.pm in $module_dir));

	my $module_filename = qq($module_dir/Config.pm);
	if (-f $module_filename){
		$term->ask_yn(
			prompt => qq(\n$module_filename exists.\nOverwrite?),
			default => q(n),
		) or exit 0;
		$logger->info(q(Overwrite has been requested));
	}

	for my $section (qw(config_dir pid_dir log_dir)){
		$Zabbix::ServerScript::Config->{$section} = $term->get_reply(
			prompt => $section,
			default => $Zabbix::ServerScript::Config->{$section},
		);
	}

	open my $fh, q(>), $module_filename or die(qq(Cannot open file $module_filename: $!)); 
	print $fh Data::Dumper->Dump([$Zabbix::ServerScript::Config], [q($Zabbix::ServerScript::Config)]);
	close $fh;

	require $module_filename or die(qq(Cannot load module: $!));
	$logger->info(qq($module_filename has been created successfully));
	exit 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

Zabbix::ServerScript - Simplify your Zabbix server scripts' environment.

=head1 SYNOPSIS

    #!/usr/bin/perl
    
    use strict;
    use warnings;
    use utf8;
    use Zabbix::ServerScript;
    
    my $opt = {
    	id => 1,
    };
    
    my @opt_specs = qw(
    	id=i
    );
    
    sub main {
    	Zabbix::ServerScript::init($opt, @opt_specs);
	Zabbix::ServerScript::return_value(1);
    }

    main();

=head1 DESCRIPTION

Zabbix::ServerScript is a module to simplify writing new scripts for Zabbix server: external scripts, alert scripts, utils, etc.

=head1 SUBROUTINES

=head2 init($opt, @opt_specs)

Initializes variables, sets logger, API, etc.

If specified, the first argument must be hashref, which can have the following keys:
	
	$opt = {
		config => q(path/to/local/config.yaml),
		console => 0, 				# should the script log to STDERR or not
		verbose => 0, 				# increase verbosity. By default, script will log only WARN messages and above.
		debug => 0, 				# Enable debug mode.
		logger => q(Zabbix.ServerScript), 	# Log4perl logger name
		api => q(),				# name of Zabbix API instance in global config
		id => q(),	 			# unique identifier of what is being done, e.g.: database being checked
		unique => 0, 				# only one instance for each $opt->{id} is allowed
		daemon => 0, 				# daemonize during initialization. See Proc::Damon for details
	}

If specified, the 2nd argument must be array of options descriptions, as for Getopt::Long::GetOptions.

The following options descrtiptions are included by default (see their meanings above):

	verbose|v+ # --verbose (supports bundling, e.g. -vvv)
	debug
	daemon
	console


Initializes the following global variables: 

=over 4

=item $logger

Log4perl instance

=item $config 

hashref contais both local (script-specific) and global config data.

Default global config is located at Zabbix/ServerScript/DefaultConfig.pm.

User can generate its own global config and store it into Zabbix/ServerScript/Config.pm. Config.pm is preferred over DefaultConfig.pm.

Global config data can be accessed through $Zabbix::ServerScript::Config and $config->{global} variables.

Script-specific config is searched within $Zabbix::ServerScript::Config->{config_dir} path. Only YAML is currently supported for script-specific configs.

	$config = {
		global => {
			config_dir => q(/path/to/local/config/dir),
			log_dir => q(/tmp),
			...,
		},
		local_item1 => ...,
		local_item2 => ...,
	}

=item $zx_api

Zabbix::ServerScript::API object

=back

=head2 return_value($value)

Prints $value to STDOUT and exits. Throws an exception if $value is not defined.

=head2 store_cache($cache, $cache_filename)

Stores cache to file using Storable module. $cache_filename is optional.

=head2 retrieve_cache($cache_filename)

Retrieves cache from file using Storable module. $cache_filename is optional.

=head2 connect_to_db($dsn, $user, $password)

Connects to database via unixODBC. $dsn is mandatory.
Returns database handle or throws an exception on failure.

=head2 send($data_structure)

Send data to Zabbix trapper like zabbix_sender does. $data_structure is mandatory.
Returns server response on success or throws an exception on failure.
$data_structure must be either hashref or arrayref of hashrefs.

Each of hashref must be like:

	{
		host => q(Linux host),	# hostname as in Zabbix frontend
		key => q(item_key),
		value => 1,
		clock => time,		# unix timestamp, optional
	}

=head2 create_config

Creates Config.pm from DefaultConfig.pm.

Usage:

	perl -MZabbix::ServerScript -e create_config

=head1 LICENSE

Copyright (C) Anton Alekseyev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Alekseyev E<lt>akint.wr+github@gmail.comE<gt>

=cut
