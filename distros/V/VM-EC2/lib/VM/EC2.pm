package VM::EC2;

=head1 NAME

VM::EC2 - Perl interface to Amazon EC2, Virtual Private Cloud, Elastic Load Balancing, Autoscaling, and Relational Database services

=head1 SYNOPSIS

NOTE: For information on AWS's VPC, load balancing, autoscaling and relational
databases services, see L<VM::EC2::VPC>, L<VM::EC2::ELB>,
L<VM::EC2::REST::autoscaling>, and
L<VM::EC2::REST::relational_database_service>

 # set environment variables EC2_ACCESS_KEY, EC2_SECRET_KEY and/or EC2_URL
 # to fill in arguments automatically

 ## IMAGE AND INSTANCE MANAGEMENT
 # get new EC2 object
 my $ec2 = VM::EC2->new(-access_key => 'access key id',
                        -secret_key => 'aws_secret_key',
                        -endpoint   => 'http://ec2.amazonaws.com');

 # fetch an image by its ID
 my $image = $ec2->describe_images('ami-12345');

 # get some information about the image
 my $architecture = $image->architecture;
 my $description  = $image->description;
 my @devices      = $image->blockDeviceMapping;
 for my $d (@devices) {
    print $d->deviceName,"\n";
    print $d->snapshotId,"\n";
    print $d->volumeSize,"\n";
 }

 # run two instances
 my @instances = $image->run_instances(-key_name      =>'My_key',
                                       -security_group=>'default',
                                       -min_count     =>2,
                                       -instance_type => 't1.micro')
           or die $ec2->error_str;

 # wait for both instances to reach "running" or other terminal state
 $ec2->wait_for_instances(@instances);

 # print out both instance's current state and DNS name
 for my $i (@instances) {
    my $status = $i->current_status;
    my $dns    = $i->dnsName;
    print "$i: [$status] $dns\n";
 }

 # tag both instances with Role "server"
 foreach (@instances) {$_->add_tag(Role=>'server');

 # stop both instances
 foreach (@instances) {$_->stop}
 
 # find instances tagged with Role=Server that are
 # stopped, change the user data and restart.
 @instances = $ec2->describe_instances({'tag:Role'       => 'Server',
                                        'instance-state-name' => 'stopped'});
 for my $i (@instances) {
    $i->userData('Secure-mode: off');
    $i->start or warn "Couldn't start $i: ",$i->error_str;
 }

 # create an image from both instance, tag them, and make
 # them public
 for my $i (@instances) {
     my $img = $i->create_image("Autoimage from $i","Test image");
     $img->add_tags(Name  => "Autoimage from $i",
                    Role  => 'Server',
                    Status=> 'Production');
     $img->make_public(1);
 }

 ## KEY MANAGEMENT

 # retrieve the name and fingerprint of the first instance's 
 # key pair
 my $kp = $instances[0]->keyPair;
 print $instances[0], ": keypair $kp=",$kp->fingerprint,"\n";

 # create a new key pair
 $kp = $ec2->create_key_pair('My Key');
 
 # get the private key from this key pair and write it to a disk file
 # in ssh-compatible format
 my $private_key = $kp->private_key;
 open (my $f,'>MyKeypair.rsa') or die $!;
 print $f $private_key;
 close $f;

 # Import a preexisting SSH key
 my $public_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8o...';
 $key = $ec2->import_key_pair('NewKey',$public_key);

 ## SECURITY GROUPS AND FIREWALL RULES
 # Create a new security group
 my $group = $ec2->create_security_group(-name        => 'NewGroup',
                                         -description => 'example');

 # Add a firewall rule 
 $group->authorize_incoming(-protocol  => 'tcp',
                            -port      => 80,
                            -source_ip => ['192.168.2.0/24','192.168.2.1/24'});

 # Write rules back to Amazon
 $group->update;

 # Print current firewall rules
 print join ("\n",$group->ipPermissions),"\n";

 ## VOLUME && SNAPSHOT MANAGEMENT

 # find existing volumes that are available
 my @volumes = $ec2->describe_volumes({status=>'available'});

 # back 'em all up to snapshots
 foreach (@volumes) {$_->snapshot('Backup on '.localtime)}

 # find a stopped instance in first volume's availability zone and 
 # attach the volume to the instance using /dev/sdg
 my $vol  = $volumes[0];
 my $zone = $vol->availabilityZone;
 @instances = $ec2->describe_instances({'availability-zone'=> $zone,
                                        'run-state-name'   => $stopped);
 $instances[0]->attach_volume($vol=>'/dev/sdg') if @instances;

 # create a new 20 gig volume
 $vol = $ec2->create_volume(-availability_zone=> 'us-east-1a',
                            -size             =>  20);
 $ec2->wait_for_volumes($vol);
 print "Volume $vol is ready!\n" if $vol->current_status eq 'available';

 # create a new elastic address and associate it with an instance
 my $address = $ec2->allocate_address();
 $instances[0]->associate_address($address);

=head1 DESCRIPTION

This is an interface to the 2014-05-01 version of the Amazon AWS API
(http://aws.amazon.com/ec2). It was written provide access to the new
tag and metadata interface that is not currently supported by
Net::Amazon::EC2, as well as to provide developers with an extension
mechanism for the API. This library will also support the Open Stack
open source cloud (http://www.openstack.org/).

The main interface is the VM::EC2 object, which provides methods for
interrogating the Amazon EC2, launching instances, and managing
instance lifecycle. These methods return the following major object
classes which act as specialized interfaces to AWS:

 VM::EC2::BlockDevice               -- A block device
 VM::EC2::BlockDevice::Attachment   -- Attachment of a block device to an EC2 instance
 VM::EC2::BlockDevice::EBS          -- An elastic block device
 VM::EC2::BlockDevice::Mapping      -- Mapping of a virtual storage device to a block device
 VM::EC2::BlockDevice::Mapping::EBS -- Mapping of a virtual storage device to an EBS block device
 VM::EC2::Group                     -- Security groups
 VM::EC2::Image                     -- Amazon Machine Images (AMIs)
 VM::EC2::Instance                  -- Virtual machine instances
 VM::EC2::Instance::Metadata        -- Access to runtime metadata from running instances
 VM::EC2::Region                    -- Availability regions
 VM::EC2::Snapshot                  -- EBS snapshots
 VM::EC2::Tag                       -- Metadata tags

In addition, there is a high level interface for interacting with EC2
servers and volumes, including file transfer and remote shell facilities:

  VM::EC2::Staging::Manager         -- Manage a set of servers and volumes.
  VM::EC2::Staging::Server          -- A staging server, with remote shell and file transfer
                                        facilities.
  VM::EC2::Staging::Volume          -- A staging volume with the ability to copy itself between
                                        availability zones and regions.

and a few specialty classes:

  VM::EC2::Security::Token          -- Temporary security tokens for granting EC2 access to
                                        non-AWS account holders.
  VM::EC2::Security::Credentials    -- Credentials for use by temporary account holders.
  VM::EC2::Security::Policy         -- Policies that restrict what temporary account holders
                                        can do with EC2 resources.
  VM::EC2::Security::FederatedUser  -- Account name information for temporary account holders.

Lastly, there are several utility classes:

 VM::EC2::Generic                   -- Base class for all AWS objects
 VM::EC2::Error                     -- Error messages
 VM::EC2::Dispatch                  -- Maps AWS XML responses onto perl object classes
 VM::EC2::ReservationSet            -- Hidden class used for describe_instances() request;
                                        The reservation Ids are copied into the Instance
                                         object.

There is also a high-level API called "VM::EC2::Staging::Manager" for
managing groups of staging servers and volumes which greatly
simplifies the task of creating and updating instances that mount
multiple volumes. The API also provides a one-line command for
migrating EBS-backed AMIs from one zone to another. See
L<VM::EC2::Staging::Manager>.

The interface provided by these modules is based on that described at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/. The
following caveats apply:

 1) Not all of the Amazon API is currently implemented. Specifically,
    a handful calls dealing with cluster management and VM importing
    are missing.  See L</MISSING METHODS> for a list of all the
    unimplemented API calls. Volunteers to fill in these gaps are
    most welcome!

 2) For consistency with common Perl coding practices, method calls
    are lowercase and words in long method names are separated by
    underscores. The Amazon API prefers mixed case.  So in the Amazon
    API the call to fetch instance information is "DescribeInstances",
    while in VM::EC2, the method is "describe_instances". To avoid
    annoyance, if you use the mixed case form for a method name, the
    Perl autoloader will automatically translate it to underscores for
    you, and vice-versa; this means you can call either
    $ec2->describe_instances() or $ec2->DescribeInstances().

 3) Named arguments passed to methods are all lowercase, use
    underscores to separate words and start with hyphens.
    In other words, if the AWS API calls for an argument named
    "InstanceId" to be passed to the "DescribeInstances" call, then
    the corresponding Perl function will look like:

         $instance = $ec2->describe_instances(-instance_id=>'i-12345')

    In most cases automatic case translation will be performed for you
    on arguments. So in the previous example, you could use
    -InstanceId as well as -instance_id. The exception
    is when an absurdly long argument name was replaced with an 
    abbreviated one as described below. In this case, you must use
    the documented argument name.

    In a small number of cases, when the parameter name was absurdly
    long, it has been abbreviated. For example, the
    "Placement.AvailabilityZone" parameter has been represented as
    -placement_zone and not -placement_availability_zone. See the
    documentation for these cases.

 4) For each of the describe_foo() methods (where "foo" is a type of
    resource such as "instance"), you can fetch the resource by using
    their IDs either with the long form:

          $ec2->describe_foo(-foo_id=>['a','b','c']),

    or a shortcut form: 

          $ec2->describe_foo('a','b','c');

    Both forms are listed in the headings in the documentation.

 5) When the API calls for a list of arguments named Arg.1, Arg.2,
    then the Perl interface allows you to use an anonymous array for
    the consecutive values. For example to call describe_instances()
    with multiple instance IDs, use:

       @i = $ec2->describe_instances(-instance_id=>['i-12345','i-87654'])

 6) All Filter arguments are represented as a -filter argument whose value is
    an anonymous hash:

       @i = $ec2->describe_instances(-filter=>{architecture=>'i386',
                                               'tag:Name'  =>'WebServer'})

    If there are no other arguments you wish to pass, you can omit the
    -filter argument and just pass a hashref:

       @i = $ec2->describe_instances({architecture=>'i386',
                                      'tag:Name'  =>'WebServer'})

    For any filter, you may represent multiple OR arguments as an arrayref:

      @i = $ec2->describe-instances({'instance-state-name'=>['stopped','terminated']})

    When adding or removing tags, the -tag argument uses the same syntax.

 7) The tagnames of each XML object returned from AWS are converted into methods
    with the same name and typography. So the <privateIpAddress> tag in a
    DescribeInstancesResponse, becomes:

           $instance->privateIpAddress

    You can also use the more Perlish form -- this is equivalent:

          $instance->private_ip_address

    Methods that correspond to complex objects in the XML hierarchy
    return the appropriate Perl object. For example, an instance's
    blockDeviceMapping() method returns an object of type
    VM::EC2::BlockDevice::Mapping.

    All objects have a fields() method that will return the XML
    tagnames listed in the AWS specifications.

      @fields = sort $instance->fields;
      # 'amiLaunchIndex', 'architecture', 'blockDeviceMapping', ...

 8) Whenever an object has a unique ID, string overloading is used so that 
    the object interpolates the ID into the string. For example, when you
    print a VM::EC2::Volume object, or use it in another string context,
    then it will appear as the string "vol-123456". Nevertheless, it will
    continue to be usable for method calls.

         ($v) = $ec2->describe_volumes();
         print $v,"\n";                 # prints as "vol-123456"
         $zone = $v->availabilityZone;  # acts like an object

 9) Many objects have convenience methods that invoke the AWS API on your
    behalf. For example, instance objects have a current_status() method that returns
    the run status of the object, as well as start(), stop() and terminate()
    methods that control the instance's lifecycle.

         if ($instance->current_status eq 'running') {
             $instance->stop;
         }

 10) Calls to AWS that have failed for one reason or another (invalid
    arguments, communications problems, service interruptions) will
    return undef and set the VM::EC2->is_error() method to true. The
    error message and its code can then be recovered by calling
    VM::EC2->error.

      $i = $ec2->describe_instance('i-123456');
      unless ($i) {
          warn 'Got no instance. Message was: ',$ec2->error;
      }

    You may also elect to raise an exception when an error occurs.
    See the new() method for details.

