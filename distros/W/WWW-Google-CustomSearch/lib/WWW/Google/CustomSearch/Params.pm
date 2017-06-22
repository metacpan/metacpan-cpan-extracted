package WWW::Google::CustomSearch::Params;

$WWW::Google::CustomSearch::Params::VERSION   = '0.35';
$WWW::Google::CustomSearch::Params::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

WWW::Google::CustomSearch::Params - Placeholders for parameters for WWW::Google::CustomSearch

=head1 VERSION

Version 0.35

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use vars qw(@ISA @EXPORT @EXPORT_OK);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw($FIELDS);

my $LANGUAGE = {
    'lang_ar' => 1, 'lang_bg' => 1, 'lang_ca' => 1, 'lang_zh-cn' => 1, 'lang_zh-tw' => 1,
    'lang_hr' => 1, 'lang_cs' => 1, 'lang_da' => 1, 'lang_nl'    => 1, 'lang_en'    => 1,
    'lang_et' => 1, 'lang_fi' => 1, 'lang_fr' => 1, 'lang_de'    => 1, 'lang_el'    => 1,
    'lang_iw' => 1, 'lang_hu' => 1, 'lang_is' => 1, 'lang_id'    => 1, 'lang_it'    => 1,
    'lang_ja' => 1, 'lang_ko' => 1, 'lang_lv' => 1, 'lang_lt'    => 1, 'lang_no'    => 1,
    'lang_pl' => 1, 'lang_pt' => 1, 'lang_ro' => 1, 'lang_ru'    => 1, 'lang_sr'    => 1,
    'lang_sk' => 1, 'lang_sl' => 1, 'lang_es' => 1, 'lang_sv'    => 1, 'lang_tr'    => 1 };

