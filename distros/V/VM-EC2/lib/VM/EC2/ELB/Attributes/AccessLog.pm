package VM::EC2::ELB::Attributes::AccessLog;

=head1 NAME

VM::EC2::ELB:Attributes::AccessLog - Object describing the AccessLog attributes
of an Elastic Load Balancer.

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2           = VM::EC2->new(...);
 my $lb            = $ec2->describe_load_balancer_attributes('my-lb');
 my $access_log    = $lb->AccessLog;

=head1 DESCRIPTION

This object is returned as part of the DescribeLoadBalancerAttributes API call.

=head1 METHODS

The following object methods are supported:
 
 EmitInterval             --  The interval for publishing the access logs. You
                              can specify an interval of either 5 minutes or 60
                              minutes.  Default is 60 mins.

 Enabled                  --  Specifies whether access log is enabled for the
                              load balancer.

 S3BucketName             --  The name of the Amazon S3 bucket where the access
                              logs are stored.

 S3BucketPrefix           --  The logical hierarchy you created for your Amazon
                              S3 bucket, for example my-bucket-prefix/prod. If
                              the prefix is not provided, the log is placed at
                              the root level of the bucket.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate the
instance state.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

use overload
    '""'     => sub {
        my $self = shift;
        my $string = "Access Log:\n";
	if ($self->Enabled) {
            $string .= ' Emit Interval=' . $self->EmitInterval;
            $string .= "\n S3 Bucket=" . $self->S3BucketName;
            $string .= "\n S3 Bucket Prefix=" . $self->S3BucketPrefix;
	} else {
            $string .= ' DISABLED';
	}
        return $string},
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(EmitInterval Enabled S3BucketName S3BucketPrefix);
}

sub Enabled {
    my $self = shift;
    my $enabled = $self->SUPER::Enabled;
    return $enabled eq 'true';
}

1;
