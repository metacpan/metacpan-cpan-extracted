package VUser::Install;
use warnings;
use strict;

# Copyright 2005 Randy Smith <perlstalker@vuser.org>
# $Id: Install.pm,v 1.6 2005/10/13 17:04:38 perlstalker Exp $

use vars ('@ISA');

use VUser::ExtLib qw(strip_ws check_bool);
use VUser::Meta;
use VUser::ResultSet;
use VUser::Extension;
push @ISA, 'VUser::Extension';

our $REVISION = (split (' ', '$Revision: 1.6 $'))[1];
our $VERSION = '0.1.0';

my $c_sec = 'Extension_Install';

my %meta = (
	    'service' => VUser::Meta->new('name' => 'service',
					  'type' => 'string',
					  'description' => ''),
	    'ip' => VUser::Meta->new('name' => 'ip',
				     'type' => 'string', # IPv4
				     'description' => 'IP Address'),
	    'mac' => VUser::Meta->new('name' => 'mac',
				      'type' => 'string', # MAC addr
				      'description' => 'MAC address'),
	    'hostname' => VUser::Meta->new('name' => 'hostname',
					   'type' => 'string',
					   'description' => 'Host name'),
	    'disk' => VUser::Meta->new('name' => 'disk',
				       'type' => 'string',
				       'description' => 'Disk to partition'),
	    'kernel' => VUser::Meta->new('name' => 'kernel',
					 'type' => 'string',
					 'description' => 'Default kernel')
	    );

my %lcfg; # Local config

my $debug = $main::DEBUG;
my $verbose = $debug;

sub version { return $VERSION; }
sub revision { return $REVISION; }

sub unload { return; }

