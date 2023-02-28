#!perl

use strict;
use warnings;

# Can't use done_testing here as "classic" Test::Builder outputs the plan twice
# (The rewrite to use Test2 fixes this, but I don't want to depend on that)
use Test::More tests => 10;
use Test::Warnings;
use Test::Fatal;
use Config;

BEGIN {
    use_ok('Test::NoTty');
}

is(eval "sub foo { without_tty(42); };", undef, "without_tty prototype enforced");
like($@, qr/\AType of arg 1 to Test::NoTty::without_tty must be block or sub /,
     "must be a block or sub");

require './t/force-a-tty.pl';

# A lexical will be a syntax error if I typo it. A fixed string will slip past.
my $dev_tty = '/dev/tty';

my $have = without_tty {
    return 42
        if open my $fh, '+<', $dev_tty;
    # We should get here:
    return 6 * 9;
};
is($have, 54, "Failed to open $dev_tty in the block called by without_tty");

sub die_string {
    die "Exceptions are propagated";
    return 1;
}

like(exception(sub {
    without_tty(\&die_string);
    fail("The code above should have died, hence this line should not execute");
}), qr/\AExceptions are propagated at /);

sub die_object {
    die bless ["The marvel is not that the bear dances well, but that the bear dances at all."],
        "Some::Class";
    return 7;
}

# Object exceptions can't work:
like(exception(sub {
    without_tty(\&die_object);
    fail("The code above should have died, hence this line should not execute");
}), qr/\ASome::Class=ARRAY\(0x/);

is(exception(sub {
    is(without_tty(sub {
        my $have = eval {
            die "This should be trapped";
            1;
        };
        return 1
            if defined $have;
        return $@ =~ qr/\AThis should be trapped at/ ? 3 : 2;
    }), 3, 'eval should "work" in the tested code');
}), undef, 'eval in the tested code should not leak the exception');


my $sig = 'INT';
my $sig_num;
my $i = 0;
for my $name (split ' ', $Config{sig_name}) {
    if ($name eq $sig) {
        $sig_num = $i;
        last;
    }
    ++$i;
}

SKIP: {
    skip("Could not find signal number for $sig", 1)
        unless $sig_num;

    # Signals are reported:
    like(exception(sub {
        without_tty(sub {
            kill $sig, $$;
            return 9;
        });
        fail("The code above should have died, hence this line should not execute");
    }), qr/\ACode called by without_tty\(\) died with signal $sig_num /);
}

# Testing the code for "signals are propagated (best effort)" is rather hard to
# implement reliably. without_tty() tries hard to run the block passed to it
# synchronously - ie ensure that that code runs to completion before returning.
# Meaning that we need some way to trigger a signal during its call waitpid
# which in turn kills the parent process, to trigger the module code that
# propagates that signal to the child, and then what? The child should exit,
# but the parent code isn't robust enough to retry waitpid to get the real
# status...
# The point of the *parent* signal handling was to make control-C interrupt an
# interactive test (rather than the forked child detaching and continuing
# despite the parent exiting and the shell prompt appearing)
# Not to do anything more reliable than that.
