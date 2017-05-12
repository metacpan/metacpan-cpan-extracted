#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok 'bareword::filehandles' }

foreach my $func (qw(
    close closedir write eof getc readdir rewinddir select sysread
    sysseek syswrite tell telldir open binmode fcntl flock read seek
    seekdir fileno ioctl opendir stat lstat -R -W -X -r -w -x -e -s -M
    -A -C -O -o -z -S -c -b -f -d -p -u -g -k -l -t -T -B send recv
    socket socketpair bind connect listen accept shutdown getsockopt
    setsockopt getsockname getpeername truncate chdir pipe
)) {
    eval "sub { no bareword::filehandles; $func BAREWORD }";
    $@ =~ s/-([oO])/"-".chr(ord($1)^0x20)/e if "$]" < 5.008008; # workaround Perl RT#36672
    like "$@", qr/^Use of bareword filehandle in \Q$func\E\b/, "$func BAREWORD dies";
    foreach my $fh ("", qw(STDIN STDERR STDOUT DATA ARGV)) {
        eval "sub { no bareword::filehandles; $func $fh }";
        unlike "$@", qr/Use of bareword filehandle/, "$func $fh lives";
    }
}

foreach my $func (qw(accept pipe socketpair)) {
    eval "sub { no bareword::filehandles; $func my \$fh, BAREWORD }";
    like "$@", qr/^Use of bareword filehandle in \Q$func\E\b/, "$func my \$fh, BAREWORD dies";
}

done_testing;