sub init
{
    my $eh = shift;
    my %cfg = @_;

    my $lconfig = strip_ws($cfg{$c_sec}{'config dir'}).'/VUser-Install.ini';
    if (-e $lconfig) {
	tie %lcfg, 'Config::IniFiles', (-file => $lconfig);
    } else {
	die "Config file $lconfig doesn't exist\n";
    }

    # install
    $eh->register_keyword('install', 'Installation tools');

    # install-diskless
    $eh->register_action('install', 'diskless', 'Manage diskless installs');
    $eh->register_option('install', 'diskless', $meta{'service'}, 'req');
    $eh->register_option('install', 'diskless', $meta{'ip'}, 'req');
    $eh->register_option('install', 'diskless', $meta{'mac'}, 'req');
    $eh->register_option('install', 'diskless', $meta{'hostname'}, 'req');
    $eh->register_option('install', 'diskless', $meta{'disk'});
    $eh->register_option('install', 'diskless', $meta{'kernel'});
    # Local scripts are usually only run on the server that is being installed
    # and a disk is required. The 'local-scripts' option tells VUser::Install
    # to run the scripts in the diskless root space. This can 'almost' be
    # used to force a diskless install when a disk is required. I say
    # 'almost' because certain things, e.g. /etc/fstab, expect to be mounting
    # those disks.
    $eh->register_option('install', 'diskless', 'local-scripts', '', 0,
			 'Run local commands');
    $eh->register_task('install', 'diskless', \&install_diskless);

    # install-standalone
    $eh->register_action('install', 'standalone', 'Not implemented');
    $eh->register_option('install', 'standalone', $meta{'service'}, 'req');
    $eh->register_option('install', 'standalone', $meta{'ip'}, 'req');
    $eh->register_option('install', 'standalone', $meta{'mac'});
    $eh->register_option('install', 'standalone', $meta{'hostname'}, 'req');
    $eh->register_option('install', 'standalone', $meta{'disk'}, 'req');
    $eh->register_option('install', 'standalone', $meta{'kernel'});
    #$eh->register_task('install', 'standalone', \&install_standalone);

    # install-tarball
    $eh->register_action('install', 'tarball', 'Get the location of the install tarball');
    $eh->register_option('install', 'tarball', $meta{'service'}, 'req');
    $eh->register_option('install', 'tarball', $meta{'ip'}, 'req');
    $eh->register_task('install', 'tarball', \&install_tarball);

    # install-diskrequired
    $eh->register_action('install', 'diskrequired', 'See if a local disk is required for the given service');
    $eh->register_option('install', 'diskrequired', $meta{'service'}, 'req');
    $eh->register_task('install', 'diskrequired', \&install_diskrequired);

    # install-diskinfo
    $eh->register_action('install', 'diskinfo', 'Get partition info for disk');
    $eh->register_option('install', 'diskinfo', $meta{'service'}, 'req');
    $eh->register_task('install', 'diskinfo', \&install_diskinfo);

    # install-partinfo
    $eh->register_action('install', 'partinfo', 'Get partition info for disk');
    $eh->register_option('install', 'partinfo', $meta{'service'}, 'req');
    $eh->register_task('install', 'partinfo', \&install_partinfo);

    # install-fsinfo
    $eh->register_action('install', 'fsinfo', 'Get filesystem info for disks');
    $eh->register_option('install', 'fsinfo', $meta{'service'}, 'req');
    $eh->register_task('install', 'fsinfo', \&install_fsinfo);

    # install-mountinfo
    $eh->register_action('install', 'mountinfo', 'Get mount point info for disks');
    $eh->register_option('install', 'mountinfo', $meta{'service'}, 'req');
    $eh->register_task('install', 'mountinfo', \&install_mountinfo);

    # install-services
    $eh->register_action('install', 'services', 'Get the list of available services');
    $eh->register_task('install', 'services', \&install_services);

    # update
    $eh->register_keyword('update', 'Update tools');

    # update-dhcp
    $eh->register_action('update', 'dhcp', 'Update dhcp configuration');
    $eh->register_task('update', 'dhcp', \&update_dhcp);

    # upgrade
    $eh->register_keyword('upgrade', 'Upgrade systems');

    # upgrade-diskless
    $eh->register_action('upgrade', 'diskless', 'Upgrade diskless installs');
    $eh->register_option('upgrade', 'diskless', $meta{'service'});
    $eh->register_option('upgrade', 'diskless', $meta{'ip'});
    $eh->register_option('upgrade', 'diskless', 'local-scripts', '', 0,
			 'Run local commands');
    $eh->register_task('upgrade', 'diskless', \&upgrade_diskless);

    # uninstall
    $eh->register_keyword('uninstall', 'Uninstall management');

    # uninstall-diskless
    $eh->register_action('uninstall', 'diskless', 'Remove a node from diskless setup');
    $eh->register_option('uninstall', 'diskless', $meta{'ip'}, 'req');
    $eh->register_task('uninstall', 'diskless', \&uninstall_diskless);

    # uninstall-standalone?

    # Optionally update dhcp on a install (or uninstall) diskless.
    if (check_bool($cfg{$c_sec}{'auto-update dhcp'})) {
	$eh->register_task('install', 'diskless', \&update_dhcp, '+ 1');
	$eh->register_task('uninstall', 'diskless', \&update_dhcp, '+ 1');
    }
}

