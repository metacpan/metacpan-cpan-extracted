use lib 'lib';
use Test::More tests => 4;
use WWW::Wikipedia::Links;
use Mojo::DOM;
use utf8;

my $html = do { local $/; <DATA> };
my $dom = Mojo::DOM->new->parse($html);

my $res = WWW::Wikipedia::Links::_extract_from_dom($dom);

my $langs = join ' ', map $_->{lang}, @{$res->{translations}};
is $langs, 'en es fr ja no', 'extracted the right languages';

my $urls = join ' ', map $_->{url}, @{ $res->{translations} };
is $urls, join(' ', qw{
        http://en.wikipedia.org/wiki/Ralf_Isau
        http://es.wikipedia.org/wiki/Ralf_Isau
        http://fr.wikipedia.org/wiki/Ralf_Isau
        http://ja.wikipedia.org/wiki/%E3%83%A9%E3%83%AB%E3%83%95%E3%83%BB%E3%82%A4%E3%83%BC%E3%82%B6%E3%82%A6
        http://no.wikipedia.org/wiki/Ralf_Isau
    }), 'extracted the right links';

my $titles = join '|', map $_->{title}, @{ $res->{translations} };
is $titles,
    'Ralf Isau|Ralf Isau|Ralf Isau|ラルフ・イーザウ|Ralf Isau',
    'extracted the right titles';

is $res->{license}, 'http://creativecommons.org/licenses/by-sa/3.0/',
    'extracted license URL';


__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="de" dir="ltr" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Ralf Isau – Wikipedia</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="generator" content="MediaWiki 1.17wmf1" />
<link rel="alternate" type="application/x-wiki" title="Seite bearbeiten" href="/w/index.php?title=Ralf_Isau&amp;action=edit" />
<link rel="edit" title="Seite bearbeiten" href="/w/index.php?title=Ralf_Isau&amp;action=edit" />
<link rel="apple-touch-icon" href="http://de.wikipedia.org/apple-touch-icon.png" />
<link rel="shortcut icon" href="/favicon.ico" />
<link rel="search" type="application/opensearchdescription+xml" href="/w/opensearch_desc.php" title="Wikipedia (de)" />
<link rel="EditURI" type="application/rsd+xml" href="http://de.wikipedia.org/w/api.php?action=rsd" />
<link rel="copyright" href="http://creativecommons.org/licenses/by-sa/3.0/" />
<link rel="alternate" type="application/atom+xml" title="Atom-Feed für „Wikipedia“" href="/w/index.php?title=Spezial:Letzte_%C3%84nderungen&amp;feed=atom" />
<link rel="stylesheet" href="http://bits.wikimedia.org/de.wikipedia.org/load.php?debug=false&amp;lang=de&amp;modules=mediawiki%21legacy%21commonPrint%7Cmediawiki%21legacy%21shared%7Cskins%21vector&amp;only=styles&amp;skin=vector" type="text/css" media="all" />

<link rel="stylesheet" href="http://bits.wikimedia.org/w/extensions-1.17/FlaggedRevs/client/flaggedrevs.css?87" type="text/css" media="all" /><meta name="ResourceLoaderDynamicStyles" content="" /><link rel="stylesheet" href="http://bits.wikimedia.org/de.wikipedia.org/load.php?debug=false&amp;lang=de&amp;modules=site&amp;only=styles&amp;skin=vector" type="text/css" media="all" />
<style type="text/css" media="all">a.new,#quickbar a.new{color:#ba0000}

/* cache key: dewiki:resourceloader:filter:minify-css:5:f2a9127573a22335c2a9102b208c73e7 */</style>
<script type="text/javascript">wgNamespaceNumber=0;wgAction="view";wgPageName="Ralf_Isau";wgMainPageTitle="Wikipedia:Hauptseite";wgWikimediaMobileUrl="http:\/\/de.m.wikipedia.org\/wiki";</script><script src="http://bits.wikimedia.org/w/extensions-1.17/WikimediaMobile/MobileRedirect.js?8.2" type="text/javascript"></script><!--[if lt IE 7]><style type="text/css">body{behavior:url("/w/skins-1.17/vector/csshover.min.htc")}</style><![endif]--></head>
<body class="mediawiki ltr capitalize-all-nouns ns-0 ns-subject page-Ralf_Isau skin-vector">
		<div id="mw-page-base" class="noprint"></div>
		<div id="mw-head-base" class="noprint"></div>
		<!-- content -->
		<div id="content">
			<a id="top"></a>

			<div id="mw-js-message" style="display:none;"></div>
						<!-- sitenotice -->
			<div id="siteNotice"><!-- centralNotice loads here --></div>
			<!-- /sitenotice -->
						<!-- firstHeading -->
			<h1 id="firstHeading" class="firstHeading">Ralf Isau</h1>
			<!-- /firstHeading -->
			<!-- bodyContent -->

			<div id="bodyContent">
				<!-- tagline -->
				<div id="siteSub">aus Wikipedia, der freien Enzyklopädie</div>
				<!-- /tagline -->
				<!-- subtitle -->
				<div id="contentSub"></div>
				<!-- /subtitle -->
																<!-- jumpto -->

				<div id="jump-to-nav">
					Wechseln zu: <a href="#mw-head">Navigation</a>,
					<a href="#p-search">Suche</a>
				</div>
				<!-- /jumpto -->
								<!-- bodytext -->
				<div class="thumb tright">
