package VM::EC2::Staging::Volume;

=head1 NAME

VM::EC2::Staging::Volume - High level functions for provisioning and populating EC2 volumes

=head1 SYNOPSIS

 use VM::EC2::Staging::manager;

 # get a new staging manager
 my $ec2     = VM::EC2->new;
 my $staging = $ec2->staging_manager();                                         );

 my $vol1 = $staging->get_volume(-name => 'Backup',
                                 -fstype => 'ext4',
                                 -size   => 11,
                                 -zone   => 'us-east-1a');

 # make a couple of directories in new volume
 $vol1->mkdir('pictures');
 $vol1->mkdir('videos');

 # use rsync to copy local files onto a subdirectory of this volume
 $vol1->put('/usr/local/my_pictures/' =>'pictures');
 $vol1->put('/usr/local/my_videos/'   =>'videos');

 # use rsync to to copy a set of files on the volume to a local directory 
 mkdir('/tmp/jpegs');
 $vol1->get('pictures/*.jpg','/tmp/jpegs');

 # note that these commands are executed on the remote server as root!
 @listing = $vol1->ls('-r','pictures');
 $vol1->chown('fred','pictures');
 $vol1->chgrp('nobody','pictures');
 $vol1->chmod('0700','pictures');
 $vol1->rm('-rf','pictures/*');
 $vol1->rmdir('pictures');

 # get some information about the volume
 my $mtpt     = $vol->mtpt;
 my $mtdev    = $vol->mtdev;
 my $mounted  = $vol->mounted;
 my $server   = $vol->server;

 # detach the volume
 $vol->detach;

 # delete the volume entirely
 $vol->delete;

=head1 DESCRIPTION

This is a high-level interface to EBS volumes which is used in
conjunction with VM::EC2::Staging::Manager and
VM::EC2::Staging::Server. It is intended to ease the process of
allocating and managing EBS volumes, and provides for completely
automated filesystem creation, directory management, and data transfer
to and from the volume.

You can use staging volumes without having to manually create and
manage the instances needed to manipulate the volumes. As needed, the
staging manager will create the server(s) needed to execute the
desired actions on the volumes.

Staging volumes are wrappers around VM::EC2::Volume, and have all the
methods associated with those objects. In addition to the standard EC2
volume characteristics, each staging volume in an EC2 region has a
symbolic name, which can be used to retrieve previously-created
volumes without remembering their volume ID. This symbolic name is
stored in the tag StagingName. Volumes also have a filesystem type
(stored in the tag StagingFsType). When a volume is mounted on a
staging server, it will also have a mount point on the file system,
and a mounting device (e.g. /dev/sdf1).

=cut

use strict;
use VM::EC2;
use Carp 'croak';
use File::Spec;

use overload
    '""'     => sub {my $self = shift;
 		     return $self->short_name;  # "inherited" from VM::EC2::Volume
},
    fallback => 1;

my $Volume = 1;  # for anonymously-named volumes
our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;
    my ($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
    return if $func_name eq 'DESTROY';
    my $vol = eval {$self->ebs} or croak overload::StrVal($self)," no longer connected to an Amazon EBS object, so can't execute $func_name()";
    return $vol->$func_name(@_);
}

sub can {
    my $self = shift;
    my $method = shift;

    my $can  = $self->SUPER::can($method);
    return $can if $can;

    my $ebs  = $self->ebs or return;
    return $ebs->can($method);
}

=head1 Staging Volume Creation

Staging volumes are created via a staging manager's get_volume() or
provision_volume() methods. See L<VM::EC2::Staging::Manager>. One
typical invocation is:

 my $ec2     = VM::EC2->new;
 my $manager = $ec2->staging_manager();                                         );
 my $vol = $manager->get_volume(-name => 'Backup',
                                -fstype => 'ext4',
                                -size   => 5,
                                -zone   => 'us-east-1a');

This will either retrieve an existing volume named "Backup", or, if
none exists, create a new one using the provided specification. Behind
the scenes, a staging server will be allocated to mount the
volume. The manager tries to conserve resources, and so will reuse a
suitable running staging server if one is available.

