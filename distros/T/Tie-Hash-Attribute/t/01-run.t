#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 17;

use Tie::Hash::Attribute;

tie my %tag, 'Tie::Hash::Attribute', sorted => 1;
%tag = map {($_ => undef)} qw( table tr td );

is_deeply \%tag, { table => undef, tr => undef, td => undef },                  "looks like a hash";

$tag{table}{$_} = 0 for qw( border cellpadding cellspacing );
is_deeply $tag{table}, { border => 0, cellpadding => 0, cellspacing => 0 },     "looks like a hash";
is $tag{-table}, ' border="0" cellpadding="0" cellspacing="0"',                 "correct attributes 1 level deep";

$tag{tr}{style}{color} = 'red';
$tag{tr}{style}{align} = 'right';
is $tag{-tr}, ' style="align: right; color: red;"',                             "correct attributes 2 levels deep";

$tag{td}{style}{align} = [qw(left right)];
$tag{td}{style}{color} = [qw(blue green red)];
is $tag{-td}, ' style="align: left; color: blue;"',                             "correct attributes rotating vals 1";
is $tag{-td}, ' style="align: right; color: green;"',                           "correct attributes rotating vals 2";
is $tag{-td}, ' style="align: left; color: red;"',                              "correct attributes rotating vals 3";
is $tag{-td}, ' style="align: right; color: blue;"',                            "correct attributes rotating vals 4";

%tag = ( style => { align => 'left', color => [qw(red green)] } );
is scalar %tag, ' style="align: left; color: red;"',                            "scalar emits all keys and values";

$tag{th}{style}{color} = ['#010101','#020202','#030303'];
is $tag{-th}, ' style="color: #010101"',                                        "no trailing semi-colon when one sub attr";

%tag = ();
is sprintf( '<th%s>', $tag{-th} ), '<th>',                                      "empty string when hash is empty";

%tag = ();
$tag{one}{two}{three}{four} = 'five';
is $tag{-one}, ' two="three: four"',                                            "deepness check on key";
is scalar %tag, ' one="two: three"',                                            "deepness check on scalar";

$tag{one}{three}{four}{five} = 'six';
is $tag{-one}, ' three="four: five" two="three: four"',                         "deepness check on key after another added";
is scalar %tag, ' one="three: four; two: three;"',                              "deepness check on scalar after another key added";

$tag{one}{two}{four}{five} = 'six';
is $tag{-one}, ' three="four: five" two="four: five; three: four;"',            "deepness check on sub key";
is scalar %tag, ' one="three: four; two: four;"',                               "deepness check on scalar with sub keys";

