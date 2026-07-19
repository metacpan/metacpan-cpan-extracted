#!/usr/bin/perl
######################################################################
# eg/km/mb_practical.pl - កាត់ជួរឈរថេរដោយមិនធ្វើឱ្យតួអក្សរខូច
#
# ឧទាហរណ៍នេះបង្ហាញអ្វី (កិច្ចការពិតតូចមួយ)៖
#   កាត់បន្ទាត់ Shift_JIS ឱ្យនៅ DISPLAY WIDTH ថេរ សម្រាប់ output ជួរឈរ
#   ថេរ ដោយរាប់តួអក្សរទទឹងពាក់កណ្តាលជា 1 ជួរឈរ និងតួអក្សរទទឹងពេញជា 2
#   ជួរឈរ (សមាមាត្របុរាណ 1:2) ហើយមិនដែលពុះតួអក្សរពីរបៃនៅព្រំដែនឡើយ។
#
# ខុសពី CORE យ៉ាងណា៖
#   CORE substr(EXPR, 0, N) បែបឆោតល្ងង់ កាត់នៅ OCTET ទី N ហើយអាចទុក
#   lead byte សំយុង -- ពាក់កណ្តាលតួអក្សរដែលខូច។ នៅទីនេះ យើងដើរតាមតួអក្សរ
#   ទាំងមូលដោយ mb::split('') វាស់ទទឹងតួអក្សរនីមួយៗតាមប្រវែងបៃរបស់វា (1 បៃ
#   -> 1 ជួរឈរ, 2 បៃ -> 2 ជួរឈរ) ហើយឈប់មុនពេលលើសថវិកា។ mb::length()
#   បញ្ជាក់ថាលទ្ធផលជាចំនួនតួអក្សរគត់។
#
# ប្រភពជា US-ASCII; ទិន្នន័យ multibyte ប្រើ byte escape \xHH។ runtime
# interface តែប៉ុណ្ណោះ ដូច្នេះវាដំណើរការលើ perl គ្រប់កំណែចាប់ពី 5.005_03 ឡើងទៅ។
#
#     perl eg/km/mb_practical.pl
#
######################################################################
use strict;
use vars qw($line $budget $out $col $ch $w $aiu $octet_cut $char_cut);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# A B C បន្ទាប់មកហ៊ីរ៉ាហ្គាណាទទឹងពេញបីតួ a i u បន្ទាប់មកកាតាកាណាទទឹងពាក់កណ្តាលពីរតួ។
#   ASCII A B C            : 1 ជួរឈរក្នុងមួយតួ
#   ទទឹងពេញ a(\x82\xA0) i(\x82\xA2) u(\x82\xA4) : 2 ជួរឈរក្នុងមួយតួ
#   ទទឹងពាក់កណ្តាល ka(\xB6) ki(\xB7)             : 1 ជួរឈរក្នុងមួយតួ
$line   = "ABC\x82\xA0\x82\xA2\x82\xA4\xB6\xB7";
$budget = 7;   # កាត់ឱ្យនៅ 7 ជួរឈរបង្ហាញ

# ការកាត់ដែលសុវត្ថិភាពនៅព្រំដែនតួអក្សរ និងដឹងទទឹង។
$out = '';
$col = 0;
for $ch (mb::split('', $line)) {
    $w = length($ch);        # 1 បៃ -> 1 ជួរឈរ, 2 បៃ -> 2 ជួរឈរ
    last if $col + $w > $budget;
    $out .= $ch;
    $col += $w;
}

# ABC (3 ជួរឈរ) + a (2) + i (2) = 7 ជួរឈរ; u នឹងលើសហើយត្រូវទម្លាក់ ដូច្នេះ
# តួអក្សរពីរបៃចុងក្រោយនៅពេញលេញ។
print "input chars      : ", mb::length($line), "\n";        # 8
print "budget columns   : $budget\n";                        # 7
print "kept chars       : ", mb::length($out), "\n";         # 5
print "used columns     : $col\n";                           # 7
print "kept bytes       : ", length($out), "\n";             # 7

# ផ្ទុយពីទិន្នន័យពីរបៃសុទ្ធ៖ ការកាត់នៅចំនួន OCTET ថេរអាចធ្លាក់ខាងក្នុង
# តួអក្សរ។ ហ៊ីរ៉ាហ្គាណា a i u សុទ្ធតែពីរបៃ ដូច្នេះប្រវែងបៃសេសមានន័យថាការ
# កាត់បានពុះតួអក្សរ; mb::substr ឈប់នៅព្រំដែនតួអក្សរជានិច្ច (ប្រវែងបៃគូនៅទីនេះ)។
$aiu       = "\x82\xA0\x82\xA2\x82\xA4";
$octet_cut = substr($aiu, 0, 3);        # a + lead byte សំយុង
$char_cut  = mb::substr($aiu, 0, 1);    # a ត្រឹមត្រូវ
print "CORE substr 3oct : ", length($octet_cut), " bytes (odd -> split)\n"; # 3
print "mb::substr 1char : ", length($char_cut),  " bytes (whole char)\n";   # 2

exit 0;