<div class="thumbinner" style="width:222px;"><a href="/w/index.php?title=Datei:Ralf_Isau_01.jpg&amp;filetimestamp=20071124225004" class="image"><img alt="" src="http://upload.wikimedia.org/wikipedia/commons/thumb/f/f4/Ralf_Isau_01.jpg/220px-Ralf_Isau_01.jpg" width="220" height="321" class="thumbimage" /></a>

<div class="thumbcaption">
<div class="magnify"><a href="/w/index.php?title=Datei:Ralf_Isau_01.jpg&amp;filetimestamp=20071124225004" class="internal" title="vergrößern"><img src="http://bits.wikimedia.org/skins-1.17/common/images/magnify-clip.png" width="15" height="11" alt="" /></a></div>
Ralf Isau bei einer Lesung in Stuttgart</div>
</div>
</div>
<p><b>Ralf Isau</b> (* <a href="/wiki/1._November" title="1. November">1. November</a> <a href="/wiki/1956" title="1956">1956</a> in <a href="/wiki/Berlin" title="Berlin">Berlin</a>) ist ein deutscher Schriftsteller.</p>

<table id="toc" class="toc">
<tr>
<td>
<div id="toctitle">
<h2>Inhaltsverzeichnis</h2>
</div>
<ul>
<li class="toclevel-1 tocsection-1"><a href="#Leben"><span class="tocnumber">1</span> <span class="toctext">Leben</span></a></li>
<li class="toclevel-1 tocsection-2"><a href="#Auszeichnungen"><span class="tocnumber">2</span> <span class="toctext">Auszeichnungen</span></a></li>
<li class="toclevel-1 tocsection-3"><a href="#Werke"><span class="tocnumber">3</span> <span class="toctext">Werke</span></a>

<ul>
<li class="toclevel-2 tocsection-4"><a href="#Neschan-Trilogie"><span class="tocnumber">3.1</span> <span class="toctext">Neschan-Trilogie</span></a></li>
<li class="toclevel-2 tocsection-5"><a href="#Der_Kreis_der_D.C3.A4mmerung"><span class="tocnumber">3.2</span> <span class="toctext">Der Kreis der Dämmerung</span></a></li>
<li class="toclevel-2 tocsection-6"><a href="#Die_Chroniken_von_Mirad"><span class="tocnumber">3.3</span> <span class="toctext">Die Chroniken von Mirad</span></a></li>
<li class="toclevel-2 tocsection-7"><a href="#Der_Zirkel_der_Phantanauten"><span class="tocnumber">3.4</span> <span class="toctext">Der Zirkel der Phantanauten</span></a></li>

</ul>
</li>
<li class="toclevel-1 tocsection-8"><a href="#Weblinks"><span class="tocnumber">4</span> <span class="toctext">Weblinks</span></a></li>
</ul>
</td>
</tr>
</table>
<h2><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=1" title="Abschnitt bearbeiten: Leben">Bearbeiten</a>]</span> <span class="mw-headline" id="Leben">Leben</span></h2>
<p>Er arbeitete zunächst als Organisationsprogrammierer, PC-Verkäufer, Systemanalytiker und Niederlassungsleiter eines Software-Hauses, Projektmanager und seit 1996 als selbstständiger EDV-Berater. Zu dieser Zeit hatte er bereits ein Kinderbuch und drei Romane veröffentlicht. Zum Schreiben kam er 1988, als er mit der Arbeit an der <a href="/wiki/Neschan-Trilogie" title="Neschan-Trilogie">Neschan-Trilogie</a> begann. 1992 überreichte er <a href="/wiki/Michael_Ende" title="Michael Ende">Michael Ende</a> anlässlich einer Lesung ein kleines, selbstgebundenes Märchenbuch (<i>Der Drache Gertrud</i>), das er für seine Tochter geschrieben hatte. Ende empfahl ihn dem <a href="/wiki/Thienemann_Verlag" title="Thienemann Verlag">Thienemann Verlag</a>, wo Ralf Isau seither über ein Dutzend Romane für jüngere und ältere Leser veröffentlichte, die in zwölf Sprachen übersetzt und mit mehreren Preisen ausgezeichnet worden sind. Ein Merkmal seiner Romane, die er selbst als „Phantagone“ bezeichnet, ist die Vermischung von Fiktion mit historischen Tatsachen.</p>

<p>Mit Romanen wie <i>Der silberne Sinn</i> (2003) und <i>Der Herr der Unruhe</i> (2004) wagte Ralf Isau den Schritt vom Jugendbuch zur Erwachsenenliteratur. Im Roman <i>Die Galerie der Lügen Oder: Der unachtsame Schläfer</i> (2005) setzt er sich mit der Darwinschen <a href="/wiki/Evolutionstheorie" title="Evolutionstheorie">Evolutionstheorie</a> auseinander, die er zugunsten einer auf <a href="/wiki/Intelligent_Design" title="Intelligent Design">Intelligent Design</a> basierenden Sichtweise ablehnt.</p>

<p>Isau lebt mit seiner Frau in <a href="/wiki/Asperg" title="Asperg">Asperg</a> bei <a href="/wiki/Ludwigsburg" title="Ludwigsburg">Ludwigsburg</a>.</p>
<h2><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=2" title="Abschnitt bearbeiten: Auszeichnungen">Bearbeiten</a>]</span> <span class="mw-headline" id="Auszeichnungen">Auszeichnungen</span></h2>
<ul>
<li><i><a href="/wiki/Das_Museum_der_gestohlenen_Erinnerungen" title="Das Museum der gestohlenen Erinnerungen">Das Museum der gestohlenen Erinnerungen</a></i><br />
<a href="/wiki/Buxtehuder_Bulle" title="Buxtehuder Bulle">Buxtehuder Bullen</a> für das beste Jugendbuch des Jahres 1997, Buch des Jahres 1998 (JuBuCrew Göttingen), Buch des Monats Februar 1998 (JuBuCrew Göttingen), gefördert von Inter Nations</li>

