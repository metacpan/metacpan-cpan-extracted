package XML::IODEF::Simple::Plugin::Url;

use Regexp::Common qw /URI/;
use URI::Escape;
use Digest::SHA1 qw/sha1_hex/;
use Digest::MD5 qw/md5_hex/;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    my $address = $info->{'address'};
    return unless($address);
    return unless($address =~ /^$RE{'URI'}/ || $address =~ /^$RE{'URI'}{'HTTP'}{-scheme => 'https'}/);
    $address = lc($address);
    $address =~ s/\/$//;
    my $safe = uri_escape($address,'\x00-\x1f\x7f-\xff');
    $address = $safe;
    $info->{'address'} = $safe;
    $info->{'md5'} = md5_hex($safe) unless($info->{'md5'});
    $info->{'sha1'} = sha1_hex($safe) unless($info->{'sha1'});
    unless($info->{'impact'} =~ / url$/){
        $info->{'impact'} = $info->{'impact'}.' url';
    }
    return(1);
}

sub isUrl {
    my $address = shift;
    return unless($address);
    return unless($address =~ /^$RE{'URI'}$/ || $address =~ /^$RE{'URI'}{'HTTP'}{-scheme => 'https'}$/);
    return(1);
}

sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;

    my $address = lc($info->{'address'});

    $iodef->add('IncidentEventDataFlowSystemNodeAddresscategory','ext-value');
    $iodef->add('IncidentEventDataFlowSystemNodeAddressext-category','url');
    $iodef->add('IncidentEventDataFlowSystemNodeAddress',$address);

    $iodef->add('IncidentEventDataFlowSystemAdditionalDatadtype','string');
    $iodef->add('IncidentEventDataFlowSystemAdditionalDatameaning','md5');
    $iodef->add('IncidentEventDataFlowSystemAdditionalData',$info->{'md5'});

    $iodef->add('IncidentEventDataFlowSystemAdditionalDatadtype','string');
    $iodef->add('IncidentEventDataFlowSystemAdditionalDatameaning','sha1');
    $iodef->add('IncidentEventDataFlowSystemAdditionalData',$info->{'sha1'});
    
    my $domain;

    my $port = 80;
    if($address =~ /^(https?\:\/\/)?([A-Za-z0-9-\.]+\.[a-z]{2,5})(:\d+)\/?/){
        $domain = $2;
        $port = $3;
    } elsif($address =~ /^(https?\:\/\/)?($RE{'net'}{'IPv4'})(:\d+)?\//) {
        $domain = $2;
        $port = $3;
        $port = 443 unless($port);
    }
    $port =~ s/^://;
    unless($info->{'portlist'}){
        unless($iodef->get('IncidentEventDataFlowSystemServicePortlist')){
            $iodef->add('IncidentEventDataFlowSystemServicePortlist',$port);
        }
    }
    unless($info->{'protocol'}){
        unless($iodef->get('IncidentEventDataFlowSystemServiceip_protocol')){
        $iodef->add('IncidentEventDataFlowSystemServiceip_protocol',6);
        }
    }

    return($iodef);
}

1;
