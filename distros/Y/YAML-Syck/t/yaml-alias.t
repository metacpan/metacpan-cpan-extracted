#!/usr/bin/perl
use Test::More tests => 14;
use YAML::Syck;

my ( $undumped, $roundtripped );

$undumped = [ {} ];
$undumped->[1] = $undumped->[0];
$roundtripped = Load( Dump($undumped) );
is( Dump($roundtripped), Dump($undumped), "array with anchor" );

$undumped->[1]     = 'xyz';
$roundtripped->[1] = 'xyz';
is( Dump($roundtripped), Dump($undumped), "touched array with anchor" );

$undumped = { abc => {} };
$undumped->{'def'} = $undumped->{'abc'};
$roundtripped = Load( Dump($undumped) );
is( Dump($roundtripped), Dump($undumped), "hash with anchor" );

$undumped->{'def'}     = 'xyz';
$roundtripped->{'def'} = 'xyz';
is( Dump($roundtripped), Dump($undumped), "touched hash with anchor" );

$undumped = [ {} ];
push @$undumped, $undumped->[0] for ( 1 .. 10 );
$roundtripped = Load( Dump($undumped) );
is( Dump($roundtripped), Dump($undumped), "huge array with anchor" );

$undumped->[0]     = 'xyz';
$roundtripped->[0] = 'xyz';
is( Dump($roundtripped), Dump($undumped), "touched huge array with anchor" );

$undumped = { abc => {}, def => {} };
$undumped->{abc}->{sibling} = $undumped->{def};
$undumped->{def}->{sibling} = $undumped->{abc};
$roundtripped               = Load( Dump($undumped) );
is_deeply( $roundtripped, $undumped, "circular" );

$undumped->{def}->{sibling}     = {};
$roundtripped->{def}->{sibling} = {};
is( Dump($roundtripped), Dump($undumped), "touched circular" );

$undumped = [ {}, {} ];
push @$undumped, $undumped->[0], $undumped->[1] for ( 1 .. 10 );
$roundtripped = Load( Dump($undumped) );
is( Dump($roundtripped), Dump($undumped), "many anchors" );

$undumped->[0]     = 'abc';
$undumped->[3]     = 'def';
$roundtripped->[0] = 'abc';
$roundtripped->[3] = 'def';
is( Dump($roundtripped), Dump($undumped), "touched many anchors" );

my $s = 'scal';
$undumped = [ \$s, \$s, \$s ];
$roundtripped = Load( Dump($undumped) );
is( Dump($roundtripped), Dump($undumped), "scalar reference" );

$undumped->[1]     = 'hello';
$roundtripped->[1] = 'hello';
is( Dump($roundtripped), Dump($undumped), "touched scalar reference" );

my $os = bless \$s, 'obj_scal';
my $oa = bless ['array'], 'obj_array';
my $oh = bless { key => 'value' }, 'obj_hash';

$undumped = [ $os, $oa, $oh, $os, $oa, $oh ];
$roundtripped = Load( Dump($undumped) );
TODO: {
    local $TODO = "Skip this because anchor #1 is going to be truncated. no problem";
    is( Dump($roundtripped), Dump($undumped), "object" );
}

$undumped->[3]     = 'mod';
$undumped->[4]     = {};
$undumped->[5]     = $undumped->[4];
$roundtripped->[3] = 'mod';
$roundtripped->[4] = {};
$roundtripped->[5] = $roundtripped->[4];
is( Dump($roundtripped), Dump($undumped), "touched object" );
