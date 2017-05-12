package perfSONAR_PS::OWP::Utils;

require 5.005;
require Exporter;
use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::OWP::Utils

=head1 DESCRIPTION

Auxiliary subs for large time conversions.

=cut

use Math::BigInt;
use Math::BigFloat;
use POSIX;

@ISA    = qw(Exporter);
@EXPORT = qw(time2owptime owptimeadd owpgmtime owptimegm owpgmstring owplocaltime owplocalstring owptrange owptime2time owptstampi owpi2owp owptstampdnum pldatetime owptstamppldatetime owptime2exacttime owpexactgmstring);

#$Utils::REVISION = '$Id: Utils.pm 1877 2008-03-27 16:33:01Z aaron $';
#$VERSION = $Utils::VERSION='1.0';

use constant JAN_1970 => 0x83aa7e80;    # offset in seconds
my $scale = new Math::BigInt 2**32;

=head2 time2owptime()

Convert value return by time() into owamp-style (ASCII form
of the unsigned 64-bit integer [32.32]

=cut

sub time2owptime {
    my $bigtime = new Math::BigInt $_[0];
    $bigtime = ( $bigtime + JAN_1970 ) * $scale;
    $bigtime =~ s/^\+//;
    return $bigtime;
}

=head2 owptime2time()

TDB

=cut

sub owptime2time {
    my $bigtime = new Math::BigInt $_[0];
    $bigtime /= $scale;
    return $bigtime - JAN_1970;
}

=head2 owptimeadd()

Add a number of seconds to an owamp-style number.

=cut

sub owptimeadd {
    my $bigtime = new Math::BigInt shift;

    while ( $_ = shift ) {
        my $add = new Math::BigInt $_;
        $bigtime += ( $add * $scale );
    }

    $bigtime =~ s/^\+//;
    return $bigtime;
}

=head2 owptstampi()

TDB

=cut

sub owptstampi {
    my $bigtime = new Math::BigInt shift;
    return $bigtime >> 32;
}

=head2 owpi2owp()

TDB

=cut

sub owpi2owp {
    my $bigtime = new Math::BigInt shift;

    return $bigtime << 32;
}

=head2 owpgmtime()

TDB

=cut

sub owpgmtime {
    my $bigtime = new Math::BigInt shift;

    my $unixsecs = ( $bigtime / $scale ) - JAN_1970;

    return gmtime($unixsecs);
}

=head2 owptimegm()

TDB

=cut

sub owptimegm {
    $ENV{'TZ'} = 'UTC 0';
    POSIX::tzset();
    my $unixstamp = POSIX::mktime(@_) || return;

    return time2owptime($unixstamp);
}

=head2 pldatetime()

TDB

=cut

sub pldatetime {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $frac ) = @_;

    $frac = 0 if ( !defined($frac) );

    return sprintf "%04d-%02d-%02d.%02d:%02d:%06.3f", $year + 1900, $mon + 1, $mday, $hour, $min, $sec + $frac;
}

=head2 owptstamppldatetime()

TDB

=cut

sub owptstamppldatetime {
    my ($tstamp) = new Math::BigInt shift;
    my ($frac)   = new Math::BigFloat($tstamp);

    # move fractional part to the right of the radix point.
    $frac /= $scale;

    # Now subtract away the integer portion
    $frac -= ( $tstamp / $scale );
    return pldatetime( ( perfSONAR_PS::OWP::Utils::owpgmtime($tstamp) )[ 0 .. 7 ], $frac );
}

=head2 owptstampdnum()

TDB

=cut

sub owptstampdnum {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = perfSONAR_PS::OWP::Utils::owpgmtime(shift);
    return sprintf "%04d%02d%02d", $year + 1900, $mon + 1, $mday;
}

my @dnames = qw(Sun Mon Tue Wed Thu Fri Sat);
my @mnames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

=head2 owpgmstring()

TDB

=cut

sub owpgmstring {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = perfSONAR_PS::OWP::Utils::owpgmtime(shift);
    $year += 1900;
    return sprintf "$dnames[$wday] $mnames[$mon] $mday %02d:%02d:%02d UTC $year", $hour, $min, $sec;
}

=head2 owplocalstring()

TDB

=cut

sub owplocalstring {
    my $bigtime = new Math::BigInt shift;

    my $unixsecs = ( $bigtime / $scale ) - JAN_1970;

    return strftime "%a %b %e %H:%M:%S %Z", localtime;
}

=head2 owplocaltime()

TDB

=cut

sub owplocaltime {
    my $bigtime = new Math::BigInt shift;

    my $unixsecs = ( $bigtime / $scale ) - JAN_1970;

    return localtime($unixsecs);
}

=head2 owptrange()

TDB

=cut

sub owptrange {
    my ( $tstamp, $fref, $lref, $dur ) = @_;

    my ( $first, $last );

    $dur = 900 if ( !defined($dur) );

    undef $$fref;
    undef $$lref;

    if ($$tstamp) {
        if ( $$tstamp =~ /^now$/oi ) {
            undef $$tstamp;
        }
        elsif ( ( $first, $last ) = ( $$tstamp =~ m#^(\d*?)_(\d*)#o ) ) {
            $first = new Math::BigInt $first;
            $last  = new Math::BigInt $last;
            if ( $first > $last ) {
                $$fref = $last + 0;
                $$lref = $first + 0;
            }
            else {
                $$fref = $first + 0;
                $$lref = $last + 0;
            }
        }
        else {
            $$lref = new Math::BigInt $$tstamp;
        }
    }

    if ( !$$tstamp ) {
        $$lref   = new Math::BigInt time2owptime( time() );
        $$tstamp = 'now';
    }

    if ( !$$fref ) {
        $$fref = new Math::BigInt owptimeadd( $$lref, -$dur );
    }

    return 1;
}

=head2 owptime2exacttime()

Convert owp time representation to a unix timestamp with fractional seconds
where applicable.

=cut

sub owptime2exacttime {
    my $bigtime     = new Math::BigInt $_[0];
    my $mantissa    = $bigtime % $scale;
    my $significand = ( $bigtime / $scale ) - JAN_1970;
    return ( $significand . "." . $mantissa );
}

=head2 owpexactgmstring()

Convert owp time representation to a ISO value with fractional seconds where
applicable.

=cut

sub owpexactgmstring {
    my $time = perfSONAR_PS::OWP::Utils::owptime2exacttime(shift);
    my @parts = split( /\./mx, $time );
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday ) = gmtime($time);
    $year += 1900;
    return sprintf "$dnames[$wday] $mnames[$mon] $mday %02d:%02d:%02d.%u UTC $year", $hour, $min, $sec, $parts[1];
}

1;

__END__

=head1 SEE ALSO

L<Math::BigInt>, L<Math::BigFloat>, L<POSIX>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: Utils.pm 1877 2008-03-27 16:33:01Z aaron $

=head1 AUTHOR

Anatoly Karp
Jeff Boote, boote@internet2.edu
Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2002-2008, Internet2

All rights reserved.

=cut
