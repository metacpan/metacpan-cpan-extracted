package VM::EC2::REST::elastic_load_balancer;

use strict;
use VM::EC2 '';  # important not to import anything!
package VM::EC2;  # add methods to VM::EC2
require VM::EC2::ELB::ParmParser;

VM::EC2::Dispatch->register(
    AddTags                           => sub { exists shift->{AddTagsResult} },
    ApplySecurityGroupsToLoadBalancer => 'elb_member_list,SecurityGroups',
    AttachLoadBalancerToSubnets       => 'elb_member_list,Subnets',
    ConfigureHealthCheck              => 'fetch_one_result,HealthCheck,VM::EC2::ELB::HealthCheck',
    CreateAppCookieStickinessPolicy   => sub { exists shift->{CreateAppCookieStickinessPolicyResult} },
    CreateLBCookieStickinessPolicy    => sub { exists shift->{CreateLBCookieStickinessPolicyResult} },
    CreateLoadBalancer                => sub { shift->{CreateLoadBalancerResult}{DNSName} },
    CreateLoadBalancerListeners       => sub { exists shift->{CreateLoadBalancerListenersResult} },
    CreateLoadBalancerPolicy          => sub { exists shift->{CreateLoadBalancerPolicyResult} },
    DeleteLoadBalancer                => sub { exists shift->{DeleteLoadBalancerResult} },
    DeleteLoadBalancerListeners       => sub { exists shift->{DeleteLoadBalancerListenersResult} },
    DeleteLoadBalancerPolicy          => sub { exists shift->{DeleteLoadBalancerPolicyResult} },
    DeregisterInstancesFromLoadBalancer => 'elb_member_list,Instances,InstanceId',
    DescribeInstanceHealth            => 'fetch_members,InstanceStates,VM::EC2::ELB::InstanceState', 
    DescribeLoadBalancerAttributes    => 'fetch_one_result,LoadBalancerAttributes,VM::EC2::ELB::Attributes',
    DescribeLoadBalancerPolicies      => 'fetch_members,PolicyDescriptions,VM::EC2::ELB::PolicyDescription',
    DescribeLoadBalancerPolicyTypes   => 'fetch_members,PolicyTypeDescriptions,VM::EC2::ELB::PolicyTypeDescription',
    DescribeLoadBalancers             => 'fetch_members,LoadBalancerDescriptions,VM::EC2::ELB',
    DescribeTags                      => 'fetch_members,TagDescriptions,VM::EC2::ELB::TagDescription',
    DetachLoadBalancerFromSubnets     => 'elb_member_list,Subnets',
    DisableAvailabilityZonesForLoadBalancer =>
                                         'elb_member_list,AvailabilityZones',
    EnableAvailabilityZonesForLoadBalancer =>
                                         'elb_member_list,AvailabilityZones',
    ModifyLoadBalancerAttributes      => 'fetch_one_result,LoadBalancerAttributes,VM::EC2::ELB::Attributes',
    RegisterInstancesWithLoadBalancer => 'elb_member_list,Instances,InstanceId',
    SetLoadBalancerListenerSSLCertificate =>
                                         sub { exists shift->{SetLoadBalancerListenerSSLCertificateResult} },
    SetLoadBalancerPoliciesForBackendServer =>
                                         sub { exists shift->{SetLoadBalancerPoliciesForBackendServerResult} },
    SetLoadBalancerPoliciesOfListener => sub { exists shift->{SetLoadBalancerPoliciesOfListenerResult} },
    );

sub elb_call {
    my $self = shift;
    (my $endpoint = $self->{endpoint}) =~ s/ec2/elasticloadbalancing/;
    local $self->{endpoint} = $endpoint;
    local $self->{version}  = '2012-06-01';
    $self->call(@_);
}

my $VEP = 'VM::EC2::ELB::ParmParser';

=head1 NAME VM::EC2::REST::elastic_load_balancer

=head1 SYNOPSIS

 use VM::EC2 ':elb';

=head1 METHODS

The methods in this module allow you to retrieve information about
Elastic Load Balancers, create new ELBs, and change the properties of
the ELBs.

Implemented:
 AddTags
 ApplySecurityGroupsToLoadBalancer
 AttachLoadBalancerToSubnets
 ConfigureHealthCheck
 CreateAppCookieStickinessPolicy
 CreateLBCookieStickinessPolicy
 CreateLoadBalancer
 CreateLoadBalancerListeners
 CreateLoadBalancerPolicy
 DeleteLoadBalancer
 DeleteLoadBalancerListeners
 DeleteLoadBalancerPolicy
 DeregisterInstancesFromLoadBalancer
 DescribeInstanceHealth
 DescribeLoadBalancerAttributes
 DescribeLoadBalancerPolicies
 DescribeLoadBalancerPolicyTypes
 DescribeLoadBalancers
 DescribeTags
 DetachLoadBalancerFromSubnets
 DisableAvailabilityZonesForLoadBalancer
 EnableAvailabilityZonesForLoadBalancer
 ModifyLoadBalancerAttributes
 RegisterInstancesWithLoadBalancer
 RemoveTags
 SetLoadBalancerListenerSSLCertificate
 SetLoadBalancerPoliciesForBackendServer
 SetLoadBalancerPoliciesOfListener

