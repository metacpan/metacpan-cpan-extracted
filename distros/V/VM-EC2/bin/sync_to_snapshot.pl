#!/usr/bin/perl

# An example of creating a data snapshots
# Steps:
#     1. Provision a new server.
#     2. Create new data volume, attach and mount it.
#     3. Rsync the indicated data over
#     4. Unmount the volume, detach it.
#     5. Save the snapshot.
#     6. Delete the volume
#     7. Terminate the server.

use strict;
use VM::EC2;
use Getopt::Long;
use File::Find;
use File::Basename 'basename';
use constant GB => 1_073_741_824;

$SIG{INT}=$SIG{TERM}= sub {cleanup(); exit 0};

my $Program_name = basename($0);
$Program_name    =~ s/\.pl$//;

my($Snapshot_name,$Filesystem,$Image,$Type,$Username,$Access_key,$Secret_key);
GetOptions('snapshot=s'    => \$Snapshot_name,
	   'filesystem=s'  => \$Filesystem,
	   'image=s'       => \$Image,
	   'username=s'    => \$Username,
	   'type=s'        => \$Type,
	   'access_key=s'  => \$Access_key,
	   'secret_key=s'  => \$Secret_key) or die <<USAGE;
Usage: $Program_name [options] files/directories to copy...
Rsync the indicated files and directories to Amazon EC2 and store
in a named EBS snapshot. Snapshot will be incrementally updated
if it already exists. The Version tag will be updated.

This will use the default EC2 endpoint URL unless environment variable
EC2_URL is set.

Options:
      --snapshot    Snapshot name (required)
      --access_key  EC2 access key
      --secret_key  EC2 secret key
      --image       Server AMI ID (defaults to ami-ccf405a5, Ubuntu Maverick 32bit)
      --type        Server type (defaults to m1.small)
      --username    Username for logging into instance ("ubuntu")
      --filesystem  Type of filesystem to create (bfs,cramfs,ext*,minix,ntfs,vfat,msdos).
                    Anything with a /sbin/mkfs.* executable on the server side will work.
                    Defaults to ext4.

Options can be abbreviated.
USAGE
    ;

#setup defaults
$ENV{EC2_ACCESS_KEY} = $Access_key if defined $Access_key;
$ENV{EC2_SECRET_KEY} = $Secret_key if defined $Secret_key;
$Filesystem        ||= 'ext4';
$Image             ||= 'ami-ccf405a5';
$Type              ||= 'm1.small';
$Username          ||= 'ubuntu';

$Snapshot_name or die "Please provide a snapshot name. Run $Program_name --help for help.\n";
my @locations    = @ARGV;

# These are variables that contain EC2 objects that need to be destroyed
# when script is done.
my ($ec2,$KeyPair,$KeyFile,$Group,$Volume,$Instance);

eval {

    $ec2 = VM::EC2->new() or die "Can't create new VM::EC2";

# find how large a volume we'll need.
    print STDERR "Calculating needed size of staging volume...\n";
    my $bytes_needed = 0;
    find(sub {$bytes_needed += -s $_},@locations);

# add 15% overhead for filesystem
    $bytes_needed *= 1.15;

# and convert to GB
    my $gb = int(0.5+$bytes_needed/GB);
    $gb    = 1 if $gb < 1;

    die "Required volume exceeds EC2 1TB limit"
	if $gb > 1024;

# Provision the volume
    print STDERR "Provisioning a $gb GB volume...\n";
    my($volume,$needs_mkfs,$needs_resize) = provision_volume($gb,$Snapshot_name);
    $Volume = $volume;

# Create a temporary key for ssh'ing
    print STDERR "Creating a temporary ssh key...\n";
    my $keypairname = "${Program_name}_$$";
    $KeyFile        = File::Spec->catfile(File::Spec->tmpdir,"$keypairname.pem");
    $KeyPair        = $ec2->create_key_pair($keypairname);
    my $private_key = $KeyPair->privateKey;
    open my $k,'>',$KeyFile or die "Couldn't create $KeyFile: $!";
    chmod 0600,$KeyFile     or die "Couldn't chmod  $KeyFile: $!";
    print $k $private_key;
    close $k;

# Create a temporary security group for ssh'ing
    print STDERR "Creating a temporary security group with ssh enabled...\n";
    $Group          = $ec2->create_security_group(-name        => "${Program_name}_$$",
						  -description => "Temporary security group created by $Program_name"
	) or die $ec2->error_str;
    $Group->authorize_incoming(-protocol   => 'tcp',
			       -port       => 'ssh');
    $Group->update or die $ec2->error_str;

# Provision an instance in the same availability zone
    print STDERR "Provisioning staging instance...\n";
    my $zone        = $Volume->availabilityZone;
    $Instance       = $ec2->run_instances(-image_id => $Image,
					  -zone     => $zone,
					  -key_name => $KeyPair,
					  -instance_type     => $Type,
					  -security_group_id => $Group) or die $ec2->error_str;
    $Instance->add_tag(Name => "Staging instance for snapshot $Snapshot_name created by $Program_name");

# wait until the instance is running and the ssh daemon is responding...
    print STDERR "Waiting for instance to come up. This may take a while...\n";
    $ec2->wait_for_instances($Instance);
    $Instance->current_status eq 'running'      or die "Instance $Instance, status = ",$Instance->current_status;
    wait_for_ssh_daemon();  # we may die on this step
    
    my $device = eval{unused_device()}          or die "Couldn't find suitable device to attach";
    
# attach and initialize volume
    print STDERR "Attaching staging volume...\n";
    my $s = $Instance->attach_volume($Volume=>$device)  or die "Couldn't attach $Volume to $Instance via $device";
    $ec2->wait_for_attachments($s)                      or die "Couldn't attach $Volume to $Instance via $device";
    $s->current_status eq 'attached'                    or die "Couldn't attach $Volume to $Instance via $device";

    if ($needs_resize) {
	die "Sorry, but can only resize ext volumes " unless $Filesystem =~ /^ext/;
	print STDERR "Resizing previously-snapshotted volume to $gb GB...\n";
	ssh("sudo /sbin/resize2fs $device");
    } elsif ($needs_mkfs) {
	print STDERR "Making $Filesystem filesystem on staging volume...\n";
	ssh("sudo /sbin/mkfs.$Filesystem $device");
    }

# do the rsync
    print STDERR "Mounting staging volume...\n";
    ssh("sudo mkdir -p /mnt/transfer; sudo mount $device /mnt/transfer; sudo chown $Username /mnt/transfer");

    print STDERR "Beginning rsync...\n";
    my $Host = $Instance->dnsName;
    system "rsync -Ravz -e'ssh -o \"StrictHostKeyChecking no\" -i $KeyFile -l $Username' @locations $Host:/mnt/transfer";

    ssh('sudo umount /mnt/transfer');
    $Instance->detach_volume($Volume);

    # snapshot stuff
    my $version = 1;
    if (my $snap = $Volume->from_snapshot) {
	$version = $snap->tags->{Version} || 0;
	$version++;
    }

    print STDERR "Creating snapshot $Snapshot_name version $version...\n";
    my $snap = $Volume->create_snapshot($Snapshot_name);
    $snap->add_tags(Version => $version);
    $snap->add_tags(Name    => $Snapshot_name);
    print "Created snap $snap\n";
};

