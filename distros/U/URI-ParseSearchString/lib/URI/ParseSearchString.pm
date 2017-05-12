package URI::ParseSearchString;

require Exporter;
@ISA = (Exporter);
@EXPORT = ( qw (parse_search_string findEngine se_host se_name se_term) );

use warnings;
use strict;
use URI;
use Data::Dumper;

=encoding utf8

=head1 NAME

URI::ParseSearchString - parse search engine referrer URLs and extract keywords used

=head1 VERSION

Version 3.51  (Diablo 3 edition)

=cut

our $VERSION = '3.51';

=head1 SYNOPSIS

  use URI::ParseSearchString ;

  my $uparse = new URI::ParseSearchString();
  my $ref    = 'http://www.google.com/search?hl=en&q=a+simple+test&btnG=Google+Search';
    
  my $query_terms = $uparse->se_term( $ref );
  my $canonical   = $uparse->se_name( $ref );
  my $hostname    = $uparse->se_host( $ref );

=head1 FUNCTIONS

=head2 new
  
  Creates a new instance object of the module.
  
  my $uparse = new URI::ParseSearchString() ;

=cut

my $RH_LOOKUPS = {
    
    'answers.yahoo.com'     => { name => 'Yahoo Answers', q=>'p' },
    
   'sapo.pt'                => { name => 'Pesquisa SAPO', q => 'q'},
   'iol.pt'                 => { name => 'Pesquisa Iol',  q => 'q'},
   'pesquisa.clix.pt'       => { name => 'Pesquisa Clix', q => 'question'},
   'aeiou.pt'               => { name => 'Aeiou',         q => 'q'},
   'cuil.pt'                => { name => 'Cuil PT',       q => 'q' },

	
   'fotos.sapo.pt'          => { name => 'SAPO fotos',    q => 'word'},
   'videos.sapo.pt'         => { name => 'SAPO videos',   q => 'word'},
   'sabores.sapo.pt'        => { name => 'SAPO sabores',  q => 'cxSearch'},
   'jn.sapo.pt'             => { name => 'Jornal Noticias', q => 'Pesquisa'},
   'dn.sapo.pt'             => { name => 'Diario Noticias', q => 'Pesquisa'},
	
	
   'rtp.pt'                 => { name => 'Rtp',           q => 'search'},
   'record.pt'              => { name => 'Jornal Record', q => 'q'},
   'correiodamanha.pt'      => { name => 'Correio da Manha',        q => 'pesquisa'},
   'correiomanha.pt'        => { name => 'Correio Manha',        q => 'pesquisa'},
   'publico.clix.pt'        => { name => 'Publico',       q => 'q'},
   'xl.pt'                  => { name => 'XL',            q => 'pesquisa'},
        
   'abacho.com'             => { name => 'Abacho',        q => 'q'},
   'alice.it'               => { name => 'Alice.it',      q => 'qs' },
   'altavista.com'          => { name => 'Altavista',     q => 'q' },
   'aolsearch.aol.com'      => { name => 'AOL Search',    q => 'query' },
   'as.starware.com'        => { name => 'Starware',      q => 'qry' },
   'blogs.icerocket.com'    => { name => 'IceRocket',     q => 'q' },
   'blogsearch.google.com'  => { name => 'Google Blogsearch', q => 'q' },
   'busca.orange.es'        => { name => 'Orange ES',     q => 'buscar' },
   'buscador.lycos.es'      => { name => 'Lycos ES',      q => 'query' },
   'buscador.terra.es'      => { name => 'Terra ES',      q => 'query' },
   'buscar.ozu.es'          => { name => 'Ozu ES',        q => 'q' },
   'categorico.it'          => { name => 'Categorico IT', q => 'q' },
   'cuil.com'               => { name => 'Cuil',          q => 'q' },
   'clusty.com'             => { name => 'Clusty',        q => 'query' },
   'excite.com'             => { name => 'Excite',        q => 'q' },
   'excite.it'              => { name => 'Excite IT',     q => 'q' },
   'fastweb.it'             => { name => 'Fastweb IT',    q => 'q' },
   'fastbrowsersearch.com'  => { name => 'Fastbrowsersearch', q=> 'q' },
   'godado.com'             => { name => 'Godado',        q => 'key' },
   'godado.it'              => { name => 'Godado (IT)',   q => 'key' },
   'gps.virgin.net'         => { name => 'Virgin Search', q => 'q' },
   'ilmotore.com'           => { name => 'ilMotore',      q => 'query' },
   'ithaki.net'             => { name => 'Ithaki',        q => 'query' },
   'kataweb.it'             => { name => 'Kataweb IT',    q => 'q' },
   'libero.it'              => { name => 'Libero IT',     q => 'query' },
   'lycos.it'               => { name => 'Lycos IT',      q => 'query' },
   'search.aol.co.uk'       => { name => 'AOL UK',        q => 'query' },
   'search.arabia.msn.com'  => { name => 'MSN Arabia',    q => 'q' },
   'search.bbc.co.uk'       => { name => 'BBC Search',    q => 'q' },
   'search.conduit.com'     => { name => 'Conduit',       q => 'q' },
   'search.icq.com'         => { name => 'ICQ dot com',   q => 'q' },
   'search.live.com'        => { name => 'Live.com',      q => 'q' },
   'search.lycos.co.uk'     => { name => 'Lycos UK',      q => 'query' },
   'search.lycos.com'       => { name => 'Lycos',         q => 'query' },
   'search.msn.co.uk'       => { name => 'MSN UK',        q => 'q' },
   'search.msn.com'         => { name => 'MSN',           q => 'q' },
   'search.myway.com'       => { name => 'MyWay',         q => 'searchfor' },
   'search.mywebsearch.com' => { name => 'My Web Search', q => 'searchfor' },
   'search.ntlworld.com'    => { name => 'NTLWorld',      q => 'q' },
   'search.orange.co.uk'    => { name => 'Orange Search', q => 'q' },
   'search.prodigy.msn.com' => { name => 'MSN Prodigy',   q => 'q' },
   'search.sweetim.com'     => { name => 'Sweetim',       q => 'q' },
   'search.virginmedia.com' => { name => 'VirginMedia',   q => 'q' },
   'search.yahoo.co.jp'     => { name => 'Yahoo Japan',   q => 'p' },
   'search.yahoo.com'       => { name => 'Yahoo!',        q => 'p' },
   'search.yahoo.jp'        => { name => 'Yahoo! Japan',  q => 'p' },
   'simpatico.ws'           => { name => 'Simpatico IT',  q => 'query' },
   'soso.com'               => { name => 'Soso',          q => 'w' },
   'suche.fireball.de'      => { name => 'Fireball DE',   q => 'query' },
   'suche.web.de'           => { name => 'Suche DE',      q => 'su' },
   'suche.t-online.de'      => { name => 'T-Online',      q => 'q' },
   'thespider.it'           => { name => 'TheSpider IT',  q => 'q' },
   'uk.altavista.com'       => { name => 'Altavista UK',  q => 'q' },
   'uk.ask.com'             => { name => 'Ask UK',        q => 'q' },
   'uk.search.yahoo.com'    => { name => 'Yahoo! UK',     q => 'p' },
   'alltheweb.com'          => { name => 'AllTheWeb',     q => 'q' },
   'ask.com'                => { name => 'Ask dot com',   q => 'q' },
   'blueyonder.co.uk'       => { name => 'Blueyonder',    q => 'q' },
   'feedster.com'           => { name => 'Feedster',      q => 'q' },
   'google.ad'              => { name => 'Google Andorra',q => 'q' },
   'google.ae'              => { name => 'Google United Arab Emirates', q => 'q' },
   'google.af'              => { name => 'Google Afghanistan',          q => 'q' },
   'google.ag'              => { name => 'Google Antiqua and Barbuda',  q => 'q' },
   'google.am'              => { name => 'Google Armenia',              q => 'q' },
   'google.as'              => { name => 'Google American Samoa',       q => 'q' },
   'google.at'              => { name => 'Google Austria',    q => 'q' },
   'google.az'              => { name => 'Google Azerbaijan', q => 'q' },
   'google.ba'              => { name => 'Google Bosnia and Herzegovina', q => 'q' },
   'google.be'              => { name => 'Google Belgium', q => 'q' },
   'google.bg'              => { name => 'Google Bulgaria',q => 'q' },
   'google.bi'              => { name => 'Google Burundi', q => 'q' },
   'google.biz'             => { name => 'Google dot biz', q => 'q' },
   'google.bo'              => { name => 'Google Bolivia', q => 'q' },
   'google.bs'              => { name => 'Google Bahamas', q => 'q' },
   'google.bz'              => { name => 'Google Belize',  q => 'q' },
   'google.ca'              => { name => 'Google Canada',  q => 'q' },
   'google.cc'              => { name => 'Google Cocos Islands',    q => 'q' },
   'google.cd'              => { name => 'Google Dem Rep of Congo', q => 'q' },
   'google.cg'              => { name => 'Google Rep of Congo',     q => 'q' },
   'google.ch'              => { name => 'Google Switzerland',      q => 'q' },
   'google.ci'              => { name => 'Google Cote dIvoire',     q => 'q' },
   'google.cl'              => { name => 'Google Chile',    q => 'q' },
   'google.cn'              => { name => 'Google China',    q => 'q' },
   'google.co.at'           => { name => 'Google Austria',  q => 'q' },
   'google.co.bi'           => { name => 'Google Burundi',  q => 'q' },
   'google.co.bw'           => { name => 'Google Botswana', q => 'q' },
   'google.co.ci'           => { name => 'Google Ivory Coast',  q => 'q' },
   'google.co.ck'           => { name => 'Google Cook Islands', q => 'q' },
   'google.co.cr'           => { name => 'Google Costa Rica',   q => 'q' },
   'google.co.gg'           => { name => 'Google Guernsey',     q => 'q' },
   'google.co.gl'           => { name => 'Google Greenland',    q => 'q' },
   'google.co.gy'           => { name => 'Google Guyana',       q => 'q' },
   'google.co.hu'           => { name => 'Google Hungary',      q => 'q' },
   'google.co.id'           => { name => 'Google Indonesia',    q => 'q' },
   'google.co.il'           => { name => 'Google Israel',       q => 'q' },
   'google.co.im'           => { name => 'Google Isle of Man',  q => 'q' },
   'google.co.in'           => { name => 'Google India',        q => 'q' },
   'google.co.it'           => { name => 'Google Italy',        q => 'q' },
   'google.co.je'           => { name => 'Google Jersey',       q => 'q' },
   'google.co.jp'           => { name => 'Google Japan',        q => 'q' },
   'google.co.ke'           => { name => 'Google Kenya',        q => 'q' },
   'google.co.kr'           => { name => 'Google South Korea',  q => 'q' },
   'google.co.ls'           => { name => 'Google Lesotho',      q => 'q' },
   'google.co.ma'           => { name => 'Google Morocco',      q => 'q' },
   'google.co.mu'           => { name => 'Google Mauritius',    q => 'q' },
   'google.co.mw'           => { name => 'Google Malawi',       q => 'q' },
   'google.co.nz'           => { name => 'Google New Zeland',   q => 'q' },
   'google.co.pn'           => { name => 'Google Pitcairn Islands',    q => 'q' },
   'google.co.th'           => { name => 'Google Thailand',            q => 'q' },
   'google.co.tt'           => { name => 'Google Trinidad and Tobago', q => 'q' },
   'google.co.ug'           => { name => 'Google Uganda',       q => 'q' },
   'google.co.uk'           => { name => 'Google UK',           q => 'q' },
   'google.co.uz'           => { name => 'Google Uzbekistan',   q => 'q' },
   'google.co.ve'           => { name => 'Google Venezuela',    q => 'q' },
   'google.co.vi'           => { name => 'Google US Virgin Islands', q => 'q' },
   'google.co.za'           => { name => 'Google  South Africa',q => 'q' },
   'google.co.zm'           => { name => 'Google Zambia',       q => 'q' },
   'google.co.zw'           => { name => 'Google Zimbabwe',     q => 'q' },
   'google.com'             => { name => 'Google',              q => 'q' },
   'google.com.af'          => { name => 'Google Afghanistan',  q => 'q' },
   'google.com.ag'          => { name => 'Google Antiqua and Barbuda', q => 'q' },
   'google.com.ai'          => { name => 'Google Anguilla',    q => 'q' },
   'google.com.ar'          => { name => 'Google Argentina',   q => 'q' },
   'google.com.au'          => { name => 'Google Australia',   q => 'q' },
   'google.com.az'          => { name => 'Google Azerbaijan',  q => 'q' },
   'google.com.bd'          => { name => 'Google Bangladesh',  q => 'q' },
   'google.com.bh'          => { name => 'Google Bahrain',     q => 'q' },
   'google.com.bi'          => { name => 'Google Burundi',     q => 'q' },
   'google.com.bn'          => { name => 'Google Brunei Darussalam', q => 'q' },
   'google.com.bo'          => { name => 'Google Bolivia',     q => 'q' },
   'google.com.br'          => { name => 'Google Brazil',      q => 'q' },
   'google.com.bs'          => { name => 'Google Bahamas',     q => 'q' },
   'google.com.bz'          => { name => 'Google Belize',      q => 'q' },
   'google.com.cn'          => { name => 'Google China',       q => 'q' },
   'google.com.co'          => { name => 'Google',             q => 'q' },
   'google.com.cu'          => { name => 'Google Cuba',        q => 'q' },
   'google.com.do'          => { name => 'Google Dominican Rep', q => 'q' },
   'google.com.ec'          => { name => 'Google Ecuador',     q => 'q' },
   'google.com.eg'          => { name => 'Google Egypt',       q => 'q' },
   'google.com.et'          => { name => 'Google Ethiopia',    q => 'q' },
   'google.com.fj'          => { name => 'Google Fiji',        q => 'q' },
   'google.com.ge'          => { name => 'Google Georgia',     q => 'q' },
   'google.com.gh'          => { name => 'Google Ghana',       q => 'q' },
   'google.com.gi'          => { name => 'Google Gibraltar',   q => 'q' },
   'google.com.gl'          => { name => 'Google Greenland',   q => 'q' },
   'google.com.gp'          => { name => 'Google Guadeloupe',  q => 'q' },
   'google.com.gr'          => { name => 'Google Greece',      q => 'q' },
   'google.com.gt'          => { name => 'Google Guatemala',   q => 'q' },
   'google.com.gy'          => { name => 'Google Guyana',      q => 'q' },
   'google.com.hk'          => { name => 'Google Hong Kong',   q => 'q' },
   'google.com.hn'          => { name => 'Google Honduras',    q => 'q' },
   'google.com.hr'          => { name => 'Google Croatia',     q => 'q' },
   'google.com.jm'          => { name => 'Google Jamaica',     q => 'q' },
   'google.com.jo'          => { name => 'Google Jordan',      q => 'q' },
   'google.com.kg'          => { name => 'Google Kyrgyzstan',  q => 'q' },
   'google.com.kh'          => { name => 'Google Cambodia',    q => 'q' },
   'google.com.ki'          => { name => 'Google Kiribati',    q => 'q' },
   'google.com.kz'          => { name => 'Google Kazakhstan',  q => 'q' },
   'google.com.lk'          => { name => 'Google Sri Lanka',   q => 'q' },
   'google.com.lv'          => { name => 'Google Latvia',      q => 'q' },
   'google.com.ly'          => { name => 'Google Libya',       q => 'q' },
   'google.com.mt'          => { name => 'Google Malta',       q => 'q' },
   'google.com.mu'          => { name => 'Google Mauritius',   q => 'q' },
   'google.com.mw'          => { name => 'Google Malawi',      q => 'q' },
   'google.com.mx'          => { name => 'Google Mexico',      q => 'q' },
   'google.com.my'          => { name => 'Google Malaysia',    q => 'q' },
   'google.com.na'          => { name => 'Google Namibia',     q => 'q' },
   'google.com.nf'          => { name => 'Google Norfolk Island', q => 'q' },
   'google.com.ng'          => { name => 'Google Nigeria',        q => 'q' },
   'google.com.ni'          => { name => 'Google Nicaragua',   q => 'q' },
   'google.com.np'          => { name => 'Google Nepal',       q => 'q' },
   'google.com.nr'          => { name => 'Google Nauru',       q => 'q' },
   'google.com.om'          => { name => 'Google Oman',        q => 'q' },
   'google.com.pa'          => { name => 'Google Panama',      q => 'q' },
   'google.com.pe'          => { name => 'Google Peru',        q => 'q' },
   'google.com.ph'          => { name => 'Google Philipines',  q => 'q' },
   'google.com.pk'          => { name => 'Google Pakistan',    q => 'q' },
   'google.com.pl'          => { name => 'Google Poland',      q => 'q' },
   'google.com.pr'          => { name => 'Google Puerto Rico', q => 'q' },
   'google.com.pt'          => { name => 'Google Portugal',    q => 'q' },
   'google.com.py'          => { name => 'Google Paraguay',    q => 'q' },
   'google.com.qa'          => { name => 'Google',             q => 'q' },
   'google.com.ru'          => { name => 'Google Russia',      q => 'q' },
   'google.com.sa'          => { name => 'Google Saudi Arabia',    q => 'q' },
   'google.com.sb'          => { name => 'Google Solomon Islands', q => 'q' },
   'google.com.sc'          => { name => 'Google Seychelles',      q => 'q' },
   'google.com.sg'          => { name => 'Google Singapore',   q => 'q' },
   'google.com.sv'          => { name => 'Google El Savador',  q => 'q' },
   'google.com.tj'          => { name => 'Google Tajikistan',  q => 'q' },
   'google.com.tr'          => { name => 'Google Turkey',      q => 'q' },
   'google.com.tt'          => { name => 'Google Trinidad and Tobago', q => 'q' },
   'google.com.tw'          => { name => 'Google Taiwan',      q => 'q' },
   'google.com.ua'          => { name => 'Google Ukraine',      q => 'q' },
   'google.com.uy'          => { name => 'Google Uruguay',     q => 'q' },
   'google.com.uz'          => { name => 'Google Uzbekistan',  q => 'q' },
   'google.com.ve'          => { name => 'Google Venezuela',   q => 'q' },
   'google.com.vi'          => { name => 'Google US Virgin Islands', q => 'q' },
   'google.com.vn'          => { name => 'Google Vietnam',     q => 'q' },
   'google.com.ws'          => { name => 'Google Samoa',       q => 'q' },
   'google.cz'              => { name => 'Google Czech Rep',   q => 'q' },
   'google.de'              => { name => 'Google Germany',     q => 'q' },
   'google.dj'              => { name => 'Google Djubouti',    q => 'q' },
   'google.dk'              => { name => 'Google Denmark',     q => 'q' },
   'google.dm'              => { name => 'Google Dominica',    q => 'q' },
   'google.ec'              => { name => 'Google Ecuador',     q => 'q' },
   'google.ee'              => { name => 'Google Estonia',     q => 'q' },
   'google.es'              => { name => 'Google Spain',       q => 'q' },
   'google.fi'              => { name => 'Google Finland',     q => 'q' },
   'google.fm'              => { name => 'Google Micronesia',  q => 'q' },
   'google.fr'              => { name => 'Google France',      q => 'q' },
   'google.gd'              => { name => 'Google Grenada',     q => 'q' },
   'google.ge'              => { name => 'Google Georgia',     q => 'q' },
   'google.gf'              => { name => 'Google French Guiana', q => 'q' },
   'google.gg'              => { name => 'Google Guernsey',      q => 'q' },
   'google.gl'              => { name => 'Google Greenland',     q => 'q' },
   'google.gm'              => { name => 'Google Gambia',        q => 'q' },
   'google.gp'              => { name => 'Google Guadeloupe',    q => 'q' },
   'google.gr'              => { name => 'Google Greece',        q => 'q' },
   'google.gy'              => { name => 'Google Guyana',        q => 'q' },
   'google.hk'              => { name => 'Google Hong Kong',     q => 'q' },
   'google.hn'              => { name => 'Google Honduras',      q => 'q' },
   'google.hr'              => { name => 'Google Croatia',       q => 'q' },
   'google.ht'              => { name => 'Google Haiti',         q => 'q' },
   'google.hu'              => { name => 'Google Hungary',       q => 'q' },
   'google.ie'              => { name => 'Google Ireland',       q => 'q' },
   'google.im'              => { name => 'Google Isle of Man',   q => 'q' },
   'google.in'              => { name => 'Google India',         q => 'q' },
   'google.info'            => { name => 'Google dot info',      q => 'q' },
   'google.is'              => { name => 'Google Iceland',       q => 'q' },
   'google.it'              => { name => 'Google Italy',         q => 'q' },
   'google.je'              => { name => 'Google Jersey',        q => 'q' },
   'google.jo'              => { name => 'Google Jordan',        q => 'q' },
   'google.jobs'            => { name => 'Google dot jobs',      q => 'q' },
   'google.jp'              => { name => 'Google Japan',         q => 'q' },
   'google.kg'              => { name => 'Google Kyrgyzstan',    q => 'q' },
   'google.ki'              => { name => 'Google Kiribati',      q => 'q' },
   'google.kz'              => { name => 'Google Kazakhstan',    q => 'q' },
   'google.la'              => { name => 'Google Laos',          q => 'q' },
   'google.li'              => { name => 'Google Liechtenstein', q => 'q' },
   'google.lk'              => { name => 'Google Sri Lanka',     q => 'q' },
   'google.lt'              => { name => 'Google Lithuania',     q => 'q' },
   'google.lu'              => { name => 'Google Luxembourg',    q => 'q' },
   'google.lv'              => { name => 'Google Latvia',        q => 'q' },
   'google.ma'              => { name => 'Google Morocco',       q => 'q' },
   'google.md'              => { name => 'Google Moldova',       q => 'q' },
   'google.mn'              => { name => 'Google Mongolia',      q => 'q' },
   'google.mobi'            => { name => 'Google dot mobi',      q => 'q' },
   'google.ms'              => { name => 'Google Montserrat',    q => 'q' },
   'google.mu'              => { name => 'Google Mauritius',     q => 'q' },
   'google.mv'              => { name => 'Google Maldives',      q => 'q' },
   'google.mw'              => { name => 'Google Malawi',        q => 'q' },
   'google.net'             => { name => 'Google dot net',       q => 'q' },
   'google.nf'              => { name => 'Google Norfolk Island', q => 'q' },
   'google.nl'              => { name => 'Google Netherlands',    q => 'q' },
   'google.no'              => { name => 'Google Norway',        q => 'q' },
   'google.nr'              => { name => 'Google Nauru',         q => 'q' },
   'google.nu'              => { name => 'Google Niue',          q => 'q' },
   'google.off.ai'          => { name => 'Google Anguilla',      q => 'q' },
   'google.ph'              => { name => 'Google Philipines',    q => 'q' },
   'google.pk'              => { name => 'Google Pakistan',      q => 'q' },
   'google.pl'              => { name => 'Google Poland',        q => 'q' },
   'google.pn'              => { name => 'Google Pitcairn Islands', q => 'q' },
   'google.pr'              => { name => 'Google Puerto Rico',   q => 'q' },
   'google.pt'              => { name => 'Google Portugal',      q => 'q' },
   'google.ro'              => { name => 'Google Romania',       q => 'q' },
   'google.ru'              => { name => 'Google Russia',        q => 'q' },
   'google.rw'              => { name => 'Google Rwanda',        q => 'q' },
   'google.sc'              => { name => 'Google Seychelles',    q => 'q' },
   'google.se'              => { name => 'Google Sweden',        q => 'q' },
   'google.sg'              => { name => 'Google Singapore',     q => 'q' },
   'google.sh'              => { name => 'Google Saint Helena',  q => 'q' },
   'google.si'              => { name => 'Google Slovenia',      q => 'q' },
   'google.sk'              => { name => 'Google Slovakia',      q => 'q' },
   'google.sm'              => { name => 'Google San Marino',    q => 'q' },
   'google.sn'              => { name => 'Google Senegal',       q => 'q' },
   'google.sr'              => { name => 'Google Suriname',      q => 'q' },
   'google.st'              => { name => 'Google Sao Tome',      q => 'q' },
   'google.tk'              => { name => 'Google Tokelau',       q => 'q' },
   'google.tm'              => { name => 'Google Turkmenistan',  q => 'q' },
   'google.to'              => { name => 'Google Tonga',        q => 'q' },
   'google.tp'              => { name => 'Google East Timor',   q => 'q' },
   'google.tt'              => { name => 'Google Trinidad and Tobago', q => 'q' },
   'google.tv'              => { name => 'Google Tuvalu', q => 'q' },
   'google.tw'              => { name => 'Google Taiwan', q => 'q' },
   'google.ug'              => { name => 'Google Uganda', q => 'q' },
   'google.us'              => { name => 'Google US',     q => 'q' },
   'google.uz'              => { name => 'Google Uzbekistan',             q => 'q' },
   'google.vg'              => { name => 'Google British Virgin Islands', q => 'q' },
   'google.vn'              => { name => 'Google Vietnam', q => 'q' },
   'google.vu'              => { name => 'Google Vanuatu', q => 'q' },
   'google.ws'              => { name => 'Google Samoa',  q => 'q' },
   'hotbot.com'             => { name => 'HotBot',        q => 'query' },
   'in.gr'                  => { name => 'In GR',         q => 'q' },
   'mamma.com'              => { name => 'Mamma',         q => 'query' },
   'mahalo.com'             => { name => 'Mahalo',        q => 'search' },
   'megasearching.net'      => { name => 'Megasearching', q => 's' },
   'mirago.co.uk'           => { name => 'Mirago UK',     q => 'qry' },
   'netscape.com'           => { name => 'Netscape',      q => 's' },
   'community.paglo.com'    => { name => 'Paglo',         q => 'q' },
   'pathfinder.gr'          => { name => 'Pathfinder GR', q => 'q' },
   'phantis.com'            => { name => 'Phantis GR' ,   q => 'q'},
   'robby.gr'               => { name => 'Robby GR'     , q => 'searchstr' },
   'sproose.com'            => { name => 'Sproose',       q => 'query' },
   'technorati.com'         => { name => 'Technorati',    q => 'q' },
   'tesco.net'              => { name => 'Tesco Search',  q => 'q' },
   'tiscali.co.uk'          => { name => 'Tiscali UK',    q => 'query' },
   'bing.com'               => { name => 'Bing',          q => 'q' },
   
   'acbusca.com'            => { name => 'ACBusca',          q => 'query' },
   'atalhocerto.com.br'     => { name => 'Atalho Certo',     q => 'keyword' },
   'bastaclicar.com.br'     => { name => 'Basta Clicar',     q => 'search' },
   'bemrapido.com.br'       => { name => 'Bem Rapido',       q => 'chave' },
   'br.altavista.com'       => { name => 'AltaVista Brasil', q => 'q' },
   'br.search.yahoo.com'    => { name => 'Yahoo Brazil',     q => 'p' },
   'busca.uol.com.br'       => { name => 'Radar UOL',        q => 'q' },
   'buscaaqui.com.br'       => { name => 'Busca Aqui',       q => 'q' },
   'buscador.terra.com.br'  => { name => 'Terra Busca',      q => 'query' },
   'cade.search.yahoo.com'  => { name => 'Cadê',             q => 'p' },
   'clickgratis.com.br'     => { name => 'Click Gratis',     q => 'query' },
   'entrada.com.br'         => { name => 'Entrada',          q => 'q' },
   'gigabusca.com.br'       => { name => 'Giga Busca',       q => 'what' },
   'internetica.com.br'     => { name => 'Internetica',      q => 'busca' },
   'katatudo.com.br'        => { name => 'KataTudo',         q => 'q' },
   'minasplanet.com.br'     => { name => 'Minas Planet',     q => 'term' },
   'speedybusca.com.br'     => { name => 'SpeedyBusca',      q => 'q' },
   'vaibuscar.com.br'       => { name => 'Vai Busca',        q => 'q' },
   
   'search.conduit.com'     => { name => 'Conduit',          q=>'q'   },
   'in.search.yahoo.com'    => { name => 'Yahoo India',      q => 'p'  },
   'rediff.com'             => { name => 'Rediff',           q => 'MT' },
   'guruji.com'             => { name => 'Guruji',           q => 'q'  },
   
   'isohunt.com'            => { name => 'Isohunt',          q => 'ihq' },
   'btjunkie.org'           => { name => 'BT Junkie',        q => 'q' },
   'torrentz.eu'            => { name => 'Torrentz',         q => 'f' }
   
};

