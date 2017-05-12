package XML::IODEF::Simple::Plugin::Hijacked;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    return(0) unless($info->{'impact'});
    return(0) unless($info->{'impact'} =~ /hijacked/);
    return(1);
}

sub convert {
    my $class = shift;
    my $info = shift;
    my $iodef = shift;

    unless($info->{'severity'}){
        $iodef->add('IncidentAssessmentImpactseverity','medium');
    }

    return($iodef);
}

1;