The other typical invocation is:

 my $vol = $manager->provision_volume(-name => 'Backup',
                                      -fstype => 'ext4',
                                      -size   => 5,
                                      -zone   => 'us-east-1a');

This forces creation of a new volume with the indicated
characteristics. If a volume of the same name already exists, this
method will die with a fatal error (to avoid this, either wrap in an
eval, or leave off the -name argument and let the manager pick a
unique name for you).

=cut

=head1 Volume Information

The methods in this section return status information about the staging volume.

=head2 $name = $vol->name([$newname])

Get/set the symbolic name associated with this volume.

=head2 $mounted = $vol->mounted

Returns true if the volume is currently mounted on a server.

=cut

sub mounted {
    my $self = shift;
    my $m    = $self->{mounted};
    $self->{mounted} = shift if @_;
    return $m;
}

=head2 $type = $vol->fstype

Return the filesystem type requested at volume creation time.

=head2 $server = $vol->server

Get the server associated with this volume, if any.

=head2 $device = $vol->mtdev

Get the device that the volume is attached to, e.g. /dev/sdf1. If the
volume is not attached to a server, returns undef.

=head2 $device = $vol->mtpt

Get the mount point for this volume on the attached server. If the
volume is not mounted, returns undef.

=head2 $ebs_vol = $vol->ebs

Get the underlying EBS volume associated with the staging volume object.

=head2 $manager = $vol->manager

Return the VM::EC2::Staging::Manager which manages this volume.

=cut

=head2 $string = $vol->fstab_line();

This method returns the line in /etc/fstab that would be necessary to
mount this volume on the server to which it is currently attached at
boot time. For example:

 /dev/sdf1 /mnt/staging/Backups ext4 defaults,nobootwait 0 2

You can add this to the current server's fstab using the following
code fragment:

 my $server = $vol->server;
 my $fh = $server->scmd_write('sudo -s "cat >>/etc/fstab"');
 print $fh $vol->fstab,"\n";
 close $fh;

=cut

sub fstab_line {
    my $self = shift;
    return join "\t",$self->mtdev,$self->mtpt,$self->fstype,'defaults,nobootwait',0,2;
}


# $stagingvolume->new({-server => $server,  -volume => $volume,
#                      -mtdev => $device,   -mtpt   => $mtpt,
#                      -name => $name,      -fstype => $fstype})
#
sub new {
    my $self = shift;
    my $args;
    if (ref $_[0]) {
	$args = shift;
    } else {
	my %args = @_;
	$args    = \%args;
    }
    return bless $args,ref $self || $self;
}

# accessors:
# sub volume
# sub mtpt
# sub name
# sub manager
foreach (qw(-server -volume -name -endpoint -mtpt -mtdev -fstype)) {
    (my $function = $_) =~ s/^-//;
    eval <<END;
    sub $function {
	my \$self = shift;
	my \$d    = \$self->{$_};
	\$self->{$_} = shift if \@_;
	return \$d;
    }
END
}

sub ebs  {shift->volume(@_)}
sub manager {
    my $self = shift;
    my $ep   = $self->endpoint;
    return VM::EC2::Staging::Manager->find_manager($ep);
}

=head2 $type = $vol->get_fstype

Return the volume's actual filesystem type. This can be different from
the requested type if it was later altered by running mkfs on the
volume, or the contents of the disk were overwritten by a block-level
dd command. As a side effect, this method sets fstype() to the current
correct value.

=cut

# look up our filesystem type
sub get_fstype {
    my $self = shift;
    return $self->fstype if $self->fstype;
    return 'raw'         if $self->mtpt eq 'none';

    $self->_spin_up;
    my $dev    = $self->mtdev;
    my $blkid  = $self->server->scmd("sudo blkid -p $dev");
    my ($type) = $blkid =~ /TYPE="([^"]+)"/;
    $self->fstype($type);
    return $type || 'raw';
}

sub _spin_up {
    my $self = shift;
    my $nomount = shift;
    unless ($self->server) {
	$self->manager->info("provisioning server to mount $self\n");
	my $server = $self->manager->get_server_in_zone($self->availabilityZone);
	$self->server($server);
    }
    unless ($self->server->status eq 'running') {
	$self->manager->info("Starting server to mount $self\n");
	$self->server->start;
    }
    $self->server->mount_volume($self) unless $nomount || $self->mounted();
}