<li><i>Das Netz der Schattenspiele</i><br />
Buch des Jahres 1999 (JuBuCrew Göttingen), 3. Platz beim Preis der <a href="/w/index.php?title=Moerser-Jugendbuch-Jury&amp;action=edit&amp;redlink=1" class="new" title="Moerser-Jugendbuch-Jury (Seite nicht vorhanden)">Moerser-Jugendbuch-Jury</a> 1999/2000</li>
</ul>
<h2><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=3" title="Abschnitt bearbeiten: Werke">Bearbeiten</a>]</span> <span class="mw-headline" id="Werke">Werke</span></h2>
<ul>
<li><i>Der Drache Gertrud</i>. 1994, <a href="/wiki/Spezial:ISBN-Suche/3522173589" class="internal mw-magiclink-isbn">ISBN 3-522-17358-9</a></li>

<li><i>Das Museum der gestohlenen Erinnerungen</i>. 1997, <a href="/wiki/Spezial:ISBN-Suche/3522175794" class="internal mw-magiclink-isbn">ISBN 3-522-17579-4</a></li>
<li><i>Das Echo der Flüsterer</i>. 1998, <a href="/wiki/Spezial:ISBN-Suche/3522171934" class="internal mw-magiclink-isbn">ISBN 3-522-17193-4</a></li>
<li><i>Das Netz der Schattenspiele</i>. 1999, <a href="/wiki/Spezial:ISBN-Suche/3522172574" class="internal mw-magiclink-isbn">ISBN 3-522-17257-4</a></li>
<li><i>Pala und die seltsame Verflüchtigung der Worte</i>. 2002, <a href="/wiki/Spezial:ISBN-Suche/3522174321" class="internal mw-magiclink-isbn">ISBN 3-522-17432-1</a></li>
<li><i>Der Silberne Sinn</i>. 2003, <a href="/wiki/Spezial:ISBN-Suche/3404152344" class="internal mw-magiclink-isbn">ISBN 3-404-15234-4</a></li>

<li><i>Die unsichtbare Pyramide</i>. 2003, <a href="/wiki/Spezial:ISBN-Suche/3522175948" class="internal mw-magiclink-isbn">ISBN 3-522-17594-8</a></li>
<li><i>Die geheime Bibliothek des Thaddäus Tillmann Trutz</i>. 2003, <a href="/wiki/Spezial:ISBN-Suche/3426196425" class="internal mw-magiclink-isbn">ISBN 3-426-19642-5</a></li>
<li><i>Der Leuchtturm in der Wüste</i>. 2004, <a href="/wiki/Spezial:ISBN-Suche/3522176634" class="internal mw-magiclink-isbn">ISBN 3-522-17663-4</a></li>
<li><i>Der Herr der Unruhe</i>. 2004, <a href="/wiki/Spezial:ISBN-Suche/343103392X" class="internal mw-magiclink-isbn">ISBN 3-431-03392-X</a></li>
<li><i>Die Galerie der Lügen</i>. 2005, <a href="/wiki/Spezial:ISBN-Suche/3431036368" class="internal mw-magiclink-isbn">ISBN 3-431-03636-8</a></li>

<li><i>Die Dunklen</i>. 2007, <a href="/wiki/Spezial:ISBN-Suche/3492701396" class="internal mw-magiclink-isbn">ISBN 3-492-70139-6</a></li>
<li><i>Minik - An den Quellen der Nacht</i>. 2008, <a href="/wiki/Spezial:ISBN-Suche/3522178734" class="internal mw-magiclink-isbn">ISBN 3522178734</a></li>
<li><i>Der Mann, der nichts vergessen konnte</i>. 2008, <a href="/wiki/Spezial:ISBN-Suche/3492701418" class="internal mw-magiclink-isbn">ISBN 3492701418</a></li>
<li><i>Der Schattendieb</i>. 2009, <a href="/wiki/Spezial:ISBN-Suche/9783522200295" class="internal mw-magiclink-isbn">ISBN 9783522200295</a></li>
<li><i>Messias</i>. 2009, <a href="/wiki/Spezial:ISBN-Suche/3492701426" class="internal mw-magiclink-isbn">ISBN 3-492-70142-6</a></li>

</ul>
<h3><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=4" title="Abschnitt bearbeiten: Neschan-Trilogie">Bearbeiten</a>]</span> <span class="mw-headline" id="Neschan-Trilogie"><i><a href="/wiki/Neschan-Trilogie" title="Neschan-Trilogie">Neschan-Trilogie</a></i></span></h3>
<ul>
<li><i>Die Träume des Jonathan Jabbok</i>. 1995, <a href="/wiki/Spezial:ISBN-Suche/3522168968" class="internal mw-magiclink-isbn">ISBN 3-522-16896-8</a></li>
<li><i>Das Geheimnis des siebten Richters</i>. 1996, <a href="/wiki/Spezial:ISBN-Suche/3522169018" class="internal mw-magiclink-isbn">ISBN 3-522-16901-8</a></li>
<li><i>Das Lied der Befreiung Neschans</i>. 1996, <a href="/wiki/Spezial:ISBN-Suche/352216945X" class="internal mw-magiclink-isbn">ISBN 3-522-16945-X</a></li>