sub install_diskless
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $prototypes = strip_ws($cfg->{$c_sec}{'prototype dir'});
    my $diskless = strip_ws($cfg->{$c_sec}{'diskless dir'});
    my $data_dir = strip_ws($cfg->{$c_sec}{'data dir'});
    my $config_dir = strip_ws($cfg->{$c_sec}{'config dir'});

    my $service = $opts->{'service'};
    if (not $lcfg{$service} or not -d $prototypes) {
	die "No such service '$service'\n";
    }

    my $kernel = $opts->{'kernel'} || 'bzImage';
    my $nfs_server = strip_ws($lcfg{$service}{'nfs server'});
    die "No NFS server defined\n" unless defined $nfs_server;

    my $ip = $opts->{'ip'};

    if (not -e "$diskless/$service" or not -d "$diskless/$service") {
	die "$diskless/$service does not exist or is not a directory\n";
    }

    my $disk = $opts->{'disk'} || '';
    
    # Add the new server to the config file that we'll use to write
    # dhcp.conf.
    my $file = "$data_dir/servers.dat";
    add_server_info($file,
		    $opts->{ip},
		    $opts->{mac},
		    $opts->{service},
		    $opts->{hostname},
		    $opts->{disk},
		    $opts->{kernel}
		    );

    # Now, it's time to build the root system for this node
    if (-e "$diskless/$service/$ip" or -d "$diskless/$service/$ip") {
	#die "$diskless/$service/$ip already exists\n";
    }
    
    System("mkdir", "$diskless/$service") unless -e "$diskless/$service";
    System("mkdir", "$diskless/$service/$ip") unless -e "$diskless/$service/$ip";

    # TODO: This should be more configurable
    my @dirs = qw(home dev proc tmp mnt mnt/.initd root
		  var var/lib var/empty var/lock var/log var/log/news 
		  var/run var/spool
		  usr opt mfs
		  );
    foreach my $dir (@dirs) {
	#run_dangerous("mkdir '$diskless/$service/$ip/$dir'");
	if (not -e "$diskless/$service/$ip/$dir") {
	    System('mkdir', "$diskless/$service/$ip/$dir");
	}
    }
    System('chmod', '777', "$diskless/$service/$ip/tmp");
    # Make console device
    # WARNING: Linux-centric
    unless  (-e "$diskless/$service/$ip/dev/console") {
	System('mknod', "$diskless/$service/$ip/dev/console", "c", "5", "1");
    }

    # Dirs that must be in the root file system to successfully boot.
    # TODO: This should be more configurable
    my @root_dirs = qw(etc bin sbin lib);
    # Sync the new root with the prototype
    foreach my $dir (@root_dirs) {
	System('rsync', '-avz',
	       "$prototypes/$service/$dir",
	       "$diskless/$service/$ip/");
    }
    my $host = $opts->{'hostname'};
    System("echo $host >$diskless/$service/$ip/etc/hostname");

    # WARNING: More Linux-centric stuff
    # PXELINUX will look for a file with the IP (in HEX) to determine the
    # boot flags. It it can't find it, It will strip off the right-most
    # letter of the address and repete until it finds the file or there
    # are no letters left. If it runs out of files, it will use a file
    # named 'default'

    # Convert IP to HEX
    use Socket;
    my $ip_hex = sprintf('%04X', unpack('N', inet_aton($ip)));

    # Create the pxelinux config for this IP
    System ("echo 'DEFAULT kernels/$kernel' >$diskless/$service/pxelinux.cfg/$ip_hex");
    System ("echo 'APPEND ip=dhcp root=/dev/nfs nfsroot=$nfs_server:$diskless/$service/$ip' >>$diskless/$service/pxelinux.cfg/$ip_hex");

    # Run init scripts
    if (-d "$diskless/$service/init") {
	if (opendir (INIT, "$diskless/$service/init")) {
	    my @scripts = grep { ! /^\./
				     && /\.(?:pl|sh)$/
				 } readdir INIT;
	    closedir INIT;

	    print "Running scripts in $diskless/$service/init/\n";
	    use Cwd;
	    my $cwd = cwd();
	    chdir ("$diskless/$service/init");
	    foreach my $script (sort @scripts) {
		if (-x "$diskless/$service/init/$script") {
		    System ("$diskless/$service/init/$script",
			    "$diskless/$service/$ip",
			    $service,
			    $host,
			    $ip,
			    $nfs_server,
			    "$prototypes/$service",
			    $disk
			    );
		}
	    }
	    chdir($cwd);
	}
    }

    if ($opts->{'local-scripts'} and -d "$diskless/$service/init/local") {
	if (opendir (INIT, "$diskless/$service/init/local")) {
	    my @scripts = grep { ! /^\./
				     && /\.(?:pl|sh)$/
				 } readdir INIT;
	    closedir INIT;

	    print "Running scripts in $diskless/$service/init/local/\n";
	    use Cwd;
	    my $cwd = cwd();
	    chdir ("$diskless/$service/init");
	    foreach my $script (sort @scripts) {
		if (-x "$diskless/$service/init/$script") {
		    System ("$diskless/$service/init/$script",
			    "$diskless/$service/$ip",
			    $service,
			    $host,
			    $ip,
			    $nfs_server,
			    "$prototypes/$service",
			    $disk);
		}
	    }
	    chdir($cwd);
	}
    }
}

sub install_diskrequired
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $req = check_bool($lcfg{$opts->{'service'}}{'disk required'});
    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'diskrequired',
				   'type' => 'boolean',
				   'description' => 'Is a local disk required')
		  );
    $rs->add_data([$req]) if defined $req; # $req should always be defined

    return $rs;
}

