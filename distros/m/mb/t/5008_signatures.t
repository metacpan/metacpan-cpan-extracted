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
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 1
sub max {}
END1
sub max {}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 2
sub max ( $m, $n ) {}
END1
sub max ( $m, $n ) {}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 3
sub max ( $max_so_far, @rest ) {}
END1
sub max ( $max_so_far, @rest ) {}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 4
sub max ( $max_so_far, @ ) {}
END1
sub max ( $max_so_far, @ ) {}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 5
sub max ( $max_so_far, @) {}
END1
sub max ( $max_so_far, @) {}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 6
sub list_from_fred_to_barney ( $fred = 0, $barney = 7 ) {}
END1
sub list_from_fred_to_barney ( $fred = 0, $barney = 7 ) {}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 7
sub one_or_two_args ( $first, $= ) {}
END1
sub one_or_two_args ( $first, $= ) {}
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 8
sub PI () { 3.1415926 }
END1
sub PI () { 3.1415926 }
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 9
END1
END2
    sub { $_=<<'END1'; mb::parse() eq <<'END2'; }, # test no 10
END1
END2
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