my $COUNTRY_COLLECTION = {
    'countryaf' => 1, 'countryal' => 1, 'countrydz' => 1, 'countryas' => 1, 'countryad' => 1,
    'countryao' => 1, 'countryai' => 1, 'countryaq' => 1, 'countryag' => 1, 'countryar' => 1,
    'countryam' => 1, 'countryaw' => 1, 'countryau' => 1, 'countryat' => 1, 'countryaz' => 1,
    'countrybs' => 1, 'countrybh' => 1, 'countrybd' => 1, 'countrybb' => 1, 'countryby' => 1,
    'countrybe' => 1, 'countrybz' => 1, 'countrybj' => 1, 'countrybm' => 1, 'countrybt' => 1,
    'countrybo' => 1, 'countryba' => 1, 'countrybw' => 1, 'countrybv' => 1, 'countrybr' => 1,
    'countryio' => 1, 'countrybn' => 1, 'countrybg' => 1, 'countrybf' => 1, 'countrybi' => 1,
    'countrykh' => 1, 'countrycm' => 1, 'countryca' => 1, 'countrycv' => 1, 'countryky' => 1,
    'countrycf' => 1, 'countrytd' => 1, 'countrycl' => 1, 'countrycn' => 1, 'countrycx' => 1,
    'countrycc' => 1, 'countryco' => 1, 'countrykm' => 1, 'countrycg' => 1, 'countrycd' => 1,
    'countryck' => 1, 'countrycr' => 1, 'countryci' => 1, 'countryhr' => 1, 'countrycu' => 1,
    'countrycy' => 1, 'countrycz' => 1, 'countrydk' => 1, 'countrydj' => 1, 'countrydm' => 1,
    'countrydo' => 1, 'countrytp' => 1, 'countryec' => 1, 'countryeg' => 1, 'countrysv' => 1,
    'countrygq' => 1, 'countryer' => 1, 'countryee' => 1, 'countryet' => 1, 'countryeu' => 1,
    'countryfk' => 1, 'countryfo' => 1, 'countryfj' => 1, 'countryfi' => 1, 'countryfr' => 1,
    'countryfx' => 1, 'countrygf' => 1, 'countrypf' => 1, 'countrytf' => 1, 'countryga' => 1,
    'countrygm' => 1, 'countryge' => 1, 'countryde' => 1, 'countrygh' => 1, 'countrygi' => 1,
    'countrygr' => 1, 'countrygl' => 1, 'countrygd' => 1, 'countrygp' => 1, 'countrygu' => 1,
    'countrygt' => 1, 'countrygn' => 1, 'countrygw' => 1, 'countrygy' => 1, 'countryht' => 1,
    'countryhm' => 1, 'countryva' => 1, 'countryhn' => 1, 'countryhk' => 1, 'countryhu' => 1,
    'countryis' => 1, 'countryin' => 1, 'countryid' => 1, 'countryir' => 1, 'countryiq' => 1,
    'countryie' => 1, 'countryil' => 1, 'countryit' => 1, 'countryjm' => 1, 'countryjp' => 1,
    'countryjo' => 1, 'countrykz' => 1, 'countryke' => 1, 'countryki' => 1, 'countrykp' => 1,
    'countrykr' => 1, 'countrykw' => 1, 'countrykg' => 1, 'countryla' => 1, 'countrylv' => 1,
    'countrylb' => 1, 'countryls' => 1, 'countrylr' => 1, 'countryly' => 1, 'countryli' => 1,
    'countrylt' => 1, 'countrylu' => 1, 'countrymo' => 1, 'countrymk' => 1, 'countrymg' => 1,
    'countrymw' => 1, 'countrymy' => 1, 'countrymv' => 1, 'countryml' => 1, 'countrymt' => 1,
    'countrymh' => 1, 'countrymq' => 1, 'countrymr' => 1, 'countrymu' => 1, 'countryyt' => 1,
    'countrymx' => 1, 'countryfm' => 1, 'countrymd' => 1, 'countrymc' => 1, 'countrymn' => 1,
    'countryms' => 1, 'countryma' => 1, 'countrymz' => 1, 'countrymm' => 1, 'countryna' => 1,
    'countrynr' => 1, 'countrynp' => 1, 'countrynl' => 1, 'countryan' => 1, 'countrync' => 1,
    'countrynz' => 1, 'countryni' => 1, 'countryne' => 1, 'countryng' => 1, 'countrynu' => 1,
    'countrynf' => 1, 'countrymp' => 1, 'countryno' => 1, 'countryom' => 1, 'countrypk' => 1,
    'countrypw' => 1, 'countryps' => 1, 'countrypa' => 1, 'countrypg' => 1, 'countrypy' => 1,
    'countrype' => 1, 'countryph' => 1, 'countrypn' => 1, 'countrypl' => 1, 'countrypt' => 1,
    'countrypr' => 1, 'countryqa' => 1, 'countryre' => 1, 'countryro' => 1, 'countryru' => 1,
    'countryrw' => 1, 'countrysh' => 1, 'countrykn' => 1, 'countrylc' => 1, 'countrypm' => 1,
    'countryvc' => 1, 'countryws' => 1, 'countrysm' => 1, 'countryst' => 1, 'countrysa' => 1,
    'countrysn' => 1, 'countrycs' => 1, 'countrysc' => 1, 'countrysl' => 1, 'countrysg' => 1,
    'countrysk' => 1, 'countrysi' => 1, 'countrysb' => 1, 'countryso' => 1, 'countryza' => 1,
    'countrygs' => 1, 'countryes' => 1, 'countrylk' => 1, 'countrysd' => 1, 'countrysr' => 1,
    'countrysj' => 1, 'countrysz' => 1, 'countryse' => 1, 'countrych' => 1, 'countrysy' => 1,
    'countrytw' => 1, 'countrytj' => 1, 'countrytz' => 1, 'countryth' => 1, 'countrytg' => 1,
    'countrytk' => 1, 'countryto' => 1, 'countrytt' => 1, 'countrytn' => 1, 'countrytr' => 1,
    'countrytm' => 1, 'countrytc' => 1, 'countrytv' => 1, 'countryug' => 1, 'countryua' => 1,
    'countryae' => 1, 'countryuk' => 1, 'countryus' => 1, 'countryum' => 1, 'countryuy' => 1,
    'countryuz' => 1, 'countryvu' => 1, 'countryve' => 1, 'countryvn' => 1, 'countryvg' => 1,
    'countryvi' => 1, 'countrywf' => 1, 'countryeh' => 1, 'countryye' => 1, 'countryyu' => 1,
    'countryzm' => 1, 'countryzw' => 1 };

