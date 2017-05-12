# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Connector::ResponseHandle;

use base qw(IO::Handle);
use strict;
use warnings;

use Servlet::Util::Exception ();

sub new {
    my $self = shift;
    my $response = shift;

    $self = $self->SUPER::new(@_);

    ${*self}->{wombat_connector_responsehandle_count} = 0;
    ${*self}->{wombat_connector_responsehandle_response} = $response;
    ${*self}->{wombat_connector_responsehandle_closed} = undef;

    return $self;
}

# overridden IO::Handle methods

sub close {
    my $self = shift;

    if (${*self}->{wombat_connector_responsehandle_closed}) {
        my $msg = "close attempted on closed output handle";
        Servlet::Util::IOException->throw($msg);
    }

    eval {
        ${*self}->{wombat_connector_responsehandle_response}->flushBuffer();
        ${*self}->{wombat_connector_responsehandle_closed} = 1;
    };
    if ($@) {
        Servlet::Util::IOException->throw($@);
    }

    return 1;
}

sub flush {
    my $self = shift;

    if (${*self}->{wombat_connector_responsehandle_closed}) {
        my $msg = "flush attempted on closed output handle";
        Servlet::Util::IOException->throw($msg);
    }

    eval {
        ${*self}->{wombat_connector_responsehandle_response}->flushBuffer();
    };
    if ($@) {
        Servlet::Util::IOException->throw($@);
    }

    return 1;
}

sub print {
    my $self = shift;

    $self->write(join('', @_));

    return 1;
}

sub write {
    my $self = shift;

    if (${*self}->{wombat_connector_responsehandle_closed}) {
        my $msg = "write attempted on closed output handle";
        Servlet::Util::IOException->throw($msg);
    }

    # delegate to the response so that it can buffer output
    my $written =
        ${*self}->{wombat_connector_responsehandle_response}->write(@_);
    ${*self}->{wombat_connector_responsehandle_count} += $written;

    return $written;
}

# package methods

sub closed {
    my $self = shift;

    return ${*self}->{wombat_connector_responsehandle_closed};
}

1;
__END__
