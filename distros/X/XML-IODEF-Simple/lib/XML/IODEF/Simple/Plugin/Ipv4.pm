package XML::IODEF::Simple::Plugin::Ipv4;

use Regexp::Common qw/net/;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    my $address = $info->{'address'};
    return(0) unless($address && $address =~ /^$RE{'net'}{'IPv4'}/);
    if($address =~ /^$RE{'net'}{'IPv4'}$/){
        $info->{'impact'} = $info->{'impact'}.' infrastructure' unless($info->{'impact'} =~ /infrastructure/);
    } else {
        $info->{'impact'} = $info->{'impact'}.' network' unless($info->{'impact'} =~ /network/);
    }
    return(1);
}

sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;

    my $cat = ($info->{'address'} =~ /^$RE{'net'}{'IPv4'}$/) ? 'ipv4-addr' : 'ipv4-net';
    $iodef->add('IncidentEventDataFlowSystemNodeAddresscategory',$cat);
    $iodef->add('IncidentEventDataFlowSystemNodeAddress',$info->{'address'});

    return($iodef);
}

1;

