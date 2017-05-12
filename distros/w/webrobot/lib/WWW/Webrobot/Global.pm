package WWW::Webrobot::Global;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG

use Carp;

{
    my $plan_name = "";

    sub plan_name {
        my ($pkg, $prefix) = @_;
        $plan_name = $prefix if defined $prefix;
        return $plan_name;
    }
}


{
    my $save_memory = 0;
    
    sub save_memory {
        my ($pkg, $save) = @_;
        $save_memory = $save if defined $save;
        return $save_memory;
    }
}

1;

=head1 NAME

WWW::Webrobot::Global - Some global functions (internal)

=cut
