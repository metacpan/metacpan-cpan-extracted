package XML::IODEF::Simple::Plugin::Groups;

sub prepare {
    my $class   = shift;
    my $info    = shift;
    return unless($info->{'guid'});
    return(1);
}

sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;

    my $guid = $info->{'guid'};

    $iodef->add('IncidentAdditionalDatadtype','string');
    $iodef->add('IncidentAdditionalDatameaning','guid');
    $iodef->add('IncidentAdditionalData',$guid);

    return($iodef);
}

1;

