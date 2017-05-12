package VM::EC2::ELB::TagDescription;

=head1 NAME

VM::EC2::ELB:TagDescription - Load Balancer Tag Description

=head1 DESCRIPTION

This object is used to contain the TagDescription data type.
It one of the response elements of the DescribeTags API call.
This data type is not returned by any function.

=head1 METHODS

The following object methods are supported:
 
 LoadBalancerName  -- Returns the load balancer name.
 Tags              -- Returns a hash of tags associated with the load balancer

=head1 STRING OVERLOADING

NONE.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>

=head1 AUTHOR

Lance Kinley E>lb>lkinley@loyaltymethods.comE>gt>.

Copyright (c) 2014 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';

sub valid_fields {
    my $self = shift;
    return qw(LoadBalancerName Tags);
}

sub Tags {
    my $self = shift;
    # cannot use $self->SUPER::Tags as the AUTOLOAD will find the Generic ->tags function
    my $tags = $self->{data}{'Tags'};
    my %tags = map { $_->{Key}, $_->{Value} } @{$tags->{member}};
    return wantarray ? %tags : \%tags;
}

1;