sub new {
  my $class        = shift ;
  my $self         = { } ;
  $self->{engines} = $RH_LOOKUPS; 
  return bless $self, $class ;
}

=head2 parse_search_string

This module provides a simple function to parse and extract search engine query strings. It was designed and tested having
Apache referrer logs in mind. It can be used for a wide number of purposes, including tracking down what keywords people use
on popular search engines before they land on a site. Although a number of existing modules and scripts exist for this purpose,
the majority of them are either outdated using obsolete search strings associated with each engine.

The default function exported is "parse_search_string" which accepts an unquoted referrer string as input and returns the 
search engine query contained within. It currently works with both escaped and un-escaped queries and will translate the search
terms before returning them in the latter case. The function returns undef in all other cases and errors.

for example: 

   my $ref   = 'http://www.google.com/search?hl=en&q=a+simple+test&btnG=Google+Search';
   my $terms = 
      $uparse->parse_search_string( $ref );

would return I<'a simple test'>

whereas

   my $ref   = 'http://www.mamma.com/Mamma?utfout=1&qtype=0&query=a+more%21+complex_+search%24&Submit=%C2%A0%C2%A0Search%C2%A0%C2%A0';
   my $terms =  
      $uparse->parse_search_string( $ref );

would return I<'a more! complex_ search$'> 

