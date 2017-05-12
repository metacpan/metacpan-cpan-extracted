#!/usr/bin/perl -w

# (C) 2004 Identity Commons.  All Rights Reserved.
# See LICENSE for licensing details

# Author: Fen Labalme <fen@idcommons.net>, <fen@comedia.com>

# Command line interface to XRI Resolver library
# a return value that starts with "$error:" indicates an error

use XRI 0.2.0;
use Getopt::Std;

$VERSION = '0.2.0';

# initialize options system
$Getopt::Std::STANDARD_HELP_VERSION = 1;
our ($opt_l, $opt_n, $opt_s, $opt_t);
getopts('lns:t:');

die "Usage: $0 [-n] [-l] [-s service] [-t type] XRI\n" unless $#ARGV == 0;

getLocalAccess( $ARGV[0] );

sub getLocalAccess {
    my $xri = shift;
    my $XRI = XRI->new($xri);

    eval {
        local (*STDERR) = stderr;
        if ( $opt_n ) {
            # FIXME: HACK: need to get logging done correctly in XRI library
            # FIXME: HACK: only turn on logging when option -d is given.
            open(DN, ">/dev/null") || die "Can't open /dev/null for writing\n";
            *STDERR = *DN;
        }
        if ( $opt_l || $opt_s || $opt_t ) {
            $XRI->resolveToLocalAccessURI($opt_s, $opt_t);
        }
        else {
            $XRI->resolveToAuthorityXML;
        }
    };
    if ( $@ ) {
        chomp $@;
        print "\$error: $@";
        exit 1;
    }
    if ( $opt_l || $opt_s || $opt_t ) {
        print $XRI->{localAccessURL};
    }
    else {
        print $XRI->{descriptorXML};
    }
    exit 0;
}
__END__
=head1 NAME

xriresolve.pl - CLI to Resolver for eXtensible Resource Identifiers

=head1 SYNOPSIS

xriresolve.pl [-n] [-l] [-s service] [-t type] XRI

=head1 ABSTRACT

This is the command line interface to the XRI Resolver library

=head1 DESCRIPTION

This is the command line interface to the XRI Resolver library.
In its default form (with no options) it returns (to STDOUT)
the XRI Descriptor for the Authority portion of the passed XRI.
Tracing information is written to STDERR.

A return value that begins with the string "$error: " indicates an
error.  Text following the $error string attempts to describe the
error, and is documented in the XRI library.

=head2 OPTIONS

B<-l>
    return the Local Access URI (as opposed to the XRIDescriptor XML,
    which is the current default behavior)

B<-n>
    argument to turn off tracing

B<-s service>
    return URI to Authority that matches service

B<-t type>
    return URI to Authority that matches type

=head1 TODO

=over 4

=item *

Note that when returning the XRI Descriptor, the local access URI
segment(s) - e.g. anything after the first forward slash - are lost.
Find them!

=item *

Once tracing is fixed in the XRI library, add a -d (debug) flag to
turn *on* tracing

=back

=head1 SEE ALSO

XRI(3)

Mailing list:
   http://idcommons.net/cgi-bin/mailman/listinfo/icdev

Identity Commons wiki:
    http://wiki.idcommons.net/

=head1 AUTHOR

Fen Labalme, E<lt>fen@idcommons.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Identity Commons

See LICENSE.

=cut
