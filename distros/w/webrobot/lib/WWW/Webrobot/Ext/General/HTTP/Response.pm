package WWW::Webrobot::Ext::General::HTTP::Response;
use strict;
use warnings;

# Author: Stefan Trcek
# Copyright(c) 2004 ABAS Software AG


# extend LWPs HTTP::Response without subclassing
package HTTP::Response;
use strict;

sub elapsed_time {
    my ($self, $value) = @_;
    $self->{_elapsed_time} = $value if defined $value;
    return $self->{_elapsed_time} || 0;
}

1;
