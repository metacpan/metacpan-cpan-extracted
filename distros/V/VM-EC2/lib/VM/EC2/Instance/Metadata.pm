package VM::EC2::Instance::Metadata;

=head1 NAME

VM::EC2::Instance::Metadata - Object describing the metadata of a running instance

=head1 SYNOPSIS

 # For use within a running EC2 instance only!

 use VM::EC2::Instance::Metadata;
 my $meta = VM::EC2::Instance::Metadata->new;

 # alternatively...
 my $meta = VM::EC2->instance_metadata;
 my $meta = $instance->metadata;

 # image information
 $image_id  = $meta->imageId;
 $index     = $meta->imageLaunchIndex;
 $path      = $meta->amiManifestPath;
 $location  = $meta->imageLocation;    # same as previous
 @ancestors = $meta->ancestorAmiIds;
 @ancestors = $meta->imageAncestorIds; # same as previous
 @codes     = $meta->productCodes;

 # launch and runtime information
 $inst_id   = $meta->instanceId;
 $kern_id   = $meta->kernelId;
 $rd_id     = $meta->ramdiskId;
 $res_id    = $meta->reservationId;
 $type      = $meta->instanceType;
 $zone      = $meta->availabilityZone;
 $userdata  = $meta->userData;
 @groups    = $meta->securityGroups;
 @keys      = $meta->publicKeys;
 $block_dev = $meta->blockDeviceMapping; # a hashref

 # Network information
 $priv_name = $meta->localHostname;
 $priv_name = $meta->privateDnsName;   # same as previous
 $priv_ip   = $meta->localIpv4;
 $priv_ip   = $meta->privateIpAddress;
 $mac       = $meta->mac;
 $pub_name  = $meta->publicHostname;
 $pub_name  = $meta->dnsName;          # same as previous
 $pub_ip    = $meta->publicIpv4;
 $pub_ip    = $meta->ipAddress;
 $interfaces= $meta->interfaces;       # a hashref

 # IAM information
 $iam_info   = $metadata->iam_info;         # a hashref
 $iam_role   = $metadata->iam_role;         # name of the role
 $credentials= $metadata->iam_credentials;  # VM::EC2::Security::Credentials object

 # Undocumented fields
 $action    = $meta->instanceAction;
 $profile   = $meta->profile;

=head1 DESCRIPTION

This is an interface to the metadata that is provided to a running
instance via the http://169.254.169.254/latest URL, as described in
http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/index.html?instancedata-data-categories.html.

Each metadata object caches its values, so there is no overhead in
calling a method repeatedly. Methods return scalar values, lists and
hashrefs as appropriate.

The methods from this class should only be called within the context
of a running EC2 instance. Attempts to call outside of this
context will result in long delays as the module attempts to
connect to an invalid hostname.

=head1 METHODS

=head2 $meta = VM::EC2::Instance::Metadata->new()

=head2 $meta = $ec2->instance_metadata()

=head2 $meta = $instance->metadata()

You can create a new metadata object either using this class's new()
constructor, or by calling an VM::EC2 object's instance_metadata()
method, or by calling a VM::EC2::Instance object's metadata () method.

=head2 Methods that return scalar values

The following methods all return single-valued results:

=over 4

=item Image information:

 imageId                -- ID of AMI used to launch this instance
 imageLaunchIndex       -- This index's launch index. If four instances
                           were launched by one $image->run_instances()
                           call, they will be numbered from 0 to 3.
 amiManifestPath        -- S3 path to the image
 imageLocation          -- Same as amiManifestPath(), for consistency with
                           VM::EC2::Image

=item Launch and runtime information:

 instanceId             -- ID of this instance
 kernelId               -- ID of this instance's kernel.
 ramdiskId              -- This instance's ramdisk ID
 reservationId          -- This instance's reservation ID
 instanceType           -- Machine type, e.g. "m1.small"
 availabilityZone       -- This instance's availability zone.
 region                 -- This instance's region.
 endpoint               -- This instance's endpoint.
 userData               -- User data passed at launch time.

=item Network information:

 localHostname          -- The instance hostname corresponding to its
                           internal EC2 IP address.
 privateDnsName         -- Same as localHostname(), for consistency with
                           VM::EC2::Instance
 localIpv4              -- The instance IP address on the internal EC2 network.
 privateIpAddress       -- Same as localIpv4(), for consistency with 
                           VM::EC2::Instance.
 mac                    -- This instance's MAC (ethernet) address.
 publicHostname         -- This instance's public hostname.
 dnsName                -- Same as publicHostname() for consistency with
                           VM::EC2::Instance.
 publicIpv4             -- This instance's public IP address.
 ipAddress              -- Same as publicIpv4() for consistency with
                           VM::EC2::Instance.

