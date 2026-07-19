#!/usr/bin/perl
######################################################################
# eg/km/mb_length.pl - រាប់តួអក្សរធៀបនឹងបៃ ដោយប្រើ mb
#
# ឧទាហរណ៍នេះបង្ហាញអ្វី៖
#   length() របស់ CORE រាប់ OCTET (បៃ); mb::length() រាប់តួអក្សរ multibyte
#   ទាំងមូលតាម script encoding ដែលបានជ្រើសរើស។ mb::substr() និង
#   mb::index() ក៏ធ្វើការតាមឯកតាតួអក្សរដែរ ដូច្នេះតួអក្សរពីរបៃមិនដែលត្រូវ
#   កាត់ពាក់កណ្តាលទេ។
#
# ខុសពី CORE យ៉ាងណា៖
#   length("\x82\xA0") គឺ 2 (បៃ) ប៉ុន្តែ mb::length("\x82\xA0") គឺ 1
#   (ហ៊ីរ៉ាហ្គាណា Shift_JIS មួយ)។
#
# ចំណាំ៖ កូដប្រភព និងទិន្នន័យ \xHH នៅតែជា US-ASCII; ឯកសារនេះជា UTF-8 (មតិយោបល់ជាភាសាខ្មែរតែប៉ុណ្ណោះ)។
#
#     perl eg/km/mb_length.pl
#
######################################################################
use strict;
use vars qw($aiu $byte_len $char_len $head $tail $pos);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# ហ៊ីរ៉ាហ្គាណា Shift_JIS បីតួ សរុបប្រាំមួយបៃ៖
#     \x82\xA0  a   \x82\xA2  i   \x82\xA4  u
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# length() របស់ CORE រាប់បៃ; mb::length() រាប់តួអក្សរ។
$byte_len = length($aiu);
$char_len = mb::length($aiu);
print "byte length      : $byte_len\n";   # 6
print "character length : $char_len\n";   # 3

# mb::substr() កាត់តាមឯកតាតួអក្សរ ដូច្នេះតួអក្សរពីរបៃមិនត្រូវពុះជាពាក់
# កណ្តាលទេ។ តួអក្សរ 2 ដំបូងគឺជាខ្សែអក្សរ 4 បៃត្រឹមត្រូវ។
$head = mb::substr($aiu, 0, 2);
$tail = mb::substr($aiu, 2);
print "first 2 chars    : ", length($head), " bytes\n";   # 4
print "remaining chars  : ", length($tail), " bytes\n";   # 2

# mb::index() រាយការណ៍ទីតាំងជាតួអក្សរ មិនមែនជាបៃទេ។ តួអក្សរទីបីចាប់ផ្តើម
# នៅបៃ 4 ប៉ុន្តែនៅសន្ទស្សន៍តួអក្សរ 2។
$pos = mb::index($aiu, "\x82\xA4");
print "index of 3rd char: $pos\n";        # 2

exit 0;
