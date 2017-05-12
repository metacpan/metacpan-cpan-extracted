use strict;
use warnings;
use Test::More;
use List::Util qw( sum );
use Scalar::Util qw( looks_like_number );

use lib 't/lib';
use FakeGit;
use Test::Requires::Git -nocheck;

# pick a random git version to work with
my @version = (
    [ 1, 2 ]->[ rand 2 ],
    [ 0 .. 12 ]->[ rand 13 ],
    [ 0 .. 12 ]->[ rand 13 ],
    [ 0 .. 12 ]->[ rand 13 ],
);
my $version = join '.', @version;
diag "fake version: $version";
fake_git($version);

# generate other versions based on the current one
my ( @lesser, @greater );
for ( 0 .. $#version ) {
    local $" = '.';
    my @v = @version;
    next if !looks_like_number( $v[$_] );
    $v[$_]++;
    push @greater, "@v";
    next if 0 > ( $v[$_] -= 2 );
    push @lesser, "@v";
}

# an rc is always lesser
push @lesser, join '.', @version[ 0 .. 2 ], 'rc1';

# build up test data
my ( @pass, @skip );
for my $t ( # [ op => [ pass ], [ skip ] ]
    [ version_eq => [$version], [ @lesser, @greater ] ],
    #[ version_ne => [ @lesser, @greater ], [$version] ],
    [ version_lt => [@greater], [ @lesser,  $version ] ],
    [ version_gt => [@lesser],  [ $version, @greater ] ],
    #[ version_le => [ $version, @greater ], [@lesser] ],
    #[ version_ge => [ @lesser,  $version ], [@greater] ],
  )
{
    my ( $op, $pass, $skip ) = @$t;
    push @pass, map [ $version, $op, $_ ], @$pass;
    push @skip, map [ $version, $op, $_ ], @$skip;
}

# more complex cases
push @pass,
  [ '1.7.2.rc0.13.gc9eaaa', 'version_eq', '1.7.2.rc0.13.gc9eaaa' ],
  [ '1.7.2.rc0.13.gc9eaaa', 'version_ge', '1.7.2.rc0.13.gc9eaaa' ],
  [ '1.7.2.rc0.13.gc9eaaa', 'version_le', '1.7.2.rc0.13.gc9eaaa' ],
  [ '1.7.1',                'version_gt', '1.7.1.rc0' ],
  [ '1.7.1.rc1',            'version_gt', '1.7.1.rc0' ],
  [ '1.3.2',                'version_gt', '0.99' ],
  [ '1.7.2.rc0.13.gc9eaaa', 'version_gt', '1.7.0.4' ],
  [ '1.7.1.rc2',            'version_gt', '1.7.1.rc1' ],
  [ '1.7.2.rc0.1.g078e',    'version_gt', '1.7.2.rc0' ],
  [ '1.7.2.rc0.10.g1ba5c',  'version_gt', '1.7.2.rc0.1.g078e' ],
  [ '1.7.1.1',              'version_gt', '1.7.1.1.gc8c07' ],
  [ '1.7.1.1',              'version_gt', '1.7.1.1.g5f35a' ],
  [ '1.0.0b',               'version_gt', '1.0.0a' ],
  [ '1.0.3',                'version_gt', '1.0.0a' ],
  [ '1.7.0.4',              'version_ne', '1.7.2.rc0.13.gc9eaaa' ],
  [ '1.7.1.rc1',            'version_ne', '1.7.1.rc2' ],
  [ '1.0.0a',               'version_ne', '1.0.0' ],
  [ '1.4.0.rc1',            'version_le', '1.4.1' ],
  [ '1.0.0a',               'version_gt', '1.0.0' ],
  [ '1.0.0a',               'version_lt', '1.0.3' ],
  [ '1.0.0a',               'version_eq', '1.0.1' ],
  [ '1.0.0b',               'version_eq', '1.0.2' ],
  [ '1.7.1.236.g81fa0',     'version_gt', '1.7.1' ],
  [ '1.7.1.236.g81fa0',     'version_lt', '1.7.1.1' ],
  [ '1.7.1.211.g54fcb21',   'version_gt', '1.7.1.209.gd60ad81' ],
  [ '1.7.1.211.g54fcb21',   'version_ge', '1.7.1.209.gd60ad81' ],
  [ '1.7.1.209.gd60ad81',   'version_lt', '1.7.1.1.1.g66bd8ab' ],
  [ '1.7.0.2.msysgit.0',    'version_gt', '1.6.6' ],
  [ '1.6.5.4.52.g952dfc6',  'version_gt', '1.6.5' ],
  [ '2.6.4 (Apple Git-63)', 'version_gt', '1.6.5' ],
  ;

# operator reversal: $a op $b <=> $b rop $a
my %reverse = (
    version_eq => 'version_eq',
    #version_ne => 'version_ne',
    #version_ge => 'version_le',
    version_gt => 'version_lt',
    #version_le => 'version_ge',
    version_lt => 'version_gt',
);
push @pass, map [ $_->[2], $reverse{ $_->[1] }, $_->[0] ],
  grep exists $reverse{ $_->[1] }, @pass;
push @skip, map [ $_->[2], $reverse{ $_->[1] }, $_->[0] ],
  grep exists $reverse{ $_->[1] }, @skip;

# operator negation
my %negate = (
    version_ne => 'version_eq',
    version_eq => 'version_ne',
    version_ge => 'version_lt',
    version_gt => 'version_le',
    version_le => 'version_gt',
    version_lt => 'version_ge',
);
push @pass, map [ $_->[0], $negate{ $_->[1] }, $_->[2] ], @skip;
push @skip, map [ $_->[0], $negate{ $_->[1] }, $_->[2] ], @pass;

# sort test cases by v1
@pass = sort { $a->[0] cmp $b->[0] } @pass;
@skip = sort { $a->[0] cmp $b->[0] } @skip;

plan tests => 1 + 2 * @pass + @skip;

pass('initial pass');

# run all tests in a SKIP block

# PASS
my $prev = '';
for my $t (@pass) {
    my ( $v1, $op, $v2 ) = @$t;
    fake_git($v1) if $v1 ne $prev;

    my $passed = 0;
  SKIP: {
        test_requires_git $op => $v2, skip => 1;
        pass("$v1 $op $v2");
        $passed = 1;
    }
    ok( $passed, "$v1 $op $v2" );
    $prev = $v1;
}

# SKIP
$prev = '';
for my $t (@skip) {
    my ( $v1, $op, $v2 ) = @$t;
    fake_git($v1) if $v1 ne $prev;

  SKIP: {
        test_requires_git $op => $v2, skip => 1;
        fail("$v1 $op $v2");
    }
    $prev = $v1;
}