=item IAM information

These routines return information about the instance's IAM role, if
any. These calls also provide a temporary security credentials for
making EC2 calls, as described here:
http://docs.amazonwebservices.com/AWSEC2/latest/UserGuide/UsingIAM.html.

Note that these routines require installation of the perl JSON module, and will
cause a fatal error if this module cannot be loaded.

 iam_info               -- Returns a hash containing the fields 'LastUpdated',
                           'InstanceProfileArn', and 'InstanceProfileId'. These
                           provide information about the instance's IAM role.
 iam_role               -- Returns the IAM role name for the currently running
                           instance.
 iam_credentials        -- Returns a VM::EC2::Security::Credentials object that can
                           be passed to VM::EC2->new(-security_token=>$credentials).

=item Unknown information:

 profile                -- An undocumented field that contains the virtualization
                           type in the form "default-paravirtual".
 instanceAction         -- Undocumented metadata field named "instance-action"

=back

=head2 Methods that return lists

The following methods all return lists.

=over 4

=item Image information

 ancestorAmiIds        -- List of  AMIs from which the current one was derived
 imageAncestorIds      -- Same as ancestorAmiIds() but easier to read.
 productCodes          -- List of product codes applying to the image from which
                          this instance was launched.

=item Launch and runtime information

 securityGroups        -- List of security groups to which this instance is assigned.
                          For non-VPC instances, this will be the security group
                          name. For VPC instances, this will be the security group ID.
 publicKeys            -- List of public key pair names attached to this instance.

=back

=head2 Methods that return a hashref

The following methods return a hashref for representing complex data structures:

=over 4

=item $devices = $meta->blockDeviceMapping

This returns a hashref in which the keys are the names of instance
block devices, such as "/dev/sda1", and the values are the EC2 virtual
machine names. For example:

 x $meta->blockDeviceMapping
 0  HASH(0x9b4f2f8)
   '/dev/sda1' => 'root'
   '/dev/sda2' => 'ephemeral0'
   '/dev/sdg' => 'ebs1'
   '/dev/sdh' => 'ebs9'
   '/dev/sdi' => 'ebs10'
   'sda3' => 'swap'

For reasons that are not entirely clear, the swap device is reported
as "sda3" rather than as "/dev/sda3".

=item $interfaces = $meta->interfaces

Returns a mapping of all virtual ethernet devices owned by this
instance. This is primarily useful for VPC instances, which can have
more than one device. The hash keys are the MAC addresses of each
ethernet device, and the values are hashes that have the following
keys:

 mac
 localHostname
 localIpv4s        (an array ref)
 publicIpv4s       (an array ref)
 securityGroupIds  (an array ref)
 subnetId
 subnetIpv4CidrBlock
 vpcId
 vpcIpv4CidrBlock

For example:

                                                                                                                                     D
 x $meta->interfaces        
 0 HASH(0x9b4f518)
   '12:31:38:01:b8:97' => HASH(0x9eaa090)
      'localHostname' => 'domU-12-31-38-01-B8-97.compute-1.internal'
      'localIpv4s' => ARRAY(0x9b4f8a8)
         0  '10.253.191.101'
      'mac' => '12:31:38:01:b8:97'
      'publicIpv4s' => ARRAY(0x9ea9e40)
         0  '184.73.241.210'
      'securityGroupIds' => ARRAY(0x9eaa490)
           empty array
      'subnetId' => undef
      'subnetIpv4CidrBlock' => undef
      'vpcId' => undef
      'vpcIpv4CidrBlock' => undef

=back

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::BlockDevice>
L<VM::EC2::State::Reason>
L<VM::EC2::State>
L<VM::EC2::Instance>
L<VM::EC2::Tag>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use LWP::UserAgent;
use URI::Escape 'uri_unescape';
use Carp 'croak';

use constant TIMEOUT => 5; # seconds
my $global_cache = {};

sub new {
    my $pack = shift;
    return bless { cache => {} },ref $pack || $pack;
}

