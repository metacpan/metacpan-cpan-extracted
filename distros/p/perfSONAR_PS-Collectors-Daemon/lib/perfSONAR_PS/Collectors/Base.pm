package perfSONAR_PS::Collectors::Base;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);

use fields 'CONF', 'DIRECTORY';

our $VERSION = 0.09;

sub new {
    my ($self, $conf, $directory) = @_;

    $self = fields::new($self) unless ref $self;

    if (defined $conf and $conf ne "") {
        $self->{CONF} = \%{$conf};
    }

    if (defined $directory and $directory ne "") {
        $self->{DIRECTORY} = $directory;
    }

    return $self;
}

sub setConf {
    my ($self, $conf) = @_;   
    my $logger = get_logger("perfSONAR_PS::Collectors::Base");

    if(defined $conf and $conf ne "") {
        $self->{CONF} = \%{$conf};
    } else {
        $logger->error("Missing argument."); 
    }

    return;
}

sub setDirectory {
    my ($self, $directory) = @_;   
    my $logger = get_logger("perfSONAR_PS::Collectors::Base");

    if(defined $directory and $directory ne "") {
        $self->{DIRECTORY} = $directory;
    } else {
        $logger->error("Missing argument."); 
    }

    return;
}

sub init {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::Base");

    $logger->error("collectMeasurements() function is not implemented");

    return -1;
}

sub collectMeasurements {
    my ($self) = @_;
    my $logger = get_logger("perfSONAR_PS::Collectors::Base");

    $logger->error("collectMeasurements() function is not implemented");

    return -1;
}

1;

__END__

=head1 NAME

perfSONAR_PS::Collectors::Base - The base module for periodic collectors.

=head1 DESCRIPTION

This module provides a very simple base class to be used by all perfSONAR
collectors.

=head1 SYNOPSIS

=head1 DETAILS

=head1 API

=head2 init($self)
    This function is called by the daemon to initialize the collector. It must
    return 0 on success and -1 on failure.

=head2 collectMeasurements($self)
    This function is called by the daemon to collect and store measurements.

=head1 SEE ALSO

To join the 'perfSONAR-PS' mailing list, please visit:

https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, E<lt>aaron@internet2.eduE<gt>, Jason Zurawski, E<lt>zurawski@internet2.eduE<gt>

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
