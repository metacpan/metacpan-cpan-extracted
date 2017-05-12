package VM::EC2::ELB::Policies;

=head1 NAME

VM::EC2::ELB:Policies - Elastic Load Balancer Policies

=head1 SYNOPSIS

 use VM::EC2;

 my $ec2            = VM::EC2->new(...);
 my $lb             = $ec2->describe_load_balancers('my-lb');
 my $p              = $lb->Policies;
 my @lb_policies    = $p->LBCookieStickinessPolicies;
 my @app_policies   = $p->AppCookieStickinessPolicies;
 my @other_policies = $p->OtherPolicies;

=head1 DESCRIPTION

This object is used to describe the policies that are attached to an Elastic
Load Balancer, segregated by type.  To more easily obtain a full list of
policies associated with the ELB, used the VM::EC2->describe_load_balancers()
method.

=head1 METHODS

The following object methods are supported:
 
 AppCookieStickinessPolicies  -- Application-based cookie stickiness policies
 LBCookieStickinessPolicies   -- Load Balancer-based cookie stickiness policies
 OtherPolicies                -- Other Policies

=head1 STRING OVERLOADING

NONE.

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::ELB>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::ELB::Policies::AppCookieStickinessPolicy;
use VM::EC2::ELB::Policies::LBCookieStickinessPolicy;

sub valid_fields {
    my $self = shift;
    return qw(AppCookieStickinessPolicies OtherPolicies LBCookieStickinessPolicies);
}

sub AppCookieStickinessPolicies {
    my $self = shift;
    my $acsp = $self->SUPER::AppCookieStickinessPolicies or return;
    return map { VM::EC2::ELB::Policies::AppCookieStickinessPolicy->new($_,$self->aws) } @{$acsp->{member}};
}

sub LBCookieStickinessPolicies {
    my $self = shift;
    my $lbcsp = $self->SUPER::LBCookieStickinessPolicies or return;
    return map { VM::EC2::ELB::Policies::LBCookieStickinessPolicy->new($_,$self->aws) } @{$lbcsp->{member}};
}

sub OtherPolicies {
    my $self = shift;
    my $op = $self->SUPER::OtherPolicies or return;
    return @{$op->{member}};
}

1;