Unimplemented:
 (none) 

The primary object manipulated by these methods is
L<VM::EC2::ELB>. Please see the L<VM::EC2::ELB> manual page

=head2 $success = $ec2->tag_load_balancer(-load_balancer_names => $name, -tags => { key => value, [key2 => value2], ... })

Adds one or more tags for the specified load balancer.  Each load balancer can
have a maximum of 10 tags.  Each tag consists of a key and an optional value.

Tag keys must be unique for each load balancer.
If a tag with the same key is already associated with the load balancer, this
action will update the value of the key.

Arguments:

 -load_balancer_names    The name of the load balancer to tag. You can specify a
                         maximum of one load balancer name.

 -tags                   Hashref of tag key/value pairs.

Returns true on success.

=cut

sub add_load_balancer_tags {
    my $self = shift;
    my %args = $self->args('-tags',@_);
    $args{'-load_balancer_names'} ||= $args{-lb_name};
    $args{'-load_balancer_names'} ||= $args{-lb_names};
    $args{'-load_balancer_names'} ||= $args{-load_balancer_name};
    $args{'-load_balancer_names'} ||
        croak "describe_load_balancer_tags(): -load_balancer_names argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        member_list_parm      => 'LoadBalancerNames',
                                        member_key_value_parm => 'Tags',
                                    });
    return $self->elb_call('AddTags',@params);
}

=head2 %tags = $ec2->describe_load_balancer_tags(-load_balancer_name=>\@names)

=head2 %tags = $ec2->describe_load_balancer_tags(@names)

Describes the tags associated with one or more load balancers.

Arguments:

 -load_balancer_names    The name of the load balancers to retrieve tags for.

Returns a hash of hashes in this format:

{
   'LBName' =>
   {
       TagName => TagValue,
       TagName => TagValue,
   }
}

=cut

sub describe_load_balancer_tags {
    my $self = shift;
    my %args = $self->args('-load_balancer_names',@_);
    $args{'-load_balancer_names'} ||= $args{-lb_name};
    $args{'-load_balancer_names'} ||= $args{-lb_names};
    $args{'-load_balancer_names'} ||= $args{-load_balancer_name};
    $args{'-load_balancer_names'} ||
        croak "describe_load_balancer_tags(): -load_balancer_names argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        member_list_parm => 'LoadBalancerNames',
                                    });
    my @tag_descs = $self->elb_call('DescribeTags',@params);
    my %tags;
    foreach my $desc (@tag_descs) {
        $tags{$desc->LoadBalancerName} = $desc->Tags;
    }
    return wantarray ? %tags : \%tags;
}

=head2 $success = $ec2->remove_load_balancer_tags(-load_balancer_names => $name, -tags => [ name1,[name2,name3,...] ])

=head2 $success = $ec2->remove_load_balancer_tags(-load_balancer_names => $name, -tags => $tag)

=cut

sub remove_load_balancer_tags {
    my $self = shift;
    my %args = $self->args('-load_balancer_names',@_);
    $args{'-load_balancer_names'} ||= $args{-lb_name};
    $args{'-load_balancer_names'} ||= $args{-lb_names};
    $args{'-load_balancer_names'} ||= $args{-load_balancer_name};
    $args{'-load_balancer_names'} ||
        croak "remove_load_balancer_tags(): -load_balancer_names argument missing";
    $args{-tags} ||
        croak "remove_load_balancer_tags(): -tags argument missing";
    my $tags = $args{-tags};
    my @tags = ref $tags eq 'ARRAY' ? @$tags : ($tags);
    my @taglist;
    push @taglist, { Key => $_ } foreach @tags;
    $args{-tags} = \@taglist;
    my @params = $VEP->format_parms(\%args,
                                    {
                                        member_list_parm => 'LoadBalancerNames',
                                        member_hash_parm => 'Tags',
                                    });
    return $self->elb_call('RemoveTags',@params);
}

=head2 $attrs = $ec2->describe_load_balancer_attributes(-load_balancer_name => $name)

Returns detailed information about all of the attributes associated with the
specified load balancer.

Arguments:

    -load_balancer_name     Name of the ELB to return information on. 

Returns a L<VM::EC2::ELB::Attributes> object.

=cut

sub describe_load_balancer_attributes {
    my $self = shift;
    my %args = $self->args('-load_balancer_name',@_);
    $args{'-load_balancer_name'} ||= $args{-lb_name};
    $args{'-load_balancer_name'} ||= $args{-lb_names};
    $args{'-load_balancer_name'} ||= $args{-load_balancer_names};
    $args{'-load_balancer_name'} ||
        croak "describe_load_balancer_attributes(): -load_balancer_name argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => 'LoadBalancerName',
                                    });
    return $self->elb_call('DescribeLoadBalancerAttributes',@params);
}

=head2 $attr = $ec2->modify_load_balancer_attributes(%args)

Modifies the attributes of a specified load balancer.

Arguments:

 -load_balancer_name        Name of the ELB to change attributes on. (Required)

