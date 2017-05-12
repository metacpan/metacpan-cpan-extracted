package perfSONAR_PS::OWP;

require 5.005;
require Exporter;
use strict;
use warnings;

use vars qw(@ISA @EXPORT $VERSION);
use constant JAN_1970 => 0x83aa7e80;

our $VERSION = 0.09;

=head1 NAME

perfSONAR_PS::OWP

=head1 DESCRIPTION

TBD 

=cut

use FindBin;
use POSIX;
use Fcntl qw(:flock);
use FileHandle;
use perfSONAR_PS::OWP::Conf;
use perfSONAR_PS::OWP::Utils;

@ISA    = qw(Exporter);
@EXPORT = qw(daemonize setids owpverify_args print_hash);

#$OWP::REVISION = '$Id: OWP.pm 1877 2008-03-27 16:33:01Z aaron $';
#$VERSION = '1.0';

=head2 owpverify_args()

TDB

=cut

sub owpverify_args {
    my ( $arglist, $must, %args ) = @_;

    foreach ( keys %args ) {
        my $name = $_;
        $name =~ tr/a-z/A-Z/;
        if ( $name ne $_ ) {
            $args{$name} = $args{$_};
            delete $args{$_};
        }
    }

    foreach (@$must) {
        return undef if !exists $args{$_};
    }

    my @args = %args;
    return @args;
}

=head2 setids()

TDB

=cut

sub setids {
    my (%args) = @_;
    my ( $uid,  $gid );
    my ( $unam, $gnam );

    $uid = $args{'USER'}  if ( defined $args{'USER'} );
    $gid = $args{'GROUP'} if ( defined $args{'GROUP'} );

    # Don't do anything if we are not running as root.
    return if ( $> != 0 );

    die "Must set User option! (Running as root is folly!)"
        if ( !$uid );

    # set GID first to ensure we still have permissions to.
    if ( defined($gid) ) {
        if ( $gid =~ /\D/ ) {

            # If there are any non-digits, it is a groupname.
            $gid = getgrnam( $gnam = $gid )
                or die "Can't getgrnam($gnam): $!";
        }
        elsif ( $gid < 0 ) {
            $gid = -$gid;
        }
        die("Invalid GID: $gid") if ( !getgrgid($gid) );
        $) = $( = $gid;
    }

    # Now set UID
    if ( $uid =~ /\D/ ) {

        # If there are any non-digits, it is a username.
        $uid = getpwnam( $unam = $uid )
            or die "Can't getpwnam($unam): $!";
    }
    elsif ( $uid < 0 ) {
        $uid = -$uid;
    }
    die("Invalid UID: $uid") if ( !getpwuid($uid) );
    $> = $< = $uid;

    return;
}

=head2 daemonize()

TDB

=cut

sub daemonize {
    my (%args) = @_;
    my ( $dnull, $umask ) = ( '/dev/null', 022 );
    my $fh;

    $dnull = $args{'DEVNULL'} if ( defined $args{'DEVNULL'} );
    $umask = $args{'UMASK'}   if ( defined $args{'UMASK'} );

    if ( defined $args{'PIDFILE'} ) {
        $fh = new FileHandle $args{'PIDFILE'}, O_CREAT | O_RDWR | O_TRUNC;
        unless ( $fh && flock( $fh, LOCK_EX | LOCK_NB ) ) {
            die "Unable to lock pid file $args{'PIDFILE'}: $!";
        }
        $_ = <$fh>;
        if ( defined $_ ) {
            my ($pid) = /(\d+)/;
            chomp $pid;
            die "$FindBin::Script:$pid still running..."
                if ( kill( 0, $pid ) );
        }
    }

    open STDIN,  "$dnull"   or die "Can't read $dnull: $!";
    open STDOUT, ">>$dnull" or die "Can't write $dnull: $!";
    if ( !$args{'KEEPSTDERR'} ) {
        open STDERR, ">>$dnull" or die "Can't write $dnull: $!";
    }

    defined( my $pid = fork ) or die "Can't fork: $!";

    # parent
    exit if $pid;

    # child
    $fh->seek( 0, 0 );
    $fh->print($$);
    undef $fh;
    setsid or die "Can't start new session: $!";
    umask $umask;

    return 1;
}

=head2 print_hash()

TDB

=cut

sub print_hash {
    my ( $name, %hash ) = @_;
    my $key;

    foreach $key ( sort keys(%hash) ) {
        warn "\$$name\{$key\}:\t$hash{$key}\n";
    }
}

#
# Hacks to fix incomplete CGI.pm
#
package CGI;

=head2 script_filename()

TDB

=cut

sub script_filename {
    return $ENV{'SCRIPT_FILENAME'};
}

1;

__END__

=head1 SEE ALSO

L<FindBin>, L<POSIX>, L<Fcntl>, L<FileHandle>, L<perfSONAR_PS::OWP::Conf>,
L<perfSONAR_PS::OWP::Utils>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: OWP.pm 1877 2008-03-27 16:33:01Z aaron $

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
