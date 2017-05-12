package perfSONAR_PS::Collectors::LinkStatus::Agent::Script;

=head1 NAME

perfSONAR_PS::Collectors::LinkStatus::Agent::Script - This module provides an
agent for the Link Status Collector that gets status information by executing a
script.

=head1 DESCRIPTION

This agent will run a script that should print out the link status information
in the format: "timestamp,measurement_value".

=head1 API
=cut

use strict;
use warnings;
use Log::Log4perl qw(get_logger);

our $VERSION = 0.09;

use fields 'TYPE', 'SCRIPT','PARAMETERS';

=head2 new ($self, $status_type, $script, $parameters)
    Creates a new Script Agent of the specified type and with the specified
    script and script parameters.
=cut
sub new {
    my ($class, $type, $script, $parameters) = @_;

    my $self = fields::new($class);

    $self->{"TYPE"} = $type;
    $self->{"SCRIPT"} = $script;
    $self->{"PARAMETERS"} = $parameters;

    return $self;
}

=head2 getType
    Returns the status type of this agent: admin or oper.
=cut
sub getType {
    my ($self) = @_;

    return $self->{TYPE};
}

=head2 setType ($self, $type)
    Sets the status type of this agent: admin or oper.
=cut
sub setType {
    my ($self, $type) = @_;

    $self->{TYPE} = $type;

    return;
}

=head2 setScript ($self, $script)
    Sets the script to be run
=cut
sub setScript {
    my ($self, $script) = @_;

    $self->{SCRIPT} = $script;

    return;
}

=head2 getScript
    Returns the script to be run
=cut
sub getScript {
    my ($self) = @_;

    return $self->{SCRIPT};
}

=head2 setParameters ($self, $parameters)
    Sets the parameters that are passed to the script
=cut
sub setParameters {
    my ($self, $parameters) = @_;

    $self->{PARAMETERS} = $parameters;

    return;
}

=head2 getParameters
    Returns the set of parameters that are passed to the script
=cut
sub getParameters {
    my ($self) = @_;

    return $self->{PARAMETERS};
}

=head2 run ($self)
    This function is called by the collector daemon. It executes the script
    adding the status type ('admin' or 'oper') and any parameters specified as
    parameters to the script.
=cut
sub run {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::LinkStatus::Agent::Script");

    my $cmd = $self->{SCRIPT} . " " . $self->{TYPE};

    if (defined $self->{PARAMETERS}) {
        $cmd .= " " . $self->{PARAMETERS};
    }

    $logger->debug("Command to run: $cmd");

    open my $SCRIPT, "-|", $cmd or return (-1, "Couldn't execute cmd: $cmd");
    my @lines = <$SCRIPT>;
    close($SCRIPT);

    if ($#lines < 0) {
        my $msg = "script returned no output";
        return (-1, $msg);
    }

    if ($#lines > 0) {
        my $msg = "script returned invalid output: more than one line";
        return (-1, $msg);
    }

    $logger->debug("Command returned \"$lines[0]\"");

    chomp($lines[0]);
    my ($measurement_time, $measurement_value) = split(',', $lines[0]);

    if (not defined $measurement_time or $measurement_time eq "") {
        my $msg = "script returned invalid output: does not contain measurement time";
        return (-1, $msg);
    }

    if (not defined $measurement_value or $measurement_value eq "") {
        my $msg = "script returned invalid output: does not contain link status";
        return (-1, $msg);
    }

    $measurement_value = lc($measurement_value);

    return (0, $measurement_time, $measurement_value);
}

1;

__END__

To join the 'perfSONAR-PS' mailing list, please visit:

https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
