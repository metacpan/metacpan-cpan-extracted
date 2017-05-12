package VM::EC2::Staging::Server;

# high level interface for transferring data, and managing data snapshots
# via a series of Staging VMs.

=head1 NAME

VM::EC2::Staging::Server - High level interface to EC2-based servers

=head1 SYNOPSIS

 use VM::EC2::Staging::Manager;

 # get a new staging manager
 my $ec2     = VM::EC2->new;
 my $staging = $ec2->staging_manager();                                         );

 # Fetch a server named 'my_server'. Create it if it does not already exist.
 my $server1 = $staging->get_server(-name              => 'my_server',
                                   -availability_zone  => 'us-east-1a',
                                   -architecture       => 'i386',
                                   -instance_type      => 't1.micro');

 # As above, but force a new server to be provisioned.
 my $server2 = $staging->provision_server(-name              => 'my_server',
                                          -availability_zone => 'us-east-1a',
                                          -architecture      => 'i386',
                                          -instance_type     => 't1.micro');

 # open up a terminal emulator in a separate window
 $server1->shell;
 
 # Run a command over ssh on the server. Standard in and out will be connected to
 # STDIN/OUT
 $server1->ssh('whoami');

 # run a command over ssh on the server, returning standard output as an array of lines or a
 # scalar string, similar to backticks (``)
 my @password_lines = $server1->scmd('cat /etc/passwd');

 # run a command on the server and read from it using a filehandle
 my $fh  = $server1->scmd_read('ls -R /usr/lib');
 while (<$fh>) { # do something }

 # run a command on the server and write to it using a filehandle
 my $fh  = $server1->scmd_write('sudo -s "cat >>/etc/fstab"');
 print $fh "/dev/sdf3 /mnt/demo ext3 0 2\n";
 close $fh;

 # provision and mount a 5 gig ext3 volume mounted on /opt, returning
 # VM::EC2::Staging::Volume object
 my $opt = $server1->provision_volume(-mtpt   => '/opt',
                                      -fstype => 'ext3',
                                      -size   => 5);

 # copy some data from the local filesystem onto the opt volume
 $server1->rsync("$ENV{HOME}/local_staging_volume/" => $opt);

 # same thing, but using server path name
 $server1->put("$ENV{HOME}/local_staging_volume/" => '/opt');

 # provision a volume attached to another server, and let the
 # system choose the filesystem and mount point for us
 my $backups = $server2->provision_volume(-name => 'Backup',
                                          -size => 10);

 # copy some data from opt to the new volume using rsync
 $server1->rsync($opt => "$backups/opt");
 
 # Do a block-level copy between disks - warning, the filesystem must be unmounted
 # before you attempt this.
 $backups->unmount;
 $server1->dd($opt => $backups);

=head1 DESCRIPTION

VM::EC2::Staging::Server objects are an extension of VM::EC2::Instance
to allow for higher-level access, including easy management of ssh
keys, remote copying of data from one server to another, and executing
of remote commands on the server from within Perl. See
L<VM::EC2::Staging::Manager> for an overview of staging servers and
volumes.

Note that proper functioning of this module is heavily dependent on
running on a host system that has access to ssh, rsync and terminal
emulator command-line tools. It will most likely fail when run on a
Windows host.

=cut

use strict;
use VM::EC2;
use Carp 'croak';
use Scalar::Util 'weaken';
use File::Spec;
use File::Path 'make_path','remove_tree';
use File::Basename 'dirname';
use POSIX 'setsid';
use overload
    '""'     => sub {my $self = shift;
 		     return $self->short_name;  # "inherited" from VM::EC2::Server
},
    fallback => 1;

use constant GB => 1_073_741_824;

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my ($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
    return if $func_name eq 'DESTROY';
    my $inst = eval {$self->instance} or croak "Can't locate object method \"$func_name\" via package \"$pack\"";;
    return $inst->$func_name(@_);
}

sub can {
    my $self = shift;
    my $method = shift;

    my $can  = $self->SUPER::can($method);
    return $can if $can;

    my $inst  = $self->instance or return;
    return $inst->can($method);
}

=head1 Staging Server Creation

Staging servers are usually created via a staging manager's
get_server() or provision_server() methods. See L<VM::EC2::Staging::Manager>.

There is also a new() class method that is intended to be used
internally in most cases. It is called like this:

=head2 $server = VM::EC2::Staging::Server->new(%args)

With the arguments:

 -keyfile    path to the ssh public/private keyfile for this instance
 -username   username for remote login on this instance
 -instance   VM::EC2::Instance to attach this server to
 -manager    VM::EC2::Staging::Manager in same zone as the instance

Note that you will have to launch a staging manager, start an
instance, and appropriate provision the SSH credentials for that
instance before invoking new() directly.

=cut

sub new {
    my $class = shift;
    my %args  = @_;
    $args{-keyfile}        or croak 'need -keyfile path';
    $args{-username}       or croak 'need -username';
    $args{-instance}       or croak 'need a -instance VM::EC2::Instance argument';
    $args{-manager}        or croak 'need a -manager argument';

    my $endpoint = $args{-manager}->ec2->endpoint;
    my $self = bless {
	endpoint => $endpoint,
	instance => $args{-instance},
	username => $args{-username},
	keyfile  => $args{-keyfile},
	name     => $args{-name} || undef,
    },ref $class || $class;
    return $self;
}

=head1 Information about the Server

VM::EC2::Staging::Server objects have all the methods of
VM::EC2::Instance, such as dnsName(), but add several new methods. The
new methods involving getting basic information about the server are
listed in this section.

=head2 $name = $server->name

This method returns the server's symbolic name, if any.

Servers can optionally be assigned a symbolic name at the time they
are created by the manager's get_server() or provision_server()
methods. The name persists as long as the underlying instance exists
(including in stopped state for EBS-backed instances). Calling
$manager->get_server() with this name returns the server object.

=cut

sub name     { shift->{name}     }

=head2 $ec2 = $server->ec2

Return the VM::EC2 object associated with the server.

=cut

sub ec2      { shift->manager->ec2    }

=head2 $ec2 = $server->endpoint

Return the endpoint URL associated with this server.

=cut

sub endpoint { shift->{endpoint}  }

=head2 $instance = $server->instance

Return the VM::EC2::Instance associated with this server.

=cut

sub instance { shift->{instance} }

=head2 $file = $server->keyfile

Return the full path to the SSH PEM keyfile used to log into this
server.

=cut

sub keyfile  { shift->{keyfile}  }

=head2 $user = $server->username

Return the name of the user (e.g. 'ubuntu') used to ssh into this
server.

=cut

sub username { 
    my $self = shift;
    my $d    = $self->{username};
    $self->{username} = shift if @_;
    $d;
}

=head2 $manager = $server->manager

Returns the VM::EC2::Staging::Manager that manages this server.

=cut

sub manager {
    my $self = shift;
    my $ep   = $self->endpoint;
    return VM::EC2::Staging::Manager->find_manager($ep);
}

=head1 Lifecycle Methods

The methods in this section manage the lifecycle of a server.

=head2 $flag = $server->ping

The ping() method returns true if the server is running and is
reachable via ssh. It is different from checking that the underlying
instance is "running" via a call to current_status, because it also
checks the usability of the ssh daemon, the provided ssh key and
username, firewall rules, and the network connectivity.

The result of ping is cached so that subsequent invocations return
quickly.

=cut

sub ping {
    my $self = shift;
    return unless $self->instance->status eq 'running';
    return 1 if $self->is_up;
    return unless $self->ssh('pwd >/dev/null 2>&1');
    $self->is_up(1);
    return 1;
}

=head2 $result = $server->start

Attempt to start a stopped server. The method will wait until a ping()
is successful, or until a timeout of 120 seconds. The result code will
be true if the server was successfully started and is reachable.

If you wish to start a set of servers without waiting for each one
individually, then you may call the underling instance's start()
method:

 $server->instance->start;

You may then wish to call the staging manager's wait_for_instances()
method to wait on all of the servers to start:

 $manager->wait_for_servers(@servers);

Also check out $manager->start_all_servers().

=cut


sub start {
    my $self = shift;
    return if $self->is_up;
    $self->manager->info("Starting staging server\n");
    eval {
	local $SIG{ALRM} = sub {die 'timeout'};
	alarm(VM::EC2::Staging::Manager::SERVER_STARTUP_TIMEOUT());
	$self->ec2->start_instances($self);
	$self->manager->wait_for_servers($self);
    };
    alarm(0);
    if ($@) {
	$self->manager->warn("could not start $self\n");
	return;
    }
    $self->is_up(1);
    1;
}

=head2 $result = $server->stop

Attempt to stop a running server. The method will wait until the
server has entered the "stopped" state before returning. It will
return a true result if the underlying instance stopped successfully.

If you wish to stop a set of servers without waiting for each one
individually, then you may call the underling instance's start()
method:

 $server->instance->stop;

You may then wish to call the staging manager's wait_for_instances()
method to wait on all of the servers to start:

 $status = $manager->wait_for_servers(@servers);

Also check out $manager->stop_all_servers().

=cut

sub stop {
    my $self = shift;
    return unless $self->instance->status eq 'running';
    $self->instance->stop;
    $self->is_up(0);
    my $status = $self->manager->wait_for_instances($self);
    return $status->{$self->instance} eq 'stopped';
}

=head2 $result = $server->terminate

Terminate a server and unregister it from the manager. This method
will stop and wait until the server is terminated.

If you wish to stop a set of servers without waiting for each one
individually, then you may call the underling instance's start()
method:

 $server->instance->terminate;

=cut

sub terminate {
    my $self = shift;
    $self->manager->_terminate_servers($self);
    $self->is_up(0);
    1;
}

=head1 Remote Shell Methods

The methods in this section allow you to run remote commands on the
staging server and interrogate the results. Since the staging manager
handles the creation of SSH keys internally, you do not need to worry
about finding the right public/private keypair.

=head2 $result = $server->ssh(@command)

The ssh() method invokes a command on the remote server. You may
provide the command line as a single string, or broken up by argument:

  $server->ssh('ls -lR /var/log');
  $server->ssh('ls','-lR','/var/log');

The output of the command will appear on STDOUT and STDERR of the perl
process. Input, if needed, will be read from STDIN. If no command is
provided, then an interactive ssh session will be started on the
remote server and the script will wait until you have logged out.

If the remote command was successful, the method result will be true.

=cut

sub ssh {
    my $self = shift;

    my @extra_args;
    if (ref($_[0]) && ref($_[0]) eq 'ARRAY') {
	my $extra      = shift;
	@extra_args = @$extra;
    }
    my @cmd   = @_;
    my $Instance = $self->instance or die "Remote instance not set up correctly";
    my $host     = $Instance->dnsName;
    system('ssh',$self->_ssh_args,@extra_args,$host,@cmd)==0;
}

=head2 $output = $server->scmd(@command)

This is similar to ssh(), except that the standard output of the
remote command will be captured and returned as the function result,
similar to the way backticks work in perl:

 my $output = $server->scmd('date');
 print "The localtime for the server is $output";

=cut

sub scmd {
    my $self = shift;
    my @extra_args;
    if (ref($_[0]) && ref($_[0]) eq 'ARRAY') {
	my $extra      = shift;
	@extra_args = @$extra;
    }
    my @cmd   = @_;

    my $Instance = $self->instance or die "Remote instance not set up correctly";
    my $host     = $Instance->dnsName;

    my $pid = open my $kid,"-|"; #this does a fork
    die "Couldn't fork: $!" unless defined $pid;
    if ($pid) {
	my @results;
	while (<$kid>) {
	    push @results,$_;
	}
	close $kid;
	if (wantarray) {
	    chomp(@results);
	    return @results;
	} else {
	    return join '',@results;
	}
    }

    # in child
    exec 'ssh',$self->_ssh_args,@extra_args,$host,@cmd;
}

=head2 $fh = $server->scmd_write(@command)

This method executes @command on the remote server, and returns a
filehandle that is attached to the standard input of the command. Here
is a slightly dangerous example that appends a line to /etc/passwd:

 my $fh = $server->scmd_write('sudo -s "cat >>/etc/passwd"');
 print $fh "whoopsie:x:119:130::/nonexistent:/bin/false\n";
 close $fh;

=cut

# return a filehandle that you can write to:
# e.g.
# my $fh = $server->scmd_write('cat >/tmp/foobar');
# print $fh, "testing\n";
# close $fh;
sub scmd_write {
    my $self = shift;
    return $self->_scmd_pipe('write',@_);
}

=head2 $fh = $server->scmd_read(@command)

This method executes @command on the remote server, and returns a
filehandle that is attached to the standard output of the command. Here
is an example of reading syslog:

 my $fh = $server->scmd_read('sudo cat /var/log/syslog');
 while (<$fh>) {
    next unless /kernel/;
    print $_;
 }
 close $fh;

=cut

# same thing, but you read from it:
# my $fh = $server->scmd_read('cat /tmp/foobar');
# while (<$fh>) {
#    print $_;
#}
sub scmd_read {
    my $self = shift;
    return $self->_scmd_pipe('read',@_);
}

=head2 $server->shell()

This method works in an X Windowing environment by launching a new
terminal window and running an interactive ssh session on the server
host. The terminal window is executed in a fork()ed session, so that
the rest of the script continues running.  If X Windows is not
running, then the method behaves the same as calling ssh() with no
arguments.

The terminal emulator to run is determined by calling the method get_xterm().

=cut

sub shell {
    my $self = shift;
    return $self->ssh() unless $ENV{DISPLAY};
    
    fork() && return;
    setsid(); # so that we are independent of parent signals
    my $host     = $self->instance->dnsName;
    my $ssh_args = $self->_ssh_escaped_args;
    my $emulator = $self->get_xterm;
    exec $emulator,'-e',"ssh $ssh_args $host" or die "$emulator: $!";
}

sub get_xterm {
    my $self = shift;
    return 'xterm';
}

sub _ssh_args {
    my $self = shift;
    return (
	'-o','CheckHostIP no',
	'-o','StrictHostKeyChecking no',
	'-o','UserKnownHostsFile /dev/null',
	'-o','LogLevel QUIET',
	'-i',$self->keyfile,
	'-l',$self->username,
	);
}

sub _ssh_escaped_args {
    my $self = shift;
    my @args = $self->_ssh_args;
    for (my $i=1;$i<@args;$i+=2) {
	$args[$i] = qq("$args[$i]") if $args[$i];
    }
    my $args = join ' ',@args;
    return $args;
}

sub _scmd_pipe {
    my $self = shift;
    my ($op,@cmd) = @_;
    my @extra_args;
    if (ref($cmd[0]) && ref($cmd[0]) eq 'ARRAY') {
	my $extra      = shift @cmd;
	@extra_args = @$extra;
    }
    my $operation = $op eq 'write' ? '|-' : '-|';

    my $host = $self->dnsName;
    my $pid = open(my $fh,$operation); # this does a fork
    defined $pid or croak "piped open failed: $!" ;
    return $fh if $pid;         # writing to the filehandle writes to an ssh session
    exec 'ssh',$self->_ssh_args,@extra_args,$host,@cmd;
    exit 0;
}

=head1 Volume Management Methods

The methods in this section allow you to create and manage volumes
attached to the server. These supplement the EC2 facilities for
creating and attaching EBS volumes with the ability to format the
volumes with a variety of filesystems, and mount them at a desired
location.

=head2 $volume = $server->provision_volume(%args)

Provision and mount a new volume. If successful, the volume is
returned as a VM::EC2::Staging::Volume object.

Arguments (default):

 -name         Symbolic name for the desired volume (autogenerated)
 -fstype       Filesystem type for desired volume (ext4)
 -size         Size for the desired volume in GB (1)
 -mtpt         Mountpoint for this volume (/mnt/Staging/$name)
 -mount        Alias for -mtpt
 -volume_id    ID of existing volume to attach & mount (none)
 -snapshot_id  ID of existing snapshot to use to create this volume (none)
 -reuse        Reuse an existing managed volume of same name (false)
 -label        Disk label to assign during formatting ($name)
 -uuid         UUID to assign during formatting (none)

None of the arguments are required, and reasonable defaults will be
chosen if they are missing.

The B<-name> argument specifies the symbolic name to be assigned to
the newly-created staging volume. The name allows the staging manager
to retrieve this volume at a later date if it is detached from the
server and returned to the available pool. If no name is provided,
then an arbitrary one will be autogenerated.

The B<-fstype> argument specifies the filesystem to be generated on
the volume, ext4 by default. The following filesystems are currently
supported: ext2, ext3, ext4, xfs, reiserfs, jfs, ntfs, nfs, vfat,
msdos. In addition, you can specify a filesystem of "raw", which means
to provision and attach the volume to the server, but not to format
it. This can be used to set up LVM and RAID devices. Note that if the
server does not currently have the package needed to manage the
desired filesystem, it will use "apt-get" to install it.

The B<-mtpt> and B<-mount> arguments (they are equivalent) specify the
mount point for the volume on the server filesystem. The default is
"/mnt/Staging/$name", where $name is the symbolic name provided by
-name or autogenerated. No checking is done on the sensibility of the
mount point, so try to avoid mounting disks over essential parts of
the system.

B<-volume_id> and B<-snapshot_id> instruct the method to construct the
staging volume from an existing EBS volume or snapshot. -volume_id is
an EBS volume ID. If provided, the volume must be located in the
server's availability zone and be in the "available"
state. -snapshot_id is an EBS snapshot ID in the server's region. In
no case will provision_volume() attempt to reformat the resulting
volume, even if the -fstype argument is provided. However, in the case
of a volume created from a snapshot, you may specify a -size argument
larger than the snapshot and the filesystem will be dynamically
resized to fill the requested space. This currently only works with
ext2, ext3 and ext4 volumes, and cannot be used to make filesystems
smaller.

If the B<-reuse> argument is true, and a symbolic name is provided in
B<-name>, then the method will look for an available staging volume of
the same name and mount this at the specified location. If no suitable
staging volume is found, then the method will look for a snapshot
created earlier from a staging volume of the same name. If neither a
suitable volume nor a snapshot is available, then a new volume is
provisioned. This is intended to support the following use case of
synchronizing a filesystem somewhere to an EBS snapshot:

 my $server = $staging_manager->get_server('my_server');
 my $volume = $server->provision_volume(-name=>'backup_1',
                                        -reuse  => 1,
                                        -fstype => 'ext3',
                                        -size   => 10);
 $volume->put('fred@gw.harvard.edu:my_music');
 $volume->create_snapshot('music_backups');
 $volume->delete;

The B<-label> and B<-uuid> arguments are used to set the volume label
and UUID during formatting of new filesystems. The default behavior is
to create no label and to allow the server to choose an arbitrary
UUID.

=cut

sub provision_volume {
    my $self = shift;
    my %args = @_;

    my $name   = $args{-name} ||= VM::EC2::Staging::Manager->new_volume_name;
    my $size   = $args{-size};
    my $volid  = $args{-volume_id};
    my $snapid = $args{-snapshot_id};
    my $reuse  = $args{-reuse};
    my $label  = $args{-label};
    my $uuid   = $args{-uuid};

    $self->manager->find_volume_by_name($args{-name}) && 
	croak "There is already a volume named $args{-name} in this region";

    if ($volid || $snapid) {
	$name  ||= $volid || $snapid;
	$size  ||= -1;
    } else {
	$name        =~ /^[a-zA-Z0-9_.,&-]+$/
	    or croak "Volume name must contain only characters [a-zA-Z0-9_.,&-]; you asked for '$name'";
    }

    my $ec2      = $self->ec2;
    my $fstype   = $args{-fstype} || 'ext4';
    my $mtpt     = $fstype eq 'raw' ? 'none' : ($args{-mount}  || $args{-mtpt} || $self->default_mtpt($name));
    my $username = $self->username;
    
    $size = int($size) < $size ? int($size)+1 : $size;  # dirty ceil() function

    my $instance = $self->instance;
    my $zone     = $instance->placement;
    my ($vol,$needs_mkfs,$needs_resize) = $self->_create_volume($name,$size,$zone,$volid,$snapid,$reuse);

    $vol->add_tag(Name        => $self->volume_description($name)) unless exists $vol->tags->{Name};
    $vol->add_tags(StagingName   => $name,
		   StagingMtPt   => $mtpt,
		   StagingFsType => $fstype,
		   StagingRole   => 'StagingVolume');
    
    my ($ebs_device,$mt_device) = eval{$self->unused_block_device()}           
                      or die "Couldn't find suitable device to attach this volume to";
    my $s = $instance->attach_volume($vol=>$ebs_device)  
	              or die "Couldn't attach $vol to $instance via $ebs_device: ",$ec2->error_str;
    $ec2->wait_for_attachments($s)                   or croak "Couldn't attach $vol to $instance via $ebs_device";
    $s->current_status eq 'attached'                 or croak "Couldn't attach $vol to $instance via $ebs_device";

    if ($needs_resize) {
	$self->scmd("sudo blkid -p $mt_device") =~ /"ext\d"/   or croak "Sorry, but can only resize ext volumes ";
	$self->info("Checking filesystem...\n");
	$self->ssh("sudo /sbin/e2fsck -fy $mt_device")          or croak "Couldn't check $mt_device";
	$self->info("Resizing previously-used volume to $size GB...\n");
	$self->ssh("sudo /sbin/resize2fs $mt_device ${size}G") or croak "Couldn't resize $mt_device";
    } elsif ($needs_mkfs && $fstype ne 'raw') {
	local $_ = $fstype;
	my $label_cmd =!$label     ? ''
                       :/^ext/     ? "-L '$label'"
                       :/^xfs/     ? "-L '$label'"
                       :/^reiser/  ? "-l '$label'"
                       :/^jfs/     ? "-L '$label'"
                       :/^vfat/    ? "-n '$label'"
                       :/^msdos/   ? "-n '$label'"
                       :/^ntfs/    ? "-L '$label'"
		       :/^hfs/     ? "-v '$label'"
                       :'';
	my $uu = $uuid ? ( /^ext/     ? "-U $uuid"
			  :/^xfs/     ? ''
			  :/^reiser/  ? "-u $uuid"
			  :/^jfs/     ? ''
			  :/^vfat/    ? ''
			  :/^msdos/   ? ''
			  :/^ntfs/    ? "-U $uuid"
			  :/^hfs/     ? ''
			  :'')
	          : '';
	my $quiet = $self->manager->verbosity < 3 && !/msdos|vfat|hfs/ ? "-q" : '';

	my $apt_packages = $self->_mkfs_packages();
	if (my $package = $apt_packages->{$fstype}) {
	    $self->info("checking for /sbin/mkfs.$fstype\n");
	    $self->ssh("if [ ! -e /sbin/mkfs.$fstype ]; then sudo apt-get -q update; sudo apt-get -q -y install $package; fi");
	}
	$self->info("Making $fstype filesystem on staging volume...\n");
	$self->ssh("sudo /sbin/mkfs.$fstype $quiet $label_cmd $uu $mt_device") or croak "Couldn't make filesystem on $mt_device";

	if ($uuid && !$uu) {
	    $self->info("Setting the UUID for the volume\n");
	    $self->ssh("sudo xfs_admin -U $uuid $mt_device") if $fstype =~ /^xfs/;
	    $self->ssh("sudo jfs_tune -U $uuid $mt_device")  if $fstype =~ /^jfs/;
	    # as far as I know you cannot set a uuid for FAT and VFAT volumes
	}
    }

    my $volobj = $self->manager->volume_class->new({
	-volume    => $vol,
	-mtdev     => $mt_device,
	-mtpt      => $mtpt,
	-server    => $self,
	-name      => $name});

    # make sure the guy is mountable before trying it
    if ($volid || $snapid) {
	my $isfs = $self->scmd("sudo blkid -p $mt_device") =~ /filesystem/i;
	$self->mount_volume($volobj) if $isfs;
	$volobj->mtpt('none')    unless $isfs;
	$fstype = $volobj->get_fstype;
	$volobj->fstype($fstype);
    } else {
	$volobj->fstype($fstype);
	$self->mount_volume($volobj);
    }

    $self->manager->register_volume($volobj);
    return $volobj;
}

=head2 $volume = $server->add_volume(%args)

This is the same as provision_volume().

=cut

sub add_volume {
    shift->provision_volume(@_)
}

=head2 @volumes = $server->volumes()

Return a list of all the staging volumes attached to this
server. Unmanaged volumes, such as the root volume, are not included
in the list.

=cut

sub volumes {
    my $self   = shift;
    $self->refresh;
    my @volIds  = map {$_->volumeId} $self->blockDeviceMapping;
    my @volumes = map {$self->manager->find_volume_by_volid($_)} @volIds;
    return grep {defined $_} @volumes;
}

=head2 $server->unmount_volume($volume)

Unmount the volume $volume. The volume will remain attached to the
server. This method will die with a fatal error if the operation
fails.

See VM::EC2::Staging::Volume->detach() for the recommended way to
unmount and detach the volume.

=cut

sub unmount_volume {
    my $self = shift;
    my $vol  = shift;
    my $mtpt = $vol->mtpt;
    return unless $mtpt;
    return if $mtpt eq 'none';
    return unless $vol->mounted;
    $self->info("unmounting $vol...\n");
    $self->ssh('sudo','umount',$mtpt) or croak "Could not umount $mtpt";
    $vol->delete_tags('StagingMtPt');
    $vol->mounted(0);
}

=head2 $server->detach_volume($volume)

Unmount and detach the volume from the server, waiting until EC2
reports that the detachment completed. A fatal error will occur if the
operation fails.

=cut

sub detach_volume {
    my $self = shift;
    my $vol  = shift;
    return unless $vol->server;
    return unless $vol->current_status eq 'in-use';
    $vol->server eq $self or croak "Volume is not attached to this server";
    my $status = $vol->detach();
    $self->ec2->wait_for_attachments($status);
    $vol->refresh;
}

=head2 $server->mount_volume($volume [,$mountpt])

Mount the volume $volume using the mount information recorded inside
the VM::EC2::Staging::Volume object (returned by its mtpt() and
mtdev() methods). If the volume has not previously been mounted on
this server, then it will be attached to the server and a new
mountpoint will be allocated automatically. You can change the mount
point by specifying it explicitly in the second argument.

Here is the recommended way to detach a staging volume from one server
and attach it to another:

 $server1->detach_volume($volume);
 $server2->mount_volume($volume);

This method will die in case of error.

=cut

sub mount_volume {
    my $self = shift;
    my ($vol,$mtpt)  = @_;
    $vol->mounted and return;
    if ($vol->mtdev && $vol->mtpt) {
	return if $vol->mtpt eq 'none';
	$self->_mount($vol->mtdev,$vol->mtpt);
    } else {
	$self->_find_or_create_mount($vol,$mtpt);
    }
    $vol->add_tags(StagingMtPt   => $vol->mtpt);
    $vol->server($self);
    $vol->mounted(1);
}

=head2 $server->remount_volume($volume)

This is similar to mount_volume(), except that it will fail with a
fatal error if the volume was not previously mounted on this server.
This is to be used when temporarily unmounting and remounting a volume
on the same server:

 $server->unmount_volume($volume);
 # do some work on the volume
 $server->remount_volume($volume)

=cut

sub remount_volume {
    my $self = shift;
    my $vol  = shift;
    my $mtpt = $vol->mtpt;
    return if $mtpt eq 'none';
    my $device = $vol->mtdev;
    my $server = $vol->server;
    ($mtpt && $device && $server eq $self)
	or croak "attempt to remount a volume that was not previously mounted on this server";
    $self->info("remounting $vol\n");
    $self->ssh('sudo','mount',$device,$mtpt) or croak "Could not remount $mtpt";
    $vol->mounted(1);
}

=head2 $server->delete_volume($volume)

Unmount, detach, and then delete the indicated volume entirely.

=cut

sub delete_volume {
   my $self = shift;
   my $vol  = shift;
   my $ec2 = $self->ec2;
   $self->manager->unregister_volume($vol);
   $self->unmount_volume($vol);
   # call underlying EBS function to avoid the volume trying to spin up the
   # server just to unmount itself.
   $ec2->wait_for_attachments( $vol->ebs->detach() ); 
   $self->info("deleting $vol...\n");
   $ec2->delete_volume($vol->volumeId);
   $vol->mounted(0);
}

=head2 $snap = $server->create_snapshot($volume,$description)

Unmount the volume, snapshot it using the provided description, and
then remount the volume. If successful, returns the snapshot.

The snapshot is tagged with the identifying information needed to
associate the snapshot with the staging volume. This information then
used when creating new volumes from the snapshot with
$server->provision_volume(-reuse=>1).

=cut

sub create_snapshot {
    my $self = shift;
    my ($vol,$description) = @_;

    my $was_mounted = $vol->mounted;
    $self->unmount_volume($vol) if $was_mounted;

    $self->info("snapshotting $vol\n");
    my $volume = $vol->ebs;
    my $snap = $volume->create_snapshot($description) or croak "Could not snapshot $vol: ",$vol->ec2->error_str;

    $snap->add_tag(StagingName => $vol->name                  );
    $snap->add_tag(Name        => "Staging volume ".$vol->name);

    $self->remount_volume($vol) if $was_mounted;
    return $snap;
}

sub _create_volume {
    my $self = shift;
    my ($name,$size,$zone,$volid,$snapid,$reuse_staging_volume) = @_;
    my $ec2 = $self->ec2;

    my (@vols,@snaps);

    if ($volid) {
	my $vol = $ec2->describe_volumes($volid) or croak "Unknown volume $volid";
	croak "$volid is not in server availability zone $zone."
	    unless $vol->availabilityZone eq $zone;
	croak "$vol is unavailable for use, status ",$vol->status
	    unless $vol->status eq 'available';
	@vols = $vol;
    }

    elsif ($snapid) {
	my $snap = $ec2->describe_snapshots($snapid) or croak "Unknown snapshot $snapid";
	@snaps   = $snap;
    }

    elsif ($reuse_staging_volume) {
	@vols = sort {$b->createTime cmp $a->createTime} $ec2->describe_volumes({status              => 'available',
										 'availability-zone' => $zone,
										 'tag:StagingName'   => $name});
	@snaps = sort {$b->startTime cmp $a->startTime} $ec2->describe_snapshots(-owner  => $ec2->account_id,
										 -filter => {'tag:StagingName' => $name})
	    unless @vols;
    }

    my ($vol,$needs_mkfs,$needs_resize);

    if (@vols) {
	$vol = $vols[0];
	$size   = $vol->size unless $size > 0;
	$self->info("Using volume $vol...\n");
	$vol->size == $size or croak "Cannot (yet) resize live volumes. Please snapshot first and restore from the snapshot"
    }

    elsif (@snaps) {
	my $snap = $snaps[0];
	$size    = $snap->volumeSize unless $size > 0;
	$self->info("Using snapshot $snap...\n");
	$snap->volumeSize <= $size or croak "Cannot (yet) shrink volumes derived from snapshots. Please choose a size >= snapshot size";
	$vol = $snap->create_volume(-availability_zone=>$zone,
				    -size             => $size);
	$needs_resize = $snap->volumeSize < $size;
    }

    else {
	unless ($size > 0) {
	    $self->info("No size provided. Defaulting to 10 GB.\n");
	    $size = 10;
	}
	$self->info("Provisioning a new $size GB volume...\n");
	$vol = $ec2->create_volume(-availability_zone=>$zone,
				   -size             =>$size);
	$needs_mkfs++;
    }

    return unless $vol;

    return ($vol,$needs_mkfs,$needs_resize);
}

sub _mount {
    my $self = shift;
    my ($mt_device,$mtpt) = @_;
    $self->info("Mounting staging volume at $mt_device on $mtpt.\n");
    $self->ssh("sudo mkdir -p $mtpt; sudo mount $mt_device $mtpt") or croak "mount failed";
}

sub _mkfs_packages {
    my $self = shift;
    return {
	xfs       => 'xfsprogs',
	reiserfs  => 'reiserfsprogs',
	jfs       => 'jfsutils',
	ntfs      => 'ntfsprogs',
	hfs       => 'hfsprogs',
    }
}

sub _find_or_create_mount {
    my $self = shift;
    my ($vol,$mtpt)  = @_;

    $vol->refresh;
    my ($ebs_device,$mt_device,$old_mtpt);
    
    # handle the case of the volme already being attached
    if (my $attachment = $vol->attachment) {

	if ($attachment->status eq 'attached') {

	    $attachment->instanceId eq $self->instanceId or
		die "$vol is attached to wrong server";
	    ($mt_device,$old_mtpt) = $self->_find_mount($attachment->device);
	    $mtpt ||= $old_mtpt || $vol->tags->{StagingMtPt} || $self->default_mtpt($vol);
	    $self->_mount($mt_device,$mtpt);

	    #oops, device is in a semi-attached state. Let it settle then reattach.
	} else {
	    $self->info("$vol was recently used. Waiting for attachment state to settle...\n");
	    $self->ec2->wait_for_attachments($attachment);
	}
    }

    unless ($mt_device && $mtpt) {
	($ebs_device,$mt_device) = $self->unused_block_device;
	$self->info("attaching $vol to $self via $ebs_device\n");
	my $s = $vol->attach($self->instanceId,$ebs_device) 
	    or croak "Can't attach $vol to $self: ",$self->ec2->error_str;
	$self->ec2->wait_for_attachments($s);
	$s->current_status eq 'attached' or croak "Can't attach $vol to $self";
	$mtpt ||= $vol->tags->{StagingMtPt} || $self->default_mtpt($vol);
	$self->_mount($mt_device,$mtpt);
    }

    $vol->mtpt($mtpt);
    $vol->mtdev($mt_device);
}

# this gets called to find a device that is already mounted
sub _find_mount {
    my $self       = shift;
    my $device     = shift;
    my @mounts = $self->scmd('cat /proc/mounts');
    my (%mounts,$xvd);
    for my $m (@mounts) {
	my ($dev,$mtpt) = split /\s+/,$m;
	$xvd++ if $dev =~ m!^/dev/xvd!;
	$mounts{$dev} = $mtpt;
    }
    $device =~ s!^/dev/sd!/dev/xvd! if $xvd;
    return ($device,$mounts{$device});
}

=head1 Data Copying Methods

The methods in this section are used to copy data from one staging server to another, and to
copy data from a local file system to a staging server.

=head2 $result = $server->rsync($src1,$src2,$src3...,$dest)

This method is a passthrough to VM::EC2::Staging::Manager->rsync(),
and provides efficient file-level synchronization (rsync) file-level
copying between one or more source locations and a destination
location via an ssh tunnel. Copying among arbitrary combinations of
local and remote filesystems is supported, with the caveat that the
remote filesystems must be contained on volumes and servers managed by
this module (see below for a workaround).

You may provide two or more directory paths. The last path will be
treated as the copy destination, and the source paths will be treated
as copy sources. All copying is performed using the -avz options, which
activates recursive directory copying in which ownership, modification
times and permissions are preserved, and compresses the data to reduce
network usage. 

Source paths can be formatted in one of several ways:

 /absolute/path 
      Copy the contents of the directory /absolute/path located on the
      local machine to the destination. This will create a
      subdirectory named "path" on the destination disk. Add a slash
      to the end of the path (i.e. "/absolute/path/") in order to
      avoid creating this subdirectory on the destination disk.

 ./relative/path
      Relative paths work the way you expect, and depend on the current
      working directory. The terminating slash rule applies.

 $staging_server:/absolute/path
     Pass a staging server object and absolute path to copy the contents
     of this path to the destination disk. Because of string interpolation
     you can include server objects in quotes: "$my_server:/opt"

 $staging_server:relative/path
     This form will copy data from paths relative to the remote user's home
     directory on the staging server. Typically not very useful, but supported.

 $staging_volume
      Pass a VM::EC2::Staging::Volume to copy the contents of the
      volume to the destination disk starting at the root of the
      volume. Note that you do *not* need to have any knowledge of the
      mount point for this volume in order to copy its contents.

 $staging_volume:/absolute/path
      Copy a subdirectory of a staging volume to the destination disk.
      The root of the volume is its top level, regardless of where it
      is mounted on the staging server.  Because of string
      interpolation magic, you can enclose staging volume object names
      in quotes in order to construct the path, as in
      "$picture_volume:/family/vacations/". As in local paths, a
      terminating slash indicates that the contents of the last
      directory in the path are to be copied without creating the
      enclosing directory on the desetination. Note that you do *not*
      need to have any knowledge of the mount point for this volume in
      order to copy its contents.

 $staging_volume:absolute/path
 $staging_volume/absolute/path
     These are alternatives to the previous syntax, and all have the
     same effect as $staging_volume:relative/path. There is no

The same syntax is supported for destination paths, except that it
makes no difference whether a path has a trailing slash or not.

Note that neither the source nor destination paths need to reside on
this server.

See VM::EC2::Staging::Manager->rsync() for examples and more details.

=cut

sub rsync {
    shift->manager->rsync(@_);
}

=head2 $server->dd($source_vol=>$dest_vol)

This method is a passthrough to VM::EC2::Staging::Manager->dd(), and
performs block-level copying of the contents of $source_vol to
$dest_vol by using dd over an SSH tunnel, where both source and
destination volumes are VM::EC2::Staging::Volume objects. The volumes
must be attached to a server but not mounted. Everything in the
volume, including its partition table, is copied, allowing you to make
an exact image of a disk.

The volumes do B<not> actually need to reside on this server, but can
be attached to any staging server in the zone.

=cut

sub dd {
    shift->manager->dd(@_);
}

=head2 $server->put($source1,$source2,$source3,...,$dest)

Use rsync to copy the indicated source directories into the
destination path indicated by $dest. The destination is either a path
on the server machine, or a staging volume object mounted on the
server (string interpolation is accepted). The sources can be local
paths on the machine the perl script is running on, or any of the
formats described for rsync().

Examples:

 $server1->put("$ENV{HOME}/my_pictures"     => '/var/media');
 $server1->put("$ENV{HOME}/my_pictures","$ENV{HOME}/my_audio" => '/var/media');
 $server1->put("$ENV{HOME}/my_pictures"     => "$backup_volume/home_media");
 $server1->put("fred@gw.harvard.edu:media/" => "$backup_volume/home_media");

=cut

# last argument is implied on this server
sub put {
    my $self  = shift;
    my @paths = @_;
    @paths >= 2 or croak "usage: VM::EC2::Staging::Server->put(\$source1,\$source2...,\$dest)";
    $paths[-1] =~ m/:/ && croak "invalid pathname; must not contain a hostname";
    $paths[-1] = "$self:$paths[-1]" unless $paths[-1] =~ /^vol-[0-9a-f]{8}/;
    $self->manager->rsync(@paths);
}

=head2 $server->get($source1,$source2,$source3,...,$dest)

Use rsync to copy the indicated source directories into the
destination path indicated by $dest. The source directories are either
paths on the server, or staging volume(s) mounted on the server
(string interpolation to indicate subdirectories on the staging volume
also works). The destination can be any of the path formats described
for rsync(), including unmanaged hosts that accept ssh login.

Examples:

 $server1->get('/var/media' =>"$ENV{HOME}/my_pictures");
 $server1->get('/var/media','/usr/bin' => "$ENV{HOME}/test");
 $server1->get("$backup_volume/home_media" => "$ENV{HOME}/my_pictures");
 $server1->get("$backup_volume/home_media" => "fred@gw.harvard.edu:media/");

=cut

# source arguments are implied on this server+
sub get {
    my $self  = shift;
    my @paths = @_;
    @paths >= 2 or croak "usage: VM::EC2::Staging::Server->get(\$source1,\$source2...,\$dest)";
    my $dest = pop @paths;
    foreach (@paths) {
	m/:/ && croak "invalid pathname; must not contain a hostname";
	$_ = "$self:$_" unless /^vol-[0-9a-f]{8}/;
    }
    $self->manager->rsync(@paths,$dest);
}


sub _rsync_put {
    my $self   = shift;
    my $rsync_args = shift;
    my @source     = @_;
    my $dest       = pop @source;

    # resolve symbolic name of $dest
    $dest            =~ s/^.+://;  # get rid of hostname, if it is there
    my $host         = $self->instance->dnsName;
    my $ssh_args     = $self->_ssh_escaped_args;
    $rsync_args    ||= $self->manager->_rsync_args;
    $self->info("Beginning rsync @source $host:$dest ...\n");

    my $dots = $self->manager->_dots_cmd;
    my $status = system("rsync $rsync_args -e'ssh $ssh_args' --rsync-path='sudo rsync' @source $host:$dest $dots") == 0;
    $self->info("...rsync done\n");
    return $status;
}

sub _rsync_get {
    my $self = shift;
    my $rsync_args = shift;
    my @source     = @_;
    my $dest       = pop @source;

    # resolve symbolic names of src
    my $host     = $self->instance->dnsName;
    foreach (@source) {
	(my $path = $_) =~ s/^.+://;  # get rid of host part, if it is there
	$_ = "$host:$path";
    }
    my $ssh_args     = $self->_ssh_escaped_args;
    $rsync_args    ||= $self->manager->_rsync_args;
    
    $self->info("Beginning rsync @source $host:$dest ...\n");
    my $dots = $self->manager->_dots_cmd;
    my $status = system("rsync $rsync_args -e'ssh $ssh_args' --rsync-path='sudo rsync' @source $dest $dots")==0;
    $self->info("...rsync done\n");
    return $status;
}

=head1 Internal Methods

This section documents internal methods. They are not intended for use
by end-user scripts but may be useful to know about during
subclassing. There are also additional undocumented methods that begin
with a "_" character which you can explore in the source code.

=head2 $description = $server->volume_description($vol)

This method is called to get the value of the Name tag assigned to new
staging volume objects. The current value is "Staging volume for $name
created by VM::EC2::Staging::Server."

You will see these names associated with EBS volumes in the AWS console.

=cut

sub volume_description {
    my $self = shift;
    my $vol  = shift;
    my $name = ref $vol ? $vol->name : $vol;
    return "Staging volume for $name created by ".__PACKAGE__;
}

=head2 ($ebs_device,$local_device) = $server->unused_block_device([$major_start])

This method returns an unused block device path. It is invoked when
provisioning and mounting new volumes. The behavior is to take the
following search path:

 /dev/sdf1
 /dev/sdf2
 ...
 /dev/sdf15
 /dev/sdfg1
 ...
 /dev/sdp15

You can modify the search path slightly by providing a single
character major start. For example, to leave all the sdf's free and to
start the search at /dev/sdg:

 ($ebs_device,$local_device) = $server->unused_block_device('g');

The result is a two element list consisting of the unused device name
from the perspective of EC2 and the server respectively. The issue
here is that on some recent Linux kernels, the EC2 device /dev/sdf1 is
known to the server as /dev/xvdf1. This module understands that
complication and uses the EC2 block device name when managing EBS
volumes, and the kernel block device name when communicating with the
server.

=cut

# find an unused block device
sub unused_block_device {
    my $self        = shift;
    my $major_start = shift || 'f';

    my @devices = $self->scmd('ls -1 /dev/sd?* /dev/xvd?* 2>/dev/null');
    return unless @devices;
    my %used = map {$_ => 1} @devices;
    
    my $base =   $used{'/dev/sda1'}   ? "/dev/sd"
               : $used{'/dev/xvda1'}  ? "/dev/xvd"
               : '';
    die "Device list contains neither /dev/sda1 nor /dev/xvda1; don't know how blocks are named on this system"
	unless $base;

    my $ebs = '/dev/sd';
    for my $major ($major_start..'p') {
        for my $minor (1..15) {
            my $local_device = "${base}${major}${minor}";
            next if $used{$local_device}++;
            my $ebs_device = "/dev/sd${major}${minor}";
            return ($ebs_device,$local_device);
        }
    }
    return;
}

=head2 $flag = $server->has_key($keyname)

Returns true if the server has a copy of the private key corresponding
to $keyname. This is used by the rsync() method to enable server to
server data transfers.

=cut

sub has_key {
    my $self    = shift;
    my $keyname = shift;
    $self->{_has_key}{$keyname} = shift if @_;
    return $self->{_has_key}{$keyname} if exists $self->{_has_key}{$keyname};
    return $self->{_has_key}{$keyname} = $self->scmd("if [ -e $keyname ]; then echo 1; fi");
}

=head2 $flag = $server->accepts_key($keyname)

Returns true if the server has a copy of the public key part of
$keyname in its .ssh/authorized_keys file. This is used by the rsync()
method to enable server to server data transfers.

=cut

sub accepts_key {
    my $self = shift;
    my $keyname = shift;
    $self->{_accepts_key}{$keyname} = shift if @_;
    return $self->{_accepts_key}{$keyname};
}

=head2 $up = $server->is_up([$new_value])

Get/set the internal is_up() flag, which indicates whether the server
is up and running. This is used to cache the results of the ping() method.

=cut

sub is_up {
    my $self = shift;
    my $d    = $self->{_is_up};
    $self->{_is_up} = shift if @_;
    $d;
}

=head2 $path = $server->default_mtpt($volume)

Given a staging volume, return its default mount point on the server
('/mnt/Staging/'.$volume->name). Can also pass a string corresponding
to the volume's name.

=cut

sub default_mtpt {
    my $self = shift;
    my $vol  = shift;
    my $name = ref $vol ? $vol->name : $vol;
    return "/mnt/Staging/$name";
}

=head2 $server->info(@message)

Log a message to standard output, respecting the staging manager's
verbosity() setting.

=cut

sub info {
    my $self = shift;
    $self->manager->info(@_);
}

=head1 Subclassing

For reasons having to do with the order in which objects are created,
VM::EC2::Staging::Server is a wrapper around VM::EC2::Instance rather
than a subclass of it. To access the VM::EC2::Instance object, you
call the server object's instance() method. In practice this means
that to invoke the underlying instance's method for, say, start() you
will need to do this:

  $server->instance->start();

rather than this:

  $server->SUPER::start();

You may subclass VM::EC2::Staging::Server in the usual way.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Instance>
L<VM::EC2::Volume>
L<VM::EC2::Snapshot>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

1;

