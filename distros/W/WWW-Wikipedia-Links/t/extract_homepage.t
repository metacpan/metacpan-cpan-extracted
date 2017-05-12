use lib 'lib';
use Test::More tests => 1;
use WWW::Wikipedia::Links;
use Mojo::DOM;
use utf8;
use strict;
use warnings;

my $html = do { local $/; <DATA> };
my $dom = Mojo::DOM->new->parse($html);

my $res = WWW::Wikipedia::Links::_extract_from_dom($dom);
is $res->{official_website}, 'http://www.cgpublishing.com',
        'extracted official homepage from vcard';

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html lang="en" dir="ltr" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Apogee Books - Wikipedia, the free encyclopedia</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="generator" content="MediaWiki 1.17wmf1" />
<link rel="alternate" type="application/x-wiki" title="Edit this page" href="/w/index.php?title=Apogee_Books&amp;action=edit" />
<link rel="edit" title="Edit this page" href="/w/index.php?title=Apogee_Books&amp;action=edit" />
<link rel="apple-touch-icon" href="http://en.wikipedia.org/apple-touch-icon.png" />
<link rel="shortcut icon" href="/favicon.ico" />
<link rel="search" type="application/opensearchdescription+xml" href="/w/opensearch_desc.php" title="Wikipedia (en)" />
<link rel="EditURI" type="application/rsd+xml" href="http://en.wikipedia.org/w/api.php?action=rsd" />
<link rel="copyright" href="http://creativecommons.org/licenses/by-sa/3.0/" />
<link rel="alternate" type="application/atom+xml" title="Wikipedia Atom feed" href="/w/index.php?title=Special:RecentChanges&amp;feed=atom" />
<link rel="stylesheet" href="http://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&amp;lang=en&amp;modules=mediawiki%21legacy%21commonPrint%7Cmediawiki%21legacy%21shared%7Cskins%21vector&amp;only=styles&amp;skin=vector" type="text/css" media="all" />

<meta name="ResourceLoaderDynamicStyles" content="" /><link rel="stylesheet" href="http://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&amp;lang=en&amp;modules=site&amp;only=styles&amp;skin=vector" type="text/css" media="all" />
<style type="text/css" media="all">a.new,#quickbar a.new{color:#ba0000}

/* cache key: enwiki:resourceloader:filter:minify-css:5:f2a9127573a22335c2a9102b208c73e7 */</style>
<script type="text/javascript">wgNamespaceNumber=0;wgAction="view";wgPageName="Apogee_Books";wgMainPageTitle="Main Page";wgWikimediaMobileUrl="http:\/\/en.m.wikipedia.org\/wiki";</script><script src="http://bits.wikimedia.org/w/extensions-1.17/WikimediaMobile/MobileRedirect.js?8.2" type="text/javascript"></script><!--[if lt IE 7]><style type="text/css">body{behavior:url("/w/skins-1.17/vector/csshover.min.htc")}</style><![endif]--></head>
<body class="mediawiki ltr ns-0 ns-subject page-Apogee_Books skin-vector">
		<div id="mw-page-base" class="noprint"></div>
		<div id="mw-head-base" class="noprint"></div>
		<!-- content -->
		<div id="content">
			<a id="top"></a>

			<div id="mw-js-message" style="display:none;"></div>
						<!-- sitenotice -->
			<div id="siteNotice"><!-- centralNotice loads here --><script type="text/javascript">
/* <![CDATA[ */
document.writeln("\x3cdiv id=\"localNotice\"\x3e\x3cp\x3e\x3c/p\x3e\n\x3c/div\x3e");
/* ]]> */
</script></div>
			<!-- /sitenotice -->
						<!-- firstHeading -->
			<h1 id="firstHeading" class="firstHeading">Apogee Books</h1>
			<!-- /firstHeading -->
			<!-- bodyContent -->

			<div id="bodyContent">
				<!-- tagline -->
				<div id="siteSub">From Wikipedia, the free encyclopedia</div>
				<!-- /tagline -->
				<!-- subtitle -->
				<div id="contentSub"></div>
				<!-- /subtitle -->
																<!-- jumpto -->

				<div id="jump-to-nav">
					Jump to: <a href="#mw-head">navigation</a>,
					<a href="#p-search">search</a>
				</div>
				<!-- /jumpto -->
								<!-- bodytext -->
				<table class="infobox vcard" style="font-size:90%;text-align:left;width:24em;">
