package XML::IODEF::Simple::Plugin::Bgp;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    return(1) if($info->{'prefix'});
    return(1) if($info->{'asn'});
    return(1) if($info->{'cc'});
    return(1) if($info->{'rir'});
    return(0);
}

sub convert {
    my $self = shift;
    my $info = shift;
    my $iodef = shift;

    my $prefix  = $info->{'prefix'};
    my $asn     = $info->{'asn'};
    my $cc      = $info->{'cc'};
    my $rir     = $info->{'rir'};
    my $asn_desc = $info->{'asn_desc'};

    if($prefix){
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatadtype','string');
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatameaning','prefix');
        $iodef->add('IncidentEventDataFlowSystemAdditionalData',$prefix);

    }
    if($asn){
        $asn .= ' '.$asn_desc if($asn_desc);
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatadtype','string');
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatameaning','asn');
        $iodef->add('IncidentEventDataFlowSystemAdditionalData',$asn);
    }
    if($cc){
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatadtype','string');
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatameaning','cc');
        $iodef->add('IncidentEventDataFlowSystemAdditionalData',$cc);
    }
    if($rir){
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatadtype','string');
        $iodef->add('IncidentEventDataFlowSystemAdditionalDatameaning','rir');
        $iodef->add('IncidentEventDataFlowSystemAdditionalData',$rir);
    }
    return $iodef;
}

1;
