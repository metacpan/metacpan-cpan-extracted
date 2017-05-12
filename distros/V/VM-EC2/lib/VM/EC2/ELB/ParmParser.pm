package VM::EC2::ELB::ParmParser;

=head1 NAME

VM::EC2::ELB::ParmParser - Format parameters for passing to the ELB API

Inherits from and augments VM::EC2::ParmParser with ELB specific parameter
building functions

=head1 SYNOPSIS

=head1 METHODS

=cut

use base 'VM::EC2::ParmParser';

sub elb_instance_id_list {
    my $self = shift;
    my ($parm,$values) = @_;
    return unless defined $values;
    my @param;

    my $c = 1;
    for my $i (ref $values eq 'ARRAY' ? @$values : $values) {
        push @param, ("$parm.member.$c.InstanceId" => $i);
        $c++;
    }
    return @param;
}

sub elb_attr_name_value_parm {
    my $self = shift;
    my ($parm,$values) = @_;
    my @param;

    my $i = 1;
    for my $policy (ref $values && ref $values eq 'ARRAY' ? @$values : $values) {
        if (ref $policy eq 'HASH') {
            next unless (grep(/^AttributeName$/,keys %$policy) && grep(/^AttributeValue$/,keys %$policy));
            push @param,("$parm.member.$i.AttributeName"=> $policy->{AttributeName});
            push @param,("$parm.member.$i.AttributeValue"=> $policy->{AttributeValue});
            $i++;
        } elsif (ref $policy eq 'VM::EC2::ELB::PolicyAttribute') {
            push @param,("$parm.member.$i.AttributeName"=> $policy->AttributeName);
            push @param,("$parm.member.$i.AttributeValue"=> $policy->AttributeValue);
            $i++;
        }
    }
    return @param;
}

sub elb_attr_parm {
    my $self = shift;
    my ($parm,$values) = @_;
    my @params;

    return unless ref $values eq 'HASH';
    foreach my $setting (keys %$values) {
	    push @params, ("LoadBalancerAttributes.$parm.$setting" => $values->{$setting});
    }
    return @params;
}

sub elb_listeners_parm {
    my $self = shift;
    my ($parm,$values) = @_;
    my @param;

    my $i = 1;
    my @p = qw(Protocol LoadBalancerPort InstancePort InstanceProtocol SSLCertificateId);
    for my $lsnr (ref $values eq 'ARRAY' ? @$values : $values) {
        if (ref $lsnr eq 'HASH') {
            foreach my $p (@p) {
                push @param,("$parm.member.$i.$p"=> $lsnr->{$p}) if $lsnr->{$p};
            }
            $i++;
        } elsif (ref $lsnr eq 'VM::EC2::ELB::Listener') {
            foreach my $p (@p) {
                push @param,("$parm.member.$i.$p"=> $lsnr->$p) if $lsnr->$p;
            }
            $i++;
        }
    }
    return @param;
}

1;