=cut

=head2 se_term

Same as parse_search_string().

=cut

sub se_term {
  my $self   = shift ;
  my $string = shift ;
  return unless defined $string ;
  return $self->parse_search_string($string) ;
}

## internal method for creating a URI object

sub _uri {
   my $self   = shift;
   my $string = shift;
   
   return unless defined($string);
   
   ## create a new URI object
	## and return unless its http or https
	
	my $uri = URI->new( $string );
	return 
	   unless (defined($uri) 
	       && (ref($uri) eq 'URI::http' || ref($uri) eq 'URI::https'));
	
	## feedster and technorati as they do not follow
	## the usual search patterns thus we extract the query
	## terms by taking the last element from the path segments
	
    my $host = $uri->host;
    
    return unless defined($host) && $host;
    
   if ( $host =~ m/(feedster|technorati)\.com$/ ){
	   $uri->query_form( q => ( $uri->path_segments)[-1]);
	}

	## clean up the host until it matches
	## something we already know about
	
	 while( ! defined $self->{'engines'}{ $host }){
        my $c = index($host, '.');
        last if $c <0;
        $host= substr($host, $c+1);
    }

    return ($uri, $host);
    
}


sub parse_search_string {
   my $self   = shift ;
   my $string = shift ;
	return unless defined($string); 
	
	my ($uri,$host) = $self->_uri( $string );
	return unless defined($uri);
	
	## get rid of the www
	$host =~ m!^www\.!;
		
	## find the query parameter the engine uses
	my $q = $self->{'engines'}{$host}{'q'};
	return unless defined $q;
	
	## return the string passed to the query parameter
	my %h_query = $uri->query_form;
	
	return $h_query{$q}
}