=head1 ASYNCHRONOUS CALLS

As of version 1.24, VM::EC2 supports asynchronous calls to AWS using
AnyEvent::HTTP. This allows you to make multiple calls in parallel for
a significant improvement in performance.

In asynchronous mode, VM::EC2 calls that ordinarily wait for AWS to
respond and then return objects corresponding to EC2 instances,
volumes, images, and so forth, will instead immediately return an
AnyEvent condition variable. You can retrieve the result of the call
by calling the condition variable's recv() method, or by setting a
callback to be executed when the call is complete.

To make an asynchronous call, you can set the global variable
$VM::EC2::ASYNC to a true value

Here is an example of a normal synchronous call:
  
 my @instances = $ec2->describe_instances();

Here is the asynchronous version initiated after setting
$VM::EC2::ASYNC (using a local block to limit its effects).

 {
    local $VM::EC2::ASYNC=1;
    my $cv = $ec2->describe_instances();   # returns immediately
    my @instances = $cv->recv;
 }

In case of an error recv() will return undef and the error object can
be recovered using the condition variable's error() method (this is an
enhancement over AnyEvent's standard condition variable class):

 my @instances = $cv->recv 
    or die "No instances found! error = ",$cv->error();

You may attach a callback CODE reference to the condition variable using
its cb() method, in which case the callback will be invoked when the
APi call is complete. The callback will be invoked with a single
argument consisting of the condition variable. Ordinarily you will
call recv() on the variable and then do something with the result:

 {
   local $VM::EC2::ASYNC=1;
   my $cv = $ec2->describe_instances();
   $cv->cb(sub {my $v = shift;
                my @i = $v->recv;
                print "instances = @i\n"; 
                });
  }

For callbacks to be invoked, someone must be run an event loop
using one of the event frameworks that AnyEvent supports (e.g. Coro,
Tk or Gtk). Alternately, you may simply run:

 AnyEvent->condvar->recv();
 
If $VM::EC2::ASYNC is false, you can issue a single asynchronous call
by appending "_async" to the name of the method call. Similarly, if
$VM::EC2::ASYNC is true, you can make a single normal synchrous call
by appending "_sync" to the method name.

For example, this is equivalent to the above:

 my $cv = $ec2->describe_instances_async();  # returns immediately
 my @instances = $cv->recv;

You may stack multiple asynchronous calls on top of one another. When
you call recv() on any of the returned condition variables, they will
all run in parallel. Hence the three calls will take no longer than
the longest individual one:

 my $cv1 = $ec2->describe_instances_async({'instance-state-name'=>'running'});
 my $cv2 = $ec2->describe_instances_async({'instance-state-name'=>'stopped'});
 my @running = $cv1->recv;
 my @stopped = $cv2->recv;

Same thing with callbacks:

 my (@running,@stopped);
 my $cv1 = $ec2->describe_instances_async({'instance-state-name'=>'running'});
 $cv1->cb(sub {@running = shift->recv});

 my $cv2 = $ec2->describe_instances_async({'instance-state-name'=>'stopped'});
 $cv1->cb(sub {@stopped = shift->recv});

 AnyEvent->condvar->recv;

And here it is using a group conditional variable to block until all
pending describe_instances() requests have completed:

 my %instances;
 my $group = AnyEvent->condvar;
 $group->begin;
 for my $state (qw(pending running stopping stopped)) {
    $group->begin;
    my $cv = $ec2->describe_instances_async({'instance-state-name'=>$state});
    $cv->cb(sub {my @i = shift->recv;
                 $instances{$state}=\@i;
                 $group->end});
 }
 $group->recv;
 # when we get here %instances will be populated by all instances,
 # sorted by their state.

If this looks mysterious, please consult L<AnyEvent> for full
documentation and examples.

Lastly, be advised that some of the objects returned by calls to
VM::EC2, such as the VM::EC2::Instance object, will make their own
calls into VM::EC2 for certain methods. Some of these methods will
block (be synchronous) of necessity, even if you have set
$VM::EC2::ASYNC. For example, the instance object's current_status()
method must block in order to update the object and return the current
status. Other object methods may behave unpredictably in async
mode. Caveat emptor!

=head1 API GROUPS

The extensive (and growing) Amazon API has many calls that you may
never need. To avoid the performance overhead of loading the
interfaces to all these calls, you may use Perl's import mechanism to
load only those modules you care about. By default, all methods are
loaded.

Loading is controlled by the "use" import list, and follows the
conventions described in the Exporter module:

 use VM::EC2;                     # load all methods!

 use VM::EC2 'key','elastic_ip';  # load Key Pair and Elastic IP
				  # methods only

 use VM::EC2 ':standard';         # load all the standard methods

 use VM::EC2 ':standard','!key';  # load standard methods but not Key Pair

Related API calls are grouped together using the scheme described at
http://docs.aws.amazon.com/AWSEC2/latest/APIReference/OperationList-query.html. The
modules that define the API calls can be found in VM/EC2/REST/; you
can read their documentation by running perldoc VM::EC2::REST::"name
of module":

 perldoc VM::EC2::REST::elastic_ip

The groups that you can import are as follows:
 
 :standard => ami, ebs, elastic_ip, instance, keys, general,
              monitoring, tag, security_group, security_token, zone

 :vpc      => customer_gateway, dhcp, elastic_network_interface, 
              private_ip, internet_gateway, network_acl, route_table,
              vpc, vpn, vpn_gateway

 :misc     => devpay, monitoring, reserved_instance,
              spot_instance, vm_export, vm_import, windows

 :scaling  => elastic_load_balancer,autoscaling

 :hpc      => placement_group

 :all      => :standard, :vpn, :misc

 :DEFAULT  => :all

The individual modules are:

 ami               -- Control Amazon Machine Images
 autoscaling       -- Control autoscaling
 customer_gateway  -- VPC/VPN gateways
 devpay            -- DevPay API
 dhcp              -- VPC DHCP options
 ebs               -- Elastic Block Store volumes & snapshots
 elastic_ip        -- Elastic IP addresses
 elastic_load_balancer -- The Elastic Load Balancer service
 elastic_network_interface -- VPC Elastic Network Interfaces
 general           -- Get console output and account attributes
 instance          -- Control EC2 instances
 internet_gateway  -- VPC connections to the internet
 keys              -- Manage SSH keypairs
 monitoring        -- Control instance monitoring
 network_acl       -- Control VPC network access control lists
 placement_group   -- Control the placement of HPC instances
 private_ip        -- VPC private IP addresses
 reserved_instance -- Reserve instances and view reservations
 route_table       -- VPC network routing
 security_group    -- Security groups for VPCs and normal instances
 security_token    -- Temporary credentials for use with IAM roles
 spot_instance     -- Request and manage spot instances
 subnet            -- VPC subnets
 tag               -- Create and interrogate resource tags.
 vm_export         -- Export VMs
 vm_import         -- Import VMs
 vpc               -- Create and manipulate virtual private clouds
 vpn_gateway       -- Create and manipulate VPN gateways within VPCs
 vpn               -- Create and manipulate VPNs within VPCs
 windows           -- Windows operating system-specific API calls.
 zone              -- Interrogate availability zones
  
