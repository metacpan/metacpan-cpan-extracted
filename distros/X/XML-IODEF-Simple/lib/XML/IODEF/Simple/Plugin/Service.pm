package XML::IODEF::Simple::Plugin::Service;

use Regexp::Common qw/net/;

sub prepare {
    my $class   = shift;
    my $info    = shift;
    return(0) unless($info->{'portlist'} || $info->{'protocol'});
    return(1);
}

sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;

    $info->{'protocol'} = normalize($info->{'protocol'}) if($info->{'protocol'});

    unless($iodef->get('IncidentEventDataFlowSystemServicePortlist')){
        $iodef->add('IncidentEventDataFlowSystemServicePortlist',$info->{'portlist'}) if($info->{'portlist'});
    }
    unless($iodef->get('IncidentEventDataFlowSystemServiceip_protocol')){
        $iodef->add('IncidentEventDataFlowSystemServiceip_protocol',$info->{'protocol'}) if($info->{'protocol'});
    }
    return($iodef);
}

sub normalize {
    my $proto = shift;
    return $proto if($proto =~ /^\d+$/);

    for(lc($proto)){
        if(/^tcp$/){
            return(6);
        }
        if(/^udp$/){
            return(17);
        }
        if(/^icmp$/){
            return(1);
        }
    }
    return($proto);
}
1;
