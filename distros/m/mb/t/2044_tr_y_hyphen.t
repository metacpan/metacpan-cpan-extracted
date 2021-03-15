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

# 1
push @test, sub { eval(q{$_='+,-./'; tr!-,-./!1234!;  $_ eq '+2144'}) };
push @test, sub { eval(q{$_='+,-./'; tr!\-,-./!1234!; $_ eq '+2144'}) };
push @test, sub { eval(q{$_='+,-./'; tr!+--./!1234!;  $_ eq '12344'}) };
push @test, sub { eval(q{$_='+,-./'; tr!+\--./!1234!; $_ eq '1,234'}) };
push @test, sub { eval(q{$_='+,-./'; tr!+,--/!1234!;  $_ eq '123.4'}) };
push @test, sub { eval(q{$_='+,-./'; tr!+,-\-/!1234!; $_ eq '123.4'}) };
push @test, sub { eval(q{$_='+,-./'; tr!+,-.-!1234!;  $_ eq '1234/'}) };
push @test, sub { eval(q{$_='+,-./'; tr!+,-.\-!1234!; $_ eq '1234/'}) };
push @test, sub {1};
push @test, sub {1};

# 11
push @test, sub { mb::eval(q{$_='+,-./'; tr!-,-./!1234!;  $_ eq '+2144'}) };
push @test, sub { mb::eval(q{$_='+,-./'; tr!\-,-./!1234!; $_ eq '+2144'}) };
push @test, sub { mb::eval(q{$_='+,-./'; tr!+--./!1234!;  ($_ eq '12344', $_)}) };
push @test, sub { mb::eval(q{$_='+,-./'; tr!+\--./!1234!; $_ eq '1,234'}) };
push @test, sub { mb::eval(q{$_='+,-./'; tr!+,--/!1234!;  $_ eq '123.4'}) };
push @test, sub { mb::eval(q{$_='+,-./'; tr!+,-\-/!1234!; $_ eq '123.4'}) };
push @test, sub { mb::eval(q{$_='+,-./'; tr!+,-.-!1234!;  $_ eq '1234/'}) };
push @test, sub { mb::eval(q{$_='+,-./'; tr!+,-.\-!1234!; $_ eq '1234/'}) };
push @test, sub {1};
push @test, sub {1};

# 21
push @test, sub { eval(q{$_='ABCDEFG'; tr!B-E/!5-8!;  $_ eq 'A5678FG'}) };
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};

# 31
push @test, sub { mb::eval(q{$_='ABCDEFG'; tr!B-E/!5-8!;  ($_ eq 'A5678FG', $_)}) };
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};
push @test, sub {1};

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
