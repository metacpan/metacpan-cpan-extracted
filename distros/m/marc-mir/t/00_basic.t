#! /usr/bin/perl
use YAML;
use MARC::MIR;
use Test::More;

my $mir =
[ ''
, [ ['001' => 'PPN']
  , ['010', [ [a => 'ISBN'] ] ]
  , ['991', [ [a => 'ISBN'] ] ]
  , ['992', [ [a => 'ISBN'] ] ]
  , ['993', [ [a => 'ISBN'] ] ]
  , ['993', [ [a => 'ISBN'] ] ]
  , ['999', [ [a => 'ISBN'] ] ]
  ]
];

my ( $got, $expected );

$got = grep_fields {  (tag) ~~ /^9/ } $mir;
ok( $got , "have 9xx fields" );

with_fields { @$_ = grep { (tag) !~ /^9/ }  @$_ } $mir;
$got = grep_fields {  (tag) ~~ /^9/ } $mir;
ok( not($got) , "with_fields with parameter" )
    or diag "$got fields remains";

$_ = $mir;
with_fields { push @$_, ['999', [ [a => 'ISBN'] ] ] };
$got = grep_fields {  (tag) ~~ /^9/ } $mir;
ok( $got , "with_fields without parameter" );
$got = grep_fields {  (tag) ~~ /^9/ };
ok( $got , "grep_fields without parameter" ); 

done_testing;
