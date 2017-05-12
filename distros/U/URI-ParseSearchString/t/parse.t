use strict;
use warnings ;

use Test::More tests => 515;
use Test::NoWarnings;

use_ok('URI::ParseSearchString') ;

my $obj = new URI::ParseSearchString() ;
isa_ok($obj, 'URI::ParseSearchString');

my $raa_simpleTests = [
     ['http://www.google.co.uk/url?hl=en&q=a+simple+test&btnG=Google+Search&meta=&aq=f&oq=a+simple+tes',    'Google.com simple search', 'google.co.uk' ], # new style ref string
    ['http://www.google.com/search?hl=en&q=a+simple+test&btnG=Google+Search',                                  'Google.com simple search', 'google.com', ],
    ['http://www.google.co.uk/search?hl=en&q=a+simple+test&btnG=Google+Search&meta=',                          'Google.co.uk simple search', 'google.co.uk',  ],
    ['http://www.google.co.jp/search?hl=ja&q=a+simple+test&btnG=Google+%E6%A4%9C%E7%B4%A2&lr=',                'Google.jp encoding simple search', 'google.co.jp' ],
    ['http://search.msn.co.uk/results.aspx?q=a+simple+test&geovar=56&FORM=REDIR',                              'MSN.co.uk simple search', 'search.msn.co.uk'          ],
    ['http://search.msn.com/results.aspx?q=a+simple+test&geovar=56&FORM=REDIR',                                'MSN.com simple search', 'search.msn.com'          ],
    ['http://www.altavista.com/web/results?itag=ody&q=a+simple+test&kgs=1&kls=0',                              'Altavista.com simple search', 'altavista.com'      ],
    ['http://uk.altavista.com/web/results?itag=ody&q=a+simple+test&kgs=1&kls=0',                               'Altavista.co.uk simple search', 'uk.altavista.com'    ],
    ['http://www.blueyonder.co.uk/blueyonder/searches/search.jsp?q=a+simple+test&cr=&sitesearch=&x=0&y=0',     'Blueyonder.co.uk simple search', 'blueyonder.co.uk'   ],
    ['http://www.alltheweb.com/search?cat=web&cs=iso88591&q=a+simple+test&rys=0&itag=crv&_sb_lang=pref',       'Alltheweb.com simple search', 'alltheweb.com'      ],
    ['http://search.lycos.com/?query=a+simple+test&x=0&y=0',                                                   'Lycos.com simple search', 'search.lycos.com'          ],  
    ['http://search.lycos.co.uk/cgi-bin/pursuit?query=a+simple+test&enc=utf-8&cat=slim_loc&sc=blue',           'Lycos.co.uk simple search', 'search.lycos.co.uk'        ],
    ['http://www.hotbot.com/index.php?query=a+simple+test&ps=&loc=searchbox&tab=web&mode=search&currProv=msn', 'HotBot.com simple search', 'hotbot.com'         ],
    ['http://search.yahoo.com/search?p=a+simple+test&fr=FP-tab-web-t400&toggle=1&cop=&ei=UTF-8',               'Yahoo.com simple search', 'search.yahoo.com'          ],
    ['http://uk.search.yahoo.com/search?p=a+simple+test&fr=FP-tab-web-t340&ei=UTF-8&meta=vc%3D',               'Yahoo.co.uk simple search', 'uk.search.yahoo.com'        ],
    ['http://uk.ask.com/web?q=a+simple+test&qsrc=0&o=0&l=dir&dm=all',                                          'Ask.com simple search', 'uk.ask.com'            ],
    ['http://www.mirago.co.uk/scripts/qhandler.aspx?qry=a+simple+test&x=0&y=0',                                'Mirago simple search', 'mirago.co.uk'             ],
    ['http://www.netscape.com/search/?s=a+simple+test',                                                        'Netscape.com simple search', 'netscape.com'        ],
    ['http://search.aol.co.uk/web?invocationType=ns_uk&query=a%20simple%20test',                               'AOL UK simple search', 'search.aol.co.uk'             ],
    ['http://www.tiscali.co.uk/search/results.php?section=&from=&query=a+simple+test',                         'Tiscali simple search', 'tiscali.co.uk'            ],
    ['http://www.mamma.com/Mamma?utfout=1&qtype=0&query=a+simple+test&Submit=%C2%A0%C2%A0Search%C2%A0%C2%A0',  'Mamma.com simple search', 'mamma.com'          ],
    ['http://blogs.icerocket.com/search?q=a+simple+test',                                                                                 'Icerocket Blogs simple search', 'blogs.icerocket.com'    ], 
    ['http://blogsearch.google.com/blogsearch?hl=en&ie=UTF-8&q=a+simple+test&btnG=Search+Blogs',                     'Google Blogs simple search', 'blogsearch.google.com'               ],
    ['http://suche.fireball.de/cgi-bin/pursuit?query=a+simple+test&x=0&y=0&cat=fb_loc&enc=utf-8',                    'Fireball.de simple search', 'suche.fireball.de'          ],
    ['http://suche.web.de/search/web/?allparams=&smode=&su=a+simple+test&webRb=de',                                        'Web.de simple search', 'suche.web.de'                        ],
    ['http://www.technorati.com/search/a%20simple%20test',                                                      'Technorati simple search', 'technorati.com' ],
    ['http://www.feedster.com/search/a%20simple%20test',                                                        'Feedster.com simple search', 'feedster.com'],
    ['http://www.google.co.uk/search?sourceid=navclient&aq=t&ie=UTF-8&rls=DVXA,DVXA:2006-32,DVXA:en&q=a+simple+test', 'Google weird search', 'google.co.uk'],
    ['http://www.tesco.net/google/searchresults.asp?q=a+simple+test&cr=', 'Tesco.net Google search', 'tesco.net'],
    ['http://gps.virgin.net/search/sitesearch?submit.x=1&start=0&format=1&num=10&restrict=site&sitefilter=site%2Fsite_filter.hts&siteresults=site%2Fsite_results.hts&sitescorethreshold=28&q=a+simple+test&scope=UK&x=0&y=0', 'Virgin.net search', 'gps.virgin.net'],
    ['http://search.bbc.co.uk/cgi-bin/search/results.pl?tab=web&go=homepage&q=a+simple+test&Search.x=0&Search.y=0&Search=Search&scope=all', 'BBC Google search', 'search.bbc.co.uk'],
    ['http://search.live.com/results.aspx?q=a+simple+test&mkt=en-us&FORM=LVSP&go.x=0&go.y=0&go=Search', 'MS Live', 'search.live.com'],
    ['http://search.mywebsearch.com/mywebsearch/AJmain.jhtml?searchfor=a+simple+test', 'MyWebSearch.com', 'search.mywebsearch.com'],
    ['http://www.megasearching.net/m/search.aspx?s=a+simple+test&mkt=&orig=1', 'Megasearch', 'megasearching.net'],
    ['http://www.blueyonder.co.uk/blueyonder/searches/search.jsp?q=a+simple+test&cr=&sitesearch=&x=0&y=0', 'Blueyonder search', 'blueyonder.co.uk'],
    ['http://search.ntlworld.com/ntlworld/search.php?q=a+simple+test&cr=&x=0&y=0', 'NTLworld search', 'search.ntlworld.com'],
    ['http://search.orange.co.uk/all?p=_searchbox&pt=resultgo&brand=ouk&tab=web&q=a+simple+test', 'Orange.co.uk', 'search.orange.co.uk'],
    ['http://search.virginmedia.com/results/index.php?channel=other&q=a+simple+test&cr=&x=0&y=0', 'VirginMedia search', 'search.virginmedia.com'],
    ['http://as.starware.com/dp/search?src_id=305&product=unknown&qry=a+simple+test&z=Find+It', 'Starware', 'as.starware.com'],
    ['http://aolsearch.aol.com/aol/search?invocationType=topsearchbox.webhome&query=a+simple+test', 'AOLsearch','aolsearch.aol.com'],
    ['http://www.ask.com/web?q=a+simple+test&qsrc=0&o=0&l=dir', 'Ask.com', 'ask.com' ],
    ['http://buscador.terra.es/Default.aspx?source=Search&ca=s&query=a%20simple%20test', 'Terra.es', 'buscador.terra.es'],
    ['http://busca.orange.es/search?origen=home&destino=web&buscar=a+simple+test', 'Orange.es', 'busca.orange.es'],
    ['http://search.sweetim.com/search.asp?ln=en&q=a%20simple%20test', 'Sweetim', 'search.sweetim.com'],
    ['http://search.conduit.com/Results.aspx?q=a+simple+test&hl=en&SelfSearch=1&SearchSourceOrigin=1&ctid=WEBSITE', 'Conduit', 'search.conduit.com'],
    ['http://buscar.ozu.es/index.php?etq=web&q=a+simple+test', 'Ozu.es', 'buscar.ozu.es'],
    ['http://buscador.lycos.es/cgi-bin/pursuit?query=a+simple+test&websearchCat=loc&cat=loc&SITE=de&enc=utf-8&ref=sboxlink', 'Lycos.es', 'buscador.lycos.es'],
    ['http://search.icq.com/search/results.php?q=a+simple+test&ch_id=st&search_mode=web', 'ICQ.com', 'search.icq.com'],
    ['http://search.yahoo.co.jp/search?ei=UTF-8&fr=sfp_as&p=a+simple+test&meta=vc%3D', 'Yahoo Japan', 'search.yahoo.co.jp'],
    ['http://www.soso.com/q?pid=s.idx&w=a+simple+test', 'Soso', 'soso.com'],
    ['http://search.myway.com/search/AJmain.jhtml?searchfor=a+simple+test', 'MyWay', 'search.myway.com'],
    ['http://www.ilmotore.com/newsearch/?query=a+simple+test&where=web', 'ilMotore', 'ilmotore.com'],
    ['http://www.ithaki.net/ricerca.cgi?where=italia&query=a+simple+test', 'Ithaki', 'ithaki.net'],
    ['http://ricerca.alice.it/ricerca?f=hpn&qs=a+simple+test', 'Alice.it', 'alice.it'],
    ['http://it.search.yahoo.com/search?p=a+simple+test&fr=yfp-t-501&ei=UTF-8&rd=r1','Yahoo IT', 'search.yahoo.com'],
    ['http://www.excite.it/search/web/results?l=&q=a+simple+test', 'Excite IT', 'excite.it'],
    ['http://it.altavista.com/web/results?itag=ody&q=a+simple+test&kgs=1&kls=0','Altavista IT', 'altavista.com'],
    ['http://cerca.lycos.it/cgi-bin/pursuit?query=a+simple+test&cat=web', 'Lycos IT', 'lycos.it'],
    ['http://arianna.libero.it/search/abin/integrata.cgi?query=a+simple+test&regione=8&x=0&y=0', 'Libero IT', 'libero.it'],
    ['http://www.thespider.it/dir/index.php?q=a+simple+test&search-btn.x=0&search-btn.y=0', 'TheSpider.it', 'thespider.it'],
    ['http://godado.it/engine.php?l=it&key=a+simple+test&x=0&y=0', 'Godado IT', 'godado.it'],
    ['http://www.kataweb.it/ricerca?q=a%20simple%20test&amp;hl=it&amp;start=0', 'Kataweb IT', 'kataweb.it'],
    ['http://www.simpatico.ws/cgi-bin/links/search.cgi?query=a+simple+test&Vai=Go', 'Simpatico IT', 'simpatico.ws'],
    ['http://www.categorico.it/ricerca.html?domains=Categorico.it&q=a+simple+test&sa=Cerca+con+Google&sitesearch=&client=pub-0499722654836507&forid=1&channel=7983145815&ie=ISO-8859-1&oe=ISO-8859-1&cof=GALT%3A%23008000%3BGL%3A1%3BDIV%3A%23336699%3BVLC%3A663399%3BAH%3Acenter%3BBGC%3AFFFFFF%3BLBGC%3A336699%3BALC%3A0000FF%3BLC%3A0000FF%3BT%3A000000%3BGFNT%3A0000FF%3BGIMP%3A0000FF%3BFORID%3A11&hl=it', 'Categorico IT', 'categorico.it'],
    ['http://www.cuil.com/search?q=a+simple+test', 'Cuil', 'cuil.com'],
    ['http://www.fastweb.it/portale/google/?qtype=w&q=a+simple+test', 'Fastweb', 'fastweb.it'],
    ['http://suche.t-online.de/fast-cgi/tsc?q=a+simple+test&encQuery=haus+in+lichtenau+bei+karlshuld+&x=0&y=0&lang=any&mandant=toi&device=html&portallanguage=de&userlanguage=de&dia=suche&context=internet-tab&tpc=internet&ptl=std&classification=internet-tab_internet_std&start=0&num=10&ocr=yes&type=all&sb=top&more=none', 'T-Online', 'suche.t-online.de'],
    ['https://community.paglo.com/search?q=a+simple+test&x=0&y=0', 'Paglo', 'community.paglo.com' ],
    ['http://mahalo.com/Special:Search?search=a+simple+test&go=Search', 'Mahalo', 'mahalo.com'],
    ['http://www.bing.com/search?q=a+simple+test&go=&form=QBLH&filt=all', 'Bing', 'bing.com'],
    ['http://www.sproose.com/search?query=a+simple+test&searchLanguage=en', 'Sproose', 'sproose.com'],
    [ 'http://fastbrowsersearch.com/results/results.aspx?q=a+simple+test&s=homepage&tid=&v=', 'Fastbrowsersearch', 'fastbrowsersearch.com'],
    [ 'http://clusty.com/search?input-form=clusty-simple&v%3Asources=webplus&query=a+simple+test', 'Clusty', 'clusty.com' ],
    [ 'http://find.in.gr/result.asp?src=0&q=a%20simple%20test', 'In GR', 'in.gr' ],
    [ 'http://www.robby.gr/search.pl?lang=english&searchstr=a+simple+test&submit=Search&topic=greece', 'Robby GR', 'robby.gr' ],
    [ 'http://search.pathfinder.gr/?q=a%20simple%20test', 'Pathfinder GR', 'pathfinder.gr' ],
    [ 'http://world.phantis.com/spade.get?q=a+simple+test&cs=iso8859-7', 'Phantis GR', 'phantis.com' ],
   [ 'http://www.google.com.ua/search?hl=uk&source=hp&q=a+simple+test&btnG=Пошук+Google&meta=&aq=f&oq=', 'Google UA', 'google.com.ua' ],
   [ 'http://www.acbusca.com/busca?query=a+simple+test&ss=Procurar&meta=all',    'ACBusca', 'acbusca.com' ],
   [ 'http://atalhocerto.com.br/parking.php?ses=Y3JlPTEyODU2ODY0MjcmdGNpZD1hdGFsaG9jZXJ0by5jb20uYnI0Y2EyMDQ5YTFlNjViNC41MjkyMTEzNSZma2k9MTUwNDc1MjMyJnRhc2s9c2VhcmNoJmRvbWFpbj1hdGFsaG9jZXJ0by5jb20uYnImcz1mMWYyNWViMjQxOTZjMzk1MTNiOSZsYW5ndWFnZT1lbiZwZ3Q9R1ZMRXRmMlc4VVlLRXdpWmpQR1ZzNnFrQWhYUGhOOEtIWFl0aktBWUFDQUFPREJBcUx5UDM1X2p0djR0JmFncz03RGZhMVhYUmlzUUtFd2laalBHVnM2cWtBaFhQaE44S0hYWXRqS0FZQXlBQU9EQkFxTHlQMzVfanR2NHQmYV9pZD0xJnRyYWNrcXVlcnk9MQ%3D%3D&token=7Dfa1XXRisQKEwiZjPGVs6qkAhXPhN8KHXYtjKAYAyAAODBAqLyP35_jtv4t&keyword=a+simple+test',   'atalhocerto', 'atalhocerto.com.br' ],
   [ 'http://bastaclicar.com.br/search.asp?search=a+simple+test&destino=1',   'Basta Clicar', 'bastaclicar.com.br' ],
   [ 'http://bemrapido.com.br/engine.php?chave=a+simple+test', 'Bem   Rapido', 'bemrapido.com.br' ],
   [ 'http://br.altavista.com/web/results?fr=altavista&itag=ody&q=a+simple+test&kgs=1&kls=0',   'AltaVista Brasil', 'br.altavista.com' ],
   [ 'http://br.search.yahoo.com/search?vc=&p=a+simple+test&toggle=1&cop=mss&ei=UTF-8&fr=yfp-t-707',   'Yahoo Brazil', 'br.search.yahoo.com' ],
   [ 'http://mundo.busca.uol.com.br/buscar.html?q=a+simple+test&ad=on',   'Radar UOL', 'busca.uol.com.br' ],
   [ 'http://www.buscaaqui.com.br/meta/busca.php?cx=014464830400903769598:fvcs3xxfjn8&cof=FORID:9&ie=UTF-8&q=a+simple+test&sa=Pesquisar',
   'Busca Aqui', 'buscaaqui.com.br' ],
   [ 'http://buscador.terra.com.br/Default.aspx?source=Search&ca=s&query=a%20simple%20test',   'Terra Busca', 'buscador.terra.com.br' ],
   [ 'http://cade.search.yahoo.com/search;_ylt=A0oG749bBaJMrTABlIDa7Qt.;_ylc=X1MDMjE0MjQ3ODk0OARfcgMyBGZyA3NmcARuX2dwcwM1BG9yaWdpbgNzeWMEcXVlcnkDYSBzaW1wbGUgdGVzdARzYW8DMQ--?p=a+simple+test&fr=sfp&fr2=&iscqry=',   'Cadê', 'cade.search.yahoo.com' ],
   [ 'http://www.clickgratis.com.br/links/index.php?query=a+simple+test',   'Click Gratis', 'clickgratis.com.br' ],   [ 'http://entrada.com.br/busca.asp?q=a+simple+test&d=entrada.com.br&qs=06oENya4ZG1YS6vOLJwpLiFdjG9zxAJmLXwvTu2iPjK6Hygucd3wEEdFF99h2IeJhmNgoo36JFx9uDdDLFIqPee5LPG_vsfzqpaK0Twzq7mNfLqIi3txEaymklZWrNIH8k0zcw-pkv34SCXoLJgQr70khTrh_kDbBRBdy2G1rzPFdUoeszfwxmtKn7neQAHdXxZdolAjVKt0nEcxjGiEkmLVzGhUxjN4o4m9X3VrLcmAVnlm6S41D9-l5rSP5b53MlrR9BzVK1my7zl4ll-vteAUnqrS4XgKCUO9BkmFYGCZpRdMk4,YT0z',   'Entrada', 'entrada.com.br' ],
   [ 'http://www.gigabusca.com.br/search.php?what=a+simple+test&search_top=',   'Giga Busca', 'gigabusca.com.br' ],
   [ 'http://internetica.com.br/busca.asp?co=BR&busca=a+simple+test&imageField2.x=0&imageField2.y=0',   'Internetica', 'internetica.com.br' ],
   [ 'http://www.katatudo.com.br/busca/busca.php?base=web&tag=KATATUDO&layout_sel=layout_simples&tema_sel=padrao&q=a+simple+test',   'KataTudo', 'katatudo.com.br' ],
   [ 'http://minasplanet.com.br/index.php?term=a+simple+test&req=search&category=0&contain=all&find=similar&Submit=Procurar',   'Minas Planet', 'minasplanet.com.br' ],
   [ 'http://speedybusca.com.br/busca.php?cx=008561444203672047661:hmm5kbhjfoa&cof=FORID:9&mode=allwords&q=a+simple+test&botao.x=0&botao.y=0&botao=Buscar&pesquisar=portugues',   'SpeedyBusca', 'speedybusca.com.br' ],
   [ 'http://vaibuscar.com.br/buscar.asp?q=a+simple+test&submeter=++++Buscar++++',   'Vai Busca', 'vaibuscar.com.br' ],
   [ 'http://search.conduit.com/Results.aspx?q=a+simple+test&meta=all&hl=en&gl=uk&SelfSearch=1&SearchSourceOrigin=32&ctid=WEBSITE', 'Conduit', 'search.conduit.com', ],
   [ 'http://in.search.yahoo.com/search;_ylt=A0oG75Wz6K5M6WoANuu6HAx.;_ylc=X1MDMjE0MjQ3ODk0OARfcgMyBGZyA3NmcARuX2dwcwM1BG9yaWdpbgNzeWMEcXVlcnkDYSBzaW1wbGUgdGVzdARzYW8DMQ--?p=a+simple+test&fr=sfp&fr2=&iscqry=',   'Yahoo India', 'in.search.yahoo.com' ],
  [ 'http://search1.rediff.com/dirsrch/default.asp?src=web&MT=a%20simple%20test',   'Rediff', 'rediff.com' ],
  [ 'http://www.guruji.com/search?hl=en&q=a+simple+test&sb=1',   'Guruji', 'guruji.com' ],
  ['http://www.cuil.pt/results.html?cx=004604575179660434744%3Aiy7nuhrkv7g&cof=FORID%3A10&ie=UTF-8&q=a+simple+test&sa=Search', 'Cuil PT', 'cuil.pt'],
   [ 'http://isohunt.com/torrents/?ihq=a+simple+test', 'Isohunt', 'isohunt.com' ],
   ['http://btjunkie.org/search?q=a+simple+test', 'BT Junkie', 'btjunkie.org' ],
   ['http://torrentz.eu/search?f=a+simple+test', 'Torrentz', 'torrentz.eu' ],
   
] ;

