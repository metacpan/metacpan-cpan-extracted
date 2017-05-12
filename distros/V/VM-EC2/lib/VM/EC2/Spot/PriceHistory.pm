package VM::EC2::Spot::PriceHistory;
use strict;
use base 'VM::EC2::Generic';

=head1 NAME

VM::EC2::Spot::PriceHistory - Object describing an Amazon EC2 spot instance price history record

=head1 SYNOPSIS

  use VM::EC2;

  $ec2     = VM::EC2->new(...);

  my @history = $ec2->describe_spot_price_history(-start_time => '2011-09-01T00:00:00',
						  -end_time   => '2011-09-05T00:00:00',
                                                  -availability_zone => 'us-east-1a',
                                                  -instance_type   => 'm1.small',
						  -filter     => {'product-description'=>'*Linux*'},
						} or die $ec2->error_str;
  for my $h (@history) {
    print join("\t",$h->timestamp,
                    $h->spot_price,
                    $h->instanceType,
                    $h->productDescription,
                    $h->availability_zone),"\n";
  }

=head1 DESCRIPTION

This object represents an Amazon EC2 spot instance price history record,
and is returned by VM::EC2->describe_spot_price_history().

=head1 METHODS

These object methods are supported:

 instanceType         -- Instance type, e.g. 'm1.small'
 productDescription   -- Product description, e.g. "windows"
 spotPrice            -- Price, in dollars per run-hour.
 timestamp            -- Timestamp of data point, in format yyyy-mm-ddThh:mm:ss.000Z
 availabilityZone     -- Availability zone of spot instance.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>

=head1 AUTHOR

Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2011 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

sub valid_fields {
    my $self = shift;
    return qw(instanceType productDescription spotPrice timestamp availabilityZone);
}


1;