One or more of the following arguments are required:

 -access_log                A hashref of attribute values for AccessLog
                            ex: -access_log => { Enabled => 'false' }

 -connection_draining       A hashref of attribute values for ConnectionDraining
                            ex: -connection_draining => { Enabled => 'false' }

 -connection_settings       A hashref of attribute values for ConnectionSettings
                            ex: -connection_settings => { IdleTimeout => 30 }

 -cross_zone_load_balancing A hashref of attribute values for
                            CrossZoneLoadBalancing.  ex:
                            -cross_zone_load_balancing => { Enabled => 'true' }

Returns a L<VM::EC2::ELB::Attributes> object.

=cut

sub modify_load_balancer_attributes {
    my $self = shift;
    my %args = $self->args('-load_balancer_name',@_);
    $args{'-load_balancer_name'} ||= $args{-lb_name};
    $args{'-load_balancer_name'} ||= $args{-lb_names};
    $args{'-load_balancer_name'} ||= $args{-load_balancer_names};
    $args{'-load_balancer_name'} or
        croak "modify_load_balancer_attributes(): -load_balancer_name argument missing";
    ($args{-access_log} || $args{-connection_draining} ||
     $args{-connection_settings} || $args{-cross_zone_load_balancing}) or
        croak "modify_load_balancer_attributes(): missing attribute parameter";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm   => 'LoadBalancerName',
                                        elb_attr_parm => [qw(AccessLog ConnectionDraining
                                                             ConnectionSettings
                                                             CrossZoneLoadBalancing)],
                                    });
    return $self->elb_call('ModifyLoadBalancerAttributes',@params);
}

=head2 @lbs = $ec2->describe_load_balancers(-load_balancer_name=>\@names)

=head2 @lbs = $ec2->describe_load_balancers(@names)

Provides detailed configuration information for the specified ELB(s).

Optional parameters are:

    -load_balancer_names     Name of the ELB to return information on. 
                             This can be a string scalar, or an arrayref.

    -lb_name,-lb_names,      
      -load_balancer_name    Aliases for -load_balancer_names

Returns a series of L<VM::EC2::ELB> objects.

=cut

sub describe_load_balancers {
    my $self = shift;
    my %args = $self->args('-load_balancer_names',@_);
    $args{'-load_balancer_names'} ||= $args{-lb_name};
    $args{'-load_balancer_names'} ||= $args{-lb_names};
    $args{'-load_balancer_names'} ||= $args{-load_balancer_name};
    my @params = $VEP->format_parms(\%args,
                                    {
                                        member_list_parm => 'LoadBalancerNames',
                                    });
    return $self->elb_call('DescribeLoadBalancers',@params);
}

=head2 $success = $ec2->delete_load_balancer(-load_balancer_name=>$name)

=head2 $success = $ec2->delete_load_balancer($name)

Deletes the specified ELB.

Arguments:

 -load_balancer_name    -- The name of the ELB to delete

 -lb_name               -- Alias for -load_balancer_name

Returns true on successful deletion.  NOTE:  This API call will return
success regardless of existence of the ELB.

=cut

sub delete_load_balancer {
    my $self = shift;
    my %args = $self->args('-load_balancer_name',@_);
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "delete_load_balancer(): -load_balancer_name argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => 'LoadBalancerName',
                                    });
    return $self->elb_call('DeleteLoadBalancer',@params);
}

=head2 $healthcheck = $ec2->configure_health_check(-load_balancer_name  => $name,
                                                   -healthy_threshold   => $cnt,
                                                   -interval            => $secs,
                                                   -target              => $target,
                                                   -timeout             => $secs,
                                                   -unhealthy_threshold => $cnt)

Defines an application healthcheck for the instances.

All Parameters are required.

    -load_balancer_name    Name of the ELB.

    -healthy_threashold    Specifies the number of consecutive health probe successes 
                           required before moving the instance to the Healthy state.

    -interval              Specifies the approximate interval, in seconds, between 
                           health checks of an individual instance.

    -target                Must be a string in the form: Protocol:Port[/PathToPing]
                            - Valid Protocol types are: HTTP, HTTPS, TCP, SSL
                            - Port must be in range 1-65535
                            - PathToPing is only applicable to HTTP or HTTPS protocol
                              types and must be 1024 characters long or fewer.

    -timeout               Specifies the amount of time, in seconds, during which no
                           response means a failed health probe.

    -unhealthy_threashold  Specifies the number of consecutive health probe failures
                           required before moving the instance to the Unhealthy state.

    -lb_name               Alias for -load_balancer_name

Returns a L<VM::EC2::ELB::HealthCheck> object.

=cut

sub configure_health_check {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "configure_health_check(): -load_balancer_name argument missing";
    $args{-healthy_threshold} && $args{-interval} &&
        $args{-target} && $args{-timeout} && $args{-unhealthy_threshold} or
        croak "configure_health_check(): healthcheck argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm               => 'LoadBalancerName',
                                        'HealthCheck.single_parm' =>
                                            [ qw(HealthyThreshold Interval Target
                                                 Timeout UnhealthyThreshold)
                                            ],
                                    });
    return $self->elb_call('ConfigureHealthCheck',@params);
}