my $raa_complexTests = [
   ['http://www.google.com/search?hl=en&lr=&q=a+more%21+complex_+search%24&btnG=Search',                      'Google.com complex search', 'google.com'                  ],
   ['http://www.google.co.uk/search?hl=en&q=a+more%21+complex_+search%24&btnG=Google+Search&meta=',           'Google.co.uk complex search', 'google.co.uk'                ],
   ['http://www.google.co.jp/search?hl=ja&q=a+more%21+complex_+search%24&btnG=Google+%E6%A4%9C%E7%B4%A2&lr=', 'Google.co.jp complex search', 'google.co.jp'                ],
   ['http://search.msn.com/results.aspx?q=a+more%21+complex_+search%24&FORM=QBHP',                            'MSN.com complex search', 'search.msn.com'         ],
   ['http://search.msn.co.uk/results.aspx?q=a+more%21+complex_+search%24&FORM=MSNH&srch_type=0&cp=65001',     'Altavista.com complex search', 'search.msn.co.uk'               ],
   ['http://www.altavista.com/web/results?itag=ody&q=a+more%21+complex_+search%24&kgs=1&kls=0',               'Altavista.com complex search' , 'altavista.com'              ],
   ['http://uk.altavista.com/web/results?itag=ody&q=a+more%21+complex_+search%24&kgs=1&kls=0',                'Altavista.co.uk complex search' , 'uk.altavista.com'            ],
   ['http://www.blueyonder.co.uk/blueyonder/searches/search.jsp?q=a+more%21+complex_+search%24&cr=&sitesearch=&x=0&y=0', 'Blueyonder.co.uk complex search', 'blueyonder.co.uk' ],
   ['http://www.alltheweb.com/search?cat=web&cs=iso88591&q=a+more%21+complex_+search%24&rys=0&itag=crv&_sb_lang=pref', 'Alltheweb.com complex search', 'alltheweb.com'      ],
   ['http://search.lycos.com/?query=a+more%21+complex_+search%24&x=0&y=0',                                              'Lycos.com complex search', 'search.lycos.com'         ],
   ['http://search.lycos.co.uk/cgi-bin/pursuit?query=a+more%21+complex_+search%24&enc=utf-8&cat=slim_loc&sc=blue', 'Lucos.co.uk complex search', 'search.lycos.co.uk'            ],
   ['http://www.hotbot.com/index.php?query=a+more%21+complex_+search%24&ps=&loc=searchbox&tab=web&mode=search&currProv=msn', 'Hotbot.com complex search', 'hotbot.com'   ],
   ['http://search.yahoo.com/search?p=a+more%21+complex_+search%24&fr=FP-tab-web-t400&toggle=1&cop=&ei=UTF-8', 'Yahoo.com complex search', 'search.yahoo.com'   ],
   ['http://uk.search.yahoo.com/search?p=a+more%21+complex_+search%24&fr=FP-tab-web-t340&ei=UTF-8&meta=vc%3D', 'Yahoo.co.uk complex search', 'uk.search.yahoo.com' ],
   ['http://uk.ask.com/web?q=a+more%21+complex_+search%24&qsrc=0&o=0&l=dir&dm=all', 'Ask.com UK complex search', 'uk.ask.com'],
   ['http://www.mirago.co.uk/scripts/qhandler.aspx?qry=a+more%21+complex_+search%24&x=0&y=0', 'Mirago complex search', 'mirago.co.uk' ],
   ['http://www.netscape.com/search/?s=a+more%21+complex_+search%24', 'Netscape.com complex search', 'netscape.com' ],
   ['http://search.aol.co.uk/web?query=a+more%21+complex_+search%24&x=0&y=0&isinit=true&restrict=wholeweb', 'AOL UK complex search', 'search.aol.co.uk' ],
   ['http://www.tiscali.co.uk/search/results.php?section=&from=&query=a+more%21+complex_+search%24', 'Tiscali.co.uk complex search', 'tiscali.co.uk' ],
   ['http://www.mamma.com/Mamma?utfout=1&qtype=0&query=a+more%21+complex_+search%24&Submit=%C2%A0%C2%A0Search%C2%A0%C2%A0', 'Mamma.com complex search', 'mamma.com'],
] ;

