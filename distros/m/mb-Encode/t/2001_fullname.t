######################################################################
#
# 2001_fullname.t
#
# Copyright (c) 2021 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

# This file is encoded in UTF-8.
die "This file is not encoded in UTF-8.\n" if 'あ' ne "\xe3\x81\x82";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb::Encode;
use vars qw(@test);

@test = (
# 1
    sub { my $want="\x98\xB1"; my $got=mb::Encode::to_cp932     ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="\x98\xB1"; my $got=mb::Encode::cp932        ("亞"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { my $want="亞"; my $got=mb::Encode::by_cp932     ("\x98\xB1"); $got eq $want, sprintf("want=%s, got=%s", unpack('H*',$want), unpack('H*',$got)) },
    sub { 1 },
    sub { 1 },
    sub { 1 },
    sub { 1 },
    sub { 1 },
    sub { 1 },
    sub { 1 },
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
