# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2 qw(*mb);
use vars qw(@test);

@test = (
# 1
    sub { $_='ABC';      my $r=    length($_); $r == 3 },
    sub { $_='ABC';      my $r=    length;     $r == 3 },
    sub { $_='';         my $r=    length($_); $r == 0 },
    sub { $_='';         my $r=    length;     $r == 0 },
    sub { $_='ABC';      my $r=mb::length($_); $r == 3 },
    sub { $_='ABC';      my $r=mb::length;     $r == 3 },
    sub { $_='あいうえ'; my $r=mb::length($_); $r == 4 },
    sub { $_='あいうえ'; my $r=mb::length;     $r == 4 },
    sub { $_='';         my $r=mb::length($_); $r == 0 },
    sub { $_='';         my $r=mb::length;     $r == 0 },
# 11
    sub { $_='1あAい!';  my $r=mb::length($_); $r == 5 },
    sub { $_='1あAい!';  my $r=mb::length;     $r == 5 },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