=head2 findEngine

Returns a list with the hostname of the search engine as the first element and 
the canonical name as the second element.

  my $ref = 'http://www.google.com/search?hl=en&q=a+simple+test&btnG=Google+Search';
  my ($hostname, $canonical) = $uparse->findEngine( $ref ) ;

This will return 'google.com' as the search engine hostname and 'Google' as the name.
This function will return I<undef> on error.

=cut

sub findEngine {
  my $self    = shift ;
  my $string  = shift ;
 
  return unless defined($string);
  
  ## create a URI object
  
  my ($uri,$hostname) = $self->_uri( $string );
  return unless defined($uri) && $uri;
  return unless defined($hostname) && $hostname;
  
  my $canonical = $self->{'engines'}->{$hostname}->{'name'};
	
  return ($hostname,$canonical);
}

=head2 se_host 

Wrapper around findEngine - returns just the hostname.
This function will return I<undef> on error.

=cut

sub se_host {
  my $self   = shift ;
  my $string = shift ;
  return unless defined($string) ;
  my ($host,$name) = $self->findEngine($string) ;
  return $host ;
}

=head2 se_name

Wrapper around findEngine - returns just the canonical name;
This function will return I<undef> on error.

=cut

sub se_name {
  my $self   = shift ;
  my $string = shift ;
  return unless defined($string);
  my ($host,$name) = $self->findEngine($string) ;
  return $name ;
}