my $COUNTRY_CODE = {
    'af' => 1, 'al' => 1, 'dz' => 1, 'as' => 1, 'ad' => 1, 'ao' => 1, 'ai' => 1, 'aq' => 1,
    'ag' => 1, 'ar' => 1, 'am' => 1, 'aw' => 1, 'au' => 1, 'at' => 1, 'az' => 1, 'bs' => 1,
    'bh' => 1, 'bd' => 1, 'bb' => 1, 'by' => 1, 'be' => 1, 'bz' => 1, 'bj' => 1, 'bm' => 1,
    'bt' => 1, 'bo' => 1, 'ba' => 1, 'bw' => 1, 'bv' => 1, 'br' => 1, 'io' => 1, 'bn' => 1,
    'bg' => 1, 'bf' => 1, 'bi' => 1, 'kh' => 1, 'cm' => 1, 'ca' => 1, 'cv' => 1, 'ky' => 1,
    'cf' => 1, 'td' => 1, 'cl' => 1, 'cn' => 1, 'cx' => 1, 'cc' => 1, 'co' => 1, 'km' => 1,
    'cg' => 1, 'cd' => 1, 'ck' => 1, 'cr' => 1, 'ci' => 1, 'hr' => 1, 'cu' => 1, 'cy' => 1,
    'cz' => 1, 'dk' => 1, 'dj' => 1, 'dm' => 1, 'do' => 1, 'ec' => 1, 'eg' => 1, 'sv' => 1,
    'gq' => 1, 'er' => 1, 'ee' => 1, 'et' => 1, 'fk' => 1, 'fo' => 1, 'fj' => 1, 'fi' => 1,
    'fr' => 1, 'gf' => 1, 'pf' => 1, 'tf' => 1, 'ga' => 1, 'gm' => 1, 'ge' => 1, 'de' => 1,
    'gh' => 1, 'gi' => 1, 'gr' => 1, 'gl' => 1, 'gd' => 1, 'gp' => 1, 'gu' => 1, 'gt' => 1,
    'gn' => 1, 'gw' => 1, 'gy' => 1, 'ht' => 1, 'hm' => 1, 'va' => 1, 'hn' => 1, 'hk' => 1,
    'hu' => 1, 'is' => 1, 'in' => 1, 'id' => 1, 'ir' => 1, 'iq' => 1, 'ie' => 1, 'il' => 1,
    'it' => 1, 'jm' => 1, 'jp' => 1, 'jo' => 1, 'kz' => 1, 'ke' => 1, 'ki' => 1, 'kp' => 1,
    'kr' => 1, 'kw' => 1, 'kg' => 1, 'la' => 1, 'lv' => 1, 'lb' => 1, 'ls' => 1, 'lr' => 1,
    'ly' => 1, 'li' => 1, 'lt' => 1, 'lu' => 1, 'mo' => 1, 'mk' => 1, 'mg' => 1, 'mw' => 1,
    'my' => 1, 'mv' => 1, 'ml' => 1, 'mt' => 1, 'mh' => 1, 'mq' => 1, 'mr' => 1, 'mu' => 1,
    'yt' => 1, 'mx' => 1, 'fm' => 1, 'md' => 1, 'mc' => 1, 'mn' => 1, 'ms' => 1, 'ma' => 1,
    'mz' => 1, 'mm' => 1, 'na' => 1, 'nr' => 1, 'np' => 1, 'nl' => 1, 'an' => 1, 'nc' => 1,
    'nz' => 1, 'ni' => 1, 'ne' => 1, 'ng' => 1, 'nu' => 1, 'nf' => 1, 'mp' => 1, 'no' => 1,
    'om' => 1, 'pk' => 1, 'pw' => 1, 'ps' => 1, 'pa' => 1, 'pg' => 1, 'py' => 1, 'pe' => 1,
    'ph' => 1, 'pn' => 1, 'pl' => 1, 'pt' => 1, 'pr' => 1, 'qa' => 1, 're' => 1, 'ro' => 1,
    'ru' => 1, 'rw' => 1, 'sh' => 1, 'kn' => 1, 'lc' => 1, 'pm' => 1, 'vc' => 1, 'ws' => 1,
    'sm' => 1, 'st' => 1, 'sa' => 1, 'sn' => 1, 'cs' => 1, 'sc' => 1, 'sl' => 1, 'sg' => 1,
    'sk' => 1, 'si' => 1, 'sb' => 1, 'so' => 1, 'za' => 1, 'gs' => 1, 'es' => 1, 'lk' => 1,
    'sd' => 1, 'sr' => 1, 'sj' => 1, 'sz' => 1, 'se' => 1, 'ch' => 1, 'sy' => 1, 'tw' => 1,
    'tj' => 1, 'tz' => 1, 'th' => 1, 'tl' => 1, 'tg' => 1, 'tk' => 1, 'to' => 1, 'tt' => 1,
    'tn' => 1, 'tr' => 1, 'tm' => 1, 'tc' => 1, 'tv' => 1, 'ug' => 1, 'ua' => 1, 'ae' => 1,
    'uk' => 1, 'us' => 1, 'um' => 1, 'uy' => 1, 'uz' => 1, 'vu' => 1, 've' => 1, 'vn' => 1,
    'vg' => 1, 'vi' => 1, 'wf' => 1, 'eh' => 1, 'ye' => 1, 'zm' => 1, 'zw' => 1 };

