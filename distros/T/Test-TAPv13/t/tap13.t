#! /usr/bin/perl

use Test::TAPv13 ':all'; # must come before Test::More
use Test::More tests => 3;

my $data = { affe => { tiger => 111,
                       birne => "amazing",
                       loewe => [ qw( 1 two three) ],
                     },
             zomtec => "here's another one",
             DrWho  => undef,
           };

ok(1, "hot stuff");
tap13_pragma "-strict"; # +strict does not work in TAP::Harness with the nested TAP yet
tap13_yaml($data);
ok(1, "more hot stuff");

subtest 'Level 2 subtest'
 => sub {
         plan tests => 3;
         tap13_pragma "+strict"; # nested pragmas are ignored
         pass("Sub test");
         tap13_yaml($data);
         pass("Sub stuff");
         subtest 'Level 3 subtest'
         => sub {
                 plan tests => 2;
                 tap13_pragma "+strict"; # nested pragmas are ignored
                 pass("DEEP SUBTEST");
                 tap13_yaml($data);
                 pass("DEEP STUFF");
                };
        };