<tr style="background:lightblue;">

<th colspan="2" style="font-size:larger;text-align:center;" class="fn org">Apogee Books</th>
</tr>
<tr>
<th><a href="/wiki/Parent_company" title="Parent company">Parent company</a></th>
<td><a href="/wiki/Collector%27s_Guide_Publishing" title="Collector's Guide Publishing">Collector's Guide Publishing</a></td>
</tr>
<tr>
<th>Founded</th>
<td>1998</td>
</tr>
<tr>
<th>Founder</th>

<td><a href="/wiki/Robert_Godwin" title="Robert Godwin">Robert Godwin</a></td>
</tr>
<tr>
<th>Country of origin</th>
<td><a href="/wiki/Canada" title="Canada">Canada</a></td>
</tr>
<tr>
<th>Headquarters location</th>
<td><span class="label"><a href="/wiki/Burlington,_Ontario" title="Burlington, Ontario">Burlington, Ontario</a></span></td>
</tr>
<tr>
<th>Publication types</th>

<td><a href="/wiki/Book" title="Book">Books</a></td>
</tr>
<tr>
<th>Nonfiction topics</th>
<td><a href="/wiki/Space" title="Space">Space</a></td>
</tr>
<tr>
<th><a href="/wiki/Genre" title="Genre">Fiction genres</a></th>
<td><a href="/wiki/Science_Fiction" title="Science Fiction" class="mw-redirect">Science Fiction</a></td>
</tr>
<tr>
<th>Official website</th>

<td><span class="url"><span class="url"><a href="http://www.cgpublishing.com" class="external text" rel="nofollow">cgpublishing.com</a></span></span></td>
</tr>
</table>

            <!-- (stripped) -->

			</div>
			<!-- /bodyContent -->
		</div>
		<!-- /content -->
		<!-- header -->
		<div id="mw-head" class="noprint">
			
<!-- 0 -->
<div id="p-personal" class="">

	<h5>Personal tools</h5>
	<ul>
					<li  id="pt-login"><a href="/w/index.php?title=Special:UserLogin&amp;returnto=Apogee_Books" title="You are encouraged to log in; however, it is not mandatory. [o]" accesskey="o">Log in / create account</a></li>
			</ul>
</div>

<!-- /0 -->
			<div id="left-navigation">
				
<!-- 0 -->

<div id="p-namespaces" class="vectorTabs">
	<h5>Namespaces</h5>
	<ul>
					<li  id="ca-nstab-main" class="selected"><span><a href="/wiki/Apogee_Books"  title="View the content page [c]" accesskey="c">Article</a></span></li>
					<li  id="ca-talk"><span><a href="/wiki/Talk:Apogee_Books"  title="Discussion about the content page [t]" accesskey="t">Discussion</a></span></li>
			</ul>
</div>

<!-- /0 -->

<!-- 1 -->
<div id="p-variants" class="vectorMenu emptyPortlet">
		<h5><span>Variants</span><a href="#"></a></h5>
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
	<h5>Views</h5>
	<ul>
					<li id="ca-view" class="selected"><span><a href="/wiki/Apogee_Books" >Read</a></span></li>
					<li id="ca-edit"><span><a href="/w/index.php?title=Apogee_Books&amp;action=edit"  title="You can edit this page. &#10;Please use the preview button before saving. [e]" accesskey="e">Edit</a></span></li>

					<li id="ca-history" class="collapsible "><span><a href="/w/index.php?title=Apogee_Books&amp;action=history"  title="Past versions of this page [h]" accesskey="h">View history</a></span></li>
			</ul>
</div>

<!-- /0 -->

<!-- 1 -->
<div id="p-cactions" class="vectorMenu emptyPortlet">
	<h5><span>Actions</span><a href="#"></a></h5>
	<div class="menu">
		<ul>

					</ul>
	</div>
</div>

<!-- /1 -->