my $INTERFACE_LANGUAGE = {
    'af' => 1, 'sq' => 1, 'sm'    => 1, 'ar'    => 1, 'az'    => 1, 'eu' => 1, 'be' => 1, 'bn' => 1, 'bh' => 1,
    'bs' => 1, 'bg' => 1, 'ca'    => 1, 'zh-cn' => 1, 'zh-tw' => 1, 'hr' => 1, 'cs' => 1, 'da' => 1, 'nl' => 1,
    'en' => 1, 'eo' => 1, 'et'    => 1, 'fo'    => 1, 'fi'    => 1, 'fr' => 1, 'fy' => 1, 'gl' => 1, 'ka' => 1,
    'de' => 1, 'el' => 1, 'gu'    => 1, 'iw'    => 1, 'hi'    => 1, 'hu' => 1, 'is' => 1, 'id' => 1, 'ia' => 1,
    'ga' => 1, 'it' => 1, 'ja'    => 1, 'jw'    => 1, 'kn'    => 1, 'ko' => 1, 'la' => 1, 'lv' => 1, 'lt' => 1,
    'mk' => 1, 'ms' => 1, 'ml'    => 1, 'mt'    => 1, 'mr'    => 1, 'ne' => 1, 'no' => 1, 'nn' => 1, 'oc' => 1,
    'fa' => 1, 'pl' => 1, 'pt-br' => 1, 'pt-pt' => 1, 'pa'    => 1, 'ro' => 1, 'ru' => 1, 'gd' => 1, 'sr' => 1,
    'si' => 1, 'sk' => 1, 'sl'    => 1, 'es'    => 1, 'su'    => 1, 'sw' => 1, 'sv' => 1, 'tl' => 1, 'ta' => 1,
    'te' => 1, 'th' => 1, 'ti'    => 1, 'tr'    => 1, 'uk'    => 1, 'ur' => 1, 'uz' => 1, 'vi' => 1, 'cy' => 1,
    'xh' => 1, 'zu' => 1 };

my $FILE_TYPE = {
    '.swf' => 1, '.pdf'  => 1, '.ps'   => 1, '.dwf'  => 1, '.kml'  => 1, '.kmz'  => 1, '.gpx'  => 1,
    '.hwp' => 1, '.htm'  => 1, '.html' => 1, '.xls'  => 1, '.xlsx' => 1, '.ppt'  => 1, '.pptx' => 1,
    '.doc' => 1, '.docx' => 1, '.odp'  => 1, '.ods'  => 1, '.odt'  => 1, '.rtf'  => 1, '.wri'  => 1,
    '.svg' => 1, '.tex'  => 1, '.txt'  => 1, '.text' => 1, '.bas'  => 1, '.c'    => 1, '.cc'   => 1,
    '.cpp' => 1, '.cxx'  => 1, '.h'    => 1, '.hpp'  => 1, '.cs'   => 1, '.java' => 1, '.pl'   => 1,
    '.py'  => 1, '.wml'  => 1, '.wap'  => 1, '.xml'  => 1 };

my $DOMINANT_COLOR = {
    'black'  => 1, 'blue'   => 1, 'brown'  => 1,  'gray'   => 1,  'green'  => 1,  'pink'   => 1,
    'purple' => 1, 'teal'   => 1, 'white'  => 1,  'yellow' => 1 };

my $COLOR_TYPE    = { 'color' => 1, 'gray'  => 1, 'mono'  => 1 };

my $IMAGE_SIZE    = { 'huge' => 1, 'icon' => 1, 'large' => 1, 'medium' => 1, 'small' => 1, 'xlarge' => 1, 'xxlarge'=> 1 };

my $IMAGE_TYPE    = { 'clipart' => 1, 'face' => 1, 'lineart' => 1, 'news' => 1, 'photo' => 1 };

my $RIGHTS        = { 'cc_publicdomain'  => 1, 'cc_attribute'  => 1, 'cc_sharealike'  => 1, 'cc_noncommercial' => 1, 'cc_nonderived' => 1 };

my $SEARCH_TYPE   = { 'image' => 1 };

my $SEARCH_FILTER = { 'e' => 1, 'i' => 1 };

my $SAFETY_LEVEL  = { 'off' => 1, 'medium' => 1, 'high' => 1 };


