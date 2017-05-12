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
    eval "use $T qw(FindFile ReadDir);";
    die "Can't load $T: $@." if $@;

    my $d_glob = \%main::;
    no strict 'refs';

    my $s_glob = \%{ "$T\::" };
    $d_glob->{$_} = $s_glob->{$_} for 'wchar', 'wfchar', 'uchar';

};

my @r1 = FindFile( '*' );
my @r2 = ReadDir( '.');
ok( @r1=@r2, "ReadDir and FindFile a same" );
my @r3= FindFile( "t/01-use.t" );
ok( @r3 == 1, "t/01-use.t present" );
my $use = $r3[0] or return;
is( $use->name, '01-use.t', "name ok 1");
is( $use->FileName, '01-use.t', "name ok 2");
is( $use->fileName, '01-use.t', "name ok 2");
is( $use->cFileName, '01-use.t', "name ok 3");
is( $use->relName(), '01-use.t', "relname()");
is( $use->relName(""), '01-use.t', "relname('')");
is( $use->relName("abc"), 'abc/01-use.t', "relname 1 (abc)");
is( $use->relName("abc\\"), 'abc/01-use.t', "relname 2 (abc)");
is( $use->relName("abc\/"), 'abc/01-use.t', "relname 3 (abc)");
is( $use->relName("/"),  '/01-use.t', "relname 4 (/)");
is( $use->relName("\\"), "\\01-use.t", "relname 5 (\\)");
is( $use->relName("C:\\"), 'C:\\01-use.t', "relname 6 (C:\\)");


is( $use->relName("", "\\"), '01-use.t', "relname('')");
is( $use->relName("abc", "\\")  , 'abc\\01-use.t',   "relname[delim] 1 (abc)");
is( $use->relName("abc\\", "\\"), 'abc\\01-use.t', "relname[delim] 2 (abc)");
is( $use->relName("abc\/", "\\"), 'abc\\01-use.t', "relname[delim] 3 (abc)");

my $mtime = (stat $use->relName( "t" ))[9];
#print Dumper( $mtime, int($use->mtime));
is( $mtime , int($use->mtime) );
is( $mtime , int($use->ftLastWriteTime) );
ok( defined eval { $use->mtime > 0 } );
ok( defined eval { $use->mtime < 0 } );
ok( defined eval { $use->mtime != 0 } );

