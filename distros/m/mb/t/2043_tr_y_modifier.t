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
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!;    ($_ eq '111222DE', "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!c;   ($_ eq 'AAABBC22', "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!d;   ($_ eq '11122DE' , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!s;   ($_ eq '12DE'    , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!cd;  ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!cs;  ($_ eq 'AAABBC2' , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!ds;  ($_ eq '12DE'    , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; tr!ABC!12!cds; ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub {1};
push @test, sub {1};

# 11
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','');    ($_ eq '111222DE', "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','c');   ($_ eq 'AAABBC22', "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','d');   ($_ eq '11122DE' , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','s');   ($_ eq '12DE'    , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','cd');  ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','cs');  ($_ eq 'AAABBC2' , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','ds');  ($_ eq '12DE'    , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; mb::tr($_,'ABC','12','cds'); ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub {1};
push @test, sub {1};

# 21
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!;    ($_ eq '111222DE', "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!c;   ($_ eq 'AAABBC22', "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!d;   ($_ eq '11122DE' , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!s;   ($_ eq '12DE'    , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!cd;  ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!cs;  ($_ eq 'AAABBC2' , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!ds;  ($_ eq '12DE'    , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; tr!ABC!12!cds; ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub {1};
push @test, sub {1};

# 31
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!;    ($_ eq '‚P‚P‚P‚Q‚Q‚Q‚c‚d', "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!c;   ($_ eq '‚`‚`‚`‚a‚a‚b‚Q‚Q', "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!d;   ($_ eq '‚P‚P‚P‚Q‚Q‚c‚d'  , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!s;   ($_ eq '‚P‚Q‚c‚d'        , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!cd;  ($_ eq '‚`‚`‚`‚a‚a‚b'    , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!cs;  ($_ eq '‚`‚`‚`‚a‚a‚b‚Q'  , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!ds;  ($_ eq '‚P‚Q‚c‚d'        , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; tr!‚`‚a‚b!‚P‚Q!cds; ($_ eq '‚`‚`‚`‚a‚a‚b'    , "($_)")}) };
push @test, sub {1};
push @test, sub {1};

# 41
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!;    ($_ eq '111222DE', "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!c;   ($_ eq 'AAABBC22', "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!d;   ($_ eq '11122DE' , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!s;   ($_ eq '12DE'    , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!cd;  ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!cs;  ($_ eq 'AAABBC2' , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!ds;  ($_ eq '12DE'    , "($_)")}) };
push @test, sub { eval(q{$_='AAABBCDE'; y!ABC!12!cds; ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub {1};
push @test, sub {1};

# 51
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!;    ($_ eq '111222DE', "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!c;   ($_ eq 'AAABBC22', "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!d;   ($_ eq '11122DE' , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!s;   ($_ eq '12DE'    , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!cd;  ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!cs;  ($_ eq 'AAABBC2' , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!ds;  ($_ eq '12DE'    , "($_)")}) };
push @test, sub { mb::eval(q{$_='AAABBCDE'; y!ABC!12!cds; ($_ eq 'AAABBC'  , "($_)")}) };
push @test, sub {1};
push @test, sub {1};

# 61
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!;    ($_ eq '‚P‚P‚P‚Q‚Q‚Q‚c‚d', "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!c;   ($_ eq '‚`‚`‚`‚a‚a‚b‚Q‚Q', "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!d;   ($_ eq '‚P‚P‚P‚Q‚Q‚c‚d'  , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!s;   ($_ eq '‚P‚Q‚c‚d'        , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!cd;  ($_ eq '‚`‚`‚`‚a‚a‚b'    , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!cs;  ($_ eq '‚`‚`‚`‚a‚a‚b‚Q'  , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!ds;  ($_ eq '‚P‚Q‚c‚d'        , "($_)")}) };
push @test, sub { mb::eval(q{$_='‚`‚`‚`‚a‚a‚b‚c‚d'; y!‚`‚a‚b!‚P‚Q!cds; ($_ eq '‚`‚`‚`‚a‚a‚b'    , "($_)")}) };
push @test, sub {1};
push @test, sub {1};

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