sub imageId          { shift->fetch('ami-id') }
sub imageLaunchIndex { shift->fetch('ami-launch-index') }
sub amiManifestPath  { shift->fetch('ami-manifest-path')}
sub imageLocation    { shift->amiManifestPath            }
sub ancestorAmiIds   { split /\s+/,shift->fetch('ancestor-ami-ids')  }
sub imageAncestorIds { shift->ancestorAmiIds             }  
sub instanceAction   { shift->fetch('instance-action')   }
sub instanceId       { shift->fetch('instance-id')       }
sub instanceType     { shift->fetch('instance-type')     }
sub localHostname    { shift->fetch('local-hostname')    }
sub privateDnsName   { shift->localHostname              }
sub localIpv4        { shift->fetch('local-ipv4')        }
sub privateIpAddress { shift->localIpv4                  }
sub kernelId         { shift->fetch('kernel-id')         }
sub mac              { shift->fetch('mac')               }
sub availabilityZone { shift->fetch('placement/availability-zone') }
sub region           { my $r = shift->availabilityZone;
                       $r    =~ s/[a-z]$//;              
		       return $r;                        }
sub endpoint         { 'http://ec2.'.shift->region.'.amazonaws.com'}
sub productCodes     { split /\s+/,shift->fetch('product-codes')   }
sub publicHostname   { shift->fetch('public-hostname')   }
sub dnsName          { shift->publicHostname             }
sub publicIpv4       { shift->fetch('public-ipv4')       }
sub ipAddress        { shift->publicIpv4                 }
sub ramdiskId        { shift->fetch('ramdisk-id')        }
sub reservationId    { shift->fetch('reservation-id')    }
sub securityGroups   { split /\s+/,shift->fetch('security-groups')   }
sub profile          { shift->fetch('profile')           }
sub userData         { shift->fetch('../user-data')      }

sub blockDeviceMapping {
    my $self = shift;
    my @devices = split /\s+/,$self->fetch('block-device-mapping');
    my %map     = map {$self->fetch("block-device-mapping/$_") => $_} @devices;
    return \%map;
}
sub interfaces {
    my $self = shift;
    my @macs   = split /\s+/,$self->fetch('network/interfaces/macs');
    my %result;
    for my $m (@macs) {
	$m =~ s/\/$//; # get rid of hanging slash
	for my $pair ([localHostname     => 'local-hostname'],
		      [localIpv4s        => 'local-ipv4s'],
		      [mac               => 'mac'],
		      [publicIpv4s       => 'public-ipv4s'],
		      [securityGroupIds  => 'security-groupids'],
		      [subnetId          => 'subnet-id'],
		      [subnetIpv4CidrBlock => 'subnet-ipv4-cidr-block'],
		      [vpcId             => 'vpc-id'],
		      [vpcIpv4CidrBlock  => 'vpc-ipv4-cidr-block']) {
	    my ($tag,$attribute) = @$pair;
	    my $value = $self->fetch("network/interfaces/macs/$m/$attribute");
	    my @value = split /\s+/,$value;
	    $result{$m}{$tag} = $attribute =~ /s$/ ? \@value : $value;
	}
    }
    return \%result;
}

sub publicKeys {
    my $self = shift;
    my @keys = split /\s+/,$self->fetch('public-keys');
    return map {/^\d+=(.+)/ && $1} @keys;
}

sub iam_info {
    my $self = shift;
    $self->_load_json;
    return JSON::from_json($self->fetch('iam/info'));
}

sub iam_role {
    my $self = shift;
    return $self->fetch('iam/security-credentials');
}

sub iam_credentials {
    my $self = shift;
    my $role = $self->iam_role or return;
    my $data = $self->fetch("iam/security-credentials/$role") or return;
    eval "require VM::EC2::Security::Credentials"
	unless VM::EC2::Security::Credentials->can('new_from_json');
    return VM::EC2::Security::Credentials->new_from_json($data,$self->endpoint);
}

sub _load_json {
    return if JSON->can('decode');
    eval "require JSON; 1" or croak "no JSON module installed: $@";
}

sub fetch {
    my $self = shift;
    my $attribute = shift or croak "Usage: VM::EC2::Instance::Metadata->get('attribute')";
    my $cache = $self->{cache} || $global_cache;  # protect against class invocation
    return $cache->{$attribute} if exists $cache->{$attribute};
    my $ua = $self->{ua} ||= LWP::UserAgent->new();
    $ua->timeout(TIMEOUT);
    my $response = $ua->get("http://169.254.169.254/latest/meta-data/$attribute");
    if ($response->is_success) {
	return $cache->{$attribute} = uri_unescape($response->decoded_content);  # don't know why, but URI escapes used here.
    } else {
	print STDERR $response->status_line,"\n" unless $response->code == 404;
	return;
    }
}

1;