=head2 $success = $ec2->create_app_cookie_stickiness_policy(-load_balancer_name => $name,
                                                            -cookie_name        => $cookie,
                                                            -policy_name        => $policy)

Generates a stickiness policy with sticky session lifetimes that follow that of
an application-generated cookie. This policy can be associated only with
HTTP/HTTPS listeners.

Required arguments:

    -load_balancer_name    Name of the ELB.

    -cookie_name           Name of the application cookie used for stickiness.

    -policy_name           The name of the policy being created. The name must
                           be unique within the set of policies for this ELB. 

    -lb_name               Alias for -load_balancer_name

Returns true on successful execution.

=cut

sub create_app_cookie_stickiness_policy {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "create_app_cookie_stickiness_policy(): -load_balancer_name argument missing";
    $args{-cookie_name} && $args{-policy_name} or
        croak "create_app_cookie_stickiness_policy(): -cookie_name or -policy_name option missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(LoadBalancerName CookieName PolicyName)],
                                    });
    return $self->elb_call('CreateAppCookieStickinessPolicy',@params);
}

=head2 $success = $ec2->create_lb_cookie_stickiness_policy(-load_balancer_name       => $name,
                                                           -cookie_expiration_period => $secs,
                                                           -policy_name              => $policy)

Generates a stickiness policy with sticky session lifetimes controlled by the
lifetime of the browser (user-agent) or a specified expiration period. This
policy can be associated only with HTTP/HTTPS listeners.

Required arguments:

    -load_balancer_name         Name of the ELB.

    -cookie_expiration_period   The time period in seconds after which the
                                cookie should be considered stale. Not
                                specifying this parameter indicates that the
                                sticky session will last for the duration of
                                the browser session.  OPTIONAL

    -policy_name                The name of the policy being created. The name
                                must be unique within the set of policies for 
                                this ELB. 

    -lb_name                    Alias for -load_balancer_name

Returns true on successful execution.

=cut

sub create_lb_cookie_stickiness_policy {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "create_lb_cookie_stickiness_policy(): -load_balancer_name argument missing";
    $args{-cookie_expiration_period} && $args{-policy_name} or
        croak "create_lb_cookie_stickiness_policy(): -cookie_expiration_period or -policy_name option missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(LoadBalancerName CookieExpirationPeriod PolicyName)],
                                    });
    return $self->elb_call('CreateLBCookieStickinessPolicy',@params);
}

=head2 $lb = $ec2->create_load_balancer(-load_balancer_name => $name,
                                        -listeners          => \@listeners,
                                        -availability_zones => \@zones,
                                        -scheme             => $scheme,
)

Creates a new ELB.

Required arguments:

    -load_balancer_name         Name of the ELB.

    -listeners                  Must either be a L<VM::EC2::ELB:Listener> object
                                (or arrayref of objects) or a hashref (or arrayref
                                of hashrefs) containing the following keys:

              Protocol            -- Value as one of: HTTP, HTTPS, TCP, or SSL
              LoadBalancerPort    -- Value in range 1-65535
              InstancePort        -- Value in range 1-65535
                and optionally:
              InstanceProtocol    -- Value as one of: HTTP, HTTPS, TCP, or SSL
              SSLCertificateId    -- Certificate ID from AWS IAM certificate list


    -availability_zones    Literal string or array of strings containing valid
                           availability zones.  Optional if subnets are
                           specified in a VPC usage scenario.

Optional arguments:

    -scheme                The type of ELB.  By default, Elastic Load Balancing
                           creates an Internet-facing LoadBalancer with a
                           publicly resolvable DNS name, which resolves to
                           public IP addresses.  Specify the value 'internal'
                           for this option to create an internal LoadBalancer
                           with a DNS name that resolves to private IP addresses.
                           This option is only available in a VPC.

    -security_groups       The security groups assigned to your ELB within your
                           VPC.  String or arrayref.

    -subnets               A list of subnet IDs in your VPC to attach to your
                           ELB.  String or arrayref.  REQUIRED if availability
                           zones are not specified above.

    -tags                  A list of tags to assign to the load balancer.
                           Hashref of tag key/value pairs.
                           ex: { Name => Value, Name => Value, ... }

Argument aliases:

    -zones                 Alias for -availability_zones
    -lb_name               Alias for -load_balancer_name
                          
Returns a L<VM::EC2::ELB> object if successful.

=cut

sub create_load_balancer {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-availability_zones } ||= $args{-zones};
    $args{-load_balancer_name} or
        croak "create_load_balancer(): -load_balancer_name argument missing";
    $args{-listeners} or
        croak "create_load_balancer(): -listeners option missing";
    $args{-availability_zones} || $args{-subnets} or
        croak "create_load_balancer(): -availability_zones option is required if subnets are not specified";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm           => [qw(LoadBalancerName Scheme)],
                                        member_list_parm      => [qw(AvailabilityZones SecurityGroups Subnets)],
                                        elb_listeners_parm    => 'Listeners',
                                        member_key_value_parm => 'Tags',
                                    });
    return unless $self->elb_call('CreateLoadBalancer',@params);
    return eval {
            my $elb;
            local $SIG{ALRM} = sub {die "timeout"};
            alarm(60);
            until ($elb = $self->describe_load_balancers($args{-load_balancer_name})) { sleep 1 }
            alarm(0);
            $elb;
    };
}