sub install_diskinfo
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'disk',
				   'type' => 'string',
				   'description' => 'Disk name')
		  );
    $rs->add_meta(VUser::Meta->new('name' => 'partinfo',
				   'type' => 'string',
				   'description' => 'Partion Info')
		  );
    $rs->add_meta(VUser::Meta->new('name' => 'fsinfo',
				   'type' => 'string',
				   'description' => 'Filesystem Info')
		  );
    $rs->add_meta(VUser::Meta->new('name' => 'mountinfo',
				   'type' => 'string',
				   'description' => 'Mount point Info')
		  );

    my %disks = get_disk_config($cfg, $opts);
    foreach my $disk (sort keys %disks) {
	$rs->add_data([$disk,
		       $disks{$disk}{'part'},
		       $disks{$disk}{'fs'},
		       $disks{$disk}{'mount'},
		       ]);
    }

    return $rs;
}

sub install_partinfo
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'partinfo',
				   'type' => 'string',
				   'description' => 'Partion Info')
		  );

    my %disks = get_disk_config($cfg, $opts);
    foreach my $disk (sort keys %disks) {
	$rs->add_data([$disks{$disk}{'part'}]);
    }

    return $rs;
}

sub install_fsinfo
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'fsinfo',
				   'type' => 'string',
				   'description' => 'Filesystem Info')
		  );

    my %disks = get_disk_config($cfg, $opts);
    foreach my $disk (sort keys %disks) {
	$rs->add_data([$disks{$disk}{'fs'}]);
    }

    return $rs;
}

sub install_mountinfo
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'mountinfo',
				   'type' => 'string',
				   'description' => 'Mount point Info')
		  );

    my %disks = get_disk_config($cfg, $opts);
    foreach my $disk (sort keys %disks) {
	$rs->add_data([$disks{$disk}{'mount'}]);
    }

    return $rs;
}

sub install_services
{
    my ($cfg, $opts, $action, $eh) = @_;
    
    my $dir = strip_ws($cfg->{$c_sec}{'prototype dir'});
    my @services = get_services($cfg);

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'service',
				   'type' => 'string',
				   'description' => 'Available services')
		  );

    foreach my $service (@services) {
	$rs->add_data([$service]);
    }

    return $rs;
}

sub install_tarball
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $service = $opts->{'service'};
    my $ip = $opts->{'ip'};

    my $base = strip_ws($lcfg{$service}{'tarball base url'});
    my $file = strip_ws($lcfg{$service}{'tarball file'});
    $base =~ s!/$!!; # Strip off any trailing /s.

    $base = eval qq("$base");
    $file = eval qq("$file");

    my $url = $base.'/'.$file;
    #eval $url; # Replace $service, $ip in URL

    my $rs = VUser::ResultSet->new();
    $rs->add_meta(VUser::Meta->new('name' => 'url',
				   'type' => 'string', # URL
				   'description' => 'Tarball URL')
		  );
    $rs->add_data([$url]);

    print "Tarball URL: $url\n" if $debug;

    return $rs;
}

