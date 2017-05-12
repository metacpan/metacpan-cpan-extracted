package VM::EC2::Security::Policy;

=head1 NAME

VM::EC2::Security::Policy -- Simple IAM policy generator for EC2

=head1 SYNOPSIS

 my $policy = VM::EC2::Security::Policy->new;
 $policy->allow('Describe*','CreateVolume','delete_volume');
 $policy->deny('DescribeVolumes');
 print $policy->as_string;

=head1 DESCRIPTION

This is a very simple Identity and Access Management (IAM) policy
statement generator that works sufficiently well to create policies to
control access EC2 resources. It is not fully general across all AWS
services.

=head1 METHODS

This section describes the methods available to
VM::EC2::Security::Policy. You will create a new, empty, policy using
new(), grant access to EC2 actions using allow(), and deny access to
EC2 actions using deny(). When you are done, either call as_string(),
or just use the policy object in a string context, to get a
properly-formatted policy string.


allow() and deny() return the modified object, allowing you to chain
methods. For example:

 my $p = VM::EC2::Security::Policy->new
             ->allow('Describe*')
             ->deny('DescribeImages','DescribeInstances');
 print $p;

=head2 $policy = VM::EC2::Security::Policy->new()

This class method creates a new, empty policy object. The default
policy object denies all access to EC2 resources.

=head2 $policy->allow('action1','action2','action3',...)

Grant access to the listed EC2 actions. You may specify actions using
Amazon's MixedCase notation (e.g. "DescribeInstances"), or using
VM::EC2's more Perlish underscore notation
(e.g. "describe_instances"). You can find the list of actions in
L<VM::EC2>, or in the Amazon API documentation at
http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/OperationList-query.html.

The "*" wildcard allows you to indicate a series of matching
operations. For example, to allow all Describe operations:

 $policy->allow('Describe*')

As described earlier, allow() returns the object, making it easy to
chain methods.

=head2 $policy->deny('action1','action2','action3',...)

Similar to allow(), but in this case denies access to certain
actions. Deny statements take precedence over allow statements.

As described earlier, deny() returns the object, making it easy to
chain methods.

=head2 $string = $policy->as_string

Converts the policy into a JSON string that can be passed to
VM::EC2->get_federation_token(), or other AWS libraries.

=head1 STRING OVERLOADING

When used in a string context, this object will interpolate into the
policy JSON string using as_string().

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

use strict;

use JSON;
use VM::EC2;

use Carp 'croak';
use overload
    '""'     => 'as_string',
    fallback => 1;

sub new {
    my $class = shift;
    return bless {
	statements => {},
    },ref $class || $class;
}

sub allow {
    my $self = shift;
    my @actions = @_ ? @_ : '*';
    return $self->_add_statement(-effect=>'allow',
				 -actions=>\@actions);
}
sub deny {
    my $self = shift;
    my @actions = @_ ? @_ : '*';
    return $self->_add_statement(-effect=>'deny',
				 -actions=>\@actions);
}

sub _add_statement {
    my $self = shift;
    my %args = @_;
    my $effect  = $args{-effect} || 'allow';
    my $actions = $args{-action} || $args{-actions} || [];
    $actions    = [$actions] unless ref $actions && ref $actions eq 'ARRAY';
    $effect     =~ /^allow|deny$/i or croak '-effect must be "allow" or "deny"';
    foreach (@$actions) {
	s/^ec2://i;
	$self->{statements}{lc $effect}{ucfirst VM::EC2->uncanonicalize($_)}++ ;
    }
    return $self;
}

sub as_string {
    my $self = shift;
    my $st   = $self->{statements};

    my @list;
    foreach my $effect (sort keys %$st) {
        push @list, {
            Action => [map { "ec2:$_" } keys %{$st->{$effect}}],
            Effect => "\u$effect\E",
            Resource => '*',
        };
    }

    unless (@list) {
        # No statements, so deny all;
        local $self->{statements};
        $self->deny('*');
        return $self->as_string;
    }

    my $json = JSON->new();
    $json->canonical(1);

    return $json->encode({Statement => \@list});
}

1;