#sub as_string {
#    my $self = shift;
#    return $self->server.':'.$self->mtpt;
#}

=head1 Lifecycle Methods

The methods in this section control the state of the volume.

=head2 $snapshot = $vol->create_snapshot('description')

Create a VM::EC2::Snapshot of the volume with an optional
description. This differs from the VM::EC2::Volume method of the same
name in that it is aware of the mount state of the volume and will
first try to unmount it so that the snapshot is clean. After the
snapshot is started, the volume is remounted.

=cut

sub create_snapshot {
    my $self = shift;
    my $description = shift;
    if (my $server = $self->server) {
	my ($snap) = $server->create_snapshot($self => $description);
	return $snap;
    } else {
	$self->ebs->create_snapshot($description);
    }
}

=head2 $snapshot = $vol->snapshot('description')

Identical to create_snapshot(), but the method name is shorter.

=cut

sub snapshot {shift->create_snapshot(@_)}

=head2 $vol->mount($server [,$mtpt])

=head2 $vol->mount()

Mount the volume on the indicated VM::EC2::Staging::Server, optionally
at a named mount point on the file system. If the volume is already
attached to a different server, it will be detached first. If any of
these step fails, the method will die with a fatal error.

When called with no arguments, the volume is automounted on a staging
server, creating or starting the server if necessary.

=cut

# mount the volume on a server
sub mount {
    my $self = shift;
    unless (@_) {
	return $self->_spin_up;
    }
    my ($server,$mtpt) = @_;
    if (my $existing_server = $self->server) {
	if ($existing_server eq $server) {
	    $self->unmount;
	} else {
	    $self->detach;
	}
    }
    $server->mount_volume($self,$mtpt);
}

=head2 $vol->unmount()

Unmount the volume from wherever it is, but leave it attached to the
staging server. If the volume is not already mounted, nothing happens.

Note that it is possible for a volume to be mounted on a I<stopped>
server, in which case the server will be started and the volume only
unmounted when it is up and running.

=cut

# unmount volume from wherever it is
sub unmount {
    my $self = shift;
    my $server = $self->server or return;
    # guarantees that server is running, but avoids mounting the disk
    # prior to unmounting it again.
    $self->_spin_up('nomount'); 
    $server->unmount_volume($self);
    $self->mtpt(undef);
}

sub umount { shift->unmount(@_) }  # because I forget

=head2 $vol->detach()

Unmount and detach the volume from its current server, if any.

Note that it is possible for a volume to be mounted on a I<stopped>
server, in which case the server will be started and the volume only
unmounted when it is up and running.

=cut

sub detach {
    my $self = shift;
    my $server = $self->server or return;
    $self->current_status eq 'in-use' or return;
    $self->unmount;  # make sure we are not mounted; this might involve starting a server
    $server->info("detaching $self\n");
    my $status = $self->volume->detach;
    $self->mtpt(undef);
    $self->mtdev(undef);
    $self->server(undef);
    return $status;
}

=head2 $vol->delete()

Delete the volume entirely. If it is mounted and/or attached to a
server, it will be unmounted/detached first. If any steps fail, the
method will die with a fatal error.

=cut

# remove volume entirely
sub delete {
    my $self = shift;
    my $status = $self->current_status;
    if ($status eq 'in-use') {
	my $server = $self->server 
	    || $self->manager->find_server_by_instance($self->attachment->instanceId);
	$server->delete_volume($self) if $server;
    } elsif ($status eq 'available') {
	$self->ec2->delete_volume($self);
    } else {
	croak "Cannot delete volume, status is $status";
    }
    $self->mounted(0);
    $self->mtpt(undef);
    $self->mtdev(undef);
    $self->fstype(undef);
}

=head1 Data Operations

The methods in this section operate on the contents of the volume.  By
and large, they operate with root privileges on the server machine via
judicious use of sudo. Elevated permissions on the local machine (on
which the script is running) are not needed.

=cut

=head2 $vol->get($source_on_vol_1,$source_on_vol_2,...,$dest)