sub update_dhcp
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $data_dir = strip_ws($cfg->{$c_sec}{'config dir'});
    my $file = "$data_dir/servers.dat";
    my %servers = read_server_info($file);

    use Text::Template;

    my @entries = ();
    my $diskless = strip_ws($cfg->{$c_sec}{'diskless dir'});

    # $server keys are: ip mac service hostname disk kernel
    foreach my $server (values %servers) {
	# use Data::Dumper; print Dumper $server;
	my $service = $server->{'service'};
	my $mac = $server->{'mac'};
	my $ip = $server->{'ip'};
	my $template = '';
	if (-e "$data_dir/$service-$mac.dhcp.tmpl") {
	    $template = "$service-$mac.dhcp.tmpl";
	} elsif (-e "$data_dir/$service-$ip.dhcp.tmpl") {
	    $template = "$service-$ip.dhcp.tmpl";
	} else {
	    $template = "$service.dhcp.tmpl";
	}

	my $tt = Text::Template->new (TYPE => 'FILE',
				      SOURCE => "$data_dir/$template");
	
	if (not $tt) {
	    warn "Can't build template ($template): $Text::Template::ERROR\n";
	    next;
	}

	my $text = $tt->fill_in(HASH => { server => $server,
					  diskless => $diskless
				      },
				DELIMITERS => ['<<', '>>']
				);
	if (not defined $text) {
	    warn "Can't fill in template ($template): $Text::Template::ERROR\n";
	    next;
	}
	push @entries, $text;
	$server->{'entry'} = $text;
    }

    my $main = "$data_dir/dhcp.tmpl";
    my $tt = Text::Template->new (TYPE => 'FILE', SOURCE => $main);
    if (not $tt) {
	die "Can't build template ($main): $Text::Template::ERROR\n";
    }

    my $dhcp = strip_ws($cfg->{$c_sec}{'dhcp.conf'});
    open (DHCP, ">$dhcp.tmp") or die "Can't write $dhcp.tmp: $!\n";
    my $warning = VUser::ExtLib::edit_warning();
    my $ok = $tt->fill_in(HASH => { entries => \@entries,
				    diskless => $diskless,
				    servers => \%servers,
				    warning => $warning
				},
			  OUTPUT => \*DHCP,
			  DELIMITERS => ['<<', '>>']
			  );
    close DHCP;

    if ($ok) {
	run_dangerous("rename '$dhcp.tmp', '$dhcp'");
	System (strip_ws($cfg->{$c_sec}{'dhcp restart'}));
    }
}

sub upgrade_diskless
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $service = $opts->{'service'};
    my $ip = $opts->{'ip'};

    if (not defined $ip and not defined $service) {
	die "At least one of 'ip' or 'service' must be used.\n";
    }

    my $data_dir = strip_ws($cfg->{$c_sec}{'config dir'});
    my $file = "$data_dir/servers.dat";

    my %servers = read_server_info($file);

    my %to_upgrade = ();
    if (defined $service) {
	foreach my $ip (keys %servers) {
	    if ($servers{$ip}{'service'} eq $service) {
		$to_upgrade{$ip} = $servers{$ip};
	    }
	}
    } else {
	%to_upgrade = %servers;
    }

    my @keys;
    if ($ip) {
	@keys = ($ip);
    } else {
	@keys = keys %to_upgrade;
    }

    foreach my $host (@keys) {
	my %inst_opts = ();
	$inst_opts{'service'} = $to_upgrade{$host}{'service'};
	$inst_opts{'ip'} = $to_upgrade{$host}{'ip'};
	$inst_opts{'mac'} = $to_upgrade{$host}{'mac'};
	$inst_opts{'hostname'} = $to_upgrade{$host}{'hostname'};
	$inst_opts{'disk'} = $to_upgrade{$host}{'disk'} if $to_upgrade{$host}{'disk'};
	$inst_opts{'kernel'} = $to_upgrade{$host}{'kernel'};
	$inst_opts{'local-scripts'} = $opts->{'local-scripts'};
	$eh->run_tasks('install', 'diskless', $cfg, %inst_opts);
    }
}

sub uninstall_diskless
{
    my ($cfg, $opts, $action, $eh) = @_;

    my $ip = $opts->{'ip'};

    my $diskless = strip_ws($cfg->{$c_sec}{'diskless dir'});

    my $data_dir = strip_ws($cfg->{$c_sec}{'config dir'});
    my $file = "$data_dir/servers.dat";

    my %servers = read_server_info($file);

     if (not exists $servers{$ip}) {
 	warn "Unknown server: $ip\n";
 	return;
     }

    my $service = $servers{$ip}{'service'};

    del_server_info($file, $ip);

    if (-d "$diskless/$service/$ip") {
	System('rm', '-r', "$diskless/$service/$ip");
    } else {
	warn "Unable to delete server directory: $diskless/$service/$ip doesn't exist\n";
    }
}

# Return a list of services names for use in various places
sub get_services
{
    my $cfg = shift;

    my @services = ();

    @services = sort keys %lcfg;

#     if (opendir (PROTOS, $dir)) {
# 	@services = grep { $_ !~ /^\./ && -d "$dir/$_" } readdir PROTOS;
# 	closedir PROTOS;
#     }

    return @services;
};

