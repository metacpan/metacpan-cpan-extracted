# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Win32-FindFile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan' => () ;
use lib 'lib';
use Data::Dumper;
use constant T=> 'Win32::FindFile';
use strict;
use warnings;

BEGIN{
    my $T = T;
    eval "use ExtUtils::testlib;" unless grep { m/::testlib/ } keys %INC;
    print "not ok $@" if $@;
    eval "use $T qw(FindFile);";
    die "Can't load $T: $@." if $@;

    my $d_glob = \%main::;
    no strict 'refs';

    my $s_glob = \%{ "$T\::" };
    $d_glob->{$_} = $s_glob->{$_} for 'wchar', 'wfchar', 'uchar';

};

my @r = FindFile( '*' );

for (@r){
	ok( ($_=~/^\.{1,2}\z/ xor $_->is_entry), "'$_'" );
}

