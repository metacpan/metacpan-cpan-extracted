#!/usr/bin/perl
######################################################################
# eg/km/mb_regexp.pl - ការផ្គូផ្គងដែលដឹងអំពី multibyte ដោយប្រើ mb::qr
#
# ឧទាហរណ៍នេះបង្ហាញអ្វី៖
#   mb::qr(PATTERN) compile regular expression ដែល ".", character class
#   និង capture ធ្វើការជាតួអក្សរ multibyte ទាំងមូលតាម script encoding
#   ដែលបានជ្រើសរើស។
#
# ខុសពី CORE យ៉ាងណា៖
#   "." របស់ CORE ផ្គូផ្គង OCTET តែមួយ ដូច្នេះ /(.)/g លើហ៊ីរ៉ាហ្គាណា
#   Shift_JIS បីតួ ផ្តល់ប្រាំមួយបំណែក។ លំនាំដដែលតាមរយៈ mb::qr ផ្តល់បី
#   មួយបំណែកក្នុងមួយតួអក្សរ។ ជួរ class ដូចជា [a-hiragana ...] ប្រៀបធៀប
#   តួអក្សរទាំងមូល ហើយ capture ត្រឡប់តួអក្សរទាំងមូល។
#
# ប្រភពជា US-ASCII; ទិន្នន័យ multibyte ប្រើ byte escape \xHH។ នេះជា
# runtime interface (គ្មាន source filter) ដូច្នេះវាដំណើរការលើ perl គ្រប់
# កំណែចាប់ពី 5.005_03 ឡើងទៅ។
#
#     perl eg/km/mb_regexp.pl
#
######################################################################
use strict;
use vars qw($aiu @core @mbcs $dot $range $cap @found);

use FindBin;
use lib "$FindBin::Bin/../../lib";
use mb;
mb::set_script_encoding('sjis');

# ហ៊ីរ៉ាហ្គាណា Shift_JIS បីតួ៖ a(\x82\xA0) i(\x82\xA2) u(\x82\xA4)។
$aiu = "\x82\xA0\x82\xA2\x82\xA4";

# "." របស់ CORE គឺ octet មួយ -- ប្រាំមួយបំណែកសម្រាប់ប្រាំមួយបៃ។
@core = ($aiu =~ /(.)/g);
print "CORE /(.)/g      : ", scalar(@core), " pieces (bytes)\n";   # 6

# mb::qr("(.)") ធ្វើឱ្យ "." ក្លាយជាតួអក្សរទាំងមូល -- បីបំណែក។ compile
# ម្តង រួចបញ្ចូលលំនាំដែល compile រួចទៅក្នុងការផ្គូផ្គង។
$dot  = mb::qr("(.)");
@mbcs = ($aiu =~ /$dot/g);
print "mb::qr /(.)/g    : ", scalar(@mbcs), " pieces (chars)\n";   # 3

# ជួរ character-class លើប្លុកហ៊ីរ៉ាហ្គាណា a..n (\x82\xA0-\x82\xF1)។ ជួរ
# នេះប្រៀបធៀបតួអក្សរទាំងមូល ដូច្នេះ u នៅខាងក្នុង ហើយ "A" បែប ASCII មិននៅទេ។
$range = mb::qr("[\x82\xA0-\x82\xF1]");
print "u in [a-n]       : ", ("\x82\xA4" =~ /$range/ ? 1 : 0), "\n";   # 1
print "A in [a-n]       : ", ("A"         =~ /$range/ ? 1 : 0), "\n";   # 0

# capture ត្រឡប់តួអក្សរ multibyte ទាំងមូល (ពីរបៃនៅទីនេះ) មិនដែលពាក់
# កណ្តាលឡើយ។
$cap = mb::qr("([\x82\xA0-\x82\xF1])");
if ("X\x82\xA2Y" =~ /$cap/) {
    print "captured char    : ", length($1), " bytes\n";   # 2
}

# ស្វែងរកហ៊ីរ៉ាហ្គាណាគ្រប់តួក្នុងខ្សែអក្សរចម្រុះ ជាឯកតាតួអក្សរ។
@found = ("a\x82\xA0b\x82\xA2c" =~ /$cap/g);
print "hiragana found   : ", scalar(@found), "\n";   # 2

exit 0;
