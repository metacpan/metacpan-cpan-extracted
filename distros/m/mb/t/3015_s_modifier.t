# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

use vars qw($MSWin32_MBCS);
$MSWin32_MBCS = ($^O =~ /MSWin32/) and (qx{chcp} =~ m/[^0123456789](932|936|949|950|951|20932|54936)\Z/);

@test = (
##############################################################################

# 1
    sub { mb::eval(<<'END1'); },
$_='‚`'; s/‚`//
END1
    sub { mb::eval(<<'END1'); },
$_='‚`'; s/‚`//g
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; scalar(s/‚`//g) == 3
END1
    sub { mb::eval(<<'END1'); },
$_='‚`'; s/(‚`)//g
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; scalar(s/(‚`)//g) == 3
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 11
    sub { mb::eval(<<'END1'); },
$_='ƒA'; s/ƒA//;
END1
    sub { mb::eval(<<'END1'); },
$_='ƒA'; not s/A//;
END1
    sub { mb::eval(<<'END1'); },
$_='ƒA'; not s/A//i;
END1
    sub { mb::eval(<<'END1'); },
$_='A'; not s/a//;
END1
    sub { mb::eval(<<'END1'); },
$_='A'; s/a//i;
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 21
    sub { mb::eval(<<'END1'); },
$_="123\n456"; not s/^456//;
END1
    sub { mb::eval(<<'END1'); },
$_="123\n456"; s/^456//m;
END1
    sub { mb::eval(<<'END1'); },
$_="123\n456"; not s/123$//;
END1
    sub { mb::eval(<<'END1'); },
$_="123\n456"; s/123$//m;
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 31
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; s/$a//;
END1
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; s/$a//o;
END1
    sub { mb::eval(<<'END1'); },
$_='AAA'; $a='A'; my $r; for my $i (1..3) { $r .= s/$a//; } $r eq '111'
END1
    sub { mb::eval(<<'END1'); },
$_='AAA'; $a='A'; my $r; for my $i (1..3) { $r .= s/$a//o; } $r eq '111'
END1
    sub { return 'SKIP' if $] =~ /^5\.006/; mb::eval(<<'END1'); },
$_='AAA'; $a='A'; my $r; for my $i (1..3) { $r .= s/$a//o; $a.='B' } $r eq '111'
END1
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; my $r; for my $i (1..3) { $r .= s/$a//; $a.='B' } $r eq '1'
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 41
    sub { mb::eval(<<'END1'); },
$_="\n"; not s/.//;
END1
    sub { mb::eval(<<'END1'); },
$_="\n"; s/.//s;
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 51
    sub { mb::eval(<<'END1'); },
$_='‚`'; s/ ‚` //x
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 61
    sub { CORE::eval(<<'END1'); },
$_='ABC'; s'(B)'sprintf("(%s)(%s)(%s)",$`,$&,$1)'e; $_ eq 'A(A)(B)(B)C'
END1
    sub { mb::eval(<<'END1'); },
$_='ABC'; s/B/($`)($&)($')/; $_ eq 'A(A)(B)(C)C'
END1
    sub { mb::eval(<<'END1'); },
$_='ABC'; s/(A)(B)(C)/($3)($2)($1)/; $_ eq '(C)(B)(A)'
END1
    sub { mb::eval(<<'END1'); },
$_='A'; s/(A)/sprintf('%-10s', $1)/e; $_ eq "A         ";
END1
    sub { mb::eval(<<'END1'); },
$_='‚`'; s/(‚`)/sprintf('%-10s', $1)/e; $_ eq "‚`        ";
END1
    sub { mb::eval(<<'END1'); },
$_='ABC'; s'B'($`)($&)'; $_ eq 'A($`)($&)C'
END1
    sub { mb::eval(<<'END1'); },
$_='ABC'; s'(A)(B)(C)'($3)($2)($1)'; $_ eq '($3)($2)($1)'
END1
    sub { mb::eval(<<'END1'); },
$_='A'; s'(A)'sprintf("%s",$1)'e; $_ eq 'A';
END1
    sub { mb::eval(<<'END1'); },
$_='A'; s'(A)'sprintf("%s","$1")'e; $_ eq 'A';
END1
    sub { mb::eval(<<'END1'); },
$_='‚`'; s'(‚`)'sprintf("%04d",123)'e; $_ eq '0123';
END1

##############################################################################
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