sub System
{
    print(join(" ", @_), "\n") if $verbose;

    return 0 if $debug;

    my $rc = system (@_);
    return $rc;
}

sub run_dangerous
{
    my $cmd = shift;
    print("$cmd\n") if $verbose;

    return 0 if $debug;

    my @rv = eval $cmd;
    die $@ if $@;
    return wantarray? @rv : $rv[0];
}

# Get server info used to write dhcp.conf from the given file.
# Format: | delimited
# Fields (In order):
#  IP
#  MAC
#  Service
#  Hostname
#  Kernel
sub read_server_info
{
    my $config_file = shift;

    my %servers = ();

    open (CONF, $config_file) or die "Can't read config file ($config_file): $!\n";

    while (my $line = <CONF>) {
	chomp $line;
	my $server = {};
	@{$server}{qw(ip mac service hostname disk kernel)} = split('\|', $line);
	$servers{$server->{ip}} = $server;
    }

    close CONF;
    return %servers;
}

sub write_server_info
{
    my $config_file = shift;
    my %servers = @_;

    open (CONF, ">$config_file.tmp") or die "Can't write config file ($config_file.tmp): $!\n";

    foreach my $server (values %servers) {
	print CONF join('|', map { defined $_? $_ : ''} @{$server}{qw(ip mac service hostname disk kernel)});
	print CONF "\n";
    }

    close CONF;

    unless ($debug) {
	rename "$config_file.tmp", $config_file
	    or die "Enable to rename to $config_file: $!\n";
    }
}

sub add_server_info
{
    my ($file, $ip, $mac, $service, $hostname, $disk, $kernel) = @_;

    $kernel = 'bzImage' if not defined $kernel or $kernel eq '';

    my %servers = read_server_info($file);
    $servers{$ip} = {ip => $ip,
		     mac => $mac,
		     service => $service,
		     hostname => $hostname,
		     disk => $disk,
		     kernel => $kernel};

    write_server_info($file, %servers);
}

sub del_server_info
{
    my ($file, $ip) = @_;
    my %servers = read_server_info($file);
    delete $servers{$ip};
    write_server_info($file, %servers);
}

sub get_disk_config
{
    my ($cfg, $opts) = @_;
    my %disks = ();
    foreach my $disk (sort grep { /^disk\d+/ } keys %{ $lcfg{$opts->{'service'}} }) {
	my ($part, $fs, $mount) = split ('\|', $lcfg{$opts->{'service'}}{$disk});

	$mount =~ s!/$!! if defined $mount and $mount ne '/';

	$disks{$disk} = {'part' => $part,
			 'fs' => $fs,
			 'mount' => $mount};
    }

    return %disks;
}

1;

=head1 NAME

VUser::Install - vuser extension to manage netboot installs

=head1 REQUIRES

Text::Template

=head1 DESCRIPTION

Handles installs of new systems from netboot installs.

=head2 Diskless

Configures the DHCP server to give the new box a static IP address
and sets up the root path and kernel options. B<Note:> VUser::Install
assumes that it is running on the DHCP server that the diskless box will
boot off of.

If you need to partition a disk for scratch space or other things on the
node, run the install-local script from the node.

=head2 Stand-alone 

Packages a root tarball that can be unpackaged in / to install/upgrade
a system. The included 'install-local' script can be run from the new
system with the diskless setup.

The assumption here, is that you have a system root installed somewhere
that can easily be packaged up after running a few scripts to change
things based on IP address or host name.

=head2 install-local

This is an interactive script which is designed to run on a new server
to make local changes to the server that cannot be done from the install
server, e.g. partitioning disks.

B<Note:> install-local currently tries to use F<sfdisk> to partition drives.
At some point, I hope to add F<disklabel> support for systems that use
that instead.

install-local requires that vsoapd is running on the installation server.

