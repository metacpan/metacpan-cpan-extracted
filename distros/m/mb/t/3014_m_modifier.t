# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

@test = (
##############################################################################

# 1
    sub { mb::eval(<<'END1'); },
$_='‚`'; m/‚`/
END1
    sub { mb::eval(<<'END1'); },
$_='‚`'; m/‚`/g
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; scalar(m/‚`/g) == 1
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; (@_ = m/‚`/g) == 3
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; @_ = m/‚`/g; "@_" eq '‚` ‚` ‚`'
END1
    sub { mb::eval(<<'END1'); },
$_='‚`'; m/(‚`)/g
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; scalar(m/(‚`)/g) == 1
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; (@_ = m/(‚`)/g) == 3
END1
    sub { mb::eval(<<'END1'); },
$_='‚`‚`‚`'; @_ = m/(‚`)/g; "@_" eq '‚` ‚` ‚`'
END1
    sub {1},

# 11
    sub { mb::eval(<<'END1'); },
$_='ƒA'; m/ƒA/;
END1
    sub { mb::eval(<<'END1'); },
$_='ƒA'; not m/A/;
END1
    sub { mb::eval(<<'END1'); },
$_='ƒA'; not m/A/i;
END1
    sub { mb::eval(<<'END1'); },
$_='A'; not m/a/;
END1
    sub { mb::eval(<<'END1'); },
$_='A'; m/a/i;
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 21
    sub { mb::eval(<<'END1'); },
$_="123\n456"; not m/^456/;
END1
    sub { mb::eval(<<'END1'); },
$_="123\n456"; m/^456/m;
END1
    sub { mb::eval(<<'END1'); },
$_="123\n456"; not m/123$/;
END1
    sub { mb::eval(<<'END1'); },
$_="123\n456"; m/123$/m;
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 31
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; m/$a/;
END1
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; m/$a/o;
END1
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; my $r; for my $i (1..3) { $r .= m/$a/; } $r eq '111'
END1
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; my $r; for my $i (1..3) { $r .= m/$a/o; } $r eq '111'
END1
    sub { return 'SKIP' if $] =~ /^5\.006/; mb::eval(<<'END1'); },
$_='A'; $a='A'; my $r; for my $i (1..3) { $r .= m/$a/o; $a.='B' } $r eq '111'
END1
    sub { mb::eval(<<'END1'); },
$_='A'; $a='A'; my $r; for my $i (1..3) { $r .= m/$a/; $a.='B' } $r eq '1'
END1
    sub {1},
    sub {1},
    sub {1},
    sub {1},

# 41
    sub { mb::eval(<<'END1'); },
$_="\n"; not m/./;
END1
    sub { mb::eval(<<'END1'); },
$_="\n"; m/./s;
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
$_='‚`'; m/ ‚` /x
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

##############################################################################
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