</ul>
<h3><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=5" title="Abschnitt bearbeiten: Der Kreis der Dämmerung">Bearbeiten</a>]</span> <span class="mw-headline" id="Der_Kreis_der_D.C3.A4mmerung"><i><a href="/wiki/Der_Kreis_der_D%C3%A4mmerung" title="Der Kreis der Dämmerung">Der Kreis der Dämmerung</a></i></span></h3>
<ul>
<li><i>Der Kreis der Dämmerung – Teil 1: Das Jahrhundertkind</i>. 1999, <a href="/wiki/Spezial:ISBN-Suche/3522173066" class="internal mw-magiclink-isbn">ISBN 3-522-17306-6</a></li>
<li><i>Der Kreis der Dämmerung – Teil 2: Der Wahrheitsfinder</i>. 2000, <a href="/wiki/Spezial:ISBN-Suche/352217335X" class="internal mw-magiclink-isbn">ISBN 3-522-17335-X</a></li>
<li><i>Der Kreis der Dämmerung – Teil 3: Der weiße Wanderer</i>. 2001, <a href="/wiki/Spezial:ISBN-Suche/3522174011" class="internal mw-magiclink-isbn">ISBN 3-522-17401-1</a></li>

<li><i>Der Kreis der Dämmerung – Teil 4: Der unsichtbare Freund</i>. 2001, <a href="/wiki/Spezial:ISBN-Suche/3522174747" class="internal mw-magiclink-isbn">ISBN 3-522-17474-7</a></li>
</ul>
<h3><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=6" title="Abschnitt bearbeiten: Die Chroniken von Mirad">Bearbeiten</a>]</span> <span class="mw-headline" id="Die_Chroniken_von_Mirad"><i><a href="/w/index.php?title=Die_Chroniken_von_Mirad&amp;action=edit&amp;redlink=1" class="new" title="Die Chroniken von Mirad (Seite nicht vorhanden)">Die Chroniken von Mirad</a></i></span></h3>
<ul>
<li><i>Das gespiegelte Herz</i>. 2005, <a href="/wiki/Spezial:ISBN-Suche/3522177452" class="internal mw-magiclink-isbn">ISBN 3-522-17745-2</a></li>
<li><i>Der König im König</i>. 2006, <a href="/wiki/Spezial:ISBN-Suche/3522177460" class="internal mw-magiclink-isbn">ISBN 3-522-17746-0</a></li>

<li><i>Das Wasser von Silmao</i>. 2006, <a href="/wiki/Spezial:ISBN-Suche/3522177479" class="internal mw-magiclink-isbn">ISBN 3-522-17747-9</a></li>
</ul>
<h3><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=7" title="Abschnitt bearbeiten: Der Zirkel der Phantanauten">Bearbeiten</a>]</span> <span class="mw-headline" id="Der_Zirkel_der_Phantanauten"><i><a href="/w/index.php?title=Der_Zirkel_der_Phantanauten&amp;action=edit&amp;redlink=1" class="new" title="Der Zirkel der Phantanauten (Seite nicht vorhanden)">Der Zirkel der Phantanauten</a></i></span></h3>
<ul>
<li><i>Der Tränenpalast</i>. 2008, <a href="/wiki/Spezial:ISBN-Suche/9783522180870" class="internal mw-magiclink-isbn">ISBN 978-3-522-18087-0</a></li>
<li><i>Metropoly</i>. 2008, <a href="/wiki/Spezial:ISBN-Suche/9783522180887" class="internal mw-magiclink-isbn">ISBN 978-3-522-18088-7</a></li>

<li><i>Der Feuerkristall</i>. 2009, <a href="/wiki/Spezial:ISBN-Suche/9783522181716" class="internal mw-magiclink-isbn">ISBN 978-3-522-18171-6</a></li>
</ul>
<h2><span class="editsection">[<a href="/w/index.php?title=Ralf_Isau&amp;action=edit&amp;section=8" title="Abschnitt bearbeiten: Weblinks">Bearbeiten</a>]</span> <span class="mw-headline" id="Weblinks">Weblinks</span></h2>
<div class="sisterproject" style="margin:0.1em 0 0 0;"><img alt="" src="http://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Wikiquote-logo.svg/13px-Wikiquote-logo.svg.png" width="13" height="15" />&#160;<b><a href="http://de.wikiquote.org/wiki/Ralf_Isau" class="extiw" title="q:Ralf Isau">Wikiquote: Ralf Isau</a></b>&#160;– Zitate</div>
<ul>
<li><a href="http://www.isau.de/" class="external text" rel="nofollow">Netzauftritt von Ralf Isau</a></li>

