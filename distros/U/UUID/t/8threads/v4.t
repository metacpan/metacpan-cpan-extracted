#
# make sure v4 works in threads.
#
use strict;
use warnings;
use version 0.77;
use Config;

BEGIN {
    unless ($Config{useithreads}) {
        print "1..0 # SKIP no ithreads\n";
        exit 0;
    }
    my $v = version->parse($Config{version});
    if ($v >= '5.9.5' and $v < '5.10.1') {
        # See note in t/5persist/threads.t.
        print "1..0 # SKIP threads broken in Perl_parser_dup\n";
        exit 0;
    }
    if ($Config{osname} eq 'openbsd' and $Config{osvers} eq '7.0') {
        print "1..0 # SKIP OpenBSD 7.0 threads broken?\n";
        exit 0;
    }
}

use threads;
use threads::shared;
use Thread::Semaphore;
use Test::More;
use MyNote;

use vars qw(@OPTS);

BEGIN {
    @OPTS = qw(uuid4);
    ok 1, 'began';
}

use UUID @OPTS;
ok 1, 'loaded';

my $sync = 0;
my $seen = {};
my $mutex = Thread::Semaphore->new(0); # locked
note 'mutex init';
share($sync);
note 'shared sync';
share($seen);
note 'shared seen';
share($mutex);
note 'shared mutex';

my ($t10, $t11, $t12, $t13, $t14, $t15, $t16, $t17, $t18, $t19);

my $cnt = 0;
$t10 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t11 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t12 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t13 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t14 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t15 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t16 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t17 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t18 = threads->create(\&doit, ++$cnt);
note 'threads created';
$t19 = threads->create(\&doit, ++$cnt);
note 'threads created';

note 'waiting';
my $timeout = 20; # 5 secs
while (1) {
    my $s;
    { lock($sync); $s = $sync }
    note "so far: $s";
    last if $s >= 10;
    select undef, undef, undef, 0.25;
    next if --$timeout > 0;
    fail 'Waiting too long';
    plan skip_all => 'HUNG';
}

note 'do it';
$mutex->up(10);  # thundering herd!

$t10->join; $t11->join; $t12->join; $t13->join; $t14->join;
$t15->join; $t16->join; $t17->join; $t18->join; $t19->join;

sub doit {
    note 'in doit()';
    my $i = shift;
    note "reporting $i";
    { lock $sync; ++$sync }
    note "requesting $i";
    $mutex->down;
    note "generating $i";
    my $uu = uuid4();
    note "releasing $i";
    $mutex->up;
    note $uu;
    lock $seen;
    note "recording $i";
    ++$seen->{$uu};
}

is scalar(keys %$seen), 10, 'no dupes';
if ((scalar keys %$seen) != 0) {
    note "$_  $seen->{$_}"
        for sort keys %$seen;
}

done_testing;