<!-- 2 -->
<div id="p-search">
	<h5><label for="searchInput">Search</label></h5>
	<form action="/w/index.php" id="searchform">
		<input type='hidden' name="title" value="Special:Search"/>

				<div id="simpleSearch">
						<input id="searchInput" name="search" type="text"  title="Search Wikipedia [f]" accesskey="f"  value="" />
						<button id="searchButton" type='submit' name='button'  title="Search Wikipedia for this text"><img src="http://bits.wikimedia.org/skins-1.17/vector/images/search-ltr.png?301-2" alt="Search" /></button>
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
					<div id="p-logo"><a style="background-image: url(http://upload.wikimedia.org/wikipedia/en/b/bc/Wiki.png);" href="/wiki/Main_Page"  title="Visit the main page"></a></div>
				<!-- /logo -->
				
<!-- navigation -->
<div class="portal" id='p-navigation'>
	<h5>Navigation</h5>

	<div class="body">
				<ul>
					<li id="n-mainpage-description"><a href="/wiki/Main_Page" title="Visit the main page [z]" accesskey="z">Main page</a></li>
					<li id="n-contents"><a href="/wiki/Portal:Contents" title="Guides to browsing Wikipedia">Contents</a></li>
					<li id="n-featuredcontent"><a href="/wiki/Portal:Featured_content" title="Featured content – the best of Wikipedia">Featured content</a></li>
					<li id="n-currentevents"><a href="/wiki/Portal:Current_events" title="Find background information on current events">Current events</a></li>
					<li id="n-randompage"><a href="/wiki/Special:Random" title="Load a random article [x]" accesskey="x">Random article</a></li>

					<li id="n-sitesupport"><a href="http://wikimediafoundation.org/wiki/Special:Landingcheck?landing_page=WMFJA085&amp;language=en&amp;utm_source=donate&amp;utm_medium=sidebar&amp;utm_campaign=20101204SB002" title="Support us">Donate to Wikipedia</a></li>
				</ul>
			</div>
</div>

<!-- /navigation -->

<!-- SEARCH -->

<!-- /SEARCH -->

<!-- interaction -->
<div class="portal" id='p-interaction'>

	<h5>Interaction</h5>
	<div class="body">
				<ul>
					<li id="n-help"><a href="/wiki/Help:Contents" title="Guidance on how to use and edit Wikipedia">Help</a></li>
					<li id="n-aboutsite"><a href="/wiki/Wikipedia:About" title="Find out about Wikipedia">About Wikipedia</a></li>
					<li id="n-portal"><a href="/wiki/Wikipedia:Community_portal" title="About the project, what you can do, where to find things">Community portal</a></li>
					<li id="n-recentchanges"><a href="/wiki/Special:RecentChanges" title="The list of recent changes in the wiki [r]" accesskey="r">Recent changes</a></li>

					<li id="n-contact"><a href="/wiki/Wikipedia:Contact_us" title="How to contact Wikipedia">Contact Wikipedia</a></li>
				</ul>
			</div>
</div>

<!-- /interaction -->

<!-- TOOLBOX -->
<div class="portal" id="p-tb">
	<h5>Toolbox</h5>
	<div class="body">

		<ul>
					<li id="t-whatlinkshere"><a href="/wiki/Special:WhatLinksHere/Apogee_Books" title="List of all English Wikipedia pages containing links to this page [j]" accesskey="j">What links here</a></li>
						<li id="t-recentchangeslinked"><a href="/wiki/Special:RecentChangesLinked/Apogee_Books" title="Recent changes in pages linked from this page [k]" accesskey="k">Related changes</a></li>
																																					<li id="t-upload"><a href="/wiki/Wikipedia:Upload" title="Upload files [u]" accesskey="u">Upload file</a></li>
											<li id="t-specialpages"><a href="/wiki/Special:SpecialPages" title="List of all special pages [q]" accesskey="q">Special pages</a></li>
											<li id="t-permalink"><a href="/w/index.php?title=Apogee_Books&amp;oldid=411882518" title="Permanent link to this revision of the page">Permanent link</a></li>

				<li id="t-cite"><a href="/w/index.php?title=Special:Cite&amp;page=Apogee_Books&amp;id=411882518" title="Information on how to cite this page">Cite this page</a></li>		</ul>
	</div>
