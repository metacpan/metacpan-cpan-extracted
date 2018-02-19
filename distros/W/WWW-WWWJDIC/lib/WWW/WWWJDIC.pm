package WWW::WWWJDIC;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/get_mirrors/;
use warnings;
use strict;
our $VERSION = '0.005';
use Encode qw/encode decode/;
use utf8;
use URI::Escape;
use JSON::Parse 'json_file_to_perl';

my $jfile = __FILE__;
$jfile =~ s/\.pm/.json/;
my $j = json_file_to_perl ($jfile);

my %mirrors = %{$j->{mirrors}};

our %dictionaries = (
'AV' => 'aviation ',
'BU' => 'buddhdic',
'CA' => 'cardic',
'CC' => 'concrete',
'CO' => 'compdic',
'ED' => 'edict (the rest)',
'EP' => 'edict (priority subset)',
'ES' => 'engscidic',
'EV' => 'envgloss',
'FM' => 'finmktdic',
'FO' => 'forsdic_e',
'GE' => 'geodic ',
'KD' => 'small hiragana dictionary for glossing ',
'LG' => 'lingdic',
'LS' => 'lifscidic',
'MA' => 'manufdic',
'NA' => 'enamdict',
'PL' => 'j_places (entries not already in enamdict)',
'PP' => 'pandpdic ',
'RH' => 'revhenkan (kanji/kana with no English translation yet)',
'RW' => 'riverwater',
'SP' => 'special words &amp; phrases',
'ST' => 'stardict',
);

our %codes = (
'Buddh' => 'Buddhism',
'MA' => 'martial arts',
'P' => '"Priority" entry, i.e. among approx. 20,000 words deemed to be common in Japanese',
'X' => 'rude or X-rated term (not displayed in educational software)',
'abbr' => 'abbreviation',
'adj-f' => 'noun, verb, etc. acting prenominally (incl. rentaikei)',
'adj-i' => 'adjective (keiyoushi)',
'adj-na' => 'adjectival nouns or quasi-adjectives (keiyoudoushi)',
'adj-no' => 'nouns which may take the genitive case particle "no"',
'adj-pn' => 'pre-noun adjectival (rentaishi)',
'adj-t' => '"taru" adjective',
'adv' => 'adverb (fukushi)',
'arch' => 'archaism',
'ateji' => 'kanji used as phonetic symbol(s)',
'aux' => 'auxiliary',
'aux-v' => 'auxiliary verb',
'c' => 'company name',
'col' => 'colloquialism',
'comp' => 'computing/telecommunications',
'conj' => 'conjunction',
'ctr' => 'counter',
'exp' => 'Expressions (phrases, clauses, etc.)',
'f' => 'female given name',
'fam' => 'familiar language',
'fem' => 'female term or language',
'food' => 'food',
'g' => 'given name, as-yet not classified by sex',
'geom' => 'geometry',
'gikun' => 'gikun (meaning) reading',
'h' => 'a full (family plus given) name of a historical person',
'hon' => 'honorific or respectful (sonkeigo) language',
'hum' => 'humble (kenjougo) language',
'iK' => 'word containing irregular kanji usage',
'id' => 'idiomatic expression',
'ik' => 'word containing irregular kana usage',
'int' => 'interjection (kandoushi)',
'io' => 'irregular okurigana usage',
'ling' => 'linguistics',
'm' => 'male given name',
'm-sl' => 'manga slang',
'male' => 'male term or language',
'math' => 'mathematics',
'mil' => 'military',
'n' => 'noun (common) (futsuumeishi)',
'n-adv' => 'adverbial noun (fukushitekimeishi)',
'n-t' => 'noun (temporal) (jisoumeishi)',
'o' => 'organization name',
'oK' => 'word containing out-dated kanji',
'obs' => 'obsolete term',
'obsc' => 'obscure term',
'ok' => 'out-dated or obsolete kana usage',
'on-mim' => 'onomatopoeic or mimetic word',
'p' => 'place-name',
'physics' => 'physics',
'pn' => 'pronoun',
'pol' => 'polite (teineigo) language',
'pr' => 'product name',
'pref' => 'prefix',
'prt' => 'particle',
's' => 'surname',
'sens' => 'term with some sensitivity about its usage',
'sl' => 'slang',
'st' => 'station name',
'suf' => 'suffix',
'u' => 'person name, as-yet unclassified',
'uK' => 'word usually written using kanji alone',
'uk' => 'word usually written using kana alone',
'v1' => 'Ichidan verb',
'v5' => 'Godan verb (not completely classified)',
'v5aru' => 'Godan verb - -aru special class',
'v5k-s' => 'Godan verb - Iku/Yuku special class',
'v5u, v5k, etc.' => 'Godan verb with `u\', `ku\', etc. endings',
'vi' => 'intransitive verb',
'vk' => 'Kuru verb - special class',
'vs' => 'noun or participle which takes the aux. verb suru',
'vs-s' => 'suru verb - special class',
'vt' => 'transitive verb',
'vulg' => 'vulgar expression or word',
'vz' => 'Ichidan verb - -zuru special class (alternative form of -jiru verbs)',
);

sub get_mirrors
{
    return %mirrors;
}

# Default mirror

our $default = 'usa';

sub new
{
    my ($class, %options) = @_;
    my $wwwjdic = {};
    if ($options{mirror}) {
	my $mirror = lc $options{mirror};
	if ($mirrors{$mirror}) {
	    $wwwjdic->{site} = $mirrors{$mirror};
	}
	else {
	    print STDERR __PACKAGE__,
		": unknown mirror '$options{mirror}': using $default\n";
	}
    }
    else {
	$wwwjdic->{site} = $mirrors{$default};
    }
    bless $wwwjdic;
    return $wwwjdic;
}

sub lookup_url
{
    my ($wwwjdic, $search_key, $search_type) = @_;
    my %type;
    for (@$search_type) {
	$type{max} = $_ if /^[0-9]+$/;
    }
    my $url = $wwwjdic->{site}; # Start off with the site.
    # Q = all the dictionaries.
    # M = backdoor entry.
    # search type = U: UTF-8 lookup
    $url .= "?QMUJ";
    my $search_key_encoded = URI::Escape::uri_escape_utf8 ($search_key);
    $url .= $search_key_encoded;
    # This means UTF-8 encoding. I don't think this is documented
    # anywhere.
    $url .= "_3";
    # Maximum number of results to return.
    $url .= '_' . $type{max} if $type{max};
    return $url;
}

1;