=head1 EXAMPLE SCRIPT

The script sync_to_snapshot.pl, distributed with this module,
illustrates a relatively complex set of steps on EC2 that does
something useful. Given a list of directories or files on the local
filesystem it copies the files into an EBS snapshot with the desired
name by executing the following steps:

1. Provisions a new EBS volume on EC2 large enough to hold the data.

2. Spins up a staging instance to manage the network transfer of data
from the local machine to the staging volume.

3. Creates a temporary ssh keypair and a security group that allows an
rsync-over-ssh.

4. Formats and mounts the volume if necessary.

5. Initiates an rsync-over-ssh for the designated files and
directories.

6. Unmounts and snapshots the volume.

7. Cleans up.

If a snapshot of the same name already exists, then it is used to
create the staging volume, enabling network-efficient synchronization
of the files. A snapshot tag named "Version" is incremented each time
you synchronize.

=head1 CORE METHODS

This section describes the VM::EC2 constructor, accessor methods, and
methods relevant to error handling.

=cut

use strict;

use VM::EC2::Dispatch;
use VM::EC2::ParmParser;
eval "require AWS::Signature4"; # optional

use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(hmac_sha256 sha1_hex sha256_hex);
use POSIX 'strftime';
use URI;
use URI::Escape;
use AnyEvent;
use AnyEvent::HTTP;
use AnyEvent::CacheDNS ':register';
use HTTP::Request::Common;
use VM::EC2::Error;
use Carp 'croak','carp';
use JSON;

our $VERSION = '1.28';
our $AUTOLOAD;
our @CARP_NOT = qw(VM::EC2::Image    VM::EC2::Volume
                   VM::EC2::Snapshot VM::EC2::Instance
                   VM::EC2::ReservedInstance);
our $ASYNC;

# hard-coded timeout for several wait_for_terminal_state() calls.
use constant WAIT_FOR_TIMEOUT => 600;

sub AUTOLOAD {
    my $self = shift;
    my ($pack,$func_name) = $AUTOLOAD=~/(.+)::([^:]+)$/;
    return if $func_name eq 'DESTROY';
    my $proper = VM::EC2->canonicalize($func_name);
    $proper =~ s/^-//;

    my $async;
    if ($proper =~ /^(\w+)_(a?sync)$/i) {
	$proper = $1;
	$async  = $2 eq 'async' ? 1 : 0;
    }

    if ($self->can($proper)) {
	my $local = defined $async ? "local \$ASYNC=$async;" : '';
	eval "sub $pack\:\:$func_name {$local shift->$proper(\@_)}; 1" or die $@;
	$self->$func_name(@_);
    } 

    else {
	croak "Can't locate object method \"$func_name\" via package \"$pack\"";
    }
}

use constant import_tags => {
    ':standard' => [qw(instance elastic_ip ebs ami keys monitoring zone general tag security_group security_token)],
    ':vpc'      => [qw(customer_gateway dhcp elastic_network_interface private_ip 
                       internet_gateway network_acl route_table subnet vpc vpn vpn_gateway)],
    ':hpc'      => ['placement_group'],
    ':scaling'  => ['elastic_load_balancer','autoscaling'],
    ':elb'      => ['elastic_load_balancer'],
    ':rds'      => ['relational_database_service'],
    ':misc'     => ['devpay','reserved_instance', 'spot_instance','vm_export','vm_import','windows'],
    ':all'      => [qw(:standard :vpc :hpc :scaling :misc)],
    ':DEFAULT'  => [':all'],
};

# e.g. use VM::EC2 ':default','!ami';
sub import {
    my $self = shift;
    my @args = @_;
    @args    = ':DEFAULT' unless @args;
    while (1) {
	my @processed = map {/^:/ && import_tags->{$_} ? @{import_tags->{$_}} : $_ } @args;
	last if "@processed" eq  "@args";  # no more expansion needed
	@args = @processed;
    }
    my (%excluded,%included);
    foreach (@args) {
	if (/^!(\S+)/) {
	    $excluded{$1}++ ;
	    $_ = $1;
	}
    }
    foreach (@args) {
	next unless /^\S/;
	next if $excluded{$_};
	next if $included{$_}++;
	croak "'$_' is not a valid import tag" if /^[!:]/;
	next if $INC{"VM/EC2/REST/$_.pm"};
	my $class = "VM::EC2::REST::$_";
	eval "require $class; 1" or die $@;
    }
}

=head2 $ec2 = VM::EC2->new(-access_key=>$id,-secret_key=>$key,-endpoint=>$url)

Create a new Amazon access object. Required arguments are:

 -access_key   Access ID for an authorized user

 -secret_key   Secret key corresponding to the Access ID

 -security_token Temporary security token obtained through a call to the
               AWS Security Token Service

 -endpoint     The URL for making API requests

 -region       The region to receive the API requests

 -raise_error  If true, throw an exception.

 -print_error  If true, print errors to STDERR.

One or more of -access_key or -secret_key can be omitted if the
environment variables EC2_ACCESS_KEY and EC2_SECRET_KEY are
defined. If no endpoint is specified, then the environment variable
EC2_URL is consulted; otherwise the generic endpoint
http://ec2.amazonaws.com/ is used. You can also select the endpoint by
specifying one of the Amazon regions, such as "us-west-2", with the
-region argument. The endpoint specified by -region will override
-endpoint.

-security_token is used in conjunction with temporary security tokens
returned by $ec2->get_federation_token() and $ec2->get_session_token()
to grant restricted, time-limited access to some or all your EC2
resources to users who do not have access to your account. If you pass
either a VM::EC2::Security::Token object, or the
VM::EC2::Security::Credentials object contained within the token
object, then new() does not need the -access_key or -secret_key
arguments. You may also pass a session token string scalar to
-security_token, in which case you must also pass the access key ID
and secret keys generated at the same time the session token was
created. See
http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/UsingIAM.html
and L</AWS SECURITY TOKENS>.

To use an Open Stack cloud, please provide the appropriate endpoint
URL.

By default, when the Amazon API reports an error, such as attempting
to perform an invalid operation on an instance, the corresponding
method will return empty and the error message can be recovered from
$ec2->error(). However, if you pass -raise_error=>1 to new(), the module
will instead raise a fatal error, which you can trap with eval{} and
report with $@:

  eval {
     $ec2->some_dangerous_operation();
     $ec2->another_dangerous_operation();
  };
  print STDERR "something bad happened: $@" if $@;

The error object can be retrieved with $ec2->error() as before.

=cut

sub new {
    my $self = shift;
    my %args = @_;

    my ($id,$secret,$token);
    if (ref $args{-security_token} && $args{-security_token}->can('access_key_id')) {
	$id     = $args{-security_token}->accessKeyId;
	$secret = $args{-security_token}->secretAccessKey;
	$token  = $args{-security_token}->sessionToken;
    }

    $id           ||= $args{-access_key} || $ENV{EC2_ACCESS_KEY}
                      or croak "Please provide -access_key parameter or define environment variable EC2_ACCESS_KEY";
    $secret       ||= $args{-secret_key} || $ENV{EC2_SECRET_KEY}
                      or croak "Please provide -secret_key or define environment variable EC2_SECRET_KEY";
    $token        ||= $args{-security_token};

    my $endpoint_url = $args{-endpoint}   || $ENV{EC2_URL} || 'https://ec2.amazonaws.com/';
    $endpoint_url   .= '/'                      unless $endpoint_url =~ m!/$!;
    $endpoint_url    = "https://".$endpoint_url unless $endpoint_url =~ m!https?://!;

    my $raise_error  = $args{-raise_error};
    my $print_error  = $args{-print_error};
    my $obj = bless {
	id              => $id,
	secret          => $secret,
	security_token  => $token,
	endpoint        => $endpoint_url,
	idempotent_seed => sha1_hex(rand()),
	raise_error     => $raise_error,
	print_error     => $print_error,
    },ref $self || $self;

    if ($args{-region}) {
	$self->import('zone');
	my $region   = eval{$obj->describe_regions($args{-region})};
	my $endpoint = $region ? $region->regionEndpoint :"ec2.$args{-region}.amazonaws.com";
	$obj->endpoint($endpoint);
    }

    return $obj;
}

sub _region {
    my $self = shift;
    my $endpoint = $self->endpoint || return 'us-east-1';
    my ($region) = $endpoint =~ /([^.]+)\.amazonaws\.com/;
    return $region || 'us-east-1';
}

=head2 $access_key = $ec2->access_key([$new_access_key])

Get or set the ACCESS KEY. In this and all similar get/set methods,
call the method with no arguments to get the current value, and with a
single argument to change the value:

 $current_key = $ec2->access_key;
 $ec2->access_key('XYZZY');

In the case of setting the value, these methods will return the old
value as their result:

 $old_key = $ec2->access_key($new_key);

=cut

sub access_key {shift->id(@_)}

sub id       { 
    my $self = shift;
    my $d    = $self->{id};
    $self->{id} = shift if @_;
    $d;
}

=head2 $secret = $ec2->secret([$new_secret])

Get or set the SECRET KEY

=cut

sub secret   {
    my $self = shift;
    my $d    = $self->{secret};
    $self->{secret} = shift if @_;
    $d;
}

=head2 $secret = $ec2->security_token([$new_token])

Get or set the temporary security token. See L</AWS SECURITY TOKENS>.

=cut

sub security_token   {
    my $self = shift;
    my $d    = $self->{security_token};
    $self->{security_token} = shift if @_;
    $d;
}

=head2 $endpoint = $ec2->endpoint([$new_endpoint])

