package perfSONAR_PS::OWP::Sum;

require 5.005;
require Exporter;
use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::OWP::Sum

=head1 DESCRIPTION

TBD 

=cut

@ISA    = qw(Exporter);
@EXPORT = qw(parsesum);

#$Sum::REVISION = '$Id: Sum.pm 1877 2008-03-27 16:33:01Z aaron $';
#$VERSION = $Sum::VERSION='1.0';

=head2 parsesum()

TDB

=cut

sub parsesum {
    my ( $sfref, $rref ) = @_;

    while (<$sfref>) {
        my ( $key, $val );
        next if (/^\s*#/);    # comments
        next if (/^\s*$/);    # blank lines

        if ( ( ( $key, $val ) = /^(\w+)\s+(.*?)\s*$/o ) ) {
            $key =~ tr/a-z/A-Z/;
            $$rref{$key} = $val;
            next;
        }

        if (/^<BUCKETS>\s*/) {
            my @buckets;
            my ( $bi, $bn );
        BUCKETS:
            while (<$sfref>) {
                last BUCKETS if (/^<\/BUCKETS>\s*/);
                if ( ( ( $bi, $bn ) = /^\s*(-{0,1}\d+)\s+(\d+)\s*$/o ) ) {
                    push @buckets, $bi, $bn;
                }
                else {
                    warn "SUM Syntax Error[line:$.]: $_";
                    return;
                }
            }
            if ( @buckets > 0 ) {
                $$rref{'BUCKETS'} = join '_', @buckets;
            }
            next;
        }

        if (/^<TTLBUCKETS>\s*/) {
            my @buckets;
            my ( $bi, $bn );
        TTLBUCKETS:
            while (<$sfref>) {
                last TTLBUCKETS if (/^<\/TTLBUCKETS>\s*/);
                if ( ( ( $bi, $bn ) = /^\s*(-{0,1}\d+)\s+(\d+)\s*$/o ) ) {
                    push @buckets, $bi, $bn;
                }
                else {
                    warn "SUM Syntax Error[line:$.]: $_";
                    return;
                }
            }
            if ( @buckets > 0 ) {
                $$rref{'TTLBUCKETS'} = join '_', @buckets;
            }
            next;
        }

        warn "SUM Syntax Error[line:$.]: $_";
        return;
    }

    if ( !defined( $$rref{'SUMMARY'} ) ) {
        warn "perfSONAR_PS::OWP::Sum::parsesum(): Invalid Summary";
        return;
    }

    return 1;
}

1;

__END__

=head1 SEE ALSO

N/A

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: Sum.pm 1877 2008-03-27 16:33:01Z aaron $

=head1 AUTHOR

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
