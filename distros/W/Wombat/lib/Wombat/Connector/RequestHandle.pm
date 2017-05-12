# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::RequestHandle;

use base qw(IO::Handle);
use strict;
use warnings;

use Servlet::Util::Exception ();

sub new {
    my $self = shift;
    my $request = shift;

    $self = $self->SUPER::new(@_);

    ${*self}->{wombat_connector_requesthandle_closed} = undef;
    ${*self}->{wombat_connector_requesthandle_count} = 0;
    ${*self}->{wombat_connector_requesthandle_length} =
        $request->getContentLength();
    ${*self}->{wombat_connector_requesthandle_handle} = $request->getHandle();
    ${*self}->{wombat_connector_requesthandle_request} = $request;

    return $self;
}

# overridden IO::Handle methods

sub close {
    my $self = shift;

    if (${*self}->{wombat_connector_requesthandle_closed}) {
        my $msg = "close attempted on closed input handle";
        Servlet::Util::IOException->throw($msg);
    }

    ${*self}->{wombat_connector_requesthandle_closed} = 1;

    return 1;
}

sub read {
    my $self = shift;

    if (${*self}->{wombat_connector_requesthandle_closed}) {
        my $msg = "read attempted on closed input handle";
        Servlet::Util::IOException->throw($msg);
    }

    # return EOF if we've read the entire Content-Length bytes
    if (${*self}->{wombat_connector_requesthandle_length} &&
        ${*self}->{wombat_connector_requesthandle_count} >=
        ${*self}->{wombat_connector_requesthandle_length}) {
        return undef;
    }

    my $read;
    eval {
        $read = ${*self}->{wombat_connector_requesthandle_handle}->read(@_);
        ${*self}->{wombat_connector_requesthandle_count} += $read;
    };
    if ($@) {
        Servlet::Util::IOException->throw($@);
    }

    return $read;
}

# package methods

sub closed {
    my $self = shift;

    return ${*self}->{wombat_connector_requesthandle_closed};
}

1;
__END__
