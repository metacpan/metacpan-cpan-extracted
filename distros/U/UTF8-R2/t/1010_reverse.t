######################################################################
#
# 1010_reverse.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

@test = (
# 1
    sub { @_=(qw( AB CD EF ));       my @r=          reverse(@_); "@r" eq "EF CD AB"       },
    sub { @_=(qw( AB CD EF ));       my @r=UTF8::R2::reverse(@_); "@r" eq "EF CD AB"       },
    sub { @_=(qw( AB CD EF ));       my $r=          reverse(@_); "$r" eq "FEDCBA"         },
    sub { @_=(qw( AB CD EF ));       my $r=UTF8::R2::reverse(@_); "$r" eq "FEDCBA"         },
    sub { @_=(qw( あい うえ おか )); my @r=UTF8::R2::reverse(@_); "@r" eq "おか うえ あい" },
    sub { @_=(qw( あい うえ おか )); my $r=UTF8::R2::reverse(@_); "$r" eq "かおえういあ"   },
    sub {1},
    sub {1},
    sub {1},
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