<li><a href="https://portal.d-nb.de/opac.htm?query=Woe%3D115739386&amp;method=simpleSearch" class="external text" rel="nofollow">Literatur von und über Ralf Isau</a> im Katalog der <a href="/wiki/Deutsche_Nationalbibliothek" title="Deutsche Nationalbibliothek">Deutschen Nationalbibliothek</a></li>
<li><a href="http://www.ava-international.de/autoren/risau.php" class="external text" rel="nofollow">AVA-Autorenrubrik Ralf Isau</a></li>
<li><a href="http://www.buchwurm-info.de/book/anzeigen.php?id_book=5869/" class="external text" rel="nofollow">Rezension Messias</a></li>
</ul>
<div id="normdaten" class="catlinks"><b>Normdaten</b>: <a href="/wiki/Personennamendatei" title="Personennamendatei">PND</a>: <a href="http://d-nb.info/gnd/115739386" class="external text" rel="nofollow">115739386</a> <span class="metadata">(<a href="http://dispatch.opac.d-nb.de/DB=4.1/SET=4/TTL=1/PRS=PP%7F/PPN?PPN=115739386" class="external text" rel="nofollow">PICA</a>)</span> | <a href="/wiki/Library_of_Congress_Control_Number" title="Library of Congress Control Number">LCCN</a>: <a href="http://errol.oclc.org/laf/n2001031331.html" class="external text" rel="nofollow">n2001031331</a> | <a href="/wiki/Virtual_International_Authority_File" title="Virtual International Authority File">VIAF</a>: <a href="http://viaf.org/viaf/59821526/" class="external text" rel="nofollow">59821526</a> | <a href="http://toolserver.org/~apper/pd/person/Ralf_Isau" class="external text" rel="nofollow">WP-Personeninfo</a></div>

<p><br /></p>
<table class="metadata" style="margin-top:15pt;">
<tr>
<th colspan="2"><a href="/wiki/Hilfe:Personendaten" title="Hilfe:Personendaten">Personendaten</a></th>
</tr>
<tr>
<td class="metadata-label">NAME</td>
<td style="font-weight: bold;">Isau, Ralf</td>
</tr>
<tr>
<td class="metadata-label">KURZBESCHREIBUNG</td>
<td>deutscher Schriftsteller</td>

</tr>
<tr>
<td class="metadata-label">GEBURTSDATUM</td>
<td>1. November 1956</td>
</tr>
<tr>
<td class="metadata-label">GEBURTSORT</td>
<td><a href="/wiki/Berlin" title="Berlin">Berlin</a></td>
</tr>
</table>


<!-- 
NewPP limit report
Preprocessor node count: 308/1000000
Post-expand include size: 2214/2048000 bytes
Template argument size: 643/2048000 bytes
Expensive parser function count: 0/500
-->

<!-- Saved in stable version parser cache with key dewiki:stable-pcache:idhash:181099-0!1!0!!de!4 and timestamp 20110519071440 --><div class="printfooter">
Von „<a href="http://de.wikipedia.org/wiki/Ralf_Isau">http://de.wikipedia.org/wiki/Ralf_Isau</a>“</div>
				<!-- /bodytext -->
								<!-- catlinks -->
				<div id='catlinks' class='catlinks'><div id="mw-normal-catlinks"><a href="/wiki/Spezial:Kategorien" title="Spezial:Kategorien">Kategorien</a>: <span dir='ltr'><a href="/wiki/Kategorie:Autor" title="Kategorie:Autor">Autor</a></span> | <span dir='ltr'><a href="/wiki/Kategorie:Literatur_(20._Jahrhundert)" title="Kategorie:Literatur (20. Jahrhundert)">Literatur (20. Jahrhundert)</a></span> | <span dir='ltr'><a href="/wiki/Kategorie:Literatur_(Deutsch)" title="Kategorie:Literatur (Deutsch)">Literatur (Deutsch)</a></span> | <span dir='ltr'><a href="/wiki/Kategorie:Kinder-_und_Jugendliteratur" title="Kategorie:Kinder- und Jugendliteratur">Kinder- und Jugendliteratur</a></span> | <span dir='ltr'><a href="/wiki/Kategorie:Fantasyliteratur" title="Kategorie:Fantasyliteratur">Fantasyliteratur</a></span> | <span dir='ltr'><a href="/wiki/Kategorie:Deutscher" title="Kategorie:Deutscher">Deutscher</a></span> | <span dir='ltr'><a href="/wiki/Kategorie:Geboren_1956" title="Kategorie:Geboren 1956">Geboren 1956</a></span> | <span dir='ltr'><a href="/wiki/Kategorie:Mann" title="Kategorie:Mann">Mann</a></span></div></div>				<!-- /catlinks -->

												<div class="visualClear"></div>
			</div>
			<!-- /bodyContent -->
		</div>
		<!-- /content -->
		<!-- header -->
		<div id="mw-head" class="noprint">
			
<!-- 0 -->
<div id="p-personal" class="">

	<h5>Meine Werkzeuge</h5>
	<ul>
					<li  id="pt-login"><a href="/w/index.php?title=Spezial:Anmelden&amp;returnto=Ralf_Isau" title="Anmelden ist zwar keine Pflicht, wird aber gerne gesehen. [o]" accesskey="o">Anmelden / Benutzerkonto erstellen</a></li>
			</ul>
</div>

<!-- /0 -->
			<div id="left-navigation">
				
<!-- 0 -->

<div id="p-namespaces" class="vectorTabs">
	<h5>Namensräume</h5>
	<ul>
					<li  id="ca-nstab-main" class="selected"><span><a href="/wiki/Ralf_Isau"  title="Seiteninhalt anzeigen [c]" accesskey="c">Artikel</a></span></li>
					<li  id="ca-talk"><span><a href="/wiki/Diskussion:Ralf_Isau"  title="Diskussion zum Seiteninhalt [t]" accesskey="t">Diskussion</a></span></li>
			</ul>
</div>

<!-- /0 -->

<!-- 1 -->
<div id="p-variants" class="vectorMenu emptyPortlet">
		<h5><span>Varianten</span><a href="#"></a></h5>
	<div class="menu">
		<ul>
					</ul>
	</div>
</div>

