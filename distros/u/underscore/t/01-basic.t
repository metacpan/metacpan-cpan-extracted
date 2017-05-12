#!perl -T

use Test::More tests => 7;
no underscore;

my $dummy;

my %ok = (
    For => sub { for (<DATA>) { $dummy = ord } },
);

my %notok = (
    Assignment => sub { $_ = "Bad" },
    Reading    => sub { print },
    Matching   => sub { my $x = /badness/ },
    Chop       => sub { chop },
    Filetest   => sub { -x },
    While      => sub { while (<DATA>) { $dummy = ord } },
);

for my $t (sort keys %notok){
    eval { $notok{$t}->() };
    ok !!$@, "$t:$@";
}

for my $t (sort keys %ok){
    eval { $ok{$t}->() };
    ok !$@, $t;
}

# warn $dummy;
__DATA__
Pathologically
Eclectic
Rubbish
Lister