Invoke rsync() on the server to copy files & directories from the
indicated source locations on the staging volume to the
destination. Source paths can be relative paths, such as
"media/photos/vacation", in which case they are relative to the top
level of the mounted volume, or absolute paths, such as
"/usr/local/media/photos/vacation", in which case they are treated as
absolute paths on the server on which the volume is mounted.

The destination can be a path on the local machine, a host:/path on a
remote machine, a staging server and path in the form $server:/path,
or a staging volume and path in the form "$volume/path". See
L<VM::EC2::Staging::Manager/Instance Methods for Managing Staging Volumes> 
for more formats you can use.

As a special case, if you invoke get() with a
single argument:

 $vol->get('/tmp/foo')

Then the entire volume will be rsynced into the destination directory
/tmp/foo.

=cut

# $vol->get($source1,$source2,$source3....,$dest)
# If $source not in format hostname:/path then 
# volume will be appended to it.
sub get {
    my $self = shift;
    croak 'usage: ',ref($self),'->get($source1,$source2,$source3....,$dest_path)'
	unless @_;
    unshift @_,'./' if @_ < 2;
    
    my $dest   = pop;
    my $server = $self->server or croak "no staging server available";

    $self->mounted or croak "Volume is not currently mounted";
    my @source = $self->_rel2abs(@_);
    $server->rsync(@source,$dest);
}

=head2 $vol->copy($source_on_vol_1,$source_on_vol_2,...,$dest)

This is an alias for get(). It is intended to make it easier to read the
intent of this command:

 $source_volume->copy($destination_volume);

Which basically makes a copy of $source_volume onto
$destination_volume.

=cut

sub copy { shift->get(@_) }

=head2 $vol->put($source1,$source2,$source3,...,$dest_on_volume)

Invoke rsync() on the server to copy files & directories from the
indicated source locations a destination located on the staging
volume. The rules for paths are the same as for the get() method and as described in
L<VM::EC2::Staging::Manager/Instance Methods for Managing Staging Volumes> .

As a special case, if you invoke put() with a single argument:

 $vol->put('/tmp/foo')

Then the local directory /tmp/foo will be copied onto the top level of
the staging volume. To do something similar with multiple source
directories, use '/' or '.' as the destination:

 $vol->put('/tmp/pictures','/tmp/audio' => '/');

=cut

# $vol->put($source1,$source2,$source3....,$dest)
# If $dest not in format hostname:/path then 
# volume will be appended to it.
sub put {
    my $self = shift;
    croak 'usage: ',ref($self),'->put($source1,$source2,$source3....,$dest_path)'
	unless @_;
    push @_,'.' if @_ < 2;

    my $dest = pop;
    my @source = @_;

    $self->_spin_up;
    my $server = $self->server or croak "no staging server available";
    ($dest)    = $self->_rel2abs($dest);
    $server->rsync(@source,$dest);
}

=head2 $vol->dd($destination_volume)

The dd() method performs a block level copy of the volume's disk onto
the destination. The destination must be another staging volume.

=cut

sub dd   { 
    my $self = shift;
    unshift @_,$self if @_ < 2;
    $self->_spin_up;
    $self->server->dd(@_);
}

=head2 $output = $vol->cmd($cmd,@args)

This method runs command $cmd on the server that is mounting the
volume using ssh. Before the command is run, the working directory is
changed to the top level of the volume's mount point. Any arguments,
switches, etc you wish to pass to the command can be provided as
@args. The output of the command is returned as a string in a scalar
context, or an array of lines in a list context.

Example:

 @log = $volume->cmd('tar cvf /tmp/archive.tar .');

=head2 $result = $vol->ssh($cmd,@args)

This is similar to cmd(), except that the output of the command is
sent to STDOUT and the method returns true if the command executed
succcessfully on the remote machine. The cmd() and ssh() methods are
equivalent to backticks are system() respectively.

Example:

 $volume->ssh('gzip /tmp/archive.tar') or die "couldn't compress archive";

=head2 $output  = $vol->df(@args)

=head2 $output  = $vol->ls(@args)

=head2 $success = $vol->mkdir(@args)

=head2 $success = $vol->chown(@args)

=head2 $success = $vol->chgrp(@args)

=head2 $success = $vol->chmod(@args)

=head2 $success = $vol->cp(@args)