</div>

<!-- /TOOLBOX -->

<!-- coll-print_export -->
<div class="portal" id='p-coll-print_export'>
	<h5>Print/export</h5>
	<div class="body">

				<ul id="collectionPortletList"><li id="coll-create_a_book"><a href="/w/index.php?title=Special:Book&amp;bookcmd=book_creator&amp;referer=Apogee+Books" title="Create a book or page collection" rel="nofollow">Create a book</a></li><li id="coll-download-as-rl"><a href="/w/index.php?title=Special:Book&amp;bookcmd=render_article&amp;arttitle=Apogee+Books&amp;oldid=411882518&amp;writer=rl" title="Download a PDF version of this wiki page" rel="nofollow">Download as PDF</a></li><li id="t-print"><a href="/w/index.php?title=Apogee_Books&amp;printable=yes" title="Printable version of this page [p]" accesskey="p">Printable version</a></li></ul>			</div>
</div>

<!-- /coll-print_export -->

<!-- LANGUAGES -->

<!-- /LANGUAGES -->
			</div>
		<!-- /panel -->

		<!-- footer -->
		<div id="footer">
											<ul id="footer-info">
																	<li id="footer-info-lastmod"> This page was last modified on 4 February 2011 at 00:00.<br /></li>
																							<li id="footer-info-copyright">Text is available under the <a rel="license" href="http://en.wikipedia.org/wiki/Wikipedia:Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License">Creative Commons Attribution-ShareAlike License</a><a rel="license" href="http://creativecommons.org/licenses/by-sa/3.0/" style="display:none;"></a>;
additional terms may apply.
See <a href="http://wikimediafoundation.org/wiki/Terms_of_Use">Terms of Use</a> for details.<br/>

Wikipedia&reg; is a registered trademark of the <a href="http://www.wikimediafoundation.org/">Wikimedia Foundation, Inc.</a>, a non-profit organization.<br /></li><li class="noprint"><a class='internal' href="http://en.wikipedia.org/wiki/Wikipedia:Contact_us">Contact us</a></li>
															</ul>
															<ul id="footer-places">
																	<li id="footer-places-privacy"><a href="http://wikimediafoundation.org/wiki/Privacy_policy" title="wikimedia:Privacy policy">Privacy policy</a></li>
																							<li id="footer-places-about"><a href="/wiki/Wikipedia:About" title="Wikipedia:About">About Wikipedia</a></li>

																							<li id="footer-places-disclaimer"><a href="/wiki/Wikipedia:General_disclaimer" title="Wikipedia:General disclaimer">Disclaimers</a></li>
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
		
<script src="http://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&amp;lang=en&amp;modules=startup&amp;only=scripts&amp;skin=vector" type="text/javascript"></script>
<script type="text/javascript">if ( window.mediaWiki ) {
	mediaWiki.config.set({"wgCanonicalNamespace": "", "wgCanonicalSpecialPageName": false, "wgNamespaceNumber": 0, "wgPageName": "Apogee_Books", "wgTitle": "Apogee Books", "wgAction": "view", "wgArticleId": 14010746, "wgIsArticle": true, "wgUserName": null, "wgUserGroups": ["*"], "wgCurRevisionId": 411882518, "wgCategories": ["Book publishing companies of Canada"], "wgBreakFrames": false, "wgRestrictionEdit": [], "wgRestrictionMove": [], "wgSearchNamespaces": [0], "wgFlaggedRevsParams": {"tags": {"status": {"levels": 1, "quality": 2, "pristine": 3}}}, "wgStableRevisionId": null, "wgRevContents": {"error": "Unable to get content.", "waiting": "Waiting for content"}, "wgWikimediaMobileUrl": "http://en.m.wikipedia.org/wiki", "wgVectorEnabledModules": {"collapsiblenav": true, "collapsibletabs": true, "editwarning": true, "expandablesearch": false, "footercleanup": false, "sectioneditlinks": false, "simplesearch": true, "experiments": true}, "wgWikiEditorEnabledModules": {"toolbar": true, "dialogs": true, "templateEditor": false, "templates": false, "addMediaWizard": false, "preview": false, "previewDialog": false, "publish": false, "toc": false}, "wgTrackingToken": "ebf81d0548c75e717cbe2ae617cb5b61", "Geo": {"city": "", "country": ""}, "wgNoticeProject": "wikipedia"});
}
</script>
<script type="text/javascript">if ( window.mediaWiki ) {
	mediaWiki.loader.load(["mediawiki.legacy.wikibits", "mediawiki.util", "mediawiki.legacy.ajax", "mediawiki.legacy.mwsuggest", "ext.vector.collapsibleNav", "ext.vector.collapsibleTabs", "ext.vector.editWarning", "ext.vector.simpleSearch", "ext.UserBuckets", "ext.articleFeedback.startup"]);
	mediaWiki.loader.go();
}
</script>