=head1 CONFIGURATION

 [Extension_Install]
 # Prototype roots are ${prototype dir}/$service
 prototype dir = /prototypes
 
 # Diskless roots are ${diskless dir}/$service/$ip
 diskless dir = /diskless
 
 # Directory to store server info used to write dhcp.conf
 # The server file is called 'servers.dat'
 data dir = /etc/vuser/
 
 # Directory for VUser::Install service configs.
 # Also, in this directory, templates for dhcp entries will be stored
 # dhcp templates for a new host are used in this order:
 # (Where $service, $mac and $ip are replaced with the values for this node)
 #  $service-$mac.dhcp.tmpl
 #  $service-$ip.dhcp.tmpl
 #  $service.dhcp.tmpl
 #
 # The main dhcp.conf is dhcp.tmpl
 config dir = /etc/vuser/install/
 
 # DHCP settings
 # dhcp config file
 dhcp.conf = /etc/dhcp/dhcp.conf
 
 # Command to run to restart dhcp
 dhcp restart = /etc/init.d/dhcp restart

=head1 diskless node data file

IP|MAC|service|hostname|disk|kernel

Example data file:

 192.168.1.100|00:0D:87:6A:4E:22|mail|mail1|hda|bzImage
 192.168.1.101|00:0D:87:6A:4E:24|mail|mail2|hda|bzImage
 192.168.2.100|00:0D:87:6A:4F:32|www|web1|sda|bzImage-smp
 192.168.3.147|00:0D:87:6A:3F:27|desktop|desk47||bzImage

=head1 dhcp Templates

VUser::Install uses Text::Template to generate these files. Variables
are inserted like so: C<E<lt>E<lt> $foo E<gt>E<gt>>.

See perldoc Text::Template for full details on the format of templates.
The short version is that you can include any perl code between
'E<lt>E<lt>' and 'E<gt>E<gt>'.
The return value (or the value of the I<$OUT> variable) will replace the
E<lt>E<lt> E<gt>E<gt> block.

=head2 Node Template

These templates are used for idividual nodes. The following variables are
available to the template:

=over 4

=item $diskless