=head2 $success = $ec2->create_load_balancer_listeners(-load_balancer_name => $name,
                                                       -listeners          => \@listeners)

Creates one or more listeners on a ELB for the specified port. If a listener 
with the given port does not already exist, it will be created; otherwise, the
properties of the new listener must match the properties of the existing
listener.

 -listeners    Must either be a L<VM::EC2::ELB:Listener> object (or arrayref of
               objects) or a hash (or arrayref of hashes) containing the
               following keys:

             Protocol            -- Value as one of: HTTP, HTTPS, TCP, or SSL
             LoadBalancerPort    -- Value in range 1-65535
             InstancePort        -- Value in range 1-65535
              and optionally:
             InstanceProtocol    -- Value as one of: HTTP, HTTPS, TCP, or SSL
             SSLCertificateId    -- Certificate ID from AWS IAM certificate list

 -lb_name      Alias for -load_balancer_name

Returns true on successful execution.

=cut

sub create_load_balancer_listeners {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "create_load_balancer_listeners(): -load_balancer_name argument missing";
    $args{-listeners} or
        croak "create_load_balancer_listeners(): -listeners option missing";

    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => 'LoadBalancerName',
                                    });
    push @params, $self->_listener_parm($args{-listeners});
    return $self->elb_call('CreateLoadBalancerListeners',@params);
}

=head2 $success = $ec2->delete_load_balancer_listeners(-load_balancer_name  => $name,
                                                       -load_balancer_ports => \@ports)

Deletes listeners from the ELB for the specified port.

Arguments:

 -load_balancer_name     The name of the ELB

 -load_balancer_ports    An arrayref of strings or literal string containing
                         the port numbers.

 -ports                  Alias for -load_balancer_ports

 -lb_name                Alias for -load_balancer_name

Returns true on successful execution.

=cut

sub delete_load_balancer_listeners {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_ports} ||= $args{-ports};
    $args{-load_balancer_name} or
        croak "delete_load_balancer_listeners(): -load_balancer_name argument missing";
    $args{-load_balancer_ports} or
        croak "delete_load_balancer_listeners(): -load_balancer_ports argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'LoadBalancerPorts',
                                    });
    return $self->elb_call('DeleteLoadBalancerListeners',@params);
}

=head2 @z = $ec2->disable_availability_zones_for_load_balancer(-load_balancer_name => $name,
                                                               -availability_zones => \@zones)

Removes the specified EC2 Availability Zones from the set of configured
Availability Zones for the ELB.  There must be at least one Availability Zone
registered with a LoadBalancer at all times.  Instances registered with the ELB
that are in the removed Availability Zone go into the OutOfService state.

Arguments:

 -load_balancer_name    The name of the ELB

 -availability_zones    Arrayref or literal string of availability zone names
                        (ie. us-east-1a)

 -zones                 Alias for -availability_zones

 -lb_name               Alias for -load_balancer_name


Returns an array of L<VM::EC2::AvailabilityZone> objects now associated with the ELB.

=cut

sub disable_availability_zones_for_load_balancer {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-availability_zones} ||= $args{-zones};
    $args{-load_balancer_name} or
        croak "disable_availability_zones_for_load_balancer(): -load_balancer_name argument missing";
    $args{-availability_zones} or
        croak "disable_availability_zones_for_load_balancer(): -availability_zones argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'AvailabilityZones',
                                    });
    my @zones = $self->elb_call('DisableAvailabilityZonesForLoadBalancer',@params) or return;
    return $self->describe_availability_zones(@zones);
}

=head2 @z = $ec2->enable_availability_zones_for_load_balancer(-load_balancer_name => $name,
                                                              -availability_zones => \@zones)

Adds one or more EC2 Availability Zones to the ELB.  The ELB evenly distributes
requests across all its registered Availability Zones that contain instances.

Arguments:

 -load_balancer_name    The name of the ELB

 -availability_zones    Array or literal string of availability zone names
                        (ie. us-east-1a)

 -zones                 Alias for -availability_zones

 -lb_name               Alias for -load_balancer_name

Returns an array of L<VM::EC2::AvailabilityZone> objects now associated with the ELB.

=cut

sub enable_availability_zones_for_load_balancer {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-availability_zones} ||= $args{-zones};
    $args{-load_balancer_name} or
        croak "enable_availability_zones_for_load_balancer(): -load_balancer_name argument missing";
    $args{-availability_zones} or
        croak "enable_availability_zones_for_load_balancer(): -availability_zones argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'AvailabilityZones',
                                    });
    my @zones = $self->elb_call('EnableAvailabilityZonesForLoadBalancer',@params) or return;
    return $self->describe_availability_zones(@zones);
}

=head2 @i = $ec2->register_instances_with_load_balancer(-load_balancer_name => $name,
                                                        -instances          => \@instance_ids)

Adds new instances to the ELB.  If the instance is in an availability zone that
is not registered with the ELB will be in the OutOfService state.  Once the zone
is added to the ELB the instance will go into the InService state.

