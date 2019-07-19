package Mock::HTTP::Tiny;

use strict;
use warnings;
use Moo;
use Ref::Util 0.202 qw/ is_arrayref /;

my %get = (
    "https://ws.detectlanguage.com/0.2/languages" =>
    qq|[{"code":"aa","name":"AFAR"},{"code":"ab","name":"ABKHAZIAN"},{"code":"af","name":"AFRIKAANS"},{"code":"ak","name":"AKAN"},{"code":"am","name":"AMHARIC"},{"code":"ar","name":"ARABIC"},{"code":"as","name":"ASSAMESE"},{"code":"ay","name":"AYMARA"},{"code":"az","name":"AZERBAIJANI"},{"code":"ba","name":"BASHKIR"},{"code":"be","name":"BELARUSIAN"},{"code":"bg","name":"BULGARIAN"},{"code":"bh","name":"BIHARI"},{"code":"bi","name":"BISLAMA"},{"code":"bn","name":"BENGALI"},{"code":"bo","name":"TIBETAN"},{"code":"br","name":"BRETON"},{"code":"bs","name":"BOSNIAN"},{"code":"bug","name":"BUGINESE"},{"code":"ca","name":"CATALAN"},{"code":"ceb","name":"CEBUANO"},{"code":"chr","name":"CHEROKEE"},{"code":"co","name":"CORSICAN"},{"code":"crs","name":"SESELWA"},{"code":"cs","name":"CZECH"},{"code":"cy","name":"WELSH"},{"code":"da","name":"DANISH"},{"code":"de","name":"GERMAN"},{"code":"dv","name":"DHIVEHI"},{"code":"dz","name":"DZONGKHA"},{"code":"egy","name":"EGYPTIAN"},{"code":"el","name":"GREEK"},{"code":"en","name":"ENGLISH"},{"code":"eo","name":"ESPERANTO"},{"code":"es","name":"SPANISH"},{"code":"et","name":"ESTONIAN"},{"code":"eu","name":"BASQUE"},{"code":"fa","name":"PERSIAN"},{"code":"fi","name":"FINNISH"},{"code":"fj","name":"FIJIAN"},{"code":"fo","name":"FAROESE"},{"code":"fr","name":"FRENCH"},{"code":"fy","name":"FRISIAN"},{"code":"ga","name":"IRISH"},{"code":"gd","name":"SCOTS_GAELIC"},{"code":"gl","name":"GALICIAN"},{"code":"gn","name":"GUARANI"},{"code":"got","name":"GOTHIC"},{"code":"gu","name":"GUJARATI"},{"code":"gv","name":"MANX"},{"code":"ha","name":"HAUSA"},{"code":"haw","name":"HAWAIIAN"},{"code":"hi","name":"HINDI"},{"code":"hmn","name":"HMONG"},{"code":"hr","name":"CROATIAN"},{"code":"ht","name":"HAITIAN_CREOLE"},{"code":"hu","name":"HUNGARIAN"},{"code":"hy","name":"ARMENIAN"},{"code":"ia","name":"INTERLINGUA"},{"code":"id","name":"INDONESIAN"},{"code":"ie","name":"INTERLINGUE"},{"code":"ig","name":"IGBO"},{"code":"ik","name":"INUPIAK"},{"code":"is","name":"ICELANDIC"},{"code":"it","name":"ITALIAN"},{"code":"iu","name":"INUKTITUT"},{"code":"iw","name":"HEBREW"},{"code":"ja","name":"JAPANESE"},{"code":"jw","name":"JAVANESE"},{"code":"ka","name":"GEORGIAN"},{"code":"kha","name":"KHASI"},{"code":"kk","name":"KAZAKH"},{"code":"kl","name":"GREENLANDIC"},{"code":"km","name":"KHMER"},{"code":"kn","name":"KANNADA"},{"code":"ko","name":"KOREAN"},{"code":"ks","name":"KASHMIRI"},{"code":"ku","name":"KURDISH"},{"code":"ky","name":"KYRGYZ"},{"code":"la","name":"LATIN"},{"code":"lb","name":"LUXEMBOURGISH"},{"code":"lg","name":"GANDA"},{"code":"lif","name":"LIMBU"},{"code":"ln","name":"LINGALA"},{"code":"lo","name":"LAOTHIAN"},{"code":"lt","name":"LITHUANIAN"},{"code":"lv","name":"LATVIAN"},{"code":"mfe","name":"MAURITIAN_CREOLE"},{"code":"mg","name":"MALAGASY"},{"code":"mi","name":"MAORI"},{"code":"mk","name":"MACEDONIAN"},{"code":"ml","name":"MALAYALAM"},{"code":"mn","name":"MONGOLIAN"},{"code":"mr","name":"MARATHI"},{"code":"ms","name":"MALAY"},{"code":"mt","name":"MALTESE"},{"code":"my","name":"BURMESE"},{"code":"na","name":"NAURU"},{"code":"ne","name":"NEPALI"},{"code":"nl","name":"DUTCH"},{"code":"no","name":"NORWEGIAN"},{"code":"nr","name":"NDEBELE"},{"code":"nso","name":"PEDI"},{"code":"ny","name":"NYANJA"},{"code":"oc","name":"OCCITAN"},{"code":"om","name":"OROMO"},{"code":"or","name":"ORIYA"},{"code":"pa","name":"PUNJABI"},{"code":"pl","name":"POLISH"},{"code":"ps","name":"PASHTO"},{"code":"pt","name":"PORTUGUESE"},{"code":"qu","name":"QUECHUA"},{"code":"rm","name":"RHAETO_ROMANCE"},{"code":"rn","name":"RUNDI"},{"code":"ro","name":"ROMANIAN"},{"code":"ru","name":"RUSSIAN"},{"code":"rw","name":"KINYARWANDA"},{"code":"sa","name":"SANSKRIT"},{"code":"sco","name":"SCOTS"},{"code":"sd","name":"SINDHI"},{"code":"sg","name":"SANGO"},{"code":"si","name":"SINHALESE"},{"code":"sk","name":"SLOVAK"},{"code":"sl","name":"SLOVENIAN"},{"code":"sm","name":"SAMOAN"},{"code":"sn","name":"SHONA"},{"code":"so","name":"SOMALI"},{"code":"sq","name":"ALBANIAN"},{"code":"sr","name":"SERBIAN"},{"code":"ss","name":"SISWANT"},{"code":"st","name":"SESOTHO"},{"code":"su","name":"SUNDANESE"},{"code":"sv","name":"SWEDISH"},{"code":"sw","name":"SWAHILI"},{"code":"syr","name":"SYRIAC"},{"code":"ta","name":"TAMIL"},{"code":"te","name":"TELUGU"},{"code":"tg","name":"TAJIK"},{"code":"th","name":"THAI"},{"code":"ti","name":"TIGRINYA"},{"code":"tk","name":"TURKMEN"},{"code":"tl","name":"TAGALOG"},{"code":"tlh","name":"KLINGON"},{"code":"tn","name":"TSWANA"},{"code":"to","name":"TONGA"},{"code":"tr","name":"TURKISH"},{"code":"ts","name":"TSONGA"},{"code":"tt","name":"TATAR"},{"code":"ug","name":"UIGHUR"},{"code":"uk","name":"UKRAINIAN"},{"code":"ur","name":"URDU"},{"code":"uz","name":"UZBEK"},{"code":"ve","name":"VENDA"},{"code":"vi","name":"VIETNAMESE"},{"code":"vo","name":"VOLAPUK"},{"code":"war","name":"WARAY_PHILIPPINES"},{"code":"wo","name":"WOLOF"},{"code":"xh","name":"XHOSA"},{"code":"yi","name":"YIDDISH"},{"code":"yo","name":"YORUBA"},{"code":"za","name":"ZHUANG"},{"code":"zh","name":"CHINESE_SIMPLIFIED"},{"code":"zh-Hant","name":"CHINESE_TRADITIONAL"},{"code":"zu","name":"ZULU"}]|,
    "https://ws.detectlanguage.com/0.2/user/status" => qq|{"date":"2019-07-13","requests":0,"bytes":0,"plan":"FREE","plan_expires":null,"daily_requests_limit":1000,"daily_bytes_limit":1048576,"status":"ACTIVE"}|,
);

