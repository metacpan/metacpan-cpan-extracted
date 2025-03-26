#use Devel::Peek;
#use Data::Dumper;
use Time::HiRes;
use Benchmark qw(cmpthese timethese :hireswallclock);
use blib;

BEGIN {
    unshift(@INC, '.');
    print("1..1\n");
    require Win32::ExeAsDll;
    print('ok 1 - require Win32::ExeAsDll'."\n");

    package Benchmark;
    sub new {
        my @t = (mytime, times, @_ == 2 ? $_[1] : 0);
        $t[2] += $t[0];
        #$t[4] += $t[0];
        bless \@t;
    }
    package main;
    print STDERR "# \n# patched times() inside Benchmark::new()\n";
}

{
    my $o = Win32::ExeAsDll->new();
    my $pp_system = sub{system('cmd.exe /C del 2>:NUL')};
    my $exe2dll = sub{$o->main('cmd.exe /C del 2>:NUL')};
    my $out;
    {
        open(my $ofh, '>', \$out) or die;
        local *STDOUT = $ofh;
        my $r = timethese(-1.75,{pp_system => $pp_system,ExeAsDll => $exe2dll});
        cmpthese($r);
        #cmpthese(-1.75,{pp_system => $pp_system,ExeAsDll => $exe2dll});
        close($ofh);
    }
    print (STDERR "# \n# ".join("\n# ", split("\n",$out))."\n");
}
