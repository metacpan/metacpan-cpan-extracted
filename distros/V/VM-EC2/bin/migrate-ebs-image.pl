#!/usr/bin/perl

=head1 NAME

migrate-ebs-image.pl     Copy an EBS-backed Amazon Image from one region to another

=head1 SYNOPSYS

  % migrate-ebs-image.pl --from us-east-1 --to ap-southeast-1 ami-123456

=head1 DESCRIPTION

This script copies an EBS-backed Unix/Linux/windows AMI located in the
EC2 region indicated by --from to the region indicated by --to. All
associated volume snapshots, including LVM and RAID volumes, are
migrated as well.

If --from is omitted, then the source region is derived from the
endpoint URL contained in the EC2_URL environment variable. The --to
option is required.

This script works with any EBS backed image, including Linux PVM,
Linux HVM (cluster) and Windows images. It will B<not> work with any
instance-store backed image. To migrate such instances, please see one
of the recipes listed online, for example:

 http://www.dowdandassociates.com/content/howto-move-ec2-instance-store-ami-one-region-another

=head1 COMMAND-LINE OPTIONS

Options can be abbreviated.  For example, you can use -l for
--list-regions and -b for --block-device-mapping:

      --from         Region in which the AMI is currently located (e.g. "us-east-1")
      --to           Region to which the AMI is to be copied (e.g. "us-west-1") REQUIRED
      --access_key   EC2 access key
      --secret_key   EC2 secret key
      --block_device_mapping 
                     Add additional block devices to the image.
      --endpoint     EC2 URL (defaults to http://ec2.amazonaws.com/)
      --kernel       Force assignment of kernel in destination image.
      --ramdisk      Force assignment of ramdisk in destination image.
      --quiet        Quench status messages
      --list_regions List the EC2 regions

The --block-device-mapping (-b) option is used to add ephemeral
storage to the destination image. Amazon's API doesn't describe
ephemeral volumes that are associated with images, and so this
information is not copied from the source to the destination image,
requiring you to add it back manually. The value of the argument is a
block device mapping string in the same format as described for the
command line program ec2-register:

 migrate-ebs-image.pl -f us-east-1 -t ap-southeast-1 \
                      -b /dev/sdy=ephemeral0 \
                      ami-123456

Ordinarily the script attempts to guess the correct matching kernel
and ramdisk for the destination image based on approximate string
matching. You can override these values by manually specifying the
kernel and/or ramdisk ID in the destination region. Note that no
checking is performed that the values you provide are correct.

=head1 ENVIRONMENT VARIABLES

The following environment variables are used if the corresponding
options are not present:

 EC2_ACCESS_KEY     your access key
 EC2_SECRET_KEY     your secret key
 EC2_URL            the desired region endpoint

=head1 INSTALLING THIS SCRIPT

This script is part of the Perl VM::EC2 package. To install from the
command line:

 % perl -MCPAN -e 'install VM::EC2'
 % migrate-ebs-image.pl --from us-east-1 --to ap-southeast-1 ami-123456

=head1 IMPORTANT CAVEATS

This script launches two "m1.small" instances, one each in the source
and destination regions. It also creates transient volumes in both
regions to hold the root volume and all other EBS snapshots associated
with the image. Running it will incur charges for instance run time
and data storage.

In addition, this script will transfer data from one region to another
across the internet, incurring internet data out fees on the source
side, and internet data in fees on the destination side. Volumes that
contain a filesystem, such as ext4 or ntfs, are copied from source to
destination using rsync. Volumes that are part of a RAID or LVM volume
are copied at the block level using gzip and dd via the secure
shell. In general, rsync will be much faster and parsimonious of
network bandwidth than block copying!

=head1 SEE ALSO

L<VM::EC2>, L<VM::EC2::Staging::Manager>

=head1 AUTHOR

Lincoln Stein, lincoln.stein@gmail.com

Copyright (c) 2012 Ontario Institute for Cancer Research
                                                                                
This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use lib '../lib';

use VM::EC2::Staging::Manager;
use File::Basename 'basename';
use Getopt::Long;

my($From,$To,$Access_key,$Secret_key,$Endpoint,$Quiet,$List,$Kernel,$Ramdisk,@Block_devices);
my $Program_name = basename($0);

GetOptions('from=s'        => \$From,
	   'to=s'          => \$To,
	   'access_key|access-key=s'  => \$Access_key,
	   'secret_key|secret-key=s'  => \$Secret_key,
	   'endpoint=s'    => \$Endpoint,
	   'quiet'         => \$Quiet,
	   'list_regions|list-regions'  => \$List,
	   'block_device_mapping|block-device-mapping=s' => \@Block_devices,
	   'kernel'        => \$Kernel,
	   'ramdisk'       => \$Ramdisk,
    ) or exec 'perldoc',$0;

#setup defaults
$ENV{EC2_ACCESS_KEY} = $Access_key if defined $Access_key;
$ENV{EC2_SECRET_KEY} = $Secret_key if defined $Secret_key;
$ENV{EC2_URL}        = $Endpoint   if defined $Endpoint;
$Quiet             ||= 0;

my $ec2 = VM::EC2->new();
if ($List) {
    print join("\n",sort $ec2->describe_regions),"\n";
    exit 0;
}

my $ami = shift or exec 'perldoc',$0;
$To             or  exec 'perldoc',$0;
$From ||= $ec2->region;

unless ($From) {
    my $endpoint = $ec2->endpoint;
    ($From)      = grep {$_->endpoint eq $ec2->endpoint} $ec2->describe_regions;
}

my $source = eval {VM::EC2->new(-region => $From)->staging_manager(-on_exit=>'terminate',
		                                                   -quiet  => $Quiet)}
    or die $@;

my $dest = eval {VM::EC2->new(-region => $To)->staging_manager(-on_exit=>'terminate',
							       -quiet  => $Quiet)}
    or die $@;

my @extra = @Block_devices ? (-block_devices=>\@Block_devices) : ();
push @extra,(-kernel_id  => $Kernel)  if $Kernel;
push @extra,(-ramdisk_id => $Ramdisk) if $Ramdisk;

my $img  = $source->copy_image($ami => $dest,@extra);

undef $source;
undef $dest;

print "New snapshot is now located in $To under $img.\n";

exit 0;

