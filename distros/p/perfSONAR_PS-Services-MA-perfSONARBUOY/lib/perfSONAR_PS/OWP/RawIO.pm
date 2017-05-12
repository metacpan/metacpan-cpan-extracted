package perfSONAR_PS::OWP::RawIO;

require 5.005;
require Exporter;
use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION);

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::OWP::RawIO

=head1 DESCRIPTION

TBD 

=cut

use POSIX;
use FindBin;

#use Errno qw(EINTR EIO :POSIX);

@ISA    = qw(Exporter);
@EXPORT = qw(sys_readline sys_writeline);

#$RawIO::REVISION = '$Id: RawIO.pm 1877 2008-03-27 16:33:01Z aaron $';
#$VERSION = $RawIO::VERSION='1.0';

=head2 sys_readline()

TDB

=cut

sub sys_readline {
    my (%args) = @_;
    my ( $fh, $tmout ) = ( \*STDIN, 0 );
    my ($cb) = sub {return};
    my $char;
    my $read;
    my $line = "";
    $tmout = $args{'TIMEOUT'}    if ( defined $args{'TIMEOUT'} );
    $fh    = $args{'FILEHANDLE'} if ( defined $args{'FILEHANDLE'} );
    $cb    = $args{'CALLBACK'}   if ( defined $args{'CALLBACK'} );

    while (1) {
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            local $SIG{PIPE} = sub { die "pipe\n" };
            alarm $tmout;
            $read = sysread( $fh, $char, 1 );
            alarm 0;
        };
        if ( !defined($read) ) {
            if ( ( $! == EINTR ) && ( $@ ne "alarm\n" ) && ( $@ ne "pipe\n" ) ) {
                next;
            }
            return &$cb( undef, $@ );
        }
        if ( $read < 1 ) {
            return &$cb( $read, undef );
        }
        if ( $char eq "\n" ) {

            #warn "RECV: $line\n";
            return $line;
        }
        $line .= $char;
    }
    return;
}

=head2 sys_writeline()

TDB

=cut

sub sys_writeline {
    my (%args) = @_;
    my ( $fh, $line, $md5, $tmout ) = ( \*STDOUT, '', undef, 0 );
    my ($cb) = sub {return};
    $line  = $args{'LINE'}       if ( defined $args{'LINE'} );
    $tmout = $args{'TIMEOUT'}    if ( defined $args{'TIMEOUT'} );
    $fh    = $args{'FILEHANDLE'} if ( defined $args{'FILEHANDLE'} );
    $cb    = $args{'CALLBACK'}   if ( defined $args{'CALLBACK'} );
    $md5   = $args{'MD5'}        if ( defined $args{'MD5'} );

    $md5->add($line) if ( ( defined $md5 ) && !( $line =~ /^$/ ) );

    $line .= "\n";
    my $len    = length($line);
    my $offset = 0;

    while ($len) {
        my $written;
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            local $SIG{PIPE} = sub { die "pipe\n" };
            alarm $tmout;
            $written = syswrite $fh, $line, $len, $offset;
            alarm 0;
        };
        if ( !defined($written) ) {
            if ( ( $! == EINTR ) && ( $@ ne "alarm\n" ) && ( $@ ne "pipe\n" ) ) {
                next;
            }
            return &$cb( undef, $@ );
        }
        $len -= $written;
        $offset += $written;
    }

    #warn "TXMT: $line";
    return 1;
}

1;

__END__

=head1 SEE ALSO

L<POSIX>, L<FindBin>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: RawIO.pm 1877 2008-03-27 16:33:01Z aaron $

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