=head1 SUPPORTED ENGINES

Currently supported search engines include: Sproose, Google Namibia, Google Ivory Coast, Google Oman, Technorati, Google Ecuador, 
Google Norfolk Island, Mahalo, Google UK, Yahoo! UK, Google Micronesia, Google Bahrain, Basta Clicar, 
Giga Busca, Google Greece, Google Belgium, Google Egypt, Google Chile, Godado (IT), Google Australia, 
Google Uruguay, Google India, Google Taiwan, Google Ukraine, Google US, Terra ES, 
Tesco Search, Megasearching, SAPO videos, Google Nepal, Google Israel, Google US Virgin Islands, Google Hungary, 
Google San Marino, Google Croatia, Google dot jobs, Google Panama, Google Malaysia, Internetica, Google Brunei Darussalam,
Google Denmark, Google Pakistan, Google Solomon Islands, Google dot biz, Google Lesotho, IceRocket, Google Greenland, Fireball DE,
Rtp, Google Portugal, Google Samoa, Google Kazakhstan, Google Blogsearch, Google Thailand, Google, Google Antiqua and Barbuda, 
Google Germany, Google Moldova, Google Zambia, Google Greece, Google Sri Lanka, Google Ireland, Google Austria, 
Google Peru, Google Guatemala, ICQ dot com, AOL UK, Google Guyana, In GR, Google dot info, MyWay, Pathfinder GR, Google Costa Rica, 
KataTudo, Google Jamaica, Google Vietnam, Google Morocco, Google Gambia, Google Singapore, Google Mauritius, Altavista, Google Afghanistan, 
Google Cote dIvoire, Google Kazakhstan, Google Czech Rep, Phantis GR, Google Bahamas, Google United Arab Emirates, Google East Timor, Ozu ES,
Google Venezuela, Google Puerto Rico, Google Armenia, Google Croatia, Google Botswana, Google Tuvalu, Ask UK, Google Singapore, Mirago UK, 
Google Greenland, MSN Arabia, Google Nauru, Publico, Robby GR, Minas Planet, Pesquisa Iol, Google Romania, Google South Korea, Google Jersey,
Netscape, Busca Aqui, Google Bulgaria, Google Uzbekistan, Tiscali UK, Ithaki, Cadê, Lycos IT, Google Suriname, Excite IT, Google Hong Kong, 
Kataweb IT, Google Burundi, Click Gratis, Google Vietnam, MSN, Alice.it, Google Honduras, Google Trinidad and Tobago, Google Uganda, XL, 
Jornal Noticias, Google Cook Islands, Google Japan, Google Ecuador, Google Ghana, Google Guadeloupe, Google Libya, Google Kenya, Fastbrowsersearch, 
Aeiou, Google Niue, Jornal Record, HotBot, Google Honduras, Google Georgia, Google Fiji, Google Philipines, BBC Search, Google, Google Laos, 
Soso, AltaVista Brasil, Lycos UK, SAPO fotos, Ask dot com, Google Netherlands, Google Philipines, Google Trinidad and Tobago, Google Turkey, 
AllTheWeb, Google Japan, Google Argentina, Google Vanuatu, Blueyonder, Google Greenland, Google Samoa, Google Georgia, Google Slovakia, 
Google Sri Lanka, Pesquisa SAPO, Google Latvia, Google Latvia, Correio Manha, Terra Busca, Google El Savador, Google Cambodia, 
Google Mauritius, Google China, AOL Search, Google Tokelau, Google Tonga, Correio da Manha, Radar UOL, Google Jordan, Godado, Google Jordan, 
Google Pitcairn Islands, Categorico IT, Google Morocco, Google Dominican Rep, Google France, Abacho, Google Azerbaijan, Google Andorra, Google Belize, 
Google Paraguay, Simpatico IT, Google Ethiopia, Google Uganda, Google Poland, Google Bolivia, Google Hungary, Google Russia, Diario Noticias, 
Google Puerto Rico, Google Montserrat, Yahoo! Japan, Google Seychelles, Mamma, Google Pitcairn Islands, Google  South Africa, Paglo, Google Malta, 
Google Azerbaijan, Google New Zeland, Google China, Google Norway, Google Bosnia and Herzegovina, Google Indonesia, SpeedyBusca, Entrada, Google Anguilla, 
Google Rep of Congo, Google Dominica, Google Finland, Altavista UK, Google Guyana, MSN UK, Yahoo Answers, Google British Virgin Islands, Google Guadeloupe,
Google Lithuania, Google Antiqua and Barbuda, Google Bahamas, Google Malawi, MSN Prodigy, Bing, Google Bolivia, Google Djubouti, Google Uzbekistan, Fastweb IT, 
Google Tajikistan, Virgin Search, Google Nigeria, Yahoo Japan, Pesquisa Clix, Google Grenada, Google Haiti, Google American Samoa, Google Pakistan, 
Google Cocos Islands, Google Hong Kong, NTLWorld, ilMotore, Google Belize, Google Guernsey, Google Sweden, Google Anguilla, Google Bangladesh, Google Isle of Man, 
Google Guernsey, Google Kyrgyzstan, Google Dem Rep of Congo, Google Malawi, Orange Search, Google Seychelles, Google Guyana, Google Gibraltar, 
oogle Italy, Google Kiribati, TheSpider IT, Google Nicaragua, Google Russia, Google Venezuela, Google Poland, Google Brazil, Google Senegal, Conduit, Lycos, 
Google Isle of Man, Live.com, Google Italy, Libero IT, Google Canada, Google Nauru, Google Liechtenstein, Google Afghanistan, Cuil, Google Zimbabwe, Google Mauritius, 
Orange ES, Google Burundi, Google Portugal, ACBusca, Bem Rapido, Atalho Certo, Excite, Clusty, Yahoo Brazil, My Web Search, Google Spain, Google Uzbekistan, Google,
Google Mexico, T-Online, Google dot mobi, Google Luxembourg, Google Austria, Yahoo!, Google Kiribati, Sweetim, Vai Busca, Google Mongolia, Google Saudi Arabia, Google dot net,
Google Maldives, Google Trinidad and Tobago, Google Jersey, Feedster, Google Turkmenistan, Google Switzerland, Google Norfolk Island, Suche DE, Google Malawi, Google Rwanda, 
Lycos ES, Google Burundi, Google French Guiana, Google Kyrgyzstan, Google Saint Helena, VirginMedia, Google Iceland, SAPO sabores, Google India, Google Cuba, 
Google US Virgin Islands, Google Taiwan, Google Sao Tome, Google Slovenia, Starware, Google Estonia, Conduit, Yahoo India, Rediff, Guruji

=head1 AUTHOR

Spiros Denaxas, C<< <s.denaxas at gmail.com> >>

=head1 SOURCE CODE

The source code can be found on github L<https://github.com/spiros/URI-ParseSearchString>

=head1 BUGS

This is my first CPAN module so I encourage you to send all comments, especially bad, 
to my email address.

This could not have been possible without the support of my co-workers at 
http://nestoria.co.uk - the easiest way of finding UK property.

=head1 SUPPORT

For more information, you could also visit my blog: 

	http://blog.ffffruit.com

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2011 Spiros Denaxas, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of URI::ParseSearchString
