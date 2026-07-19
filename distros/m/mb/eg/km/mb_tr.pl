#!/usr/bin/perl
######################################################################
# eg/km/mb_tr.pl - ការប្តូរអក្សរតាមឯកតាតួអក្សរ ដោយប្រើ mb::tr
#
# ឧទាហរណ៍នេះបង្ហាញអ្វី៖
#   mb::tr(STRING, SEARCH, REPLACE [, MODIFIER]) ប្តូរអក្សរតួអក្សរ
#   multibyte ទាំងមូល។ បើគ្មាន /r វាកែសម្រួល argument ទីមួយនៅនឹងកន្លែង
#   ហើយត្រឡប់ចំនួន; បើមាន /r វាត្រឡប់លទ្ធផល ហើយទុក argument ដដែល។
#
# ខុសពី CORE យ៉ាងណា៖
#   CORE tr/// ធ្វើការតាម octet ម្តងមួយ ដូច្នេះវាអាចខូច DAMEMOJI --
#   តួអក្សរពីរបៃដែលបៃទីពីរជា metacharacter ASCII ឧ. So(\x83\x5C) ដែលបៃ
#   ចុងក្រោយ \x5C ជា backslash។ CORE tr លើ \x5C នឹងប៉ះបៃចុងក្រោយនោះ;
#   mb::tr មើលឃើញ So ជាតួអក្សរតែមួយ ហើយទុកវាដដែល។
#
# ចំណាំ៖ ក្នុង mb::tr ជួរសហសញ្ញា (a-z) ត្រូវពង្រីកសម្រាប់តែចុង US-ASCII
# ប៉ុណ្ណោះ; តួអក្សរ multibyte ក្នុង SEARCH ត្រូវរាយម្តងមួយ (ដូចជា
# transpiler ពង្រីក tr/// បែប MBCS ដែរ)។
#
# ប្រភពជា US-ASCII; ទិន្នន័យ multibyte ប្រើ byte escape \xHH។
#
#     perl eg/km/mb_tr.pl
#
######################################################################
use strict;
use vars qw($fw $zenkaku $n $dame $core $cn $safe $sn $keep $out);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# លេខទទឹងពេញក្នុង Shift_JIS៖ 0(\x82\x4F) .. 9(\x82\x58)។ SEARCH រាយលេខ
# ទទឹងពេញទាំងដប់ជាតួអក្សរទាំងមូល; REPLACE ជាជួរ US-ASCII "0-9" (ជួរ
# សហសញ្ញា ASCII ដែល mb::tr ពង្រីក)។
$zenkaku = "\x82\x4F\x82\x50\x82\x51\x82\x52\x82\x53"
         . "\x82\x54\x82\x55\x82\x56\x82\x57\x82\x58";

# ទទឹងពេញ "1" "3" "6" -> ទទឹងពាក់កណ្តាល "136"។
$fw = "\x82\x50\x82\x52\x82\x55";
$n  = mb::tr($fw, $zenkaku, "0-9");
print "full->half count : $n\n";        # 3
print "full->half result: $fw\n";        # 136

# សុវត្ថិភាព DAMEMOJI។ ខ្សែអក្សរគឺ A So(\x83\x5C) B។ CORE tr ដែលតម្រង់
# ទៅបៃ backslash \x5C ធ្វើឱ្យតួអក្សរខូច; mb::tr ដែល map តែអក្សរ ASCII
# ទុក So ដដែលពេញលេញ។
$dame = "A\x83\x5CB";

$core = $dame;
$cn   = ($core =~ tr/\x5C/#/);   # CORE tr ប៉ះបៃចុងក្រោយនៃ So
print "CORE tr on \\x5C  : count=$cn (corrupts DAMEMOJI)\n";   # 1

$safe = $dame;
$sn   = mb::tr($safe, "AB", "ab");
print "mb::tr letters   : count=$sn, DAMEMOJI kept=",
      (substr($safe, 1, 2) eq "\x83\x5C" ? 1 : 0), "\n";       # 2, 1

# modifier /r៖ មិនបំផ្លាញ ត្រឡប់ច្បាប់ចម្លងដែលបានប្តូរអក្សរ។
$keep = "\x82\x50\x82\x51";                 # ទទឹងពេញ 1 2
$out  = mb::tr($keep, $zenkaku, "0-9", "r");
print "/r result        : $out\n";                            # 12
print "/r original kept : ",
      ($keep eq "\x82\x50\x82\x51" ? 1 : 0), "\n";            # 1

exit 0;