Arguments:

 -load_balancer_name    The name of the ELB

 -instances             An arrayref or literal string of Instance IDs.

 -lb_name               Alias for -load_balancer_name

Returns an array of instances now associated with the ELB in the form of
L<VM::EC2::Instance> objects.

=cut

sub register_instances_with_load_balancer {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-instances} ||= $args{-instance_id};
    $args{-load_balancer_name} or
        croak "register_instances_with_load_balancer(): -load_balancer_name argument missing";
    $args{-instances} or
        croak "register_instances_with_load_balancer(): -instances argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm          => 'LoadBalancerName',
                                        elb_instance_id_list => 'Instances',
                                    });
    my @i = $self->elb_call('RegisterInstancesWithLoadBalancer',@params) or return;
    return $self->describe_instances(@i);
}

=head2 @i = $ec2->deregister_instances_from_load_balancer(-load_balancer_name => $name,
                                                          -instances          => \@instance_ids)

Deregisters instances from the ELB. Once the instance is deregistered, it will
stop receiving traffic from the ELB. 

Arguments:

 -load_balancer_name    The name of the ELB

 -instances             An arrayref or literal string of Instance IDs.

 -lb_name               Alias for -load_balancer_name

Returns an array of instances now associated with the ELB in the form of
L<VM::EC2::Instance> objects.

=cut

sub deregister_instances_from_load_balancer {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-instances} ||= $args{-instance_id};
    $args{-load_balancer_name} or
        croak "deregister_instances_from_load_balancer(): -load_balancer_name argument missing";
    $args{-instances} or
        croak "deregister_instances_from_load_balancer(): -instances argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm          => 'LoadBalancerName',
                                        elb_instance_id_list => 'Instances',
                                    });
    my @i = $self->elb_call('DeregisterInstancesFromLoadBalancer',@params) or return;
    return $self->describe_instances(@i);
}

=head2 $success = $ec2->set_load_balancer_listener_ssl_certificate(-load_balancer_name => $name,
                                                                   -load_balancer_port => $port,
                                                                   -ssl_certificate_id => $cert_id)

Sets the certificate that terminates the specified listener's SSL connections.
The specified certificate replaces any prior certificate that was used on the
same ELB and port.

Required arguments:

 -load_balancer_name    The name of the the ELB.

 -load_balancer_port    The port that uses the specified SSL certificate.

 -ssl_certificate_id    The ID of the SSL certificate chain to use.  See the
                        AWS Identity and Access Management documentation under
                        Managing Server Certificates for more information.

Alias arguments:

 -lb_name    Alias for -load_balancer_name

 -port       Alias for -load_balancer_port

 -cert_id    Alias for -ssl_certificate_id

Returns true on successful execution.

=cut

sub set_load_balancer_listener_ssl_certificate {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_port} ||= $args{-port};
    $args{-ssl_certificate_id} ||= $args{-cert_id};
    $args{-load_balancer_name} or
        croak "set_load_balancer_listener_ssl_certificate(): -load_balancer_name argument missing";
    $args{-load_balancer_port} or
        croak "set_load_balancer_listener_ssl_certificate(): -load_balancer_port argument missing";
    $args{-ssl_certificate_id} or
        croak "set_load_balancer_listener_ssl_certificate(): -ssl_certificate_id argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(LoadBalancerName LoadBalancerPort)],
                                    });
    push @params,('SSLCertificateId'=>$args{-ssl_certificate_id}) if $args{-ssl_certificate_id};
    return $self->elb_call('SetLoadBalancerListenerSSLCertificate',@params);
}

=head2 @states = $ec2->describe_instance_health(-load_balancer_name => $name,
                                                -instances          => \@instance_ids)

Returns the current state of the instances of the specified LoadBalancer. If no
instances are specified, the state of all the instances for the ELB is returned.

Required arguments:

    -load_balancer_name     The name of the ELB

Optional parameters:

    -instances              Literal string or arrayref of Instance IDs

    -lb_name                Alias for -load_balancer_name

    -instance_id            Alias for -instances

Returns an array of L<VM::EC2::ELB::InstanceState> objects.

=cut

sub describe_instance_health {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-instances} ||= $args{-instance_id};
    $args{-load_balancer_name} or
        croak "describe_instance_health(): -load_balancer_name argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm          => 'LoadBalancerName',
                                        elb_instance_id_list => 'Instances',
                                    });
    return $self->elb_call('DescribeInstanceHealth',@params);
}

=head2 $success = $ec2->create_load_balancer_policy(-load_balancer_name => $name,
                                                    -policy_name        => $policy,
                                                    -policy_type_name   => $type_name,
                                                    -policy_attributes  => \@attrs)

Creates a new policy that contains the necessary attributes depending on the
policy type. Policies are settings that are saved for your ELB and that can be
applied to the front-end listener, or the back-end application server,
depending on your policy type.

Required Arguments:

 -load_balancer_name   The name associated with the LoadBalancer for which the
                       policy is being created. This name must be unique within
                       the client AWS account.

 -policy_name          The name of the ELB policy being created. The name must
                       be unique within the set of policies for this ELB.

 -policy_type_name     The name of the base policy type being used to create
                       this policy. To get the list of policy types, use the
                       describe_load_balancer_policy_types function.