my $ra_nowarnings = [
  'http://www.google.com/reader/view/',
  'http://www.google.co.uk/',
  'http://www.googlesyndicatedsearch.com/u/huddersfield?hl=en&lr=&ie=ISO-8859-1&domains=www.hud.ac.uk&q=property%2Btong%2C+bradford&btnG=Search&sitesearch=',
  'http://www.google.com/notebook/fullpage',
  'http://intranet/WorkSite/scripts/redirector.aspx?url=http%3A//www.google.co.uk',
  'http://www.googlesyndicatedsearch.com/u/huddersfield?hl=en&lr=&ie=ISO-8859-1&domains=www.hud.ac.uk&q=property%2Btong%2C+bradford&btnG=Search&sitesearch=',
] ;

diag 'Testing simple queries';

foreach my $ra_test (@$raa_simpleTests) {
  my $string     = $ra_test->[0];
  my $text       = $ra_test->[1];
  my $hostname   = $ra_test->[2];
  
  ok( my $got_terms  = $obj->se_term( $string ) );
  
  is(
     $got_terms,
     'a simple test',
     "se_term() for $hostname OK"     
  );
  
  ok( my $got_host = $obj->se_host( $string ) );
   
  is(
     $got_host,
     $hostname,
     "se_host() for $hostname OK"     
  );
   
} 

