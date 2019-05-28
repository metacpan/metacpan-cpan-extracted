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
  SKIP: {
        skip "Can't check filetest '$func' on Perl < 5.31.1", 1 if "$]" < 5.031001 and $func =~ /\A-.\z/;
        eval "sub { no bareword::filehandles; $func BAREWORD }";
        $@ =~ s/-([oO])/"-".chr(ord($1)^0x20)/e if "$]" < 5.008008; # workaround Perl RT#36672
        like "$@", qr/^Use of bareword filehandle in \Q$func\E\b/, "$func BAREWORD dies";
    }
    foreach my $fh ("", qw(STDIN STDERR STDOUT DATA ARGV)) {
        eval "sub { no bareword::filehandles; $func $fh }";
        unlike "$@", qr/Use of bareword filehandle/, "$func $fh lives";
    }
}

foreach my $func (qw(accept pipe socketpair)) {
    eval "sub { no bareword::filehandles; $func my \$fh, BAREWORD }";
    like "$@", qr/^Use of bareword filehandle in \Q$func\E\b/, "$func my \$fh, BAREWORD dies";
}


SKIP: {
    skip "no stacked file tests on perl $]", 2 if "$]" < 5.010;
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    ok -d -e ".", "stacked file test works";
    is $warnings, '', "no warnings for stacked file test";
};

done_testing;

