use lib qw/lib/;
use Unicode::EastAsianWidth::Detect qw(is_cjk_lang);

print "You uses" . (!is_cjk_lang() ? " not" : "") . " CJK\n";