The path to the diskless tree (From Extention_Install::diskless dir

=item %server

The server information. See entry in L<Global Template> for a list of keys.
B<Note:> The I<entry> key does not exist here since this template is what's
used to create that.

=back

Below is a sample template.

  host << $server{hostname} >> {
    hardware ethernet << $server{mac} >>;
    fixed-address << $server{ip} >>;
    filename "<< $server{service} >>/pxelinux.0";
    option root-path "<< $diskless >>/<< $server{service} >>/<< $server{ip} >>";
  }

=head2 Global Template

The global template gives you these variables:

=over 4

=item @entries

These are the already created templates for each node. For simple
networks, this is the easiest way of put the get the entries into the
config file.

 << join("\n", @entries); >>

=item $diskless

Path to diskless (from Extention_Install::diskless dir

=item %servers

If you have a more complex setup, you can use I<%servers> to do all
sorts of fun stuff. The keys of I<%servers> are the IP addresses of the
servers. The values are hash refs with the following keys:

=over 8

=item ip

The host's IP address

=item mac

The host's MAC address.

=item hostname

The host's hostname.

=item service

The service for this host.

=item disk

=item kernel

The prefered kernel for this host.

=item entry

The filled out template for this host. This matches the entry for the
host in I<@entries>.

=back

=item $warning

A simple warning message that says the file was generated by vuser and
the time it was created. See the example below.

 # This file was written by vuser on Mon Sep 12 16:44:22 2005
 # DO NOT EDIT THIS FILE. Manual changes to this file will be lost.

=back

Below is a sample template.

 # option definitions common to all supported networks...
 option domain-name "vuser.org";
 option domain-name-servers 192.168.100.1, 192.168.100.2;
 
 default-lease-time 600;
 max-lease-time 7200;
 
 # If this DHCP server is the official DHCP server for the local
 # network, the authoritative directive should be uncommented.
 authoritative;
 
 # Use this to send dhcp log messages to a different log file (you also
 # have to hack syslog.conf to complete the redirection).
 log-facility local7;
 
 ddns-update-style none;
 
 subnet 192.168.1.0 netmask 255.255.255.0 {
   option subnet-mask 255.255.255.0;
   option broadcast-address 192.168.1.255;
   option routers 192.168.1.1;
 
   range 192.168.1.125 192.168.1.127;
   next-server 192.168.1.120;

 # Server entries here 
 << join("\n", @entries); >>
 }

=head1 Service configuration file

B<Note:> I<service> below, is the name of the service.

 [service]
 # Is a local disk required. (yes|no)
 disk required = yes
 
 # Partition instructions.
 # The values are pipe delimited with these fields:
 #  partition instructions
 #  file system.
 #  mount point
 #
 # ex:
 #  disk1=,4096,S|swap
 #  disk2=;|reiserfs
 #
 # disk1 creates a 4GB partion at the start of the disk and will be
 # use for swap space.
 # disk2 will use the rest of the disk for reiserfs
 #
 # The partion instructions look like sfdisk commands
 # for a reason. (See sfdisk(8) dir details) Size units are MBs.
 #
 # If the file system is not specified, no file system will be created
 # on the partition.
 # Filesystem types are:
 # (Note: You must have the appropriate tools in your install 
 # setup or that filesystem will fail.)
 #  swap
 #  reiserfs
 #  ext2
 #  ext3
 #  jfs
 #  xfs
 #
 # The mount point is specified here so that it can be used as a reference
 # point for the setup scripts to initialize them. For example, if you are
 # installing an MTA (such as postfix) you may want to have a local disk
 # for the spool. That spool will need to have certain directories created
 # after the disk is partitioned and the filesystem is created. In the case
 # of postfix, the directory /var/spool/postfix would need to be created.
 # You may also want to use the local disk for scratch space for a virus
 # scanner or other things and so those directories will need to be created
 # as well.
 #
 # The mount point may be left empty for swap disks.
 disk1=,4096,S|swap|
 disk2=;|reiserfs|/var
 
 # Location to put tarballs of standalone systems for download
 tarball dir=/tarballs
 
 # Given $service and $ip, what is the base URL of the tarball
 #tarball base url=http://download.example.com/tarballs/$service/
 tarball base url=http://download.example.com/tarballs/
 
 # Given $service and $ip, what is the name of the tarball
 #tarball file=$service-default.tgz
 tarball file=$service-$ip.tgz

=head1 FILE LAYOUTS

=head2 Prototypes

 /prototypes

F</prototypes/service> is the root directory for the service prototype.

 /prototypes/service

=head2 Diskless

F</diskless> here is set by Extension_Install::diskless. I<service> and
I<ip> are the service and node IP address, respectively.

 /diskless
 /diskless/service/

The pxelinux bootstrap is pxelinux.0 and the config files for it are in
F<pxelinux.cfg>.

 /diskless/service/pxelinux.0
 /diskless/service/pxelinux.cfg/

The available kernels for this service are saved in:

 /diskless/service/kernels

F<init> holds scripts and various other files for configuring a node.

 /diskless/service/init

Each node's root directory is in:

 /diskless/service/ip

=head1 INIT SCRIPTS

Executable files in F</diskless/service/init> are called when a new service
is installed. These scripts B<must> be able to be run again even if the
service is already install. (This is primarily for upgrade functionality.)

VUser::Install will cd to F</diskless/service/init> before running any
init scripts. Each script will be passed the following command line
parameters:

=over 4

=item diskless root

This is the root directory for the new install (/diskless/service/ip).

=item service

The name of the service (from the --service option)

=item hostname

The hostname for this install (from --hostname)

=item ip address

This install's IP (from --ip)

=item NFS server

The NFS server this host will use. (From VUser-Install.ini service::nfs server)

=item Prototype Root

The path to the prototype root (from Extension_Install::prototype dir
and --service; e.g /prototypes/service)

=back

=head1 ADDING USERS

If you use F<install-local>, you will need to create users to allow
it to connect. These users will are user by vuser's SOAP daemon F<vsoapd>
to allow access.

1) Enable the I<ACL> extension in F<vuser.conf>:

 extensions = Install ACL
 
 [ACL]
 use internal auth=yes
 auth modules=SQLite
 # ALLOW or DENY
 acl default=ALLOW
 
 [ACL SQLite]
 file=/etc/vuser/install/acl.db

B<Note:> This setup requires that DBD::SQLite be installed on the master
server, i.e. the box running F<vsoapd>.

=head1 AUTHOR

Randy Smith <perlstalker@vuser.org>

=head1 LICENSE
 
 This file is part of vuser.
 
 vuser is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 vuser is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with vuser; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=cut
