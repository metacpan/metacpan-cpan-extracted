#!/usr/bin/env perl -w   # -*- cperl; cperl-indent-level: 4 -*-
## no critic qw(ProhibitCallsToUnexportedSubs RestrictLongStrings ProhibitImplicitNewlines RequireASCII)
use strict;
use warnings;

use utf8;
use 5.014000;

our $VERSION = '0.101';

use CGI qw/:all/;
use Getopt::Long;
use HTTP::Server::Brick;
use HTTP::Status qw(:constants status_message);
use Pod::Usage;
use Pod::Usage::CommandLine;

use Readonly;
Readonly::Scalar my $EMPTY           => q{};
Readonly::Scalar my $SPACE           => q{ };
Readonly::Scalar my $SLASH           => q{/};
Readonly::Scalar my $FALLBACK_OUTPUT => q{PHP};
Readonly::Scalar my $CONNECTOR_PORT  => 18_081;
Readonly::Scalar my $MAX_REQUESTS    => 100;
Readonly::Scalar my $API_KEY         => q{TEST};
Readonly::Scalar my $API_VERSION     => q{v1};
Readonly::Scalar my $CHARSET         => q{; charset=utf-8};
Readonly::Scalar my $ROOT            => qq{/$API_VERSION/};
Readonly::Scalar my $STRIP_QUERY     => qr{^/[?]}sxm;

Readonly::Array my @GETOPT_CONFIG =>
  qw(no_ignore_case bundling auto_version auto_help);
