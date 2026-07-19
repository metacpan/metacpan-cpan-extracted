#!/usr/bin/perl
######################################################################
# eg/km/mb_split.pl - បំបែកនៅព្រំដែនតួអក្សរ ដោយប្រើ mb::split
#
# ឧទាហរណ៍នេះបង្ហាញអ្វី៖
#   mb::split('', EXPR) បំបែកខ្សែអក្សរទៅជាតួអក្សរ multibyte ទាំងមូល ហើយ
#   mb::split(PATTERN, EXPR) បំបែកនៅ delimiter MBCS ដោយមិនដែលផ្គូផ្គងបៃ
#   ដែលស្ថិតនៅខាងក្នុងតួអក្សរ multibyte ឡើយ។
#
# ខុសពី CORE យ៉ាងណា៖
#   CORE split(//, "\x82\xA0") ត្រឡប់ OCTET ពីរ ("\x82", "\xA0"); ហ៊ីរ៉ា
#   ហ្គាណាពីរបៃត្រូវហែក។ mb::split('', ...) ត្រឡប់វាជាតួអក្សរតែមួយ។
#   mb::split ជាដៃគូគ្រប់គ្រងពេល runtime នៃ "split //" ដែលបាន transpile
#   ហើយឆបគ្នាថយក្រោយដល់ Perl 5.005_03។
#
# ប្រភពជា US-ASCII; ទិន្នន័យ multibyte ប្រើ byte escape \xHH។
#
#     perl eg/km/mb_split.pl
#
######################################################################
use strict;
use vars qw($aiu @byte @char $csv @field);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# ហ៊ីរ៉ាហ្គាណា Shift_JIS បីតួ៖ a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)។
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# CORE split(//, ...) មើលឃើញបៃ៖ ប្រាំមួយនៅទីនេះ។
@byte = split(//, $aiu);
print "CORE split(//)   : ", scalar(@byte), " pieces (bytes)\n";   # 6

# mb::split('', ...) មើលឃើញតួអក្សរ៖ បីនៅទីនេះ។
@char = mb::split('', $aiu);
print "mb::split('')    : ", scalar(@char), " pieces (chars)\n";   # 3

# បំបែកនៅ delimiter MBCS។ delimiter គឺហ៊ីរ៉ាហ្គាណា a (\x82\xA0); mb::split
# ផ្គូផ្គងវាជាតួអក្សរទាំងមូល មិនមែនជាបៃ \x82 ឬ \xA0 នៅកន្លែងណាដែលបៃ
# ទាំងនោះកើតឡើងឡើយ។
#     A a B a C  ->  fields: A, B, C
$csv   = "A\x82\xA0B\x82\xA0C";
@field = mb::split("\x82\xA0", $csv);
print "fields on MBCS   : ", scalar(@field), " (", join(',', @field), ")\n"; # 3 (A,B,C)

# រាប់ចំនួនតួអក្សរតាមរយៈ list context នៃ mb::split (ដូចជាកម្មវិធីជំនួយ chars())។
{
    local($^W) = undef;
    print "character count  : ", scalar(mb::split('', $aiu)), "\n";   # 3
}

exit 0;
