# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl XML-Crawler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN { use_ok('XML::Crawler') };

#########################

# test 0
{
    my $xml = <<'END_XML';
END_XML

    xml_to_ra_ok( $xml, undef, 'null XML document' );
}

# test 1
{
    my $xml = <<'END_XML';
<?xml version="1.0"?>
END_XML

    xml_to_ra_ok( $xml, undef, 'null XML document' );
}

# test 2.a
{
    my $xml = <<'END_XML';
<?xml version="1.0"?>
<fruit type="banana">yellow</fruit>
END_XML

    my @expect = (
        '#document' => [
            [ 'fruit' => { 'type' => 'banana' } => 'yellow' ]
        ]
    );

    xml_to_ra_ok( $xml, \@expect, 'very small XML document' );
}

# test 2
{
    my $xml = <<'END_XML';
<?xml version="1.0"?>
<contact-info>
  <name>Jane Smith</name>
  <company>AT&amp;T</company>
  <phone>(212) 555-4567</phone>
</contact-info>
END_XML

    my @expect = (
        '#document' => [ [
                'contact-info' => [
                    [ 'name'    => 'Jane Smith' ],
                    [ 'company' => 'AT&T' ],
                    [ 'phone'   => '(212) 555-4567' ],
                ],
            ],
        ],
    );

    xml_to_ra_ok( $xml, \@expect, 'small XML document' );
}

# test 3
{
    my $xml = <<'END_XML';
<?xml version="1.0"?>
<root>
  <data>
    <row>
      <cell>Name</cell>
      <cell>Fruit</cell>
      <cell>Vegetable</cell>
    </row>
    <row>
      <cell>Captain</cell>
      <cell>Banana</cell>
      <cell>Zucchini</cell>
    </row>
    <row>
      <cell>Admiral</cell>
      <cell>Melon</cell>
      <cell>Carrot</cell>
    </row>
    <row>
      <cell>Midshipman</cell>
      <cell>Orange</cell>
      <cell>Potatoe</cell>
    </row>
  </data>
</root>
END_XML

    my @expect = (
        '#document' => [ [
                'root' => [ [
                        'data' => [ [
                                'row' => [
                                    [ 'cell' => 'Name' ],
                                    [ 'cell' => 'Fruit' ],
                                    [ 'cell' => 'Vegetable' ],
                                ],
                            ],
                            [
                                'row' => [
                                    [ 'cell' => 'Captain' ],
                                    [ 'cell' => 'Banana' ],
                                    [ 'cell' => 'Zucchini' ],
                                ],
                            ],
                            [
                                'row' => [
                                    [ 'cell' => 'Admiral' ],
                                    [ 'cell' => 'Melon' ],
                                    [ 'cell' => 'Carrot' ],
                                ],
                            ],
                            [
                                'row' => [
                                    [ 'cell' => 'Midshipman' ],
                                    [ 'cell' => 'Orange' ],
                                    [ 'cell' => 'Potatoe' ],
                                ],
                            ],
                        ],
                    ],
                ],
            ],
        ],
    );

    xml_to_ra_ok( $xml, \@expect, 'not so small XML document' );
}

