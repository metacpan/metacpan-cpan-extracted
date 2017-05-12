package ake;
use Mo;

sub assert_makefile {
    if (not -f 'Makefile.PL') {
        system("$^X -Makefile=PL");
    }
    elsif (not -f 'Makefile') {
        system("$^X Makefile.PL");
    }
}

BEGIN {
    {
        no warnings;
        return unless $^I eq 'nstall';
    }
    assert_makefile();
    exec("make install");
}

sub main::st {
    assert_makefile();
    exec("make test");
}

1;
