#!/usr/bin/perl
use strict; use warnings  FATAL => 'all'; use feature qw(state say); use utf8;
#use open IO => ':locale';
use open ':std', ':encoding(UTF-8)';
select STDERR; $|=1; select STDOUT; $|=1;
use Carp;
use Data::Dumper::Interp qw/dvis vis/;

# Tester for Tie::Indirect::*

use Test::More;

require Tie::Indirect;

sub oops(@) { package other; Carp::croak "BUG(@_)" }

my $ds1 = { foo => 123, table => {k1=>1, k2=>22}, list => [0..5] };
my $ds2 = { foo => 456, table => {k1=>91, k9=>99}, list => [6..10] };

my $masterref;

our ($foo, %table, @list);
tie $foo,   'Tie::Indirect::Scalar', sub{ \$masterref->{$_[1]} }, 'foo';
tie @list,  'Tie::Indirect::Array',  sub{ $masterref->{$_[1]} }, 'list';
tie %table, 'Tie::Indirect::Hash',   sub{ $masterref->{table} };

$masterref = $ds1;
note dvis 'ds1: $foo %table @list\n';
ok( $foo == 123 );
ok( $table{k2} == 22 );
ok( $list[2] == 2 );
ok( @list == 6 );
ok( %table );
$list[3] = 333;
ok( @list == 6 );

$foo = 66;
$table{k2} = 222;
ok( %table );
ok( $table{k2} == 222 );
ok( $foo == 66 );

my %tmp = %table;
%table = ();
ok( ! %table );
%table = %tmp;
ok( %table );

$masterref = $ds2;
note dvis 'ds2: $foo %table @list\n';
ok( $foo == 456 );
ok( $list[2] == 8 );
ok( @list == 5 );
splice @list,3,1,"A","B";
ok( @list == 6 );
ok( !defined $table{k2} );
ok( $table{k9} == 99 );

$foo = 77;
ok( $list[2] == 8 );
ok( $list[3] eq "A" );
ok( $list[5] == 10 );
ok( $foo == 77 );
note dvis 'final ds2: $foo %table @list\n';

$masterref = $ds1;
ok( $foo == 66 );
ok( $table{k2} == 222 );
ok( $list[2] == 2 );
ok( $list[3] == 333 );

note dvis 'final ds1: $foo %table @list\n';

# Check that nothing visible was blessed
ok( "$ds1 $ds1->{foo} $ds1->{table} $ds1->{list}" !~ /bless/ );
ok( "$ds2 $ds2->{foo} $ds2->{table} $ds2->{list}" !~ /bless/ );
ok( ref($ds1) eq 'HASH' );
ok( ref($ds1->{table}) eq 'HASH' );
ok( ref($ds1->{list}) eq 'ARRAY' );
ok( ref($ds2) eq 'HASH' );
ok( ref($ds2->{table}) eq 'HASH' );
ok( ref($ds2->{list}) eq 'ARRAY' );

note "Passed.\n";

done_testing();

