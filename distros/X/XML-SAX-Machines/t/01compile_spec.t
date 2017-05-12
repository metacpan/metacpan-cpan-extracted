use strict;

## This tests the parsing of sax machine specs, but does not test the resulting
## machines.  It is mostly a check of the syntax handling.

use Test;
use Data::Dumper;
use XML::SAX::Machines qw( Machine );

my $precon1 = bless { A => 1 }, "Preconstructed1" ;
my $precon2 = bless { A => 2 }, "Preconstructed2" ;
my $precon3 = bless { A => 3 }, "Preconstructed3" ;

sub Preconstructed1::set_handler {}
sub Preconstructed2::set_handler {}
sub Preconstructed3::set_handler {}

my @tests = (
## Some simple non-errors
[ "XML::SAX::Machine",           1 ],  ## Already loaded.
[ "XML::SAX::Manifold",          1 ],  ## Need to load this.
[ $precon1,                      1 ],  ## Preconstructed.
[ \*STDOUT,                      1 ],  ## A writer
[ [ A  => $precon1],             1 ],  ## ARRAY
[ [ undef() => $precon1],        1 ],  ## explicitly unnamed, via ARRAY
[ [ $precon1 ],                  1 ],  ## implicitly unnamed, via ARRAY

## Explicit linking
[
    [ A  => "XML::SAX::Machine" => "B" ],
    [ B  => "XML::SAX::Machine" => "C" ],
    [ C  => "XML::SAX::Machine" ],
    3,
],

## Explicit linking by name
[
    [ undef() => "XML::SAX::Machine" => 1 ],
    [ undef() => "XML::SAX::Machine" => 2 ],
    [ undef() => "XML::SAX::Machine" ],
    3,
],

## Explicit linking by reference to other parts in the machine
[
    [ undef() => $precon1 => $precon2 ],
    [ undef() => $precon2 => $precon3 ],
    [ undef() => $precon3 ],
    3,
],

## Explicit linking by reference to parts not in the machine
[
    [ undef() => $precon1 => $precon2 ],
    1,
],

## Errors.
[ "My::Filter",                              qr{ My\WFilter.pm} ],
[ qr/^/,                                     qr{Regexp}         ],
[ {}, {},                                    qr{HASH}           ],
[ sub {},                                    qr{CODE}           ],
[ [ "42illegal" => $precon1 ],        qr{'42illegal'}    ],
[ [ A  => $precon1, "UndefName" ], qr{'UndefName'}    ],
[ [ A  => $precon1, 99999    ],    qr{'99999'}        ],
[
    [ DupName  => $precon1 ],
    [ DupName  => $precon2 ],
    qr{'DupName'}
],

[
    [ DupName  => $precon1 => "UndefName1" ],
    [ DupName  => $precon2 => "UndefName2" ],
    qr{(('DupName'|'UndefName1'|'UndefName2').*){3}}s
],

[
    [ Cyclical => $precon1 => "Cyclical" ],
    qr{Cyclical.*Cyclical},
],

[
    [ Cyclical1 => $precon1 => "Cyclical2" ],
    [ Cyclical2 => $precon1 => "Cyclical1" ],
    qr{Cyclical1.*Cyclical2.*Cyclical1},
],

[
    [ Cyclical1 => $precon1 => "Cyclical2" ],
    [ Cyclical2 => $precon1 => "Cyclical1", "Cyclical1" ],
    qr{Cyclical1.*Cyclical2.*Cyclical1},
],

[
    [ Cyclical1  => $precon1 => qw( Cyclical2a Cyclical2b ) ],
    [ Cyclical2a => $precon2 => "Cyclical1" ],
    [ Cyclical2b => $precon3 => "Cyclical1" ],
    qr{Cyclical1.*Cyclical2a.*Cyclical1(?s:.*)Cyclical1.*Cyclical2b.*Cyclical1},
],

## Now mess with prebuild handlers in various ways.
);

plan tests => scalar @tests;

sub c { eval { scalar XML::SAX::Machine->new( @_ )->parts } || $@ }

for (@tests) {
    my $expected = pop @$_;
    
    my $got = c @$_;

    my $desc = [ @$_ ];
    $desc = [ map ref $_ ? "$_" : $_, @$desc ] if $] < 5.006001;
    $desc = Dumper $desc;

    if ( ref $expected ) {
        ## Older Test.pms do not know about qr// for expected values.
        $got =~ $expected
            ? ok 1
            : ok $got, $expected, $desc;
    }
    else {
        ok $got, $expected, $desc;
    }
}

