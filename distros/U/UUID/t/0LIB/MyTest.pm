package MyTest;
use strict;
use warnings;
require Exporter;
require UUID;
use vars qw(@EXPORT $TMPDIR $TMPFILE $TESTS_RUN);
use constant USE_ITHREADS => !!$ENV{USE_ITHREADS};

# this block serves two functions.
# 1) provides an out-of-band means of tracking tests run via tmpfiles
#    since some of the tests call into here from within threads.
# 2) speeds up the non-threaded case by not loading Fcntl / File::Temp.
BEGIN {
    if (USE_ITHREADS) {
        require File::Temp;
        require Fcntl;
        Fcntl->import(qw(
            O_APPEND O_CREAT O_WRONLY LOCK_EX LOCK_UN SEEK_END
        ));
        my $tdo  = File::Temp->newdir('UUID-test-XXXXXXXX', TMPDIR => 1, CLEANUP => 0);
        $TMPDIR  = $tdo->dirname;
        $TMPFILE = File::Temp::tempnam($TMPDIR, 'UUID.runs.');
    }
    else {
        # dummys so the compiler dont whine later
        *O_APPEND = *O_CREAT = *O_WRONLY = sub {};
        *LOCK_EX  = *LOCK_UN = *SEEK_END = sub {};
    }
    $TESTS_RUN = 0;
}

@EXPORT = qw(
    BAIL_OUT cmp_ok fail diag done_testing is isnt like note ok pass
    plan unlike use_ok
);

*import = \&Exporter::import;
sub _err;

our $PLAN_SENT = 0;
our $TESTS_PLANNED = 0;

my $realnode = UUID::_realnode();
substr $realnode, 0, 24, '' if $realnode;

sub note {
    my $work = join '', map { defined($_) ? $_ : '<UNDEF>' } @_;
    chomp $work;

    # hide the real node anywhere it appears.
    $work =~ s/$realnode/XXXXXXXXXXXX/ig
        if $realnode;

    print '# ', $work, "\n";
    undef;
}

sub diag {
    print "#DIAG FIX ME!\n";
}

# some of the tests call these from within threads,
# so try to be super-safe.
sub _TESTS_INC {
    if (USE_ITHREADS) {
        sysopen my $fh, $TMPFILE, O_CREAT|O_APPEND|O_WRONLY, 0600
            or _err "sysopen: ($TMPFILE) $!";
        flock($fh, LOCK_EX) or _err "flock LOCK_EX: ($TMPFILE) $!";
        seek($fh, 0, SEEK_END) or _err "seek: ($TMPFILE) $!";
        syswrite $fh, '+';
        flock($fh, LOCK_UN) or _err "flock LOCK_UN: ($TMPFILE) $!";
        close $fh;
    }
    else {
        ++$TESTS_RUN;
    }
}

sub _TESTS_DEC {
    if (USE_ITHREADS) {
        sysopen my $fh, $TMPFILE, O_CREAT|O_APPEND|O_WRONLY, 0600
            or _err "sysopen: ($TMPFILE) $!";
        flock($fh, LOCK_EX) or _err "flock LOCK_EX: ($TMPFILE) $!";
        seek($fh, 0, SEEK_END) or _err "seek: ($TMPFILE) $!";
        syswrite $fh, '-';
        flock($fh, LOCK_UN) or _err "flock LOCK_UN: ($TMPFILE) $!";
        close $fh;
    }
    else {
        --$TESTS_RUN;
    }
}

sub plan {
    my (%plan) = @_;
    $TESTS_PLANNED = $plan{tests};
}

sub pass (;$) {
    my ($tag) = @_;
    _TESTS_INC;
    if (defined($tag) and $tag ne '') { print "ok # $tag\n" }
    else                              { print "ok\n" }
    undef;
}

sub fail (;$) {
    my ($tag) = @_;
    _TESTS_INC;
    if (defined($tag) and $tag ne '') { print "not ok # $tag\n" }
    else                              { print "not ok\n" }
    undef;
}

sub ok ($;$) {
    my ($val, $tag) = @_;
    _TESTS_INC;
    if ($val) {
        if (defined($tag) and $tag ne '') { print "ok # $tag\n" }
        else                              { print "ok\n" }
        return 1;
    }
    else {
        if (defined($tag) and $tag ne '') { print "not ok # $tag\n" }
        else                              { print "not ok\n" }
        return !!0;
    }
}

sub is ($$;$) {
    my ($v1, $v2, $tag) = @_;
    $tag ||= '';
    _TESTS_INC;
    my $d1 = defined $v1;
    my $d2 = defined $v2;
    if ($d1 and $d2) {
        if ($v1 eq $v2) {
            if (defined($tag) and $tag ne '') { print "ok # $tag\n" }
            else                              { print "ok\n" }
        }
        else {
            if (defined($tag) and $tag ne '') { print "not ok # $tag\n" }
            else                              { print "not ok\n" }
        }
    }
    elsif (!$d1 and !$d2) {
        if (defined($tag) and $tag ne '') { print "ok # $tag\n" }
        else                              { print "ok\n" }
    }
    else {
        if (defined($tag) and $tag ne '') { print "not ok # $tag\n" }
        else                              { print "not ok\n" }
    }
    undef;
}

