#!perl
#
# test that command() is less horribly buggy than it has been
#
# NOTE with chdir a relative command (e.g. "./bin/foo") may need to be
# fully qualified with something like rel2abs of File::Spec::Functions.
# perl scripts may need to be called via $^X, '--', './bin/foo' to use
# the correct perl and to turn off perl's command line switches

use File::Spec::Functions qw(catdir splitdir);
# srand produces noise on test failure and isn't really relevant to any
# of the tests here
use Test2::V0 -no_srand => 1;
use Test2::Tools::Command;
use Test2::API 'intercept';

# an exact plan is annoying, but will catch the case where some of the
# tests are unexpectedly not running, as was the case in version 0.10 of
# this module
plan 29;

# including the PID is not necessary but helps avoid the program being
# tested cheating on the test by simply regurgitating a static input
$ENV{FOO} = "bar$$";
my $barout = "bar$$\n";

my ( $ok, $status, $out, $err ) = command {
    args   => [ $^X, '-E', 'say $ENV{FOO};warn "err\n"' ],
    stdout => $barout,
    stderr => "err\n",
};
# do not waste CPU if we cannot run the first program (opinions
# vary here; another school of thought is to keep going for as long
# as possible)
bail_out "cannot even run perl??" unless $ok;
is $status, 0;
is $$out,   $barout;
is $$err,   "err\n";

# prefix the subsequent {args} with ...
@Test2::Tools::Command::command = ( $^X, '-E' );

# sometimes extra tests will need to be made on the output if it does
# not fit neatly into a qr// or exact string match
$out = (
    command {
        args    => ['use Cwd; print getcwd, "\0"; say $ENV{FOO}; warn readline'],
        binmode => ':encoding(UTF-8)',
        chdir   => catdir(qw{t unsupercilious}),
        env     => { FOO => "ZZZ$$" },
        stdin   => "baz$$\n",    # emits via stderr
        stdout  => qr/ZZZ$$/,    # custom ENV, hopefully
        stderr  => qr/baz$$/,
    }
)[2];
if ( $$out =~ m/^([^\0]+)/ ) {
    my @dirs = splitdir $1;
    is $dirs[-1], 'unsupercilious';
} else {
    diag sprintf "%vx", $$out;
    bail_out 'did not match getcwd??';
}

# this also tests the case that {args} is unset for coverage
{
    local @Test2::Tools::Command::command = ( $^X, '-e', 'sleep 99' );
    like dies { command { timeout => 1 } }, qr/timeout/;
}

command {
    args         => ['kill TERM => $$'],
    status       => { code => 0, iscore => 0, signal => 1 },
    munge_signal => 1,
};

my $rand_status = 42 + int rand 42;
command {
    args         => ["say q{out$$}; warn qq{err\n}; exit $rand_status"],
    munge_status => 1,
    status       => 1,
    stdout       => "out$$\n",
    stderr       => "err\n"
};

# PORTABILITY the signal may vary here, this is for OpenBSD 7.2. because
# lots of CPAN Tester systems fail here, this has been made author-only
SKIP: {
    skip( "no author tests", 3 ) unless $ENV{AUTHOR_TEST_JMATES};
    command {
        args   => ['CORE::dump'],
        status => { code => 0, iscore => 1, signal => 6 },
    };
    unlink 'perl.core';
}

command {
    args         => ['exit 0'],
    munge_status => 1,
    munge_signal => 1,
    status       => undef,
    timeout      => 0,
};

# PORTABILITY the error message depends on File::chdir
like dies {
    command {
        args  => ['exit 0'],
        chdir => "no/such/dir/$$/unless/someone/mkdir/this",
    }
}, qr/Failed to change directory/;
# TODO failing on chdir back to $orig_dir that no longer exists might be
# tricky, and anyways that's a problem for File::chdir to handle

# failure is an option: what do test errors look like? (they were not
# very good in version 0.01)
#command { args => [q(say "out";warn "err\n"; exit 1)] };

# who tests the tests? coverage for failed test branches (which exposed
# a bug or two...)
my $events = intercept {
    command { args => ['say "out";warn "err\n";exit 23'], name => "stringy" };
    command {
        name   => "regexy",
        args   => ['say "out";warn "err\n";exit 51'],
        stdout => qr/doesnotmatch/,
        stderr => qr/doesnotmatch/
    };
};
my $state = $events->state;
is $state->{failed}, 6;

for my $e ( $events->event_list ) {
    if ( $e->name =~ m/^std.*stringy/ ) {
        is $e->info->[0]->details, 'expected equality with q{}';
    } elsif ( $e->name =~ m/^std.*regexy/ ) {
        like $e->info->[0]->details, qr/expected match.*doesnotmatch/;
    }
}
