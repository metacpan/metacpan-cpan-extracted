#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use lib ".";

BEGIN {
    binmode STDOUT, ":utf8" or die;
    binmode STDERR, ":utf8" or die;
}

use Test::Tester;
use Test::Regexp;
use t::Common;

sub init_data;

my @data   = init_data;

my $match_res;

foreach my $data (@data) {
    my ($subject, $pattern, $match, $expected_l, $captures) = @$data;

    for my $updown (qw [up down]) {
        my $subject2 = $subject;
        if ($updown eq "up") {
            utf8::upgrade   ($subject2);
        }
        else {
            utf8::downgrade ($subject2);
        }

        my $keep  = @$captures;
        my $param = $keep ? "keep_pattern" : "pattern";

        foreach my $args ([], [utf8_upgrade => 0], [utf8_downgrade => 0]) {
            my $match_val = $match =~ /[ym1]/i;

            my $expected = shift @$expected_l;

            #
            # For now, we aren't testing without any escaping -- this
            # requires some special handling of newlines to not upset
            # run_test.
            #
            foreach my $escape (1 .. 4) {

                my ($premature, @results) = run_tests sub {
                    $match_res = match subject    =>  $subject2,
                                       $param     =>  $pattern,
                                       match      =>  $match_val,
                                       captures   =>  $captures,
                                       escape     =>  $escape,
                                       @$args,
                };

                check results     => \@results,
                      premature   =>  $premature,
                      expected    =>  $expected,
                      match       =>  $match_val,
                      match_res   =>  $match_res,
                      pattern     =>  $pattern,
                      subject     =>  $subject2,
                      keep        =>  $keep,
                      escape      =>  $escape,
                ;
            }
        }
    }
}


sub init_data {(
    # Match without captures.
    ["F\x{f8}o",  qr /[\x20-\xFF]+/, 'y',
      ['PPPPPPPP', 'PPPPPPPP', 'PPPP', 'PPPPPPPP', 'PPPP', 'PPPPPPPP'],
      []],

    # Match without captures.
    ["F\x{f8}o",  qr /\w+/, 'y',
      ['PPPPPFSS', 'PPPPPFSS', 'PPPP', 'PFSSPPPP', 'PFSS', 'PFSSPPPP'],
      []],

    # Match with captures
    ["F\x{f8}o",  qr /[\x20-\xFF](?<a>[\x20-\xFF])(?<b>[\x20-\xFF])/, 'y',
      ['PPPPPPPPPPPPPPPPPPPP', 'PPPPPPPPPPPPPPPPPPPP', 'PPPPPPPPPP',
       'PPPPPPPPPPPPPPPPPPPP', 'PPPPPPPPPP', 'PPPPPPPPPPPPPPPPPPPP'],
      [[a => "\x{f8}"], [b => "o"]]],
)}

__END__