my %post_form_results = (
    "https://ws.detectlanguage.com/0.2/detect" => {

        "q[]=many people say that they can make more even"
            => q|{"data":{"detections":[[{"language":"en","isReliable":true,"confidence":15.47}]]}}|,

        "q[]=many people say that they can make more even/q[]=here and now are both pretty common words"
            => q|{"data":{"detections":[[{"language":"en","isReliable":true,"confidence":15.47}],[{"language":"en","isReliable":true,"confidence":16.82}]]}}|,
    }
);

sub get
{
    my ($self, $url) = @_;

    if (exists $get{$url}) {
        return {
            success => 1,
            status  => 200,
            reason  => "OK",
            content => $get{$url},
        };
    }
    else {
        return {
            success => 0,
            status  => 404,
            reason  => "Not Found",
        };
    }
}

sub post_form
{
    my ($self, $url, $form_data) = @_;
    my @form_data = @$form_data;
    my @slices;
    while (@form_data > 0) {
        my $param = shift @form_data;
        my $value = shift @form_data;
        if (is_arrayref($value)) {
            push(@slices, map { "$param=$_" } @{ $value });
        }
        else {
            push(@slices, "$param=$value");
        }
    }
    my $signature = join('/', @slices);
    if (exists $post_form_results{$url}{$signature}) {
        return {
            success => 1,
            status  => 200,
            reason  => "OK",
            content => $post_form_results{$url}{$signature},
        };
    }
    else {
        return {
            success => 0,
            status  => 404,
            reason  => "Not Found",
        };
    }
}

1;
