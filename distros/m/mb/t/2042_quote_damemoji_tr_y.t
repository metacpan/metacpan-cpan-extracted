# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if 'あ' ne "\x82\xA0";
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
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 3)) };
$_='ソ'; %s%sソ%s申%s;   $_ eq '申'
END
    }

#   for my $delim (')', qw( ! " $ % & ' * + , - . / : ; = > ? @ \ ] ^ ` | ~ )) {
    for my $delim (')', qw( ! " $ % & ' * + , - . / : ; = > ? @   ] ^ ` | ~ )) {
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 3)) };
$_='ソ'; %s%sソ%s申%s;   $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s(ソ)%s申%s;   $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s{ソ}%s申%s;   $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s[ソ]%s申%s;   $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s<ソ>%s申%s;   $_ eq '申'
END

        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s(ソ) %s申%s;  $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s{ソ} %s申%s;  $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s[ソ] %s申%s;  $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s<ソ> %s申%s;  $_ eq '申'
END

        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 3)) };
$_='ソ'; %s %sソ%s申%s;  $_ eq '申'
END

        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s (ソ)%s申%s;  $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s {ソ}%s申%s;  $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s [ソ]%s申%s;  $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s <ソ>%s申%s;  $_ eq '申'
END

        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s (ソ) %s申%s; $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s {ソ} %s申%s; $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s [ソ] %s申%s; $_ eq '申'
END
        push @test, sub { mb::eval(sprintf(<<'END', $op, ($delim) x 2)) };
$_='ソ'; %s <ソ> %s申%s; $_ eq '申'
END
    }

    for my $from ('(ソ)','{ソ}','[ソ]','<ソ>') {
        for my $to ('(申)','{申}','[申]','<申>') {
            push @test, sub { mb::eval(sprintf(<<'END', $op, $from, $to)) };
$_='ソ'; %s%s%s;   $_ eq '申'
END
            push @test, sub { mb::eval(sprintf(<<'END', $op, $from, $to)) };
$_='ソ'; %s %s%s;  $_ eq '申'
END
            push @test, sub { mb::eval(sprintf(<<'END', $op, $from, $to)) };
$_='ソ'; %s%s %s;  $_ eq '申'
END
            push @test, sub { mb::eval(sprintf(<<'END', $op, $from, $to)) };
$_='ソ'; %s %s %s; $_ eq '申'
END
        }
    }
}

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
