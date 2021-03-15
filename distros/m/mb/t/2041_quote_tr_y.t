# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = ();
for my $op (qw( tr y )) {

    for my $delim (qw( # )) {
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s%s1%s2%s;   $_ eq '2'}, $op, ($delim) x 3)) };
    }

    for my $delim (')', qw( ! " $ % & ' * + , - . / : ; = > ? @ \ ] ^ ` | ~ )) {
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s%s1%s2%s;   $_ eq '2'}, $op, ($delim) x 3)) };

        push @test, sub { mb::eval(sprintf(q{$_='1'; %s(1)%s2%s;   $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s{1}%s2%s;   $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s[1]%s2%s;   $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s<1>%s2%s;   $_ eq '2'}, $op, ($delim) x 2)) };

        push @test, sub { mb::eval(sprintf(q{$_='1'; %s(1) %s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s{1} %s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s[1] %s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s<1> %s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };

        push @test, sub { mb::eval(sprintf(q{$_='1'; %s %s1%s2%s;  $_ eq '2'}, $op, ($delim) x 3)) };

        push @test, sub { mb::eval(sprintf(q{$_='1'; %s (1)%s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s {1}%s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s [1]%s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s <1>%s2%s;  $_ eq '2'}, $op, ($delim) x 2)) };

        push @test, sub { mb::eval(sprintf(q{$_='1'; %s (1) %s2%s; $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s {1} %s2%s; $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s [1] %s2%s; $_ eq '2'}, $op, ($delim) x 2)) };
        push @test, sub { mb::eval(sprintf(q{$_='1'; %s <1> %s2%s; $_ eq '2'}, $op, ($delim) x 2)) };
    }

    for my $from ('(1)','{1}','[1]','<1>') {
        for my $to ('(2)','{2}','[2]','<2>') {
            push @test, sub { mb::eval(sprintf(q{$_='1'; %s%s%s;   $_ eq '2'}, $op, $from, $to)) };
            push @test, sub { mb::eval(sprintf(q{$_='1'; %s %s%s;  $_ eq '2'}, $op, $from, $to)) };
            push @test, sub { mb::eval(sprintf(q{$_='1'; %s%s %s;  $_ eq '2'}, $op, $from, $to)) };
            push @test, sub { mb::eval(sprintf(q{$_='1'; %s %s %s; $_ eq '2'}, $op, $from, $to)) };
        }
    }
}

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
