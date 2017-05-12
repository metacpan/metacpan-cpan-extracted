package Hardware::UPS::Perl::Constants;

#==============================================================================
# package description:
#==============================================================================
# This package defines the following variables to be used in Perl modules and
# scripts dealing with an UPS. For a detailed description see the pod
# documentation included at the end of this file.
#
# Constants:
# ----------
#   UPSBASENAME     - the basename of the script
#   UPSEXECUTABLE   - the complete path to the script
#   UPSFQDN         - the FQDN of the local host
#   UPSHOSTNAME     - the hostname of the local host
#   UPSLOGFILE      - the default log file
#   UPSMAILTO       - the default address to send mails to in case of alerts
#   UPSPIDFILE      - the standard PID file
#   UPSPORT         - the default serial port
#   UPSSCRIPT       - script name
#   UPSTCPPORT      - the default TCP/IP port for network communication
#
#==============================================================================

#==============================================================================
# Copyright:
#==============================================================================
# Copyright (c) 2007 Christian Reile, <Christian.Reile@t-online.de>. All
# rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#==============================================================================

#==============================================================================
# Entries for Revision Control:
#==============================================================================
# Revision        : $Revision: 1.7 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/14 09:37:26 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Constants.pm,v $
#   Revision 1.7  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.6  2007/04/07 15:13:47  creile
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.5  2007/03/13 17:18:04  creile
#   some beautifications.
#
#   Revision 1.4  2007/03/03 21:09:03  creile
#   usage of perl pragma constant declaring everything as
#   real constants.
#
#   Revision 1.3  2007/02/05 20:32:36  creile
#   almost all constants are in @EXPORT_OK now;
#   pod documentation revised.
#
#   Revision 1.2  2007/02/04 19:01:31  creile
#   bug fix of pod documentation.
#
#   Revision 1.1  2007/02/03 16:44:50  creile
#   initial revision.
#
#
#==============================================================================

#==============================================================================
# module preamble:
#==============================================================================

use strict;

BEGIN {
    use Exporter ();
    use vars     qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    $VERSION     = sprintf( "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/ );

    @ISA         = qw(Exporter);
    @EXPORT      = qw(
    );
    @EXPORT_OK   = qw(
        UPSBASENAME
        UPSEXECUTABLE
        UPSFQDN
        UPSHOSTNAME
        UPSMAILTO
        UPSLOGFILE
        UPSPIDFILE
        UPSPORT
        UPSSCRIPT
        UPSTCPPORT
    );
    %EXPORT_TAGS = qw();

}

use vars @EXPORT;

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   constant                - Perl pragma to declare constants
#   Env                     - Perl module that imports environment variables
#                             as scalars or arrays
#   File::Basename          - Parse file paths into directory, filename and
#                             suffix
#   File::Spec::Functions   - portably perform operations on file names
#   FindBin                 - Locate directory of original perl script
#   Net::Domain             - evaluate the current host's internet name and
#                             domain
#
#==============================================================================

use Env qw(
    UPS_MAILTO
    UPS_PORT
    UPS_TCPPORT
);
use File::Basename ();
use File::Spec::Functions;
use FindBin ();
use Net::Domain;

#==============================================================================
# defining exported constants:
#==============================================================================

use constant UPSFQDN        => Net::Domain->hostfqdn();
use constant UPSHOSTNAME    => Net::Domain->hostname();

use constant UPSMAILTO      => $UPS_MAILTO  ? $UPS_MAILTO  : q{};
use constant UPSPORT        => $UPS_PORT    ? $UPS_PORT    : "/dev/ttyS0";
use constant UPSTCPPORT     => $UPS_TCPPORT ? $UPS_TCPPORT : "9050";

use constant UPSBASENAME    => File::Basename::basename($0);
use constant UPSEXECUTABLE  => catfile $FindBin::Bin, UPSBASENAME;

use constant UPSSCRIPT      => sprintf(
    "%s", UPSBASENAME =~ /\.pl$/ ? $` =~ /(\w+)$/ : UPSBASENAME =~ /(\w+)$/
);

use constant UPSLOGFILE     => "/var/log/" . UPSSCRIPT . ".log";
use constant UPSPIDFILE     => "/var/run/" . UPSSCRIPT . ".pid";

#==============================================================================
# package return:
#==============================================================================
1;

__END__

#==============================================================================
# embedded pod documentation:
#==============================================================================

=pod

=head1 NAME

Hardware::UPS::Perl::Constants - general constants for UPS modules and scripts

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Constants qw(
        UPSBASENAME
        UPSEXECUTABLE
        UPSFQDN
        UPSHOSTNAME
        UPSLOGFILE
        UPSMAILTO
        UPSPIDFILE
        UPSPORT
        UPSTCPPORT
    );

    print STDOUT UPSBASENAME, "\n";
    print STDOUT UPSEXECUTABLE, "\n";
    print STDOUT UPSFQDN, "\n";
    print STDOUT UPSHOSTNAME, "\n";
    print STDOUT UPSLOGFILE, "\n";
    print STDOUT UPSMAILTO, "\n";
    print STDOUT UPSPIDFILE, "\n";
    print STDOUT UPSPORT, "\n";
    print STDOUT UPSSCRIPT, "\n";
    print STDOUT UPSTCPPORT, "\n";

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Constants> provides general constants required for
dealing with an UPS.

=head1 CONSTANTS

=head2 @EXPORT

=over 4

=back

=head2 @EXPORT_OK

=over 4

=item B<UPSBASENAME>

The basename of the calling script. This constant is determined at runtime
using package B<File::Basename>.

=item B<UPSEXECUTABLE>

The full path name of the calling script. This constant is determined at
runtime from B<$UPSBASENAME> using the packages B<File::Spec::Functions> and
B<FindBin>. This might be useful for restarting a program.

=item B<UPSFQDN>

The fully qualified domain name of the local host. The constant is determined
at runtime using the Perl5 extension package B<Net::Domain>.

=item B<UPSHOSTNAME>

The hostname of the local host. The constant is determined at runtime using
the Perl5 extension package B<Net::Domain>.

=item B<UPSLOGFILE>

The default log file F</var/log/UPSSCRIPT.log>.

=item B<UPSMAILTO>

The default mail address to send mails to in case of alerts. This variable is
identical to the environment variable F<UPS_MAILTO>.

=item B<UPSPIDFILE>

The default PID file F</var/run/UPSSCRIPT.pid>.

=item B<UPSPORT>

The default serial port for a local UPS. This constant is set to F</dev/ttyS0>
unless overriden by the environment variable F<UPS_PORT>.

=item B<UPSSCRIPT>

The name of the calling script. This constant is determined at runtime from
B<UPSBASENAME>.

=item B<UPSTCPPORT>

The default TCP/IP port where a remote Hardware::UPS::Perl agent can be found.
This constant is set to F<9050> unless overriden by the environment variable
F<UPS_TCPPORT>.

=back

=head1 SEE ALSO

Env(3pm),
File::Basename(3pm),
File::Spec::Functions(3pm),
FindBin(3pm),
Net::Domain(3pm),
constant(3pm),
Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm)

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Constants> are welcome, though
due to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