<!-- /1 -->

			</div>
			<div id="right-navigation">
				
<!-- 0 -->
<div id="p-views" class="vectorTabs">
	<h5>Ansichten</h5>
	<ul>
					<li id="ca-view" class="selected"><span><a href="/wiki/Ralf_Isau" >Lesen</a></span></li>
					<li id="ca-edit"><span><a href="/w/index.php?title=Ralf_Isau&amp;action=edit"  title="Seite bearbeiten. Bitte vor dem Speichern die Vorschaufunktion benutzen. [e]" accesskey="e">Bearbeiten</a></span></li>

					<li id="ca-history" class="collapsible "><span><a href="/w/index.php?title=Ralf_Isau&amp;action=history"  title="Frühere Versionen dieser Seite [h]" accesskey="h">Versionsgeschichte</a></span></li>
			</ul>
</div>

<!-- /0 -->

<!-- 1 -->
<div id="p-cactions" class="vectorMenu emptyPortlet">
	<h5><span>Aktionen</span><a href="#"></a></h5>
	<div class="menu">
		<ul>

					</ul>
	</div>
</div>

<!-- /1 -->

<!-- 2 -->
<div id="p-search">
	<h5><label for="searchInput">Suche</label></h5>
	<form action="/w/index.php" id="searchform">
		<input type='hidden' name="title" value="Spezial:Suche"/>

				<div id="simpleSearch">
						<input id="searchInput" name="search" type="text"  title="Durchsuche die Wikipedia [f]" accesskey="f"  value="" />
						<button id="searchButton" type='submit' name='button'  title="Suche nach Seiten, die diesen Text enthalten"><img src="http://bits.wikimedia.org/skins-1.17/vector/images/search-ltr.png?301-2" alt="Volltext" /></button>
					</div>
			</form>
</div>

<!-- /2 -->
			</div>
		</div>

		<!-- /header -->
		<!-- panel -->
			<div id="mw-panel" class="noprint">
				<!-- logo -->
					<div id="p-logo"><a style="background-image: url(http://upload.wikimedia.org/wikipedia/commons/e/ec/Wikipedia-logo-v2-de.png);" href="/wiki/Wikipedia:Hauptseite"  title="Hauptseite"></a></div>
				<!-- /logo -->
				
<!-- SEARCH -->

<!-- /SEARCH -->

<!-- navigation -->
<div class="portal" id='p-navigation'>
	<h5>Navigation</h5>
	<div class="body">
				<ul>
					<li id="n-mainpage-description"><a href="/wiki/Wikipedia:Hauptseite" title="Hauptseite besuchen [z]" accesskey="z">Hauptseite</a></li>
					<li id="n-aboutsite"><a href="/wiki/Wikipedia:%C3%9Cber_Wikipedia">Über Wikipedia</a></li>
					<li id="n-topics"><a href="/wiki/Portal:Wikipedia_nach_Themen">Themenportale</a></li>

					<li id="n-alphindex"><a href="/wiki/Spezial:Alle_Seiten">Von A bis Z</a></li>
					<li id="n-randompage"><a href="/wiki/Spezial:Zuf%C3%A4llige_Seite" title="Zufällige Seite [x]" accesskey="x">Zufälliger Artikel</a></li>
				</ul>
			</div>
</div>

<!-- /navigation -->

<!-- Mitmachen -->
<div class="portal" id='p-Mitmachen'>
	<h5>Mitmachen</h5>

	<div class="body">
				<ul>
					<li id="n-help"><a href="/wiki/Wikipedia:Hilfe" title="Hilfeseite anzeigen">Hilfe</a></li>
					<li id="n-portal"><a href="/wiki/Wikipedia:Autorenportal" title="Über das Projekt, was du tun kannst, wo was zu finden ist">Autorenportal</a></li>
					<li id="n-recentchanges"><a href="/wiki/Spezial:Letzte_%C3%84nderungen" title="Liste der letzten Änderungen in Wikipedia [r]" accesskey="r">Letzte Änderungen</a></li>
					<li id="n-contact"><a href="/wiki/Wikipedia:Kontakt">Kontakt</a></li>
					<li id="n-sitesupport"><a href="http://wikimediafoundation.org/wiki/Special:Landingcheck?landing_page=WMFJA085&amp;language=de&amp;utm_source=donate&amp;utm_medium=sidebar&amp;utm_campaign=20101204SB002" title="Unterstütze uns">Spenden</a></li>

				</ul>
			</div>
</div>

<!-- /Mitmachen -->

<!-- coll-print_export -->
<div class="portal" id='p-coll-print_export'>
	<h5>Drucken/exportieren</h5>
	<div class="body">
				<ul id="collectionPortletList"><li id="coll-create_a_book"><a href="/w/index.php?title=Spezial:Buch&amp;bookcmd=book_creator&amp;referer=Ralf+Isau" title="Ein Buch oder eine Artikelsammlung erstellen" rel="nofollow">Buch erstellen</a></li><li id="coll-download-as-rl"><a href="/w/index.php?title=Spezial:Buch&amp;bookcmd=render_article&amp;arttitle=Ralf+Isau&amp;oldid=80621898&amp;writer=rl" title="Eine PDF-Version dieser Wikiseite herunterladen" rel="nofollow">Als PDF herunterladen</a></li><li id="t-print"><a href="/w/index.php?title=Ralf_Isau&amp;printable=yes" title="Druckansicht dieser Seite [p]" accesskey="p">Druckversion</a></li></ul>			</div>

</div>

<!-- /coll-print_export -->