Readonly::Array my @GETOPTIONS => ( q{port|p=s}, q{verbose|v+}, );
Readonly::Hash my %OPTS_DEFAULT => ( 'port' => $CONNECTOR_PORT, );
Readonly::Hash my %OUTPUT => (
    'json' => q{application/json},
    'xml'  => q{text/xml},
    'php'  => q{text/plain},
);
Readonly::Hash my %RESPONSE => (
    'version' => {
        'json' => q{{
    "version": [
        {
            "version": "v1",
            "build": "0.0.1"
        }
    ]   
        }},
        'xml' => q{<?xml version="1.0" encoding="UTF-8"?>
<list type="version" itemcount="1">
    <item>
        <version><![CDATA[v1]]></version>
        <build><![CDATA[0.0.1]]></build>
    </item>
</list>},
        'php' =>
q{a:1:{s:7:"version";a:1:{i:0;a:2:{s:7:"version";s:2:"v1";s:5:"build";s:5:"0.0.1";}}}},
    },
    'latest_article' => {
        'json' => q{{
"latest_article": [
    [
        {
            "id": "156833"
            "type": "article",
            "title": "Zeker honderd doden bij vliegramp in Tripoli"
            "description": "Bij een vliegtuigongeluk op de luchthaven van de Libische hoofdstad Tripoli zouden 103 doden zijn gevallen."
            "published": "2010-05-12 10:26:00"
            "last_update": "2010-05-12 09:11:04"
            "thumbnail_xs": http://content.nos.nl/data/image/xs/2010/07/30/175416.jpg
            "thumbnail_s": http://content.nos.nl/data/image/s/2010/07/30/175416.jpg
            "thumbnail_m": http://content.nos.nl/data/image/m/2010/07/30/175416.jpg
            "link": http://nos.nl/artikel/156833-zeker-honderd-doden-bij-vliegramp-in-tripoli.html
            "keywords": [
                "libië"
                "doden"
                "tripoli"
                "vliegtuig"
                "crash"
                "Seizoen 2009/2010"
            ]
        },
        {
            "id": "156845"
            "type": "article",
            "title": "Groei Nederlandse economie neemt af"
            "description": "De Nederlandse economie is in het eerste kwartaal van het jaar gegroeid, maar de groei is lager dan in de twee voorgaande kwartalen."
            "published": "2010-05-12 10:06:02"
            "last_update": "2010-05-12 10:11:04"
            "thumbnail_xs": http://content.nos.nl/data/image/xs/2010/07/30/175416.jpg
            "thumbnail_s": http://content.nos.nl/data/image/s/2010/07/30/175416.jpg
            "thumbnail_m": http://content.nos.nl/data/image/m/2010/07/30/175416.jpg
            "link": http://nos.nl/artikel/156845-groei-nederlandse-economie-neemt-af.html
            "keywords": [
                "economie"
                "cbs"
                "kwartaalcijfers"
                "groei"
            ]
        }
    ]
]}},
        'xml' => q{<?xml version="1.0" encoding="UTF-8"?>
<list  type="article" itemcount="10">
    <article>
        <id>175418</id>
        <type>article</type>
        <title><![CDATA[Geen schot in Belgische formatie]]></title>
        <description><![CDATA[In België is er anderhalve maand na de verkiezingen nog geen zicht op de vorming van een kabinet.]]></description>
        <published><![CDATA[2010-07-30 20:29:04]]></published>
        <last_update><![CDATA[2010-07-30 20:35:06]]></last_update>
        <thumbnail_xs><![CDATA[http://content.nos.nl/data/image/xs/2010/05/25/159715.jpg]]></thumbnail_xs>
        <thumbnail_s><![CDATA[http://content.nos.nl/data/image/s/2010/05/25/159715.jpg]]></thumbnail_s>
        <thumbnail_m><![CDATA[http://content.nos.nl/data/image/m/2010/05/25/159715.jpg]]></thumbnail_m>
        <link><![CDATA[http://nos.nl/artikel/175418-geen-schot-in-belgische-formatie.html]]></link>
        <keywords>
            <keyword><![CDATA[belgië]]></keyword>
            <keyword><![CDATA[Vlaanderen]]></keyword>
            <keyword><![CDATA[Elio di Rupo]]></keyword>
            <keyword><![CDATA[kabinetsformatie]]></keyword>
        </keywords>
    </article>
</list>},
    },
    'latest_video' => {
        'json' => q{{
    "latest_video": [
        [
            {
                "id": "175327"
                "type": "video",
                "title": "28 doden door bosbranden Rusland"
                "description": "In Rusland zijn bij bosbranden zeker 28 doden gevallen. Veel huizen zijn in vlammen opgegaan, en duizenden mensen zijn geëvacueerd. Rusland heeft te kampen met de heetste zomer in ruim honderd jaar. Door de extreme droogte is de natuur extra kwetsbaar voor bosbranden."
                "published": "2010-07-30 22:25:06"
                "last_update": "2010-07-30 15:43:07"
                "thumbnail_xs": http://content.nos.nl/data/video/xs/2010/07/30/300710_18_zui-CNO1007300Z_1.jpg
                "thumbnail_s": http://content.nos.nl/data/video/s/2010/07/30/300710_18_zui-CNO1007300Z_1.jpg
                "thumbnail_m": http://content.nos.nl/data/video/m/2010/07/30/300710_18_zui-CNO1007300Z_1.jpg
                "link": http://nos.nl/video/175327-28-doden-door-bosbranden-rusland.html
                "embedcode": "<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>"
                "keywords": [
                    "bosbranden"
                    "droogte"
                    "hitte"
                    "Rusland"
                ]
            },
            {
                "id": "175424"
                "type": "video",
                "title": "Duisburg verwacht tienduizenden bezoekers rouwdienst"
                "description": "Duisburg maakt zich op voor een dag van rouw. Morgen wordt het drama met de Love Parade van vorige week herdacht. Daarbij vielen 21 doden. Om elf uur begint de rouwdienst, waarbij bondskanselier Angela Merkel aanwezig is en naar verwachting tienduizenden rouwenden, misschien zelfs wel 100.000. Sommige inwoners van Duisburg zien dat met angst tegemoet."
                "published": "2010-07-30 20:55:06"
                "last_update": "2010-07-30 21:05:08"
                "thumbnail_xs": http://content.nos.nl/data/video/xs/2010/07/30/300710_18_zui-CNO1007300Z_1.jpg
                "thumbnail_s": http://content.nos.nl/data/video/s/2010/07/30/300710_18_zui-CNO1007300Z_1.jpg
                "thumbnail_m": http://content.nos.nl/data/video/m/2010/07/30/300710_18_zui-CNO1007300Z_1.jpg
                "link": http://nos.nl/video/175424-duisburg-verwacht-tienduizenden-bezoekers-rouwdienst.html
                "embedcode": "<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>"          
                "keywords": [
                    "herdenking"
                    "Duisburg"
                    "Duitsland"
                    "rouwdienst"
                    "Love Parade"
            ]
        }
    ]
   ]
}},
        'xml' => q{<?xml version="1.0" encoding="UTF-8"?>
<list type="latest_video" itemcount="2">
    <video>
        <id>175327</id>
        <type>video</type>
        <title><![CDATA[28 doden door bosbranden Rusland]]></title>
        <description><![CDATA[In Rusland zijn bij bosbranden zeker 28 doden gevallen. Veel huizen zijn in vlammen opgegaan, en duizenden mensen zijn geëvacueerd. Rusland heeft te kampen met de heetste zomer in ruim honderd jaar. Door de extreme droogte is de natuur extra kwetsbaar voor bosbranden.]]></description>
        <published><![CDATA[2010-07-30 22:25:06]]></published>
        <last_update><![CDATA[2010-07-30 15:43:07]]></last_update>
        <thumbnail_xs><![CDATA[http://content.nos.nl/data/video/xs/2010/07/30/300710_15_ru2-CNO1007300Z_1.jpg]]></thumbnail_xs>
        <thumbnail_s><![CDATA[http://content.nos.nl/data/video/s/2010/07/30/300710_15_ru2-CNO1007300Z_1.jpg]]></thumbnail_s>
        <thumbnail_m><![CDATA[http://content.nos.nl/data/video/m/2010/07/30/300710_15_ru2-CNO1007300Z_1.jpg]]></thumbnail_m>
        <link><![CDATA[http://nos.nl/video/175327-28-doden-door-bosbranden-rusland.html]]></link>
        <embedcode><![CDATA[<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>]]></embedcode>        
        <keywords>
            <keyword><![CDATA[bosbranden]]></keyword>
            <keyword><![CDATA[droogte]]></keyword>
            <keyword><![CDATA[hitte]]></keyword>
            <keyword><![CDATA[Rusland]]></keyword>
        </keywords>
    </video>
    <video>
        <id>175424</id>
        <type>video</type>
        <title><![CDATA[Duisburg verwacht tienduizenden bezoekers rouwdienst]]></title>
        <description><![CDATA[Duisburg maakt zich op voor een dag van rouw. Morgen wordt het drama met de Love Parade van vorige week herdacht. Daarbij vielen 21 doden. Om  elf uur begint de rouwdienst, waarbij bondskanselier Angela Merkel aanwezig is en naar verwachting tienduizenden rouwenden, misschien zelfs wel 100.000. Sommige inwoners van Duisburg zien dat met angst tegemoet.]]></description>
        <published><![CDATA[2010-07-30 20:55:06]]></published>
        <last_update><![CDATA[2010-07-30 21:05:08]]></last_update>
        <thumbnail_xs><![CDATA[http://content.nos.nl/data/video/xs/2010/07/30/300710_15_ru2-CNO1007300Z_1.jpg]]></thumbnail_xs>
        <thumbnail_s><![CDATA[http://content.nos.nl/data/video/s/2010/07/30/300710_15_ru2-CNO1007300Z_1.jpg]]></thumbnail_s>
        <thumbnail_m><![CDATA[http://content.nos.nl/data/video/m/2010/07/30/300710_15_ru2-CNO1007300Z_1.jpg]]></thumbnail_m>
        <link><![CDATA[http://nos.nl/video/175424-duisburg-verwacht-tienduizenden-bezoekers-rouwdienst.html]]></link>
        <embedcode><![CDATA[<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>]]></embedcode>        
        <keywords>
            <keyword><![CDATA[herdenking]]></keyword>
            <keyword><![CDATA[Duisburg]]></keyword>
            <keyword><![CDATA[Duitsland]]></keyword>
            <keyword><![CDATA[rouwdienst]]></keyword>
            <keyword><![CDATA[Love Parade]]></keyword>
        </keywords>
    </video>
</list>},
    },
    'latest_audio' => {
        'json' => q{{
    "latest_audio": [
        [
            {
                "id": "175384"
                "type": "audio",
                "title": "Paul Sneijder over Belgische formatie"
                "description": "Ook in Belgie laat een nieuwe regering op zich wachten.n Toch is preformateur Di Rupo vanmiddag naar de koning geweest. Correspondent Paul Sneijder in Brussel."
                "published": "2010-07-30 18:00:00"
                "last_update": "2010-07-30 18:33:02"
                "thumbnail_xs": ""
                "thumbnail_s": ""
                "thumbnail_m": ""
                "link": http://nos.nl/audio/175384-paul-sneijder-over-belgische-formatie.html
                "embedcode": "<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_audio.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>"          
                "keywords": [
                    "belgië"
                    "brussel"
                    "formatie"
                ]
            },
            {
                "id": "175383"
                "type": "audio",
                "title": "Griekse chauffeurs blijven staken"
                "description": "In Griekenland dreigt een onhoudbare situatie. De vrachtwagenchauffeurs gaan door met staken. Daardoor wordt het brandstoftekort steeds nijpender. Met alle gevolgen van dien. Correspondent Conny Keesen in Athene."
                "published": "2010-07-30 18:00:00"
                "last_update": "2010-07-30 18:33:02"
                "thumbnail_xs": ""
                "thumbnail_s": ""
                "thumbnail_m": ""
                "link": http://nos.nl/audio/175383-griekse-chauffeurs-blijven-staken.html
                "embedcode": "<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_audio.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>"          
                "keywords": [
                    "vrachtwagenchauffeurs"
                    "benzine"
                    "staking"
                    "Griekenland"
                    "Athene"
                    "brandstoftekort"
                ]
            }
        ]
    ]
        }},
        'xml' => q{<?xml version="1.0" encoding="UTF-8"?>
<list type="latest_audio" itemcount="2">
    <audio>
        <id>175384</id>
        <type><![CDATA[audio]]></type>
        <title><![CDATA[Paul Sneijder over Belgische formatie]]></title>
        <description><![CDATA[Ook in Belgie laat een nieuwe regering op zich wachten.n Toch is preformateur Di Rupo vanmiddag naar de koning geweest. Correspondent Paul Sneijder in Brussel.]]></description>
        <published><![CDATA[2010-07-30 18:00:00]]></published>
        <last_update><![CDATA[2010-07-30 18:33:02]]></last_update>
        <thumbnail_xs><![CDATA[]]></thumbnail_xs>
        <thumbnail_s><![CDATA[]]></thumbnail_s>
        <thumbnail_m><![CDATA[]]></thumbnail_m>
        <link><![CDATA[http://nos.nl/audio/175384-paul-sneijder-over-belgische-formatie.html]]></link>
        <embedcode><![CDATA[<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_audio.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>]]></embedcode>        
        <keywords>
            <keyword><![CDATA[belgië]]></keyword>
            <keyword><![CDATA[brussel]]></keyword>
            <keyword><![CDATA[formatie]]></keyword>
        </keywords>
    </audio>
    <audio>
        <id>175383</id>
        <type><![CDATA[audio]]></type>
        <title><![CDATA[Griekse chauffeurs blijven staken]]></title>
        <description><![CDATA[In Griekenland dreigt een onhoudbare situatie. De vrachtwagenchauffeurs gaan door met staken. Daardoor wordt het brandstoftekort steeds nijpender. Met alle gevolgen van dien. Correspondent Conny Keesen in Athene.]]></description>
        <published><![CDATA[2010-07-30 18:00:00]]></published>
        <last_update><![CDATA[2010-07-30 18:33:02]]></last_update>
        <thumbnail_xs><![CDATA[]]></thumbnail_xs>
        <thumbnail_s><![CDATA[]]></thumbnail_s>
        <thumbnail_m><![CDATA[]]></thumbnail_m>
        <link><![CDATA[http://nos.nl/audio/175383-griekse-chauffeurs-blijven-staken.html]]></link>
        <embedcode><![CDATA[<object width="550" height="309"><param name="movie" value="http://s.nos.nl/swf/embed/nos_partner_audio.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user"></param><param name="wmode" value="transparent"></param><param name="allowScriptAccess" value="always"></param><param name="allowfullscreen" value="true"></param><embed src="http://s.nos.nl/swf/embed/nos_partner_video.swf?tcmid=tcm-5-776295&amp;platform=open&amp;partner=user" type="application/x-shockwave-flash" wmode="transparent" width="550" height="309" allowfullscreen="true" allowScriptAccess="always"></embed></object>]]></embedcode>        
        <keywords>
            <keyword><![CDATA[vrachtwagenchauffeurs]]></keyword>
            <keyword><![CDATA[benzine]]></keyword>
            <keyword><![CDATA[staking]]></keyword>
            <keyword><![CDATA[Griekenland]]></keyword>
            <keyword><![CDATA[Athene]]></keyword>
            <keyword><![CDATA[brandstoftekort]]></keyword>
        </keywords>
    </audio>
</list>},
    },
    'search' => {
        'json' => q{{
    "search":[
        {
            "documents":[
                {
                    "id":"video-36572",
                    "score":100,
                    "type":"video",
                    "title":"Cricket: finale twenty20 op Lord's","description":"Cricket, dan. De finale van het 
                    twenty20-toernooi, in Londen. Het is de tweede editie in deze verkorte uitvoering en Pakistan 
                    is voor de tweede keer finalist. Twee jaar geleden verloor Pakistan van India, en nu is het tijd 
                    voor revanche. De tegenstander is Sri Lanka.",
                    "published":"2009-06-22 23:06:54",
                    "last_update":"2010-12-02 16:12:09",
                    "thumbnail":"http://content.nos.nl/data/video/s/2009/06/22/36572.jpg",
                    "category":"Sport",
                    "subcategory":"Algemeen",
                    "link":"http://nos.nl/video/36572-cricket-finale-twenty20-op-lords.html",
                    "keywords":[
                        "india",
                        "pakistan",
                        "Cricket"
                    ]
                }
            ],
            "keywords":[
                {
                    "tag":"Cricket",
                    "count":1
                },
                {   
                    "tag":"india",
                    "count":1
                },
                {
                    "tag":"pakistan",
                    "count":1
                }
            ]
        }
    ]
        }},
        'xml' => q{<?xml version="1.0" encoding="UTF-8"?>
<list type="search" itemcount="1">
    <documents>
        <document>
            <id>video-36572</id>
            <score>100</score>
            <type>video</type>
            <title>Cricket: finale twenty20 op Lord's</title>
            <description>
            Cricket, dan. De finale van het twenty20-toernooi, in Londen. Het is de tweede editie in deze verkorte uitvoering en Pakistan is voor de tweede keer finalist. Twee jaar geleden verloor Pakistan van India, en nu is het tijd voor revanche. De tegenstander is Sri Lanka.
            </description>
            <published>2009-06-22 23:06:54</published>
            <last_update>2010-12-02 16:12:09</last_update>
            <thumbnail>
            http://content.nos.nl/data/video/s/2009/06/22/36572.jpg
            </thumbnail>
            <category>Sport</category>
            <subcategory>Algemeen</subcategory>
            <link>
            http://nos.nl/video/36572-cricket-finale-twenty20-op-lords.html
            </link>
            <keywords>
                <keyword>india</keyword>
                <keyword>pakistan</keyword>
                <keyword>Cricket</keyword>
            </keywords>
        </document>
    </documents>
    <related>
        <related>Cricket</related>
        <related>india</related>
        <related>pakistan</related>
    </related>
</list>},
    },
    'guide_radio' => {
        'json' => q{{
    guide: [
        [
            {
                "date": "2010-10-06",
                "guide": [
                    {
                        "id": "171668744"
                        "type": "radio"
                        "channel_icon": http://open.nos.nl/img/icons/radio/ra1.png
                        "channel_code": "RA1"
                        "channel_name": "Radio 1"
                        "starttime": "2010-10-06 06:00:00"
                        "endtime": "2010-10-06 06:02:00"
                        "genre": "Nieuws/actualiteiten"
                        "title": "Nieuws"
                        "description": ""
                    },
                    {
                        "id": "171929021"
                        "type": "radio"
                        "channel_icon": http://open.nos.nl/img/icons/radio/ra2.png
                        "channel_code": "RA2"
                        "channel_name": "Radio 2"
                        "starttime": "2010-10-06 06:00:00"
                        "endtime": "2010-10-06 06:05:00"
                        "genre": "Overige"
                        "title": "Nieuws"
                        "description": ""
                    },
                ]
            },
            {
                "date": "2010-10-07"
                "guide": [
                    {
                        "id": "171668782"
                        "type": "radio"
                        "channel_icon": http://open.nos.nl/img/icons/radio/ra1.png
                        "channel_code": "RA1"
                        "channel_name": "Radio 1"
                        "starttime": "2010-10-07 22:04:00"
                        "endtime": "2010-10-07 23:05:00"
                        "genre": "Sport"
                        "title": "NOS-Langs de lijn"
                        "description": ""
                    },
                ]
            }
        ]
    ]
        }},
        'xml' => q{<?xml version="1.0" encoding="UTF-8"?>
<list type="guide" daycount="2" itemcount="60">
    <dayguide type="radio" date="2010-10-06">
        <item>
            <id>171668744</id>
            <type>radio</type>
            <channel_icon>http://open.nos.nl/img/icons/radio/ra1.png</channel_icon>
            <channel_code>RA1</channel_code>
            <channel_name>Radio 1</channel_name>
            <starttime>2010-10-06 06:00:00</starttime>
            <endtime>2010-10-06 06:02:00</endtime>
            <genre>Nieuws/actualiteiten</genre>
            <title>Nieuws</title>
            <description></description>
        </item>
        <item>
            <id>171929021</id>
            <type>radio</type>
            <channel_icon>http://open.nos.nl/img/icons/radio/ra2.png</channel_icon>
            <channel_code>RA2</channel_code>
            <channel_name>Radio 2</channel_name>
            <starttime>2010-10-06 06:00:00</starttime>
            <endtime>2010-10-06 06:05:00</endtime>
            <genre>Overige</genre>
            <title>Nieuws</title>
            <description></description>
        </item>
    </dayguide>
    <dayguide type="tv" date="2010-10-07">
        <item>
            <id>171929021</id>
            <type>radio</type>
            <channel_icon>http://open.nos.nl/img/icons/radio/ra2.png</channel_icon>
            <channel_code>RA2</channel_code>
            <channel_name>Radio 2</channel_name>
            <starttime>2010-10-06 06:00:00</starttime>
            <endtime>2010-10-06 06:05:00</endtime>
            <genre>Overige</genre>
            <title>Nieuws</title>
            <description></description>
        </item>
    </dayguide>
</list>
        },
    },
    'guide_tv' => {
        'json' => q{{
    "guide": [
        [
            {
                "date": "2010-10-06",
                "guide": [
                    {
                        "id": "171026258",
                        "type": "tv",
                        "channel_icon": "http://open.nos.nl/img/icons/tv/nl1.png",
                        "channel_code": "NL1",
                        "channel_name": "Nederland 1",
                        "starttime": "2010-10-06 07:00:00",
                        "endtime": "2010-10-06 07:10:00",
                        "genre": "Nieuws/actualiteiten",
                        "title": "NOS Journaal",
                        "description": "Journaal"
                    },
                    {
                        "id": "171026254",
                        "type": "tv",
                        "channel_icon": "http://open.nos.nl/img/icons/tv/nl1.png",
                        "channel_code": "NL1",
                        "channel_name": "Nederland 1",
                        "starttime": "2010-10-06 08:00:00",
                        "endtime": "2010-10-06 08:10:00",
                        "genre": "Nieuws/actualiteiten",
                        "title": "NOS Journaal",
                        "description": "Journaal"
                    },
                ]
            },
            {
                "date": "2010-10-07",
                "guide": [
                    {
                        "id": "171026258",
                        "type": "tv",
                        "channel_icon": "http://open.nos.nl/img/icons/tv/nl1.png",
                        "channel_code": "NL1",
                        "channel_name": "Nederland 1",
                        "starttime": "2010-10-07 07:00:00",
                        "endtime": "2010-10-07 07:10:00",
                        "genre": "Nieuws/actualiteiten",
                        "title": "NOS Journaal",
                        "description": "Journaal"
                    },
                    {
                        "id": "171026254",
                        "type": "tv",
                        "channel_icon": "http://open.nos.nl/img/icons/tv/nl1.png",
                        "channel_code": "NL1",
                        "channel_name": "Nederland 1",
                        "starttime": "2010-10-07 08:00:00",
                        "endtime": "2010-10-07 08:10:00",
                        "genre": "Nieuws/actualiteiten",
                        "title": "NOS Journaal",
                        "description": "Journaal",
                    },
                ]
            }
        ]
    ]
        }},
        'xml' => q{<?xml version="1.0" encoding="UTF-8"?>
<list type="guide" daycount="2" itemcount="60">
<dayguide type="tv" date="2010-10-06">
<item>
<id>171026258</id>
<type><![CDATA[tv]]></type>
<channel_icon><![CDATA[http://open.nos.nl/img/icons/tv/nl1.png]]></channel_icon>
<channel_code><![CDATA[NL1]]></channel_code>
<channel_name><![CDATA[Nederland 1]]></channel_name>
<starttime><![CDATA[2010-10-06 07:00:00]]></starttime>
<endtime><![CDATA[2010-10-06 07:10:00]]></endtime>
<genre><![CDATA[Nieuws/actualiteiten]]></genre>
<title><![CDATA[NOS Journaal]]></title>
<description><![CDATA[Journaal]]></description>
</item>
<item>
<id>171246201</id>
<type><![CDATA[tv]]></type>
<channel_icon><![CDATA[http://open.nos.nl/img/icons/tv/nl2.png]]></channel_icon>
<channel_code><![CDATA[NL2]]></channel_code>
<channel_name><![CDATA[Nederland 2]]></channel_name>
<starttime><![CDATA[2010-10-06 07:00:00]]></starttime>
<endtime><![CDATA[2010-10-06 07:10:00]]></endtime>
<genre><![CDATA[Nieuws/actualiteiten]]></genre>
<title><![CDATA[NOS Journaal met gebarentolk]]></title>
<description><![CDATA[NOS Journaal met gebarentolk]]></description>
</item>
</dayguide>
<dayguide type="tv" date="2010-10-07">
<item>
<id>171026214</id>
<type><![CDATA[tv]]></type>
<channel_icon><![CDATA[http://open.nos.nl/img/icons/tv/nl1.png]]></channel_icon>
<channel_code><![CDATA[NL1]]></channel_code>
<channel_name><![CDATA[Nederland 1]]></channel_name>
<starttime><![CDATA[2010-10-07 00:00:00]]></starttime>
<endtime><![CDATA[2010-10-07 00:20:00]]></endtime>
<genre><![CDATA[Nieuws/actualiteiten]]></genre>
<title><![CDATA[NOS Journaal]]></title>
<description><![CDATA[NOS Journaal Laat]]></description>
</item>
<item>
<id>171026209</id>
<type><![CDATA[tv]]></type>
<channel_icon><![CDATA[http://open.nos.nl/img/icons/tv/nl1.png]]></channel_icon>
<channel_code><![CDATA[NL1]]></channel_code>
<channel_name><![CDATA[Nederland 1]]></channel_name>
<starttime><![CDATA[2010-10-07 02:20:00]]></starttime>
<endtime><![CDATA[2010-10-07 06:25:00]]></endtime>
<genre><![CDATA[Informatief]]></genre>
<title><![CDATA[NOS Tekst tv]]></title>
<description><![CDATA[Informatie uit Teletekst.]]></description>
</item>
</dayguide>
</list>
        },
    },
);
Readonly::Hash my %ERROR => (
    'bad_request_missing' =>
      q{{"badrequest":{"error":{"code":101,"message":"API-key not found"}}}},
    'bad_request_invalid' =>
q{{"wrong param value":{"error":{"code":"111","message":"Param output must be of value (php,xml,json)"}}}},
    'unauthorized' =>
q{{"unauthorized, invalid key":{"error":{"code":201,"message":"Invalid key"}}}},
    'forbidden' =>
q{{"forbidden, rate limit":{"error":{"code":301,"message":"Rate limit, max requests per minute is set at 60"}}}},
);

Getopt::Long::Configure(@GETOPT_CONFIG);
my %opts = %OPTS_DEFAULT;
Getopt::Long::GetOptions( \%opts, @GETOPTIONS ) or Pod::Usage::pod2usage(2);

my $server = HTTP::Server::Brick->new( 'port' => $opts{'port'} );

my $requests = 0;

$server->mount(
    $ROOT => {
        'handler'  => \&main,
        'wildcard' => 1,
    },
);

sub main {
    my ( $req, $res ) = @_;
    my $uri = $req->uri;
    $uri =~ s{$STRIP_QUERY}{}smx;
    my $q = CGI->new($uri);
    my %param = split $SLASH, $uri;
    if ( !defined $OUTPUT{ lc $param{'output'} } ) {
        $res->add_content_utf8( $ERROR{'bad_request_invalid'} );
        $param{'output'} = $FALLBACK_OUTPUT;
        $res->header( 'Content-Type',
            $OUTPUT{ lc $param{'output'} } . $CHARSET );
        $res->header(
            'Status',
            HTTP::Status::HTTP_BAD_REQUEST
              . $SPACE
              . status_message(HTTP::Status::HTTP_BAD_REQUEST),
        );
        $res->code(HTTP::Status::HTTP_BAD_REQUEST);
    }
    $res->header( 'Content-Type', $OUTPUT{ lc $param{'output'} } . $CHARSET );
    if ( !defined $param{'key'} ) {
        $res->add_content_utf8( $ERROR{'bad_request_missing'} );
        $res->header(
            'Status',
            HTTP::Status::HTTP_BAD_REQUEST
              . $SPACE
              . status_message(HTTP::Status::HTTP_BAD_REQUEST),
        );
        $res->code(HTTP::Status::HTTP_BAD_REQUEST);
    }
    if ( $param{'key'} ne $API_KEY ) {
        $res->header(
            'Status',
            HTTP::Status::HTTP_UNAUTHORIZED
              . $SPACE
              . status_message(HTTP::Status::HTTP_UNAUTHORIZED),
        );

        ## no critic qw(ProhibitFlagComments)
  # TODO: This also sets the content, which we don't want:
  # (this is a TODO in HTTP::Server::Brick, so fixing it there is the way to go)
        ## use critic
        $res->code(HTTP::Status::HTTP_UNAUTHORIZED);
        $res->add_content_utf8( $ERROR{'unauthorized'} );
    }
    $requests++;

    # dummy rate limit tester:
    if ( $requests > $MAX_REQUESTS ) {
        $res->add_content_utf8( $ERROR{'forbidden'} );
        $res->header(
            'Status',
            HTTP::Status::HTTP_FORBIDDEN
              . $SPACE
              . status_message(HTTP::Status::HTTP_FORBIDDEN),
        );
        $requests = 0;
        $res->code(HTTP::Status::HTTP_FORBIDDEN);
    }
    if ( defined $param{'index'} && q{version} eq $param{'index'} ) {
        $res->add_content_utf8( $RESPONSE{'version'}->{ lc $param{'output'} } );
    }
    if ( defined $param{'latest'} ) {
        $res->add_content_utf8(
            $RESPONSE{ q{latest_} . $param{'latest'} }->{ lc $param{'output'} },
        );
    }
    if ( defined $param{'search'} && q{query} eq $param{'search'} ) {
        $res->add_content_utf8( $RESPONSE{'search'}->{ lc $param{'output'} } );
    }
    if ( defined $param{'guide'} ) {
        $res->add_content_utf8(
            $RESPONSE{ q{guide_} . $param{'guide'} }->{ lc $param{'output'} } );
    }

    return 1;
}

$server->start;

__END__

=encoding utf8

=for stopwords DummyServer.pl manpage Readonly Ipenburg MERCHANTABILITY

=head1 NAME

DummyServer.pl - a dummy NOS Open server to test the API against

=head1 USAGE

B<./DummyServer.pl> [B<--port=PORT>]

=head1 DESCRIPTION

For debugging against a server that isn't the NOS Open live server, this script
provides the same API against limited content.

=head1 REQUIRED ARGUMENTS

None.

=head1 OPTIONS

=over 4

=item B< -?, -h, --help>

Show help

=item B< -m, --man>

Show manpage

=item B< -v, --verbose>

Be more verbose

=item B<--version>

Show version and license

=item B<--port>

Port number to listen on, defaults to port 18081

=back

=head1 DIAGNOSTICS

=head1 EXIT STATUS

=head1 CONFIGURATION

=head1 DEPENDENCIES

Perl 5.14.0, CGI, Getopt::Long, HTTP::Server::Brick, Pod::Usage,
Pod::Usage::CommandLine, Readonly, WWW::NOS::Open

=head1 INCOMPATIBILITIES

Version 2 of the API is not provided.

=head1 BUGS AND LIMITATIONS

Only version 1 of the API is provided.

Please report any bugs or feature requests at
L<RT for rt.cpan.org|https://rt.cpan.org/Dist/Display.html?Queue=WWW-NOS-Open>.

=head1 CONFIGURATION AND ENVIRONMENT

Using the defaults it starts the HTTP service on port 18081.

=head1 AUTHOR

Roland van Ipenburg, E<lt>ipenburg@xs4all.nlE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 by Roland van Ipenburg

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