=head2 $success = $vol->mv(@args)

=head2 $success = $vol->rm(@args)

=head2 $success = $vol->rmdir(@args)

Each of these methods performs the same function as the like-named
command-line function, after first changing the working directory to
the top level of the volume. They behave as shown in the pseudocode
below:

 chdir $vol->mtpt;
 sudo  $method @args

The df() and ls() methods return the output of their corresponding
commands. In a scalar context each method returns a string
corresponding to the output of running the command on the server to
which the volume is attached. In a list context, the methods return
one element per line of output.

For example:

 my $free      = $volume->df('.');  # free on current directory
 my ($percent) = $free =~ /(\d+)%/;
 warn "almost out of space" if $percent > 90;

The other methods return a boolean value indicating successful
execution of the command on the remote machine.

Command line switches can be passed along with other arguments:

 $volume->mkdir('-p','media/photos/vacation');
 $volume->chown('-R','fred','media');

With the exception of df, each of these commands runs as the
superuser, so be careful how you call them.

You may run your own commands using the cmd() and ssh() methods. The
former returns the output of the command. The latter returns a success
code:

 @log = $volume->cmd('tar cvf /tmp/archive.tar .');
 $volume->ssh('gzip /tmp/archive.tar') or die "couldn't compress archive";

Before calling any of these methods, the volume must be mounted and
its server running. A fatal error will occur otherwise.

=cut

sub df    { shift->_cmd('df',@_)    }
sub ls    { shift->_cmd('sudo ls',@_)    }
sub mkdir { shift->_ssh('sudo mkdir',@_) }
sub chown { shift->_ssh('sudo chown',@_) }
sub chgrp { shift->_ssh('sudo chgrp',@_) }
sub chmod { shift->_ssh('sudo chmod',@_) }
sub rm    { shift->_ssh('sudo rm',@_)    }
sub rmdir { shift->_ssh('sudo rmdir',@_) }
sub cp    { shift->_ssh('sudo cp',@_) }
sub mv    { shift->_ssh('sudo mv',@_) }

sub _cmd {
    my $self = shift;
    my $cmd          = shift;
    my @args         = map {quotemeta} @_;
    $self->mounted or croak "Volume is not currently mounted";
    my $mtpt         = $self->mtpt;
    $self->server->scmd("cd '$mtpt'; $cmd @args");
}

sub _ssh {
    my $self = shift;
    my $cmd          = shift;
    my @args         = map {quotemeta} @_;
    $self->mounted or croak "Volume is not currently mounted";
    my $mtpt         = $self->mtpt;
    $self->server->ssh("cd '$mtpt'; $cmd @args");
}

sub cmd { shift->_cmd(@_) }
sub ssh { shift->_ssh(@_) }

sub _rel2abs {
    my $self  = shift;
    my @paths = @_;

    my $server = $self->server or croak "no server";

    my @result;
    foreach (@paths) {
	if (/^([^:]+):(.+)$/) {
	    push @result,$_;
	}
	elsif (m!^/!) { # absolute path
	    push @result,"$server:".$_;
	} 
	else {
	    my $p = "$server:".File::Spec->rel2abs($_,$self->mtpt);
	    $p   .= '/' if m!/$!;
	    push @result,$p;
	}
    }
    return @result;
}

sub _select_zone {
    my $self = shift;
    my $ec2  = shift;
    if (my @servers = VM::EC2::Staging::Server->_servers($ec2->endpoint)) {
	return $servers[0]->instance->placement;
    } else {
	my @zones = $ec2->describe_availability_zones;
	return $zones[rand @zones];
    }
}

sub _get_vol_zone {
    my $self = shift;
    my ($ec2,$volid) = @_;
    my $volume = $ec2->describe_volumes($volid) or croak "unknown volumeid $volid";
    return $volume->availabilityZone;
}

sub DESTROY {
    my $self    = shift;
    my $manager = $self->manager or return;
    my $ebs     = $self->ebs     or return;
    $manager->unregister_volume($self);
}

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Staging::Manager>
L<VM::EC2::Staging::Server>
L<VM::EC2::Instance>
L<VM::EC2::Volume>
L<VM::EC2::Snapshot>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

1;
