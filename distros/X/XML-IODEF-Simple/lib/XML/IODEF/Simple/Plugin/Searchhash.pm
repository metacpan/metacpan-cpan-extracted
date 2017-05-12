package XML::IODEF::Simple::Plugin::Searchhash;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    my $impact = $info->{'impact'};
    return unless($impact && $impact =~ /search/);
    my $hash = $info->{'md5'} || $info->{'sha1'};

    $hash = lc($hash);
    return(undef) unless($hash && $hash =~ /^[a-f0-9]{32,40}$/);
    return(1);
}

sub convert {
    my $self = shift;
    my $info = shift;
    my $iodef = shift;

    if($info->{'md5'}){
        $iodef->add('IncidentEventDataAdditionalDatadtype','string');
        $iodef->add('IncidentEventDataAdditionalDatameaning','md5');
        $iodef->add('IncidentEventDataAdditionalData',$info->{'md5'});
    }

    if($info->{'sha1'}){
        $iodef->add('IncidentEventDataAdditionalDatadtype','string');
        $iodef->add('IncidentEventDataAdditionalDatameaning','sha1');
        $iodef->add('IncidentEventDataAdditionalData',$info->{'sha1'});
    }

    return $iodef;
}

1;