Optional Arguments:

 -policy_attributes    or hashref containing AttributeName and AttributeValue
                         or
                       Arrayref of VM::EC2::ELB::PolicyAttribute object or single object

 -lb_name              Alias for -load_balancer_name

Returns true if successful.

=cut

sub create_load_balancer_policy {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "create_load_balancer_policy(): -load_balancer_name argument missing";
    $args{-policy_name} or
        croak "create_load_balancer_policy(): -policy_name argument missing";
    $args{-policy_type_name} or
        croak "create_load_balancer_policy(): -policy_type_name argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm              => [qw(LoadBalancerName
                                                                        PolicyName
                                                                        PolicyTypeName)],
                                        elb_attr_name_value_parm => 'PolicyAttributes',
                                    });
    return $self->elb_call('CreateLoadBalancerPolicy',@params);
}

=head2 $success = $ec2->delete_load_balancer_policy(-load_balancer_name => $name,
                                                    -policy_name        => $policy)

Deletes a policy from the ELB. The specified policy must not be enabled for any
listeners.

Arguments:

 -load_balancer_name    The name of the ELB

 -policy_name           The name of the ELB policy

 -lb_name               Alias for -load_balancer_name

Returns true if successful.

=cut

sub delete_load_balancer_policy {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "delete_load_balancer_policy(): -load_balancer_name argument missing";
    $args{-policy_name} or
        croak "delete_load_balancer_policy(): -policy_name argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm => [qw(LoadBalancerName PolicyName)],
                                    });
    return $self->elb_call('DeleteLoadBalancerPolicy',@params);
}

=head2 @policy_descs = $ec2->describe_load_balancer_policies(-load_balancer_name => $name,
                                                             -policy_names       => \@names)

Returns detailed descriptions of ELB policies. If you specify an ELB name, the
operation returns either the descriptions of the specified policies, or
descriptions of all the policies created for the ELB. If you don't specify a ELB
name, the operation returns descriptions of the specified sample policies, or 
descriptions of all the sample policies. The names of the sample policies have 
the ELBSample- prefix.

Optional Arguments:

 -load_balancer_name  The name of the ELB.

 -policy_names        The names of ELB policies created or ELB sample policy names.

 -lb_name             Alias for -load_balancer_name

Returns an array of L<VM::EC2::ELB::PolicyDescription> objects if successful.

=cut

sub describe_load_balancer_policies {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-policy_names} ||= $args{-policy_name};
    $args{-load_balancer_name} or
        croak "describe_load_balancer_policies(): -load_balancer_name argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'PolicyNames',
                                    });
    return $self->elb_call('DescribeLoadBalancerPolicies',@params);
}

=head2 @policy_types = $ec2->describe_load_balancer_policy_types(-policy_type_names => \@names)

Returns meta-information on the specified ELB policies defined by the Elastic
Load Balancing service. The policy types that are returned from this action can
be used in a create_load_balander_policy call to instantiate specific policy
configurations that will be applied to an ELB.

Required arguemnts:

 -load_balancer_name    The name of the ELB.

Optional arguments:

 -policy_type_names    Literal string or arrayref of policy type names

 -names                Alias for -policy_type_names

Returns an array of L<VM::EC2::ELB::PolicyTypeDescription> objects if successful.

=cut

sub describe_load_balancer_policy_types {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-policy_type_names} ||= $args{-names};
    $args{-load_balancer_name} or
        croak "describe_load_balancer_policies(): -load_balancer_name argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'PolicyTypeNames',
                                    });
    return $self->elb_call('DescribeLoadBalancerPolicyTypes',@params);
}

=head2 $success = $ec2->set_load_balancer_policies_of_listener(-load_balancer_name => $name,
                                                               -load_balancer_port => $port,
                                                               -policy_names       => \@names)

Associates, updates, or disables a policy with a listener on the ELB.  Multiple
policies may be associated with a listener.

Required arguments:

 -load_balancer_name    The name associated with the ELB.

 -load_balancer_port    The external port of the LoadBalancer with which this
                        policy applies to.

 -policy_names          List of policies to be associated with the listener.
                        Currently this list can have at most one policy. If the
                        list is empty, the current policy is removed from the
                        listener.  String or arrayref.

Returns true if successful.

=cut

sub set_load_balancer_policies_of_listener {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_port} ||= $args{-port};
    $args{-load_balancer_name} or
        croak "set_load_balancer_policies_of_listener(): -load_balancer_name argument missing";
    $args{-load_balancer_port} or
        croak "set_load_balancer_policies_of_listener(): -load_balancer_port argument missing";
    $args{-policy_names} or
        croak "set_load_balancer_policies_of_listener(): -policy_names argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => [qw(LoadBalancerName LoadBalancerPort)],
                                        member_list_parm => 'PolicyNames',
                                    });
    return $self->elb_call('SetLoadBalancerPoliciesOfListener',@params);
}

=head2 @sgs = $ec2->apply_security_groups_to_load_balancer(-load_balancer_name => $name,
                                                           -security_groups    => \@groups)