Get or set the ENDPOINT URL.

=cut

sub endpoint { 
    my $self = shift;
    my $d    = $self->{endpoint};
    if (@_) {
	my $new_endpoint = shift;
	$new_endpoint    = 'https://'.$new_endpoint
	    unless $new_endpoint =~ /^https?:/;
	$self->{endpoint} = $new_endpoint;
    }
    $d;
 }

=head2 $region = $ec2->region([$new_region])

Get or set the EC2 region manipulated by this module. This has the side effect
of changing the endpoint.

=cut

sub region { 
    my $self = shift;

    my $d    = $self->{endpoint};
    $d       =~ s!^https?://!!;
    $d       =~ s!/$!!;

    $self->import('zone');
    my @regions = $self->describe_regions;
    my ($current_region) = grep {$_->regionEndpoint eq $d} @regions;

    if (@_) {
	my $new_region = shift;
	my ($region) = grep {/$new_region/} @regions;
	$region or croak "unknown region $new_region";
	$self->endpoint($region->regionEndpoint);
    }
    return $current_region;
}

=head2 $ec2->raise_error($boolean)

Change the handling of error conditions. Pass a true value to cause
Amazon API errors to raise a fatal error. Pass false to make methods
return undef. In either case, you can detect the error condition
by calling is_error() and fetch the error message using error(). This
method will also return the current state of the raise error flag.

=cut

sub raise_error {
    my $self = shift;
    my $d    = $self->{raise_error};
    $self->{raise_error} = shift if @_;
    $d;
}

=head2 $ec2->print_error($boolean)

Change the handling of error conditions. Pass a true value to cause
Amazon API errors to print error messages to STDERR. Pass false to
cancel this behavior.

=cut

sub print_error {
    my $self = shift;
    my $d    = $self->{print_error};
    $self->{print_error} = shift if @_;
    $d;
}

=head2 $boolean = $ec2->is_error

If a method fails, it will return undef. However, some methods, such
as describe_images(), will also return undef if no resources matches
your search criteria. Call is_error() to distinguish the two
eventualities:

  @images = $ec2->describe_images(-owner=>'29731912785');
  unless (@images) {
      die "Error: ",$ec2->error if $ec2->is_error;
      print "No appropriate images found\n";
  }

=cut

sub is_error {
    defined shift->error();
}

=head2 $err = $ec2->error

If the most recently-executed method failed, $ec2->error() will return
the error code and other descriptive information. This method will
return undef if the most recently executed method was successful.

The returned object is actually an AWS::Error object, which
has two methods named code() and message(). If used in a string
context, its operator overloading returns the composite string
"$message [$code]".

=cut

sub error {
    my $self = shift;
    my $d    = $self->{error};
    $self->{error} = shift if @_;
    $d;
}

=head2 $err = $ec2->error_str

Same as error() except it returns the string representation, not the
object. This works better in debuggers and exception handlers.

=cut

sub error_str { 
    my $e = shift->{error};
    $e ||= '';
    return "$e";
}

=head2 $account_id = $ec2->account_id

Looks up the account ID corresponding to the credentials provided when
the VM::EC2 instance was created. The way this is done is to fetch the
"default" security group, which is guaranteed to exist, and then
return its groupId field. The result is cached so that subsequent
accesses are fast.

=head2 $account_id = $ec2->userId

Same as above, for convenience.

=cut

sub account_id {
    my $self = shift;
    return $self->{account_id} if exists $self->{account_id};
    my $sg   = $self->describe_security_groups(-group_name=>'default') or return;
    return $self->{account_id} ||= $sg->ownerId;
}

sub userId { shift->account_id }

=head2 $new_ec2 = $ec2->clone

This method creates an identical copy of the EC2 object. It is used
occasionally internally for creating an EC2 object in a different AWS
region:

 $singapore = $ec2->clone;
 $singapore->region('ap-souteast-1');

=cut

sub clone {
    my $self = shift;
    my %contents = %$self;
    return bless \%contents,ref $self;
}

=head1 INSTANCES

Load the 'instances' module to bring in methods for interrogating,
launching and manipulating EC2 instances. This module is part of
the ':standard' API group. The methods are described in detail in
L<VM::EC2::REST::instance>. Briefly:

 @i = $ec2->describe_instances(-instance_id=>\@ids,-filter=>\%filters)
 @i = $ec2->run_instances(-image_id=>$id,%other_args)
 @s = $ec2->start_instances(-instance_id=>\@instance_ids)
 @s = $ec2->stop_instances(-instance_id=>\@instance_ids,-force=>1)
 @s = $ec2->reboot_instances(-instance_id=>\@instance_ids)
 $b = $ec2->confirm_product_instance($instance_id,$product_code)
 $m = $ec2->instance_metadata
 @d = $ec2->describe_instance_attribute($instance_id,$attribute)
 $b = $ec2->modify_instance_attribute($instance_id,-$attribute_name=>$value)
 $b = $ec2->reset_instance_attribute($instance_id,$attribute)
 @s = $ec2->describe_instance_status(-instance_id=>\@ids,-filter=>\%filters,%other_args);

=head1 VOLUMES

Load the 'ebs' module to bring in methods specific for elastic block
storage volumes and snapshots. This module is part of the ':standard'
API group. The methods are described in detail in
L<VM::EC2::REST::ebs>. Briefly:

 @v = $ec2->describe_volumes(-volume_id=>\@ids,-filter=>\%filters)
 $v = $ec2->create_volume(%args)
 $b = $ec2->delete_volume($volume_id)
 $a = $ec2->attach_volume($volume_id,$instance_id,$device)
 $a = $ec2->detach_volume($volume_id)
 $ec2->wait_for_attachments(@attachment)
 @v = $ec2->describe_volume_status(-volume_id=>\@ids,-filter=>\%filters)
 $ec2->wait_for_volumes(@volumes)
 @d = $ec2->describe_volume_attribute($volume_id,$attribute)
 $b = $ec2->enable_volume_io(-volume_id=>$volume_id)
 @s = $ec2->describe_snapshots(-snapshot_id=>\@ids,%other_args)
 @d = $ec2->describe_snapshot_attribute($snapshot_id,$attribute)
 $b = $ec2->modify_snapshot_attribute($snapshot_id,-$argument=>$value)
 $b = $ec2->reset_snapshot_attribute($snapshot_id,$attribute)
 $s = $ec2->create_snapshot(-volume_id=>$vol,-description=>$desc)
 $b = $ec2->delete_snapshot($snapshot_id) 
 $s = $ec2->copy_snapshot(-source_region=>$region,-source_snapshot_id=>$id,-description=>$desc)
 $ec2->wait_for_snapshots(@snapshots)

=head1 AMAZON MACHINE IMAGES

Load the 'ami' module to bring in methods for creating and
manipulating Amazon Machine Images. This module is part of the
':standard" group. Full details are in L<VM::EC2::REST::ami>. Briefly:

 @i = $ec2->describe_images(@image_ids)
 $i = $ec2->create_image(-instance_id=>$id,-name=>$name,%other_args)
 $i = $ec2->register_image(-name=>$name,%other_args)
 $r = $ec2->deregister_image($image_id)
 @d = $ec2->describe_image_attribute($image_id,$attribute)
 $b = $ec2->modify_image_attribute($image_id,-$attribute_name=>$value)
 $b = $ec2->reset_image_attribute($image_id,$attribute_name)

=head1 KEYS

Load the 'keys' module to bring in methods for creating and
manipulating SSH keypairs. This module is loaded with the ':standard'
group and documented in L<VM::EC2::REST::keys.

 @k = $ec2->describe_key_pairs(@names);
 $k = $ec2->create_key_pair($name)
 $k = $ec2->import_key_pair($name,$public_key) 
 $b = $ec2->delete_key_pair($name)

=head1 TAGS

