# $Id: Sources.pm,v 1.6 2004/01/06 06:57:09 cvspub Exp $
package WWW::FindConcept::Sources;

use strict;

our %source;


@{$source{google_glossary}} = 
    (
     'http://labs.google.com/glossary?q={%query%}&btnG=Google+Glossary+Search',
     ,
     qr'<font size=-1><a href=http:\/\/labs.google.com/glossary\?q=.+?>(.+?)</a>.+?<br>'

    );


@{$source{altavista}} = 
    (
     'http://altavista.com/web/results?q={%query%}&kgs=0&kls=1&avkw=aapt',
     ,
     qr'<A title=".+?" href="\/r\?r=.+?">(.+?)<\/A>.+?<BR>'

    );


@{$source{lycos}} = 
    (
     'http://search.lycos.com/default.asp?lpv=1&loc=searchhp&query={%query%}'
     ,
     qr!<nobr><a href="default.asp\?query=.+?>(.+?)<\/a><\/nobr>!

    );


@{$source{search}} = 
    (
     'http://www.search.com/search?q={%query%}',
     ,
     qr!<a href="\/search\/.+?"><b>(.+?)</b></a>!

    );

@{$source{ask}} = 
    (
     'http://web.ask.com/web?q={%query%}&qsrc=1&o=0',
     ,
     qr!<td><a href="http:\/\/tm.wc.ask.com/r.+?".+?class="rollover">(.+?)</a>!
    );

@{$source{scirus}} = 
    (
     'http://www.scirus.com/srsapp/search?q={%query%}&ds=jnl&ds=web&g=s&t=all'
     ,
     qr'<font class="smallfont">(.+?)<\/font><\/a>'

    );

@{$source{genieknows}} = 
    (
     'http://feed.genieknows.com/search/search_html.jsp?q={%query%}&client_id=ASE_6605&Submit=Search+Again'
     ,
     qr'client_id=ASE_6605">(.+?)<\/a><\/font>'

    );





1;
__END__