# test
{
    my $xml = <<'END_XML';
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<!-- Generated from data/head-home.php, ../../smarty/{head.tpl} -->
<head>
<title>World Wide Web Consortium (W3C)</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="Help" href="/Help/" />
<link rel="stylesheet" href="/2008/site/css/minimum" type="text/css" media="handheld, all" />
<style type="text/css" media="print, screen and (min-width: 481px)">
/*<![CDATA[*/
@import url("/2008/site/css/advanced");
/*]]>*/
</style>
<link href="/2008/site/css/minimum" rel="stylesheet" type="text/css" media="handheld, only screen and (max-device-width: 480px)" />
<meta name="viewport" content="width=device-width" />
<link rel="stylesheet" href="/2008/site/css/print" type="text/css" media="print" />
<link rel="shortcut icon" href="/2008/site/images/favicon.ico" type="image/x-icon" />
<meta name="description" content="The World Wide Web Consortium (W3C) is an international community where Member organizations, a full-time staff, and the public work together to develop Web standards." />
<link rel="alternate" type="application/atom+xml" title="W3C News" href="/News/atom.xml" />
</head>
<body id="www-w3-org" class="w3c_public w3c_home">
<div id="w3c_container">
<!-- Generated from data/mast-home.php, ../../smarty/{mast.tpl} -->
<div id="w3c_mast"><!-- #w3c_mast / Page top header -->
<h1 class="logo"><a tabindex="2" accesskey="1" href="/"><img src="/2008/site/images/logo-w3c-mobile-lg" width="90" height="53" alt="W3C" /></a> <span class="alt-logo">W3C</span></h1>
<div id="w3c_nav">
<form id="region_form" action="http://www.w3.org/Consortium/contact">
<div><select name="region">
<option selected="selected" value="W3C By Region">W3C By
Region</option>
<option value="all">All</option>
<option value="au">Australia</option>
<option xml:lang="de" lang="de" value="de">&#xD6;sterreich
(Austria)</option>
<option lang="nl" xml:lang="nl" value="nl">Belgi&#xEB;
(Belgium)</option>
<option value="za">Botswana</option>
<option xml:lang="pt-br" value="br" lang="pt-br">Brasil
(Brazil)</option>
<option xml:lang="zh-hans" value="cn" lang="zh-hans">&#x4E2D;&#x56FD;
(China)</option>
<option xml:lang="fi" value="fi" lang="fi">Suomi (Finland)</option>
<option xml:lang="de" value="de" lang="de">Deutschland
(Germany)</option>
<option xml:lang="el" value="gr" lang="el">&#x395;&#x3BB;&#x3BB;&#x3AC;&#x3B4;&#x3B1; (Greece)</option>
<option xml:lang="hu" value="hu" lang="hu">Magyarorsz&#xE1;g
(Hungary)</option>
<option xml:lang="hi" value="in" lang="hi">&#x92D;&#x93E;&#x930;&#x924; (India)</option>
<option xml:lang="ga" lang="ga" value="gb">&#xC9;ire (Ireland)</option>
<option xml:lang="he" value="il" lang="he">&#x5D9;&#x5E9;&#x5E8;&#x5D0;&#x5DC; (Israel)</option>
<option xml:lang="it" value="it" lang="it">Italia (Italy)</option>
<option xml:lang="ko" value="kr" lang="ko">&#xD55C;&#xAD6D; (Korea)</option>
<option value="za">Lesotho</option>
<option lang="lb" xml:lang="lb" value="nl">L&#xEB;tzebuerg
(Luxembourg)</option>
<option xml:lang="ar" value="ma" lang="ar">&#x627;&#x644;&#x645;&#x63A;&#x631;&#x628;
(Morocco)</option>
<option value="za">Namibia</option>
<option lang="nl" xml:lang="nl" value="nl">Nederland
(Netherlands)</option>
<option xml:lang="fr" value="sn" lang="fr">S&#xE9;n&#xE9;gal</option>
<option xml:lang="es" value="es" lang="es">Espa&#xF1;a (Spain)</option>
<option value="za">South Africa</option>
<option lang="ss" xml:lang="ss" value="za">Swatini
(Swaziland)</option>
<option xml:lang="sv" value="se" lang="sv">Sverige
(Sweden)</option>
<option value="gb">United Kingdom</option>
</select> <input class="button" type="submit" value="Go" /></div>
</form>
<form action="http://www.w3.org/Help/search" method="get" enctype="application/x-www-form-urlencoded">
<!-- w3c_sec_nav is populated through js -->
<div class="w3c_sec_nav"><!-- --></div>
<ul class="main_nav"><!-- Main navigation menu -->
<li class="first-item"><a href="/standards/">Standards</a></li>
<li><a href="/participate/">Participate</a></li>
<li><a href="/Consortium/membership">Membership</a></li>
<li class="last-item"><a href="/Consortium/">About W3C</a></li>
<li class="search-item">
<div id="search-form"><input tabindex="3" class="text" name="q" value="" title="Search" /> <button id="search-submit" name="search-submit" type="submit"><img class="submit" src="/2008/site/images/search-button" alt="Search" width="21" height="17" /></button></div>
</li>
</ul>
</form>
</div>
</div>
<!-- /end #w3c_mast -->
<div id="w3c_main">
<div id="w3c_logo_shadow" class="w3c_leftCol"><img height="32" alt="" src="/2008/site/images/logo-shadow" /></div>
<div class="w3c_leftCol">
<h2 class="offscreen">Site Navigation</h2>
<h3 class="category"><span class="ribbon"><a href="/standards/">Standards <img src="/2008/site/images/header-link.gif" alt="Header link" width="13" height="13" class="header-link" /></a></span></h3>
<ul class="theme">
<li class="design"><a href="/standards/webdesign/" title="HTML5, XHTML, and CSS, Scripting and Ajax, Web Applications, Graphics, Accessibility">
<span class="icon"><!-- --></span>Web Design and
Applications</a></li>
<li class="arch"><a href="/standards/webarch/" title="Architecture Principles, Identifiers, Protocols, Meta Formats"><span class="icon">
<!-- --></span>Web Architecture</a></li>
<li class="semantics"><a href="/standards/semanticweb/" title="Data, Ontologies, Query, Linked Data"><span class="icon">
<!-- --></span>Semantic Web</a></li>
<li class="xml"><a href="/standards/xml/" title="XML Essentials, Semantic Additions to XML, Schema, Security"><span class="icon">
<!-- --></span>XML Technology</a></li>
<li class="services"><a href="/standards/webofservices/" title="Data, Protocols, Service Description, Security"><span class="icon"><!-- --></span>Web of Services</a></li>
<li class="devices"><a href="/standards/webofdevices/" title="Voice Browsing, Device Independence and Content Negotation, Multimodal Access, Printing">
<span class="icon"><!-- --></span>Web of Devices</a></li>
<li class="browsers"><a href="/standards/agents/" title="Browsers and User Agents, Authoring Tools, Web Servers"><span class="icon">
<!-- --></span>Browsers and Authoring Tools</a></li>
<li class="allspecs"><a href="/TR/"><span class="icon">
<!-- --></span>&#x2026; or view all</a></li>
</ul>
<h3 class="category tMargin"><span class="ribbon"><a href="Consortium/mission.html#principles">Web for All <img src="/2008/site/images/header-link.gif" alt="Header link" width="13" height="13" class="header-link" /></a></span></h3>
<ul class="theme">
<li><a title="Popular links to W3C technology information" href="Consortium/siteindex.html#technologies">W3C
A&#xA0;to&#xA0;Z</a></li>
<li><a href="/WAI/">Accessibility</a></li>
<li><a href="/International/">Internationalization</a></li>
<li><a href="/Mobile/">Mobile Web</a></li>
<li><a href="/2007/eGov/">eGovernment</a></li>
<li><a href="/2008/MW4D/">Developing Economies</a></li>
</ul>
<h3 class="category tMargin"><span class="ribbon"><a href="Consortium/activities">W3C Groups <img src="/2008/site/images/header-link.gif" alt="Header link" width="13" height="13" class="header-link" /></a></span></h3>
<ul class="theme">
<li><a href="/TR/tr-groups-all">Specifications by group</a></li>
<li><a title="Member-only group participant guidebook" href="/Guide/">Participant guidebook</a></li>
</ul>
</div>
<div class="w3c_mainCol">
<div id="w3c_crumbs">
<div id="w3c_crumbs_frame">
<p class="bct"><span class="skip"><a tabindex="1" accesskey="2" title="Skip to content (e.g., when browsing via audio)" href="#w3c_most-recently">Skip</a></span></p>
<br /></div>
</div>
<div class="line">
<div class="unit size2on3">
<div class="main-content">
<h2 class="offscreen">News</h2>
<div id="w3c_slideshow"><div id="w3c_most-recently" class="intro hierarchy vevent_list">

<div class="event w3c_topstory expand_block">
  <div class="headline">
 <h3 class="h4 tPadding0 bPadding0 summary">
  <span class="expand_section">W3C Releases Unicorn, an All-in-One Validator </span>
</h3>
  <p class="date"><span class="dtstart published" title="2010-07-27T08:46:08-05:00">27 July 2010</span>
  | <a title="Archive: W3C Releases Unicorn, an All-in-One Validator " href="/News/2010#entry-8862">Archive</a>
</p>
</div>
 <div class="description expand_description">
    <p>W3C is pleased to announce the release of <a href="http://validator.w3.org/unicorn/">Unicorn</a>, a one-stop tool to help people improve the quality of their Web pages. Unicorn combines a number of popular tools in a single, easy interface, including the <a href="http://validator.w3.org/">Markup validator</a>, <a href="http://jigsaw.w3.org/css-validator/">CSS validator</a>, <a href="http://validator.w3.org/mobile/">mobileOk checker</a>, and <a href="http://validator.w3.org/feed/">Feed validator</a>, which remain available as individual services as well. W3C invites developers to enhance the service by <a href="http://code.w3.org/unicorn/wiki/Documentation/Observer">creating new modules</a> and testing them in our <a href="http://code.w3.org/unicorn/wiki#DevelopUnicornandValidationServices">online developer space</a> (or <a href="http://code.w3.org/unicorn/wiki/Documentation/Install">installing Unicorn locally</a>). W3C looks forward to code contributions from the community as well as <a href="http://code.w3.org/unicorn/wiki#Feedback">suggestions for new features</a>. W3C would like to thank the many people whose work has led up to this first release of Unicorn. This includes developers  who started and improved the tool over the past few years, users who have provided feedback, <a href="http://code.w3.org/unicorn/wiki/Translators">translators</a> who have helped localize the interface with  <a href="http://validator.w3.org/unicorn/translations">21 translations</a> so far, and sponsors HP and Mozilla and other individual donors. W3C welcomes <a href="http://code.w3.org/unicorn/wiki#Feedback">feedback</a> and <a href="http://www.w3.org/QA/Tools/Donate">donations</a> so that W3C can continue to expand this free service to the community. Learn more about <a href="http://www.w3.org/Status">W3C open source software</a>.
</p>

 </div>
</div>


<div class="event closed expand_block">
   <div class="headline">
    <h3 class="h4 tPadding0 bPadding0 summary"><span class="expand_section">W3C Invites Implementations of XMLHttpRequest </span></h3>
    <p class="date"><span class="published dtstart" title="2010-08-03T11:03:04-05:00">03 August 2010</span>
  | <a title="Archived: W3C Invites Implementations of XMLHttpRequest " href="/News/2010#entry-8871">Archive</a>
    </p>
</div>
    <div class="description expand_description">
      <p>The <a href="http://www.w3.org/2008/webapps/">Web Applications Working Group</a> invites implementation of the Candidate Recommendation of <a href="http://www.w3.org/TR/2010/CR-XMLHttpRequest-20100803/">XMLHttpRequest</a>. The XMLHttpRequest specification defines an API that provides scripted client functionality for transferring data between a client and a server. Learn more about the <a href="http://www.w3.org/2006/rwc/">Rich Web Client Activity</a>.</p>
    </div>
</div>

<div class="event closed expand_block">
   <div class="headline">
    <h3 class="h4 tPadding0 bPadding0 summary"><span class="expand_section">Drafts of RDFa Core 1.1 and XHTML+RDFa 1.1 Published</span></h3>
    <p class="date"><span class="published dtstart" title="2010-08-03T09:46:23-05:00">03 August 2010</span>
  | <a title="Archived: Drafts of RDFa Core 1.1 and XHTML+RDFa 1.1 Published" href="/News/2010#entry-8870">Archive</a>
    </p>
</div>
    <div class="description expand_description">
      <p>The <a href="http://www.w3.org/2010/02/rdfa/">RDFa Working Group</a> has just published two Working Drafts: <a href="http://www.w3.org/2010/02/rdfa/drafts/2010/WD-rdfa-core-20100803/">RDFa Core 1.1</a> and <a href="http://www.w3.org/TR/2010/WD-xhtml-rdfa-20100803/">XHTML+RDFa 1.1</a>. RDFa Core 1.1 is a specification for attributes to express structured data in any markup language. The embedded data already available in the markup language (e.g., XHTML) is reused by the RDFa markup, so that publishers don't need to repeat significant data in the document content. XHTML+RDFa 1.1 is an XHTML family markup language. That extends the XHTML 1.1 markup language with the attributes defined in RDFa Core 1.1. This document is intended for authors who want to create XHTML-Family documents that embed rich semantic markup. Learn more about the <a href="http://www.w3.org/2001/sw/">Semantic Web Activity</a>. </p>
    </div>
</div>

<div class="event closed expand_block">
   <div class="headline">
    <h3 class="h4 tPadding0 bPadding0 summary"><span class="expand_section">XHTML Modularization 1.1 - Second Edition is a W3C Recommendation</span></h3>
    <p class="date"><span class="published dtstart" title="2010-07-29T15:44:03-05:00">29 July 2010</span>
  | <a title="Archived: XHTML Modularization 1.1 - Second Edition is a W3C Recommendation" href="/News/2010#entry-8868">Archive</a>
    </p>
</div>
    <div class="description expand_description">
      <p>The <a href="/MarkUp/">XHTML2 Working Group</a> has published a W3C Recommendation of <a href="/TR/2010/REC-xhtml-modularization-20100729/">XHTML Modularization 1.1 - Second Edition</a>. XHTML Modularization is a tool for people who design markup languages. XHTML Modularization helps people design and manage markup language schemas and DTDs; it explains how to write schemas that will plug together. Modules can be reused and recombined across different languages, which helps keep related languages in sync. This edition includes several minor updates to provide clarifications and address errors found in version 1.1. Learn more about the <a href="/MarkUp/Activity">HTML Activity</a>.</p>
    </div>
</div>

<div class="event closed expand_block">
   <div class="headline">
    <h3 class="h4 tPadding0 bPadding0 summary"><span class="expand_section">Draft of Emotion Markup Language (EmotionML) 1.0  Published</span></h3>
    <p class="date"><span class="published dtstart" title="2010-07-29T15:36:45-05:00">29 July 2010</span>
  | <a title="Archived: Draft of Emotion Markup Language (EmotionML) 1.0  Published" href="/News/2010#entry-8867">Archive</a>
    </p>
</div>
    <div class="description expand_description">
      <p>The <a href="/2002/mmi/">Multimodal Interaction Working Group</a> has published a Working Draft of <a href="/TR/2010/WD-emotionml-20100729/">Emotion Markup Language (EmotionML) 1.0</a>. As the web is becoming ubiquitous, interactive, and multimodal, technology needs to deal increasingly with human factors, including emotions. The present draft specification of Emotion Markup Language 1.0 aims to strike a balance between practical applicability and basis in science. The language is conceived as a "plug-in" language suitable for use in three different areas: (1) manual annotation of data; (2) automatic recognition of emotion-related states from user behavior; and (3) generation of emotion-related system behavior. Learn more about the <a href="/2002/mmi/">Multimodal Interaction Activity</a>.</p>
    </div>
</div>

<div class="event closed expand_block">
   <div class="headline">
    <h3 class="h4 tPadding0 bPadding0 summary"><span class="expand_section">Cross-Origin Resource Sharing Draft Published</span></h3>
    <p class="date"><span class="published dtstart" title="2010-07-27T12:56:43-05:00">27 July 2010</span>
  | <a title="Archived: Cross-Origin Resource Sharing Draft Published" href="/News/2010#entry-8863">Archive</a>
    </p>
</div>
    <div class="description expand_description">
      <p>The <a href="/2008/webapps/">Web Applications Working Group</a> has published a Working Draft of <a href="/TR/2010/WD-cors-20100727/">Cross-Origin Resource Sharing</a>. User agents commonly apply same-origin restrictions to network requests. These restrictions prevent a client-side Web application running from one origin from obtaining data retrieved from another origin, and also limit unsafe HTTP requests that can be automatically launched toward destinations that differ from the running application's origin. In user agents that follow this pattern, network requests typically use ambient authentication and session management information, including HTTP authentication and cookie information. This specification extends this model in a number of ways.Learn more about the <a href="/2006/rwc/">Rich Web Client Activity</a>.</p>
    </div>
</div>

</div></div>
<p class="noprint"><span class="more-news"><a href="/News/archive" title="More News">More news&#x2026;</a> <a title="RSS feed for W3C home page news" href="/News/news.rss" class="feedlink"><img width="30" height="30" alt="RSS" src="/2008/site/images/icons/rss30" /></a> <a title="Atom feed for W3C home page news" href="/News/atom.xml" class="feedlink"><img width="30" height="30" alt="Atom" src="/2008/site/images/icons/atom30" /></a></span></p>
<div class="w3c_events_talks">
<div class="line">
<div class="unit size1on2">
<div id="w3c_home_talks" class="w3c_upcoming_talks"><h2 class="category"><a title="More Talks&#x2026;" href="/Talks/">
          Talks and Appearances
          <img src="/2008/site/images/header-link" alt="Header link" width="13" height="13" class="header-link" /></a></h2><ul class="vevent_list"><li class="vevent"><p class="date single"><span class="dtstart"><span class="year">2010</span><span class="mm-dd">-08-30</span></span> <span class="paren">(</span><span class="dd-mmm">30 AUG</span><span class="paren">)</span></p><div class="info-wrap"><p class="summary">GUI Frameworks for Web Applications </p><p class="source">Mohamed ZERGAOUI</p><p class="eventtitle"><a href="http://www.w3.org/2004/08/TalkFiles/2010/svgopen.org" class="uri">SVG Open 2010</a></p><p class="location">Paris,
      France</p></div></li><li class="vevent"><p class="date single"><span class="dtstart"><span class="year">2010</span><span class="mm-dd">-09-01</span></span> <span class="paren">(</span><span class="dd-mmm">1 SEP</span><span class="paren">)</span></p><div class="info-wrap"><p class="summary">All Good Things Come in Threes: A Tale of Three Screens</p><p class="source"> by Alex Danilo</p><p class="eventtitle"><a href="http://svgopen.org" class="uri">SVG Open 2010</a></p><p class="location">Paris,
      France</p></div></li><li class="vevent"><p class="date single"><span class="dtstart"><span class="year">2010</span><span class="mm-dd">-09-10</span></span> <span class="paren">(</span><span class="dd-mmm">10 SEP</span><span class="paren">)</span></p><div class="info-wrap"><p class="summary"><a href="http://is.gd/daqSR">Implementing WCAG 2.0 </a></p><p class="source"> by Michael Cooper</p><p class="eventtitle">Citizens With Disabilities - Ontario</p><p class="location">Ontario,
      Canada</p></div></li><li class="vevent"><p class="date single"><span class="dtstart"><span class="year">2010</span><span class="mm-dd">-09-20</span></span> <span class="paren">(</span><span class="dd-mmm">20 SEP</span><span class="paren">)</span></p><div class="info-wrap"><p class="summary">Extensible Multimodal Annotation for Intelligent Virtual Agents</p><p class="source"> by Deborah Dahl</p><p class="eventtitle"><a href="http://iva2010.seas.upenn.edu/" class="uri">10th International Conference on Intelligent Virtual Agents</a></p><p class="location">Philadelphia,
      USA</p></div></li></ul></div>
</div>
<div class="unit size1on2 lastUnit">
<div id="w3c_home_upcoming_events" class="w3c_upcoming_events"><h2 class="category"><a title="More Events&#x2026;" href="/participate/eventscal.html">Events <img src="/2008/site/images/header-link" alt="Header link" width="13" height="13" class="header-link" /></a></h2>
  <ul class="vevent_list">
    <li class="vevent">
      <div class="date">
<span class="dtstart"><span class="year">2010</span><span class="mm-dd">-08-02</span></span>
<span class="paren">(</span><span class="dd-mmm"> 2 AUG</span><span class="paren">)</span>
<span class="date-separator"> &#x2013; </span>
<span class="dtend"><span class="year">2010</span><span class="mm-dd">-08-06</span></span>
<span class="paren">(</span><span class="dd-mmm"> 6 AUG</span><span class="paren">)</span>
</div>      <div class="info-wrap">
      <p class="summary">
              <a href="http://www.balisage.net/" class="uri">Balisage: The Markup Conference</a>
      </p>
          <p class="location">Montreal, Canada</p>               </div>
    </li>
    <li class="vevent">
      <div class="date">
<span class="dtstart"><span class="year">2010</span><span class="mm-dd">-08-30</span></span>
<span class="paren">(</span><span class="dd-mmm">30 AUG</span><span class="paren">)</span>
<span class="date-separator"> &#x2013; </span>
<span class="dtend"><span class="year">2010</span><span class="mm-dd">-09-01</span></span>
<span class="paren">(</span><span class="dd-mmm"> 1 SEP</span><span class="paren">)</span>
</div>      <div class="info-wrap">
      <p class="summary">
              <a href="http://www.svgopen.org/2010/" class="uri">SVG Open</a>
      </p>
          <p class="location">Paris, France</p>               </div>
    </li>
    <li class="vevent">
      <div class="date">
<span class="dtstart"><span class="year">2010</span><span class="mm-dd">-09-02</span></span>
<span class="paren">(</span><span class="dd-mmm"> 2 SEP</span><span class="paren">)</span>
<span class="date-separator"> &#x2013; </span>
<span class="dtend"><span class="year">2010</span><span class="mm-dd">-09-03</span></span>
<span class="paren">(</span><span class="dd-mmm"> 3 SEP</span><span class="paren">)</span>
</div>      <div class="info-wrap">
      <p class="summary">
              <a href="http://www.w3.org/2010/09/web-on-tv/" class="uri">Web on TV</a>
      </p>
          <p class="location">Tokyo, Japan</p>       <p class="host">With the support of the Japan Ministry of Internal Affairs and Communications</p>
        </div>
    </li>
    <li class="vevent">
      <div class="date">
<span class="dtstart"><span class="year">2010</span><span class="mm-dd">-09-05</span></span>
<span class="paren">(</span><span class="dd-mmm"> 5 SEP</span><span class="paren">)</span>
<span class="date-separator"> &#x2013; </span>
<span class="dtend"><span class="year">2010</span><span class="mm-dd">-09-10</span></span>
<span class="paren">(</span><span class="dd-mmm">10 SEP</span><span class="paren">)</span>
</div>      <div class="info-wrap">
      <p class="summary">
              <a href="http://xmlsummerschool.com/" class="uri">XML Summer School</a>
      </p>
          <p class="location">Oxford, England</p>               </div>
    </li>
  </ul></div>
</div>
</div>
</div>
<!-- end events talks --></div>
<!-- end main content --></div>
<div class="unit size1on3 lastUnit">
<p class="about">The World Wide Web Consortium (W3C) is an
international community that develops <a href="/TR/">standards</a>
to ensure the long-term growth of the Web. Read about the <a href="Consortium/mission.html">W3C mission</a>.</p>
<!--
    <div id="w3c_home_new_jobs"/>
    -->
<div id="w3c_home_recent_blogs"><h2 class="category">
      <a title="More Blog Entries&#x2026;" href="/QA/">W3C Blog <img src="/2008/site/images/header-link" alt="Header link" width="13" height="13" class="header-link" />
      </a>
   </h2><ul class="hentry_list">
      <li class="hentry">
         <p class="entry-title">
            <a href="http://www.w3.org/QA/2010/07/w3c_unicorn_launch_off_to_good.html" class="uri url" rel="bookmark">W3C Unicorn Launch off to good start</a>
         </p>
         <p class="date">
            <abbr title="2010-07-30" class="published">30 July 2010</abbr> by <span class="author vcard">
               <a class="fn url" href="http://www.w3.org/People/Ted/">Ted Guild</a>
            </span>
         </p>
      </li>
      <li class="hentry">
         <p class="entry-title">
            <a href="http://www.w3.org/QA/2010/07/augmented_reality_a_point_of_i.html" class="uri url" rel="bookmark">Augmented Reality: A Point of Interest for the Web</a>
         </p>
         <p class="date">
            <abbr title="2010-07-22" class="published">22 July 2010</abbr> by <span class="author vcard">Phil Archer</span>
         </p>
      </li>
      <li class="hentry">
         <p class="entry-title">
            <a href="http://www.w3.org/QA/2010/07/html5_in_w3c_cheatsheet.html" class="uri url" rel="bookmark">HTML5 in W3C Cheatsheet</a>
         </p>
         <p class="date">
            <abbr title="2010-07-20" class="published">20 July 2010</abbr> by <span class="author vcard">
               <a class="fn url" href="http://www.w3.org/People/Dom/">Dominique Haza&#xEB;l-Massieux</a>
            </span>
         </p>
      </li>
   </ul></div>
<!--
    <div id="w3c_home_video">
      <h2 class="category">
        <a href="/participate/podcastsvideo">Featured Video
            <img src="/2008/site/images/header-link.gif" alt="Header link" width
="13" height="13" class="header-link"/>
        </a>
      </h2>
      <p>Here</p>
    </div>
    -->
<div id="w3c_home_validators_software">
<h2 class="category"><a href="Status.html">Validators, Unicorn, and
Other Software <img src="/2008/site/images/header-link.gif" alt="Header link" width="13" height="13" class="header-link" /></a></h2>
<p><a class="imageLink no-border" href="QA/Tools/Donate"><img width="80" height="15" class="icon" alt="I Love Validator" src="/2009/03/I_heart_validator" /></a> The W3C
Community has created useful <a href="Status.html">Open Source
Software</a>. Try <a href="http://validator.w3.org/unicorn/">Unicorn</a>, W3C's unified
validator, to improve the quality of your pages. Unicorn includes
the popular <a title="HTML and XHTML Validator" href="http://validator.w3.org/">HTML and markup validator</a>, <a title="CSS Validator" href="http://jigsaw.w3.org/css-validator/">CSS
validator</a>, <a title="mobileOK Checker" href="http://validator.w3.org/mobile/">mobileOK checker</a>, and more.
Become a <a href="QA/Tools/Donate#donate_sponsors">validator
sponsor</a>.</p>
<p><a class="imageLink no-border" href="http://www.w3.org/2009/cheatsheet/"><img src="http://www.w3.org/2009/cheatsheet/icons/64x" alt="Cheatsheet logo" /></a> The <a href="http://www.w3.org/2009/cheatsheet/">W3C cheatsheet</a> provides
quick access to CSS properties, WCAG tips, mobile tips, and more
(also available on <a href="http://dev.w3.org/2009/cheatsheet/doc/android">Android
market</a>).</p>
</div>
<div class="hpmt" id="w3c_home_member_testimonials">
<h2 class="category"><a href="/Consortium/Member/Testimonial/">W3C
Member Testimonial <img src="/2008/site/images/header-link" alt="Header link" width="13" height="13" class="header-link" /></a></h2>
<div id="w3c_home_member_testimonials_choice"><p class="tPadding0">
         <a rel="nofollow" href="http://www.cylex-uk.co.uk" class="no-border">
            <img class="media" width="120" height="60" alt="IKM Internet Kaufmarkt GmbH logo" src="/Consortium/Member/Testimonial/Logo/1086" />
         </a>
      </p><h3>
         <a rel="nofollow" href="http://www.cylex-uk.co.uk">IKM Internet Kaufmarkt GmbH</a>
      </h3><p>IKM is one of the leading provider of business directories in the internet. There are available business directories in Germany, the Netherlands, Belgium, UK, Austria or Switzerland, e.g. Our pages are in accordance with the W3C standards.</p></div>
<p class="more"><a href="/Consortium/Member/Testimonial/List">Read
all member testimonials.</a></p>
</div>
</div>
</div>
<!-- end main col --></div>
</div>
</div>
<!-- Generated from data/footer.php, ../../smarty/{footer-block.tpl} -->
<div id="w3c_footer">
<div id="w3c_footer-inner">
<h2 class="offscreen">Footer Navigation</h2>
<div class="w3c_footer-nav">
<h3>Navigation</h3>
<ul class="footer_top_nav">
<li><a href="/">Home</a></li>
<li><a href="/standards/">Standards</a></li>
<li><a href="/participate/">Participate</a></li>
<li><a href="/Consortium/membership">Membership</a></li>
<li class="last-item"><a href="/Consortium/">About W3C</a></li>
</ul>
</div>
<div class="w3c_footer-nav">
<h3>Contact W3C</h3>
<ul class="footer_bottom_nav">
<li><a href="/Consortium/contact">Contact</a></li>
<li><a accesskey="0" href="/Help/">Help and FAQ</a></li>
<li><a href="/Consortium/sup">Donate</a></li>
<li><a href="/Consortium/siteindex">Site Map</a></li>
<li>
<address id="w3c_signature"><a href="mailto:site-comments@w3.org">Feedback</a> (<a href="http://lists.w3.org/Archives/Public/site-comments/">archive</a>)</address>
</li>
</ul>
</div>
<div class="w3c_footer-nav">
<h3>W3C Updates</h3>
<ul class="footer_follow_nav">
<li><a href="http://twitter.com/W3C" title="Follow W3C on Twitter"><img src="/2008/site/images/twitter-bird" alt="Twitter" class="social-icon" width="78" height="83" /></a>
<a href="http://identi.ca/w3c" title="See W3C on Identica"><img src="/2008/site/images/identica-logo" alt="Identica" class="social-icon" width="91" height="83" /></a></li>
</ul>
</div>
<!-- #footer address / page signature -->
<p class="copyright">Copyright &#xA9; 2010 W3C <sup>&#xAE;</sup> (<a href="http://www.csail.mit.edu/"><acronym title="Massachusetts Institute of Technology">MIT</acronym></a>, <a href="http://www.ercim.eu/"><acronym title="European Research Consortium for Informatics and Mathematics">ERCIM</acronym></a>,
<a href="http://www.keio.ac.jp/">Keio</a>) <a href="/Consortium/Legal/2002/ipr-notice-20021231">Usage policies
apply</a>.</p>
</div>
</div>
<!-- /end #footer -->
<!-- Generated from data/scripts.php, ../../smarty/{scripts.tpl} -->
<div id="w3c_scripts"><script type="text/javascript" src="/2008/site/js/main">
//<![CDATA[
<!-- -->
//]]>
</script></div>
</body>
</html>
END_XML

    my @expect = (
        '#document',
        { 'html' => undef },
        [
            ['html'],
            [
                'html',
                {
                    'xmlns'    => 'http://www.w3.org/1999/xhtml',
                    'lang'     => 'en',
                    'xml:lang' => 'en'
                },
                [
                    [ '#comment', ' Generated from data/head-home.php, ../../smarty/{head.tpl} ' ],
                    [
                        'head',
                        [
                            [ 'title', 'World Wide Web Consortium (W3C)' ],
                            [
                                'meta',
                                {
                                    'http-equiv' => 'Content-Type',
                                    'content'    => 'text/html; charset=utf-8'
                                }
                            ],
                            [
                                'link',
                                {
                                    'rel'  => 'Help',
                                    'href' => '/Help/'
                                }
                            ],
                            [
                                'link',
                                {
                                    'rel'   => 'stylesheet',
                                    'media' => 'handheld, all',
                                    'href'  => '/2008/site/css/minimum',
                                    'type'  => 'text/css'
                                }
                            ],
                            [
                                'style',
                                {
                                    'media' => 'print, screen and (min-width: 481px)',
                                    'type'  => 'text/css'
                                },
                                [ '
/*',
                                    [
                                        '#cdata-section',
                                        '*/
@import url("/2008/site/css/advanced");
/*'
                                    ],
                                    '*/
'
                                ]
                            ],
                            [
                                'link',
                                {
                                    'rel'   => 'stylesheet',
                                    'media' => 'handheld, only screen and (max-device-width: 480px)',
                                    'href'  => '/2008/site/css/minimum',
                                    'type'  => 'text/css'
                                }
                            ],
                            [
                                'meta',
                                {
                                    'content' => 'width=device-width',
                                    'name'    => 'viewport'
                                }
                            ],
                            [
                                'link',
                                {
                                    'rel'   => 'stylesheet',
                                    'media' => 'print',
                                    'href'  => '/2008/site/css/print',
                                    'type'  => 'text/css'
                                }
                            ],
                            [
                                'link',
                                {
                                    'rel'  => 'shortcut icon',
                                    'href' => '/2008/site/images/favicon.ico',
                                    'type' => 'image/x-icon'
                                }
                            ],
                            [
                                'meta',
                                {
                                    'content' => 'The World Wide Web Consortium (W3C) is an international community where Member organizations, a full-time staff, and the public work together to develop Web standards.',
                                    'name'    => 'description'
                                }
                            ],
                            [
                                'link',
                                {
                                    'rel'   => 'alternate',
                                    'href'  => '/News/atom.xml',
                                    'title' => 'W3C News',
                                    'type'  => 'application/atom+xml'
                                } ] ]
                    ],
                    [
                        'body',
                        {
                            'class' => 'w3c_public w3c_home',
                            'id'    => 'www-w3-org'
                        },
                        [ [
                                'div',
                                { 'id' => 'w3c_container' },
                                [
                                    [ '#comment', ' Generated from data/mast-home.php, ../../smarty/{mast.tpl} ' ],
                                    [
                                        'div',
                                        { 'id' => 'w3c_mast' },
                                        [
                                            [ '#comment', ' #w3c_mast / Page top header ' ],
                                            [
                                                'h1',
                                                { 'class' => 'logo' },
                                                [ [
                                                        'a',
                                                        {
                                                            'accesskey' => '1',
                                                            'tabindex'  => '2',
                                                            'href'      => '/'
                                                        },
                                                        [ [
                                                                'img',
                                                                {
                                                                    'width'  => '90',
                                                                    'alt'    => 'W3C',
                                                                    'src'    => '/2008/site/images/logo-w3c-mobile-lg',
                                                                    'height' => '53'
                                                                } ] ]
                                                    ],
                                                    [ 'span', { 'class' => 'alt-logo' }, 'W3C' ] ]
                                            ],
                                            [
                                                'div',
                                                { 'id' => 'w3c_nav' },
                                                [ [
                                                        'form',
                                                        {
                                                            'action' => 'http://www.w3.org/Consortium/contact',
                                                            'id'     => 'region_form'
                                                        },
                                                        [ [
                                                                'div',
                                                                [ [
                                                                        'select',
                                                                        { 'name' => 'region' },
                                                                        [ [
                                                                                'option',
                                                                                {
                                                                                    'value'    => 'W3C By Region',
                                                                                    'selected' => 'selected'
                                                                                },
                                                                                'W3C By
Region'
                                                                            ],
                                                                            [ 'option', { 'value' => 'all' }, 'All' ],
                                                                            [ 'option', { 'value' => 'au' },  'Australia' ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'de',
                                                                                    'value'    => 'de',
                                                                                    'xml:lang' => 'de'
                                                                                },
                                                                                "\x{d6}sterreich
(Austria)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'nl',
                                                                                    'value'    => 'nl',
                                                                                    'xml:lang' => 'nl'
                                                                                },
                                                                                "Belgi\x{eb}
(Belgium)"
                                                                            ],
                                                                            [ 'option', { 'value' => 'za' }, 'Botswana' ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'pt-br',
                                                                                    'value'    => 'br',
                                                                                    'xml:lang' => 'pt-br'
                                                                                },
                                                                                'Brasil
(Brazil)'
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'zh-hans',
                                                                                    'value'    => 'cn',
                                                                                    'xml:lang' => 'zh-hans'
                                                                                },
                                                                                "\x{4e2d}\x{56fd}
(China)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'fi',
                                                                                    'value'    => 'fi',
                                                                                    'xml:lang' => 'fi'
                                                                                },
                                                                                'Suomi (Finland)'
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'de',
                                                                                    'value'    => 'de',
                                                                                    'xml:lang' => 'de'
                                                                                },
                                                                                'Deutschland
(Germany)'
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'el',
                                                                                    'value'    => 'gr',
                                                                                    'xml:lang' => 'el'
                                                                                },
                                                                                "\x{395}\x{3bb}\x{3bb}\x{3ac}\x{3b4}\x{3b1} (Greece)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'hu',
                                                                                    'value'    => 'hu',
                                                                                    'xml:lang' => 'hu'
                                                                                },
                                                                                "Magyarorsz\x{e1}g
(Hungary)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'hi',
                                                                                    'value'    => 'in',
                                                                                    'xml:lang' => 'hi'
                                                                                },
                                                                                "\x{92d}\x{93e}\x{930}\x{924} (India)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'ga',
                                                                                    'value'    => 'gb',
                                                                                    'xml:lang' => 'ga'
                                                                                },
                                                                                "\x{c9}ire (Ireland)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'he',
                                                                                    'value'    => 'il',
                                                                                    'xml:lang' => 'he'
                                                                                },
                                                                                "\x{5d9}\x{5e9}\x{5e8}\x{5d0}\x{5dc} (Israel)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'it',
                                                                                    'value'    => 'it',
                                                                                    'xml:lang' => 'it'
                                                                                },
                                                                                'Italia (Italy)'
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'ko',
                                                                                    'value'    => 'kr',
                                                                                    'xml:lang' => 'ko'
                                                                                },
                                                                                "\x{d55c}\x{ad6d} (Korea)"
                                                                            ],
                                                                            [ 'option', { 'value' => 'za' }, 'Lesotho' ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'lb',
                                                                                    'value'    => 'nl',
                                                                                    'xml:lang' => 'lb'
                                                                                },
                                                                                "L\x{eb}tzebuerg
(Luxembourg)"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'ar',
                                                                                    'value'    => 'ma',
                                                                                    'xml:lang' => 'ar'
                                                                                },
                                                                                "\x{627}\x{644}\x{645}\x{63a}\x{631}\x{628}
(Morocco)"
                                                                            ],
                                                                            [ 'option', { 'value' => 'za' }, 'Namibia' ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'nl',
                                                                                    'value'    => 'nl',
                                                                                    'xml:lang' => 'nl'
                                                                                },
                                                                                'Nederland
(Netherlands)'
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'fr',
                                                                                    'value'    => 'sn',
                                                                                    'xml:lang' => 'fr'
                                                                                },
                                                                                "S\x{e9}n\x{e9}gal"
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'es',
                                                                                    'value'    => 'es',
                                                                                    'xml:lang' => 'es'
                                                                                },
                                                                                "Espa\x{f1}a (Spain)"
                                                                            ],
                                                                            [ 'option', { 'value' => 'za' }, 'South Africa' ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'ss',
                                                                                    'value'    => 'za',
                                                                                    'xml:lang' => 'ss'
                                                                                },
                                                                                'Swatini
