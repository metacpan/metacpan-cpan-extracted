package VM::EC2::Staging::Manager;

=head1 NAME

VM::EC2::Staging::Manager - Automate VMs and volumes for moving data in and out of cloud.

=head1 SYNOPSIS

 use VM::EC2::Staging::Manager;

 my $ec2     = VM::EC2->new(-region=>'us-east-1');
 my $staging = $ec2->staging_manager(-on_exit     => 'stop', # default, stop servers when process exists
                                     -verbose     => 1,      # default, verbose progress messages
                                     -scan        => 1,      # default, scan region for existing staging servers and volumes
                                     -image_name  => 'ubuntu-precise-12.04',  # default server image
                                     -user_name   => 'ubuntu',                # default server login name
                                     );

 # Assuming an EBS image named ami-12345 is located in the US, copy it into 
 # the South American region, returning the AMI ID in South America
 my $new_image = $staging->copy_image('ami-12345','sa-east-1');

 # provision a new server, using defaults. Name will be assigned automatically
 my $server = $staging->provision_server(-availability_zone => 'us-east-1a');

 # retrieve a new server named "my_server", if one exists. If not, it creates one
 # using the specified options
 my $server = $staging->get_server(-name              => 'my_server',
                                   -availability_zone => 'us-east-1a',
                                   -instance_type     => 't1.micro');

 # open up an ssh session in an xterm
 $server->shell;

 # run a command over ssh on the server. See VM::EC2::Staging::Server
 $server->ssh('whoami');

 # run a command over ssh on the server, returning the result as an array of lines or a
 # scalar string, similar to backticks (``)
 my @password_lines = $server->scmd('cat /etc/passwd');

 # run a command on the server and read from it using a filehandle
 my $fh  = $server->scmd_read('ls -R /usr/lib');
 while (<$fh>) { # do something }

 # run a command on the server and write to it using a filehandle
 my $fh  = $server->scmd_write('sudo -s "cat >>/etc/fstab"');
 print $fh "/dev/sdf3 /mnt/demo ext3 0 2\n";
 close $fh;

 # Provision a new volume named "Pictures". Will automatically be mounted to a staging server in
 # the specified zone. Server will be created if needed.
 my $volume = $staging->provision_volume(-name              => 'Pictures',
                                         -fstype            => 'ext4',
                                         -availability_zone => 'us-east-1a',
                                         -size              => 2) or die $staging->error_str;

 # gets an existing volume named "Pictures" if it exists. Otherwise provisions a new volume;
 my $volume = $staging->get_volume(-name              => 'Pictures',
                                   -fstype            => 'ext4',
                                   -availability_zone => 'us-east-1a',
                                   -size              => 2) or die $staging->error_str;

 # copy contents of local directory /opt/test to remote volume $volume using rsync
 # See VM::EC2::Staging::Volume
 $volume->put('/opt/test/');

 # same thing, but first creating a subdirectory on the remote volume
 $volume->put('/opt/test/' => './mirrors/');

 # copy contents of remote volume $volume to local directory /tmp/test using rsync
 $volume->get('/tmp/test');

 # same thing, but from a subdirectory of the remote volume
 $volume->get('./mirrors/' => '/tmp/test');

 # server to server transfer (works both within and between availability regions)
 my $south_america = VM::EC2->new(-region=>'sa-east-1')->staging_manager;    # create a staging manager in Sao Paolo
 my $volume2 = $south_america->provision_volume(-name              => 'Videos',
                                                -availability_zone => 'sa-east-1a',
                                                -size              => 2);
 $staging->rsync("$volume/mirrors" => "$volume2/us-east");

 $staging->stop_all_servers();
 $staging->start_all_servers();
 $staging->terminate_all_servers();
 $staging->force_terminate_all_servers();

=head1 DESCRIPTION

VM::EC2::Staging::Manager manages a set of EC2 volumes and servers
in a single AWS region. It was primarily designed to simplify the
process of provisioning and populating volumes, but it also provides a
handy set of ssh commands that allow you to run remote commands
programmatically.

The manager also allows you to copy EBS-backed AMIs and their attached
volumes from one region to another, something that is otherwise
difficult to do.

The main classes are:

 VM::EC2::Staging::Manager -- A set of volume and server resources in
                              a single AWS region.

 VM::EC2::Staging::Server -- A staging server running somewhere in the
                             region. It is a VM::EC2::Instance
                             extended to provide remote command and
                             copy facilities.

 VM::EC2::Staging::Volume -- A staging disk volume running somewhere in the
                             region. It is a VM::EC2::Volume
                             extended to provide remote copy
                             facilities.

Staging servers can provision volumes, format them, mount them, copy
data between local and remote (virtual) machines, and execute secure
shell commands. Staging volumes can mount themselves on servers, run a
variety of filesystem-oriented commands, and invoke commands on the
servers to copy data around locally and remotely.

See L<VM::EC2::Staging::Server> and L<VM::EC2::Staging::Volume> for
the full details.

=head1 Constructors

The following methods allow you to create new
VM::EC2::Staging::Manager instances. Be aware that only one manager is
allowed per EC2 region; attempting to create additional managers in
the same region will return the same one each time.

=cut

use strict;
use VM::EC2 ':standard';
use Carp 'croak','longmess';
use File::Spec;
use File::Path 'make_path','remove_tree';
use File::Basename 'dirname','basename';
use Scalar::Util 'weaken';
use String::Approx 'adistr';
use File::Temp 'tempfile';

use constant GB => 1_073_741_824;
use constant SERVER_STARTUP_TIMEOUT => 120;
use constant LOCK_TIMEOUT  => 10;
use constant VERBOSE_DEBUG => 3;
use constant VERBOSE_INFO  => 2;
use constant VERBOSE_WARN  => 1;

my (%Zones,%Instances,%Volumes,%Managers);
my $Verbose;
my ($LastHost,$LastMt);

=head2 $manager = $ec2->staging_manager(@args)

This is a simplified way to create a staging manager. First create the
EC2 object in the desired region, and then call its staging_manager()
method:

 $manager = VM::EC2->new(-region=>'us-west-2')->staging_manager()

The staging_manager() method is only known to VM::EC2 objects if you
first "use" VM::EC2::Staging::Manager.

=over 4

=item Required Arguments

None.

=item Optional Arguments

The optional arguments change the way that the manager creates new
servers and volumes.

 -on_exit       What to do with running servers when the manager goes 
                out of scope or the script exits. One of 'run', 
                'stop' (default), or 'terminate'. "run" keeps all
                created instances running, so beware!

 -architecture  Architecture for newly-created server
                instances (default "i386"). Can be overridden in calls to get_server()
                and provision_server().

 -instance_type Type of newly-created servers (default "m1.small"). Can be overridden
                in calls to get_server() and provision_server().

 -root_type     Root type for newly-created servers (default depends
                on the -on_exit behavior; "ebs" for exit behavior of 
                "stop" and "instance-store" for exit behavior of "run"
                or "terminate".

 -image_name    Name or ami ID of the AMI to use for creating the
                instances of new servers. Defaults to 'ubuntu-precise-12.04'.
                If the image name begins with "ami-", then it is 
                treated as an AMI ID. Otherwise it is treated as
                a name pattern and will be used to search the AMI
                name field using the wildcard search "*$name*".
                Names work better than AMI ids here, because the
                latter change from one region to another. If multiple
                matching image candidates are found, then an alpha
                sort on the name is used to find the image with the
                highest alpha sort value, which happens to work with
                Ubuntu images to find the latest release.

 -availability_zone Availability zone for newly-created
                servers. Default is undef, in which case a random
                zone is selected.

 -username      Username to use for ssh connections. Defaults to 
                "ubuntu". Note that this user must be able to use
                sudo on the instance without providing a password,
                or functionality of this module will be limited.
  
 -verbose       Integer level of verbosity. Level 1 prints warning
                messages. Level 2 (the default) adds informational
                messages as well. Level 3 adds verbose debugging
                messages. Level 0 suppresses all messages.

 -quiet         (deprecated) If true, turns off all verbose messages.

 -scan          Boolean, default true. If true, scans region for
                volumes and servers created by earlier manager
                instances.

 -reuse_key     Boolean, default true. If true, creates a single
                ssh keypair for each region and reuses it. Note that
                the private key is kept on the local computer in the
                directory ~/.vm-ec2-staging, and so additional
                keypairs may be created if you use this module on
                multiple local machines. If this option is false,
                then a new keypair will be created for every server
                you partition.

 -reuse_volumes Boolean, default true. If this flag is true, then
                calls to provision_volume() will return existing
                volumes if they share the same name as the requested
                volume. If no suitable existing volume exists, then
                the most recent snapshot of this volume is used to 
                create it in the specified availability zone. Only
                if no volume or snapshot exist will a new volume be
                created from scratch.

 -dotdir        Path to the directory that contains keyfiles and other
                stable configuration information for this module.
                Defaults to ~/.vm_ec2_staging. You may wish to change
                this to, say, a private dropbox directory or an NFS-mount
                in order to share keyfiles among machines. Be aware of
                the security implications of sharing private key files.

 -server_class  By default, staging server objects created by the manager
                are of class type VM::EC2::Staging::Server. If you create
                a custom server subclass, you need to let the manager know
                about it by passing the class name to this argument.

 -volume_class  By default, staging volume objects created by the manager
                are of class type VM::EC2::Staging::Volume. If you create
                a custom volume subclass, you need to let the manager know
                about it by passing the class name to this argument.

=back

=head2 $manager = VM::EC2::Staging::Manager(-ec2 => $ec2,@args)

This is a more traditional constructur for the staging manager.

=over 4

=item Required Arguments
 
  -ec2     A VM::EC2 object.

=item Optional Arguments

All of the arguments listed in the description of
VM::EC2->staging_manager().

=back

=cut

sub VM::EC2::staging_manager {
    my $self = shift;
    return VM::EC2::Staging::Manager->new(@_,-ec2=>$self)
}


sub new {
    my $self = shift;
    my %args  = @_;
    $args{-ec2}               ||= VM::EC2->new();

    if (my $manager = $self->find_manager($args{-ec2}->endpoint)) {
	return $manager;
    }

    $args{-on_exit}           ||= $self->default_exit_behavior;
    $args{-reuse_key}         ||= $self->default_reuse_keys;
    $args{-username}          ||= $self->default_user_name;
    $args{-architecture}      ||= $self->default_architecture;
    $args{-root_type}         ||= $self->default_root_type;
    $args{-instance_type}     ||= $self->default_instance_type;
    $args{-reuse_volumes}     ||= $self->default_reuse_volumes;
    $args{-image_name}        ||= $self->default_image_name;
    $args{-availability_zone} ||= undef;
    $args{-verbose}             = $self->default_verbosity unless exists $args{-verbose};
    $args{-scan}                = 1 unless exists $args{-scan};
    $args{-pid}                 = $$;
    $args{-dotdir}            ||= $self->default_dot_directory_path;
    $args{-volume_class}      ||= $self->default_volume_class;
    $args{-server_class}      ||= $self->default_server_class;

    $args{-verbose} = 0       if $args{-quiet};

    # bring in classes
    foreach ('-server_class','-volume_class') {
	eval "use $args{$_};1" or croak "Can't use $args{$_}"
	    unless $args{$_}->can('new');
    }

    # create accessors
    my $class = ref $self || $self;
    foreach (keys %args) {
	(my $func_name = $_) =~ s/^-//;
	next if $self->can($func_name);
	eval <<END;
sub ${class}::${func_name} {
    my \$self = shift;
    my \$d    = \$self->{$_};
    \$self->{$_} = shift if \@_;
    return \$d;
}
END
    die $@ if $@;
    }

    $Verbose  = $args{-verbose};  # package global, for a few edge cases
    my $obj = bless \%args,ref $class || $class;
    weaken($Managers{$obj->ec2->endpoint} = $obj);
    if ($args{-scan}) {
	$obj->info("Scanning for existing staging servers and volumes in ",$obj->ec2->endpoint,".\n");
	$obj->scan_region;
    }
    return $obj;
}


# class method
# the point of this somewhat odd way of storing managers is to ensure that there is only one
# manager per endpoint, and to avoid circular references in the Server and Volume objects.
sub find_manager {
    my $class    = shift;
    my $endpoint = shift;
    return unless $endpoint;
    return $Managers{$endpoint};
}

=head1 Interzone Copying of AMIs and Snapshots

This library provides convenience methods for copying whole AMIs as
well as individual snapshots from one zone to another. It does this by
gathering information about the AMI/snapshot in the source zone,
creating staging servers in the source and target zones, and then
copying the volume data from the source to the target. If an
AMI/snapshot does not use a recognized filesystem (e.g. it is part of
an LVM or RAID disk set), then block level copying of the entire
device is used. Otherwise, rsync() is used to minimize data transfer
fees.

Note that interzone copying of instance-backed AMIs is B<not>
supported. Only EBS-backed images can be copied in this way.

See also the command-line script migrate-ebs-image.pl that comes with
this package.

=head2 $new_image_id = $manager->copy_image($source_image,$destination_zone,@register_options)

This method copies the AMI indicated by $source_image from the zone
that $manager belongs to, into the indicated $destination_zone, and
returns the AMI ID of the new image in the destination zone.

$source_image may be an AMI ID, or a VM::EC2::Image object.

$destination_zone may be a simple region name, such as "us-west-2", or
a VM::EC2::Region object (as returned by VM::EC2->describe_regions),
or a VM::EC2::Staging::Manager object that is associated with the
desired region. The latter form gives you control over the nature of
the staging instances created in the destination zone. For example, if
you wish to use 'm1.large' high-I/O instances in both the source and
destination reasons, you would proceed like this:

 my $source      = VM::EC2->new(-region=>'us-east-1'
                               )->staging_manager(-instance_type=>'m1.large',
                                                  -on_exit      =>'terminate');
 my $destination = VM::EC2->new(-region=>'us-west-2'
                               )->staging_manager(-instance_type=>'m1.large',
                                                  -on_exit      =>'terminate');
 my $new_image   = $source->copy_image('ami-123456' => $destination);

If present, the named argument list @register_options will be passed
to register_image() and used to override options in the destination
image. This can be used to set ephemeral device mappings, which cannot
currently be detected and transferred automatically by copy_image():

 $new_image =$source->copy_image('ami-123456'   => 'us-west-2',
                                 -description   => 'My AMI western style',
                                 -block_devices => '/dev/sde=ephemeral0');

=head2 $dest_kernel = $manager->match_kernel($src_kernel,$dest_zone)

Find a kernel in $dest_zone that matches the $src_kernel in the
current zone. $dest_zone can be a VM::EC2::Staging manager object, a
region name, or a VM::EC2::Region object.

=cut

#############################################
# copying AMIs from one zone to another
#############################################
sub copy_image {
    my $self = shift;
    my ($imageId,$destination,@options) = @_;
    my $ec2 = $self->ec2;

    my $image = ref $imageId && $imageId->isa('VM::EC2::Image') ? $imageId 
  	                                                        : $ec2->describe_images($imageId);
    $image       
	or  croak "Unknown image '$imageId'";
    $image->imageType eq 'machine' 
	or  croak "$image is not an AMI";
#    $image->platform eq 'windows'
#	and croak "It is not currently possible to migrate Windows images between regions via this method";
    $image->rootDeviceType eq 'ebs'
	or croak "It is not currently possible to migrate instance-store backed images between regions via this method";
        
    my $dest_manager = $self->_parse_destination($destination);

    my $root_type = $image->rootDeviceType;
    if ($root_type eq 'ebs') {
	return $self->_copy_ebs_image($image,$dest_manager,\@options);
    } else {
	return $self->_copy_instance_image($image,$dest_manager,\@options);
    }
}

=head2 $new_snapshot_id = $manager->copy_snapshot($source_snapshot,$destination_zone)

This method copies the EBS snapshot indicated by $source_snapshot from
the zone that $manager belongs to, into the indicated
$destination_zone, and returns the ID of the new snapshot in the
destination zone.

$source_snapshot may be an string ID, or a VM::EC2::Snapshot object.

$destination_zone may be a simple region name, such as "us-west-2", or
a VM::EC2::Region object (as returned by VM::EC2->describe_regions),
or a VM::EC2::Staging::Manager object that is associated with the
desired region.

Note that this call uses the Amazon CopySnapshot API call that was
introduced in 2012-12-01 and no longer involves the creation of
staging servers in the source and destination regions.

=cut

sub copy_snapshot {
    my $self = shift;
    my ($snapId,$dest_manager) = @_;
    my $snap   = $self->ec2->describe_snapshots($snapId) 
	or croak "Couldn't find snapshot for $snapId";
    my $description = "duplicate of $snap, created by ".__PACKAGE__." during snapshot copying";
    my $dest_region = ref($dest_manager) && $dest_manager->can('ec2') 
	              ? $dest_manager->ec2->region
		      : "$dest_manager";

    $self->info("Copying snapshot $snap from ",$self->ec2->region," to $dest_region...\n");
    my $snapshot = $snap->copy(-region       =>  $dest_region,
			       -description  => $description);

    while (!eval{$snapshot->current_status}) {
	sleep 1;
    }
    $self->info("...new snapshot = $snapshot; status = ",$snapshot->current_status,"\n");

    # copy snapshot tags
    my $tags = $snap->tags;
    $snapshot->add_tags($tags);

    return $snapshot;
}

sub _copy_instance_image {
    my $self = shift;
    croak "This module is currently unable to copy instance-backed AMIs between regions.\n";
}

sub _copy_ebs_image {
    my $self = shift;
    my ($image,$dest_manager,$options) = @_;

    # apply overrides
    my %overrides = @$options if $options;

    # hashref with keys 'name', 'description','architecture','kernel','ramdisk','block_devices','root_device'
    # 'is_public','authorized_users'
    $self->info("Gathering information about image $image.\n");
    my $info = $self->_gather_image_info($image);

    my $name         = $info->{name};
    my $description  = $info->{description};
    my $architecture = $info->{architecture};
    my $root_device  = $info->{root_device};
    my $platform     = $info->{platform};
    my ($kernel,$ramdisk);

    # make sure we have a suitable image in the destination region
    # if the virtualization type is HVM
    my $is_hvm = $image->virtualization_type eq 'hvm';
    if ($is_hvm) {
	$self->_find_hvm_image($dest_manager->ec2,
			       $root_device,
			       $architecture,
			       $platform)
	    or croak "Destination region ",$dest_manager->ec2->region," does not currently support HVM images of this type";
    }

    if ($info->{kernel} && !$overrides{-kernel}) {
	$self->info("Searching for a suitable kernel in the destination region.\n");
	$kernel       = $self->_match_kernel($info->{kernel},$dest_manager,'kernel')
	    or croak "Could not find an equivalent kernel for $info->{kernel} in region ",$dest_manager->ec2->endpoint;
	$self->info("Matched kernel $kernel\n");
    }
    
    if ($info->{ramdisk} && !$overrides{-ramdisk}) {
	$self->info("Searching for a suitable ramdisk in the destination region.\n");
	$ramdisk      = ( $self->_match_kernel($info->{ramdisk},$dest_manager,'ramdisk')
		       || $dest_manager->_guess_ramdisk($kernel)
	    )  or croak "Could not find an equivalent ramdisk for $info->{ramdisk} in region ",$dest_manager->ec2->endpoint;
	$self->info("Matched ramdisk $ramdisk\n");
    }

    my $block_devices   = $info->{block_devices};  # format same as $image->blockDeviceMapping

    $self->info("Copying EBS volumes attached to this image (this may take a long time).\n");
    my @bd              = @$block_devices;
    my %dest_snapshots  = map {
	$_->snapshotId
	    ? ($_->snapshotId => $self->copy_snapshot($_->snapshotId,$dest_manager))
	    : ()
    } @bd;
    
    $self->info("Waiting for all snapshots to complete. This may take a long time.\n");
    my $state = $dest_manager->ec2->wait_for_snapshots(values %dest_snapshots);
    my @errored = grep {$state->{$_} eq 'error'} values %dest_snapshots;
    croak ("Snapshot(s) @errored could not be completed due to an error")
	if @errored;

    # create the new block device mapping
    my @mappings;
    for my $source_ebs (@$block_devices) {
	my $dest        = "$source_ebs";  # interpolates into correct format
	$dest          =~ s/=([\w-]+)/'='.($dest_snapshots{$1}||$1)/e;  # replace source snap with dest snap
	push @mappings,$dest;
    }

    # ensure choose a unique name
    if ($dest_manager->ec2->describe_images({name => $name})) {
	print STDERR "An image named '$name' already exists in destination region. ";
	$name = $self->_token($name);
	print STDERR "Renamed to '$name'\n";
    }

    # merge block device mappings if present
    if (my $m = $overrides{-block_device_mapping}||$overrides{-block_devices}) {
	push @mappings,(ref $m ? @$m : $m);
	delete $overrides{-block_device_mapping};
	delete $overrides{-block_devices};
    }

    # helpful for recovering failed process
    my $block_device_info_args = join ' ',map {"-b $_"} @mappings;

    my $img;

    if ($is_hvm) {
	$self->info("Registering snapshot in destination with the equivalent of:\n");
	$self->info("ec2-register -n '$name' -d '$description' -a $architecture --virtualization-type hvm --root-device-name $root_device $block_device_info_args\n");
	$self->info("Note: this is a notional command line that can only be used by AWS development partners.\n");
	$img = $self->_create_hvm_image(-ec2                  => $dest_manager->ec2,
					-name                 => $name,
					-root_device_name     => $root_device,
					-block_device_mapping => \@mappings,
					-description          => $description,
					-architecture         => $architecture,
					-platform             => $image->platform,
					%overrides);
    }

    else {
	$self->info("Registering snapshot in destination with the equivalent of:\n");
	$self->info("ec2-register -n '$name' -d '$description' -a $architecture --kernel '$kernel' --ramdisk '$ramdisk' --root-device-name $root_device $block_device_info_args\n");
	$img =  $dest_manager->ec2->register_image(-name                 => $name,
						   -root_device_name     => $root_device,
						   -block_device_mapping => \@mappings,
						   -description          => $description,
						   -architecture         => $architecture,
						   $kernel  ? (-kernel_id   => $kernel):  (),
						   $ramdisk ? (-ramdisk_id  => $ramdisk): (),
						   %overrides,
	    );
	$img or croak "Could not register image: ",$dest_manager->ec2->error_str;
    }
    
    # copy launch permissions
    $img->make_public(1)                                     if $info->{is_public};
    $img->add_authorized_users(@{$info->{authorized_users}}) if @{$info->{authorized_users}};
    
    # copy tags
    my $tags = $image->tags;
    $img->add_tags($tags);

    # Improve the snapshot tags
    my $source_region = $self->ec2->region;
    my $dest_region   = $dest_manager->ec2->region;
    for (@mappings) {
	my ($snap) = /(snap-[0=9a-f]+)/ or next;
	$snap = $dest_manager->ec2->describe_snapshots($snap) or next;
	$snap->add_tags(Name => "Copy image $image($source_region) to $img($dest_region)");
    }

    return $img;
}

# copying an HVM image requires us to:
# 1. Copy each of the snapshots to the destination region
# 2. Find a public HVM image in the destination region that matches the architecture, hypervisor type,
#    and root device type of the source image. (note: platform must not be 'windows'
# 3. Run a cc2 instance: "cc2.8xlarge", but replace default block device mapping with the new snapshots.
# 4. Stop the image.
# 5. Detach the root volume
# 6. Initialize and attach a new root volume from the copied source root snapshot.
# 7. Run create_image() on the instance.
# 8. Terminate the instance and clean up.
sub _create_hvm_image {
    my $self = shift;
    my %args = @_;

    my $ec2 = $args{-ec2};

    # find a suitable image that we can run
    $self->info("Searching for a suitable HVM image in destination region\n");
    my $ami = $self->_find_hvm_image($ec2,$args{-root_device_name},$args{-architecture},$args{-platform});
    $ami or croak "Could not find suitable HVM image in region ",$ec2->region;

    $self->info("...Found $ami (",$ami->name,")\n");

    # remove root device from the block device list
    my $root            = $args{-root_device_name};
    my @nonroot_devices = grep {!/^$root/} @{$args{-block_device_mapping}};
    my ($root_snapshot) = "@{$args{-block_device_mapping}}" =~ /$root=(snap-[0-9a-f]+)/;
    
    my $instance_type = $args{-platform} eq 'windows' ? 'm1.small' : 'cc2.8xlarge';
    $self->info("Launching an HVM staging server in the target region. Heuristically choosing instance type of '$instance_type' for this type of HVM..\n");

    my $instance = $ec2->run_instances(-instance_type => $instance_type,
				       -image_id      => $ami,
				       -block_devices => \@nonroot_devices)
	or croak "Could not run HVM instance: ",$ec2->error_str;
    $self->info("Waiting for instance to become ready.\n");
    $ec2->wait_for_instances($instance);
    
    $self->info("Stopping instance temporarily to swap root volumes.\n");
    $instance->stop(1);

    $self->info("Detaching original root volume...\n");
    my $a = $instance->detach_volume($root) or croak "Could not detach $root: ", $ec2->error_str;
    $ec2->wait_for_attachments($a);
    $a->current_status eq 'detached'   or croak "Could not detach $root, status = ",$a->current_status;
    $ec2->delete_volume($a->volumeId)  or croak "Could not delete original root volume: ",$ec2->error_str;

    $self->info("Creating and attaching new root volume..\n");
    my $vol = $ec2->create_volume(-availability_zone => $instance->placement,
				  -snapshot_id       => $root_snapshot) 
	or croak "Could not create volume from root snapshot $root_snapshot: ",$ec2->error_str;
    $ec2->wait_for_volumes($vol);
    $vol->current_status eq 'available'  or croak "Volume creation failed, status = ",$vol->current_status;

    $a = $instance->attach_volume($vol,$root) or croak "Could not attach new root volume: ",$ec2->error_str;
    $ec2->wait_for_attachments($a);
    $a->current_status eq 'attached'          or croak "Attach failed, status = ",$a->current_status;
    $a->deleteOnTermination(1);

    $self->info("Creating image in destination region...\n");
    my $img = $instance->create_image($args{-name},$args{-description});

    # get rid of the original copied snapshots - we no longer need them
    foreach (@{$args{-block_device_mapping}}) {
	my ($snapshot) = /(snap-[0-9a-f]+)/ or next;
	$ec2->delete_snapshot($snapshot) 
	    or $self->warn("Could not delete unneeded snapshot $snapshot; please delete manually: ",$ec2->error_str)
    }

    # terminate the staging server.
    $self->info("Terminating the staging server\n");
    $instance->terminate;  # this will delete the volume as well because of deleteOnTermination

    return $img;
}

sub _find_hvm_image {
    my $self = shift;
    my ($ec2,$root_device_name,$architecture,$platform) = @_;

    my $cache_key = join (';',@_);
    return $self->{_hvm_image}{$cache_key} if exists $self->{_hvm_image}{$cache_key};

    my @i = $ec2->describe_images(-executable_by=> 'all',
				  -owner        => 'amazon',
				  -filter => {
				      'virtualization-type' => 'hvm',
				      'root-device-type'    => 'ebs',
				      'root-device-name'    => $root_device_name,
				      'architecture'        => $architecture,
				  });
    @i = grep {$_->platform eq $platform} @i;
    return $self->{_hvm_image}{$cache_key} = $i[0];
}


=head1 Instance Methods for Managing Staging Servers

These methods allow you to create and interrogate staging
servers. They each return one or more VM::EC2::Staging::Server
objects. See L<VM::EC2::Staging::Server> for more information about
what you can do with these servers once they are running.

=head2 $server = $manager->provision_server(%options)

Create a new VM::EC2::Staging::Server object according to the passed
options, which override the default options provided by the Manager
object.

 -name          Name for this server, which can be used to retrieve
                it later with a call to get_server().

 -architecture  Architecture for the newly-created server
                instances (e.g. "i386"). If not specified, then defaults
                to the default_architecture() value. If explicitly
                specified as undef, then the architecture of the matching
                image will be used.

 -instance_type Type of the newly-created server (e.g. "m1.small").

 -root_type     Root type for the server ("ebs" or "instance-store").

 -image_name    Name or ami ID of the AMI to use for creating the
                instance for the server. If the image name begins with
                "ami-", then it is treated as an AMI ID. Otherwise it
                is treated as a name pattern and will be used to
                search the AMI name field using the wildcard search
                "*$name*". Names work better than AMI ids here,
                because the latter change from one region to
                another. If multiple matching image candidates are
                found, then an alpha sort on the name is used to find
                the image with the highest alpha sort value, which
                happens to work with Ubuntu images to find the latest
                release.

 -availability_zone Availability zone for the server, or undef to
                choose an availability zone randomly.

 -username      Username to use for ssh connections. Defaults to 
                "ubuntu". Note that this user must be able to use
                sudo on the instance without providing a password,
                or functionality of this server will be limited.

In addition, you may use any of the options recognized by
VM::EC2->run_instances() (e.g. -block_devices).

=cut

sub provision_server {
    my $self    = shift;
    my @args    = @_;

    # let subroutine arguments override manager's args
    my %args    = ($self->_run_instance_args,@args);

    # fix possible gotcha -- instance store is not allowed for micro instances.
    $args{-root_type} = 'ebs' if $args{-instance_type} eq 't1.micro';
    $args{-name}    ||= $self->new_server_name;

    my ($keyname,$keyfile) = $self->_security_key;
    my $security_group     = $self->_security_group;
    my $image              = $self->_search_for_image(%args) or croak "No suitable image found";
    $args{-architecture}   = $image->architecture;

    my ($instance)         = $self->ec2->run_instances(
	-image_id          => $image,
	-security_group_id => $security_group,
	-key_name          => $keyname,
	%args,
	);
    $instance or croak $self->ec2->error_str;

    my $success;
    while (!$success) {
	# race condition...
	$success = eval{ $instance->add_tags(StagingRole     => 'StagingInstance',
					     Name            => "Staging server $args{-name} created by ".__PACKAGE__,
					     StagingUsername => $self->username,
					     StagingName     => $args{-name});
	}
    }

    my $class = $args{-server_class} || $self->server_class;
			
    my $server = $class->new(
	-keyfile  => $keyfile,
	-username => $self->username,
	-instance => $instance,
	-manager  => $self,
	-name     => $args{-name},
	@args,
	);
    eval {
	local $SIG{ALRM} = sub {die 'timeout'};
	alarm(SERVER_STARTUP_TIMEOUT);
	$self->wait_for_servers($server);
    };
    alarm(0);
    croak "server did not start after ",SERVER_STARTUP_TIMEOUT," seconds"
	if $@ =~ /timeout/;
    $self->register_server($server);
    return $server;
}

sub _run_instance_args {
    my $self = shift;
    my @args;
    for my $arg (qw(instance_type availability_zone architecture image_name root_type)) {
	push @args,("-${arg}" => $self->$arg);
    }
    return @args;
}

=head2 $server = $manager->get_server(-name=>$name,%other_options)

=head2 $server = $manager->get_server($name)

Return an existing VM::EC2::Staging::Server object having the
indicated symbolic name, or create a new server if one with this name
does not already exist. The server's instance characteristics will be
configured according to the options passed to the manager at create
time (e.g. -availability_zone, -instance_type). These options can be
overridden by %other_args. See provision_volume() for details.

=cut

sub get_server {
    my $self = shift;
    unshift @_,'-name' if @_ == 1;

    my %args = @_;
    $args{-name}              ||= $self->new_server_name;

    # find servers of same name
    local $^W = 0; # prevent an uninitialized value warning
    my %servers = map {$_->name => $_} $self->servers;
    my $server = $servers{$args{-name}} || $self->provision_server(%args);

    # this information needs to be renewed each time
    $server->username($args{-username}) if $args{-username};
    bless $server,$args{-server_class}  if $args{-server_class};

    $server->start unless $server->ping;
    return $server;
}

=head2 $server = $manager->get_server_in_zone(-zone=>$availability_zone,%other_options)

=head2 $server = $manager->get_server_in_zone($availability_zone)

Return an existing VM::EC2::Staging::Server running in the indicated
symbolic name, or create a new server if one with this name does not
already exist. The server's instance characteristics will be
configured according to the options passed to the manager at create
time (e.g. -availability_zone, -instance_type). These options can be
overridden by %other_args. See provision_server() for details.

=cut

sub get_server_in_zone {
    my $self = shift;
    unshift @_,'-availability_zone' if @_ == 1;
    my %args = @_;
    my $zone = $args{-availability_zone};
    if ($zone && (my $servers = $Zones{$zone}{Servers})) {
	my $server = (values %{$servers})[0];
	$server->start unless $server->is_up;
	return $server;
    }
    else {
	return $self->provision_server(%args);
    }
}

=head2 $server = $manager->find_server_by_instance($instance_id)

Given an EC2 instanceId, return the corresponding
VM::EC2::Staging::Server, if any.

=cut

sub find_server_by_instance {
    my $self  = shift;
    my $server = shift;
    return $Instances{$server};
}

=head2 @servers $manager->servers

Return all registered VM::EC2::Staging::Servers in the zone managed by
the manager.

=cut

sub servers {
    my $self      = shift;
    my $endpoint  = $self->ec2->endpoint;
    return $self->_servers($endpoint);
}

=head2 $manager->start_all_servers

Start all VM::EC2::Staging::Servers that are currently in the "stop"
state.

=cut

sub start_all_servers {
    my $self = shift;
    my @servers = $self->servers;
    my @need_starting = grep {$_->current_status eq 'stopped'} @servers;
    return unless @need_starting;
    eval {
	local $SIG{ALRM} = sub {die 'timeout'};
	alarm(SERVER_STARTUP_TIMEOUT);
	$self->_start_instances(@need_starting);
    };
    alarm(0);
    croak "some servers did not start after ",SERVER_STARTUP_TIMEOUT," seconds"
	if $@ =~ /timeout/;
}

=head2 $manager->stop_all_servers

Stop all VM::EC2::Staging::Servers that are currently in the "running"
state.

=cut

sub stop_all_servers {
    my $self = shift;
    my $ec2 = $self->ec2;
    my @servers  = grep {$_->ec2 eq $ec2} $self->servers;
    @servers or return;
    $self->info("Stopping servers @servers.\n");
    $self->ec2->stop_instances(@servers);
    $self->ec2->wait_for_instances(@servers);
}

=head2 $manager->terminate_all_servers

Terminate all VM::EC2::Staging::Servers and unregister them.

=cut

sub terminate_all_servers {
    my $self = shift;
    my $ec2 = $self->ec2 or return;
    my @servers  = $self->servers or return;
    $self->_terminate_servers(@servers);
}

=head2 $manager->force_terminate_all_servers

Force termination of all VM::EC2::Staging::Servers, even if the
internal registration system indicates that some may be in use by
other Manager instances.

=cut

sub force_terminate_all_servers {
    my $self = shift;
    my $ec2 = $self->ec2 or return;
    my @servers  = $self->servers or return;
    $ec2->terminate_instances(@servers) or warn $self->ec2->error_str;
    $ec2->wait_for_instances(@servers);
}

sub _terminate_servers {
    my $self = shift;
    my @servers = @_;
    my $ec2 = $self->ec2 or return;

    my @terminate;
    foreach (@servers) {
	my $in_use = $self->unregister_server($_);
	if ($in_use) {
	    $self->warn("$_ is still in use. Will not terminate.\n");
	    next;
	}
	push @terminate,$_;
    }
    
    if (@terminate) {
	$self->info("Terminating servers @terminate.\n");
	$ec2->terminate_instances(@terminate) or warn $self->ec2->error_str;
	$ec2->wait_for_instances(@terminate);
    }

    unless ($self->reuse_key) {
	$ec2->delete_key_pair($_) foreach $ec2->describe_key_pairs(-filter=>{'key-name' => 'staging-key-*'});
    }
}

=head2 $manager->wait_for_servers(@servers)

Wait until all the servers on the list @servers are up and able to
accept ssh commands. You may wish to wrap this in an eval{} and
timeout in order to avoid waiting indefinitely.

=cut

sub wait_for_servers {
    my $self = shift;
    my @instances = @_;
    my $status = $self->ec2->wait_for_instances(@instances);
    my %pending = map {$_=>$_} grep {$_->current_status eq 'running'} @instances;
    $self->info("Waiting for ssh daemon on @instances.\n") if %pending;
    while (%pending) {
	for my $s (values %pending) {
	    unless ($s->ping) {
		sleep 5;
		next;
	    }
	    delete $pending{$s};
	}
    }
    return $status;
}

sub _start_instances {
    my $self = shift;
    my @need_starting = @_;
    $self->info("starting instances: @need_starting.\n");
    $self->ec2->start_instances(@need_starting);
    $self->wait_for_servers(@need_starting);
}

=head1 Instance Methods for Managing Staging Volumes

These methods allow you to create and interrogate staging
volumes. They each return one or more VM::EC2::Staging::Volume
objects. See L<VM::EC2::Staging::Volume> for more information about
what you can do with these staging volume objects.

=head2 $volume = $manager->provision_volume(%options)

Create and register a new VM::EC2::Staging::Volume and mount it on a
staging server in the appropriate availability zone. A new staging
server will be created for this purpose if one does not already
exist. 

If you provide a symbolic name for the volume and the manager has
previously snapshotted a volume by the same name, then the snapshot
will be used to create the volume (this behavior can be suppressed by
passing -reuse=>0). This allows for the following pattern for
efficiently updating a snapshotted volume:

 my $vol = $manager->provision_volume(-name=>'MyPictures',
                                      -size=>10);
 $vol->put('/usr/local/my_pictures/');   # will do an rsync from local directory
 $vol->create_snapshot;  # write out to a snapshot
 $vol->delete;

You may also explicitly specify a volumeId or snapshotId. The former
allows you to place an existing volume under management of
VM::EC2::Staging::Manager and returns a corresponding staging volume
object. The latter creates the staging volume from the indicated
snapshot, irregardless of whether the snapshot was created by the
staging manager at an earlier time.

Newly-created staging volumes are automatically formatted as ext4
filesystems and mounted on the staging server under
/mnt/Staging/$name, where $name is the staging volume's symbolic
name. The filesystem type and the mountpoint can be modified with the
-fstype and -mount arguments, respectively. In addition, you may
specify an -fstype of "raw", in which case the volume will be attached
to a staging server (creating the server first if necessary) but not
formatted or mounted. This is useful when creating multi-volume RAID
or LVM setups.

Options:

 -name       Name of the staging volume. A fatal error issues if a staging
             volume by this name already exists (use get_volume() to
             avoid this).  If no name is provided, then a random
             unique one is chosen for you.

 -availability_zone 
             Availability zone in which to create this
             volume. If none is specified, then a zone is chosen that
             reuses an existing staging server, if any.

 -size       Size of the desired volume, in GB.

 -fstype     Filesystem type for the volume, ext4 by default. Supported
             types are ext2, ext3, ext4, xfs, reiserfs, jfs, hfs,
             ntfs, vfat, msdos, and raw.

 -mount      Mount point for this volume on the staging server (e.g. /opt/bin). 
             Use with care, as there are no checks to prevent you from mounting
             two staging volumes on top of each other or mounting over essential
             operating system paths.

 -label      Volume label. Only applies to filesystems that support labels
             (all except hfs, vfat, msdos and raw).

 -volume_id  Create the staging volume from an existing EBS volume with
             the specified ID. Most other options are ignored in this
             case.

 -snapshot_id 
             Create the staging volume from an existing EBS
             snapshot. If a size is specified that is larger than the
             snapshot, then the volume and its filesystem will be
             automatically extended (this only works for ext volumes
             at the moment). Shrinking of volumes is not currently
             supported.

 -reuse      If true, then the most recent snapshot created from a staging
             volume of the same name is used to create the
             volume. This is the default. Pass 0 to disable this
             behavior.

The B<-reuse> argument is intended to support the following use case
in which you wish to rsync a directory on a host system somewhere to
an EBS snapshot, without maintaining a live server and volume on EC2:

 my $volume = $manager->provision_volume(-name=>'backup_1',
                                         -reuse  => 1,
                                         -fstype => 'ext3',
                                         -size   => 10);
 $volume->put('fred@gw.harvard.edu:my_music');
 $volume->create_snapshot('Music Backup '.localtime);
 $volume->delete;

The next time this script is run, the "backup_1" volume will be
recreated from the most recent snapshot, minimizing copying. A new
snapshot is created, and the staging volume is deleted.

=cut

sub provision_volume {
    my $self = shift;
    my %args = @_;

    $args{-name}              ||= $self->new_volume_name;
    $args{-size}              ||= 1 unless $args{-snapshot_id} || $args{-volume_id};
    $args{-volume_id}         ||= undef;
    $args{-snapshot_id}       ||= undef;
    $args{-reuse}               = $self->reuse_volumes unless defined $args{-reuse};
    $args{-mount}             ||= '/mnt/Staging/'.$args{-name}; # BUG: "/mnt/Staging" is hardcoded in multiple places
    $args{-fstype}            ||= 'ext4';
    $args{-availability_zone} ||= $self->_select_used_zone;
    $args{-label}             ||= $args{-name};

    $self->find_volume_by_name($args{-name}) && 
	croak "There is already a volume named $args{-name} in this region";
    
    if ($args{-snapshot_id}) {
	$self->info("Provisioning volume from snapshot $args{-snapshot_id}.\n");
    } elsif ($args{-volume_id}) {
	$self->info("Provisioning volume from volume $args{-volume_id}.\n");
	my $v = $self->ec2->describe_volumes($args{-volume_id});
	$args{-availability_zone} = $v->availabilityZone if $v;
	$args{-size}              = $v->size             if $v;
    } else {
	$self->info("Provisioning a new $args{-size} GB $args{-fstype} volume.\n");
    }

    $args{-availability_zone} ? $self->info("Obtaining a staging server in zone $args{-availability_zone}.\n")
                              : $self->info("Obtaining a staging server.\n");
    my $server = $self->get_server_in_zone($args{-availability_zone});
    $server->start unless $server->ping;
    my $volume = $server->provision_volume(%args);
    $self->register_volume($volume);
    return $volume;
}

=head2 $volume = $manager->get_volume(-name=>$name,%other_options)

=head2 $volume = $manager->get_volume($name)

Return an existing VM::EC2::Staging::Volume object with the indicated
symbolic name, or else create a new volume if one with this name does
not already exist. The volume's characteristics will be configured
according to the options in %other_args. See provision_volume() for
details. If called with no arguments, this method returns Volume
object with default characteristics and a randomly-assigned name.

=cut

sub get_volume {
    my $self = shift;

    unshift @_,'-name' if @_ == 1;
    my %args = @_;
    $args{-name}              ||= $self->new_volume_name;

    # find volume of same name
    my %vols = map {$_->name => $_} $self->volumes;
    my $vol = $vols{$args{-name}} || $self->provision_volume(%args);
    return $vol;
}

=head2 $result = $manager->rsync($src1,$src2,$src3...,$dest)

This method provides remote synchronization (rsync) file-level copying
between one or more source locations and a destination location via an
ssh tunnel. Copying among arbitrary combinations of local and remote
filesystems is supported, with the caveat that the remote filesystems
must be contained on volumes and servers managed by this module (see
below for a workaround).

You may provide two or more directory paths. The last path will be
treated as the copy destination, and the source paths will be treated
as copy sources. All copying is performed using the -avz options,
which activates recursive directory copying in which ownership,
modification times and permissions are preserved, and compresses the
data to reduce network usage. Verbosity is set so that the names of
copied files are printed to STDERR. If you do not wish this, then use
call the manager's quiet() method with a true value.

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

 $staging_volume
      Pass a VM::EC2::Staging::Volume to copy the contents of the
      volume to the destination disk starting at the root of the
      volume. Note that you do *not* need to have any knowledge of the
      mount point for this volume in order to copy its contents.

 $staging_volume:/absolute/path
 $staging_volume:absolute/path
 $staging_volume/absolute/path
      All these syntaxes accomplish the same thing, which is to
      copy a subdirectory of a staging volume to the destination disk.
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

 $staging_server:/absolute/path
     Pass a staging server object and absolute path to copy the contents
     of this path to the destination disk. Because of string interpolation
     you can include server objects in quotes: "$my_server:/opt"

 $staging_server:relative/path
     This form will copy data from paths relative to the remote user's home
     directory on the staging server. Typically not very useful, but supported.

The same syntax is supported for destination paths, except that it
makes no difference whether a path has a trailing slash or not.

As with the rsync command, if you proceed a path with a single colon
(:/my/path), it is a short hand to use the previous server/volume/host
in the source list.

When specifying multiple source directories, all source directories must
reside on the same local or remote machine. This is legal:

 $manager->rsync("$picture_volume:/family/vacations",
                 "$picture_volume:/family/picnics"
                 => "$backup_volume:/recent_backups");

This is not:

 $manager->rsync("$picture_volume:/family/vacations",
                 "$audio_volume:/beethoven"
                 => "$backup_volume:/recent_backups");

When specifying multiple sources, you may give the volume or server
once for the first source and then start additional source paths with
a ":" to indicate the same volume or server is to be used:

 $manager->rsync("$picture_volume:/family/vacations",
                 ":/family/picnics"
                 => "$backup_volume:/recent_backups");

When copying to/from the local machine, the rsync process will run as
the user that the script was launched by. However, on remote servers
managed by the staging manager, the rsync process will run as
superuser.

The rsync() method will also accept regular remote DNS names and IP
addresses, optionally preceded by a username:

 $manager->rsync("$picture_volume:/family/vacations" => 'fred@gw.harvard.edu:/tmp')

When called in this way, the method does what it can to avoid
prompting for a password or passphrase on the non-managed host
(gw.harvard.edu in the above example). This includes turning off
strict host checking and forwarding the user agent information from
the local machine.

=head2 $result = $manager->rsync(\@options,$src1,$src2,$src3...,$dest)

This is a variant of the rsync command in which extra options can be
passed to rsync by providing an array reference as the first argument. 
For example:

    $manager->rsync(['--exclude' => '*~'],
                    '/usr/local/backups',
                    "$my_server:/usr/local");

=cut

# most general form
# 
sub rsync {
    my $self = shift;
    croak "usage: VM::EC2::Staging::Manager->rsync(\$source_path1,\$source_path2\...,\$dest_path)"
	unless @_ >= 2;

    my @p    = @_;
    my @user_args = ($p[0] && ref($p[0]) eq 'ARRAY')
	            ? @{shift @p}
                    : ();

    undef $LastHost;
    undef $LastMt;
    my @paths = map {$self->_resolve_path($_)} @p;

    my $dest   = pop @paths;
    my @source = @paths;

    my %hosts;
    local $^W=0; # avoid uninit value errors
    foreach (@source) {
	$hosts{$_->[0]} = $_->[0];
    }
    croak "More than one source host specified" if keys %hosts > 1;
    my ($source_host) = values %hosts;
    my $dest_host     = $dest->[0];

    my @source_paths      = map {$_->[1]} @source;
    my $dest_path         = $dest->[1];

    my $rsync_args        = $self->_rsync_args;
    my $dots;

    if ($self->verbosity == VERBOSE_INFO) {
	$rsync_args       .= 'v';  # print a line for each file
	$dots             = '2>&1|/tmp/dots.pl t';
    }
    $rsync_args .= ' '.join ' ', map {_quote_shell($_)} @user_args if @user_args;

    my $src_is_server    = $source_host && UNIVERSAL::isa($source_host,'VM::EC2::Staging::Server');
    my $dest_is_server   = $dest_host   && UNIVERSAL::isa($dest_host,'VM::EC2::Staging::Server');

    # this is true when one of the paths contains a ":", indicating an rsync
    # path that contains a hostname, but not a managed server
    my $remote_path      = "@source_paths $dest_path" =~ /:/;

    # remote rsync on either src or dest server
    if ($remote_path && ($src_is_server || $dest_is_server)) {
	my $server = $source_host || $dest_host;
	$self->_upload_dots_script($server) if $dots;
	return $server->ssh(['-t','-A'],"sudo -E rsync -e 'ssh -o \"CheckHostIP no\" -o \"StrictHostKeyChecking no\"' $rsync_args @source_paths $dest_path $dots");
    }

    # localhost => localhost
    if (!($source_host || $dest_host)) {
	my $dots_cmd = $self->_dots_cmd;
	return system("rsync @source $dest $dots_cmd") == 0;
    }

    # localhost           => DataTransferServer
    if ($dest_is_server && !$src_is_server) {
	return $dest_host->_rsync_put($rsync_args,@source_paths,$dest_path);
    }

    # DataTransferServer  => localhost
    if ($src_is_server && !$dest_is_server) {
	return $source_host->_rsync_get($rsync_args,@source_paths,$dest_path);
    }

    if ($source_host eq $dest_host) {
	$self->info("Beginning rsync @source_paths $dest_path...\n");
	my $result = $source_host->ssh('sudo','rsync',$rsync_args,@source_paths,$dest_path);
	$self->info("...rsync done.\n");
	return $result;
    }

    # DataTransferServer1 => DataTransferServer2
    # this one is slightly more difficult because datatransferserver1 has to
    # ssh authenticate against datatransferserver2.
    my $keyname = $self->_authorize($source_host => $dest_host);

    my $dest_ip  = $dest_host->instance->dnsName;
    my $ssh_args = $source_host->_ssh_escaped_args;
    my $keyfile  = $source_host->keyfile;
    $ssh_args    =~ s/$keyfile/$keyname/;  # because keyfile is embedded among args
    $self->info("Beginning rsync @source_paths $dest_ip:$dest_path...\n");
    $self->_upload_dots_script($source_host) if $dots;
    my $result = $source_host->ssh('sudo','rsync',$rsync_args,
				   '-e',"'ssh $ssh_args'",
				   "--rsync-path='sudo rsync'",
				   @source_paths,"$dest_ip:$dest_path",$dots);
    $self->info("...rsync done.\n");
    return $result;
}

sub _quote_shell {
    my $thing = shift;
    $thing =~ s/\s/\ /;
    $thing =~ s/(['"])/\\($1)/;
    $thing;
}

=head2 $manager->dd($source_vol=>$dest_vol)

This method performs block-level copying of the contents of
$source_vol to $dest_vol by using dd over an SSH tunnel, where both
source and destination volumes are VM::EC2::Staging::Volume
objects. The volumes must be attached to a server but not
mounted. Everything in the volume, including its partition table, is
copied, allowing you to make an exact image of a disk.

The volumes do B<not> actually need to reside on this server, but can
be attached to any staging server in the zone.

=cut

# for this to work, we have to create the concept of a "raw" staging volume
# that is attached, but not mounted
sub dd {
    my $self = shift;

    @_==2 or croak "usage: VM::EC2::Staging::Manager->dd(\$source_vol=>\$dest_vol)";

    my ($vol1,$vol2) = @_;
    my ($server1,$device1) = ($vol1->server,$vol1->mtdev);
    my ($server2,$device2) = ($vol2->server,$vol2->mtdev);
    my $hush     = $self->verbosity <  VERBOSE_INFO ? '2>/dev/null' : '';
    my $use_pv   = $self->verbosity >= VERBOSE_WARN;
    my $gigs     = $vol1->size;

    if ($use_pv) {
	$self->info("Configuring PV to show dd progress...\n");
	$server1->ssh("if [ ! -e /usr/bin/pv ]; then sudo apt-get -qq update >/dev/null 2>&1; sudo apt-get -y -qq install pv >/dev/null 2>&1; fi");
    }

    if ($server1 eq $server2) {
	if ($use_pv) {
	    print STDERR "\n";
	    $server1->ssh(['-t'], "sudo dd if=$device1 2>/dev/null | pv -f -s ${gigs}G -petr | sudo dd of=$device2 2>/dev/null");
	} else {
	    $server1->ssh("sudo dd if=$device1 of=$device2 $hush");
	}
    }  else {
	my $keyname  = $self->_authorize($server1,$server2);
	my $dest_ip  = $server2->instance->dnsName;
	my $ssh_args = $server1->_ssh_escaped_args;
	my $keyfile  = $server1->keyfile;
	$ssh_args    =~ s/$keyfile/$keyname/;  # because keyfile is embedded among args
	my $pv       = $use_pv ? "2>/dev/null | pv -s ${gigs}G -petr" : '';
	$server1->ssh(['-t'], "sudo dd if=$device1 $hush $pv | gzip -1 - | ssh $ssh_args $dest_ip 'gunzip -1 - | sudo dd of=$device2'");
    }
}

# take real or symbolic name and turn it into a two element
# list consisting of server object and mount point
# possible forms:
#            /local/path
#            vol-12345/relative/path
#            vol-12345:/relative/path
#            vol-12345:relative/path
#            $server:/absolute/path
#            $server:relative/path
# 
# treat path as symbolic if it does not start with a slash
# or dot characters
sub _resolve_path {
    my $self  = shift;
    my $vpath = shift;

    my ($servername,$pathname);
    if ($vpath =~ /^(vol-[0-9a-f]+):?(.*)/ &&
	      (my $vol = VM::EC2::Staging::Manager->find_volume_by_volid($1))) {
	my $path    = $2 || '/';
	$path       = "/$path" if $path && $path !~ m!^/!;
	$vol->_spin_up;
	$servername = $LastHost = $vol->server;
	my $mtpt    = $LastMt   = $vol->mtpt;
	$pathname   = $mtpt;
	$pathname  .= $path if $path;
    } elsif ($vpath =~ /^(i-[0-9a-f]{8}):(.+)$/ && 
	     (my $server = VM::EC2::Staging::Manager->find_server_by_instance($1))) {
	$servername = $LastHost = $server;
	$pathname   = $2;
    } elsif ($vpath =~ /^:(.+)$/) {
	$servername = $LastHost if $LastHost;
	$pathname   = $LastHost && $LastMt ? "$LastMt/$2" : $2;
    } else {
	return [undef,$vpath];   # localhost
    }
    return [$servername,$pathname];
}

sub _rsync_args {
    my $self  = shift;
    my $verbosity = $self->verbosity;
    return $verbosity < VERBOSE_WARN  ? '-azq'
	  :$verbosity < VERBOSE_INFO  ? '-azh'
	  :$verbosity < VERBOSE_DEBUG ? '-azh'
	  : '-azhv'
}

sub _authorize {
    my $self = shift;
    my ($source_host,$dest_host) = @_;
    my $keyname = "/tmp/${source_host}_to_${dest_host}";
    unless ($source_host->has_key($keyname)) {
	$source_host->info("creating ssh key for server to server data transfer.\n");
	$source_host->ssh("ssh-keygen -t dsa -q -f $keyname</dev/null 2>/dev/null");
	$source_host->has_key($keyname=>1);
    }
    unless ($dest_host->accepts_key($keyname)) {
	my $key_stuff = $source_host->scmd("cat ${keyname}.pub");
	chomp($key_stuff);
	$dest_host->ssh("mkdir -p .ssh; chmod 0700 .ssh; (echo '$key_stuff' && cat .ssh/authorized_keys) | sort | uniq > .ssh/authorized_keys.tmp; mv .ssh/authorized_keys.tmp .ssh/authorized_keys; chmod 0600 .ssh/authorized_keys");
	$dest_host->accepts_key($keyname=>1);
    }

    return $keyname;
}

=head2 $volume = $manager->find_volume_by_volid($volume_id)

Given an EC2 volumeId, return the corresponding
VM::EC2::Staging::Volume, if any.

=cut

sub find_volume_by_volid {
    my $self   = shift;
    my $volid = shift;
    return $Volumes{$volid};
}

=head2 $volume = $manager->find_volume_by_name($name)

Given a staging name (assigned at volume creation time), return the
corresponding VM::EC2::Staging::Volume, if any.

=cut

sub find_volume_by_name {
    my $self =  shift;
    my $name = shift;
    my %volumes = map {$_->name => $_} $self->volumes;
    return $volumes{$name};
}

=head2 @volumes = $manager->volumes

Return all VM::EC2::Staging::Volumes managed in this zone.

=cut

sub volumes {
    my $self = shift;
    return grep {$_->ec2->endpoint eq $self->ec2->endpoint} values %Volumes;
}

=head1 Instance Methods for Accessing Configuration Options

This section documents accessor methods that allow you to examine or
change configuration options that were set at create time. Called with
an argument, the accessor changes the option and returns the option's
previous value. Called without an argument, the accessor returns the
option's current value.

=head2 $on_exit = $manager->on_exit([$new_behavior])

Get or set the "on_exit" option, which specifies what to do with
existing staging servers when the staging manager is destroyed. Valid
values are "terminate", "stop" and "run".

=head2 $reuse_key = $manager->reuse_key([$boolean])

Get or set the "reuse_key" option, which if true uses the same
internally-generated ssh keypair for all running instances. If false,
then a new keypair will be created for each staging server. The
keypair will be destroyed automatically when the staging server
terminates (but only if the staging manager initiates the termination
itself).

=head2 $username = $manager->username([$new_username])

Get or set the username used to log into staging servers.

=head2 $architecture = $manager->architecture([$new_architecture])

Get or set the architecture (i386, x86_64) to use for launching
new staging servers.

=head2 $root_type = $manager->root_type([$new_type])

Get or set the instance root type for new staging servers
("instance-store", "ebs").

=head2 $instance_type = $manager->instance_type([$new_type])

Get or set the instance type to use for new staging servers
(e.g. "t1.micro"). I recommend that you use "m1.small" (the default)
or larger instance types because of the extremely slow I/O of the
micro instance. In addition, micro instances running Ubuntu have a
known bug that prevents them from unmounting and remounting EBS
volumes repeatedly on the same block device. This can lead to hangs
when the staging manager tries to create volumes.

=head2 $reuse_volumes = $manager->reuse_volumes([$new_boolean])

This gets or sets the "reuse_volumes" option, which if true causes the
provision_volumes() call to create staging volumes from existing EBS
volumes and snapshots that share the same staging manager symbolic
name. See the discussion under VM::EC2->staging_manager(), and
VM::EC2::Staging::Manager->provision_volume().

=head2 $name = $manager->image_name([$new_name])

This gets or sets the "image_name" option, which is the AMI ID or AMI
name to use when creating new staging servers. Names beginning with
"ami-" are treated as AMI IDs, and everything else is treated as a
pattern match on the AMI name.

=head2 $zone = $manager->availability_zone([$new_zone])

Get or set the default availability zone to use when creating new
servers and volumes. An undef value allows the staging manager to
choose the zone in a way that minimizes resources.

=head2 $class_name = $manager->volume_class([$new_class])

Get or set the name of the perl package that implements staging
volumes, VM::EC2::Staging::Volume by default. Staging volumes created
by the manager will have this class type.

=head2 $class_name = $manager->server_class([$new_class])

Get or set the name of the perl package that implements staging
servers, VM::EC2::Staging::Server by default. Staging servers created
by the manager will have this class type.

=head2 $boolean = $manager->scan([$boolean])

Get or set the "scan" flag, which if true will cause the zone to be
scanned quickly for existing managed servers and volumes when the
manager is first created.

=head2 $path = $manager->dot_directory([$new_directory])

Get or set the dot directory which holds private key files.

=cut

sub dot_directory {
    my $self = shift;
    my $dir  = $self->dotdir;
    unless (-e $dir && -d $dir) {
	mkdir $dir       or croak "mkdir $dir: $!";
	chmod 0700,$dir  or croak "chmod 0700 $dir: $!";
    }
    return $dir;
}

=head1 Internal Methods

This section documents internal methods that are not normally called
by end-user scripts but may be useful in subclasses. In addition,
there are a number of undocumented internal methods that begin with
the "_" character. Explore the source code to learn about these.

=head2 $ok   = $manager->environment_ok

This performs a check on the environment in which the module is
running. For this module to work properly, the ssh, rsync and dd
programs must be found in the PATH. If all three programs are found,
then this method returns true.

This method can be called as an instance method or class method.

=cut

sub environment_ok {
    my $self = shift;
    foreach (qw(dd ssh rsync)) {
	chomp (my $path = `which $_`);
	return unless $path;
    }
    return 1;
}

=head2 $name = $manager->default_verbosity

Returns the default verbosity level (2: warning+informational messages). This
is overridden using -verbose at create time.

=cut

sub default_verbosity { VERBOSE_INFO }

=head2 $name = $manager->default_exit_behavior

Return the default exit behavior ("stop") when the manager terminates.
Intended to be overridden in subclasses.

=cut

sub default_exit_behavior { 'stop'        }

=head2 $name = $manager->default_image_name

Return the default image name ('ubuntu-precise-12.04') for use in
creating new instances. Intended to be overridden in subclasses.

=cut

sub default_image_name    { 'ubuntu-precise-12.04' };  # launches faster than precise

=head2 $name = $manager->default_user_name

Return the default user name ('ubuntu') for use in creating new
instances. Intended to be overridden in subclasses.

=cut

sub default_user_name     { 'ubuntu'      }

=head2 $name = $manager->default_architecture

Return the default instance architecture ('i386') for use in creating
new instances. Intended to be overridden in subclasses.

=cut

sub default_architecture  { 'i386'        }

=head2 $name = $manager->default_root_type

Return the default instance root type ('instance-store') for use in
creating new instances. Intended to be overridden in subclasses. Note
that this value is ignored if the exit behavior is "stop", in which case an
ebs-backed instance will be used. Also, the m1.micro instance type
does not come in an instance-store form, so ebs will be used in this
case as well.

=cut

sub default_root_type     { 'instance-store'}

=head2 $name = $manager->default_instance_type

Return the default instance type ('m1.small') for use in
creating new instances. Intended to be overridden in subclasses. We default
to m1.small rather than a micro instance because the I/O in m1.small
is far faster than in t1.micro.

=cut

sub default_instance_type { 'm1.small'      }

=head2 $name = $manager->default_reuse_keys

Return the default value of the -reuse_keys argument ('true'). This
value allows the manager to create an ssh keypair once, and use the
same one for all servers it creates over time. If false, then a new
keypair is created for each server and then discarded when the server
terminates.

=cut

sub default_reuse_keys    { 1               }

=head2 $name = $manager->default_reuse_volumes

Return the default value of the -reuse_volumes argument ('true'). This
value instructs the manager to use the symbolic name of the volume to
return an existing volume whenever a request is made to provision a
new one of the same name.

=cut

sub default_reuse_volumes { 1               }

=head2 $path = $manager->default_dot_directory_path

Return the default value of the -dotdir argument
("$ENV{HOME}/.vm-ec2-staging"). This value instructs the manager to
use the symbolic name of the volume to return an existing volume
whenever a request is made to provision a new one of the same name.

=cut

sub default_dot_directory_path {
    my $class = shift;
    my $dir = File::Spec->catfile($ENV{HOME},'.vm-ec2-staging');
    return $dir;
}

=head2 $class_name = $manager->default_volume_class

Return the class name for staging volumes created by the manager,
VM::EC2::Staging::Volume by default. If you wish a subclass of
VM::EC2::Staging::Manager to create a different type of volume,
override this method.

=cut

sub default_volume_class {
    return 'VM::EC2::Staging::Volume';
}

=head2 $class_name = $manager->default_server_class

Return the class name for staging servers created by the manager,
VM::EC2::Staging::Server by default. If you wish a subclass of
VM::EC2::Staging::Manager to create a different type of volume,
override this method.

=cut

sub default_server_class {
    return 'VM::EC2::Staging::Server';
}

=head2 $server = $manager->register_server($server)

Register a VM::EC2::Staging::Server object. Usually called
internally.

=cut

sub register_server {
    my $self   = shift;
    my $server = shift;
    sleep 1;   # AWS lag bugs
    my $zone   = $server->placement;
    $Zones{$zone}{Servers}{$server} = $server;
    $Instances{$server->instance}   = $server;
    return $self->_increment_usage_count($server);
}

=head2 $manager->unregister_server($server)

Forget about the existence of VM::EC2::Staging::Server. Usually called
internally.

=cut

sub unregister_server {
    my $self   = shift;
    my $server = shift;
    my $zone   = eval{$server->placement} or return; # avoids problems at global destruction
    delete $Zones{$zone}{Servers}{$server};
    delete $Instances{$server->instance};
    return $self->_decrement_usage_count($server);
}

=head2 $manager->register_volume($volume)

Register a VM::EC2::Staging::Volume object. Usually called
internally.

=cut

sub register_volume {
    my $self = shift;
    my $vol  = shift;
    $self->_increment_usage_count($vol);
    $Zones{$vol->availabilityZone}{Volumes}{$vol} = $vol;
    $Volumes{$vol->volumeId} = $vol;
}

=head2 $manager->unregister_volume($volume)

Forget about a VM::EC2::Staging::Volume object. Usually called
internally.

=cut

sub unregister_volume {
    my $self = shift;
    my $vol  = shift;
    my $zone = $vol->availabilityZone;
    $self->_decrement_usage_count($vol);
    delete $Zones{$zone}{$vol};
    delete $Volumes{$vol->volumeId};
}

=head2 $pid = $manager->pid([$new_pid])

Get or set the process ID of the script that is running the
manager. This is used internally to detect the case in which the
script has forked, in which case we do not want to invoke the manager
class's destructor in the child process (because it may stop or
terminate servers still in use by the parent process).

=head2 $path = $manager->dotdir([$new_dotdir])

Low-level version of dot_directory(), differing only in the fact that
dot_directory will automatically create the path, including subdirectories.

=cut

=head2 $manager->scan_region

Synchronize internal list of managed servers and volumes with the EC2
region. Called automatically during new() and needed only if servers &
volumes are changed from outside the module while it is running.

=cut

# scan for staging instances in current region and cache them
# into memory
# status should be...
# -on_exit => {'terminate','stop','run'}
sub scan_region {
    my $self = shift;
    my $ec2  = shift || $self->ec2;
    $self->_scan_instances($ec2);
    $self->_scan_volumes($ec2);
}

sub _scan_instances {
    my $self = shift;
    my $ec2  = shift;
    my @instances = $ec2->describe_instances({'tag:StagingRole'     => 'StagingInstance',
					      'instance-state-name' => ['running','stopped']});
    for my $instance (@instances) {
	my $keyname  = $instance->keyName                   or next;
	my $keyfile  = $self->_check_keyfile($keyname)      or next;
	my $username = $instance->tags->{'StagingUsername'} or next;
	my $name     = $instance->tags->{StagingName} || $self->new_server_name;
	my $server   = $self->server_class()->new(
	    -name     => $name,
	    -keyfile  => $keyfile,
	    -username => $username,
	    -instance => $instance,
	    -manager  => $self,
	    );
	$self->register_server($server);
    }
}

sub _scan_volumes {
    my $self = shift;
    my $ec2  = shift;

    # now the volumes
    my @volumes = $ec2->describe_volumes(-filter=>{'tag:StagingRole'   => 'StagingVolume',
						   'status'            => ['available','in-use']});
    for my $volume (@volumes) {
	my $status = $volume->status;
	my $zone   = $volume->availabilityZone;

	my %args;
	$args{-endpoint} = $self->ec2->endpoint;
	$args{-volume}   = $volume;
	$args{-name}     = $volume->tags->{StagingName};
	$args{-fstype}   = $volume->tags->{StagingFsType};
	$args{-mtpt}     = $volume->tags->{StagingMtPt};
	my $mounted;

	if (my $attachment = $volume->attachment) {
	    my $server = $self->find_server_by_instance($attachment->instance);
	    $args{-server}   = $server;
	    ($args{-mtdev},$mounted)  = $server->ping &&
		                        $server->_find_mount($attachment->device);
	}

	my $vol = $self->volume_class()->new(%args);
	$vol->mounted(1) if $mounted;
	$self->register_volume($vol);
    }
}

=head2 $group = $manager->security_group

Returns or creates a security group with the permissions needed used
to manage staging servers. Usually called internally.

=cut

sub security_group {
    my $self = shift;
    return $self->{security_group} ||= $self->_security_group();
}

=head2 $keypair = $manager->keypair

Returns or creates the ssh keypair used internally by the manager to
to access staging servers. Usually called internally.

=cut

sub keypair {
    my $self = shift;
    return $self->{keypair} ||= $self->_new_keypair();
}

sub _security_key {
    my $self = shift;
    my $ec2     = $self->ec2;
    if ($self->reuse_key) {
	my @candidates = $ec2->describe_key_pairs(-filter=>{'key-name' => 'staging-key-*'});
	for my $c (@candidates) {
	    my $name    = $c->keyName;
	    my $keyfile = $self->_key_path($name);
	    return ($c,$keyfile) if -e $keyfile;
	}
    }
    my $name    = $self->_token('staging-key');
    $self->info("Creating keypair $name.\n");
    my $kp          = $ec2->create_key_pair($name) or die $ec2->error_str;
    my $keyfile     = $self->_key_path($name);
    my $private_key = $kp->privateKey;
    open my $k,'>',$keyfile or die "Couldn't create $keyfile: $!";
    chmod 0600,$keyfile     or die "Couldn't chmod  $keyfile: $!";
    print $k $private_key;
    close $k;
    return ($kp,$keyfile);
}

sub _security_group {
    my $self = shift;
    my $ec2  = $self->ec2;
    my @groups = $ec2->describe_security_groups(-filter=>{'tag:StagingRole' => 'StagingGroup'});
    return $groups[0] if @groups;
    my $name = $self->_token('ssh');
    $self->info("Creating staging security group $name.\n");
    my $sg =  $ec2->create_security_group(-name  => $name,
					  -description => "SSH security group created by ".__PACKAGE__
	) or die $ec2->error_str;
    $sg->authorize_incoming(-protocol   => 'tcp',
			    -port       => 'ssh');
    $sg->update or die $ec2->error_str;
    $sg->add_tag(StagingRole  => 'StagingGroup');
    return $sg;

}

=head2 $name = $manager->new_volume_name

Returns a new random name for volumes provisioned without a -name
argument. Currently names are in of the format "volume-12345678",
where the numeric part are 8 random hex digits. Although no attempt is
made to prevent naming collisions, the large number of possible names
makes this unlikely.

=cut

sub new_volume_name {
    return shift->_token('volume');
}

=head2 $name = $manager->new_server_name

Returns a new random name for server provisioned without a -name
argument. Currently names are in of the format "server-12345678",
where the numeric part are 8 random hex digits.  Although no attempt
is made to prevent naming collisions, the large number of possible
names makes this unlikely.

=cut

sub new_server_name {
    return shift->_token('server');
}

sub _token {
    my $self = shift;
    my $base = shift or croak "usage: _token(\$basename)";
    return sprintf("$base-%08x",1+int(rand(0xFFFFFFFF)));
}

=head2 $description = $manager->volume_description($volume)

This method is called to assign a description to newly-created
volumes. The current format is "Staging volume for Foo created by
VM::EC2::Staging::Manager", where Foo is the volume's symbolic name.

=cut

sub volume_description {
    my $self = shift;
    my $vol  = shift;
    my $name = ref $vol ? $vol->name : $vol;
    return "Staging volume for $name created by ".__PACKAGE__;
}

=head2 $manager->debug("Debugging message\n")

=head2 $manager->info("Informational message\n")

=head2 $manager->warn("Warning message\n")

Prints an informational message to standard error if current
verbosity() level allows.

=cut

sub info {
    my $self = shift;
    return if $self->verbosity < VERBOSE_INFO;
    my @lines       = split "\n",longmess();
    my $stack_count = grep /VM::EC2::Staging::Manager/,@lines;
    print STDERR '[info] ',' ' x (($stack_count-1)*3),@_;
}

sub warn {
    my $self = shift;
    return if $self->verbosity < VERBOSE_WARN;
    my @lines       = split "\n",longmess();
    my $stack_count = grep /VM::EC2::Staging::Manager/,@lines;
    print STDERR '[warn] ',' ' x (($stack_count-1)*3),@_;
}

sub debug {
    my $self = shift;
    return if $self->verbosity < VERBOSE_DEBUG;
    my @lines       = split "\n",longmess();
    my $stack_count = grep /VM::EC2::Staging::Manager/,@lines;
    print STDERR '[debug] ',' ' x (($stack_count-1)*3),@_;
}

=head2 $verbosity = $manager->verbosity([$new_value])

The verbosity() method get/sets a flag that sets the level of
informational messages.

=cut

sub verbosity {
    my $self = shift;
    my $d    = ref $self ? $self->verbose : $Verbose;
    if (@_) {
	$Verbose = shift;
	$self->verbose($Verbose) if ref $self;
    }
    return $d;
}


sub _search_for_image {
    my $self = shift;
    my %args = @_;
    my $name = $args{-image_name};

    $self->info("Searching for a staging image...\n");

    my $root_type    = $self->on_exit eq 'stop' ? 'ebs' : $args{-root_type};
    my @arch         = $args{-architecture}     ? ('architecture' => $args{-architecture}) : ();

    my @candidates = $name =~ /^ami-[0-9a-f]+/ ? $self->ec2->describe_images($name)
	                                       : $self->ec2->describe_images({'name'             => "*$args{-image_name}*",
									      'root-device-type' => $root_type,
									      @arch});
    return unless @candidates;
    # this assumes that the name has some sort of timestamp in it, which is true
    # of ubuntu images, but probably not others
    my ($most_recent) = sort {$b->name cmp $a->name} @candidates;
    $self->info("...found $most_recent: ",$most_recent->name,".\n");
    return $most_recent;
}

sub _gather_image_info {
    my $self  = shift;
    my $image = shift;
    return {
	name         =>   $image->name,
	description  =>   $image->description,
	architecture =>   $image->architecture,
	kernel       =>   $image->kernelId  || undef,
	ramdisk      =>   $image->ramdiskId || undef,
	root_device  =>   $image->rootDeviceName,
	block_devices=>   [$image->blockDeviceMapping],
	is_public    =>   $image->isPublic,
	platform     =>   $image->platform,
	virtualizationType => $image->virtualizationType,
	hypervisor         => $image->hypervisor,
	authorized_users => [$image->authorized_users],
    };
}

sub _parse_destination {
    my $self        = shift;
    my $destination = shift;

    my $ec2         = $self->ec2;
    my $dest_manager;
    if (ref $destination && $destination->isa('VM::EC2::Staging::Manager')) {
	$dest_manager = $destination;
    } else {
	my $dest_region = ref $destination && $destination->isa('VM::EC2::Region') 
	    ? $destination
	    : $ec2->describe_regions($destination);
	$dest_region 
	    or croak "Invalid EC2 Region '$dest_region'; usage VM::EC2::Staging::Manager->copy_image(\$image,\$dest_region)";
	my $dest_endpoint = $dest_region->regionEndpoint;
	my $dest_ec2      = VM::EC2->new(-endpoint    => $dest_endpoint,
					 -access_key  => $ec2->access_key,
					 -secret_key  => $ec2->secret) 
	    or croak "Could not create new VM::EC2 in $dest_region";

	$dest_manager = $self->new(-ec2           => $dest_ec2,
				   -scan          => $self->scan,
				   -on_exit       => 'destroy',
				   -instance_type => $self->instance_type);
    }

    return $dest_manager;
}

sub match_kernel {
    my $self = shift;
    my ($src_kernel,$dest) = @_;
    my $dest_manager = $self->_parse_destination($dest) or croak "could not create destination manager for $dest";
    return $self->_match_kernel($src_kernel,$dest_manager,'kernel');
}

sub _match_kernel {
    my $self = shift;
    my ($imageId,$dest_manager) = @_;
    my $home_ec2 = $self->ec2;
    my $dest_ec2 = $dest_manager->ec2;  # different endpoints!
    my $image    = $home_ec2->describe_images($imageId) or return;
    my $type     = $image->imageType;
    my @candidates;

    if (my $name     = $image->name) { # will sometimes have a name
	@candidates = $dest_ec2->describe_images({'name'        => $name,
						  'image-type'  => $type,
						    });
    }
    unless (@candidates) {
	my $location = $image->imageLocation; # will always have a location
	my @path     = split '/',$location;
	$location    = $path[-1];
	@candidates  = $dest_ec2->describe_images(-filter=>{'image-type'=>'kernel',
							    'manifest-location'=>"*/$location"},
						  -executable_by=>['all','self']);
    }
    unless (@candidates) { # go to approximate match
	my $location = $image->imageLocation;
	my @path     = split '/',$location;
	my @kernels = $dest_ec2->describe_images(-filter=>{'image-type'=>'kernel',
							   'manifest-location'=>"*/*"},
						 -executable_by=>['all','self']);
	my %k         = map {$_=>$_} @kernels;
	my %locations = map {my $l    = $_->imageLocation;
			     my @path = split '/',$l;
			     $_       => \@path} @kernels;

	my %level0          = map {$_ => abs(adistr($path[0],$locations{$_}[0]))} keys %locations;
	my %level1          = map {$_ => abs(adistr($path[1],$locations{$_}[1]))} keys %locations;
	@candidates         = sort {$level0{$a}<=>$level0{$b} || $level1{$a}<=>$level1{$b}} keys %locations;
	@candidates         = map {$k{$_}} @candidates;
    }
    return $candidates[0];
}

# find the most likely ramdisk for a kernel based on preponderant configuration of public images
sub _guess_ramdisk {
    my $self = shift;
    my $kernel = shift;
    my $ec2    = $self->ec2;
    my @images = $ec2->describe_images({'image-type' => 'machine',
					'kernel-id'  => $kernel});
    my %ramdisks;

    foreach (@images) {
	$ramdisks{$_->ramdiskId}++;
    }

    my ($highest) = sort {$ramdisks{$b}<=>$ramdisks{$a}} keys %ramdisks;
    return $highest;
}

sub _check_keyfile {
    my $self = shift;
    my $keyname = shift;
    my $dotpath = $self->dot_directory;
    opendir my $d,$dotpath or die "Can't opendir $dotpath: $!";
    while (my $file = readdir($d)) {
	if ($file =~ /^$keyname.pem/) {
	    return $1,$self->_key_path($keyname,$1);
	}
    }
    closedir $d;
    return;
}

sub _select_server_by_zone {
    my $self = shift;
    my $zone = shift;
    my @servers = values %{$Zones{$zone}{Servers}};
    return $servers[0];
}

sub _select_used_zone {
    my $self = shift;
    if (my @servers = $self->servers) {
	my @up     = grep {$_->ping} @servers;
	my $server = $up[0] || $servers[0];
	return $server->placement;
    } elsif (my $zone = $self->availability_zone) {
	return $zone;
    } else {
	return;
    }
}

sub _key_path {
    my $self    = shift;
    my $keyname = shift;
    return File::Spec->catfile($self->dot_directory,"${keyname}.pem")
}

# can be called as a class method
sub _find_server_in_zone {
    my $self = shift;
    my $zone = shift;
    my @servers = sort {$a->ping cmp $b->ping} values %{$Zones{$zone}{Servers}};
    return unless @servers;
    return $servers[-1];
}

sub _servers {
    my $self      = shift;
    my $endpoint  = shift; # optional
    my @servers   = values %Instances;
    return @servers unless $endpoint;
    return grep {$_->ec2->endpoint eq $endpoint} @servers;
}

sub _lock {
    my $self      = shift;
    my ($resource,$lock_type)  = @_;
    $lock_type eq 'SHARED' || $lock_type eq 'EXCLUSIVE'
	or croak "Usage: _lock(\$resource,'SHARED'|'EXCLUSIVE')";

    $resource->refresh;
    my $tags = $resource->tags;
    if (my $value = $tags->{StagingLock}) {
	my ($type,$pid) = split /\s+/,$value;

	if ($pid eq $$) {  # we've already got lock
	    $resource->add_tags(StagingLock=>"$lock_type $$")
		unless $type eq $lock_type;
	    return 1;
	}
	
	if ($lock_type eq 'SHARED' && $type eq 'SHARED') {
	    return 1;
	}

	# wait for lock
	eval {
	    local $SIG{ALRM} = sub {die 'timeout'};
	    alarm(LOCK_TIMEOUT);  # we get lock eventually one way or another
	    while (1) {
		$resource->refresh;
		last unless $resource->tags->{StagingLock};
		sleep 1;
	    }
	};
	alarm(0);
    }
    $resource->add_tags(StagingLock=>"$lock_type $$");
    return 1;
}

sub _unlock {
    my $self     = shift;
    my $resource = shift;
    $resource->refresh;
    my $sl = $resource->tags->{StagingLock} or return;
    my ($type,$pid) = split /\s+/,$sl;
    return unless $pid eq $$;
    $resource->delete_tags('StagingLock');
}

sub _safe_update_tag {
    my $self = shift;
    my ($resource,$tag,$value) = @_;
    $self->_lock($resource,'EXCLUSIVE');
    $resource->add_tag($tag => $value);
    $self->_unlock($resource);
}

sub _safe_read_tag {
    my $self = shift;
    my ($resource,$tag) = @_;
    $self->_lock($resource,'SHARED');
    my $value = $resource->tags->{$tag};
    $self->_unlock($resource);
    return $value;
}


sub _increment_usage_count {
    my $self     = shift;
    my $resource = shift;
    $self->_lock($resource,'EXCLUSIVE');
    my $in_use = $resource->tags->{'StagingInUse'} || 0;
    $resource->add_tags(StagingInUse=>$in_use+1);
    $self->_unlock($resource);
    $in_use+1;
}

sub _decrement_usage_count {
    my $self     = shift;
    my $resource = shift;

    $self->_lock($resource,'EXCLUSIVE');
    my $in_use = $resource->tags->{'StagingInUse'} || 0;
    $in_use--;
    if ($in_use > 0) {
	$resource->add_tags(StagingInUse=>$in_use);
    } else {
	$resource->delete_tags('StagingInUse');
	$in_use = 0;
    }
    $self->_unlock($resource);
    return $in_use;
}

sub _dots_cmd {
    my $self = shift;
    return '' unless $self->verbosity == VERBOSE_INFO;
    my ($fh,$dots_script) = tempfile('dots_XXXXXXX',SUFFIX=>'.pl',UNLINK=>1,TMPDIR=>1);
    print $fh $self->_dots_script;
    close $fh;
    chmod 0755,$dots_script;
    return "2>&1|$dots_script t";
}

sub _upload_dots_script {
    my $self   = shift;
    my $server = shift;
    my $fh     = $server->scmd_write('cat >/tmp/dots.pl');
    print $fh $self->_dots_script;
    close $fh;
    $server->ssh('chmod +x /tmp/dots.pl');
}

sub _dots_script {
    my $self = shift;
    my @lines       = split "\n",longmess();
    my $stack_count = grep /VM::EC2::Staging::Manager/,@lines;
    my $spaces      = ' ' x (($stack_count-1)*3);
    return <<END;
#!/usr/bin/perl
my \$mode = shift || 'b';
print STDERR "[info] ${spaces}One dot equals ",(\$mode eq 'b'?'100 Mb':'100 files'),': ';
my \$b; 
 READ:
    while (1) { 
	do {read(STDIN,\$b,1e5) || last READ for 1..1000} if \$mode eq 'b';
	do {<> || last READ                  for 1.. 100} if \$mode eq 't';
	print STDERR '.';
}
print STDERR ".\n";
END
}

sub DESTROY {
    my $self = shift;
    if ($$ == $self->pid) {
	my $action = $self->on_exit;
	$self->terminate_all_servers if $action eq 'terminate';
	$self->stop_all_servers      if $action eq 'stop';
    }
    delete $Managers{$self->ec2->endpoint};
}



1;


=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Staging::Server>
L<VM::EC2::Staging::Volume>
L<migrate-ebs-image.pl>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

