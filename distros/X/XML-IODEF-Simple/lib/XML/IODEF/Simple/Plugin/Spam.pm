package XML::IODEF::Simple::Plugin::Spam;

sub prepare {
    my $class   = shift;
    my $info    = shift;

    return(0) unless($info->{'impact'});
    return(0) unless($info->{'impact'} =~ /spam/);
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