<!-- TOOLBOX -->
<div class="portal" id="p-tb">
	<h5>Werkzeuge</h5>
	<div class="body">
		<ul>
					<li id="t-whatlinkshere"><a href="/wiki/Spezial:Linkliste/Ralf_Isau" title="Liste aller Seiten, die hierher verlinken [j]" accesskey="j">Links auf diese Seite</a></li>
						<li id="t-recentchangeslinked"><a href="/wiki/Spezial:%C3%84nderungen_an_verlinkten_Seiten/Ralf_Isau" title="Letzte Änderungen an Seiten, die von hier verlinkt sind [k]" accesskey="k">Änderungen an verlinkten Seiten</a></li>

																																										<li id="t-specialpages"><a href="/wiki/Spezial:Spezialseiten" title="Liste aller Spezialseiten [q]" accesskey="q">Spezialseiten</a></li>
											<li id="t-permalink"><a href="/w/index.php?title=Ralf_Isau&amp;oldid=80621898" title="Dauerhafter Link zu dieser Seitenversion">Permanenter Link</a></li>
				<li id="t-cite"><a href="/w/index.php?title=Spezial:Zitierhilfe&amp;page=Ralf_Isau&amp;id=80621898" title="Hinweis, wie diese Seite zitiert werden kann">Seite zitieren</a></li>		</ul>
	</div>
</div>

<!-- /TOOLBOX -->

<!-- LANGUAGES -->

<div class="portal" id="p-lang">
	<h5>In anderen Sprachen</h5>
	<div class="body">
		<ul>
					<li class="interwiki-en"><a href="http://en.wikipedia.org/wiki/Ralf_Isau" title="Ralf Isau">English</a></li>
					<li class="interwiki-es"><a href="http://es.wikipedia.org/wiki/Ralf_Isau" title="Ralf Isau">Español</a></li>
					<li class="interwiki-fr"><a href="http://fr.wikipedia.org/wiki/Ralf_Isau" title="Ralf Isau">Français</a></li>

					<li class="interwiki-ja"><a href="http://ja.wikipedia.org/wiki/%E3%83%A9%E3%83%AB%E3%83%95%E3%83%BB%E3%82%A4%E3%83%BC%E3%82%B6%E3%82%A6" title="ラルフ・イーザウ">日本語</a></li>
					<li class="interwiki-no"><a href="http://no.wikipedia.org/wiki/Ralf_Isau" title="Ralf Isau">‪Norsk (bokmål)‬</a></li>
				</ul>
	</div>
</div>

<!-- /LANGUAGES -->
			</div>
		<!-- /panel -->

		<!-- footer -->
		<div id="footer">
											<ul id="footer-info">
																	<li id="footer-info-lastmod"> Diese Seite wurde zuletzt am 23. Oktober 2010 um 12:27 Uhr geändert.</li>
																							<li id="footer-info-copyright">Der Text ist unter der Lizenz <a class='internal' href="http://de.wikipedia.org/wiki/Wikipedia:Lizenzbestimmungen_Commons_Attribution-ShareAlike_3.0_Unported">„Creative Commons Attribution/Share Alike“</a> verfügbar; zusätzliche Bedingungen können anwendbar sein.
Einzelheiten sind in den <a class='internal' href="http://wikimediafoundation.org/wiki/Nutzungsbedingungen">Nutzungsbedingungen</a> beschrieben.<br />

Wikipedia® ist eine eingetragene Marke der Wikimedia Foundation Inc.<br /></li>
															</ul>
															<ul id="footer-places">
																	<li id="footer-places-privacy"><a href="/wiki/Wikipedia:Datenschutz" title="Wikipedia:Datenschutz">Datenschutz</a></li>
																							<li id="footer-places-about"><a href="/wiki/Wikipedia:%C3%9Cber_Wikipedia" title="Wikipedia:Über Wikipedia">Über Wikipedia</a></li>
																							<li id="footer-places-disclaimer"><a href="/wiki/Wikipedia:Impressum" title="Wikipedia:Impressum">Impressum</a></li>
															</ul>

											<ul id="footer-icons" class="noprint">
					<li id="footer-copyrightico">
						<a href="http://wikimediafoundation.org/"><img src="/images/wikimedia-button.png" width="88" height="31" alt="Wikimedia Foundation"/></a>
					</li>
					<li id="footer-poweredbyico">
						<a href="http://www.mediawiki.org/"><img src="http://bits.wikimedia.org/skins-1.17/common/images/poweredby_mediawiki_88x31.png" alt="Powered by MediaWiki" width="88" height="31" /></a>
					</li>
				</ul>
						<div style="clear:both"></div>

		</div>
		<!-- /footer -->
		