sub isnt ($$;$) {
    my ($v1, $v2, $tag) = @_;
    $tag ||= '';
    _TESTS_INC;
    unless (defined $v1) { fail $tag; return }
    unless (defined $v2) { fail $tag; return }
    if ($v1 ne $v2) {
        if (defined($tag) and $tag ne '') { print "ok # $tag\n" }
        else                              { print "ok\n" }
    }
    else {
        if (defined($tag) and $tag ne '') { print "not ok # $tag\n" }
        else                              { print "not ok\n" }
    }
    undef;
}

sub like ($$;$) {
    my ($val, $re, $tag) = @_;
    $tag ||= '';
    _TESTS_INC;
    if ($val =~ $re) {
        if (defined($tag) and $tag ne '') { print "ok # $tag\n" }
        else                              { print "ok\n" }
    }
    else {
        if (defined($tag) and $tag ne '') { print "not ok # $tag\n" }
        else                              { print "not ok\n" }
    }
    undef;
}

sub unlike ($$;$) {
    my ($val, $re, $tag) = @_;
    $tag ||= '';
    _TESTS_INC;
    if ($val !~ $re) {
        if (defined($tag) and $tag ne '') { print "ok # $tag\n" }
        else                              { print "ok\n" }
    }
    else {
        if (defined($tag) and $tag ne '') { print "not ok # $tag\n" }
        else                              { print "not ok\n" }
    }
    undef;
}

sub cmp_ok ($$$;$) {
    my ($got, $op, $expect, $tag) = @_;
    $tag ||= '';
    _TESTS_INC;
    unless (defined $got)    { fail $tag; return }
    unless (defined $expect) { fail $tag; return }
    for ($op) {
        /<=/ and do { _TESTS_DEC; ok($got <= $expect, $tag); last };
        />/  and do { _TESTS_DEC; ok($got >  $expect, $tag); last };
        _err "OP UNIMPLEMENTED: '$op'\n";
    }
    undef;
}

sub done_testing {
    unless ($PLAN_SENT) {
        if (USE_ITHREADS) {
            open my $fh, '<', $TMPFILE or _err "open: ($TMPFILE) $!";
            my $dat = join '', <$fh>;
            close $fh;

            my $up = $dat =~ tr/+//;
            my $dn = $dat =~ tr/-//;
            $TESTS_RUN = $up - $dn;
        }
        print "1..$TESTS_RUN\n";
    }
    _cleanup();
}

sub _err {
    my $msg = shift;
    _cleanup();
    my ($pkg, $file, $line) = caller(0);
    die "$msg at file $file line $line\n";
}

sub _cleanup {
    if (USE_ITHREADS) {
        unlink $TMPFILE;
        rmdir  $TMPDIR;
    }
}

sub BAIL_OUT {
    my ($tag) = @_;
    if (defined($tag) and $tag ne '') { print "Bail out!  $tag\n" }
    else                              { print "Bail out!\n" }
}

# borrowed from Test::More (with slight modification)
sub use_ok ($;@) {
    my( $module, @imports ) = @_;

    my %caller;
    @caller{qw/pack file line sub args want eval req strict warn/} = caller(0);

    my ($pack, $filename, $line, $warn) = @caller{qw/pack file line warn/};
    $filename =~ y/\n\r/_/; # so it doesn't run off the "#line $line $f" line

    my $code;
    if( @imports == 1 and $imports[0] =~ /^\d+(?:\.\d+)?$/ ) {
        # probably a version check.  Perl needs to see the bare number
        # for it to work with non-Exporter based modules.
        $code = <<USE;
package $pack;
BEGIN { \${^WARNING_BITS} = \$args[-1] if defined \$args[-1] }
#line $line $filename
use $module $imports[0];
1;
USE
    }
    else {
        $code = <<USE;
package $pack;
BEGIN { \${^WARNING_BITS} = \$args[-1] if defined \$args[-1] }
#line $line $filename
use $module \@{\$args[0]};
1;
USE
    }

    my ($eval_result, $eval_error) = _eval($code, \@imports, $warn);
    my $ok = ok( $eval_result, "use $module;" );

    unless($ok) {
        chomp $eval_error;
        $@ =~ s{^BEGIN failed--compilation aborted at .*$}
                {BEGIN failed--compilation aborted at $filename line $line.}m;
        diag(<<DIAGNOSTIC);
    Tried to use '$module'.
    Error:  $eval_error
DIAGNOSTIC

    }

    return $ok;
}

# borrowed from Test::More
sub _eval {
    my( $code, @args ) = @_;

    # Work around oddities surrounding resetting of $@ by immediately
    # storing it.
    my( $sigdie, $eval_result, $eval_error );
    {
        local( $@, $!, $SIG{__DIE__} );    # isolate eval
        $eval_result = eval $code;              ## no critic (BuiltinFunctions::ProhibitStringyEval)
        $eval_error  = $@;
        $sigdie      = $SIG{__DIE__} || undef;
    }
    # make sure that $code got a chance to set $SIG{__DIE__}
    $SIG{__DIE__} = $sigdie if defined $sigdie;

    return( $eval_result, $eval_error );
}

1;