Associates one or more security groups with your ELB in VPC.  The provided
security group IDs will override any currently applied security groups.

Required arguments:

 -load_balancer_name The name associated with the ELB.

 -security_groups    A list of security group IDs to associate with your ELB in
                     VPC. The security group IDs must be provided as the ID and
                     not the security group name (For example, sg-123456).
                     String or arrayref.

Returns a series of L<VM::EC2::SecurityGroup> objects.

=cut

sub apply_security_groups_to_load_balancer {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "apply_security_groups_to_load_balancer(): -load_balancer_name argument missing";
    $args{-security_groups} or
        croak "apply_security_groups_to_load_balancer(): -security_groups argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'SecurityGroups',
                                    });
    my @g = $self->elb_call('ApplySecurityGroupsToLoadBalancer',@params) or return;
    return $self->describe_security_groups(@g);
}

=head2 @subnets = $ec2->attach_load_balancer_to_subnets(-load_balancer_name => $name,
                                                        -subnets            => \@subnets)

Adds one or more subnets to the set of configured subnets for the ELB.

Required arguments:

 -load_balancer_name    The name associated with the ELB.

 -subnets               A list of subnet IDs to add for the ELB.  String or
                        arrayref.

Returns a series of L<VM::EC2::VPC::Subnet> objects corresponding to the
subnets the ELB is now attached to.

=cut

sub attach_load_balancer_to_subnets {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "attach_load_balancer_to_subnets(): -load_balancer_name argument missing";
    $args{-subnets} or
        croak "attach_load_balancer_to_subnets(): -subnets argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'Subnets',
                                    });
    my @sn = $self->elb_call('AttachLoadBalancerToSubnets',@params) or return;
    return $self->describe_subnets(@sn);
}

=head2 @subnets = $ec2->detach_load_balancer_from_subnets(-load_balancer_name => $name,
                                                          -subnets            => \@subnets)

Removes subnets from the set of configured subnets in the VPC for the ELB.

Required arguments:

 -load_balancer_name    The name associated with the ELB.

 -subnets               A list of subnet IDs to add for the ELB.  String or
                        arrayref.

Returns a series of L<VM::EC2::VPC::Subnet> objects corresponding to the
subnets the ELB is now attached to.

=cut

sub detach_load_balancer_from_subnets {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-load_balancer_name} or
        croak "detach_load_balancer_from_subnets(): -load_balancer_name argument missing";
    $args{-subnets} or
        croak "detach_load_balancer_from_subnets(): -subnets argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => 'LoadBalancerName',
                                        member_list_parm => 'Subnets',
                                    });
    my @sn = $self->elb_call('DetachLoadBalancerFromSubnets',@params) or return;
    return $self->describe_subnets(@sn);
}

=head2 $success = $ec2->set_load_balancer_policies_for_backend_server(-instance_port      => $port,
                                                                      -load_balancer_name => $name,
                                                                      -policy_names       => \@policies)

Replaces the current set of policies associated with a port on which the back-
end server is listening with a new set of policies. After the policies have 
been created, they can be applied here as a list.  At this time, only the back-
end server authentication policy type can be applied to the back-end ports;
this policy type is composed of multiple public key policies.

Required arguments:

 -load_balancer_name    The name associated with the ELB.

 -instance_port         The port number associated with the back-end server.

 -policy_names          List of policy names to be set. If the list is empty,
                        then all current polices are removed from the back-end
                        server.

Aliases:

 -port      Alias for -instance_port
 -lb_name   Alias for -load_balancer_name

Returns true if successful.

=cut

sub set_load_balancer_policies_for_backend_server {
    my $self = shift;
    my %args = @_;
    $args{-load_balancer_name} ||= $args{-lb_name};
    $args{-instance_port} ||= $args{-port};
    $args{-load_balancer_name} or
        croak "set_load_balancer_policies_for_backend_server(): -load_balancer_name argument missing";
    $args{-instance_port} or
        croak "set_load_balancer_policies_for_backend_server(): -instance_port argument missing";
    $args{-policy_names} or
        croak "set_load_balancer_policies_for_backend_server(): -policy_names argument missing";
    my @params = $VEP->format_parms(\%args,
                                    {
                                        single_parm      => [qw(LoadBalancerName InstancePort)],
                                        member_list_parm => 'PolicyNames',
                                    });
    return $self->elb_call('SetLoadBalancerPoliciesForBackendServer',@params);
}

=head1 SEE ALSO

L<VM::EC2>

=head1 AUTHOR

Lance Kinley E<lt>lkinley@loyaltymethods.com<gt>.
Lincoln Stein E<lt>lincoln.stein@gmail.comE<gt>.

Copyright (c) 2012 Loyalty Methods, Inc.
Copyright (c) 2012 Ontario Institute for Cancer Research

This package and its accompanying libraries is free software; you can
redistribute it and/or modify it under the terms of the GPL (either
version 1, or at your option, any later version) or the Artistic
License 2.0.  Refer to LICENSE for the full license text. In addition,
please see DISCLAIMER.txt for disclaimers of warranty.

=cut


1;