sub check_int                { return defined ($_[0]) && $_[0] =~ /^\d+$/                      };
sub check_str                { return !check_int($_[0])                                        };
sub check_language           { return exists($LANGUAGE->{lc($_[0])})                           };
sub check_country_collection { return exists($COUNTRY_COLLECTION->{lc($_[0])})                 };
sub check_file_type          { return exists($FILE_TYPE->{lc($_[0])})                          };
sub check_country_code       { return exists($COUNTRY_CODE->{lc($_[0])})                       };
sub check_interface_language { return exists($INTERFACE_LANGUAGE->{lc($_[0])})                 };
sub check_color_type         { return exists($COLOR_TYPE->{lc($_[0])})                         };
sub check_dominant_color     { return exists($DOMINANT_COLOR->{lc($_[0])})                     };
sub check_image_size         { return exists($IMAGE_SIZE->{lc($_[0])})                         };
sub check_image_type         { return exists($IMAGE_TYPE->{lc($_[0])})                         };
sub check_rights             { return exists($RIGHTS->{lc($_[0])})                             };
sub check_search_type        { return exists($SEARCH_TYPE->{lc($_[0])})                        };
sub check_search_filter      { return exists($SEARCH_FILTER->{lc($_[0])})                      };
sub check_safety_level       { return exists($SAFETY_LEVEL->{lc($_[0])})                       };
sub check_date_restrict      { return ($_[0] =~ /^[d|w|m|y]\d+$/i)                             };
sub check_start_index        { return ($_[0] =~ /^\d+$/) && ($_[0] >= 1)                       };
sub check_result_count       { return ($_[0] =~ /^\d{1,2}$/) && ($_[0] >= 1) && ($_[0] <= 10)  };

our $FIELDS = {
    'filter'           => { required => 0, type => 'd' },
    'prettyprint'      => { required => 0, type => 's' },
    'c2coff'           => { required => 0, type => 'd' },
    'callback'         => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'fields'           => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'quotaUser'        => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'userIp'           => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'cr'               => { required => 0, check => sub { check_country_collection(@_) }, type => 's' },
   #'cref'             => { required => 0, check => sub { check_str(@_)                }, type => 's' },
   #'cx'               => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'dateRestrict'     => { required => 0, check => sub { check_date_restrict(@_)      }, type => 's' },
    'exactTerms'       => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'excludeTerms'     => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'fileType'         => { required => 0, check => sub { check_file_type(@_)          }, type => 's' },
    'gl'               => { required => 0, check => sub { check_country_code(@_)       }, type => 's' },
    'googlehost'       => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'highRange'        => { required => 0, check => sub { check_int(@_)                }, type => 'd' },
    'hl'               => { required => 0, check => sub { check_interface_language(@_) }, type => 's' },
    'hq'               => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'imgColorType'     => { required => 0, check => sub { check_color_type(@_)         }, type => 's' },
    'imgDominantColor' => { required => 0, check => sub { check_dominant_color(@_)     }, type => 's' },
    'imgSize'          => { required => 0, check => sub { check_image_size(@_)         }, type => 's' },
    'imgType'          => { required => 0, check => sub { check_image_type(@_)         }, type => 's' },
    'linkSite'         => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'lowRange'         => { required => 0, check => sub { check_int(@_)                }, type => 'd' },
    'lr'               => { required => 0, check => sub { check_language(@_)           }, type => 's' },
    'num'              => { required => 0, check => sub { check_result_count(@_)       }, type => 'd' },
    'orTerms'          => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'relatedSite'      => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'rights'           => { required => 0, check => sub { check_rights(@_)             }, type => 's' },
    'safe'             => { required => 0, check => sub { check_safety_level(@_)       }, type => 's' },
    'searchType'       => { required => 0, check => sub { check_search_type(@_)        }, type => 's' },
    'siteSearch'       => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'siteSearchFilter' => { required => 0, check => sub { check_search_filter(@_)      }, type => 's' },
    'sort'             => { required => 0, check => sub { check_str(@_)                }, type => 's' },
    'start'            => { required => 0, check => sub { check_start_index(@_)        }, type => 'd' },
};

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/WWW-Google-CustomSearch>

=head1 CONTRIBUTORS

David Kitcher-Jones (m4ddav3)

=head1 BUGS

Please  report  any  bugs or feature requests to C<bug-www-google-customsearch at
rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Google-CustomSearch>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Google::CustomSearch::Params

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Google-CustomSearch>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Google-CustomSearch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Google-CustomSearch>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Google-CustomSearch/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of WWW::Google::CustomSearch::Params
