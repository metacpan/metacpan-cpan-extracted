# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Servlet::Test::Request;

use base qw(Servlet::ServletRequest Servlet::Test::Dummy);
use strict;
use warnings;

use Servlet::Test::InputHandle ();

sub getInputHandle {
    my $self = shift;

    return Servlet::Test::InputHandle->new();
}

1;
__END__