The methods in this module (loaded with ':standard') allow you to
create, delete and fetch resource tags. You may find that you rarely
need to use these methods directly because every object produced by
VM::EC2 supports a simple tag interface:
 
  $object = $ec2->describe_volumes(-volume_id=>'vol-12345'); # e.g.
  $tags = $object->tags();
  $name = $tags->{Name};
  $object->add_tags(Role => 'Web Server', Status=>'development);
  $object->delete_tags(Name=>undef);

See L<VM::EC2::Generic> for a full description of the uniform object
tagging interface, and L<VM::EC2::REST::tag> for methods that allow
you to manipulate the tags on multiple objects simultaneously. The
methods defined by this module are:

 @t = $ec2->describe_tags(-filter=>\%filters);
 $b = $ec2->create_tags(-resource_id=>\@ids,-tag=>{key1=>value1...})
 $b = $ec2->delete_tags(-resource_id=>$id1,-tag=>{key1=>value1...})
 
=head1 VIRTUAL PRIVATE CLOUDS

EC2 virtual private clouds (VPCs) provide facilities for creating
tiered applications combining public and private subnetworks, and for
extending your home/corporate network into the cloud. VPC-related
methods are defined in the customer_gateway, dhcp,
elastic_network_interface, private_ip, internet_gateway, network_acl,
route_table, vpc, vpn, and vpn_gateway modules, and are loaded by
importing ':vpc'. See L<VM::EC2::REST::vpc> for an introduction.

The L<VM::EC2::VPC> and L<VM::EC2::VPC::Subnet> modules define
convenience methods that simplify working with VPC objects. This
allows for steps that typically follow each other, such as creating a
route table and associating it with a subnet, happen
automatically. For example, this series of calls creates a VPC with a
single subnet, creates an Internet gateway attached to the VPC,
associates a new route table with the subnet and then creates a
default route from the subnet to the Internet gateway:

 $vpc       = $ec2->create_vpc('10.0.0.0/16')     or die $ec2->error_str;
 $subnet1   = $vpc->create_subnet('10.0.0.0/24')  or die $vpc->error_str;
 $gateway   = $vpc->create_internet_gateway       or die $vpc->error_str;
 $routeTbl  = $subnet->create_route_table         or die $vpc->error_str;
 $routeTbl->create_route('0.0.0.0/0' => $gateway) or die $vpc->error_str;

=head1 ELASTIC LOAD BALANCERS (ELB) AND AUTOSCALING

The methods in the 'elastic_load_balancer' and 'autoscaling' modules
allow you to retrieve information about Elastic Load Balancers, create
new ELBs, and change the properties of the ELBs, as well as define
autoscaling groups and their launch configurations. These modules are
both imported by the ':scaling' import group. See
L<VM::EC2::REST::elastic_load_balancer> and
L<VM::EC2::REST::autoscaling> for descriptions of the facilities
enabled by this module.

=head1 AWS SECURITY POLICY

The VM::EC2::Security::Policy module provides a simple Identity and
Access Management (IAM) policy statement generator geared for use with
AWS security tokens (see next section). Its facilities are defined in
L<VM::EC2::Security::Token>.

=head1 AWS SECURITY TOKENS

AWS security tokens provide a way to grant temporary access to
resources in your EC2 space without giving them permanent
accounts. They also provide the foundation for mobile services and
multifactor authentication devices (MFA). These methods are defined in
'security_token', which is part of the ':standard' group. See
L<VM::EC2::REST::security_token> for details. Here is a quick example:

Here is an example:

 # on your side of the connection
 $ec2 = VM::EC2->new(...);  # as usual
 my $policy = VM::EC2::Security::Policy->new;
 $policy->allow('DescribeImages','RunInstances');
 my $token = $ec2->get_federation_token(-name     => 'TemporaryUser',
                                        -duration => 60*60*3, # 3 hrs, as seconds
                                        -policy   => $policy);
 my $serialized = $token->credentials->serialize;
 send_data_to_user_somehow($serialized);

 # on the temporary user's side of the connection
 my $serialized = get_data_somehow();
 my $token = VM::EC2::Security::Credentials->new_from_serialized($serialized);
 my $ec2   = VM::EC2->new(-security_token => $token);
 print $ec2->describe_images(-owner=>'self');

=head1 SPOT AND RESERVED INSTANCES

The 'spot_instance' and 'reserved_instance' modules allow you to
create and manipulate spot and reserved instances. They are both part
of the ':misc' import group. See L<VM::EC2::REST::spot_instance> and
L<VM::EC2::REST::reserved_instance>. For example:

 @offerings = $ec2->describe_reserved_instances_offerings(
          {'availability-zone'   => 'us-east-1a',
           'instance-type'       => 'c1.medium',
           'product-description' =>'Linux/UNIX',
           'duration'            => 31536000,  # this is 1 year
           });
 $offerings[0]->purchase(5) and print "Five reserved instances purchased\n";



=head1 WAITING FOR STATE CHANGES

VM::EC2 provides a series of methods that allow your script to wait in
an efficient manner for desired state changes in instances, volumes
and other objects. They are described in detail the individual modules
to which they apply, but in each case the method will block until each
member of a list of objects transitions to a terminal state
(e.g. "completed" in the case of a snapshot). Briefly:

 $ec2->wait_for_instances(@instances)
 $ec2->wait_for_snapshots(@snapshots) 
 $ec2->wait_for_volumes(@volumes) 
 $ec2->wait_for_attachments(@attachment)

There is also a generic version of this defined in the VM::EC2 core:

=head2 $ec2->wait_for_terminal_state(\@objects,['list','of','states'] [,$timeout])

Generic version of the last four methods. Wait for all members of the
provided list of Amazon objects instances to reach some terminal state
listed in the second argument, and then return a hash reference that
maps each object ID to its final state.

If a timeout is provided, in seconds, then the method will abort after
waiting the indicated time and return undef.

=cut

sub wait_for_terminal_state {
    my $self = shift;
    my ($objects,$terminal_states,$timeout) = @_;
    my %terminal_state = map {$_=>1} @$terminal_states;
    my %status = ();
    my @pending = grep {defined $_} @$objects; # in case we're passed an undef

    my %timers;
    my $done = $self->condvar();
    $done->begin(sub {
	my $cv = shift;
	if ($cv->error) {
	    $self->error($cv->error);
	    $cv->send();
	} else {
	    $cv->send(\%status);
	}
		 }
	);
    
    for my $obj (@pending) {
	$done->begin;
	my $timer = AnyEvent->timer(interval => 3,
				    cb       => sub {
					$obj->current_status_async->cb( 
					    sub {
						my $state = shift->recv;
						if (!$state || $terminal_state{$state}) {
						    $status{$obj} = $state;
						    $done->end;
						    undef $timers{$obj};
						}})});
	$timers{$obj} = $timer;
    }

    # timeout
    my $timeout_event;
    $timeout_event = AnyEvent->timer(after=> $timeout,
				     cb   => sub {
					 undef %timers; # cancel all timers
					 undef $timeout_event;
					 $done->error('timeout waiting for terminal state');
					 $done->end foreach @pending;
				     }) if $timeout;
    $done->end;

    return $ASYNC ? $done : $done->recv;
}

=head2 $timeout = $ec2->wait_for_timeout([$new_timeout]);

Get or change the timeout for wait_for_instances(), wait_for_attachments(),
and wait_for_volumes(). The timeout is given in seconds, and defaults to
600 (10 minutes). You can set this to 0 to wait forever.

=cut

sub wait_for_timeout {
    my $self = shift;
    $self->{wait_for_timeout} = WAIT_FOR_TIMEOUT
	unless defined $self->{wait_for_timeout};
    my $d = $self->{wait_for_timeout};
    $self->{wait_for_timeout} = shift if @_;
    return $d;
}

# ------------------------------------------------------------------------------------------

=head1 INTERNAL METHODS

These methods are used internally and are listed here without
documentation (yet).

=head2 $underscore_name = $ec2->canonicalize($mixedCaseName)

=cut

sub canonicalize {
    my $self = shift;
    my $name = shift;

    $name =~ s/^-//;
    $name    =~ s/DB/Db/g;
    $name    =~ s/AZ/Az/g;

    while ($name =~ /[A-Z][^A-Z]/) {
        $name    =~ s/(?<!^)([A-Z]*[\d]*)\.?([A-Z])/\L$1_$2/g or last;
    }
    return '-'.lc $name;
}

sub uncanonicalize {
    my $self = shift;
    my $name = shift;
    $name    =~ s/_([a-z])/\U$1/g;
    return $name;
}

=head2 $instance_id = $ec2->instance_parm(@args)

=cut

sub instance_parm {
    my $self = shift;
    my %args;
    if ($_[0] =~ /^-/) {
	%args = @_; 
    } elsif (@_ > 1) {
	%args = (-instance_id => [@_]);
    } else {
	%args = (-instance_id => shift);
    }
    my $id = $args{-instance_id};
    return ref $id && ref $id eq 'ARRAY' ? @$id : $id;
}

=head2 @arguments = $ec2->value_parm(ParameterName => \%args)

=cut

sub value_parm {
    my $self = shift;
    my ($argname,$args) = @_;
    my $name = $self->canonicalize($argname);
    return unless exists $args->{$name} || exists $args->{"-$argname"};
    my $val = $args->{$name} || $args->{"-$argname"};
    return ("$argname.Value"=>$val);
}

=head2 @arguments = $ec2->single_parm(ParameterName => \%args)

=cut

sub single_parm {
    my $self = shift;
    my ($argname,$args) = @_;
    my $name = $self->canonicalize($argname);
    my $val  = $args->{$name} || $args->{"-$argname"};
    defined $val or return;
    my $v = ref $val  && ref $val eq 'ARRAY' ? $val->[0] : $val;
    return ($argname=>$v);
}

=head2 @parameters = $ec2->prefix_parm($prefix, ParameterName => \%args)

=cut

sub prefix_parm {
    my $self = shift;
    my ($prefix,$argname,$args) = @_;
    my $name = $self->canonicalize($argname);
    my $val  = $args->{$name} || $args->{"-$argname"};
    defined $val or return;
    my $v = ref $val  && ref $val eq 'ARRAY' ? $val->[0] : $val;
    return ("$prefix.$argname"=>$v);
}

=head2 @arguments = $ec2->member_hash_parms(ParameterName => \%args)

Create a parameter list from a hashref or arrayref of hashes

Created specifically for the RDS ModifyDBParameterGroup parameter
'Parameters', but may be useful for other calls in the future.

ie:

The argument would be in the form:

   [
           {
                   ParameterName=>'max_user_connections',
                   ParameterValue=>24,
                   ApplyMethod=>'pending-reboot'
           },
           {
                   ParameterName=>'max_allowed_packet',
                   ParameterValue=>1024,
                   ApplyMethod=>'immediate'
           },
   ];

The resulting output would be if the argname is '-parameters':

Parameters.member.1.ParameterName => max_user_connections
Parameters.member.1.ParameterValue => 24
Parameters.member.1.ApplyMethod => pending-reboot
Parameters.member.2.ParameterName => max_allowed_packet
Parameters.member.2.ParameterValue => 1024
Parameters.member.2.ApplyMethod => immediate

=cut

sub member_hash_parms {
    my $self = shift;
    my ($argname,$args) = @_;
    my $name = $self->canonicalize($argname);

    my @params;
    if (my $arg = $args->{$name}||$args->{"-$argname"}) {
        $arg = [ $arg ] if ref $arg eq 'HASH';
        return unless ref $arg eq 'ARRAY';
        my $c = 1;
        foreach my $a (@$arg) {
            next unless ref $a eq 'HASH';
            foreach my $key (keys %$a) {
                push @params, ("$argname.member.$c.$key" => $a->{$key});
            }
            $c++;
        }
    }
    return @params;
}

=head2 @arguments = $ec2->list_parm(ParameterName => \%args)

=cut

sub list_parm {
    my $self = shift;
    my ($argname,$args) = @_;
    return $self->_list_parm($argname,$args);
}

=head2 @parameters = $ec2->member_list_parm(ParameterName => \%args)

=cut

sub member_list_parm {
    my $self = shift;
    my ($argname,$args) = @_;
    return $self->_list_parm($argname,$args,'member');
}

sub _list_parm {
    my $self = shift;
    my ($argname,$args,$append) = @_;
    my $name = $self->canonicalize($argname);

    my @params;
    if (my $a = $args->{$name}||$args->{"-$argname"}) {
        $argname .= ".$append" if $append;
	my $c = 1;
	for (ref $a && ref $a eq 'ARRAY' ? @$a : $a) {
	    push @params,("$argname.".$c++ => $_);
	}
    }

    return @params;
}

=head2 @arguments = $ec2->filter_parm(\%args)

=cut

sub filter_parm {
    my $self = shift;
    my $args = shift;
    return $self->key_value_parameters('Filter','Name','Value',$args);
}

=head2 @arguments = $ec2->key_value_parameters($param_name,$keyname,$valuename,\%args,$skip_undef_values)

=cut

sub key_value_parameters {
    my $self = shift;
    # e.g. 'Filter', 'Name','Value',{-filter=>{a=>b}}
    return $self->_key_value_parameters(@_);
}

=head2 @arguments = $ec2->member_key_value_parameters($param_name,$keyname,$valuename,\%args,$skip_undef_values)

=cut

sub member_key_value_parameters {
    my $self = shift;
    my ($parameter_name,$keyname,$valuename,$args,$skip_undef_values) = @_;  
    return $self->_key_value_parameters($parameter_name,$keyname,$valuename,$args,$skip_undef_values,'member');
}

sub _key_value_parameters {
    my $self = shift;
    # e.g. 'Filter', 'Name','Value',{-filter=>{a=>b}}
    my ($parameter_name,$keyname,$valuename,$args,$skip_undef_values,$append) = @_;  
    my $arg_name     = $self->canonicalize($parameter_name);
    
    my @params;
    if (my $a = $args->{$arg_name}||$args->{"-$parameter_name"}) {
        $parameter_name .= ".$append" if $append;
	my $c = 1;
	if (ref $a && ref $a eq 'HASH') {
	    while (my ($name,$value) = each %$a) {
		push @params,("$parameter_name.$c.$keyname"   => $name);
		if (ref $value && ref $value eq 'ARRAY') {
		    for (my $m=1;$m<=@$value;$m++) {
			push @params,("$parameter_name.$c.$valuename.$m" => $value->[$m-1])
		    }
		} else {
		    push @params,("$parameter_name.$c.$valuename" => $value)
			unless !defined $value && $skip_undef_values;
		}
		$c++;
	    }
	} else {
	    for (ref $a ? @$a : $a) {
		my ($name,$value) = /([^=]+)\s*=\s*(.+)/;
		push @params,("$parameter_name.$c.$keyname"   => $name);
		push @params,("$parameter_name.$c.$valuename" => $value)
		    unless !defined $value && $skip_undef_values;
		$c++;
	    }
	}
    }

    return @params;
}

=head2 @arguments = $ec2->launch_perm_parm($prefix,$suffix,$value)

=cut

sub launch_perm_parm {
    my $self = shift;
    my ($prefix,$suffix,$value) = @_;
    return unless defined $value;
    $self->_perm_parm('LaunchPermission',$prefix,$suffix,$value);
}

sub create_volume_perm_parm {
    my $self = shift;
    my ($prefix,$suffix,$value) = @_;
    return unless defined $value;
    $self->_perm_parm('CreateVolumePermission',$prefix,$suffix,$value);
}

sub _perm_parm {
    my $self = shift;
    my ($base,$prefix,$suffix,$value) = @_;
    return unless defined $value;
    my @list = ref $value && ref $value eq 'ARRAY' ? @$value : $value;
    my $c = 1;
    my @param;
    for my $v (@list) {
	push @param,("$base.$prefix.$c.$suffix" => $v);
	$c++;
    }
    return @param;
}

=head2 @arguments = $ec2->iam_parm($args)

=cut

sub iam_parm {
    my $self = shift;
    my $args = shift;
    my @p;
    push @p,('IamInstanceProfile.Arn'  => $args->{-iam_arn})             if $args->{-iam_arn};
    push @p,('IamInstanceProfile.Name' => $args->{-iam_name})            if $args->{-iam_name};
    return @p;
}

=head2 @arguments = $ec2->block_device_parm($block_device_mapping_string)

=cut

sub block_device_parm {
    my $self    = shift;
    my $devlist = shift or return;

    my @dev     = ref $devlist && ref $devlist eq 'ARRAY' ? @$devlist : $devlist;

    my @p;
    my $c = 1;
    for my $d (@dev) {
	$d =~ /^([^=]+)=([^=]+)$/ or croak "block device mapping must be in format /dev/sdXX=device-name";

	my ($devicename,$blockdevice) = ($1,$2);
	push @p,("BlockDeviceMapping.$c.DeviceName"=>$devicename);

	if ($blockdevice =~ /^vol-/) {  # this is a volume, and not a snapshot
	    my ($volume,$delete_on_term) = split ':',$blockdevice;
	    push @p,("BlockDeviceMapping.$c.Ebs.VolumeId" => $volume);
	    push @p,("BlockDeviceMapping.$c.Ebs.DeleteOnTermination"=>$delete_on_term) 
		if defined $delete_on_term  && $delete_on_term=~/^(true|false|1|0)$/
	}
	elsif ($blockdevice eq 'none') {
	    push @p,("BlockDeviceMapping.$c.NoDevice" => '');
	} elsif ($blockdevice =~ /^ephemeral\d$/) {
	    push @p,("BlockDeviceMapping.$c.VirtualName"=>$blockdevice);
	} else {
	    my ($snapshot,$size,$delete_on_term,$vtype,$iops) = split ':',$blockdevice;

	    # Workaround for apparent bug in 2012-12-01 API; instances will crash without volume size
	    # even if a snapshot ID is provided
	    if ($snapshot) {
		$size ||= eval{$self->describe_snapshots($snapshot)->volumeSize};
		push @p,("BlockDeviceMapping.$c.Ebs.SnapshotId" =>$snapshot);
	    }

	    push @p,("BlockDeviceMapping.$c.Ebs.VolumeSize" =>$size)                    if $size;
	    push @p,("BlockDeviceMapping.$c.Ebs.DeleteOnTermination"=>$delete_on_term) 
		if defined $delete_on_term  && $delete_on_term=~/^(true|false|1|0)$/;
	    push @p,("BlockDeviceMapping.$c.Ebs.VolumeType"=>$vtype)                    if $vtype;
	    push @p,("BlockDeviceMapping.$c.Ebs.Iops"=>$iops)                           if $iops;
	}
	$c++;
    }
    return @p;
}

# ['eth0=eni-123456','eth1=192.168.2.1,192.168.3.1,192.168.4.1:subnet-12345:sg-12345:true:My Weird Network']
# form 1: ethX=network device id
# form 2: ethX=primary_address,secondary_address1,secondary_address2...:subnetId:securityGroupId:deleteOnTermination:description:AssociatePublicIpAddress
# form 3: ethX=primary_address,secondary_address_count:subnetId:securityGroupId:deleteOnTermination:description:AssociatePublicIpAddress
sub network_interface_parm {
    my $self = shift;
    my $args    = shift;
    my $devlist = $args->{-network_interfaces} or return;
    my @dev     = ref $devlist && ref $devlist eq 'ARRAY' ? @$devlist : $devlist;

    my @p;
    my $c = 0;
    for my $d (@dev) {
	$d =~ /^eth(\d+)\s*=\s*([^=]+)$/ or croak "network device mapping must be in format ethX=option-string";

	my ($device_index,$device_options) = ($1,$2);
	push @p,("NetworkInterface.$c.DeviceIndex" => $device_index);
	my @options = split ':',$device_options;
	if (@options == 1) {
	    push @p,("NetworkInterface.$c.NetworkInterfaceId" => $options[0]);
	} 
	else {
	    my ($ip_addresses,$subnet_id,$security_group_id,$delete_on_termination,$description,$assoc_public_ip_addr) = @options;
            # if assoc_public_ip_addr is true, the following conditions must be met:
            #  * can only associate a public address with a single network interface with a device index of 0
            #  * cannot associate a public ip with a second network interface
            #  * cannot assoicate a public ip when launching more than one network interface
            # NOTE: This option defaults to true in a default VPC
            if ($assoc_public_ip_addr) {
                $assoc_public_ip_addr = (($assoc_public_ip_addr eq 'true') && 
                                         ($device_index == 0) && 
                                         (@dev == 1)) ? 'true' : 'false';
            }
	    my @addresses = split /\s*,\s*/,$ip_addresses;
	    for (my $a = 0; $a < @addresses; $a++) {
		if ($addresses[$a] =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
		    push @p,("NetworkInterface.$c.PrivateIpAddresses.$a.PrivateIpAddress" => $addresses[$a]);
		    push @p,("NetworkInterface.$c.PrivateIpAddresses.$a.Primary"          => $a == 0 ? 'true' : 'false');
		}
		elsif ($addresses[$a] =~ /^\d+$/ && $a > 0) {
		    push @p,("NetworkInterface.$c.SecondaryPrivateIpAddressCount"        => $addresses[$a]);
		}
	    }
	    my @sgs = split ',',$security_group_id;
	    for (my $i=0;$i<@sgs;$i++) {
		push @p,("NetworkInterface.$c.SecurityGroupId.$i" => $sgs[$i]);
	    }

	    push @p,("NetworkInterface.$c.SubnetId"              => $subnet_id)             if length $subnet_id;
	    push @p,("NetworkInterface.$c.DeleteOnTermination"   => $delete_on_termination) if length $delete_on_termination;
	    push @p,("NetworkInterface.$c.Description"           => $description)           if length $description;
	    push @p,("NetworkInterface.$c.AssociatePublicIpAddress" => $assoc_public_ip_addr) if $assoc_public_ip_addr;
	}
	$c++;
    }
    return @p;
}

sub boolean_parm {
    my $self = shift;
    my ($argname,$args) = @_;
    my $name = $self->canonicalize($argname);
    return unless exists $args->{$name} || exists $args->{$argname};
    my $val = $args->{$name} || $args->{$argname};
    return ($argname => $val ? 'true' : 'false');
}

sub boolean_value_parm {
    my $self = shift;
    my ($argname,$args) = @_;
    my $name = $self->canonicalize($argname);
    return unless exists $args->{$name} || exists $args->{$argname};
    my $val = $args->{$name} || $args->{$argname};
    return ("$argname.Value" => $val ? 'true' : 'false');
}

=head2 $version = $ec2->version()

Returns the API version to be sent to the endpoint. Calls
guess_version_from_endpoint() to determine this.

=cut

sub version  { 
    my $self = shift;
    return $self->{version} ||=  $self->guess_version_from_endpoint();
}

=head2 $version = $ec2->guess_version_from_endpoint()

This method attempts to guess what version string to use when
communicating with various endpoints. When talking to endpoints that
contain the string "Eucalyptus" uses the old EC2 API
"2009-04-04". When talking to other endpoints, uses the latest EC2
version string.

=cut

sub guess_version_from_endpoint {
    my $self = shift;
    my $endpoint = $self->endpoint;
    return '2009-04-04' if $endpoint =~ /Eucalyptus/;  # eucalyptus version according to http://www.eucalyptus.com/participate/code
    return '2014-05-01';                               # most recent AWS version that we support
}

=head2 $ts = $ec2->timestamp

=cut

sub timestamp {
    return strftime("%Y-%m-%dT%H:%M:%SZ",gmtime);
}


=head2 @obj = $ec2->call($action,@param);

Make a call to Amazon using $action and the passed arguments, and
return a list of objects.

if $VM::EC2::ASYNC is set to true, then will return a
AnyEvent::CondVar object instead of a list of objects. You may
retrieve the objects by calling recv() or setting a callback:

    $VM::EC2::ASYNC = 1;
    my $cv  = $ec2->call('DescribeInstances');
    my @obj = $cv->recv;

or 

    $VM::EC2::ASYNC = 1;
    my $cv  = $ec2->call('DescribeInstances');
    $cv->cb(sub { my @objs = shift->recv;
                  do_something(@objs);
                });

=cut

sub call {
    my $self = shift;
    return $ASYNC ? $self->_call_async(@_) : $self->_call_sync(@_);
}
sub _call_sync {
    my $self = shift;
    my $cv   = $self->_call_async(@_);
    my @obj  = $cv->recv;
    $self->error($cv->error) if $cv->error;
    if (!wantarray) { # scalar context
	return $obj[0] if @obj == 1;
	return         if @obj == 0;
	return @obj;
    } else {
	return @obj;
    }
}

sub _call_async {
    my $self  = shift;
    my ($action,@param) = @_;

    # called if AWS::Signature4 NOT present; use built-in method
    unless (AWS::Signature4->can('new')) {
	my ($action,@param) = @_;
	my $post  = $self->_signature(Action=>$action,@param);
	my $u     = URI->new($self->endpoint);
	$u->query_form(@$post);
	return $self->async_post($action,POST($self->endpoint,Content=>$u->query));
    }


    # called if AWS::Signature4 IS present; use external module
    my $request = POST($self->endpoint,
		       'content-type'=>'application/x-www-form-urlencoded',
		       Content => [
			   Action  => $action,
			   Version => $self->version,
			   @param
		       ]);
    my $access_key = $self->access_key;
    my $secret_key = $self->secret;
    my $host       = URI->new($self->endpoint)->host;
    $request->header('x-amz-security-token'=>$self->security_token) if $self->security_token;
    $request->header('user-agent' => 'VM::EC2-perl');
    $request->header('action'     => $action);  # maybe not necessary, but docs say it is!
    $request->header('host'       => $host);
    
    AWS::Signature4->new(-access_key=>$access_key,
			 -secret_key=>$secret_key)->sign($request);
    $self->async_post($action,$request);
}

sub async_post {
    my $self = shift;
    $self->async_request('POST',@_);
}

sub async_get {
    my $self = shift;
    $self->async_request('GET',@_);
}

sub async_put {
    my $self = shift;
    $self->async_request('PUT',@_);
}

sub async_delete {
    my $self = shift;
    $self->async_request('DELETE',@_);
}

sub async_request {
    my $self = shift;
    my ($method,$action,$request) = @_;

    my @headers;
    $request->headers->scan(sub {push @headers,@_});

    my $cv    = $self->condvar;
    my $callback = sub {
	my $timer = shift;
	http_request(
	    $method => $request->uri,
	    body    => $request->content,
	    headers => {
		TE      => undef,
		Referer => undef,
		@headers,
	    },
	    sub {
		my ($body,$hdr) = @_;
		if ($hdr->{Status} !~ /^2/) { # an error
		    if ($body =~ /RequestLimitExceeded/) {
			warn "RequestLimitExceeded. Retry in ",$timer->next_interval()," seconds\n";
			$timer->retry();
			return;
		    } else {
			$self->async_send_error($action,$hdr,$body,$cv);
			$timer->success();
			return;
		    }
		} else { # success
		    $self->error(undef);
		    my @obj = VM::EC2::Dispatch->content2objects($action,$body,$self);
		    $cv->send(@obj);
		    $timer->success();
		}
	    })
    };
    RetryTimer->new(on_retry       => $callback,
		    interval       => 1,
		    max_retries    => 12,
		    on_max_retries => sub { $cv->error(VM::EC2::Error->new({Code=>500,Message=>'RequestLimitExceeded'},$self)) });

    return $cv;
}

sub async_send_error {
    my $self = shift;
    my ($action,$hdr,$body,$cv) = @_;
    my $error;

    if ($body =~ /<Response>/) {
	$error = VM::EC2::Dispatch->create_error_object($body,$self,$action);
    } elsif ($body =~ /<ErrorResponse xmlns="http:\/\//) {
        $error = VM::EC2::Dispatch->create_alt_error_object($body,$self,$action);
    } else {
	my $code = $hdr->{Status};
        my $msg  = $code =~ /^59[0-9]/ ? $hdr->{Reason} : $body;
	$error = VM::EC2::Error->new({Code=>$code,Message=>"$msg, at API call '$action')"},$self);
    }

    $cv->error($error);

    # this is probably not want we want to do, because it will cause error messages to
    # appear in random places nested into some deep callback.
    carp  "$error"     if $self->print_error;

    if ($self->raise_error) {
	$cv->croak($error);
    } else {
	$cv->send;
    }
}

sub signin_call {
    my $self = shift;
    my ($action,%args) = @_;
    my $endpoint = 'https://signin.aws.amazon.com/federation';

    $args{'Action'} = $action;

    my @param;
    for my $p (sort keys %args) {
	    push @param , join '=' , map { uri_escape($_,"^A-Za-z0-9\-_.~") } ($p,$args{$p});
    }
 
    my $request = GET "$endpoint?" . join '&', @param;

    my $response = $self->ua->request($request);

    return JSON::decode_json($response->content);
}

=head2 $url = $ec2->login_url(-credentials => $credentials, -issuer => $issuer_url, -destination => $console_url);

Returns an HTTP::Request object that points to the URL to login a user with STS credentials

  -credentials => $fed_token->credentials - Credentials from an $ec2->get_federation_token call
  -token => $token                        - a SigninToken from $ec2->get_signin_token call
  -issuer => $issuer_url
  -destination => $console_url            - URL of the AWS console. Defaults to https://console.aws.amazon.com/console/home
  -auto_scaling_group_names     List of auto scaling groups to describe
  -names                        Alias of -auto_scaling_group_names

-credentials or -token are required for this method to work

Usage can be:

  my $fed_token = $ec2->get_federation_token(...);
  my $token = $ec2->get_signin_token(-credentials => $fed_token->credentials);
  my $url = $ec2->login_url(-token => $token->{SigninToken}, -issuer => $issuer_url, -destination => $console_url);

Or:

  my $fed_token = $ec2->get_federation_token(...);
  my $url = $ec2->login_url(-credentials => $fed_token->credentials, -issuer => $issuer_url, -destination => $console_url);

=cut

sub login_url {
    my $self = shift;
    my %args = @_;
    my $endpoint = 'https://signin.aws.amazon.com/federation';

    my %parms; 
    $parms{Action}      = 'login';
    $parms{Destination} = $args{-destination} if ($args{-destination});
    $parms{Issuer}      = $args{-issuer}      if ($args{-issuer});
    $parms{SigninToken} = $args{-token}       if ($args{-token});

    if (defined $args{-credentials} and not defined $parms{SigninToken}) {
        $parms{SigninToken} = $self->get_signin_token(-credentials => $args{-credentials})->{SigninToken};
    }


    my @param;
    for my $p (sort keys %parms) {
	    push @param , join '=' , map { uri_escape($_,"^A-Za-z0-9\-_.~") } ($p,$parms{$p});
    }

    GET "$endpoint?" . join '&', @param;
}

=head2 $request = $ec2->_sign(@args)

Create and sign an HTTP::Request.

=cut

# adapted from Jeff Kim's Net::Amazon::EC2 module
sub _sign {
    my $self = shift;
    my $signature = $self->_signature(@_);
    return POST $self->endpoint,$signature;
}

sub _signature {
    my $self    = shift;
    my @args    = @_;

    my $action = 'POST';
    my $uri    = URI->new($self->endpoint);
    my $host   = $uri->host_port;
    $host      =~ s/:(80|443)$//;  # default ports will break
    my $path   = $uri->path||'/';

    my %sign_hash                = @args;
    $sign_hash{AWSAccessKeyId}   = $self->id;
    $sign_hash{Timestamp}        = $self->timestamp;
    $sign_hash{Version}          = $self->version;
    $sign_hash{SignatureVersion} = 2;
    $sign_hash{SignatureMethod}  = 'HmacSHA256';
    $sign_hash{SecurityToken}    = $self->security_token if $self->security_token;

    my @param;
    my @parameter_keys = sort keys %sign_hash;
    for my $p (@parameter_keys) {
	push @param,join '=',map {uri_escape($_,"^A-Za-z0-9\-_.~")} ($p,$sign_hash{$p});
    }
    my $to_sign = join("\n",
		       $action,$host,$path,join('&',@param));
    my $signature = encode_base64(hmac_sha256($to_sign,$self->secret),'');
    $sign_hash{Signature} = $signature;
    return [%sign_hash];
}

=head2 @param = $ec2->args(ParamName=>@_)

Set up calls that take either method(-resource_id=>'foo') or method('foo').

=cut

sub args {
    my $self = shift;
    my $default_param_name = shift;
    return unless @_;
    return @_ if $_[0] =~ /^-/;
    return (-filter=>shift) if @_==1 && ref $_[0] && ref $_[0] eq 'HASH';
    return ($default_param_name => \@_);
}

sub condvar {
    bless AnyEvent->condvar,'VM::EC2::CondVar';
}

# utility - retry a call with exponential backoff until it succeeds
package RetryTimer;
use AnyEvent;
use Carp 'croak';

# try a subroutine multiple times with exponential backoff
# until it succeeds. Subroutine must call timer's success() method
# if it succeds, retry() otherwise.

# Arguments
# on_retry=>CODEREF,
# on_max_retries=>CODEREF,
# interval => $seconds,    # defaults to 1
# multiplier=>$fraction,   # defaults to 1.5
# max_retries=>$integer,   # defaults to 10
sub new {
    my $class    = shift;
    my @args     = @_;

    my $self;
    $self = bless {
	timer => AE::timer(0,0, sub {
	    delete $self->{timer};
	    $self->{on_retry}->($self) if $self->{on_retry};
	}),
	tries            => 0,
	current_interval => 0,
	@args,
    },ref $class || $class;

    croak "need a on_retry argument" unless $self->{on_retry};
    $self->{interval}     ||= 1;
    $self->{multiplier}   ||= 1.5;
    $self->{max_retries}  = 10 unless defined $self->{max_retries};
    return $self;
}

sub retry {
    my $self = shift;
    return if $self->{timer};
    $self->{current_interval} = $self->next_interval;
    $self->{tries}++; 

    if ($self->{max_retries} && $self->{max_retries} <= $self->{tries}) {
	delete $self->{timer};
	delete $self->{current_interval};
	$self->{on_max_retries}->($self) if $self->{on_max_retries};
	return;
    }
    $self->{timer} = AE::timer ($self->{current_interval},0,
				sub {
				    delete $self->{timer};
				    $self->{on_retry}->($self)
					if $self && $self->{on_retry};
				});
}

sub next_interval {
    my $self = shift;
    if ($self->{current_interval}) {
	return $self->{current_interval} * $self->{multiplier};
    } else {
	return $self->{interval};
    }
}

sub current_interval { shift->{current_interval} };

sub success {
    my $self = shift;
    delete $self->{current_interval};
    delete $self->{timer};
}

package VM::EC2::CondVar;
use base 'AnyEvent::CondVar';

sub error {
    my $self = shift;
    my $d    = $self->{error};
    $self->{error} = shift if @_;
    return $d;
}

sub recv {
    my $self = shift;
    my @obj  = $self->SUPER::recv;
    if (!wantarray) { # scalar context
	return $obj[0] if @obj == 1;
	return         if @obj == 0;
	return @obj;
    } else {
	return @obj;
    }
}

=head1 OTHER INFORMATION

This section contains technical information that may be of interest to developers.

=head2 Signing and authentication protocol

This module uses Amazon AWS signing protocol version 2, as described at
http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?using-query-api.html.
It uses the HmacSHA256 signature method, which is the most secure
method currently available. For additional security, use "https" for
the communications endpoint:

  $ec2 = VM::EC2->new(-endpoint=>'https://ec2.amazonaws.com');

=head2 Subclassing VM::EC2 objects

To subclass VM::EC2 objects (or implement your own from scratch) you
will need to override the object dispatch mechanism. Fortunately this
is very easy. After "use VM::EC2" call
VM::EC2::Dispatch->register() one or more times:

 VM::EC2::Dispatch->register($call_name => $dispatch).

The first argument, $call_name, is name of the Amazon API call, such as "DescribeImages".

The second argument, $dispatch, instructs VM::EC2::Dispatch how to
create objects from the parsed XML. There are three possible syntaxes:

 1) A CODE references, such as an anonymous subroutine.

    In this case the code reference will be invoked to handle the 
    parsed XML returned from the request. The code will receive 
    two arguments consisting of the parsed
    content of the response, and the VM::EC2 object used to generate the
    request.

 2) A VM::EC2::Dispatch method name, optionally followed by its arguments
    delimited by commas. Example:

           "fetch_items,securityGroupInfo,VM::EC2::SecurityGroup"

    This tells Dispatch to invoke its fetch_items() method with
    the following arguments:

     $dispatch->fetch_items($parsed_xml,$ec2,'securityGroupInfo','VM::EC2::SecurityGroup')

    The fetch_items() method is used for responses in which a
    list of objects is embedded within a series of <item> tags.
    See L<VM::EC2::Dispatch> for more information.

    Other commonly-used methods are "fetch_one", and "boolean".

 3) A class name, such as 'MyVolume'

    In this case, class MyVolume is loaded and then its new() method
    is called with the four arguments ($parsed_xml,$ec2,$xmlns,$requestid),
    where $parsed_xml is the parsed XML response, $ec2 is the VM::EC2
    object that generated the request, $xmlns is the XML namespace
    of the XML response, and $requestid is the AWS-generated ID for the
    request. Only the first two arguments are really useful.

    I suggest you inherit from VM::EC2::Generic and use the inherited new()
    method to store the parsed XML object and other arguments.

