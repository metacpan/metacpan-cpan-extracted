package XML::IODEF::Simple::Plugin::History;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    return(0) unless($info->{'history'});
    return(1);
}

sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;
    my $c = $info->{'history'};

    my @array;
    if(ref($c) eq 'HASH'){
        push(@array,$c);
    } else {
        @array = @$c;
    }
    
    foreach my $h (@array){
        my $action          = $h->{'action'} || 'status-new-info';
        my $restriction     = $h->{'restriction'} || 'private';

        my $role    = $h->{'Contact'}->{'role'} || 'creator';
        my $type    = $h->{'Contact'}->{'type'} || 'person';

        my $root = 'IncidentHistoryHistoryItem';
        $iodef->add($root.'restriction',$restriction);
        $iodef->add($root.'action',$action);
        $iodef->add($root.'DateTime',$h->{'DateTime'});

        $iodef->add($root.'Contacttype',$type);
        $iodef->add($root.'Contactrole',$role);
        $iodef->add($root.'ContactEmail',$h->{'Contact'}->{'email'}) if($h->{'Contact'}->{'email'});
        $iodef->add($root.'ContactContactName',$h->{'Contact'}->{'name'}) if($h->{'Contact'}->{'name'});

        if(my $id = $h->{'IncidentID'}){
            $iodef->add($root.'IncidentIDname',$id->{'name'}) if($id->{'name'});
            $iodef->add($root.'IncidentIDinstance',$id->{'instance'}) if($id->{'instance'});
            $iodef->add($root.'IncidentID',$id->{'content'}) if($id->{'content'});
        }

        $iodef->add($root.'Description',$h->{'Description'});
    }
    return($iodef);
}

1;