diag 'Testing complex queries';

foreach my $ra_test (@$raa_complexTests) {
   
   
    my $string     = $ra_test->[0];
    my $text       = $ra_test->[1];
    my $hostname   = $ra_test->[2];

    ok( my $got_terms  = $obj->se_term( $string ) );

    is(
       $got_terms,
       'a more! complex_ search$',
       "se_term() for $hostname OK"     
    );

    ok( my $got_host = $obj->se_host( $string ) );

    is(
       $got_host,
       $hostname,
       "se_host() for $hostname OK"     
    );
      
}

diag 'Making sure no warnings get issues from weird Google';

foreach my $teststring (@$ra_nowarnings) {
  is(
     $obj->parse_search_string($teststring),
     undef,
     'no warnings test' 
  );
}

diag 'Testing for akward situations';

is(
   $obj->parse_search_string('http://googlemapsmania.blogspot.com/'),
   undef,
   'Google-esque sites do not go through'
);

is(
   $obj->parse_search_string('-------------------------'),
   undef,
   'Works with bad input'
);

is(
   $obj->parse_search_string(''),
   undef,
   'Works with no input'
);

is(
   $obj->parse_search_string('http://www.google.co.uk/search?q=%22The+Berwick+Inn%22+Sussex&hl=en'),
   '"The Berwick Inn" Sussex',
   'proper escaping'
);

my $ra_bad_strings = [ 'http:', 'http://', 'https:', 'https://', 'http', 'https' ];

foreach my $bad_string (@$ra_bad_strings) {
    is(
        $obj->se_host( $bad_string ),
        undef,
        'badly formatted strings'
    );
    
}


