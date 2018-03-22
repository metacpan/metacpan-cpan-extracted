package t::ExampleProject::KidsShow::TimberBeam;
use t::ExampleProject::KidsShow::OldClown;
use t::ExampleProject::KidsShow::NewClown qw ( ShowOfWeight );
use strict;

sub UpAndDown {
    my ($Number1, $Number2) = @_;

    my $WeightNewClown = ShowOfWeight($Number1);
    my $WeightOldClown = t::ExampleProject::KidsShow::OldClown::BeHeavy($Number2);
    if($WeightNewClown > $WeightOldClown){
        return 'New clown wins';
    }elsif($WeightNewClown == $WeightOldClown){
        return 'balanced';
    }else{
        return 'Old clown wins';
    }
    return;
}

sub GetLineUpName {
    my $self = shift;
    return 'The historical lake chopper';
}
1;