warn $@ if $@;
cleanup();

exit 0;

sub ssh {
    my @cmd   = @_;
    $Instance or die "Remote instance not set up correctly";
    my $host = $Instance->dnsName;

    my $pid = open my $kid,"-|"; #this does a fork
    die "Couldn't fork: $!" unless defined $pid;
    if ($pid) {
	my @results;
	while (<$kid>) {
	    push @results,$_;
	}
	close $kid;
	die "ssh failed with status ",$?>>8 unless $?==0;
	if (wantarray) {
	    chomp(@results);
	    return @results;
	} else {
	    return join '',@results;
	}
    }

    # in child
    exec '/usr/bin/ssh','-o','CheckHostIP no','-o','StrictHostKeyChecking no','-i',$KeyFile,'-l',$Username,$host,@cmd;
}

sub unused_device {
    my %devices = map {$_=>1} ssh('ls /dev/*d[a-z][0-9]*');
    my $base    = $devices{'/dev/sda1'}  ? '/dev/sd'
	         :$devices{'/dev/xvda1'} ? '/dev/xvd'
		 :die "can't figure out whether to use /dev/sd or /dev/xvd";
    for my $major ('f'..'p') {
	for my $minor (1..15) {
	    my $candidate = $base.$major.$minor;
	    return $candidate unless $devices{$candidate};
	}
    }
}

sub provision_volume {
    my ($size,$snapshot_name)  = @_;
    my @zones = $ec2->describe_availability_zones({state=>'available'});
    my $zone  = $zones[rand @zones];

    my @snaps = sort {$b->startTime cmp $a->startTime} $ec2->describe_snapshots(-owner  => $ec2->account_id,
										-filter => {description=>$snapshot_name});
    my ($vol,$needs_mkfs,$needs_resize);
    if (@snaps) {
	my $snap = $snaps[0];
	print STDERR "Reusing existing snapshot $snap...\n";
	my $s    = $size > $snap->volumeSize ? $size : $snap->volumeSize;
	$vol = $snap->create_volume(-availability_zone=>$zone,
				    -size             => $s);
	$needs_resize = $snap->volumeSize < $s;
    } else {
	$vol = $ec2->create_volume(-availability_zone=>$zone,
				   -size             =>$size);
	$needs_mkfs++;
    }
    return unless $vol;
    $vol->add_tag(Name=>"Staging volume for snapshot $snapshot_name created by $Program_name");
    return ($vol,$needs_mkfs,$needs_resize);
}

sub wait_for_ssh_daemon {
    open SAVERR,">&STDERR";
    open STDERR,">/dev/null";  # inhibit error messages temporarily
    eval {
	local $SIG{ALRM} = sub {die 'timeout'};
	alarm(60);  # do not wait more than one minute
	while (!eval{ssh('echo running')}) {sleep 2; }
	alarm(0);
    };
    open STDERR,">&SAVERR";
    if ($@ =~ /timeout/) {
	die "Timed out while waiting for ssh daemon to come up";
    }
}

sub cleanup {
    return unless $ec2;

    print STDERR "Deleting temporary keypair...\n";
    $ec2->delete_key_pair($KeyPair)        if $KeyPair;
    unlink $KeyFile                        if -e $KeyFile;

    print STDERR "Deleting staging volume...\n";
    $ec2->delete_volume($Volume)           if $Volume;

    print STDERR "Terminating staging instance...\n";
    $Instance->terminate()                 if $Instance;

    if ($Group) {
	print STDERR "Waiting for staging instance to terminate...\n";
	$ec2->wait_for_instances($Instance);
	print STDERR "Deleting temporary security group...\n";
	$ec2->delete_security_group($Group);
    }
    undef $KeyPair;
    undef $Instance;
    undef $Volume;
    undef $KeyFile;
    undef $Group;
}

END {
    cleanup();
}
