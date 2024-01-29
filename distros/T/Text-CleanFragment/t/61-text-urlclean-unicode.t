#!perl -w
use strict;
use Test2::V0 '-no_srand';
use Data::Dumper;

use Text::CleanFragment;
use utf8;

binmode DATA, ':utf8';
my @tests = map { s!\s+$!!g; [split /\|/] } grep {!/^\s*#/ && /\S/} <DATA>;

push @tests, ["String\nWith\n\nNewlines\r\nEmbedded","String_With_Newlines_Embedded"];
push @tests, ["String\tWith \t Tabs \tEmbedded","String_With_Tabs_Embedded"];
push @tests, ["","",'Empty String'];
push @tests, ["\x{5317}\x{4EB0}\n",  # those are the Chinese characters for Beijing, according to Sean M. Burke
              "\x{5317}\x{4EB0}", '(Some) Chinese characters also work'];
push @tests, ["Do p\x{00FC}t <this> into URL's?","Do_p\x{00FC}t_this_into_URLs",'Synopsis'];
push @tests, ["Do\x{A0}nonbreaking\x{A0}spaces\x{A0}work?","Do\x{A0}nonbreaking\x{A0}spaces\x{A0}work",'nbsp']
    if $] > 5.032000; # earlier versions match \x{A0} in \s

plan tests => 1+@tests*4;

for (@tests) {
    my $name= $_->[2] || $_->[1];
    my $res = clean_fragment_filename($_->[0]);
    is $res, $_->[1], $name;
    like $res,        qr/^([-–.,;\w\d\x{A0}+,();&!]([-–.\w\d\x{A0}+,();&!]*[-–.,;\w\d\x{A0}+,();&!])?)?$/,
      "Result matches qr/^([-–.,;\\w\\d\\x{A0}+,();&!]([-–.\\w\\d\x{A0}+,();&!]*[-–.,;\\w\\d\\x{A0}+,();&!])?)?\$/";
    unlike $res, qr/--/ , "No doubled dashes in result";
    is clean_fragment_filename($_->[1]), $_->[1], "'$_->[1]' is idempotent";
};

is [clean_fragment(
    'Lenny', 'Motörhead'
)], ['Lenny','Motorhead'], "Multiple arguments also work";

__DATA__
Grégory|Grégory
   Leading Spaces|Leading_Spaces
   Trailing Space     |Trailing_Space
Don't Think|Dont_Think|Apostrophes get eliminated
Don´t Think|Dont_Think|Left-quote-Apostrophes get eliminated
He said "happy", not "sad"|He_said_happy,_not_sad|Quotes get eliminated
Ævar Arnfjörð Bjarmason|Ævar_Arnfjörð_Bjarmason
forward/slash|forward_slash
back\slash|back_slash
Ümloud feat. ß|Ümloud_feat._ß
/foo/bar/index.html|foo_bar_index.html|filename with path
<script>alert();</script>|script_alert();_script|Tag injection
javascript:alert();|javascript_alert();|Immediate JS URL attempt
&lt;script&gt;|&lt;script&gt;|Amp-encoded tag injection
C++|C++|Plus signs get eliminated
Justice - Cross|Justice-Cross|Space-dash-space to dash
Justice - - Across the Universe|Justice-Across_the_Universe|Repeated dashes also get squashed
What Is This?|What_Is_This|Question marks get eliminated
Do püt <this> into URL's?|Do_püt_this_into_URLs|Synopsis
This is plenking ...|This_is_plenking...|No underscore before \W
Also    this   should be ___ squashed|Also_this_should_be_squashed|Squash underscores
Also _ _ _ this _ _ should be _ _ squashed|Also_this_should_be_squashed|Squash underscores
Bang!|Bang!|Exclamation points also get eliminated
Die Arzte - Drei Mann – Zwei Songs (EP)|Die_Arzte-Drei_Mann–Zwei_Songs(EP)|long dash
C++|C++|Trailing underscores get eliminated (even if this mangles C++)
C++ and C|C++_and_C|Underscores get merged
C++ - _ - C|C++-C|Underscore-Dashes get converted to dashes
some`backquotes|somebackquotes