(Swaziland)'
                                                                            ],
                                                                            [
                                                                                'option',
                                                                                {
                                                                                    'lang'     => 'sv',
                                                                                    'value'    => 'se',
                                                                                    'xml:lang' => 'sv'
                                                                                },
                                                                                'Sverige
(Sweden)'
                                                                            ],
                                                                            [ 'option', { 'value' => 'gb' }, 'United Kingdom' ] ]
                                                                    ],
                                                                    [
                                                                        'input',
                                                                        {
                                                                            'value' => 'Go',
                                                                            'type'  => 'submit',
                                                                            'class' => 'button'
                                                                        } ] ] ] ]
                                                    ],
                                                    [
                                                        'form',
                                                        {
                                                            'enctype' => 'application/x-www-form-urlencoded',
                                                            'action'  => 'http://www.w3.org/Help/search',
                                                            'method'  => 'get'
                                                        },
                                                        [ [
                                                                '#comment',
                                                                ' w3c_sec_nav is populated through js '
                                                            ],
                                                            [
                                                                'div',
                                                                { 'class' => 'w3c_sec_nav' },
                                                                [ [
                                                                        '#comment',
                                                                        ' '
                                                                    ] ]
                                                            ],
                                                            [
                                                                'ul',
                                                                { 'class' => 'main_nav' },
                                                                [ [
                                                                        '#comment',
                                                                        ' Main navigation menu '
                                                                    ],
                                                                    [
                                                                        'li',
                                                                        { 'class' => 'first-item' },
                                                                        [ [ 'a', { 'href' => '/standards/' }, 'Standards' ] ]
                                                                    ],
                                                                    [
                                                                        'li',
                                                                        [ [ 'a', { 'href' => '/participate/' }, 'Participate' ] ]
                                                                    ],
                                                                    [
                                                                        'li',
                                                                        [ [ 'a', { 'href' => '/Consortium/membership' }, 'Membership' ] ]
                                                                    ],
                                                                    [
                                                                        'li',
                                                                        { 'class' => 'last-item' },
                                                                        [ [ 'a', { 'href' => '/Consortium/' }, 'About W3C' ] ]
                                                                    ],
                                                                    [
                                                                        'li',
                                                                        { 'class' => 'search-item' },
                                                                        [ [
                                                                                'div',
                                                                                { 'id' => 'search-form' },
                                                                                [ [
                                                                                        'input',
                                                                                        {
                                                                                            'tabindex' => '3',
                                                                                            'value'    => '',
                                                                                            'name'     => 'q',
                                                                                            'title'    => 'Search',
                                                                                            'class'    => 'text'
                                                                                        }
                                                                                    ],
                                                                                    [
                                                                                        'button',
                                                                                        {
                                                                                            'name' => 'search-submit',
                                                                                            'type' => 'submit',
                                                                                            'id'   => 'search-submit'
                                                                                        },
                                                                                        [ [
                                                                                                'img',
                                                                                                {
                                                                                                    'width'  => '21',
                                                                                                    'alt'    => 'Search',
                                                                                                    'src'    => '/2008/site/images/search-button',
                                                                                                    'class'  => 'submit',
                                                                                                    'height' => '17'
                                                                                                } ] ] ] ] ] ] ] ] ] ] ] ] ] ]
                                    ],
                                    [
                                        '#comment',
                                        ' /end #w3c_mast '
                                    ],
                                    [
                                        'div',
                                        { 'id' => 'w3c_main' },
                                        [ [
                                                'div',
                                                {
                                                    'class' => 'w3c_leftCol',
                                                    'id'    => 'w3c_logo_shadow'
                                                },
                                                [ [
                                                        'img',
                                                        {
                                                            'alt'    => '',
                                                            'src'    => '/2008/site/images/logo-shadow',
                                                            'height' => '32'
                                                        } ] ]
                                            ],
                                            [
                                                'div',
                                                { 'class' => 'w3c_leftCol' },
                                                [ [
                                                        'h2',
                                                        { 'class' => 'offscreen' },
                                                        'Site Navigation'
                                                    ],
                                                    [
                                                        'h3',
                                                        { 'class' => 'category' },
                                                        [ [
                                                                'span',
                                                                { 'class' => 'ribbon' },
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/standards/' },
                                                                        [
                                                                            'Standards ',
                                                                            [
                                                                                'img',
                                                                                {
                                                                                    'width'  => '13',
                                                                                    'alt'    => 'Header link',
                                                                                    'src'    => '/2008/site/images/header-link.gif',
                                                                                    'class'  => 'header-link',
                                                                                    'height' => '13'
                                                                                } ] ] ] ] ] ]
                                                    ],
                                                    [
                                                        'ul',
                                                        { 'class' => 'theme' },
                                                        [ [
                                                                'li',
                                                                { 'class' => 'design' },
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/standards/webdesign/',
                                                                            'title' => 'HTML5, XHTML, and CSS, Scripting and Ajax, Web Applications, Graphics, Accessibility'
                                                                        },
                                                                        [
                                                                            [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ],
                                                                            'Web Design and
Applications'
                                                                        ] ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'arch' },
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/standards/webarch/',
                                                                            'title' => 'Architecture Principles, Identifiers, Protocols, Meta Formats'
                                                                        },
                                                                        [ [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ], 'Web Architecture' ] ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'semantics' },
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/standards/semanticweb/',
                                                                            'title' => 'Data, Ontologies, Query, Linked Data'
                                                                        },
                                                                        [ [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ], 'Semantic Web' ] ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'xml' },
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/standards/xml/',
                                                                            'title' => 'XML Essentials, Semantic Additions to XML, Schema, Security'
                                                                        },
                                                                        [ [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ], 'XML Technology' ] ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'services' },
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/standards/webofservices/',
                                                                            'title' => 'Data, Protocols, Service Description, Security'
                                                                        },
                                                                        [ [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ], 'Web of Services' ] ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'devices' },
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/standards/webofdevices/',
                                                                            'title' => 'Voice Browsing, Device Independence and Content Negotation, Multimodal Access, Printing'
                                                                        },
                                                                        [ [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ], 'Web of Devices' ] ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'browsers' },
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/standards/agents/',
                                                                            'title' => 'Browsers and User Agents, Authoring Tools, Web Servers'
                                                                        },
                                                                        [ [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ], 'Browsers and Authoring Tools' ] ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'allspecs' },
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/TR/' },
                                                                        [ [ 'span', { 'class' => 'icon' }, [ [ '#comment', ' ' ] ] ], "\x{2026} or view all" ] ] ] ] ]
                                                    ],
                                                    [
                                                        'h3',
                                                        { 'class' => 'category tMargin' },
                                                        [ [
                                                                'span',
                                                                { 'class' => 'ribbon' },
                                                                [ [
                                                                        'a',
                                                                        { 'href' => 'Consortium/mission.html#principles' },
                                                                        [
                                                                            'Web for All ',
                                                                            [
                                                                                'img',
                                                                                {
                                                                                    'width'  => '13',
                                                                                    'alt'    => 'Header link',
                                                                                    'src'    => '/2008/site/images/header-link.gif',
                                                                                    'class'  => 'header-link',
                                                                                    'height' => '13'
                                                                                } ] ] ] ] ] ]
                                                    ],
                                                    [
                                                        'ul',
                                                        { 'class' => 'theme' },
                                                        [ [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => 'Consortium/siteindex.html#technologies',
                                                                            'title' => 'Popular links to W3C technology information'
                                                                        },
                                                                        "W3C
A\x{a0}to\x{a0}Z"
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [ 'a', { 'href' => '/WAI/' }, 'Accessibility' ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [ 'a', { 'href' => '/International/' }, 'Internationalization' ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [ 'a', { 'href' => '/Mobile/' }, 'Mobile Web' ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [ 'a', { 'href' => '/2007/eGov/' }, 'eGovernment' ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [ 'a', { 'href' => '/2008/MW4D/' }, 'Developing Economies' ] ] ] ]
                                                    ],
                                                    [
                                                        'h3',
                                                        { 'class' => 'category tMargin' },
                                                        [ [
                                                                'span',
                                                                { 'class' => 'ribbon' },
                                                                [ [
                                                                        'a',
                                                                        { 'href' => 'Consortium/activities' },
                                                                        [
                                                                            'W3C Groups ',
                                                                            [
                                                                                'img',
                                                                                {
                                                                                    'width'  => '13',
                                                                                    'alt'    => 'Header link',
                                                                                    'src'    => '/2008/site/images/header-link.gif',
                                                                                    'class'  => 'header-link',
                                                                                    'height' => '13'
                                                                                } ] ] ] ] ] ]
                                                    ],
                                                    [
                                                        'ul',
                                                        { 'class' => 'theme' },
                                                        [ [
                                                                'li',
                                                                [ [ 'a', { 'href' => '/TR/tr-groups-all' }, 'Specifications by group' ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => '/Guide/',
                                                                            'title' => 'Member-only group participant guidebook'
                                                                        },
                                                                        'Participant guidebook'
                                                                    ] ] ] ] ] ]
                                            ],
                                            [
                                                'div',
                                                { 'class' => 'w3c_mainCol' },
                                                [ [
                                                        'div',
                                                        { 'id' => 'w3c_crumbs' },
                                                        [ [
                                                                'div',
                                                                { 'id' => 'w3c_crumbs_frame' },
                                                                [ [
                                                                        'p',
                                                                        { 'class' => 'bct' },
                                                                        [ [
                                                                                'span',
                                                                                { 'class' => 'skip' },
                                                                                [ [
                                                                                        'a',
                                                                                        {
                                                                                            'accesskey' => '2',
                                                                                            'tabindex'  => '1',
                                                                                            'href'      => '#w3c_most-recently',
                                                                                            'title'     => 'Skip to content (e.g., when browsing via audio)'
                                                                                        },
                                                                                        'Skip'
                                                                                    ] ] ] ]
                                                                    ],
                                                                    ['br'] ] ] ]
                                                    ],
                                                    [
                                                        'div',
                                                        { 'class' => 'line' },
                                                        [ [
                                                                'div',
                                                                { 'class' => 'unit size2on3' },
                                                                [ [
                                                                        'div',
                                                                        { 'class' => 'main-content' },
                                                                        [
                                                                            [ 'h2', { 'class' => 'offscreen' }, 'News' ],
                                                                            [
                                                                                'div',
                                                                                { 'id' => 'w3c_slideshow' },
                                                                                [ [
                                                                                        'div',
                                                                                        {
                                                                                            'class' => 'intro hierarchy vevent_list',
                                                                                            'id'    => 'w3c_most-recently'
                                                                                        },
                                                                                        [ [
                                                                                                'div',
                                                                                                { 'class' => 'event w3c_topstory expand_block' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        { 'class' => 'headline' },
                                                                                                        [
                                                                                                            [ 'h3', { 'class' => 'h4 tPadding0 bPadding0 summary' }, [ [ 'span', { 'class' => 'expand_section' }, 'W3C Releases Unicorn, an All-in-One Validator ' ] ] ],
                                                                                                            [
                                                                                                                'p',
                                                                                                                { 'class' => 'date' },
                                                                                                                [ [
                                                                                                                        'span',
                                                                                                                        {
                                                                                                                            'title' => '2010-07-27T08:46:08-05:00',
                                                                                                                            'class' => 'dtstart published'
                                                                                                                        },
                                                                                                                        '27 July 2010'
                                                                                                                    ],
                                                                                                                    '
  | ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/News/2010#entry-8862',
                                                                                                                            'title' => 'Archive: W3C Releases Unicorn, an All-in-One Validator '
                                                                                                                        },
                                                                                                                        'Archive'
                                                                                                                    ] ] ] ]
                                                                                                    ],
                                                                                                    [
                                                                                                        'div',
                                                                                                        { 'class' => 'description expand_description' },
                                                                                                        [ [
                                                                                                                'p',
                                                                                                                [
                                                                                                                    'W3C is pleased to announce the release of ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://validator.w3.org/unicorn/'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'Unicorn'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ', a one-stop tool to help people improve the quality of their Web pages. Unicorn combines a number of popular tools in a single, easy interface, including the ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://validator.w3.org/'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'Markup validator'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ', ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://jigsaw.w3.org/css-validator/'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'CSS validator'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ', ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://validator.w3.org/mobile/'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'mobileOk checker'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ', and ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://validator.w3.org/feed/'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'Feed validator'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ', which remain available as individual services as well. W3C invites developers to enhance the service by ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://code.w3.org/unicorn/wiki/Documentation/Observer'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'creating new modules'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ' and testing them in our ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://code.w3.org/unicorn/wiki#DevelopUnicornandValidationServices'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'online developer space'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ' (or ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://code.w3.org/unicorn/wiki/Documentation/Install'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'installing Unicorn locally'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    '). W3C looks forward to code contributions from the community as well as ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://code.w3.org/unicorn/wiki#Feedback'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'suggestions for new features'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    '. W3C would like to thank the many people whose work has led up to this first release of Unicorn. This includes developers  who started and improved the tool over the past few years, users who have provided feedback, ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://code.w3.org/unicorn/wiki/Translators'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'translators'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ' who have helped localize the interface with  ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://validator.w3.org/unicorn/translations'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        '21 translations'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ' so far, and sponsors HP and Mozilla and other individual donors. W3C welcomes ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://code.w3.org/unicorn/wiki#Feedback'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'feedback'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ' and ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://www.w3.org/QA/Tools/Donate'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'donations'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    ' so that W3C can continue to expand this free service to the community. Learn more about ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'
                                                                                                                                =>
                                                                                                                                'http://www.w3.org/Status'
                                                                                                                        }
                                                                                                                        ,
                                                                                                                        'W3C open source software'
                                                                                                                    ]
                                                                                                                    ,
                                                                                                                    '.
'
                                                                                                                ] ] ] ] ]
                                                                                            ],
                                                                                            [
                                                                                                'div',
                                                                                                { 'class' => 'event closed expand_block' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        { 'class' => 'headline' },
                                                                                                        [ [
                                                                                                                'h3',
                                                                                                                { 'class' => 'h4 tPadding0 bPadding0 summary' },
                                                                                                                [ [ 'span', { 'class' => 'expand_section' }, 'W3C Invites Implementations of XMLHttpRequest ' ] ]
                                                                                                            ],
                                                                                                            [
                                                                                                                'p',
                                                                                                                { 'class' => 'date' },
                                                                                                                [ [
                                                                                                                        'span',
                                                                                                                        {
                                                                                                                            'title' => '2010-08-03T11:03:04-05:00',
                                                                                                                            'class' => 'published dtstart'
                                                                                                                        },
                                                                                                                        '03 August 2010'
                                                                                                                    ],
                                                                                                                    '
  | ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/News/2010#entry-8871',
                                                                                                                            'title' => 'Archived: W3C Invites Implementations of XMLHttpRequest '
                                                                                                                        },
                                                                                                                        'Archive'
                                                                                                                    ] ] ] ]
                                                                                                    ],
                                                                                                    [
                                                                                                        'div',
                                                                                                        { 'class' => 'description expand_description' },
                                                                                                        [ [
                                                                                                                'p',
                                                                                                                [ 'The ', [ 'a', { 'href' => 'http://www.w3.org/2008/webapps/' }, 'Web Applications Working Group' ], ' invites implementation of the Candidate Recommendation of ', [ 'a', { 'href' => 'http://www.w3.org/TR/2010/CR-XMLHttpRequest-20100803/' }, 'XMLHttpRequest' ], '. The XMLHttpRequest specification defines an API that provides scripted client functionality for transferring data between a client and a server. Learn more about the ', [ 'a', { 'href' => 'http://www.w3.org/2006/rwc/' }, 'Rich Web Client Activity' ], '.' ] ] ] ] ]
                                                                                            ],
                                                                                            [
                                                                                                'div',
                                                                                                { 'class' => 'event closed expand_block' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        { 'class' => 'headline' },
                                                                                                        [ [
                                                                                                                'h3',
                                                                                                                { 'class' => 'h4 tPadding0 bPadding0 summary' },
                                                                                                                [ [ 'span', { 'class' => 'expand_section' }, 'Drafts of RDFa Core 1.1 and XHTML+RDFa 1.1 Published' ] ]
                                                                                                            ],
                                                                                                            [
                                                                                                                'p',
                                                                                                                { 'class' => 'date' },
                                                                                                                [ [
                                                                                                                        'span',
                                                                                                                        {
                                                                                                                            'title' => '2010-08-03T09:46:23-05:00',
                                                                                                                            'class' => 'published dtstart'
                                                                                                                        },
                                                                                                                        '03 August 2010'
                                                                                                                    ],
                                                                                                                    '
  | ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/News/2010#entry-8870',
                                                                                                                            'title' => 'Archived: Drafts of RDFa Core 1.1 and XHTML+RDFa 1.1 Published'
                                                                                                                        },
                                                                                                                        'Archive'
                                                                                                                    ] ] ] ]
                                                                                                    ],
                                                                                                    [
                                                                                                        'div',
                                                                                                        { 'class' => 'description expand_description' },
                                                                                                        [ [
                                                                                                                'p',
                                                                                                                [
                                                                                                                    'The ',
                                                                                                                    [ 'a', { 'href' => 'http://www.w3.org/2010/02/rdfa/' }, 'RDFa Working Group' ],
                                                                                                                    ' has just published two Working Drafts: ',
                                                                                                                    [ 'a', { 'href' => 'http://www.w3.org/2010/02/rdfa/drafts/2010/WD-rdfa-core-20100803/' }, 'RDFa Core 1.1' ],
                                                                                                                    ' and ',
                                                                                                                    [ 'a', { 'href' => 'http://www.w3.org/TR/2010/WD-xhtml-rdfa-20100803/' }, 'XHTML+RDFa 1.1' ],
                                                                                                                    '. RDFa Core 1.1 is a specification for attributes to express structured data in any markup language. The embedded data already available in the markup language (e.g., XHTML) is reused by the RDFa markup, so that publishers don\'t need to repeat significant data in the document content. XHTML+RDFa 1.1 is an XHTML family markup language. That extends the XHTML 1.1 markup language with the attributes defined in RDFa Core 1.1. This document is intended for authors who want to create XHTML-Family documents that embed rich semantic markup. Learn more about the ',
                                                                                                                    [ 'a', { 'href' => 'http://www.w3.org/2001/sw/' }, 'Semantic Web Activity' ], '. '
                                                                                                                ] ] ] ] ]
                                                                                            ],
                                                                                            [
                                                                                                'div',
                                                                                                { 'class' => 'event closed expand_block' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        { 'class' => 'headline' },
                                                                                                        [ [
                                                                                                                'h3',
                                                                                                                { 'class' => 'h4 tPadding0 bPadding0 summary' },
                                                                                                                [ [ 'span', { 'class' => 'expand_section' }, 'XHTML Modularization 1.1 - Second Edition is a W3C Recommendation' ] ]
                                                                                                            ],
                                                                                                            [
                                                                                                                'p',
                                                                                                                { 'class' => 'date' },
                                                                                                                [ [
                                                                                                                        'span',
                                                                                                                        {
                                                                                                                            'title' => '2010-07-29T15:44:03-05:00',
                                                                                                                            'class' => 'published dtstart'
                                                                                                                        },
                                                                                                                        '29 July 2010'
                                                                                                                    ],
                                                                                                                    '
  | ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/News/2010#entry-8868',
                                                                                                                            'title' => 'Archived: XHTML Modularization 1.1 - Second Edition is a W3C Recommendation'
                                                                                                                        },
                                                                                                                        'Archive'
                                                                                                                    ] ] ] ]
                                                                                                    ],
                                                                                                    [
                                                                                                        'div',
                                                                                                        { 'class' => 'description expand_description' },
                                                                                                        [ [
                                                                                                                'p',
                                                                                                                [ 'The ', [ 'a', { 'href' => '/MarkUp/' }, 'XHTML2 Working Group' ], ' has published a W3C Recommendation of ', [ 'a', { 'href' => '/TR/2010/REC-xhtml-modularization-20100729/' }, 'XHTML Modularization 1.1 - Second Edition' ], '. XHTML Modularization is a tool for people who design markup languages. XHTML Modularization helps people design and manage markup language schemas and DTDs; it explains how to write schemas that will plug together. Modules can be reused and recombined across different languages, which helps keep related languages in sync. This edition includes several minor updates to provide clarifications and address errors found in version 1.1. Learn more about the ', [ 'a', { 'href' => '/MarkUp/Activity' }, 'HTML Activity' ], '.' ] ] ] ] ]
                                                                                            ],
                                                                                            [
                                                                                                'div',
                                                                                                { 'class' => 'event closed expand_block' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        { 'class' => 'headline' },
                                                                                                        [ [
                                                                                                                'h3',
                                                                                                                { 'class' => 'h4 tPadding0 bPadding0 summary' },
                                                                                                                [ [ 'span', { 'class' => 'expand_section' }, 'Draft of Emotion Markup Language (EmotionML) 1.0  Published' ] ]
                                                                                                            ],
                                                                                                            [
                                                                                                                'p',
                                                                                                                { 'class' => 'date' },
                                                                                                                [ [
                                                                                                                        'span',
                                                                                                                        {
                                                                                                                            'title' => '2010-07-29T15:36:45-05:00',
                                                                                                                            'class' => 'published dtstart'
                                                                                                                        },
                                                                                                                        '29 July 2010'
                                                                                                                    ],
                                                                                                                    '
  | ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/News/2010#entry-8867',
                                                                                                                            'title' => 'Archived: Draft of Emotion Markup Language (EmotionML) 1.0  Published'
                                                                                                                        },
                                                                                                                        'Archive'
                                                                                                                    ] ] ] ]
                                                                                                    ],
                                                                                                    [
                                                                                                        'div',
                                                                                                        { 'class' => 'description expand_description' },
                                                                                                        [ [
                                                                                                                'p',
                                                                                                                [ 'The ', [ 'a', { 'href' => '/2002/mmi/' }, 'Multimodal Interaction Working Group' ], ' has published a Working Draft of ', [ 'a', { 'href' => '/TR/2010/WD-emotionml-20100729/' }, 'Emotion Markup Language (EmotionML) 1.0' ], '. As the web is becoming ubiquitous, interactive, and multimodal, technology needs to deal increasingly with human factors, including emotions. The present draft specification of Emotion Markup Language 1.0 aims to strike a balance between practical applicability and basis in science. The language is conceived as a "plug-in" language suitable for use in three different areas: (1) manual annotation of data; (2) automatic recognition of emotion-related states from user behavior; and (3) generation of emotion-related system behavior. Learn more about the ', [ 'a', { 'href' => '/2002/mmi/' }, 'Multimodal Interaction Activity' ], '.' ] ] ] ] ]
                                                                                            ],
                                                                                            [
                                                                                                'div',
                                                                                                { 'class' => 'event closed expand_block' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        { 'class' => 'headline' },
                                                                                                        [ [
                                                                                                                'h3',
                                                                                                                { 'class' => 'h4 tPadding0 bPadding0 summary' },
                                                                                                                [ [ 'span', { 'class' => 'expand_section' }, 'Cross-Origin Resource Sharing Draft Published' ] ]
                                                                                                            ],
                                                                                                            [
                                                                                                                'p',
                                                                                                                { 'class' => 'date' },
                                                                                                                [ [
                                                                                                                        'span',
                                                                                                                        {
                                                                                                                            'title' => '2010-07-27T12:56:43-05:00',
                                                                                                                            'class' => 'published dtstart'
                                                                                                                        },
                                                                                                                        '27 July 2010'
                                                                                                                    ],
                                                                                                                    '
  | ',
                                                                                                                    [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/News/2010#entry-8863',
                                                                                                                            'title' => 'Archived: Cross-Origin Resource Sharing Draft Published'
                                                                                                                        },
                                                                                                                        'Archive'
                                                                                                                    ] ] ] ]
                                                                                                    ],
                                                                                                    [
                                                                                                        'div',
                                                                                                        { 'class' => 'description expand_description' },
                                                                                                        [ [
                                                                                                                'p',
                                                                                                                [ 'The ', [ 'a', { 'href' => '/2008/webapps/' }, 'Web Applications Working Group' ], ' has published a Working Draft of ', [ 'a', { 'href' => '/TR/2010/WD-cors-20100727/' }, 'Cross-Origin Resource Sharing' ], '. User agents commonly apply same-origin restrictions to network requests. These restrictions prevent a client-side Web application running from one origin from obtaining data retrieved from another origin, and also limit unsafe HTTP requests that can be automatically launched toward destinations that differ from the running application\'s origin. In user agents that follow this pattern, network requests typically use ambient authentication and session management information, including HTTP authentication and cookie information. This specification extends this model in a number of ways.Learn more about the ', [ 'a', { 'href' => '/2006/rwc/' }, 'Rich Web Client Activity' ], '.' ] ] ] ] ] ] ] ] ]
                                                                            ],
                                                                            [
                                                                                'p',
                                                                                { 'class' => 'noprint' },
                                                                                [ [
                                                                                        'span',
                                                                                        { 'class' => 'more-news' },
                                                                                        [ [
                                                                                                'a',
                                                                                                {
                                                                                                    'href'  => '/News/archive',
                                                                                                    'title' => 'More News'
                                                                                                },
                                                                                                "More news\x{2026}"
                                                                                            ],
                                                                                            [
                                                                                                'a',
                                                                                                {
                                                                                                    'href'  => '/News/news.rss',
                                                                                                    'class' => 'feedlink',
                                                                                                    'title' => 'RSS feed for W3C home page news'
                                                                                                },
                                                                                                [ [
                                                                                                        'img',
                                                                                                        {
                                                                                                            'width'  => '30',
                                                                                                            'alt'    => 'RSS',
                                                                                                            'src'    => '/2008/site/images/icons/rss30',
                                                                                                            'height' => '30'
                                                                                                        } ] ]
                                                                                            ],
                                                                                            [
                                                                                                'a',
                                                                                                {
                                                                                                    'href'  => '/News/atom.xml',
                                                                                                    'class' => 'feedlink',
                                                                                                    'title' => 'Atom feed for W3C home page news'
                                                                                                },
                                                                                                [ [
                                                                                                        'img',
                                                                                                        {
                                                                                                            'width'  => '30',
                                                                                                            'alt'    => 'Atom',
                                                                                                            'src'    => '/2008/site/images/icons/atom30',
                                                                                                            'height' => '30'
                                                                                                        } ] ] ] ] ] ]
                                                                            ],
                                                                            [
                                                                                'div',
                                                                                { 'class' => 'w3c_events_talks' },
                                                                                [ [
                                                                                        'div',
                                                                                        { 'class' => 'line' },
                                                                                        [ [
                                                                                                'div',
                                                                                                { 'class' => 'unit size1on2' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        {
                                                                                                            'class' => 'w3c_upcoming_talks',
                                                                                                            'id'    => 'w3c_home_talks'
                                                                                                        },
                                                                                                        [ [
                                                                                                                'h2',
                                                                                                                { 'class' => 'category' },
                                                                                                                [ [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/Talks/',
                                                                                                                            'title' => "More Talks\x{2026}"
                                                                                                                        },
                                                                                                                        [ '
          Talks and Appearances
          ',
                                                                                                                            [
                                                                                                                                'img',
                                                                                                                                {
                                                                                                                                    'width'  => '13',
                                                                                                                                    'alt'    => 'Header link',
                                                                                                                                    'src'    => '/2008/site/images/header-link',
                                                                                                                                    'class'  => 'header-link',
                                                                                                                                    'height' => '13'
                                                                                                                                }
                                                                                                                            ] ] ] ]
                                                                                                            ],
                                                                                                            [
                                                                                                                'ul',
                                                                                                                { 'class' => 'vevent_list' },
                                                                                                                [ [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [
                                                                                                                            [ 'p', { 'class' => 'date single' }, [ [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-08-30' ] ] ], [ 'span', { 'class' => 'paren' }, '(' ], [ 'span', { 'class' => 'dd-mmm' }, '30 AUG' ], [ 'span', { 'class' => 'paren' }, ')' ] ] ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [
                                                                                                                                    [ 'p', { 'class' => 'summary' }, 'GUI Frameworks for Web Applications ' ],
                                                                                                                                    [ 'p', { 'class' => 'source' },  'Mohamed ZERGAOUI' ],
                                                                                                                                    [
                                                                                                                                        'p',
                                                                                                                                        { 'class' => 'eventtitle' },
                                                                                                                                        [ [
                                                                                                                                                'a',
                                                                                                                                                {
                                                                                                                                                    'href'  => 'http://www.w3.org/2004/08/TalkFiles/2010/svgopen.org',
                                                                                                                                                    'class' => 'uri'
                                                                                                                                                },
                                                                                                                                                'SVG Open 2010'
                                                                                                                                            ] ]
                                                                                                                                    ],
                                                                                                                                    [
                                                                                                                                        'p',
                                                                                                                                        {
                                                                                                                                            'class'
                                                                                                                                                =>
                                                                                                                                                'location'
                                                                                                                                        }
                                                                                                                                        ,
                                                                                                                                        'Paris,
      France'
                                                                                                                                    ] ] ] ]
                                                                                                                    ],
                                                                                                                    [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [ [
                                                                                                                                'p',
                                                                                                                                { 'class' => 'date single' },
                                                                                                                                [
                                                                                                                                    [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-01' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' }, '1 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  ')' ] ]
                                                                                                                            ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [
                                                                                                                                    [ 'p', { 'class' => 'summary' }, 'All Good Things Come in Threes: A Tale of Three Screens' ],
                                                                                                                                    [ 'p', { 'class' => 'source' },  ' by Alex Danilo' ],
                                                                                                                                    [
                                                                                                                                        'p',
                                                                                                                                        { 'class' => 'eventtitle' },
                                                                                                                                        [ [
                                                                                                                                                'a',
                                                                                                                                                {
                                                                                                                                                    'href'  => 'http://svgopen.org',
                                                                                                                                                    'class' => 'uri'
                                                                                                                                                },
                                                                                                                                                'SVG Open 2010'
                                                                                                                                            ] ]
                                                                                                                                    ],
                                                                                                                                    [
                                                                                                                                        'p',
                                                                                                                                        {
                                                                                                                                            'class'
                                                                                                                                                =>
                                                                                                                                                'location'
                                                                                                                                        }
                                                                                                                                        ,
                                                                                                                                        'Paris,
      France'
                                                                                                                                    ] ] ] ]
                                                                                                                    ],
                                                                                                                    [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [ [
                                                                                                                                'p',
                                                                                                                                { 'class' => 'date single' },
                                                                                                                                [
                                                                                                                                    [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-10' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' }, '10 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  ')' ] ]
                                                                                                                            ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [
                                                                                                                                    [ 'p', { 'class' => 'summary' }, [ [ 'a', { 'href' => 'http://is.gd/daqSR' }, 'Implementing WCAG 2.0 ' ] ] ],
                                                                                                                                    [ 'p', { 'class' => 'source' },     ' by Michael Cooper' ],
                                                                                                                                    [ 'p', { 'class' => 'eventtitle' }, 'Citizens With Disabilities - Ontario' ],
                                                                                                                                    [
                                                                                                                                        'p',
                                                                                                                                        {
                                                                                                                                            'class'
                                                                                                                                                =>
                                                                                                                                                'location'
                                                                                                                                        }
                                                                                                                                        ,
                                                                                                                                        'Ontario,
      Canada'
                                                                                                                                    ] ] ] ]
                                                                                                                    ],
                                                                                                                    [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [ [
                                                                                                                                'p',
                                                                                                                                { 'class' => 'date single' },
                                                                                                                                [
                                                                                                                                    [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-20' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' }, '20 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  ')' ] ]
                                                                                                                            ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [
                                                                                                                                    [ 'p', { 'class' => 'summary' }, 'Extensible Multimodal Annotation for Intelligent Virtual Agents' ],
                                                                                                                                    [ 'p', { 'class' => 'source' },  ' by Deborah Dahl' ],
                                                                                                                                    [
                                                                                                                                        'p',
                                                                                                                                        { 'class' => 'eventtitle' },
                                                                                                                                        [ [
                                                                                                                                                'a',
                                                                                                                                                {
                                                                                                                                                    'href'  => 'http://iva2010.seas.upenn.edu/',
                                                                                                                                                    'class' => 'uri'
                                                                                                                                                },
                                                                                                                                                '10th International Conference on Intelligent Virtual Agents'
                                                                                                                                            ] ]
                                                                                                                                    ],
                                                                                                                                    [
                                                                                                                                        'p',
                                                                                                                                        {
                                                                                                                                            'class'
                                                                                                                                                =>
                                                                                                                                                'location'
                                                                                                                                        }
                                                                                                                                        ,
                                                                                                                                        'Philadelphia,
      USA'
                                                                                                                                    ] ] ] ] ] ] ] ] ] ]
                                                                                            ],
                                                                                            [
                                                                                                'div',
                                                                                                { 'class' => 'unit size1on2 lastUnit' },
                                                                                                [ [
                                                                                                        'div',
                                                                                                        {
                                                                                                            'class' => 'w3c_upcoming_events',
                                                                                                            'id'    => 'w3c_home_upcoming_events'
                                                                                                        },
                                                                                                        [ [
                                                                                                                'h2',
                                                                                                                { 'class' => 'category' },
                                                                                                                [ [
                                                                                                                        'a',
                                                                                                                        {
                                                                                                                            'href'  => '/participate/eventscal.html',
                                                                                                                            'title' => "More Events\x{2026}"
                                                                                                                        },
                                                                                                                        [
                                                                                                                            'Events ',
                                                                                                                            [
                                                                                                                                'img',
                                                                                                                                {
                                                                                                                                    'width'  => '13',
                                                                                                                                    'alt'    => 'Header link',
                                                                                                                                    'src'    => '/2008/site/images/header-link',
                                                                                                                                    'class'  => 'header-link',
                                                                                                                                    'height' => '13'
                                                                                                                                } ] ] ] ]
                                                                                                            ],
                                                                                                            [
                                                                                                                'ul',
                                                                                                                { 'class' => 'vevent_list' },
                                                                                                                [ [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [ [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'date' },
                                                                                                                                [
                                                                                                                                    [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-08-02' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' },         ' 2 AUG' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          ')' ],
                                                                                                                                    [ 'span', { 'class' => 'date-separator' }, " \x{2013} " ],
                                                                                                                                    [ 'span', { 'class' => 'dtend' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-08-06' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' }, ' 6 AUG' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  ')' ] ]
                                                                                                                            ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [ [
                                                                                                                                        'p',
                                                                                                                                        { 'class' => 'summary' },
                                                                                                                                        [ [
                                                                                                                                                'a',
                                                                                                                                                {
                                                                                                                                                    'href'  => 'http://www.balisage.net/',
                                                                                                                                                    'class' => 'uri'
                                                                                                                                                },
                                                                                                                                                'Balisage: The Markup Conference'
                                                                                                                                            ] ]
                                                                                                                                    ],
                                                                                                                                    [ 'p', { 'class' => 'location' }, 'Montreal, Canada' ] ] ] ]
                                                                                                                    ],
                                                                                                                    [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [ [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'date' },
                                                                                                                                [
                                                                                                                                    [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-08-30' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' },         '30 AUG' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          ')' ],
                                                                                                                                    [ 'span', { 'class' => 'date-separator' }, " \x{2013} " ],
                                                                                                                                    [ 'span', { 'class' => 'dtend' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-01' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' }, ' 1 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  ')' ] ]
                                                                                                                            ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [ [
                                                                                                                                        'p',
                                                                                                                                        { 'class' => 'summary' },
                                                                                                                                        [ [
                                                                                                                                                'a',
                                                                                                                                                {
                                                                                                                                                    'href'  => 'http://www.svgopen.org/2010/',
                                                                                                                                                    'class' => 'uri'
                                                                                                                                                },
                                                                                                                                                'SVG Open'
                                                                                                                                            ] ]
                                                                                                                                    ],
                                                                                                                                    [ 'p', { 'class' => 'location' }, 'Paris, France' ] ] ] ]
                                                                                                                    ],
                                                                                                                    [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [ [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'date' },
                                                                                                                                [
                                                                                                                                    [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-02' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' },         ' 2 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          ')' ],
                                                                                                                                    [ 'span', { 'class' => 'date-separator' }, " \x{2013} " ],
                                                                                                                                    [ 'span', { 'class' => 'dtend' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-03' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' }, ' 3 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  ')' ] ]
                                                                                                                            ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [ [
                                                                                                                                        'p',
                                                                                                                                        { 'class' => 'summary' },
                                                                                                                                        [ [
                                                                                                                                                'a',
                                                                                                                                                {
                                                                                                                                                    'href'  => 'http://www.w3.org/2010/09/web-on-tv/',
                                                                                                                                                    'class' => 'uri'
                                                                                                                                                },
                                                                                                                                                'Web on TV'
                                                                                                                                            ] ]
                                                                                                                                    ],
                                                                                                                                    [ 'p', { 'class' => 'location' }, 'Tokyo, Japan' ],
                                                                                                                                    [ 'p', { 'class' => 'host' },     'With the support of the Japan Ministry of Internal Affairs and Communications' ] ] ] ]
                                                                                                                    ],
                                                                                                                    [
                                                                                                                        'li',
                                                                                                                        { 'class' => 'vevent' },
                                                                                                                        [ [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'date' },
                                                                                                                                [
                                                                                                                                    [ 'span', { 'class' => 'dtstart' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-05' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' },         ' 5 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },          ')' ],
                                                                                                                                    [ 'span', { 'class' => 'date-separator' }, " \x{2013} " ],
                                                                                                                                    [ 'span', { 'class' => 'dtend' }, [ [ 'span', { 'class' => 'year' }, '2010' ], [ 'span', { 'class' => 'mm-dd' }, '-09-10' ] ] ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  '(' ],
                                                                                                                                    [ 'span', { 'class' => 'dd-mmm' }, '10 SEP' ],
                                                                                                                                    [ 'span', { 'class' => 'paren' },  ')' ] ]
                                                                                                                            ],
                                                                                                                            [
                                                                                                                                'div',
                                                                                                                                { 'class' => 'info-wrap' },
                                                                                                                                [ [
                                                                                                                                        'p',
                                                                                                                                        { 'class' => 'summary' },
                                                                                                                                        [ [
                                                                                                                                                'a',
                                                                                                                                                {
                                                                                                                                                    'href'  => 'http://xmlsummerschool.com/',
                                                                                                                                                    'class' => 'uri'
                                                                                                                                                },
                                                                                                                                                'XML Summer School'
                                                                                                                                            ] ]
                                                                                                                                    ],
                                                                                                                                    [ 'p', { 'class' => 'location' }, 'Oxford, England' ] ] ] ] ] ] ] ] ] ] ] ] ] ]
                                                                            ],
                                                                            [
                                                                                '#comment',
                                                                                ' end events talks '
                                                                            ] ]
                                                                    ],
                                                                    [
                                                                        '#comment',
                                                                        ' end main content '
                                                                    ] ]
                                                            ],
                                                            [
                                                                'div',
                                                                { 'class' => 'unit size1on3 lastUnit' },
                                                                [ [
                                                                        'p',
                                                                        { 'class' => 'about' },
                                                                        [
                                                                            'The World Wide Web Consortium (W3C) is an
international community that develops ',
                                                                            [
                                                                                'a',
                                                                                {
                                                                                    'href'
                                                                                        =>
                                                                                        '/TR/'
                                                                                }
                                                                                ,
                                                                                'standards'
                                                                            ],
                                                                            '
to ensure the long-term growth of the Web. Read about the ',
                                                                            [
                                                                                'a',
                                                                                {
                                                                                    'href'
                                                                                        =>
                                                                                        'Consortium/mission.html'
                                                                                }
                                                                                ,
                                                                                'W3C mission'
                                                                            ],
                                                                            '.'
                                                                        ]
                                                                    ],
                                                                    [
                                                                        '#comment',
                                                                        '
    <div id="w3c_home_new_jobs"/>
    '
                                                                    ],
                                                                    [
                                                                        'div',
                                                                        { 'id' => 'w3c_home_recent_blogs' },
                                                                        [ [
                                                                                'h2',
                                                                                { 'class' => 'category' },
                                                                                [ [
                                                                                        'a',
                                                                                        {
                                                                                            'href'  => '/QA/',
                                                                                            'title' => "More Blog Entries\x{2026}"
                                                                                        },
                                                                                        [
                                                                                            'W3C Blog ',
                                                                                            [
                                                                                                'img',
                                                                                                {
                                                                                                    'width'  => '13',
                                                                                                    'alt'    => 'Header link',
                                                                                                    'src'    => '/2008/site/images/header-link',
                                                                                                    'class'  => 'header-link',
                                                                                                    'height' => '13'
                                                                                                } ] ] ] ]
                                                                            ],
                                                                            [
                                                                                'ul',
                                                                                { 'class' => 'hentry_list' },
                                                                                [ [
                                                                                        'li',
                                                                                        { 'class' => 'hentry' },
                                                                                        [ [
                                                                                                'p',
                                                                                                { 'class' => 'entry-title' },
                                                                                                [ [
                                                                                                        'a',
                                                                                                        {
                                                                                                            'rel'   => 'bookmark',
                                                                                                            'href'  => 'http://www.w3.org/QA/2010/07/w3c_unicorn_launch_off_to_good.html',
                                                                                                            'class' => 'uri url'
                                                                                                        },
                                                                                                        'W3C Unicorn Launch off to good start'
                                                                                                    ] ]
                                                                                            ],
                                                                                            [
                                                                                                'p',
                                                                                                { 'class' => 'date' },
                                                                                                [ [
                                                                                                        'abbr',
                                                                                                        {
                                                                                                            'class' => 'published',
                                                                                                            'title' => '2010-07-30'
                                                                                                        },
                                                                                                        '30 July 2010'
                                                                                                    ],
                                                                                                    ' by ',
                                                                                                    [
                                                                                                        'span',
                                                                                                        { 'class' => 'author vcard' },
                                                                                                        [ [
                                                                                                                'a',
                                                                                                                {
                                                                                                                    'href'  => 'http://www.w3.org/People/Ted/',
                                                                                                                    'class' => 'fn url'
                                                                                                                },
                                                                                                                'Ted Guild'
                                                                                                            ] ] ] ] ] ]
                                                                                    ],
                                                                                    [
                                                                                        'li',
                                                                                        { 'class' => 'hentry' },
                                                                                        [ [
                                                                                                'p',
                                                                                                { 'class' => 'entry-title' },
                                                                                                [ [
                                                                                                        'a',
                                                                                                        {
                                                                                                            'rel'   => 'bookmark',
                                                                                                            'href'  => 'http://www.w3.org/QA/2010/07/augmented_reality_a_point_of_i.html',
                                                                                                            'class' => 'uri url'
                                                                                                        },
                                                                                                        'Augmented Reality: A Point of Interest for the Web'
                                                                                                    ] ]
                                                                                            ],
                                                                                            [
                                                                                                'p',
                                                                                                { 'class' => 'date' },
                                                                                                [ [
                                                                                                        'abbr',
                                                                                                        {
                                                                                                            'class' => 'published',
                                                                                                            'title' => '2010-07-22'
                                                                                                        },
                                                                                                        '22 July 2010'
                                                                                                    ],
                                                                                                    ' by ',
                                                                                                    [ 'span', { 'class' => 'author vcard' }, 'Phil Archer' ] ] ] ]
                                                                                    ],
                                                                                    [
                                                                                        'li',
                                                                                        { 'class' => 'hentry' },
                                                                                        [ [
                                                                                                'p',
                                                                                                { 'class' => 'entry-title' },
                                                                                                [ [
                                                                                                        'a',
                                                                                                        {
                                                                                                            'rel'   => 'bookmark',
                                                                                                            'href'  => 'http://www.w3.org/QA/2010/07/html5_in_w3c_cheatsheet.html',
                                                                                                            'class' => 'uri url'
                                                                                                        },
                                                                                                        'HTML5 in W3C Cheatsheet'
                                                                                                    ] ]
                                                                                            ],
                                                                                            [
                                                                                                'p',
                                                                                                { 'class' => 'date' },
                                                                                                [ [
                                                                                                        'abbr',
                                                                                                        {
                                                                                                            'class' => 'published',
                                                                                                            'title' => '2010-07-20'
                                                                                                        },
                                                                                                        '20 July 2010'
                                                                                                    ],
                                                                                                    ' by ',
                                                                                                    [
                                                                                                        'span',
                                                                                                        { 'class' => 'author vcard' },
                                                                                                        [ [
                                                                                                                'a',
                                                                                                                {
                                                                                                                    'href'  => 'http://www.w3.org/People/Dom/',
                                                                                                                    'class' => 'fn url'
                                                                                                                },
                                                                                                                "Dominique Haza\x{eb}l-Massieux"
                                                                                                            ] ] ] ] ] ] ] ] ] ]
                                                                    ],
                                                                    [
                                                                        '#comment',
                                                                        '
    <div id="w3c_home_video">
      <h2 class="category">
        <a href="/participate/podcastsvideo">Featured Video
            <img src="/2008/site/images/header-link.gif" alt="Header link" width
="13" height="13" class="header-link"/>
        </a>
      </h2>
      <p>Here</p>
    </div>
    '
                                                                    ],
                                                                    [
                                                                        'div',
                                                                        { 'id' => 'w3c_home_validators_software' },
                                                                        [ [
                                                                                'h2',
                                                                                { 'class' => 'category' },
                                                                                [ [
                                                                                        'a',
                                                                                        { 'href' => 'Status.html' },
                                                                                        [
                                                                                            'Validators, Unicorn, and
Other Software ',
                                                                                            [
                                                                                                'img',
                                                                                                {
                                                                                                    'width'  => '13',
                                                                                                    'alt'    => 'Header link',
                                                                                                    'src'    => '/2008/site/images/header-link.gif',
                                                                                                    'class'  => 'header-link',
                                                                                                    'height' => '13'
                                                                                                } ] ] ] ]
                                                                            ],
                                                                            [
                                                                                'p',
                                                                                [ [
                                                                                        'a',
                                                                                        {
                                                                                            'href'  => 'QA/Tools/Donate',
                                                                                            'class' => 'imageLink no-border'
                                                                                        },
                                                                                        [ [
                                                                                                'img',
                                                                                                {
                                                                                                    'width'  => '80',
                                                                                                    'alt'    => 'I Love Validator',
                                                                                                    'src'    => '/2009/03/I_heart_validator',
                                                                                                    'class'  => 'icon',
                                                                                                    'height' => '15'
                                                                                                } ] ]
                                                                                    ],
                                                                                    ' The W3C
Community has created useful ',
                                                                                    [
                                                                                        'a',
                                                                                        {
                                                                                            'href'
                                                                                                =>
                                                                                                'Status.html'
                                                                                        }
                                                                                        ,
                                                                                        'Open Source
Software'
                                                                                    ],
                                                                                    '. Try ',
                                                                                    [ 'a', { 'href' => 'http://validator.w3.org/unicorn/' }, 'Unicorn' ],
                                                                                    ', W3C\'s unified
validator, to improve the quality of your pages. Unicorn includes
the popular ',
                                                                                    [
                                                                                        'a',
                                                                                        {
                                                                                            'href'  => 'http://validator.w3.org/',
                                                                                            'title' => 'HTML and XHTML Validator'
                                                                                        },
                                                                                        'HTML and markup validator'
                                                                                    ],
                                                                                    ', ',
                                                                                    [
                                                                                        'a',
                                                                                        {
                                                                                            'href'  => 'http://jigsaw.w3.org/css-validator/',
                                                                                            'title' => 'CSS Validator'
                                                                                        },
                                                                                        'CSS
validator'
                                                                                    ],
                                                                                    ', ',
                                                                                    [
                                                                                        'a',
                                                                                        {
                                                                                            'href'  => 'http://validator.w3.org/mobile/',
                                                                                            'title' => 'mobileOK Checker'
                                                                                        },
                                                                                        'mobileOK checker'
                                                                                    ],
                                                                                    ', and more.
Become a ',
                                                                                    [
                                                                                        'a',
                                                                                        {
                                                                                            'href'
                                                                                                =>
                                                                                                'QA/Tools/Donate#donate_sponsors'
                                                                                        }
                                                                                        ,
                                                                                        'validator
sponsor'
                                                                                    ],
                                                                                    '.'
                                                                                ]
                                                                            ],
                                                                            [
                                                                                'p',
                                                                                [ [
                                                                                        'a',
                                                                                        {
                                                                                            'href'  => 'http://www.w3.org/2009/cheatsheet/',
                                                                                            'class' => 'imageLink no-border'
                                                                                        },
                                                                                        [ [
                                                                                                'img',
                                                                                                {
                                                                                                    'alt' => 'Cheatsheet logo',
                                                                                                    'src' => 'http://www.w3.org/2009/cheatsheet/icons/64x'
                                                                                                } ] ]
                                                                                    ],
                                                                                    ' The ',
                                                                                    [ 'a', { 'href' => 'http://www.w3.org/2009/cheatsheet/' }, 'W3C cheatsheet' ],
                                                                                    ' provides
quick access to CSS properties, WCAG tips, mobile tips, and more
(also available on ',
                                                                                    [
                                                                                        'a',
                                                                                        {
                                                                                            'href'
                                                                                                =>
                                                                                                'http://dev.w3.org/2009/cheatsheet/doc/android'
                                                                                        }
                                                                                        ,
                                                                                        'Android
market'
                                                                                    ],
                                                                                    ').'
                                                                                ] ] ]
                                                                    ],
                                                                    [
                                                                        'div',
                                                                        {
                                                                            'id'    => 'w3c_home_member_testimonials',
                                                                            'class' => 'hpmt'
                                                                        },
                                                                        [ [
                                                                                'h2',
                                                                                { 'class' => 'category' },
                                                                                [ [
                                                                                        'a',
                                                                                        { 'href' => '/Consortium/Member/Testimonial/' },
                                                                                        [
                                                                                            'W3C
Member Testimonial ',
                                                                                            [
                                                                                                'img',
                                                                                                {
                                                                                                    'width'  => '13',
                                                                                                    'alt'    => 'Header link',
                                                                                                    'src'    => '/2008/site/images/header-link',
                                                                                                    'class'  => 'header-link',
                                                                                                    'height' => '13'
                                                                                                } ] ] ] ]
                                                                            ],
                                                                            [
                                                                                'div',
                                                                                { 'id' => 'w3c_home_member_testimonials_choice' },
                                                                                [ [
                                                                                        'p',
                                                                                        { 'class' => 'tPadding0' },
                                                                                        [ [
                                                                                                'a',
                                                                                                {
                                                                                                    'rel'   => 'nofollow',
                                                                                                    'href'  => 'http://www.cylex-uk.co.uk',
                                                                                                    'class' => 'no-border'
                                                                                                },
                                                                                                [ [
                                                                                                        'img',
                                                                                                        {
                                                                                                            'width'  => '120',
                                                                                                            'alt'    => 'IKM Internet Kaufmarkt GmbH logo',
                                                                                                            'src'    => '/Consortium/Member/Testimonial/Logo/1086',
                                                                                                            'class'  => 'media',
                                                                                                            'height' => '60'
                                                                                                        } ] ] ] ]
                                                                                    ],
                                                                                    [
                                                                                        'h3',
                                                                                        [ [
                                                                                                'a',
                                                                                                {
                                                                                                    'rel'  => 'nofollow',
                                                                                                    'href' => 'http://www.cylex-uk.co.uk'
                                                                                                },
                                                                                                'IKM Internet Kaufmarkt GmbH'
                                                                                            ] ]
                                                                                    ],
                                                                                    [
                                                                                        'p',
                                                                                        'IKM is one of the leading provider of business directories in the internet. There are available business directories in Germany, the Netherlands, Belgium, UK, Austria or Switzerland, e.g. Our pages are in accordance with the W3C standards.'
                                                                                    ] ]
                                                                            ],
                                                                            [
                                                                                'p',
                                                                                { 'class' => 'more' },
                                                                                [ [
                                                                                        'a',
                                                                                        { 'href' => '/Consortium/Member/Testimonial/List' },
                                                                                        'Read
all member testimonials.'
                                                                                    ] ] ] ] ] ] ] ]
                                                    ],
                                                    [
                                                        '#comment',
                                                        ' end main col '
                                                    ] ] ] ] ] ]
                            ],
                            [
                                '#comment',
                                ' Generated from data/footer.php, ../../smarty/{footer-block.tpl} '
                            ],
                            [
                                'div',
                                { 'id' => 'w3c_footer' },
                                [ [
                                        'div',
                                        { 'id' => 'w3c_footer-inner' },
                                        [ [
                                                'h2',
                                                { 'class' => 'offscreen' },
                                                'Footer Navigation'
                                            ],
                                            [
                                                'div',
                                                { 'class' => 'w3c_footer-nav' },
                                                [ [
                                                        'h3',
                                                        'Navigation'
                                                    ],
                                                    [
                                                        'ul',
                                                        { 'class' => 'footer_top_nav' },
                                                        [ [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/' },
                                                                        'Home'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/standards/' },
                                                                        'Standards'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/participate/' },
                                                                        'Participate'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/Consortium/membership' },
                                                                        'Membership'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                { 'class' => 'last-item' },
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/Consortium/' },
                                                                        'About W3C'
                                                                    ] ] ] ] ] ]
                                            ],
                                            [
                                                'div',
                                                { 'class' => 'w3c_footer-nav' },
                                                [ [
                                                        'h3',
                                                        'Contact W3C'
                                                    ],
                                                    [
                                                        'ul',
                                                        { 'class' => 'footer_bottom_nav' },
                                                        [ [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/Consortium/contact' },
                                                                        'Contact'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'accesskey' => '0',
                                                                            'href'      => '/Help/'
                                                                        },
                                                                        'Help and FAQ'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/Consortium/sup' },
                                                                        'Donate'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        { 'href' => '/Consortium/siteindex' },
                                                                        'Site Map'
                                                                    ] ]
                                                            ],
                                                            [
                                                                'li',
                                                                [ [
                                                                        'address',
                                                                        { 'id' => 'w3c_signature' },
                                                                        [ [
                                                                                'a',
                                                                                { 'href' => 'mailto:site-comments@w3.org' },
                                                                                'Feedback'
                                                                            ],
                                                                            ' (',
                                                                            [
                                                                                'a',
                                                                                { 'href' => 'http://lists.w3.org/Archives/Public/site-comments/' },
                                                                                'archive'
                                                                            ],
                                                                            ')'
                                                                        ] ] ] ] ] ] ]
                                            ],
                                            [
                                                'div',
                                                { 'class' => 'w3c_footer-nav' },
                                                [ [
                                                        'h3',
                                                        'W3C Updates'
                                                    ],
                                                    [
                                                        'ul',
                                                        { 'class' => 'footer_follow_nav' },
                                                        [ [
                                                                'li',
                                                                [ [
                                                                        'a',
                                                                        {
                                                                            'href'  => 'http://twitter.com/W3C',
                                                                            'title' => 'Follow W3C on Twitter'
                                                                        },
                                                                        [ [
                                                                                'img',
                                                                                {
                                                                                    'width'  => '78',
                                                                                    'alt'    => 'Twitter',
                                                                                    'src'    => '/2008/site/images/twitter-bird',
                                                                                    'class'  => 'social-icon',
                                                                                    'height' => '83'
                                                                                } ] ]
                                                                    ],
                                                                    [
                                                                        'a',
                                                                        {
                                                                            'href'  => 'http://identi.ca/w3c',
                                                                            'title' => 'See W3C on Identica'
                                                                        },
                                                                        [ [
                                                                                'img',
                                                                                {
                                                                                    'width'  => '91',
                                                                                    'alt'    => 'Identica',
                                                                                    'src'    => '/2008/site/images/identica-logo',
                                                                                    'class'  => 'social-icon',
                                                                                    'height' => '83'
                                                                                } ] ] ] ] ] ] ] ]
                                            ],
                                            [
                                                '#comment',
                                                ' #footer address / page signature '
                                            ],
                                            [
                                                'p',
                                                { 'class' => 'copyright' },
                                                [
                                                    "Copyright \x{a9} 2010 W3C ",
                                                    [
                                                        'sup',
                                                        "\x{ae}"
                                                    ],
                                                    ' (',
                                                    [
                                                        'a',
                                                        { 'href' => 'http://www.csail.mit.edu/' },
                                                        [ [
                                                                'acronym',
                                                                { 'title' => 'Massachusetts Institute of Technology' },
                                                                'MIT'
                                                            ] ]
                                                    ],
                                                    ', ',
                                                    [
                                                        'a',
                                                        { 'href' => 'http://www.ercim.eu/' },
                                                        [ [
                                                                'acronym',
                                                                { 'title' => 'European Research Consortium for Informatics and Mathematics' },
                                                                'ERCIM'
                                                            ] ]
                                                    ],
                                                    ',
',
                                                    [ 'a', { 'href' => 'http://www.keio.ac.jp/' }, 'Keio' ],
                                                    ') ',
                                                    [
                                                        'a',
                                                        {
                                                            'href' =>
                                                                '/Consortium/Legal/2002/ipr-notice-20021231'
                                                        },
                                                        'Usage policies
apply'
                                                    ],
                                                    '.'
                                                ] ] ] ] ]
                            ],
                            [
                                '#comment',
                                ' /end #footer '
                            ],
                            [
                                '#comment',
                                ' Generated from data/scripts.php, ../../smarty/{scripts.tpl} '
                            ],
                            [
                                'div',
                                { 'id' => 'w3c_scripts' },
                                [ [
                                        'script',
                                        {
                                            'src'  => '/2008/site/js/main',
                                            'type' => 'text/javascript'
                                        },
                                        [ '
//',
                                            [
                                                '#cdata-section',
                                                '
<!-- -->
//'
                                            ] ] ] ] ] ] ] ] ] ] );

    xml_to_ra_ok( $xml, \@expect, 'ginourmous XML document' );
}


sub xml_to_ra_ok {
    my ( $xml, $expect, $desc ) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $got = XML::Crawler::xml_to_ra($xml);

    my $ok = is_deeply( $got, $expect, $desc );

=for exclude

    if ( not $ok ) {
        u s e Data::Dumper;
        local $Data::Dumper::Terse = 1;
        warn '$got => ', Dumper( $got );
        warn '$expect => ', Dumper( $expect );
    }

=cut

    return $ok;
}