<script src="/w/index.php?title=Special:BannerController&amp;cache=/cn.js&amp;301-2" type="text/javascript"></script>
<script src="http://bits.wikimedia.org/en.wikipedia.org/load.php?debug=false&amp;lang=en&amp;modules=site&amp;only=scripts&amp;skin=vector" type="text/javascript"></script>
<script type="text/javascript">if ( window.mediaWiki ) {
	mediaWiki.user.options.set({"ccmeonemails":0,"cols":80,"contextchars":50,"contextlines":5,"date":"default","diffonly":0,"disablemail":0,"disablesuggest":0,"editfont":"default","editondblclick":0,"editsection":1,"editsectiononrightclick":0,"enotifminoredits":0,"enotifrevealaddr":0,"enotifusertalkpages":1,"enotifwatchlistpages":0,"extendwatchlist":0,"externaldiff":0,"externaleditor":0,"fancysig":0,"forceeditsummary":0,"gender":"unknown","hideminor":0,"hidepatrolled":0,"highlightbroken":1,"imagesize":2,"justify":0,"math":1,"minordefault":0,"newpageshidepatrolled":0,"nocache":0,"noconvertlink":0,"norollbackdiff":0,"numberheadings":0,"previewonfirst":0,"previewontop":1,"quickbar":1,"rcdays":7,"rclimit":50,"rememberpassword":0,"rows":25,"searchlimit":20,"showhiddencats":0,"showjumplinks":1,"shownumberswatching":1,"showtoc":1,"showtoolbar":1,"skin":"vector","stubthreshold":0,"thumbsize":4,"underline":2,"uselivepreview":0,"usenewrc":0,"watchcreations":1,"watchdefault":0,"watchdeletion":0,
	"watchlistdays":"3","watchlisthideanons":0,"watchlisthidebots":0,"watchlisthideliu":0,"watchlisthideminor":0,"watchlisthideown":0,"watchlisthidepatrolled":0,"watchmoves":0,"wllimit":250,"flaggedrevssimpleui":1,"flaggedrevsstable":false,"flaggedrevseditdiffs":true,"flaggedrevsviewdiffs":false,"vector-simplesearch":1,"useeditwarning":1,"vector-collapsiblenav":1,"usebetatoolbar":1,"usebetatoolbar-cgd":1,"variant":"en","language":"en","searchNs0":true,"searchNs1":false,"searchNs2":false,"searchNs3":false,"searchNs4":false,"searchNs5":false,"searchNs6":false,"searchNs7":false,"searchNs8":false,"searchNs9":false,"searchNs10":false,"searchNs11":false,"searchNs12":false,"searchNs13":false,"searchNs14":false,"searchNs15":false,"searchNs100":false,"searchNs101":false,"searchNs108":false,"searchNs109":false});;mediaWiki.loader.state({"user.options":"ready"});
	
	/* cache key: enwiki:resourceloader:filter:minify-js:5:27c920e3d777c540f5f38bf4516bf8fd */
}
</script><script type="text/javascript" src="http://geoiplookup.wikimedia.org/"></script>		<!-- fixalpha -->
		<script type="text/javascript"> if ( window.isMSIE55 ) fixalpha(); </script>
		<!-- /fixalpha -->
		<!-- Served by srv208 in 0.495 secs. -->			</body>

</html>

