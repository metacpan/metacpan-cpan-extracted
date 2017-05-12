package XML::IODEF::Simple::Plugin::Contact;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    return(0) unless($info->{'contact'});
    return(1);
}

sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;
    my $c = $info->{'contact'};

    my @contacts = (ref($c) eq 'ARRAY') ? @$c : $c;
    
    foreach (@contacts){
        my $role    = $_->{'role'} || 'creator';
        my $type    = $_->{'type'} || 'person';
        my $ad      = $_->{'AdditionalData'};

        $iodef->add('IncidentContacttype',$type);
        $iodef->add('IncidentContactrole',$role);
        $iodef->add('IncidentContactEmail',$_->{'email'}) if($_->{'email'});
        $iodef->add('IncidentContactContactName',$_->{'name'}) if($_->{'name'});
        
        if($ad){
            if(my $sector = $ad->{'sector'}){
                $iodef->add('IncidentContactAdditionalDatadtype','string');
                $iodef->add('IncidentContactAdditionalDatameaning','sector');
                $iodef->add('IncidentContactAdditionalData',$sector);
            }
        }
    }

    return($iodef);
}

1;