<script src="http://bits.wikimedia.org/de.wikipedia.org/load.php?debug=false&amp;lang=de&amp;modules=startup&amp;only=scripts&amp;skin=vector" type="text/javascript"></script>
<script type="text/javascript">if ( window.mediaWiki ) {
	mediaWiki.config.set({"wgCanonicalNamespace": "", "wgCanonicalSpecialPageName": false, "wgNamespaceNumber": 0, "wgPageName": "Ralf_Isau", "wgTitle": "Ralf Isau", "wgAction": "view", "wgArticleId": 181099, "wgIsArticle": true, "wgUserName": null, "wgUserGroups": ["*"], "wgCurRevisionId": 80621898, "wgCategories": ["Autor", "Literatur (20. Jahrhundert)", "Literatur (Deutsch)", "Kinder- und Jugendliteratur", "Fantasyliteratur", "Deutscher", "Geboren 1956", "Mann"], "wgBreakFrames": false, "wgRestrictionEdit": [], "wgRestrictionMove": [], "wgSearchNamespaces": [0], "wgFlaggedRevsParams": {"tags": {"accuracy": {"levels": 1, "quality": 2, "pristine": 4}}}, "wgStableRevisionId": 80621898, "wgRevContents": {"error": "Konnte keinen Inhalt empfangen.", "waiting": "Warte auf Inhalt"}, "wgWikimediaMobileUrl": "http://de.m.wikipedia.org/wiki", "wgVectorEnabledModules": {"collapsiblenav": true, "collapsibletabs": true, "editwarning": true, "expandablesearch": false, "footercleanup": false, "sectioneditlinks": false, "simplesearch": true, "experiments": true}, "wgWikiEditorEnabledModules": {"toolbar": true, "dialogs": true, "templateEditor": false, "templates": false, "addMediaWizard": false, "preview": false, "previewDialog": false, "publish": false, "toc": false}, "Geo": {"city": "", "country": ""}, "wgNoticeProject": "wikipedia"});
}
</script>
<script type="text/javascript">if ( window.mediaWiki ) {
	mediaWiki.loader.load(["mediawiki.legacy.wikibits", "mediawiki.util", "mediawiki.legacy.ajax", "mediawiki.legacy.mwsuggest", "ext.vector.collapsibleNav", "ext.vector.collapsibleTabs", "ext.vector.editWarning", "ext.vector.simpleSearch"]);
	mediaWiki.loader.go();
}
</script>

<script src="http://bits.wikimedia.org/w/extensions-1.17/FlaggedRevs/client/flaggedrevs.js?87&amp;301-2" type="text/javascript"></script>
<script type="text/javascript">
FlaggedRevs.messages = {"diffToggleShow": "Änderungen anzeigen", "diffToggleHide": "Änderungen verstecken", "logToggleShow": "zeige das Logbuch der stabilen Versionen", "logToggleHide": "zeige nicht das Logbuch der stabilen Versionen", "logDetailsShow": "Details anzeigen", "logDetailsHide": "Details ausblenden", "toggleShow": "(+)", "toggleHide": "(-)"};
</script>
<script src="/w/index.php?title=Spezial:BannerController&amp;cache=/cn.js&amp;301-2" type="text/javascript"></script>

<script src="http://bits.wikimedia.org/de.wikipedia.org/load.php?debug=false&amp;lang=de&amp;modules=site&amp;only=scripts&amp;skin=vector" type="text/javascript"></script>
<script type="text/javascript">if ( window.mediaWiki ) {
	mediaWiki.user.options.set({"ccmeonemails":0,"cols":80,"contextchars":50,"contextlines":5,"date":"default","diffonly":0,"disablemail":0,"disablesuggest":0,"editfont":"default","editondblclick":0,"editsection":1,"editsectiononrightclick":0,"enotifminoredits":0,"enotifrevealaddr":0,"enotifusertalkpages":1,"enotifwatchlistpages":0,"extendwatchlist":0,"externaldiff":0,"externaleditor":0,"fancysig":0,"forceeditsummary":0,"gender":"unknown","hideminor":0,"hidepatrolled":0,"highlightbroken":1,"imagesize":2,"justify":0,"math":1,"minordefault":0,"newpageshidepatrolled":0,"nocache":0,"noconvertlink":0,"norollbackdiff":0,"numberheadings":0,"previewonfirst":0,"previewontop":1,"quickbar":1,"rcdays":7,"rclimit":50,"rememberpassword":0,"rows":25,"searchlimit":20,"showhiddencats":0,"showjumplinks":1,"shownumberswatching":1,"showtoc":1,"showtoolbar":1,"skin":"vector","stubthreshold":0,"thumbsize":4,"underline":2,"uselivepreview":0,"usenewrc":0,"watchcreations":1,"watchdefault":0,"watchdeletion":0,
	"watchlistdays":"3","watchlisthideanons":0,"watchlisthidebots":0,"watchlisthideliu":0,"watchlisthideminor":0,"watchlisthideown":0,"watchlisthidepatrolled":0,"watchmoves":0,"wllimit":250,"flaggedrevssimpleui":1,"flaggedrevsstable":false,"flaggedrevseditdiffs":true,"flaggedrevsviewdiffs":false,"vector-simplesearch":1,"useeditwarning":1,"vector-collapsiblenav":1,"usebetatoolbar":1,"usebetatoolbar-cgd":1,"variant":"de","language":"de","searchNs0":true,"searchNs1":false,"searchNs2":false,"searchNs3":false,"searchNs4":false,"searchNs5":false,"searchNs6":false,"searchNs7":false,"searchNs8":false,"searchNs9":false,"searchNs10":false,"searchNs11":false,"searchNs12":false,"searchNs13":false,"searchNs14":false,"searchNs15":false,"searchNs100":false,"searchNs101":false});;mediaWiki.loader.state({"user.options":"ready"});
	
	/* cache key: dewiki:resourceloader:filter:minify-js:5:21582a6d47708ed60439e5fdf9ead5e4 */
}
</script><script type="text/javascript" src="http://geoiplookup.wikimedia.org/"></script>		<!-- fixalpha -->
		<script type="text/javascript"> if ( window.isMSIE55 ) fixalpha(); </script>
		<!-- /fixalpha -->
		<!-- Served by srv246 in 0.230 secs. -->			</body>
</html>

