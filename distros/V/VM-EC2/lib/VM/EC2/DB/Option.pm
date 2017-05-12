package VM::EC2::DB::Option;

=head1 NAME

VM::EC2::DB::IPRange - An RDS Database IP Range

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 STRING OVERLOADING

=head1 SEE ALSO

L<VM::EC2>
L<VM::EC2::Generic>
L<VM::EC2::DB::Instance>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.comE<gt>.

Copyright (c) 2013 Loyalty Methods, Inc.

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut

use strict;
use base 'VM::EC2::Generic';
use VM::EC2::DB::SecurityGroup::Membership;
use VM::EC2::DB::VpcSecurityGroup::Membership;

use overload '""' => sub { shift->OptionName },
    fallback => 1;

sub valid_fields {
    my $self = shift;
    return qw(DBSecurityGroupMemberships OptionDescription OptionName OptionSettings Persistent Port VpcSecurityGroupMemberships);
}

sub DBSecurityGroupMemberships {
    my $self = shift;
    my $groups = $self->SUPER::DBSecurityGroupMemberships;
    return unless $groups;
    $groups = $groups->{DBSecurityGroupMembership};
    return ref $groups eq 'HASH' ?
        (VM::EC2::DB::SecurityGroup::Membership->new($groups,$self->aws)) :
        map { VM::EC2::DB::SecurityGroup::Membership->new($_,$self->aws) } @$groups;
}

sub VpcSecurityGroupMemberships {
    my $self = shift;
    my $groups = $self->SUPER::VpcSecurityGroupMemberships;
    return unless $groups;
    $groups = $groups->{VpcSecurityGroupMembership};
    return ref $groups eq 'HASH' ?
        (VM::EC2::DB::VpcSecurityGroup::Membership->new($groups,$self->aws)) :
        map { VM::EC2::DB::VpcSecurityGroup::Membership->new($_,$self->aws) } @$groups;
}

sub db_security_group_memberships { shift->DBSecurityGroupMemberships }

sub name { shift->OptionName }

sub description { shift->OptionDescription }

sub settings { shift->OptionSettings }

1;
