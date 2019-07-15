#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use lib 't';
use MyTest;
use Benchmark qw/timethis timethese/;
use Devel::Peek;
use Data::Dumper 'Dumper';
use POSIX ":sys_wait_h";

timethis(-1, sub { MyTest::bench_sv_payload_get(1000000); });

exit;

my $o = PXSTB->create();
eval { $o = undef; };

say $o;

timethese(-1, {
    #aaa => sub { AAA1->create(); },
    bbb => sub { PXSTB->create(); },
    #ccc => sub { CCC1->create(); },
});

#my $str = "BBB1->create();" x 100000;
#my $sub = eval "sub { $str }";
#$sub->() for 1..10000;

exit;

say "START";

{
    package My::Cool::Parent::Package;
    our $a = 1;
    package My::Cool::Package;
    our @ISA = 'My::Cool::Parent::Package';
}

say XS::Framework::bench_isa_eq();
say XS::Framework::bench_isa_stash();
say XS::Framework::bench_isa_str();
say XS::Framework::bench_isa_ne();

timethese(-1, {
    isa_eq    => \&XS::Framework::bench_isa_eq,
    isa_stash => \&XS::Framework::bench_isa_stash,
    isa_str   => \&XS::Framework::bench_isa_str,
    isa_ne    => \&XS::Framework::bench_isa_ne,
});
exit();

timethis(-1, sub { XS::Framework::Test::ttt($a) });
timethis(-1, sub { XS::Framework::Test::yyy($a) });

__END__

my @a = (1..10000);

use threads ('yield',
             'stack_size' => 64*4096,
             'exit' => 'threads_only',
             'stringify');
             
{
    package AAA;
    sub new { return bless {}, 'AAA' }
    #sub CLONE { say "CLONE NAH @_"; }
}

my $aa = new AAA;
my $aa2 = new AAA;

sub thr_do {
    #say "HELLO FROM THREAD";
}

#timethis(-1, sub {
#    my $thr = threads->create(\&thr_do);
#    $thr->join();
#});

timethis(-1, sub {
    fork() or exit();
});

say "END";
