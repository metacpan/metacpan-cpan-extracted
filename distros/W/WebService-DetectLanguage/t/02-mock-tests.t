#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 4;
use lib 't/lib';
use Mock::HTTP::Tiny;
use WebService::DetectLanguage;

my %expected = (
    languages => qq[aa:AFAR/ab:ABKHAZIAN/af:AFRIKAANS/ak:AKAN/am:AMHARIC/ar:ARABIC/as:ASSAMESE/ay:AYMARA/az:AZERBAIJANI/ba:BASHKIR/be:BELARUSIAN/bg:BULGARIAN/bh:BIHARI/bi:BISLAMA/bn:BENGALI/bo:TIBETAN/br:BRETON/bs:BOSNIAN/bug:BUGINESE/ca:CATALAN/ceb:CEBUANO/chr:CHEROKEE/co:CORSICAN/crs:SESELWA/cs:CZECH/cy:WELSH/da:DANISH/de:GERMAN/dv:DHIVEHI/dz:DZONGKHA/egy:EGYPTIAN/el:GREEK/en:ENGLISH/eo:ESPERANTO/es:SPANISH/et:ESTONIAN/eu:BASQUE/fa:PERSIAN/fi:FINNISH/fj:FIJIAN/fo:FAROESE/fr:FRENCH/fy:FRISIAN/ga:IRISH/gd:SCOTS_GAELIC/gl:GALICIAN/gn:GUARANI/got:GOTHIC/gu:GUJARATI/gv:MANX/ha:HAUSA/haw:HAWAIIAN/hi:HINDI/hmn:HMONG/hr:CROATIAN/ht:HAITIAN_CREOLE/hu:HUNGARIAN/hy:ARMENIAN/ia:INTERLINGUA/id:INDONESIAN/ie:INTERLINGUE/ig:IGBO/ik:INUPIAK/is:ICELANDIC/it:ITALIAN/iu:INUKTITUT/iw:HEBREW/ja:JAPANESE/jw:JAVANESE/ka:GEORGIAN/kha:KHASI/kk:KAZAKH/kl:GREENLANDIC/km:KHMER/kn:KANNADA/ko:KOREAN/ks:KASHMIRI/ku:KURDISH/ky:KYRGYZ/la:LATIN/lb:LUXEMBOURGISH/lg:GANDA/lif:LIMBU/ln:LINGALA/lo:LAOTHIAN/lt:LITHUANIAN/lv:LATVIAN/mfe:MAURITIAN_CREOLE/mg:MALAGASY/mi:MAORI/mk:MACEDONIAN/ml:MALAYALAM/mn:MONGOLIAN/mr:MARATHI/ms:MALAY/mt:MALTESE/my:BURMESE/na:NAURU/ne:NEPALI/nl:DUTCH/no:NORWEGIAN/nr:NDEBELE/nso:PEDI/ny:NYANJA/oc:OCCITAN/om:OROMO/or:ORIYA/pa:PUNJABI/pl:POLISH/ps:PASHTO/pt:PORTUGUESE/qu:QUECHUA/rm:RHAETO_ROMANCE/rn:RUNDI/ro:ROMANIAN/ru:RUSSIAN/rw:KINYARWANDA/sa:SANSKRIT/sco:SCOTS/sd:SINDHI/sg:SANGO/si:SINHALESE/sk:SLOVAK/sl:SLOVENIAN/sm:SAMOAN/sn:SHONA/so:SOMALI/sq:ALBANIAN/sr:SERBIAN/ss:SISWANT/st:SESOTHO/su:SUNDANESE/sv:SWEDISH/sw:SWAHILI/syr:SYRIAC/ta:TAMIL/te:TELUGU/tg:TAJIK/th:THAI/ti:TIGRINYA/tk:TURKMEN/tl:TAGALOG/tlh:KLINGON/tn:TSWANA/to:TONGA/tr:TURKISH/ts:TSONGA/tt:TATAR/ug:UIGHUR/uk:UKRAINIAN/ur:URDU/uz:UZBEK/ve:VENDA/vi:VIETNAMESE/vo:VOLAPUK/war:WARAY_PHILIPPINES/wo:WOLOF/xh:XHOSA/yi:YIDDISH/yo:YORUBA/za:ZHUANG/zh:CHINESE_SIMPLIFIED/zh-Hant:CHINESE_TRADITIONAL/zu:ZULU],
    account_status => "date=2019-07-13/requests=0/bytes=0/plan=FREE/status=ACTIVE/plan_expires=undef/daily_requests_limit=1000/daily_bytes_limit=1048576",
    detect => "language-code=en/language-name=ENGLISH/is-reliable=Yes/confidence=15.47",
    multi_detect => "language-code=en/language-name=ENGLISH/is-reliable=Yes/confidence=15.47::language-code=en/language-name=ENGLISH/is-reliable=Yes/confidence=16.82",
);

my $api = WebService::DetectLanguage->new(
              key => "xxxxxx",
              ua  => Mock::HTTP::Tiny->new(),
          ) // BAIL_OUT("Failed to create user agent");

my @languages = sort { $a->code cmp $b->code } $api->languages();
my $result    = join "/",
                map { sprintf("%s:%s", $_->code, $_->name) } @languages;
# print STDERR "<<$result>>\n";
is($result, $expected{'languages'}, "list of supported languages");

my $account = $api->account_status();
$result     = sprintf("date=%s/requests=%d/bytes=%d/plan=%s/status=%s/plan_expires=%s/daily_requests_limit=%d/daily_bytes_limit=%d",
                      $account->date,
                      $account->requests,
                      $account->bytes,
                      $account->plan,
                      $account->status,
                      $account->plan_expires // 'undef',
                      $account->daily_requests_limit,
                      $account->daily_bytes_limit,
                     );

is($result, $expected{'account_status'}, "check account status");

my @results = $api->detect("many people say that they can make more even");
# my $result_string = join('||', map { detection_signature($_) } @results);
my $result_string = results_signature(@results);

is($result_string, $expected{detect}, "single language detection");

my @multi = $api->multi_detect(
                "many people say that they can make more even",
                "here and now are both pretty common words",
            );
my $string = join('::', map { results_signature(@$_) } @multi);
is($string, $expected{multi_detect}, "multiple language detection");

sub results_signature
{
    my @results = @_;

    return join('||', map { detection_signature($_) } @results);
}

sub detection_signature
{
    my $result = shift;

    return sprintf("language-code=%s/language-name=%s/is-reliable=%s/confidence=%.2f",
                   $result->language->code,
                   $result->language->name,
                   $result->is_reliable ? 'Yes' : 'No',
                   $result->confidence,
                  );
}

