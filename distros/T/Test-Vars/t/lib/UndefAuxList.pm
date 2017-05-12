package UndefAuxList;

use strict;
use warnings;

# This code comes from DateTime::Locale tools/lib/ModuleGenerator/Locale.pm -
# it's a stripped down version that triggers a bug in multideref->aux_list
sub _build_data_hash {
    my $self = shift;

    my $cal_root;
    my %eraLength;
    return $cal_root->{eras}{ 'era' . $eraLength{42} };
}

1;
