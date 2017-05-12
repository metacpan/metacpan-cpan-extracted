package VM::EC2::ReservedInstance::ParmParser;

use base 'VM::EC2::ParmParser';

sub ri_target_config_parm {
    my $self = shift;
    my ($argname,$val) = @_;
    my @param;

    my @config = ref $val eq 'ARRAY' ? @$val : ( $val );
    for (my $i=0; $i<@config; $i++) {
        my $config = $config[$i];
        my $n = $i+1;
        foreach my $p (qw(AvailabilityZone Platform
                          InstanceCount InstanceType)) {
            push @param, ("ReservedInstancesConfigurationSetItemType.$n.$p" =>
                              $config->{$p}) if $config->{$p};
        }
    }
    return @param;
}

sub ri_price_sched_parm {
    my $self = shift;
    my ($argname,$val) = @_;
    return unless $val && ref $val eq 'HASH';
    my @param;

    my $i = 0;
    foreach my $month (keys %$val) {
        push @param, "$argname.$i.Price" => $val->{$month};
        push @param, "$argname.$i.Term" => $month;
        $i++;
    }
    return @param;
}

1;