Dispatch tries each of (1), (2) and (3), in order. This means that
class names cannot collide with method names.

The parsed content is the result of passing the raw XML through a
XML::Simple object created with:

 XML::Simple->new(ForceArray    => ['item'],
                  KeyAttr       => ['key'],
                  SuppressEmpty => undef);

In general, this will give you a hash of hashes. Any tag named 'item'
will be forced to point to an array reference, and any tag named "key"
will be flattened as described in the XML::Simple documentation.

A simple way to examine the raw parsed XML is to invoke any
VM::EC2::Generic's as_string() method:

 my ($i) = $ec2->describe_instances;
 print $i->as_string;

This will give you a Data::Dumper representation of the XML after it
has been parsed.

The suggested way to override the dispatch table is from within a
subclass of VM::EC2:
 
 package 'VM::EC2New';
 use base 'VM::EC2';
  sub new {
      my $self=shift;
      VM::EC2::Dispatch->register('call_name_1'=>\&subroutine1).
      VM::EC2::Dispatch->register('call_name_2'=>\&subroutine2).
      $self->SUPER::new(@_);
 }

See L<VM::EC2::Dispatch> for a working example of subclassing VM::EC2
and one of its object classes.

=head1 DEVELOPING

The git source for this library can be found at https://github.com/lstein/LibVM-EC2-Perl,
To contribute to development, please obtain a github account and then either:
 
 1) Fork a copy of the repository, make your changes against this repository, 
    and send a pull request to me to incorporate your changes.

 2) Contact me by email and ask for push privileges on the repository.

