######################################################################
#
# 1001_basic_json.t
#
# Copyright (c) 2021, 2022 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb::JSON;
use vars qw(@test);

@test = (
# 1
    sub {               my $got=mb::JSON::parse('null');  not defined($got) },
    sub { my $want=!!1; my $got=mb::JSON::parse('true');  $got eq $want     },
    sub { my $want=!!0; my $got=mb::JSON::parse('false'); $got eq $want     },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { my $want= 0;      my $got=mb::JSON::parse('0');       $got eq $want },
    sub { my $want= 1;      my $got=mb::JSON::parse('1');       $got eq $want },
    sub { my $want= 123;    my $got=mb::JSON::parse('123');     $got eq $want },
    sub { my $want=-123;    my $got=mb::JSON::parse('-123');    $got eq $want },
    sub { my $want= 1.23;   my $got=mb::JSON::parse( '1.23');   $got eq $want },
    sub { my $want=-1.23;   my $got=mb::JSON::parse('-1.23');   $got eq $want },
    sub { my $want= 1.23e4; my $got=mb::JSON::parse( '1.23e4'); $got eq $want },
    sub { my $want=-1.23e4; my $got=mb::JSON::parse('-1.23e4'); $got eq $want },
    sub { my $want= 1.23E4; my $got=mb::JSON::parse( '1.23E4'); $got eq $want },
    sub { my $want=-1.23E4; my $got=mb::JSON::parse('-1.23E4'); $got eq $want },
# 21
    sub { my $want="あ";    my $got=mb::JSON::parse('"あ"');    $got eq $want },
    sub { my $want="\"";    my $got=mb::JSON::parse('"\""');    $got eq $want },
    sub { my $want="\\";    my $got=mb::JSON::parse(<<'END');   $got eq $want },
"\\"
END
    sub { my $want="\/";    my $got=mb::JSON::parse('"\/"');    $got eq $want },
    sub { my $want="\b";    my $got=mb::JSON::parse('"\b"');    $got eq $want },
    sub { my $want="\f";    my $got=mb::JSON::parse('"\f"');    $got eq $want },
    sub { my $want="\n";    my $got=mb::JSON::parse('"\n"');    $got eq $want },
    sub { my $want="\r";    my $got=mb::JSON::parse('"\r"');    $got eq $want },
    sub { my $want="\t";    my $got=mb::JSON::parse('"\t"');    $got eq $want },
    sub {1},
# 31
    sub { my $want="ア";    my $got=mb::JSON::parse('"\u30A2"');       $got eq $want },
    sub { my $want="ア";    my $got=mb::JSON::parse('"\u30a2"');       $got eq $want },
    sub { my $want="𩸽";    my $got=mb::JSON::parse('"\uD867\uDE3D"'); $got eq $want },
    sub { my $want="𩸽";    my $got=mb::JSON::parse('"\ud867\ude3d"'); $got eq $want },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { my $want='$';     my $got=mb::JSON::parse('"$"');     $got eq $want },
    sub { my $want='@';     my $got=mb::JSON::parse('"@"');     $got eq $want },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 51
    sub {                   my $got=mb::JSON::parse('[]');         ref($got) eq 'ARRAY' },
    sub {                   my $got=mb::JSON::parse('[1,2,3]');    ref($got) eq 'ARRAY' },
    sub {                   my $got=mb::JSON::parse('[1,2,3]');    $got->[0] == 1       },
    sub {                   my $got=mb::JSON::parse('[1,2,3]');    $got->[1] == 2       },
    sub {                   my $got=mb::JSON::parse('[1,2,3]');    $got->[2] == 3       },
    sub {                   my $got=mb::JSON::parse('[1,2,"あ"]'); $got->[2] eq "あ"    },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
# 61
    sub {                   my $got=mb::JSON::parse('{}');                         ref($got)    eq 'HASH' },
    sub {                   my $got=mb::JSON::parse('{"A":4,"B":5,"C":6}');        ref($got)    eq 'HASH' },
    sub {                   my $got=mb::JSON::parse('{"A":4,"B":5,"C":6}');        $got->{'A'}  == 4      },
    sub {                   my $got=mb::JSON::parse('{"A":4,"B":5,"C":6}');        $got->{'B'}  == 5      },
    sub {                   my $got=mb::JSON::parse('{"A":4,"B":5,"C":6}');        $got->{'C'}  == 6      },
    sub {                   my $got=mb::JSON::parse('{"A":4,"B":5,"C":"あ"}');     $got->{'C'}  eq 'あ'   },
    sub {                   my $got=mb::JSON::parse('{"い":4,"B":5,"C":"あ"}');    $got->{'い'} == 4      },
    sub {                   my $got=mb::JSON::parse('{"い":"う","B":5,"C":"あ"}'); $got->{'い'} eq "う"   },
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
