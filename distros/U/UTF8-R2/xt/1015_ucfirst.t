######################################################################
#
# 1015_ucfirst.t
#
# Copyright (c) 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for jperl only. You are using $^X.\n" if $^X !~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use UTF8::R2;
use vars qw(@test);

@test = (
# 1
    sub { $_='aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz'; my $r=          ucfirst($_); $r eq 'Aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz' },
    sub { $_='aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz'; my $r=          ucfirst;     $r eq 'Aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz' },
    sub { $_='aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz'; my $r=UTF8::R2::ucfirst($_); $r eq 'Aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz' },
    sub { $_='aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz'; my $r=UTF8::R2::ucfirst;     $r eq 'Aabbccddeeffgghhiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz' },
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
