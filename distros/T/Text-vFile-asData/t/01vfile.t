#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

if (eval "require Test::Differences") {
    no warnings 'redefine';
    *is_deeply = \&Test::Differences::eq_or_diff;
}

my $class = 'Text::vFile::asData';
require_ok( $class );
isa_ok( my $p = $class->new, $class );

# rfc2445 4.1
is_deeply( [ $p->_unwrap_lines(
    "FOO:This is a te",
    " st.  Not a",
    "  real foo." )
            ],
   [ "FOO:This is a test.  Not a real foo." ],
   "line unwrapping",
);

is_deeply( $p->parse_lines(
    "FOO:This is a te",
    " st.  Not a",
    "  real foo." ),
        {
            properties => {
                FOO => [ { value => "This is a test.  Not a real foo." }
                   ],
            },
        },
        "simple property"
       );


is_deeply( $p->parse_lines( 'CHECK:one\, two' ),
           {
               properties => {
                   CHECK => [ { value => 'one\, two' } ],
               },
           },
           "value containing an escaped comma"
          );

is_deeply( $p->parse_lines( "CHECK:one,two" ),
           {
               properties => {
                   CHECK => [ { value => "one,two" } ],
               },
           },
           "value containing an unescaped comma"
          );

is_deeply( $p->parse_lines( "CHECK;testing=one:two" ),
           {
            properties => {
                           CHECK => [ { value => 'two',
                                        param => { testing => 'one' }
                                      } ],
                           },
            },
           "a single parameter"
         );

is_deeply( $p->parse_lines( "CHECK;testing1=one;testing2=two:ffff" ),
           {
            properties => {
                           CHECK => [ { value => 'ffff',
                                        param => { testing1 => 'one',
                                                   testing2 => 'two', }
                                                 } ],
                                 },
                          },
            "multiple parameters"
           );

is_deeply( $p->parse_lines(
    "BEGIN:PIE",
    "FILLING:MEAT",
    "END:PIE",
   ),
           {
               objects => [
                   {
                       type => "PIE",
                       properties => {
                           FILLING => [ { value => 'MEAT' } ],
                       },
                   },
                  ],
           },
           "nest 1"
          );

is_deeply( $p->parse_lines(
    "BEGIN:PIE",
    "FILLING:MEAT",
    "BEGIN:CRUST",
    "BASE:CORN",
    "END:CRUST",
    "END:PIE",
   ),
           {
               objects => [
                   {
                       type       => "PIE",
                       properties => {
                           FILLING => [ { value => 'MEAT' } ],
                       },
                       objects   => [
                           {
                               type       => "CRUST",
                               properties => {
                                   BASE => [ { value => "CORN" } ],
                               }
                          },
                          ],
                   },
                  ],
           },
           "nest two"
          );

eval {
    $p->parse_lines(
        "BEGIN:PIE",
        "FILLING:MEAT",
        "END:FUN",
       );
};

like( $@, qr/^END FUN in PIE/, "nest failure" );

eval {
    $p->parse_lines(
        "BEGIN:PIE",
        "FILLING:MEAT",
       );
};

like( $@, qr/^BEGIN PIE without matching END/, "still nested nest failure" );

# rt #12381
eval {
    $p->parse_lines(
        "BEGIN:PIE",
        "FILLING:MEAT",
        "end:Pie",
       );
};

is( $@, "", "case-insensitive nesting" );


is_deeply( $p->parse_lines(
    "FOO;BAR=BAZ;QUUX=FLANGE:FROOBLE" ),
           {
               properties => {
                   FOO => [
                       {
                           param => {
                               BAR  => 'BAZ',
                               QUUX => 'FLANGE',
                           },
                           value => 'FROOBLE',
                       },
                      ],
               },
           },
           "simple params" );


is_deeply( $p->parse_lines(
    'FOO;BAR="BAZ was here";QUUX="FLANGE":FROOBLE' ),
           {
               properties => {
                   FOO => [
                       {
                           param => {
                               BAR  => 'BAZ was here',
                               QUUX => 'FLANGE',
                           },
                           value => 'FROOBLE',
                       },
                      ],
               },
           },
           "quoted params" );

is_deeply( $p->parse_lines(
    'FOO;BAR="BAZ was here";QUUX="FLANGE wants the colon: ":FROOBLE' ),
           {
               properties => {
                   FOO => [
                       {
                           param => {
                               BAR  => 'BAZ was here',
                               QUUX => 'FLANGE wants the colon: ',
                           },
                           value => 'FROOBLE',
                       },
                      ],
               },
           },
           "quoted params" );


is_deeply( $p->parse_lines(
    'FOO;BAR="BAZ was here";QUUX="FLANGE wants the colon: ":FROOBLE: NINJA' ),
           {
               properties => {
                   FOO => [
                       {
                           param => {
                               BAR  => 'BAZ was here',
                               QUUX => 'FLANGE wants the colon: ',
                           },
                           value => 'FROOBLE: NINJA',
                       },
                      ],
               },
           },
           "quoted params colon in the value" );

# Richard Russo points out this one
is_deeply( $p->parse_lines( q{ORGANIZER;CN="Will O'the Wisp":William} ),
           {
               properties => {
                   ORGANIZER => [
                       {
                           param  => {
                               CN => "Will O'the Wisp",
                           },
                           value => 'William',
                       },
                   ],
               },
           },
           "quoted param with embedded quote marks" );


# Leo's corner case; you will sometimes have two params with the same
# names (pesky vCards)
is_deeply( $p->parse_lines( 'FOO;corner=fruit;corner=case:BAZ' ),
           {
               properties => {
                   FOO => [
                       {
                           param  => {
                               corner => 'case',
                           },
                           value => 'BAZ',
                       },
                      ],
               },
           },
           "collapsing params" );

$p->preserve_params( 1 );
is_deeply( $p->parse_lines( 'FOO;corner=fruit;corner=case:BAZ' ),
           {
               properties => {
                   FOO => [
                       {
                           param  => {
                               corner => 'case',
                           },
                           params => [
                               { corner => 'fruit' },
                               { corner => 'case' },
                              ],
                           value => 'BAZ',
                       },
                      ],
               },
           },
           "collapsing and non-collapsing params" );

# Another one via Leo, parsing vCards with embedded images leads to segfaulty
# death - probably just because we try and tokenize 49k of data with a simple
# regex
open my $fh, "t/user_with_image.vcf" or die "couldn't open test card";
my $data = $p->parse( $fh );
ok( 1, "didn't segfault on parsing an embedded image" );
ok( exists $data->{objects}[0]{properties}{PHOTO}[0]{param}{BASE64},
    "Looks like we handled the vcard too" );

done_testing();