See http://help.github.com/ for help getting started.

=head1 SEE ALSO

L<Net::Amazon::EC2>
L<VM::EC2::Dispatch>
L<VM::EC2::Generic>
L<VM::EC2::BlockDevice>
L<VM::EC2::BlockDevice::Attachment>
L<VM::EC2::BlockDevice::EBS>
L<VM::EC2::BlockDevice::Mapping>
L<VM::EC2::BlockDevice::Mapping::EBS>
L<VM::EC2::Error>
L<VM::EC2::Generic>
L<VM::EC2::Group>
L<VM::EC2::Image>
L<VM::EC2::Instance>
L<VM::EC2::Instance::ConsoleOutput>
L<VM::EC2::Instance::Metadata>
L<VM::EC2::Instance::MonitoringState>
L<VM::EC2::Instance::PasswordData>
L<VM::EC2::Instance::Set>
L<VM::EC2::Instance::State>
L<VM::EC2::Instance::State::Change>
L<VM::EC2::Instance::State::Reason>
L<VM::EC2::KeyPair>
L<VM::EC2::Region>
L<VM::EC2::ReservationSet>
L<VM::EC2::ReservedInstance>
L<VM::EC2::ReservedInstance::Offering>
L<VM::EC2::SecurityGroup>
L<VM::EC2::Snapshot>
L<VM::EC2::Staging::Manager>
L<VM::EC2::Tag>
L<VM::EC2::Volume>

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
