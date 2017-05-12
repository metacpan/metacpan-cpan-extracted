use strict;
use warnings;

use Test::More tests => 6;                      # last test to print
use Test::LWP::Recorder; 
use lib qw(inc);
use LWPx::Record::DataSection;
mkdir 't/LWPtmp';
my $ua = Test::LWP::Recorder->new({
    record => 1,
    cache_dir => 't/LWPtmp', 
    filter_params => [qw(query)],
});
# Die on warning
$SIG{__WARN__} = sub { die shift; };

if ($ENV{LWPX_RECORD_APPEND_DATA}) {
    my $cacheonlyresult = $ua->get('http://www.nytimes.com');
}
my $result = $ua->get('http://www.nytimes.com');

ok(ref $result, "Result was an object");
ok($result->is_success, "Result is a success");
ok($result->content =~ m{Thompson\sConcedes}xms, 
    "Result was from 2013-09-16");


my $ua2 = Test::LWP::Recorder->new({
    record => 0,
    cache_dir => 't/LWPtmp', 
    filter_params => [qw(query)],
});

$result = $ua2->get('http://www.nytimes.com');

ok(ref $result, "Cache result was an object");
ok($result->is_success, "Cache result is a success");
ok($result->content =~ m{Thompson\sConcedes}xms, 
    "Result was from 2013-09-16");




__DATA__

@@ GET http://www.nytimes.com
HTTP/1.1 200 OK
Cache-Control: no-cache
Connection: close
Date: Mon, 16 Sep 2013 16:39:03 GMT
Pragma: no-cache
Server: Apache
Vary: Host
Content-Length: 187973
Content-Type: text/html; charset=UTF-8
Expires: Thu, 01 Dec 1994 16:00:00 GMT

<!DOCTYPE html>
<!--[if IE]><![endif]--> 
<html lang="en">
<head>
<title>The New York Times - Breaking News, World News &amp; Multimedia</title>
<meta name="robots" content="noarchive,noodp,noydir">
<meta name="description" content="Find breaking news, multimedia, reviews &amp; opinion on Washington, business, sports, movies, travel, books, jobs, education, real estate, cars &amp; more.">
<meta name="keywords" content="Washington (DC),Biological and Chemical Warfare,War Crimes, Genocide and Crimes Against Humanity,Syria,United Nations Human Rights Council,Defense and Military Forces,United Nations,Biological and Chemical Warfare,United States International Relations,Syria,Thompson, William C Jr,de Blasio, Bill,Elections, Mayors,United States Economy,Obama, Barack,South Africa,Economic Conditions and Trends,Hewitt, Julian,Hewitt, Ena,Race and Ethnicity,Newtown, Conn, Shooting (2012),Mayors Against Illegal Guns,National Rifle Assn,States (US),Referendums,Gun Control,Cruises,Shipwrecks,Maritime Accidents and Safety,Italy,Vietnam,Veterans,United States Defense and Military Forces,Parenting,Vietnam War,Factories and Manufacturing,Kaesong (North Korea),South Korea,Defense and Military Forces,Muslim Brotherhood (Egypt),Morsi, Mohamed,Middle East and North Africa Unrest (2010- ),Rural Areas,Sisi, Abdul-Fattah el-,Egypt,Demonstrations, Protests, and Riots,Ice Cream and Frozen Desserts,Seaside Park (NJ),Kohr's Frozen Custard,Original Kohr's,Kohr Brothers,Hurricane Sandy (2012),Fires and Firefighters,Family Business,Weight Lifting,Ramos, Don,Doping (Sports),United States Anti-Doping Agency">
<meta name="CG" content="Homepage">
<meta name="SCG" content="">
<meta name="PT" content="Homepage">
<meta name="PST" content="">
<meta name="HOMEPAGE_TEMPLATE_VERSION" content="300">
<meta name="application-name" content="The New York Times" />
<meta name="msapplication-starturl" content="http://www.nytimes.com/" />
<meta name="msapplication-task" content="name=Search;action-uri=http://query.nytimes.com/search/sitesearch?src=iepin;icon-uri=http://css.nyt.com/images/icons/search.ico" />
<meta name="msapplication-task" content="name=Most Popular;action-uri=http://www.nytimes.com/gst/mostpopular.html?src=iepin;icon-uri=http://css.nyt.com/images/icons/mostpopular.ico" />
<meta name="msapplication-task" content="name=Video;action-uri=http://video.nytimes.com/?src=iepin;icon-uri=http://css.nyt.com/images/icons/video.ico" />
<meta name="msapplication-task" content="name=Homepage;action-uri=http://www.nytimes.com?src=iepin&amp;adxnnl=1;icon-uri=http://css.nyt.com/images/icons/homepage.ico" />
<link rel="shortcut icon" href="http://css.nyt.com/images/icons/nyt.ico" />
<link rel="alternate" type="application/rss+xml" title="RSS" href="http://www.nytimes.com/services/xml/rss/nyt/HomePage.xml">
<link rel="alternate" media="handheld" href="http://mobile.nytimes.com">    
<link rel="stylesheet" type="text/css" href="http://css.nyt.com/css/0.1/screen/build/homepage/styles.css">
<link rel="stylesheet" type="text/css" media="print" href="http://css.nyt.com/css/0.1/print/styles.css">  
<!--[if IE]>
    <link rel="stylesheet" type="text/css" href="http://css.nyt.com/css/0.1/screen/build/homepage/ie.css?v=012611">
<![endif]-->
<!--[if IE 6]>
    <link rel="stylesheet" type="text/css" href="http://css.nyt.com/css/0.1/screen/build/homepage/ie6.css">
<![endif]-->
<!--[if lt IE 9]>
	<script src="http://js.nyt.com/js/html5shiv.js"></script>
<![endif]-->
<script type="text/javascript" src="http://js.nyt.com/js2/build/sitewide/sitewide.js"></script>
<script type="text/javascript" src="http://js.nyt.com/js2/build/homepage/top.js"></script>
<!-- ADXINFO classification="blank-but-count-imps" campaign="KRUX_DIGITAL_CONTROL_SCRIPT_LIVE_HP2" priority="9100" isInlineSafe="N" width="1" height="1" --><!-- BEGIN Krux Controltag -->
<script class="kxct" data-id="HrUwtkcl" data-version="async:1.7" type="text/javascript">
  window.Krux||((Krux=function(){Krux.q.push(arguments)}).q=[]);
  (function(){
    var k=document.createElement('script');k.type='text/javascript';k.async=true;var m,src=(m=location.href.match(/\bkxsrc=([^&]+)\b/))&&decodeURIComponent(m[1]);
    k.src=src||(location.protocol==='https:'?'https:':'http:')+'//cdn.krxd.net/controltag?confid=HrUwtkcl';
    var s=document.getElementsByTagName('script')[0];s.parentNode.insertBefore(k,s);
  })();
</script>
<!-- END Krux Controltag -->
</head>
<body id="home">
<a name="top"></a>
<div id="shell">

<ul id="memberTools">

<!-- ADXINFO classification="Share_of_Voice_Tile_-_Left" campaign="nyt2013_bar1_hp_digi_hd_3F4YQ_3F4YL" priority="1000" isInlineSafe="N" width="184" height="90" --><!-- start text link -->
<li class="cColumn-TextAdsHeader">Subscribe:
<a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Bar1&sn2=5b35bc29/49f095e7&sn1=76a23e51/37862598&camp=nyt2013_bar1_hp_digi_hd_3F4YQ_3F4YL&ad=043012-HP_bar1_3F4YQ_3F4YK&goto=http%3A%2F%2Fwww%2Enytimes%2Ecom%2Fsubscriptions%2FMultiproduct%2Flp5558%2Ehtml%3Fadxc%3D210068%26adxa%3D300150%26page%3Dhomepage.nytimes.com/index.html%26pos%3DBar1%26campaignId%3D3F4YQ" target="_blank">
Digital</a> / <a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Bar1&sn2=5b35bc29/49f095e7&sn1=7d8d321f/f1a9d222&camp=nyt2013_bar1_hp_digi_hd_3F4YQ_3F4YL&ad=043012-HP_bar1_3F4YQ_3F4YK&goto=http%3A%2F%2Fnytimesathome%2Ecom%2Fhd%2F142%3FMediaCode%3DW39AA%26CMP%3D3F4YL%26adxc%3D210068%26adxa%3D300150%26page%3Dhomepage.nytimes.com/index.html%26pos%3DBar1%26campaignId%3D3F4YL" target="_blank">Home Delivery</a>
</li>
<!-- end text link -->


                <li><a href="/auth/login?URI=http://">Log In</a></li> 
        <li><a href="/gst/regi.html" onClick="dcsMultiTrack('WT.z_ract', 'Regnow', 'WT.z_rprod', 'Masthead','WT.z_dcsm','1');">Register Now</a></li>
            

</ul>
<div class="mainTabsContainer tabsContainer">
<ul id="mainTabs" class="mainTabs tabs">
<li class="first selected"><a href="http://www.nytimes.com">Home Page</a></li>
<li><a href="http://www.nytimes.com/pages/todayspaper/index.html">Today's Paper</a></li>
<li><a href="http://video.nytimes.com/">Video</a></li>
<li><a href="http://www.nytimes.com/mostpopular">Most Popular</a></li>
</ul>
</div><!--close .tabsContainer -->
<div id="editionToggle" class="editionToggle">
Edition: <span id="editionToggleUS"><a href="http://www.nytimes.com" onmousedown="dcsMultiTrack('DCS.dcssip','www.nytimes.com','DCS.dcsuri','/toggleIHTtoNYT.html','WT.ti','toggleIHTtoNYT','WT.z_dcsm','1');" onclick="NYTD.EditionPref.setUS();">U.S.</a></span> / <span id="editionToggleGlobal"><a href="http://global.nytimes.com" onmousedown="dcsMultiTrack('DCS.dcssip','www.nytimes.com','DCS.dcsuri','/toggleNYTtoIHT.html','WT.ti','toggleNYTtoIHT','WT.z_dcsm','1');" onclick="NYTD.EditionPref.setGlobal();">Global</a></span>
</div><!--close editionToggle -->
<script type="text/javascript"> NYTD.loadEditionToggle(); </script>
<div id="page" class="tabContent active">
<div id="masthead">

<div class="singleAd" id="TopLeft">
<!-- ADXINFO classification="Share_of_Voice_Tile_-_Left" campaign="FoxFall13_SleepyHollow-1888551-nyt9" priority="9100" isInlineSafe="N" width="184" height="90" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=TopLeft&sn2=ab8a95f5/87622a3f&sn1=62b81c3d/7a1ac59b&camp=FoxFall13_SleepyHollow-1888551-nyt9&ad=SleepyHollow.HP.eBlast184x90L&goto=http%3A%2F%2Fad%2Edoubleclick%2Enet%2Fclk%3B275313777%3B102609507%3Bh" target="_blank">
<img src="http://graphics8.nytimes.com/adx/images/ADS/34/75/ad.347502/SleepyHollow_184x90Left.jpg" width="184" height="90" border="0">
</a><A HREF="http://ad.doubleclick.net/jump/N7252.276948.NYTIMES/B7557693.6;sz=1x1;ord=2013.09.16.16.39.03?"><IMG SRC="http://ad.doubleclick.net/ad/N7252.276948.NYTIMES/B7557693.6;sz=1x1;ord=2013.09.16.16.39.03?" BORDER=0 WIDTH=1 HEIGHT=1 ALT="Advertisement" CLASS="Hidden"></A>
</div>


<div class="singleAd" id="TopRight">
<!-- ADXINFO classification="Share_of_Voice_Tile_-_Right" campaign="FoxFall13_SleepyHollow-1888551-nyt9" priority="9100" isInlineSafe="N" width="184" height="90" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=TopRight&sn2=361d9a2f/d5c54928&sn1=8ea6a274/6aeabde0&camp=FoxFall13_SleepyHollow-1888551-nyt9&ad=SleepyHollow.HP.eBlast184x90R&goto=http%3A%2F%2Fad%2Edoubleclick%2Enet%2Fclk%3B275313777%3B102609514%3Bf" target="_blank">
<img src="http://graphics8.nytimes.com/adx/images/ADS/34/75/ad.347503/SleepyHollow_184x90Right.jpg" width="184" height="90" border="0">
</a><A HREF="http://ad.doubleclick.net/jump/N7252.276948.NYTIMES/B7557693.7;sz=1x1;ord=2013.09.16.16.39.03?"><IMG SRC="http://ad.doubleclick.net/ad/N7252.276948.NYTIMES/B7557693.7;sz=1x1;ord=2013.09.16.16.39.03?" BORDER=0 WIDTH=1 HEIGHT=1 ALT="Advertisement" CLASS="Hidden"></A>
</div>


<script type="text/javascript">
              if (/iPad|iPod|iPhone/.test(navigator.userAgent)){
                document.write('<img id="mastheadLogo" width="379" height="64" alt="The New York Times" src="http://i1.nyt.com/svg/nytlogo_379x64.svg">');
              } else {
                document.write('<img id="mastheadLogo" width="379" height="64" alt="The New York Times" src="http://i1.nyt.com/images/misc/nytlogo379x64.gif">');
              }
            </script>
<noscript>
<img id="mastheadLogo" width="379" height="64" alt="The New York Times" src="http://i1.nyt.com/images/misc/nytlogo379x64.gif"/>
</noscript>

<div id="date"><p>Monday, September 16, 2013 <span id="lastUpdate">Last Update: </span><span class="timestamp">12:34 PM ET</span></p></div>
</div><!--end #masthead -->

<div id="toolbar">

<div id="toolbarSearchContainer" class="toolbarSearchContainer-withad">


<div id="toolbarSearch">
<div class="inlineSearchControl">
<form id="searchForm" name="searchForm" method="get" action="http://query.nytimes.com/gst/sitesearch_selector.html" enctype="application/x-www-form-urlencoded">
<input id="hpSearchQuery" name="query" class="text"/>
<input type="hidden" name="type" value="nyt"/>
<input id="searchSubmit" title="Search" width="40" height="19" alt="Search" type="image" src="http://graphics8.nytimes.com/images/global/global_search/search_button40x19.gif">
</form>
</div>

<div id="Middle1C" class="singleAd">
<!-- ADXINFO classification="Button_Ad_88x31_" campaign="ING_DirectSiteSearch13-1850637-nyt1" priority="9000" isInlineSafe="N" width="88" height="31" --><A HREF="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Middle1C&sn2=ead05e9b/336cb178&sn1=a0841e58/f829d125&camp=ING_DirectSiteSearch13-1850637-nyt1&ad=DirectSiteSearch12.ROS.FEB.dart88x31&goto=http://ad.doubleclick.net/jump/N3282.nytimes.comSD6440/B7326326.2;sz=88x31;pc=nyt202539A325775;ord=2013.09.16.16.39.03?" TARGET="_blank">
<IMG SRC="http://ad.doubleclick.net/ad/N3282.nytimes.comSD6440/B7326326.2;sz=88x31;pc=nyt202539A325775;ord=2013.09.16.16.39.03?"
 BORDER=0 WIDTH=88 HEIGHT=31
 ALT="Click Here"></A>
</div>

<div id="HPSiteSearch" style="display:none;"></div>
</div>
</div>
<div id="toolsHome">
<!-- ADXINFO classification="Text_Link" campaign="nyt2013_bar2_hp_hd_3847K" priority="1000" isInlineSafe="N" width="0" height="0" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Bar2&sn2=5b35bc2a/499095e7&sn1=b2ff9000/e74c34c&camp=nyt2013_bar2_hp_hd_3847K&ad=052711-bar2-hd-digi-target-3847K&goto=https%3A%2F%2Fwww%2Enytimesathome%2Ecom%2Fhd%2F142%3FMediaCode%3DW37AA%26CMP%3D3847K%26adxc%3D210077%26adxa%3D267721%26page%3Dhomepage.nytimes.com/index.html%26pos%3DBar2%26campaignId%3D3847K" target="_blank"><img src="http://graphics8.nytimes.com/ads/circulation/icon-newspaper.jpg" height="27" width="40" 

alt="Subscribe to Home
Delivery" align="middle" border="0"/>Subscribe to Home Delivery</a> <span class="pipe">|</span>
<a href="http://www.nytimes.com/weather">Personalize Your Weather</a>
</div>
<div class="socialMediaModule">
<p class="listLabel">Follow Us</p>
<ul class="socialMediaTools flush"><li class="facebook"><a href="http://facebook.com/nytimes"><img class="facebookIcon" src="http://graphics8.nytimes.com/images/article/functions/facebook.gif" alt="Facebook"></a></li><li class="twitter"><a href="http://twitter.com/nytimes"><img class="twitterIcon" src="http://graphics8.nytimes.com/images/article/functions/twitter.gif" alt="Twitter"></a></li></ul>
<span class="pipe">|</span>
</div>
</div><!--end #toolbar -->


<div id="main">
<div class="baseLayout wrap"> 
<div class="nav column">
<div class="hpLeftnav" id="HPLeftNav">
<div class="columnGroup fullWidth">
<div class="navigationHomeLede">
<ul class="flush featured">
<li id="navWorld"><a href="http://www.nytimes.com/pages/world/index.html">World</a></li>
<li id="navUS"><a href="http://www.nytimes.com/pages/national/index.html">U.S.</a></li>
<li id="navPolitics"><a href="http://www.nytimes.com/pages/politics/index.html">Politics</a></li>
<li id="navNYRegion"><a href="http://www.nytimes.com/pages/nyregion/index.html">New York</a></li>
<li id="navBusiness"><a href="http://www.nytimes.com/pages/business/index.html">Business</a></li>
<li id="navDealbook"><a href="http://dealbook.nytimes.com">Dealbook</a></li>
<li id="navTechnology"><a href="http://www.nytimes.com/pages/technology/index.html">Technology</a></li>
<li id="navSports"><a href="http://www.nytimes.com/pages/sports/index.html">Sports</a></li>
<li id="navScience"><a href="http://www.nytimes.com/pages/science/index.html">Science</a></li>
<li id="navHealth"><a href="http://www.nytimes.com/pages/health/index.html">Health</a></li>
<li id="navArts"><a href="http://www.nytimes.com/pages/arts/index.html">Arts</a></li>
<li id="navStyle"><a href="http://www.nytimes.com/pages/style/index.html">Style</a></li>
<li id="navOpinion"><a href="http://www.nytimes.com/pages/opinion/index.html">Opinion</a></li>
</ul>
</div>
</div>
<div class="columnGroup">
<div class="navigationHome">
<ul class="flush primary">
<li class="firstItem singleRule">
<ul class="secondary">
<li><a href="http://www.nytimes.com/pages/automobiles/index.html">Autos</a></li>
<li><a href="http://www.nytimes.com/ref/topnews/blog-index.html">Blogs</a></li>
<li><a href="http://www.nytimes.com/pages/books/index.html">Books</a></li>
<li><a href="http://wordplay.blogs.nytimes.com/cartoons/">Cartoons</a></li>
<li><a href="http://www.nytimes.com/ref/classifieds/?incamp=hpclassifiedsnav">Classifieds</a></li>
<li><a href="http://www.nytimes.com/crosswords/index.html">Crosswords</a></li>
<li><a href="http://www.nytimes.com/pages/dining/index.html">Dining &amp; Wine</a></li>
<li><a href="http://www.nytimes.com/pages/education/index.html">Education</a></li>
<li><a href="http://www.nytimes.com/events/">Event Guide</a></li>
<li><a href="http://www.nytimes.com/pages/fashion/index.html">Fashion &amp; Style</a></li>
<li><a href="http://www.nytimes.com/pages/garden/index.html">Home &amp; Garden</a></li>
<li><a href="http://jobmarket.nytimes.com/pages/jobs/">Jobs</a></li>
<li><a href="http://www.nytimes.com/pages/magazine/index.html">Magazine</a></li>
<li><a href="http://www.nytimes.com/pages/business/media/index.html">Media</a></li>
<li><a href="http://www.nytimes.com/pages/movies/index.html">Movies</a></li>
<li><a href="http://www.nytimes.com/pages/arts/music/index.html">Music</a></li>
<li><a href="http://www.nytimes.com/pages/obituaries/index.html">Obituaries</a></li>
<li><a href="http://publiceditor.blogs.nytimes.com/">Public Editor</a></li>
<li><a href="http://www.nytimes.com/pages/realestate/index.html">Real Estate</a></li>
<li><a href="http://www.nytimes.com/pages/opinion/index.html#sundayreview">Sunday Review</a></li>
<li><a href="http://www.nytimes.com/pages/t-magazine/index.html">T Magazine</a></li>
<li><a href="http://www.nytimes.com/pages/arts/television/index.html">Television</a></li>
<li><a href="http://www.nytimes.com/pages/theater/index.html">Theater</a></li>
<li><a href="http://travel.nytimes.com">Travel</a></li>
<li><a href="http://www.nytimes.com/pages/fashion/weddings/index.html">Weddings / Celebrations</a></li>
</ul>
</li>
<li class="singleRule">
<h6 class="kickerBd">Multimedia</h6>
<ul class="secondary">
<li><a href="http://www.nytimes.com/pages/multimedia/index.html">Interactives</a></li>
<li><a href="http://lens.blogs.nytimes.com/">Photography</a></li>
<li><a href="http://video.nytimes.com/">Video</a></li>
</ul>
</li>
<li class="singleRule">
<h6 class="kickerBd">Tools &amp; more</h6>
<ul class="secondary">
<li><a href="https://myaccount.nytimes.com/mem/tnt.html">Alerts</a></li>
<li><a href="http://beta620.nytimes.com/">Beta 620</a></li>
<li><a href="http://www.nytimes.com/pages/corrections/index.html">Corrections</a></li>
<li><a href="http://www.nytimes.com/nytmobile/">Mobile</a></li>
<li><a href="http://movies.nytimes.com/movies/showtimes.html">Movie Tickets</a></li>
<li><a href="http://www.nytimes.com/learning/index.html">Learning Network</a></li>
<li><a href="http://www.nytimes.com/marketing/newsletters/">Newsletters</a></li>
<li><a href="http://nytimes.whsites.net/timestalks/">NYT Events</a></li>
<li><a href="http://www.nytimes.com/nytstore/?utm_source=nytimes&utm_medium=HPB&utm_content=services_blk&utm_campaign=NYT-HP">NYT Store</a></li>
<li><a href="http://theater.nytimes.com/gst/theater/tabclist.html">Theater Tickets</a></li>
<li><a href="http://timesmachine.nytimes.com/">Times Machine</a></li>
<li><a href="http://www.nytimes.com/timesskimmer/">Times Skimmer</a></li>
<li><a href="http://www.nytimes.com/pages/topics/">Times Topics</a></li>
<li><a href="http://www.nytimes.com/timeswire">Times Wire</a></li>
</ul>
</li>
<li class="singleRule">
<h6 class="kickerBd">Subscriptions</h6>
<ul class="flush secondary multiline">
<li><a href="http://www.nytimes.com/hdleftnav">Home Delivery</a></li>
<li><a href="http://www.nytimes.com/digitalleftnav">Digital Subscriptions</a></li>
<li><a href="http://www.nytimes.com/giftleftnav">Gift Subscriptions</a></li>
<li><a href="http://www.nytimes.com/corporateleftnav">Corporate Subscriptions</a></li>
<li><a href="http://www.nytimes.com/educationleftnav">Education Rate</a></li>
<li><a href="http://www.nytimes.com/crosswordsleftnav">Crosswords</a></li>
<li><a href="http://homedelivery.nytimes.com/HDS/HDSHome.do?mode=HDSHome">Home Delivery Customer Care</a></li>
<li><a href="http://eedition.nytimes.com/cgi-bin/signup.cgi?cc=37FYY">Replica Edition</a></li>
<li><a href="http://subs.iht.com">International Herald Tribune</a></li>
</ul>
</li>
<li class="lastItem singleRule">
<h6 class="kickerBd">Company info</h6>
<ul class="secondary multiline">
<li><a href="http://www.nytco.com/">About NYT Co.</a></li>
<li><a href="http://www.ihtinfo.com/about/history/">About IHT</a></li>
<li><a href="http://www.nytimes.whsites.net/mediakit/">Advertise</a></li>
</ul>
</li>
</ul>
</div><!--close navigationHome -->
</div><!--close columnGroup -->
</div>	<div class="columnGroup singleRule">				


</div>  
&nbsp;
</div><!--close nav -->    




<div id="spanABCRegion" class="abcColumn opening">
<div class="columnGroup first">				
<style type="text/css">
.alertsContainer { margin-left: 10px; margin-right: 9px; padding: 0; border-top: none; margin-top: 0px; }
body.globalEditionHome .alertsContainer { border-top: 1px solid #797979; margin: -1px 0 0 0; padding: 0 9px 0 10px; }
#alertsRegion { font-family: 'nyt-franklin', Arial, sans-serif; color:#808080; }
.wf-loading #alertsRegion { visibility: hidden; }
#alertsRegion h2 { font-size:1.5em; line-height:1.4em; margin-bottom: .0667em; }
#alertsRegion h2 a {color: black; }
#alertsRegion .summary, #alertsRegion li { font-size:1.3em; line-height: 1.31em;  width: 580px;  background-position: left .55em; }
#alertsRegion p { margin-bottom: 1px; }
#alertsRegion li {margin-bottom: .2em; }
#alertsRegion li:last-child {margin-bottom: 0; }
.newsAlert td, .breakingNewsAlert tr td { padding: 4px 0 8px 0; }
.newsAlertMeta, .breakingNewsAlert td.breakingNewsAlertMeta { padding-top: 9px; }
</style>
<div id="extendedNewsAlertText" style="display:none"><dl>

<dt class='headline'>
Snowden Leaves Russian Airport, Lawyer Says
</dt>

<dd class='summary'>
The lawyer said that Edward J. Snowden is permitted to stay in Russia for one year under "temporary asylum" and that he is in an undisclosed location.
</dd>

<dd class='bullet'>

</dd>

<dd class='bullet'>

</dd>

<dd class='bullet'>

</dd>

</dl></div>
<script type="text/javascript">
(function($) {
  var run = function() {
    var matchingHeadline = $.trim($("#extendedNewsAlertText > dl > dt.headline").text());
    $("#alertsRegion .breakingNewsAlert h2").each(function(i, alertNode) {
      if($.trim($(alertNode).text()) == matchingHeadline) {
        $("#extendedNewsAlertText > dl > dd.summary").each(function(i, summaryNode) {
          $(alertNode).parent().append("<p class='summary'>" + $(summaryNode).html() + "</p>");
        });
        var ul = null;
        $("#extendedNewsAlertText > dl > dd.bullet").each(function(i, bulletNode) {
          if ($.trim($(bulletNode).html()) != "") {
            if(ul == null) {
              ul = $("<ul></ul>");
              $(alertNode).parent().append(ul);
            }
            ul.append("<li>" + $(bulletNode).html() + "</li>");
          }
        });
      }
    });
  };
  $("#spanABCRegion").removeClass("opening");
  if($("#alertsRegion .breakingNewsAlert h2").length > 0) {
    run();
  } else {
    $(run);
  }
  $(function() {
    if($("#spanABCRegion .columnGroup div").not($("#extendedNewsAlertText")).length > 0) {
      $("#spanABCRegion").addClass("opening");
    }
  });
})(NYTD.jQuery);
</script>	</div>
</div><!--close abcColumn -->
<div class="column last">
<div class="spanAB">
<div class="abColumn">

<!--start lede package -->        
<div class="wideB noBackground opening module" id="ledePackageRegion">
<div class="aColumn">
<div id="aLedePackageRegion">
<div class="columnGroup first">				
<div class="story">
<h2><a href="http://www.nytimes.com/2013/09/17/us/shooting-reported-at-washington-navy-yard.html?hp">
Gunman Said
to Be Killed in
Deadly Attack
at Navy Yard</a></h2>
<h6 class="byline">
By MICHAEL D. SHEAR        <span class="timestamp" data-eastern-timestamp="12:28 PM" data-utc-timestamp="1379348908000"></span>
</h6>
<p class="summary">
The police said a shooter was killed Monday morning after a shooting that involved multiple fatalities at a naval office building not far from Capitol Hill and the White House, officials said. The authorities said they were searching for two other possible shooters.    </p>
</div>
</div>
</div>
</div>
<div class="bColumn">
<div id="bLedePackageRegion"> 
<div class="columnGroup first">				
<style type="text/css">
#photoSpotRegion .ledePhoto, #bLedePackageRegion .ledePhoto, #spanABTopRegion .ledePhoto { visibility: hidden; }

#photoSpotRegion #ledePackageMMWidget .ledePhoto, #bLedePackageRegion #ledePackageMMWidget .ledePhoto, #spanABTopRegion #ledePackageMMWidget .ledePhoto, #tabbedNewsModule #ledePackageMMWidget .ledePhoto { visibility: visible; }
</style>    <div class="story" id="ledePhotoStory">
<div class="ledePhoto" id="ledePhoto">
<div class="image">
<a href="http://www.nytimes.com/2013/09/17/us/shooting-reported-at-washington-navy-yard.html?hp"><img width="337" height="253" alt="" src="http://i1.nyt.com/images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-hpMedium.jpg"/></a>
</div>
<h6 class="credit">Jason Reed/Reuters</h6>
</div>
</div>
<script src='http://graphics8.nytimes.com/js/app/common/slideshow/embeddedSlideshowBuilder.js' type='text/javascript'></script><script type='text/javascript'>var data;function jsonSlideshowCallback(response) {data = response;}NYTD.options = {source: '+ data +', cropType: 'hpMedium', appendTo: 'ledePhoto', showHeadLine: 'false'}</script><link href='http://graphics8.nytimes.com/css/0.1/screen/slideshow/modules/slidingGallery.css' type='text/css' rel='stylesheet'/><script src='http://json8.nytimes.com/slideshow/2013/09/16/us/20130917_dcshoot_hp.slideshow.jsonp' type='text/javascript'></script><script>new NYTD.embeddedSlideshowBuilder(NYTD.options);</script>	</div>
</div>
</div>            
</div>
<div class="doubleRuleDivider insetH flushBottom"></div>
<div class="wideB module">
<div class="aColumn opening">
<div class="columnGroup first">				
<style>
  .wf-loading #nytDesignWrap {
    visibility: hidden;
  }

  #nytDesignWrap {
    position: relative;
  }

  #nytDesignWrap h5 {
    padding-bottom: 5px;
    font-family: "nyt-franklin",arial,helvetica,sans-serif;
    font-style: normal;
    font-weight: 800;
    font-size: 13px;
    line-height: 13px;
    color: black;
    text-transform: uppercase;
  }
  #nytDesignWrap a {color:#000;}
  #nytDesignWrap a:hover {text-decoration: none;}

  #nytDesignWrap .singleRule {
    z-index: -1;
    position: relative;
    top: -2px;
    padding-top: 0;
    margin-bottom: 6px;
    border-color: #1a1a1a;
  }
</style>
<div id="nytDesignWrap">
<h5><a href="http://projects.nytimes.com/live-dashboard/syria?hp">Crisis in Syria</a></h5>
<div class="singleRule"></div>
</div>	<div class="story">
<h3><a href="http://www.nytimes.com/2013/09/17/world/europe/syria-united-nations.html?hp">
Chemical Arms Used
in Rocket Attack in
Syria, U.N. Confirms</a></h3>
<h6 class="byline">
By RICK GLADSTONE and NICK CUMMING-BRUCE        <span class="timestamp" data-eastern-timestamp="12:10 PM" data-utc-timestamp="1379347841000"></span>
</h6>
<p class="summary">
The report by weapons investigators was the first confirmation by independent scientific experts that chemical weapons were used in the attack outside Damascus.    </p>
</div>
<link rel="stylesheet" type="text/css" href="http://graphics8.nytimes.com/projects/2013/syria-hp-promo/live_updates_banner.css?v=7">
<!--NOTE: to switch between "LIVE" and "LATEST" treatments, just change class on container.
For LIVE: class="live"
FOR LATEST: class="latest"
Promo adjusts styles for a and b column automatically.
 --><div class="story" style="margin-top:8px;">
<div id="nytint-syria-updates-banner" class="latest">
<h5>
<strong class="live">live</strong>
<strong class="latest">latest</strong>
<a href="http://projects.nytimes.com/live-dashboard/syria?hp" class="short">Syria Updates</a>
<a href="http://projects.nytimes.com/live-dashboard/syria?hp" class="full">Updates on the Crisis in Syria</a>
</h5>
<!--p>The Times is tracking the international response.
</p-->
</div>
</div>	<script>function getFlexData() { return {"data":{"options":{"feed_type":"dashboard","src":"http:\/\/d3iwqfew33lf4i.cloudfront.net\/live_dashboard\/syria\/live_updates.js","limit":1,"auto_refresh":true,"refresh_time":30,"show_loader":false,"show_summary":false,"num_summary_words":0,"show_scroller":false,"scroller_type":"","module_height":0,"show_view_all_updates":false,"ipad_app_links":false,"ipad_url":""},"tabs":{"id":"latest_updates","title":"Latest Updates","link":"","current":true,"filters":{"type":"type","name":"live_blog"}}}}; }NYTD.FlexTypes = NYTD.FlexTypes || []; NYTD.FlexTypes.push({"target":"FT100000002433533","type":"HPLiveUpdate","data":{"options":{"feed_type":"dashboard","src":"http:\/\/d3iwqfew33lf4i.cloudfront.net\/live_dashboard\/syria\/live_updates.js","limit":1,"auto_refresh":true,"refresh_time":30,"show_loader":false,"show_summary":false,"num_summary_words":0,"show_scroller":false,"scroller_type":"","module_height":0,"show_view_all_updates":false,"ipad_app_links":false,"ipad_url":""},"tabs":{"id":"latest_updates","title":"Latest Updates","link":"","current":true,"filters":{"type":"type","name":"live_blog"}}}});</script><link rel="stylesheet" href="http://graphics8.nytimes.com/packages/css/multimedia/bundles/projects/2012/HPLiveDebateFlex.css" />
<script src="http://graphics8.nytimes.com/packages/js/multimedia/libs/jquery-1.7.1.min.js"></script>
<script src="http://graphics8.nytimes.com/packages/js/multimedia/bundles/projects/2012/HPLiveDebateFlex.js"></script><div id="FT100000002433533"></div>	</div>
<div class="columnGroup ">				
<div class="story">
<h3><a href="http://www.nytimes.com/2013/09/17/world/europe/us-and-allies-tell-syria-to-dismantle-chemical-arms-quickly.html?hp">
U.S. and Allies Push
for Strong Measure
on Syria’s Arms</a></h3>
<h6 class="byline">
By MICHAEL R. GORDON        <span class="timestamp" data-eastern-timestamp=" 7:53 AM" data-utc-timestamp="1379332416000"></span>
</h6>
<p class="summary">
Secretary of State John Kerry and the foreign ministers of France and Britain said that they would not tolerate delays in dismantling Syria’s chemical weapons.    </p>
</div>
<div class="singleRuleDivider"></div>	</div>
<div class="columnGroup last">				
<div class="story">
<h3><a href="http://www.nytimes.com/2013/09/17/nyregion/thompson-to-concede-to-de-blasio-in-mayoral-primary.html?hp">
Thompson Concedes
to de Blasio in
Mayoral Primary</a></h3>
<h6 class="byline">
By MICHAEL BARBARO and THOMAS KAPLAN        <span class="timestamp" data-eastern-timestamp="11:48 AM" data-utc-timestamp="1379346499000"></span>
</h6>
<p class="summary">
William C. Thompson Jr., who had been holding out for the chance of a runoff vote, withdrew from the mayor’s race, ending his second bid to run the city.    </p>
<ul class="refer commentsRefer">
<li  style="background-image: none; padding-left: 0pt;"><span class="commentCountLink" articleid="http://www.nytimes.com/2013/09/17/nyregion/thompson-to-concede-to-de-blasio-in-mayoral-primary.html" overflowurl="http://community.nytimes.com/comments/www.nytimes.com/2013/09/17/nyregion/thompson-to-concede-to-de-blasio-in-mayoral-primary.html?hp&target=comments" articletitle="Thompson Concedes
to de Blasio in
Mayoral Primary"></span></li>
</ul>
</div>
</div>
</div><!--close aColumn -->
<div class="bColumn opening">
<div class="columnGroup first">				
<div class="story">
<h5><a href="http://www.nytimes.com/2013/09/17/us/politics/obama-to-release-report-on-response-to-financial-crisis.html?hp">
Obama to Release Report on Financial Crisis</a></h5>
<h6 class="byline">
By MICHAEL D. SHEAR        <span class="timestamp" data-eastern-timestamp="11:38 AM" data-utc-timestamp="1379345918000"></span>
</h6>
<p class="summary">
The report argues that the economy is improving, but acknowledges that recovery has been sluggish.    </p>
<ul class="refer commentsRefer">
<li><a href="javascript:pop_me_up2('http://www.whitehouse.gov/live/president-obama-speaks-five-year-anniversary-financial-crisis',%20'1000_600',%20'width=1000,height=600,location=no,scrollbars=yes,toolbars=no,resizable=yes')"><img src="http://graphics8.nytimes.com/images/multimedia/icons/video_icon.gif" alt="" border="0" height="9" width="12"> Video: President Obama Speaking</a> (Whitehouse.gov) <span class="timestamp">Live</span></li>
<li><a href="http://www.nytimes.com/2013/09/16/business/economy/summers-pulls-name-from-consideration-for-fed-chief.html">Democrats’ Unease Recasts Contest to Lead the Federal Reserve</a></li>
</ul>
</div>
</div>
<div class="columnGroup ">				
<div class = "story">
<h6 class = "kicker">Mamelodi Journal</h6>
<h5><a href = "http://www.nytimes.com/2013/09/16/world/africa/trading-privilege-for-privation-family-hits-a-nerve-in-south-africa.html?hp">
Trading Privilege for Privation, and Hitting Nerve</a></h5>
<div class = "thumbnail runaroundRight" style = "margin-top: 4px">
<a href = "http://www.nytimes.com/2013/09/16/world/africa/trading-privilege-for-privation-family-hits-a-nerve-in-south-africa.html?hp">
<img src = "http://i1.nyt.com/images/2013/09/16/world/0916SAFRICAjp01/0916SAFRICAjp01-thumbStandard.jpg" width = "75" 
            height = "75" 
            alt = "Ena Hewitt and her daughter Julia by their shack in the Phomolong squatter camp in South Africa. The Hewitt family’s decision to spend a month in the poor black community set off a debate." border = "0" />
</a>
</div>
<h6 class = "byline">
By LYDIA POLGREEN        <span class="timestamp" data-eastern-timestamp="10:32 PM" data-utc-timestamp="1379298759000"></span>
</h6>
<p class="summary">
A white middle-class family’s decision to move to a poor black township in South Africa had many debating whether it was about empathy or slum tourism.    </p>
<ul class = "refer commentsRefer">
<li  style = "background-image: none; padding-left: 0pt;">
<span class = "commentCountLink" articleid = "http://www.nytimes.com/2013/09/16/world/africa/trading-privilege-for-privation-family-hits-a-nerve-in-south-africa.html" 
                                overflowurl = "http://community.nytimes.com/comments/2013/09/16/world/africa/trading-privilege-for-privation-family-hits-a-nerve-in-south-africa.html?hp&target=comments" articletitle="Trading Privilege for Privation, and Hitting Nerve"></span>
</li>
</ul>
</div>	</div>
<div class="columnGroup ">				
<div class="story">
<h5><a href="http://www.nytimes.com/2013/09/16/us/in-gun-debate-divide-grows-as-both-sides-dig-in-for-battle.html?hp">
In Gun Debate, Rift Grows as Both Sides Dig In</a></h5>
<h6 class="byline">
By ERICA GOODE        <span class="timestamp" data-eastern-timestamp=" 9:54 PM" data-utc-timestamp="1379296490000"></span>
</h6>
<p class="summary">
Recent losses have hurt the hopes of backers of tougher gun laws, and both sides are preparing for new battles.    </p>
<ul class="refer commentsRefer">
<li  style="background-image: none; padding-left: 0pt;"><span class="commentCountLink" articleid="http://www.nytimes.com/2013/09/16/us/in-gun-debate-divide-grows-as-both-sides-dig-in-for-battle.html" overflowurl="http://community.nytimes.com/comments/www.nytimes.com/2013/09/16/us/in-gun-debate-divide-grows-as-both-sides-dig-in-for-battle.html?hp&target=comments" articletitle="In Gun Debate, Rift Grows as Both Sides Dig In"></span></li>
</ul>
</div>
</div>
<div class="columnGroup ">				
<div class = "story">
<h5><a href = "http://www.nytimes.com/2013/09/17/world/europe/operation-to-raise-costa-concordia-cruise-liner-in-italy.html?hp">
In Italy, Effort to Raise Sunken Cruise Ship</a></h5>
<div class = "thumbnail runaroundRight" style = "margin-top: 4px">
<a href = "http://www.nytimes.com/2013/09/17/world/europe/operation-to-raise-costa-concordia-cruise-liner-in-italy.html?hp">
<img src = "http://i1.nyt.com/images/2013/09/17/world/europe/17costa3_cnd/17costa3_cnd-thumbStandard-v2.jpg" width = "75" 
            height = "75" 
            alt = "People watched the salvage operation for the Costa Concordia from a hilltop on Giglio Island, Italy, on Monday. " border = "0" />
</a>
</div>
<h6 class = "byline">
By GAIA PIANIGIANI and ALAN COWELL        <span class="timestamp" data-eastern-timestamp="11:44 AM" data-utc-timestamp="1379346291000"></span>
</h6>
<p class="summary">
After delays caused by an overnight storm, a potentially hazardous operation began to right the Costa Concordia, the cruise liner that ran aground off Italy’s coast in 2012.    </p>
<ul class = "refer commentsRefer">
<li><a href="javascript:pop_me_up2('http://www.nytimes.com/packages/html/video/live-popout-player.html',%20'1000_600',%20'width=1000,height=600,location=no,scrollbars=yes,toolbars=no,resizable=yes')"><img src="http://graphics8.nytimes.com/images/multimedia/icons/video_icon.gif" alt="" height="9" width="12" border="0"> Video: Raising the Costa Concordia</a> <span class="timestamp">Live</span></li>
</ul>
</div>	</div>
<div class="columnGroup ">				
<div class="story">
<h5><a href="http://www.nytimes.com/2013/09/16/us/vietnam-legacy-finding-gi-fathers-and-children-left-behind.html?hp">
In Vietnam, Finding Families Torn Apart</a></h5>
<h6 class="byline">
By JAMES DAO        <span class="timestamp" data-eastern-timestamp="10:50 PM" data-utc-timestamp="1379299818000"></span>
</h6>
<p class="summary">
For aging veterans and their half-Vietnamese children, the need to find one another has become urgent.    </p>
<ul class="refer commentsRefer">
<li  style="background-image: none; padding-left: 0pt;"><span class="commentCountLink" articleid="http://www.nytimes.com/2013/09/16/us/vietnam-legacy-finding-gi-fathers-and-children-left-behind.html" overflowurl="http://community.nytimes.com/comments/www.nytimes.com/2013/09/16/us/vietnam-legacy-finding-gi-fathers-and-children-left-behind.html?hp&target=comments" articletitle="In Vietnam, Finding Families Torn Apart"></span></li>
</ul>
</div>
</div>
<div class="columnGroup ">				
<h6 class="kicker">More News</h6>
<div class="story">
<ul class="headlinesOnly">
<li>
<h5><a href="http://www.nytimes.com/2013/09/17/us/more-rain-expected-as-colorado-rescuers-wait-for-fog-to-lift.html?hp">
Helicopters Stymied in Colorado Rescue</a>
<span class="timestamp">9:12 AM ET</span>
</h5>
</li>                    <li>
<h5><a href="http://www.nytimes.com/2013/09/17/world/asia/jointly-run-factory-park-in-north-korea-resumes-production.html?hp">
Factory Park in North Korea Reopens</a>
<span class="timestamp" data-eastern-timestamp=" 2:10 AM" data-utc-timestamp="1379311810000"></span>
</h5>
</li>
<li>
<h5><a href="http://www.nytimes.com/2013/09/16/world/middleeast/reach-of-turmoil-in-egypt-extends-into-countryside.html?hp">
Turmoil in Egypt Extends to Countryside</a>
<span class="timestamp" data-eastern-timestamp=" 7:34 PM" data-utc-timestamp="1379288094000"></span>
</h5>
</li>
<li>
<h5><a href="http://www.nytimes.com/2013/09/16/nyregion/a-much-loved-family-business-meets-disaster-again-on-the-shore.html?hp">
A Jersey Shore Institution Meets Disaster Again</a>
<span class="timestamp" data-eastern-timestamp="11:27 PM" data-utc-timestamp="1379302076000"></span>
</h5>
</li>
</ul>
</div>
</div>
<div class="columnGroup last">				
<h6 class="kicker">On the Blogs</h6>
<div class="story">
<ul class="headlinesOnly">
<li>
<h5><a href="http://thelede.blogs.nytimes.com/2013/09/16/a-bahraini-activists-message-from-prison/?hp">
The Lede:    Bahraini Activist’s Message From Prison</a></h5>
</li>
<li>
<h5><a href="http://bits.blogs.nytimes.com/2013/09/16/when-tech-turns-nouns-into-verbs/?hp">
Bits:    When Tech Turns Nouns Into Verbs</a></h5>
</li>
<li>
<h5><a href="http://economix.blogs.nytimes.com/2013/09/16/subsidizing-spouses/?hp">
Economix:    Subsidizing Spouses</a></h5>
</li>
</ul>
</div>
</div>
</div><!--close bColumn -->
</div><!--close wideB -->
<div class="wideA">
<div class="aColumn">
<div class="columnGroup doubleRule">
<div id="extendedVideoPlayerModule" class="extendedVideoPlayerModule extendedVideoPlayerLegacyModule">
<div class="extVidPlayerHeader clearfix">
<a href="http://www.nytimes.com/video/" class="extVidPlayerMainHeaderLink">Video &raquo;</a>
<a href="http://www.nytimes.com/video?src=vidm" class="extVidPlayerSectionHeaderLink" target="_blank"> More Video &raquo;</a>
</div>
<div class="videoContainer">
<div class="extendedVideoPocketPlayerContainer"></div>
<div class="videoShare shareTools shareToolsThemeClassic shareToolsThemeClassicHorizontal slideshowShareTools" 
            data-shares="showall|Share,email|E-mail,twitter|Twitter,facebook|Facebook" 
            data-url="" 
            data-title="" 
            data-description="">
</div>
<div class="videoDetails">
<p class="kicker"></p>
<a href="#" class="shortDescription" target="_blank"></a>
<p class="longDescription"></p>
</div>
</div>
<div class="extVidPlayerThumbsContainer">
<div class="extVidPlayerThumbsContainerShadow"></div>
<div class="extVidPlayerNav clearfix">
<div class="extVidPlayerNavContent clearfix">
<a href="#" class="previousVideo previousVideoInactive">previous</a>
<a href="#" class="nextVideo">next</a>
</div>
</div>
<div id="extVidPlayerThumbsWrapper" class="extVidPlayerThumbsWrapper">
<ul id="extVidPlayerThumbs" class="videoThumbs clearfix"></ul>
</div>
</div>
</div>
<script type="text/javascript" src="http://js.nyt.com/js2/build/video/2.0/videofactory.js"></script>
<script type="text/javascript" src="http://js.nyt.com/js2/build/video/players/extended/1.0/app.js"></script>
<script type="text/javascript">
    var player = new NYTD.video.players.Extended({
        container: "extendedVideoPlayerModule",
        referenceId: "1194811622188",
        thumbWidth: 90,
        videoWidth: '100%',
        videoHeight: '100%'
    });
</script>                                    </div>
</div><!--close aColumn -->
<div class="bColumn">
<div class="columnGroup doubleRule">
<div id="pocketRegion" class="module">
<div class="columnGroup first">				
<div class="story">
<h5><a href="http://www.nytimes.com/2013/09/16/sports/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html?hp">
Labeled a Cheat, but He Has a Story</a></h5>
<h6 class="byline">
By JOHN BRANCH        <span class="timestamp" data-eastern-timestamp="11:26 PM" data-utc-timestamp="1379301972000"></span>
</h6>
<div class="thumbnail">
<a href="http://www.nytimes.com/2013/09/16/sports/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html?hp">
<img src="http://i1.nyt.com/images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-thumbStandard.jpg" width="75" height="75" alt="" border="0" />
</a>
</div>
<p class="summary">
Don Ramos, who holds several weight-lifting world records for his age group, has had a Forrest Gumpian odyssey, 80 years of life that were nullified by one drug test.    </p>
<ul class="refer commentsRefer">
<li  style="background-image: none; padding-left: 0pt;"><span class="commentCountLink" articleid="http://www.nytimes.com/2013/09/16/sports/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html" overflowurl="http://community.nytimes.com/comments/2013/09/16/sports/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html?hp&target=comments" articletitle="Labeled a Cheat, but He Has a Story"></span></li>
</ul>
</div>
</div>
<div class="columnGroup ">				
<div class="doubleRuleDivider"></div>	</div>
<div class="columnGroup last">				
<h6 class="kicker"><a href="http://www.nytimes.com/pages/aponline/index.html">News from A.P.</a> & <a href="http://www.nytimes.com/pages/reuters/index.html">Reuters</a> »</h6>
<div class="story">
<h6><a href="http://www.nytimes.com/reuters/2013/09/16/sports/olympics/16reuters-russia-olympics-putin.html?hp">
<!---->
Putin Sees Delays in Russian Olympic Preparations</a>
</h6>
<span class="timestamp" data-eastern-timestamp="12:27 PM" data-utc-timestamp="1379348858000"></span>
</div>
<div class="story">
<h6><a href="http://www.nytimes.com/aponline/2013/09/16/us/ap-us-business-leaders-butte.html?hp">
<!---->
Big-Business Leaders Talk Tax Code at Mont. Summit</a>
</h6>
<span class="timestamp" data-eastern-timestamp="12:29 PM" data-utc-timestamp="1379348943000"></span>
</div>
<div class="story">
<h6><a href="http://www.nytimes.com/aponline/2013/09/16/us/politics/ap-us-united-states-china.html?hp">
<!---->
Kerry to Meet With Chinese Foreign Minister</a>
</h6>
<span class="timestamp" data-eastern-timestamp="12:26 PM" data-utc-timestamp="1379348773000"></span>
</div>
<div class="story">
<h6><a href="http://www.nytimes.com/aponline/2013/09/16/us/ap-us-cluster-balloon-flight.html?hp">
<!---->
1st Solo Trans-Atlantic Balloonist Supported Quest</a>
</h6>
<span class="timestamp" data-eastern-timestamp="12:25 PM" data-utc-timestamp="1379348757000"></span>
</div>
</div>
</div><!--close pocketRegion -->
</div>
</div><!--close bColumn -->
</div><!--close wideA -->
<!--end lede package -->       
</div><!--close abColumn -->
<div class="cColumn">


<div id="cColumnTopSpanRegion">
<div class="columnGroup first">				
<div class="opinionModule">
<h4 class="sectionHeaderHome"><a href="http://www.nytimes.com/pages/opinion/index.html"><img src="http://graphics8.nytimes.com/images/opinion/homepage/opinionPagesHpC337.png" /></a>
</h4>
<div class="subColumn-2 wrap layout ">
<div class="column">
<div class="insetH">
<div class="story">
<h5><a href="http://www.nytimes.com/roomfordebate/2013/09/15/is-creativity-endangered?hp">Is Creativity Dying?
</a>
</h5>
<div class="thumbnail runaroundRight"><a href="http://www.nytimes.com/roomfordebate/2013/09/15/is-creativity-endangered?hp"><img src="http://graphics8.nytimes.com/images/2010/07/09/opinion/09rfd-image/09rfd-image-custom4.jpg" height="50" width="50" /></a>
</div>
<p class="summary flushBottom">Education, geography, management styles: What suppresses innovation, and what
nurtures it?</p>
</div>
</div>
</div>
<div class="column lastColumn">
<div class="insetH">
<ul class="headlinesOnly">
<li><a href="http://www.nytimes.com/2013/09/16/opinion/the-syrian-pact.html?hp">Editorial: The Syrian Pact</a>
</li>
<li><a href="http://www.nytimes.com/2013/09/16/opinion/how-to-fall-in-love-with-math.html?hp">Op-Ed: Loving Math</a>
</li>
<li><a href="http://opinionator.blogs.nytimes.com/2013/09/14/lifelines-for-poor-children/?hp">The Great Divide: Lifelines for Poor Children</a>
</li>
<li><a href="http://www.nytimes.com/2013/09/16/opinion/keller-the-missing-partner.html?hp">Keller: The Missing Partner</a>
</li>
<li><a href="http://www.nytimes.com/2013/09/16/opinion/krugman-give-jobs-a-change.html?hp">Krugman: Give Jobs a Chance</a>
</li>
</ul>
</div>
</div>
</div>
</div>	<div class="singleRuleDivider"></div>	</div>
</div><!--close cColumnTopSpanRegion -->


<div class="columnGroup first">				
<div class="columnGroup fullWidth flushBottom">
<div class="subColumn-2 wrap noBackground layout">
<div class="column">
<div class="columnGroup flushBottom">	<script type="text/javascript">
  <!--
    function insertWSODModule(file){
      var doc  = document.getElementsByTagName('head').item(0);
      var rnd  = "?"+ Math.random();
      var wsod = document.createElement('script');
      wsod.setAttribute('language','javascript');
      wsod.setAttribute('type','text/javascript');
      wsod.setAttribute('src',file+rnd);
      doc.appendChild(wsod);
    }
  
  //-->
</script>
<div id="wsodMarkets">
<div id="wsodMarketsChart"></div>
<script type="text/javascript"><!--
insertWSODModule("http://markets.on.nytimes.com/research/modules/home/home.asp");
//--></script>
<form id="wsodFormHome" class="searchForm" method="get" action="http://query.nytimes.com/gst/getquotes.html">
<div><label for="qsearchQuery">Get Quotes</label>
<p id="myPortfolios"><a href="http://markets.on.nytimes.com/research/portfolio/view/view.asp">My Portfolios »</a></p>
<input id="qsearchQuery" name="symb" type="text" onblur="if(this.value=='')this.value='Stock, ETFs, Funds';" onfocus="if(this.value=='Stock, ETFs, Funds')this.value='';" value="Stock, ETFs, Funds" />
<div class="querySuggestions" style="display:none"></div>
<input id="searchSubmit" type="image" src="http://graphics8.nytimes.com/images/global/buttons/go.gif"></div>
</form>
</div>	</div>
</div>
<div class="column lastColumn">
<div class="columnGroup flushBottom">
<div id="Middle4"><!-- ADXINFO classification="Share_of_Voice_Tile_-_Right" campaign="nyt2013_163x90_digi_hp_M4_3J3H8" priority="8000" isInlineSafe="N" width="184" height="90" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Middle4&sn2=1523368b/d11e58cc&sn1=c4d3eb47/670bc936&camp=nyt2013_163x90_digi_hp_M4_3J3H8&ad=163x90_acquisition_99cent_3J3H8&goto=http%3A%2F%2Fwww%2Enytimes%2Ecom%2Fsubscriptions%2FMultiproduct%2Flp5558%2Ehtml%3Fadxc%3D210766%26adxa%3D324936%26page%3Dhomepage.nytimes.com/index.html%26pos%3DMiddle4%26campaignId%3D3J3H8" target="_blank">
<img src="http://graphics8.nytimes.com/adx/images/ADS/32/49/ad.324936/12-2398_DigitalAcquisition_163x90_NF1.jpg" width="163" height="90" border="0">
</a>

<script> Krux('admEvent', 'ICdF6_0U', { Campaign_ID:"nyt2013_163x90_digi_hp_M4_3J3H8",Page:"homepage.nytimes.com/index.html", Position:"Middle4"}); </script></div>
</div>
</div>
</div>
</div>	</div>
<div id="cColumnAboveMothRegion">
<div class="columnGroup first">				

<div class="singleAd" id="HPMiddle">
<!-- ADXINFO classification="Big_Ad_-_Standard" campaign="FoxFall13_SleepyHollow-1888551-nyt9" priority="9100" isInlineSafe="N" width="300" height="250" --><div align="center"><script src="http://bs.serving-sys.com/BurstingPipe/adServer.bs?cn=rsb&c=28&pli=7720397&PluID=0&w=300&h=250&ord=2013.09.16.16.39.03&z=2147483647"></script>
<noscript>
<a href="http://bs.serving-sys.com/BurstingPipe/adServer.bs?cn=brd&FlightID=7720397&Page=&PluID=0&Pos=1016414257" target="_blank"><img src="http://bs.serving-sys.com/BurstingPipe/adServer.bs?cn=bsr&FlightID=7720397&Page=&PluID=0&Pos=1016414257" border=0 width=300 height=250></a>
</noscript></div>
</div>

</div>
<div class="columnGroup first">				
<div class="singleRuleDivider"></div>
<div class="columnGroup fullWidth flushBottom">
<div class="subColumn-2 wrap noBackground layout">
<div class="column">
<div class="columnGroup flushBottom">	<h4 class="sectionHeaderHome"><a href="http://www.nytimes.com/business/media?src=dayp">Media & Advertising »</a></h4>
<div class="story">
<h5><a href="http://www.nytimes.com/2013/09/16/business/media/movie-industry-wants-to-get-a-handle-on-the-digital-box-office.html?ref=business?src=dayp">
Hollywood and the Digital Box Office 
</a></h5>
<div class="runaroundRight">
<a href="http://www.nytimes.com/2013/09/16/business/media/movie-industry-wants-to-get-a-handle-on-the-digital-box-office.html?ref=business?src=dayp">
<img src="http://graphics8.nytimes.com/images/2013/09/16/business/trackingjump/trackingjump-thumbStandard.jpg" alt="MGM Studio Appears to Be a Moneymaker Again" width="75" height="75" />
</a></div>
<p class="summary">
Some in the film business are chafing about a lack of open information on how movies perform in on-demand channels.
</p>
</div>
<!--end of first daypart promo code, don't touch the column code below -->
</div></div><div class="column lastColumn"><div class="columnGroup flushBottom"><h4 class="sectionHeaderHome"> </h4>
<!--- insert second daypart promo below -->
<div class="story">
<h6 class="kicker">The Media Equation</h6>
<h5><a href="http://www.nytimes.com/2013/09/16/business/media/storytelling-ads-may-be-journalisms-new-peril.html?ref=media?src=dayp">
Storytelling Ads May Be Journalism’s New Peril
</a></h5>
<p class="summary">
Some say native advertising could dilute the power of a brand over time, David Carr writes.
</p>
</div>	<div id="Middle5"><!-- ADXINFO classification="Home_Page_Advantage" campaign="nyt2013_163x90_iOSPhone_hp_3HU9X" priority="1000" isInlineSafe="N" width="163" height="90" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Middle5&sn2=1523368c/d15e58cc&sn1=63a981ca/d3a5aba6&camp=nyt2013_163x90_iOSPhone_hp_3HU9X&ad=app_IOS5_163x90_hp_3HU9X&goto=https%3A%2F%2Fitunes%2Eapple%2Ecom%2Fapp%2Fnytimes%2Fid284862083%3Fmt%3D8%26adxc%3D210162%26adxa%3D330437%26page%3Dhomepage.nytimes.com/index.html%26pos%3DMiddle5%26campaignId%3D3HU9X" target="_blank">
<img src="http://graphics8.nytimes.com/adx/images/ADS/33/04/ad.330437/12-2153_iOS_iphoneNewsAppAd_163x90.jpg" width="163" height="90" border="0">
</a></div>
</div>
</div>
</div>
</div>
	<div style="margin-top: 12px;"></div>	</div>
<div class="columnGroup last">				
<div id="classifiedsWidget">
<div id="tabsContainer">
<ul class="tabs">
<li class="selected" style="border-left:1px solid #CCCCCC"><a href="http://www.nytimes.com/pages/realestate/index.html">Real Estate</a></li>
<li class=""><a href="http://www.nytimes.com/autos/">Autos</a></li>
<li class=""><a href="http://jobmarket.nytimes.com/pages/jobs/">Jobs</a></li>
<li class=""><a href="http://www.nytimes.com/ref/classifieds/">All Classifieds</a></li>
</ul> 
</div>
<style type="text/css">
#realEstate.tabContent{display:block;}

    /* use one of these three
#autos.tabContent{display:block;}
#realEstate.tabContent{display:block;}
#jobMarket.tabContent{display:block;} 

  */
</style>
<div class="tabContent" id="realEstate">
<div class="editColumn">	<h6 class="kicker">Mortgages</h6>
<h5><a href="http://www.nytimes.com/2013/09/15/realestate/when-appraisals-come-in-low.html?hp">
When the Appraisal is Low
</a></h5>
<div class="runaroundRight">
<a href="http://www.nytimes.com/2013/09/15/realestate/when-appraisals-come-in-low.html?hp">
<img src="http://graphics8.nytimes.com/images/2013/09/15/realestate/15mortgage-graphic/15mortgage-graphic-thumbStandard.jpg" alt="When the Appraisal is Low" width="75" height="75" />
</a></div>
<p class="summary">
The subprime mortgage crisis resulted in a much more rigid appraisal process, leaving some prospective borrowers out in the cold.
</p>
<ul class="refer">
<li><a href="http://www.nytimes.com/top/classifieds/realestate/columns/mortgages/index.html?hp">More Mortgages Columns</a></li>
</ul>	</div>
<div class="searchColumn">
<h6 class="kicker">Find Properties</h6>
<ul class="refer">
<li><a href="http://www.nytimes.com/pages/realestate/index.html">Go to Real Estate Section</a></li>
<li><a href="http://realestate.nytimes.com/search/advanced.aspx">Search for Properties</a></li>
<li><a href="http://itunes.apple.com/us/app/nytimesrealestate/id337316535?hp">Download the Real Estate App</a></li>
<li><a href="http://www.nytimes.com/pages/realestate/commercial/index.html">Commercial Real Estate</a></li>
<li><a href="http://www.nytimes.com/marketing/realestate/videoshowcase/">Video Showcase: Real Estate</a></li>
<li><a href="http://realestateads.nytimes.com/">Post an Ad</a></li>
</ul>
</div>
<!-- ADXINFO classification="Home_Page_Markets_Module_Tile" campaign="HPMod_Houlihan_Sep2013_1860908-cla" priority="8000" isInlineSafe="N" width="163" height="90" --><!--Ad Template Begins Here -->
<div class="story advertisement">
<div class="callout"> 
<a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">
<img src="http://graphics8.nytimes.com/ads/cla/houlihan/9.13.13-hpmod/DeerKnoll.jpg" width="173" height="98" border="0" alt="Photo">
</a>
</div>

<h5><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">Deer Knoll<br>Bedford Crnrs,NY~Private waterfront residence</a></h5> 
<span class="summary"><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&snx=1379349327&sn1=6689612f/db87c161&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=3230714" target="_blank"></a></span>

<div class="adCreative">
<a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">
<img src="http://graphics8.nytimes.com/ads/cla/houlihan/hpmod/houlihan.gif" width="78" height="36" border="0"></a>
</div>
</div>
<!--Ad Template Ends Here -->
<div class="tabFoot story advertisement refer">
<a href="http://listings.nytimes.com/classifiedsmarketplace/?DTab=2&incamp=hpclassifiedsmodule">Place a Classified Ad »</a>
</div>
</div>
<div class="tabContent" id="autos">
<div class="editColumn">	<h6 class="kicker">FRANKFURT MOTOR SHOW</h6>
<h5><a href="http://www.nytimes.com/2013/09/15/automobiles/letter-from-germany-passengers-wanted.html?hp">
Letter From Germany: Passengers Wanted
</a></h5>
<div class="runaroundRight">
<a href="http://www.nytimes.com/2013/09/15/automobiles/letter-from-germany-passengers-wanted.html?hp">
<img src="http://graphics8.nytimes.com/images/2013/09/15/automobiles/Show1/Show1-thumbStandard.jpg" alt="Letter From Germany: Passengers Wanted" width="75" height="75" />
</a></div>
<p class="summary">
Dozens of automakers revealed new cars at the Frankfurt Motor Show, hoping to stir the European market from its doldrums.
</p>
<ul class="refer"><li>
<a href="http://www.nytimes.com/slideshow/2013/09/15/automobiles/15show-slides.html?hp"><span class="icon slideshow">Slide Show</span>: Frankfurt’s Debutantes</a></li>
</ul>	</div>
<div class="searchColumn"><style type="text/css">
      #searchUsedCompact select,
      #searchNewCompact select {
        width:106px;
        vertical-align:top;
        font-family: Arial, Helvetica, sans-serif;
        font-size:11px;
        color:#333;
      }

    #searchUsedCompact .gabrielsImageButton,
    #searchNewCompact .gabrielsImageButton {
    vertical-align:top;
    }
  
    #classifiedsWidget .autosStory,
    #classifiedsWidget .autosStory {
    vertical-align:top;
    border-bottom:1px solid #ccc;
    padding:0 0 7px;
    margin:0 0 7px !important;
    }
  
    #classifiedsWidget #zipCode {
    width:99px;
    height:15px;
    }

    #makesUsed {
    margin-bottom:5px;
    }
    </style><script type="text/javascript">
      AutosSearch = {};
      AutosSearch.setNameFromSelect = function(el,select) {
        document.getElementById(el).value = select.options[select.selectedIndex].text;
      }
    </script><div class="story autosStory"><h6 class="kicker">New Cars Search</h6><form method="post" action="http://autos.nytimes.com/researchSelect.aspx" id="searchNewCompact"><select id="makesNew" name="makes" onchange="AutosSearch.setNameFromSelect('makeNamesNew',this)"><option value="0">Select Make </option><option value="227">Acura</option><option value="231">Aston Martin</option><option value="232">Audi</option><option value="233">Bentley</option><option value="235">BMW</option><option value="236">Buick</option><option value="237">Cadillac</option><option value="238">Chevrolet</option><option value="239">Chrysler</option><option value="242">Dodge</option><option value="244">Ferrari</option><option value="245">Ford</option><option value="247">GMC</option><option value="248">Honda</option><option value="249">Hummer</option><option value="250">Hyundai</option><option value="251">Infiniti</option><option value="252">Isuzu</option><option value="253">Jaguar</option><option value="254">Jeep</option><option value="255">Kia</option><option value="256">Lamborghini</option><option value="257">Land Rover</option><option value="258">Lexus</option><option value="259">Lincoln</option><option value="261">Maserati</option><option value="262">Maybach</option><option value="263">Mazda</option><option value="264">Mercedes-Benz</option><option value="265">Mercury</option><option value="267">MINI</option><option value="268">Mitsubishi</option><option value="269">Nissan</option><option value="270">Oldsmobile</option><option value="272">Panoz</option><option value="275">Plymouth</option><option value="276">Pontiac</option><option value="277">Porsche</option><option value="280">Saab</option><option value="281">Saturn</option><option value="282">Scion</option><option value="284">Subaru</option><option value="285">Suzuki</option><option value="286">Toyota</option><option value="287">Volkswagen</option><option value="288">Volvo</option><option value="290">MG</option><option value="291">Rolls-Royce</option><option value="999">Other</option></select><input type="hidden" name="makeNames" id="makeNamesNew" value="" /> <input class="gabrielsImageButton" alt="Go" type="image" src="http://graphics8.nytimes.com/images/global/buttons/go.gif"></form></div><div class="story autosStory"><h6 class="kicker">Used Cars Search</h6><form method="post" action="http://autos.nytimes.com/search.aspx" id="searchUsedCompact"><select id="makesUsed" name="makeId" onchange="AutosSearch.setNameFromSelect('makeNamesUsed',this)"><option value="0">Select Make </option><option value="227">Acura</option><option value="231">Aston Martin</option><option value="232">Audi</option><option value="233">Bentley</option><option value="235">BMW</option><option value="236">Buick</option><option value="237">Cadillac</option><option value="238">Chevrolet</option><option value="239">Chrysler</option><option value="242">Dodge</option><option value="244">Ferrari</option><option value="245">Ford</option><option value="247">GMC</option><option value="248">Honda</option><option value="249">Hummer</option><option value="250">Hyundai</option><option value="251">Infiniti</option><option value="252">Isuzu</option><option value="253">Jaguar</option><option value="254">Jeep</option><option value="255">Kia</option><option value="256">Lamborghini</option><option value="257">Land Rover</option><option value="258">Lexus</option><option value="259">Lincoln</option><option value="261">Maserati</option><option value="262">Maybach</option><option value="263">Mazda</option><option value="264">Mercedes-Benz</option><option value="265">Mercury</option><option value="267">MINI</option><option value="268">Mitsubishi</option><option value="269">Nissan</option><option value="270">Oldsmobile</option><option value="272">Panoz</option><option value="275">Plymouth</option><option value="276">Pontiac</option><option value="277">Porsche</option><option value="280">Saab</option><option value="281">Saturn</option><option value="282">Scion</option><option value="284">Subaru</option><option value="285">Suzuki</option><option value="286">Toyota</option><option value="287">Volkswagen</option><option value="288">Volvo</option><option value="290">MG</option><option value="291">Rolls-Royce</option><option value="999">Other</option></select><br>
<input type="hidden" name="makeNames" id="makeNamesUsed" value="" />
<input type="text" name="zipCode" id="zipCode" value="Enter ZIP code"
  onfocus="if(this.value=='Enter ZIP code') { this.value=''; }"
  onblur="if(this.value==null || this.value=='') { this.value='Enter ZIP code'; }"> <input class="gabrielsImageButton" alt="Go" type="image" src="http://graphics8.nytimes.com/images/global/buttons/go.gif"></form></div><h6 class="kicker">More in Automobiles</h6><ul class="refer"><li><a href="http://www.nytimes.com/pages/automobiles/reviews/index.html">New Car Reviews</a></li><li><a href="http://autos.nytimes.com/used.aspx">Used Car Information</a></li><li><a href="http://www.nytimes.com/pages/automobiles/collectiblecars/index.html">Collectible Cars</a></li><li><a href="https://placead.nytimes.com/default.asp?CategoryID=NYTCAR">Sell Your Car</a></li></ul>
</div>
<!-- ADXINFO classification="Home_Page_Markets_Module_Tile" campaign="HPMod_Houlihan_Sep2013_1860908-cla" priority="8000" isInlineSafe="N" width="163" height="90" --><!--Ad Template Begins Here -->
<div class="story advertisement">
<div class="callout"> 
<a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">
<img src="http://graphics8.nytimes.com/ads/cla/houlihan/9.13.13-hpmod/DeerKnoll.jpg" width="173" height="98" border="0" alt="Photo">
</a>
</div>

<h5><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">Deer Knoll<br>Bedford Crnrs,NY~Private waterfront residence</a></h5> 
<span class="summary"><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&snx=1379349327&sn1=6689612f/db87c161&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=3230714" target="_blank"></a></span>

<div class="adCreative">
<a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">
<img src="http://graphics8.nytimes.com/ads/cla/houlihan/hpmod/houlihan.gif" width="78" height="36" border="0"></a>
</div>
</div>
<!--Ad Template Ends Here -->
<div class="tabFoot story advertisement refer"><a href="http://listings.nytimes.com/classifiedsmarketplace/?DTab=2&incamp=hpclassifiedsmodule">Place a Classified Ad »</a></div>
</div>
<div class="tabContent" id="jobMarket">
<h3 class="sectionHeader"><a href="http://www.nytimes.com/monster"><img src="http://graphics8.nytimes.com/images/section/jobs/200703/cobrandHeader_315x20.gif" width="315" height="20" alt="NYTimes.com / Monster" /></a></h3>
<div class="editColumn">	<h6 class="kicker">Corner Office</h6>
<h5><a href="http://www.nytimes.com/2013/09/15/business/bob-moritz-on-how-to-learn-about-diversity.html?hp">
How to Learn About Diversity
</a></h5>
<p class="summary">
Bob Moritz, the chairman of PricewaterhouseCoopers, says he gained new perspectives working for the firm in Japan.
</p>	</div>
<div class="searchColumn">
<p style="font:bold 1.1em Arial; margin:0 0 10px 0">Find the best job in the New York metro area and beyond.</p>
<form class="searchForm" action="http://nytimes.monster.com/Search.aspx" method="get" name="advJobsearchForm">
<input type="hidden" name="cy" value="us" />
<input id="searchQuery" name="q" value="" />    
<input id="searchSubmit" title="Search" alt="Search" type="image" src="http://graphics8.nytimes.com/images/global/global_search/search_button40x19.gif">  <a class="refer" href="http://jobmarket.nytimes.com/jobs/search-jobs/">Advanced Search »</a> 
</form>
</div>
<div class="toolsCol">
<h6 class="kicker">Tools</h6>
<ul class="refer">
<li><a href="http://www.nytimes.com/marketing/jobmarket/postresume.html">Post Your Resumé to NYTimes.com/monster</a></li>
<li><a href="http://jobmarket.nytimes.com/jobs/category/">Find a Job by Industry</a></li>
</ul>
</div>
<div class="employersCol">
<h6 class="kicker">Employers</h6>
<ul class="refer">
<li><a href="http://www.nytimes.com/marketing/jobmarket/employercentral/postjob.html">Post a Job Online and in Print</a></li>
<li><a href="http://hiring.nytimes.monster.com/products/resumeproducts.aspx">Search Résumés</a></li>
<li><a href="http://www.nytimes.com/marketing/jobmarket/employercentral/index.html">See All Recruitment Options</a></li>
</ul>
</div>
<!-- ADXINFO classification="Home_Page_Markets_Module_Tile" campaign="HPMod_Houlihan_Sep2013_1860908-cla" priority="8000" isInlineSafe="N" width="163" height="90" --><!--Ad Template Begins Here -->
<div class="story advertisement">
<div class="callout"> 
<a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">
<img src="http://graphics8.nytimes.com/ads/cla/houlihan/9.13.13-hpmod/DeerKnoll.jpg" width="173" height="98" border="0" alt="Photo">
</a>
</div>

<h5><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">Deer Knoll<br>Bedford Crnrs,NY~Private waterfront residence</a></h5> 
<span class="summary"><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&snx=1379349327&sn1=6689612f/db87c161&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=3230714" target="_blank"></a></span>

<div class="adCreative">
<a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPmodule-RE2&sn2=d1cdc681/5274a2cb&sn1=3e4ee83b/72bd6837&camp=HPMod_Houlihan_Sep2013_1860908-cla&ad=3230714&goto=http://www.houlihanlawrence.com/3230714" target="_blank">
<img src="http://graphics8.nytimes.com/ads/cla/houlihan/hpmod/houlihan.gif" width="78" height="36" border="0"></a>
</div>
</div>
<!--Ad Template Ends Here -->
<div class="tabFoot story advertisement refer"><a href="http://listings.nytimes.com/classifiedsmarketplace/?DTab=2&incamp=hpclassifiedsmodule">Place a Classified Ad »</a></div>
</div>
<style type="text/css" media="screen">
#classifiedsWidget .tabContent .subColumns{background:transparent;}
#classifiedsWidget .tabContent .subColumnA li,#classifiedsWidget .tabContent .subColumnB li{font-size:1.1em;}
</style>
<div class="tabContent" id="allClassifieds">
<h6 class="kicker">Find a Classifieds Listing</h6>
<div class="subColumns">
<div class="subColumnA">
<ul>
<li><a href="http://www.nytimes.com/autos/">Autos</a></li>
<li><a href="http://listings.nytimes.com/BusinessDirectory/searchindex.asp">Business Directory</a></li>
<li><a href="http://listings.nytimes.com/campsandschools/searchindex.asp">Camps & Schools</a></li>
<li><a href="http://www.nytimes.com/pages/realestate/commercial/">Commercial Real Estate</a></li>
<li><a href="http://listings.nytimes.com/HomeandGarden/searchindex.asp">Home & Garden Directory</a></li>
<li><a href="http://jobmarket.nytimes.com/pages/jobs/">Jobs</a></li>
</ul>
</div>
<div class="subColumnB">
<ul>
<!--<li><a href="http://query.nytimes.com/gst/personals.html">Personals</a></li>
-->
<li><a href="http://www.legacy.com/nytimes/celebrations.asp?Page=SearchResults">Social Announcements</a></li>
<li><a href="http://www.nytimes.com/pages/realestate/">Residental Real Estate</a></li>
<li><a href="http://listings.nytimes.com/SmallInnsAndLodges/searchindex.asp">Small Inns & Lodges</a></li>
<li><a href="http://listings.nytimes.com/Weddings/searchindex.asp">Weddings Directory</a></li>
</ul>
</div>
</div>
<ul class="refer">
<li><a href="http://listings.nytimes.com/ClassifiedsMarketplace/default.asp?DTab=2">Post a Classified Ad Online</a> | <a href="http://www.nytadvertising.com/was/ATWWeb/public/index.jsp">In Print</a></li>
</ul>
<div class="tabFoot story advertisement refer"><a href="http://listings.nytimes.com/classifiedsmarketplace/?DTab=2&incamp=hpclassifiedsmodule">Place a Classified Ad »</a></div>
</div></div>
<!--close allClassifieds -->
<script type="text/javascript">new Accordian("classifiedsWidget");</script>



<div class="singleAd" id="HPMiddle3">
<!-- ADXINFO classification="Featured_Product_Image" campaign="GoogleAdSense_SPONLINK_HP2" priority="1002" isInlineSafe="N" width="120" height="90" --><script language="JavaScript" type="text/javascript">
// rev6_GoogleHP.html.new
<!--
function cs(){window.status='';}function ha(a){  pha=document.getElementById(a); nhi=pha.href.indexOf("&nh=");if(nhi < 1) {phb=pha.href+"&nh=1";} pha.href=phb;}function ca(a) {  pha=document.getElementById(a); nci=pha.href.indexOf("&nc=");if(nci < 1) {phb=pha.href+"&nc=1";} pha.href=phb;window.open(document.getElementById(a).href);}function ga(o,e) {if (document.getElementById) {a=o.id.substring(1);p = "";r = "";g = e.target;if (g) {t = g.id;f = g.parentNode;if (f) {p = f.id;h = f.parentNode;if (h)r = h.id;}} else {h = e.srcElement;f = h.parentNode;if (f)p = f.id;t = h.id;}if (t==a || p==a || r==a)return true;pha=document.getElementById(a); nbi=pha.href.indexOf("&nb=");if(nbi < 1) {phb=pha.href+"&nb=1";} pha.href=phb;window.open(document.getElementById(a).href);}}



function google_ad_request_done(ads) {
	var s = "";

	if (ads.length == 0) {
		return;
	} else if (ads.length == 1 && ads[0].type != 'image') {
		google_ad_section_line_height = "22px";
		google_ad_section_padding_left = "12px";
		google_title_link_font_size = "18px";
		google_ad_text_font_size = "14px";
		google_visible_url_font_size = "14px";
		google_target_div = 'HPMiddle3';
	} else if (ads[0].type != 'image') {
		google_ad_section_line_height = "14px";
		google_ad_section_padding_left = "7px";
		google_title_link_font_size = "12px";
		google_ad_text_font_size = "11px";
		google_visible_url_font_size = "10px";
		google_target_div = 'HPMiddle3';
	}
	s += '<table width="100%" height="" border="0" cellspacing="0" cellpadding="0" style="width:100%; border-style: solid; border-width: 1px; border-color: #9da3ad" >\n<tr>\n<td style="font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" valign="top"><table width="100%" height="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%; height:100%;">\n<tr>\n <td style="background-color:#9da3ad; width:70%; height:20px; padding-top:2px; padding-left:11px; padding-bottom:2px; font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" width="70%" height="20" bgcolor="#9da3ad" ><span style="font-size: 12px; font-weight: normal; color:#ffffff;" >Ads by Google</span></td>\n<td style="padding-top:2px; padding-bottom:2px; width:30%; height:20px; align:right; background-color:#9da3ad; font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" width="30%" height="20" align="right" bgcolor="#9da3ad" ><span><a style="font-family:Arial,Helvetica,sans-serif; color: white; font-size:12px; padding-right:7px;" href="http://www.nytimes.com/ref/membercenter/faq/linkingqa16.html" onclick="window.open(\'\',\'popupad\',\'left=100,top=100,width=390,height=390,resizable,scrollbars=no\')" target="popupad">what\'s this?</a></span></td>\n</tr>\n</table>\n</td>\n</tr>\n<tr>\n<td style="height:110px; font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" valign="top" height="110"><table height="100%" width="100%" cellpadding="4" cellspacing="0" border="0" bgcolor="#f8f8f9" style="height:100%; width:100%; padding:4px; background-color:#f8f8f9;">\n';
	for (i = 0; i < ads.length; ++i) {
	   s += '<tr>\n<td style="font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333; background-color:#f8f8f9;" valign="middle" >\n<div style="line-height:' + google_ad_section_line_height + '; padding-left:' + google_ad_section_padding_left + '; padding-bottom:5px;" >\n<a href="' + ads[i].url + '" target="_blank" style="font-size:' + google_title_link_font_size + '; color:#000066; font-weight:bold; text-decoration:underline;"> ' + ads[i].line1 + '</a><br>\n' + ads[i].line2 + ' ' + ads[i].line3 + '<br>\n<a href="' + ads[i].url + '" target="_blank" style="font-size:' + google_visible_url_font_size + '; color:#000066; font-weight:normal; text-decoration:none;">' + ads[i].visible_url + '</a>\n</div>\n </td>\n</tr>\n';
	}
	s += '</table>\n</td>\n</tr>\n</table>';
	document.getElementById(google_target_div).innerHTML = s;
	return;
}
google_ad_output = 'js';
google_max_num_ads = '3';
google_ad_client = 'ca-nytimes_homepage_js';
google_safe = 'high';
google_ad_channel = 'test1';
google_targeting = 'content';
if (window.nyt_google_count) { google_skip = nyt_google_count; }
google_ad_section = 'default';
google_hints = 'business news online,us news online,online us news,top online news,business international news,online latest news';
// -->
</script>

<script type="text/javascript" language="JavaScript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js"></script>
</div>



<script type="text/javascript">
/* Generated at 2013-09-16T12:36:41-04:00 */
renditionMapping = {"images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-hpSmall.jpg":{"path":"images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-mediumFlexible177.jpg","w":"177","h":"118"},"images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-hpMedium.jpg":{"path":"images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-hpLarge.jpg":{"path":"images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/17/world/17diplo/17diplo-hpSmall.jpg":{"path":"images/2013/09/17/world/17diplo/17diplo-mediumFlexible177.jpg","w":"177","h":"118"},"images/2013/09/17/world/17diplo/17diplo-hpMedium.jpg":{"path":"images/2013/09/17/world/17diplo/17diplo-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/17/world/17diplo/17diplo-hpLarge.jpg":{"path":"images/2013/09/17/world/17diplo/17diplo-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/17/nyregion/17thompson-2/17thompson-2-hpSmall.jpg":{"path":"images/2013/09/17/nyregion/17thompson-2/17thompson-2-mediumFlexible177.jpg","w":"177","h":"100"},"images/2013/09/17/nyregion/17thompson-2/17thompson-2-hpMedium.jpg":{"path":"images/2013/09/17/nyregion/17thompson-2/17thompson-2-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/17/nyregion/17thompson-2/17thompson-2-hpLarge.jpg":{"path":"images/2013/09/17/nyregion/17thompson-2/17thompson-2-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/16/world/0916SAFRICAjp01/0916SAFRICAjp01-hpSmall.jpg":{"path":"images/2013/09/16/world/0916SAFRICAjp01/0916SAFRICAjp01-mediumFlexible177.jpg","w":"177","h":"183"},"images/2013/09/16/world/0916SAFRICAjp01/0916SAFRICAjp01-hpMedium.jpg":{"path":"images/2013/09/16/world/0916SAFRICAjp01/0916SAFRICAjp01-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/16/world/0916SAFRICAjp01/0916SAFRICAjp01-hpLarge.jpg":{"path":"images/2013/09/16/world/0916SAFRICAjp01/0916SAFRICAjp01-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/16/us/guns/guns-hpSmall.jpg":{"path":"images/2013/09/16/us/guns/guns-mediumFlexible177.jpg","w":"177","h":"118"},"images/2013/09/16/us/guns/guns-hpMedium-v2.jpg":{"path":"images/2013/09/16/us/guns/guns-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/16/us/guns/guns-hpLarge-v2.jpg":{"path":"images/2013/09/16/us/guns/guns-largeWidescreen573-v2.jpg","w":"573","h":"286"},"images/2013/09/17/world/europe/17costa3_cnd/17costa3_cnd-hpSmall.jpg":{"path":"images/2013/09/17/world/europe/17costa3_cnd/17costa3_cnd-mediumFlexible177.jpg","w":"177","h":"118"},"images/2013/09/17/world/europe/17costa3_cnd/17costa3_cnd-hpMedium.jpg":{"path":"images/2013/09/17/world/europe/17costa3_cnd/17costa3_cnd-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/17/world/europe/17costa3_cnd/17costa3_cnd-hpLarge.jpg":{"path":"images/2013/09/17/world/europe/17costa3_cnd/17costa3_cnd-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/16/us/amerasian/amerasian-hpSmall.jpg":{"path":"images/2013/09/16/us/amerasian/amerasian-mediumFlexible177.jpg","w":"177","h":"197"},"images/2013/09/16/us/amerasian/amerasian-hpMedium.jpg":{"path":"images/2013/09/16/us/amerasian/amerasian-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/16/us/amerasian/amerasian-hpLarge.jpg":{"path":"images/2013/09/16/us/amerasian/amerasian-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/16/nyregion/FIRE1/FIRE1-hpSmall.jpg":{"path":"images/2013/09/16/nyregion/FIRE1/FIRE1-mediumFlexible177.jpg","w":"177","h":"113"},"images/2013/09/16/nyregion/FIRE1/FIRE1-hpMedium-v2.jpg":{"path":"images/2013/09/16/nyregion/FIRE1/FIRE1-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/16/nyregion/FIRE1/FIRE1-hpLarge.jpg":{"path":"images/2013/09/16/nyregion/FIRE1/FIRE1-largeWidescreen573.jpg","w":"573","h":"286"},"images/2013/09/13/technology/bits-noun/bits-noun-hpSmall.jpg":{"path":"images/2013/09/13/technology/bits-noun/bits-noun-mediumFlexible177.jpg","w":"177","h":"118"},"images/2013/09/13/technology/bits-noun/bits-noun-hpMedium.jpg":{"path":"images/2013/09/13/technology/bits-noun/bits-noun-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/13/technology/bits-noun/bits-noun-hpLarge.jpg":{"path":"images/2013/09/13/technology/bits-noun/bits-noun-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-hpSmall.jpg":{"path":"images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-mediumFlexible177.jpg","w":"177","h":"118"},"images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-hpMedium.jpg":{"path":"images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-hpLarge.jpg":{"path":"images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/15/t-magazine/15moth-tmag-dornan/15well-dornan-hpSmall.jpg":{"path":"images/2013/09/15/t-magazine/15moth-tmag-dornan/15well-dornan-mediumFlexible177.jpg","w":"177","h":"236"},"images/2013/09/15/t-magazine/15moth-tmag-dornan/15well-dornan-hpMedium.jpg":{"path":"images/2013/09/15/t-magazine/15moth-tmag-dornan/15well-dornan-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/15/t-magazine/15moth-tmag-dornan/15well-dornan-hpLarge.jpg":{"path":"images/2013/09/15/t-magazine/15moth-tmag-dornan/15well-dornan-largeWidescreen573.jpg","w":"573","h":"287"},"images/2013/09/14/science/16MOTH_health/13wellfootball2-hpSmall.jpg":{"path":"images/2013/09/14/science/16MOTH_health/13wellfootball2-mediumFlexible177.jpg","w":"177","h":"118"},"images/2013/09/14/science/16MOTH_health/13wellfootball2-hpMedium.jpg":{"path":"images/2013/09/14/science/16MOTH_health/13wellfootball2-largeHorizontal375.jpg","w":"375","h":"250"},"images/2013/09/14/science/16MOTH_health/13wellfootball2-hpLarge.jpg":{"path":"images/2013/09/14/science/16MOTH_health/13wellfootball2-largeWidescreen573.jpg","w":"573","h":"287"}};
</script>	</div>


<div class="singleRuleDivider insetH"></div>
<!--Start CColumnAboveMoth region -->
<!--End CColumnAboveMoth region -->
<!--Start CColumnAboveMothBottom -->
<div class="columnGroup">
</div><!--end .columnGroup -->
<!--End CColumnAboveMothBottom -->


</div>
</div><!--close cColumn -->
</div><!--close spanAB -->
</div><!--close column -->
</div><!--close baseLayout -->
<!--start MOTH -->
<div id="insideNYTimes" class="doubleRule nocontent">
<div id="insideNYTimesHeader">
<div class="navigation"><span id="leftArrow"><img id="mothReverse" src="http://i1.nyt.com/images/global/buttons/moth_reverse.gif" /></span>&nbsp;<span id="rightArrow"><img id="mothForward" src="http://i1.nyt.com/images/global/buttons/moth_forward.gif" /></span></div>
<h4>
Inside NYTimes.com        </h4>
</div>
<div id="insideNYTimesScrollWrapper">
<table id="insideNYTimesBrowser" cellspacing="0">
<tbody>
<tr>
<td class="first">
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/t-magazine/index.html">T Magazine »</a>                            </h6>
<div class="mothImage">
<a href="http://tmagazine.blogs.nytimes.com/2013/09/12/jamie-dornans-killer-instincts/"><img src="http://i1.nyt.com/images/2013/09/15/t-magazine/15moth-tmag-dornan/15well-dornan-moth.jpg" alt="Jamie Dornan&rsquo;s Killer Instincts" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://tmagazine.blogs.nytimes.com/2013/09/12/jamie-dornans-killer-instincts/">Jamie Dornan&rsquo;s Killer Instincts</a></h6>
</div>
</td>
<td>
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/health/index.html">Health »</a>                            </h6>
<div class="mothImage">
<a href="http://well.blogs.nytimes.com/?p=95871"><img src="http://i1.nyt.com/images/2013/09/14/science/16MOTH_health/13wellfootball2-moth.jpg" alt="When Teams Lose, Fans Tackle Fatty Food" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://well.blogs.nytimes.com/?p=95871">When Teams Lose, Fans Tackle Fatty Food</a></h6>
</div>
</td>
<td>
<div class="story">
<h6 class="kicker"><a href="http://www.nytimes.com/pages/opinion/index.html">Opinion »</a></h6>
<h3><a href="http://opinionator.blogs.nytimes.com/2013/09/15/the-banality-of-systemic-evil/">The Stone: The Banality of Systemic Evil</a></h3>
<p class="summary">A poll showed that 70 percent of people 18 to 34 thought Edward Snowden “did a good thing.” Has the younger generation lost its moral compass?</p>
</div>
</td>
<td>
<div class="story">
<h6 class="kicker">
<a href="http://theater.nytimes.com/pages/theater/index.html">Theater &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://theater.nytimes.com/2013/09/16/theater/reviews/mr-burns-a-post-electric-play-at-playwrights-horizons.html"><img src="http://i1.nyt.com/images/2013/09/16/theater/16moth_burns/16moth_burns-moth.jpg" alt="Stand Up, Survivors; Homer Is With You" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://theater.nytimes.com/2013/09/16/theater/reviews/mr-burns-a-post-electric-play-at-playwrights-horizons.html">Stand Up, Survivors; Homer Is With You</a></h6>
</div>
</td>
<td>
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/opinion/index.html">Opinion &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://opinionator.blogs.nytimes.com/2013/09/14/lifelines-for-poor-children/"><img src="http://i1.nyt.com/images/2013/09/16/opinion/16moth_divide/16moth_divide-moth.jpg" alt="The Great Divide: Lifelines for Poor Children" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://opinionator.blogs.nytimes.com/2013/09/14/lifelines-for-poor-children/">The Great Divide: Lifelines for Poor Children</a></h6>
</div>
</td>
<td>
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/national/index.html">U.S. &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://www.nytimes.com/2013/09/16/us/pontiacs-rough-road-to-recovery-could-indicate-detroits-path.html"><img src="http://i1.nyt.com/images/2013/09/16/us/16moth_pontiac/16moth_pontiac-moth.jpg" alt="Pontiac&rsquo;s Rough Road May Foreshadow Detroit&rsquo;s" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://www.nytimes.com/2013/09/16/us/pontiacs-rough-road-to-recovery-could-indicate-detroits-path.html">Pontiac&rsquo;s Rough Road May Foreshadow Detroit&rsquo;s</a></h6>
</div>
</td>
<td class="hidden">
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/world/index.html">World &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://www.nytimes.com/2013/09/16/world/asia/rebel-rifts-on-island-confound-philippines.html"><span class="img" src="http://i1.nyt.com/images/2013/09/16/world/16moth_mindanao/16moth_mindanao-moth.jpg" alt="Rebel Rifts on Island Confound Philippines" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://www.nytimes.com/2013/09/16/world/asia/rebel-rifts-on-island-confound-philippines.html">Rebel Rifts on Island Confound Philippines</a></h6>
</div>
</td>
<td class="hidden">
<div class="story">
<h6 class="kicker"><a href="http://www.nytimes.com/pages/opinion/index.html">Opinion »</a></h6>
<h3><a href="http://www.nytimes.com/roomfordebate/2013/09/15/is-creativity-endangered/">Is Creativity Dying?</a></h3>
<p class="summary">Education, geography, management styles. Room for Debate asks: What suppresses innovation, and what nurtures it?</p>
</div>
</td>
<td class="hidden">
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/nyregion/index.html">N.Y. / Region &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://www.nytimes.com/2013/09/16/nyregion/a-much-loved-family-business-meets-disaster-again-on-the-shore.html"><span class="img" src="http://i1.nyt.com/images/2013/09/16/nyregion/16moth_fire/16moth_fire-moth.jpg" alt="A Family Business Meets Disaster Again" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://www.nytimes.com/2013/09/16/nyregion/a-much-loved-family-business-meets-disaster-again-on-the-shore.html">A Family Business Meets Disaster Again</a></h6>
</div>
</td>
<td class="hidden">
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/books/index.html">Books &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://www.nytimes.com/2013/09/16/books/doctor-sleep-is-stephen-kings-sequel-to-the-shining.html"><span class="img" src="http://i1.nyt.com/images/2013/09/16/books/16moth_bookking/16moth_bookking-moth.jpg" alt="Still Shining and Spooked, but Hopeful" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://www.nytimes.com/2013/09/16/books/doctor-sleep-is-stephen-kings-sequel-to-the-shining.html">Still Shining and Spooked, but Hopeful</a></h6>
</div>
</td>
<td class="hidden">
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/opinion/index.html">Opinion &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://www.nytimes.com/2013/09/16/opinion/how-to-fall-in-love-with-math.html"><span class="img" src="http://i1.nyt.com/images/2013/09/16/opinion/16moth_oped/16moth_oped-moth.jpg" alt="Op-Ed: How to Fall in Love With Math" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://www.nytimes.com/2013/09/16/opinion/how-to-fall-in-love-with-math.html">Op-Ed: How to Fall in Love With Math</a></h6>
</div>
</td>
<td class="hidden">
<div class="story">
<h6 class="kicker">
<a href="http://www.nytimes.com/pages/business/index.html">Business &raquo;</a>
</h6>
<div class="mothImage">
<a href="http://www.nytimes.com/2013/09/16/business/media/movie-industry-wants-to-get-a-handle-on-the-digital-box-office.html"><span class="img" src="http://i1.nyt.com/images/2013/09/16/business/16moth_tracking/16moth_tracking-moth.jpg" alt="Hollywood Wants Digital Box Office Numbers" width="151" height="151" /></a>
</div>
<h6 class="headline"><a href="http://www.nytimes.com/2013/09/16/business/media/movie-industry-wants-to-get-a-handle-on-the-digital-box-office.html">Hollywood Wants Digital Box Office Numbers</a></h6>
</div>
</td>
</tr>
</tbody>
</table>
</div>
</div><!--end #insideNYTimes -->
<!--end MOTH -->
<div class="baseLayoutBelowFold wrap spanABWell">
<div class="doubleRule">
<div class="column last">
<div class="spanABBelowFold wrap">
<div class="abColumn">
<div id="wellRegion"><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/world/index.html">World  &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><h6><a  href="http://www.nytimes.com/2013/09/17/world/europe/syria-united-nations.html?hpw">U.N. Report Confirms Rockets Loaded With Sarin in Aug. 21 Attack</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/17/world/europe/us-and-allies-tell-syria-to-dismantle-chemical-arms-quickly.html?hpw">U.S. and Allies Push for Strong U.N. Measure on Syria&rsquo;s Arms</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/world/middleeast/deal-represents-turn-for-syria-rebels-deflated.html?hpw">Deal Represents Turn for Syria; Rebels Deflated</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/business/index.html">Business Day &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://economix.blogs.nytimes.com/2013/09/15/whats-needed-in-the-next-fed-chief/?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/15/business/economy/15economix-fed/15economix-fed-thumbStandard.jpg" /></a><h6><a href="http://economix.blogs.nytimes.com/2013/09/15/whats-needed-in-the-next-fed-chief/?hpw">Economix Blog: What&rsquo;s Needed in the Next Fed Chief</a></h6></li><li class=""><h6><a  href="http://dealbook.nytimes.com/2013/09/15/looking-to-twitter-to-reignite-tech-i-p-o-s/?hpw">DealBook: Looking to Twitter to Reignite Tech I.P.O.&rsquo;s</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/17/us/politics/obama-to-release-report-on-response-to-financial-crisis.html?hpw">Obama Warns Congress Not to Imperil to Recovery</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/opinion/index.html">Opinion &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/16/opinion/how-to-fall-in-love-with-math.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/opinion/0916OPEDmaida/0916OPEDmaida-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/16/opinion/how-to-fall-in-love-with-math.html?hpw">Op-Ed Contributor: How to Fall in Love With Math</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/16/opinion/the-syrian-pact.html?hpw">Editorial: The Syrian Pact</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/opinion/keller-the-missing-partner.html?hpw">Op-Ed Columnist: The Missing Partner</a></h6></li></ul></div></div><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/national/index.html">U.S. &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/17/us/shooting-reported-at-washington-navy-yard.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/us/20130917_dcshoot_hp-slide-5UD3/20130917_dcshoot_hp-slide-5UD3-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/17/us/shooting-reported-at-washington-navy-yard.html?hpw">Gunman Said to Be Killed in Deadly Attack at Navy Yard</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/17/us/more-rain-expected-as-colorado-rescuers-wait-for-fog-to-lift.html?hpw">More Rain Expected as Colorado Rescuers Wait for Fog to Lift</a></h6></li><li class="lastItem"><h6><a  href="http://thelede.blogs.nytimes.com/2013/09/15/helicopters-rescue-schoolchildren-in-colorado-floods/?hpw">The Lede: Video of Helicopter Rescue Crews Airlifting 85 Schoolchildren to Safety</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/technology/index.html">Technology &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/16/technology/for-retailers-new-gmail-has-one-tab-too-many.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/business/GOOGLE/GOOGLE-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/16/technology/for-retailers-new-gmail-has-one-tab-too-many.html?hpw">Retailers Fight Exile From Gmail In-Boxes</a></h6></li><li class=""><h6><a  href="http://dealbook.nytimes.com/2013/09/15/looking-to-twitter-to-reignite-tech-i-p-o-s/?hpw">DealBook: Looking to Twitter to Reignite Tech I.P.O.&rsquo;s</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/14/technology/the-payday-at-twitter-many-were-waiting-for.html?hpw">The Payday at Twitter Many Were Waiting For</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/arts/index.html">Arts &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/17/arts/video-games/grand-theft-auto-v-is-a-return-to-the-comedy-of-violence.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/17/arts/17gta-3/17gta-3-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/17/arts/video-games/grand-theft-auto-v-is-a-return-to-the-comedy-of-violence.html?hpw">Video Game Review | Grand Theft Auto V: Shooting Holes in Victims and 21st-Century Culture</a></h6></li><li class=""><h6><a  href="http://theater.nytimes.com/2013/09/16/theater/reviews/mr-burns-a-post-electric-play-at-playwrights-horizons.html?hpw">Theater Review | &#039;Mr. Burns, a Post-Electric Play,&#039;: Stand Up, Survivors; Homer Is With You</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/business/media/saturday-night-live-setting-its-new-cast.html?hpw">New Course for &lsquo;Weekend Update,&rsquo; and All of &lsquo;SNL&rsquo;</a></h6></li></ul></div></div><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/politics/index.html">Politics  &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/16/business/economy/summers-pulls-name-from-consideration-for-fed-chief.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/us/16summers1/16summers1-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/16/business/economy/summers-pulls-name-from-consideration-for-fed-chief.html?hpw">Summers Pulls Name From Consideration for Fed Chief</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/17/world/europe/us-and-allies-tell-syria-to-dismantle-chemical-arms-quickly.html?hpw">U.S. and Allies Push for Strong U.N. Measure on Syria&rsquo;s Arms</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/world/middleeast/brief-respite-for-president-but-no-plan-b-on-syria.html?hpw">Brief Respite for President, but No Plan B on Syria</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/sports/index.html">Sports &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/16/sports/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/13/sports/Oldest-Weightlifter-slide-PZQ4/Oldest-Weightlifter-slide-PZQ4-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/16/sports/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html?hpw">Labeled a Cheat, but He Has a Story</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/17/sports/basketball/anthony-vows-loyalty-to-knicks-but-its-early.html?hpw">On Pro Basketball: Anthony Vows Loyalty to Knicks, but It&rsquo;s Early</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/sports/football/a-little-brother-learns-a-lesson-as-the-giants-tumble-to-0-2.html?hpw">Broncos 41, Giants 23: A Little Brother Learns a Lesson as the Giants Sputter to 0-2</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/movies/index.html">Movies &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/15/movies/canadian-films-reaping-festival-awards-and-oscar-nods.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/15/arts/15SUBPRISONERS1_SPAN/15SUBPRISONERS1-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/15/movies/canadian-films-reaping-festival-awards-and-oscar-nods.html?hpw">National Pride on the Screen</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/15/movies/after-african-detour-isaiah-washington-is-back-on-screen.html?hpw">A Comeback on His Own Terms</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/movies/wadjda-by-haifaa-al-mansour-made-in-saudi-arabia.html?hpw">Where a Bicycle Is Sweetly Subversive</a></h6></li></ul></div></div><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/nyregion/index.html">N.Y. / Region  &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/17/nyregion/thompson-to-concede-to-de-blasio-in-mayoral-primary.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/17/nyregion/17thompson-2/17thompson-2-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/17/nyregion/thompson-to-concede-to-de-blasio-in-mayoral-primary.html?hpw">Thompson Concedes to de Blasio in Mayoral Primary</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/16/nyregion/an-anonymous-whistle-blower-exposed-a-scandal-at-a-jewish-charity.html?hpw">Whistle-Blower&rsquo;s Letter Led to Charity&rsquo;s Firing of Chief Executive</a></h6></li><li class="lastItem"><h6><a  href="http://cityroom.blogs.nytimes.com/2013/09/16/new-york-today-damn-yankees/?hpw">New York Today: Damn Yankees</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/obituaries/index.html">Obituaries &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/17/world/europe/shalom-yoran-jewish-resistance-fighter-dies-at-88.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/world/yoran-obit-1/yoran-obit-1-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/17/world/europe/shalom-yoran-jewish-resistance-fighter-dies-at-88.html?hpw">Shalom Yoran, Jewish Resistance Fighter, Dies at 88</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/16/nyregion/marshall-berman-professor-dies-at-72.html?hpw">Marshall Berman, Philosopher Who Praised Marx and Modernism, Dies at 72</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/sports/dick-newick-sailboat-design-visionary-dies-at-87.html?hpw">Dick Newick, Sailboat Design Visionary, Dies at  87</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://theater.nytimes.com/">Theater &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://theater.nytimes.com/2013/09/16/theater/reviews/mr-burns-a-post-electric-play-at-playwrights-horizons.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/arts/burns/burns-thumbStandard.jpg" /></a><h6><a href="http://theater.nytimes.com/2013/09/16/theater/reviews/mr-burns-a-post-electric-play-at-playwrights-horizons.html?hpw">Theater Review | &#039;Mr. Burns, a Post-Electric Play,&#039;: Stand Up, Survivors; Homer Is With You</a></h6></li><li class=""><h6><a  href="http://artsbeat.blogs.nytimes.com/2013/09/15/a-new-spider-man-on-broadway/?hpw">ArtsBeat: A New Spider-Man on Broadway</a></h6></li><li class="lastItem"><h6><a  href="http://artsbeat.blogs.nytimes.com/2013/09/15/murder-for-two-finds-a-new-home/?hpw">ArtsBeat: &lsquo;Murder for Two&rsquo; Finds a New Home</a></h6></li></ul></div></div><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/science/index.html">Science  &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><h6><a  href="http://www.nytimes.com/2013/09/16/business/energy-environment/a-federal-energy-nomination-sets-off-an-unusual-public-battle.html?hpw">An Unusual Public Battle Over an Energy Nomination</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/15/business/wall-st-exploits-ethanol-credits-and-prices-spike.html?hpw">The House Edge: Wall St. Exploits Ethanol Credits, and Prices Spike</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/world/europe/russia-preparing-patrols-of-arctic-shipping-lanes.html?hpw">Russia Preparing Patrols of Arctic Shipping Lanes</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://travel.nytimes.com/">Travel &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://travel.nytimes.com/2013/09/15/travel/iquitos-peru-wet-and-wild.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/15/travel/15-iquitos-span/15-iquitos-span-thumbStandard.jpg" /></a><h6><a href="http://travel.nytimes.com/2013/09/15/travel/iquitos-peru-wet-and-wild.html?hpw">Iquitos, Peru: Wet and Wild</a></h6></li><li class=""><h6><a  href="http://travel.nytimes.com/2013/09/15/travel/out-of-the-past-in-lively-old-rio.html?hpw">Cultured Traveler: Out of the Past in Lively Old Rio</a></h6></li><li class="lastItem"><h6><a  href="http://travel.nytimes.com/2013/09/15/travel/36-hours-in-buenos-aires.html?hpw">36 Hours in Buenos Aires</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/arts/television/index.html">Television &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/16/business/media/saturday-night-live-setting-its-new-cast.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/arts/SNL/SNL-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/16/business/media/saturday-night-live-setting-its-new-cast.html?hpw">New Course for &lsquo;Weekend Update,&rsquo; and All of &lsquo;SNL&rsquo;</a></h6></li><li class=""><h6><a  href="http://tv.nytimes.com/2013/09/16/arts/television/in-sleepy-hollow-crane-and-his-nemesis-land-in-the-21st-century.html?hpw">Television Review: An Ichabod Crane With Backbone (but Can He Use an iPad?)</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/business/media/movie-industry-wants-to-get-a-handle-on-the-digital-box-office.html?hpw">Hollywood Wants Numbers on the Digital Box Office</a></h6></li></ul></div></div><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/health/index.html">Health &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://well.blogs.nytimes.com/2013/09/16/teenagers-are-getting-more-exercise-and-vegetables/?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/10/health/well_teens/well_teens-thumbStandard.jpg" /></a><h6><a href="http://well.blogs.nytimes.com/2013/09/16/teenagers-are-getting-more-exercise-and-vegetables/?hpw">Well: Teenagers Are Getting More Exercise and Vegetables</a></h6></li><li class=""><h6><a  href="http://well.blogs.nytimes.com/2013/09/16/when-parents-need-nurturing/?hpw">Personal Health: When Parents Need Nurturing</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/sports/football/a-fierce-defender-focusing-on-football-safety.html?hpw">30 Seconds: A Fierce Defender Focusing on Football Safety</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/dining/index.html">Dining & Wine &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/18/dining/romesco-sauce-with-a-flexible-nature.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/13/dining/video-clark-broccolisalad/video-clark-broccolisalad-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/18/dining/romesco-sauce-with-a-flexible-nature.html?hpw">A Good Appetite: Romesco Sauce With a Flexible Nature</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/18/dining/a-sicilian-summer-on-the-mainland.html?hpw">City Kitchen: A Sicilian Summer on the Mainland</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/12/dining/join-our-video-chat-with-fuchsia-dunlop.html?hpw">Recipe Lab: Join Our Video Chat With Fuchsia Dunlop</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/books/index.html">Books &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/16/books/doctor-sleep-is-stephen-kings-sequel-to-the-shining.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/16/arts/book-1379268216446/book-1379268216446-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/16/books/doctor-sleep-is-stephen-kings-sequel-to-the-shining.html?hpw">Books of The Times: Still Shining and Spooked, but Hopeful</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/16/books/10-book-deal-for-terry-pratchett.html?hpw">10-Book Deal for Terry Pratchett</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/opinion/sunday/was-salinger-too-pure-for-this-world.html?hpw">Opinion: Was Salinger Too Pure for This World?</a></h6></li></ul></div></div><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/education/index.html">Education &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/15/magazine/can-emotional-intelligence-be-taught.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/15/magazine/15learning-ss-slide-DRJ0/15learning-ss-slide-DRJ0-thumbStandard-v2.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/15/magazine/can-emotional-intelligence-be-taught.html?hpw">Can Emotional Intelligence Be Taught?</a></h6></li><li class=""><h6><a  href="http://bits.blogs.nytimes.com/2013/09/15/minecraft-an-obsession-and-an-educational-tool/?hpw">Disruptions: Minecraft, a Child&rsquo;s Obsession, Finds Use as an Educational Tool</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/16/world/africa/somalia-gets-aid-to-educate-children.html?hpw">Somalia Gets Aid  to Educate Children</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/garden/index.html">Home & Garden &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/12/garden/check-in-act-out.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/12/garden/12DETAILS1_SPAN/12DETAILS1-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/12/garden/check-in-act-out.html?hpw">The Details: Check In, Act Out</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/12/garden/a-passion-and-then-a-solace.html?hpw">In the Garden: A Passion and Then a Solace</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/12/garden/life-without-walls.html?hpw">On Location | Berlin: Life Without Walls</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/opinion/index.html#sundayreview">Sunday Review &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/15/opinion/sunday/friedman-when-complexity-is-free.html?hpw"><img src="http://graphics8.nytimes.com/images/2010/09/16/opinion/Friedman_New/Friedman_New-thumbStandard.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/15/opinion/sunday/friedman-when-complexity-is-free.html?hpw">Op-Ed Columnist: When Complexity Is Free</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/15/sunday-review/is-suburban-sprawl-on-its-way-back.html?hpw">News Analysis: Is Suburban Sprawl on Its Way Back?</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/opinion/sunday/tips-and-poverty.html?hpw">Editorial: Tips and Poverty</a></h6></li></ul></div></div><div class="module wrap"><div class="column firstColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/realestate/index.html">Real Estate &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/15/realestate/living-apart-together.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/15/realestate/15COVER_SPAN/15COVER_SPAN-thumbStandard-v2.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/15/realestate/living-apart-together.html?hpw">Living Apart Together</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/15/realestate/feinsteins-home-isnt-it-romantic.html?hpw">Exclusive | 143 East 63rd Street: Feinstein&rsquo;s Home: Isn&rsquo;t It Romantic?</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/realestate/a-scenic-designers-west-village-home.html?hpw">What I Love | Derek McLane: A Scenic Designer&rsquo;s West Village Home</a></h6></li></ul></div><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/fashion/index.html">Fashion & Style &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://runway.blogs.nytimes.com/2013/09/16/jonathan-saunders-turning-the-fashion-page/?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/17/fashion/0916SAUNDERSSPAN/0916SAUNDERSSPAN-thumbStandard.jpg" /></a><h6><a href="http://runway.blogs.nytimes.com/2013/09/16/jonathan-saunders-turning-the-fashion-page/?hpw">On the Runway Blog: Jonathan Saunders: Turning the Fashion Page</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/15/fashion/an-intervention-for-malibu.html?hpw">An Intervention for Malibu</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/fashion/fashions-latest-muse-instagram.html?hpw">Fashion&rsquo;s Latest Muse? Instagram</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/magazine/index.html">Magazine &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><h6><a  href="http://www.nytimes.com/2013/09/15/magazine/can-emotional-intelligence-be-taught.html?hpw">Can Emotional Intelligence Be Taught?</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/15/magazine/no-child-left-untableted.html?hpw">No Child Left Untableted</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/magazine/rescuing-tartare-from-the-stuffy-old-power-lunchers.html?hpw">Eat: Rescuing Tartare From the Stuffy, Old Power-Lunchers</a></h6></li></ul></div></div><div class="module wrap"><div class="column"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/automobiles/index.html">Automobiles &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><a class="thumb runaroundRight" href="http://www.nytimes.com/2013/09/15/automobiles/collectibles/in-nebraska-a-field-of-low-mileage-dreams.html?hpw"><img src="http://graphics8.nytimes.com/images/2013/09/15/automobiles/collectibles/15nebraska-slides-slide-2CL0/15nebraska-slides-slide-2CL0-thumbStandard-v2.jpg" /></a><h6><a href="http://www.nytimes.com/2013/09/15/automobiles/collectibles/in-nebraska-a-field-of-low-mileage-dreams.html?hpw">In Nebraska, a Field of Low-Mileage Dreams</a></h6></li><li class=""><h6><a  href="http://www.nytimes.com/2013/09/15/automobiles/the-surround-sound-is-321080-supercar-included.html?hpw">Around the Block: The Surround Sound Is $321,080, Supercar Included</a></h6></li><li class="lastItem"><h6><a  href="http://www.nytimes.com/2013/09/15/automobiles/letter-from-germany-passengers-wanted.html?hpw">Frankfurt Motor Show: Letter From Germany: Passengers Wanted</a></h6></li></ul></div><div class="column lastColumn"><h6 class="moduleHeaderLg"><a href="http://www.nytimes.com/pages/t-magazine/index.html">T Magazine  &raquo;</a></h6><ul class="headlinesOnly"><li class="firstItem wrap"><h6><a  href="http://tmagazine.blogs.nytimes.com/2013/09/16/live-stream-burberrys-spring-2014-collection-at-london-fashion-week/?hpw">Live Stream | Burberry&rsquo;s Spring 2014 Collection at London Fashion Week</a></h6></li><li class=""><h6><a  href="http://tmagazine.blogs.nytimes.com/2013/09/16/the-scene-london-fashion-week-jonathan-saunders/?hpw">The Scene | London Fashion Week: Jonathan Saunders</a></h6></li><li class="lastItem"><h6><a  href="http://tmagazine.blogs.nytimes.com/2013/09/16/the-scene-london-fashion-week-mary-katrantzou/?hpw">The Scene | London Fashion Week: Mary Katrantzou</a></h6></li></ul></div></div></div>
&nbsp;
</div><!--close abColumn -->
<div class="cColumn">

<div class="columnGroup first">

    <a name="timeswire"></a>
    <div class="timeswireModule">
        <h4 class="sectionHeaderHome"><a href="http://www.nytimes.com/timeswire/?src=twrhp">Times Wire &raquo;</a></h4>
        <p class="refer">Most recent updates on NYTimes.com. <a href="http://www.nytimes.com/timeswire/?src=twr" title="Go to Times Wire">See More &raquo;</a></p>
        <ol id="wireContent" class="singleRule">
            <li class='wrap'><span class='timestamp' title='2013-09-16 12:25:03' data-gmt='1379348703'>12:25 AM ET</span> <a href='http://dealbook.nytimes.com/2013/09/16/questions-swirl-after-summers-drops-out-of-consideration-for-fed/?src=twrhp'>Questions Swirl After Summers Drops Out of Consideration for Fed</a></li>
            <li class='wrap'><span class='timestamp' title='2013-09-16 12:24:37' data-gmt='1379348677'>12:24 AM ET</span> <a href='http://www.nytimes.com/2013/09/17/world/europe/survey-hints-europeans-are-turning-inward.html?src=twrhp'>Survey Hints Europeans Are Turning Inward</a></li>
            <li class='wrap last'><span class='timestamp' title='2013-09-16 12:20:48' data-gmt='1379348448'>12:20 AM ET</span> <a href='http://www.nytimes.com/2013/09/17/sports/basketball/anthony-vows-loyalty-to-knicks-but-its-early.html?src=twrhp'>Anthony Vows Loyalty to Knicks, but It’s Early</a></li>
        </ol>
    </div>
    <div class="singleRuleDivider"></div>
    </div>
<div class="columnGroup ">
<div id="mostPopWidget" class="doubleRule"></div>
<script src="http://js.nyt.com/js/app/recommendations/recommendationsModule.js" type="text/javascript" charset="utf-8"></script>
</div>
<div class="columnGroup ">

<div class="singleAd" id="Box1">
<!-- ADXINFO classification="Marketing_Module" campaign="nyt2013_300X250_nytstore_photography_fsi" priority="1000" isInlineSafe="N" width="336" height="280" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Box1&sn2=5b35dc29/56a295e7&sn1=2957cd26/1c286263&camp=nyt2013_300X250_nytstore_photography_fsi&ad=300X250_nytstore_photography_fsi&goto=http%3A%2F%2Fwww%2Enytstore%2Ecom%2F" target="_blank">
<img src="http://graphics8.nytimes.com/adx/images/ADS/34/77/ad.347792/13-1633-Store-Banner_300x250_SS.jpg" width="300" height="250" border="0">
</a>
</div>

</div>
<div class="singleRuleDivider insetH"></div>
<div class="columnGroup">
<div id="blogModule" class="tabbedBlogModule">
<h4>Recent Blog Posts</h4>
<div class="tabsContainer"><ul class="tabs">
<li class="first selected" title="News"><a href="http://www.nytimes.com/">News</a></li>
<li title="Opinion"><a href="http://www.nytimes.com/pages/opinion/index.html">Opinion</a></li>
</ul></div>
<div class="tabContent active">
<ul>
<li>
<span class="kicker">DealBook: </span><a href="http://dealbook.nytimes.com/2013/09/16/questions-swirl-after-summers-drops-out-of-consideration-for-fed/">Questions Swirl After Summers Drops Out of Consideration for Fed</a><p class="date">September 16, 2013, 12:15 PM</p>
</li>
<li>
<span class="kicker">ArtsBeat: </span><a href="http://artsbeat.blogs.nytimes.com/2013/09/16/a-young-fan-dies-of-an-apparent-overdose-at-music-festival-in-australia/">A Young Fan Dies of an Apparent Overdose at Music Festival in Australia</a><p class="date">September 16, 2013, 12:03 PM</p>
</li>
<li>
<span class="kicker">Wordplay: </span><a href="http://wordplay.blogs.nytimes.com/2013/09/16/lights-2/">Robert Torrence&rsquo;s Lights Out</a><p class="date">September 16, 2013, 12:00 PM</p>
</li>
<li>
<span class="kicker">Bits: </span><a href="http://bits.blogs.nytimes.com/2013/09/16/rethinking-the-iphone-5c/">The iPhone 5C and the Allure of Shownership</a><p class="date">September 16, 2013, 11:17 AM</p>
</li>
<li>
<span class="kicker">The Lede: </span><a href="http://thelede.blogs.nytimes.com/2013/09/16/a-bahraini-activists-message-from-prison/">A Bahraini Activist&rsquo;s Message From Prison</a><p class="date">September 16, 2013, 11:12 AM</p>
</li>
<li>
<span class="kicker">You&#039;re the Boss: </span><a href="http://boss.blogs.nytimes.com/2013/09/16/today-in-small-business-scams-and-cyber-attacks/">Today in Small Business: Frauds and Cyberattacks</a><p class="date">September 16, 2013, 11:00 AM</p>
</li>
</ul>
<p class="refer"><a href="http://www.nytimes.com/ref/topnews/blog-index.html">More New York Times Blogs &#187;</a></p>
</div>
<div class="tabContent">
<ul>
<li>
<span class="kicker">Joe Nocera: </span><a href="http://nocera.blogs.nytimes.com/2013/09/16/weekend-gun-report-september-13-15-2013/">Weekend Gun Report: September 13-15, 2013</a><p class="date">September 16, 2013, 12:08 PM</p>
</li>
<li>
<span class="kicker">Dot Earth: </span><a href="http://dotearth.blogs.nytimes.com/2013/09/16/an-ecologist-explains-contested-view-of-planetary-limits/">An Ecologist Explains His Contested View of Planetary Limits</a><p class="date">September 16, 2013, 10:02 AM</p>
</li>
<li>
<span class="kicker">The Public Editor&#039;s Journal: </span><a href="http://publiceditor.blogs.nytimes.com/2013/09/16/the-public-editors-sunday-column-the-delicate-handling-of-images-of-war/">The Public Editor&#8217;s Sunday Column: The Delicate Handling of Images of War</a><p class="date">September 16, 2013,  9:16 AM</p>
</li>
<li>
<span class="kicker">Paul Krugman: </span><a href="http://krugman.blogs.nytimes.com/2013/09/16/the-political-economy-of-bloombergism/">The Political Economy of Bloombergism</a><p class="date">September 16, 2013,  9:11 AM</p>
</li>
<li>
<span class="kicker">Latitude: </span><a href="http://latitude.blogs.nytimes.com/2013/09/16/what-putin-doesnt-have-to-say-about-syria/">What Putin Doesn&#8217;t Have to Say About Syria</a><p class="date">September 16, 2013,  7:49 AM</p>
</li>
<li>
<span class="kicker">Opinionator: </span><a href="http://opinionator.blogs.nytimes.com/2013/09/15/the-banality-of-systemic-evil/">The Banality of Systemic Evil</a><p class="date">September 15, 2013,  5:00 PM</p>
</li>
</ul>
<p class="refer"><a href="http://www.nytimes.com/ref/topnews/blog-index.html">More New York Times Blogs &#187;</a></p>
</div>
</div><script type="text/javascript" language="JavaScript" src="http://graphics8.nytimes.com/js/app/lib/NYTD/0.0.1/tabset.js"></script><script type="text/javascript" language="JavaScript">
        
        (function(){
            var tabbedModule = NYTD.TabSet("blogModule");
            var date         = new Date();

            if(date.getMinutes() > 30) {
                $$("#blogModule ul.tabs li.selected").invoke("removeClassName", "selected");
                $$("#blogModule div.active").invoke("removeClassName", "active");
                tabbedModule.activateTab(tabbedModule.getTabs()[1], tabbedModule.getTabContent()[1]);
            }
        })()
        
    </script>
    </div>
<div class="columnGroup ">

<div class="singleAd" id="HPBottom1">
<!-- ADXINFO classification="Text_Link" campaign="nyt2013_footer_digi_hp_ros_39Y4U" priority="1000" isInlineSafe="N" width="0" height="0" --><table width="100%" border="0">
<tr>
<td width="300"><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=HPBottom1&sn2=ba5a7590/f9c69a68&sn1=be704ee7/3e3a50a0&camp=nyt2013_footer_digi_hp_ros_39Y4U&ad=digi-testC2_original-try_unlimited_footer-39Y4U&goto=http%3A%2F%2Fwww%2Enytimes%2Ecom%2Fsubscriptions%2FMultiproduct%2Flp39YYF%2Ehtml%3Fadxc%3D209250%26adxa%3D306644%26page%3Dhomepage.nytimes.com/index.html%26pos%3DHPBottom1%26campaignId%3D39Y4U"><img src="http://graphics8.nytimes.com/adx/images/ADS/30/66/ad.306644/12-0999-Footer_Icon.jpg" height="27" width="40" style="float: left; margin-right: 5px;" alt="Get Home Delivery" align="middle" border="0"/>Try unlimited access to NYTimes.com for just 99&cent;.&nbsp; SEE OPTIONS &raquo;</a>

</td>
</tr>
</table>
</div>

</div>
<div class="columnGroup ">

<div class="columnGroup fullWidth">
<div class="singleRuleDivider insetH"></div>
<div class="subColumn-2 wrap">
<div class="column">
<div class="columnGroup centeredAd">

<div id="Right1"><!-- ADXINFO classification="Home_Product_Marketplace_Button" campaign="nyt2013_120x90_times4_hp_3JF3W" priority="1000" isInlineSafe="N" width="160" height="60" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Right1&sn2=b20a74cb/423db008&sn1=ae3f6289/b80ebe5&camp=nyt2013_120x90_times4_hp_3JF3W&ad=120x90_times4_hp_3JF3W&goto=https%3A%2F%2Fwww%2Enytimesathome%2Ecom%2Fhd%2F205%3FMediaCode%3DWB7AA%26CMP%3D3JF3W%26adxc%3D211378%26adxa%3D331626%26page%3Dhomepage.nytimes.com/index.html%26pos%3DRight1%26campaignId%3D3JF3W" target="_blank">
<img src="http://graphics8.nytimes.com/adx/images/ADS/33/16/ad.331626/12-2415_ext_Banners_120x90_adv6.jpg" width="120" height="90" border="0">
</a></div>

</div>
</div>
<div class="column last">
<div class="columnGroup centeredAd">

<div id="Box2"><!-- ADXINFO classification="Home_Product_Marketplace_Button" campaign="nyt2013_120x90_tapclickswipe_hp_3JF3U" priority="1000" isInlineSafe="N" width="160" height="60" --><a href="http://www.nytimes.com/adx/bin/adx_click.html?type=goto&opzn&page=homepage.nytimes.com/index.html&pos=Box2&sn2=5b35dc2a/56c295e7&sn1=263378c7/abed5ee1&camp=nyt2013_120x90_tapclickswipe_hp_3JF3U&ad=120x90_tapclickswipe_hp_3JF3U&goto=https%3A%2F%2Fwww%2Enytimesathome%2Ecom%2Fhd%2F205%3FMediaCode%3DWB7AA%26CMP%3D3JF3U%26adxc%3D211376%26adxa%3D331622%26page%3Dhomepage.nytimes.com/index.html%26pos%3DBox2%26campaignId%3D3JF3U" target="_blank">
<img src="http://graphics8.nytimes.com/adx/images/ADS/33/16/ad.331622/12-2415_HD_Banner_120x90.jpg" width="120" height="90" border="0">
</a></div>

</div>
</div>
</div><!--end .subColumn-2 wrap -->
</div><!--end .columnGroup fullWidth -->

</div>
<div class="columnGroup last">

<div class="singleAd" id="SponLinkHP">
<!-- ADXINFO classification="Featured_Product_Image" campaign="GoogleAdSense_SPONLINK_HP_extension" priority="9100" isInlineSafe="N" width="120" height="90" --><script language="JavaScript" type="text/javascript">
// rev6_GoogleHP.html.new
<!--
function cs(){window.status='';}function ha(a){  pha=document.getElementById(a); nhi=pha.href.indexOf("&nh=");if(nhi < 1) {phb=pha.href+"&nh=1";} pha.href=phb;}function ca(a) {  pha=document.getElementById(a); nci=pha.href.indexOf("&nc=");if(nci < 1) {phb=pha.href+"&nc=1";} pha.href=phb;window.open(document.getElementById(a).href);}function ga(o,e) {if (document.getElementById) {a=o.id.substring(1);p = "";r = "";g = e.target;if (g) {t = g.id;f = g.parentNode;if (f) {p = f.id;h = f.parentNode;if (h)r = h.id;}} else {h = e.srcElement;f = h.parentNode;if (f)p = f.id;t = h.id;}if (t==a || p==a || r==a)return true;pha=document.getElementById(a); nbi=pha.href.indexOf("&nb=");if(nbi < 1) {phb=pha.href+"&nb=1";} pha.href=phb;window.open(document.getElementById(a).href);}}

function randHPWell() {
	var wells = new Array("hpwell_travel","hpwell_automobiles");
	var ar_id = wells[Math.floor(Math.random()*wells.length)]+parseInt(1+Math.floor(Math.random()*3));
	if (document.getElementById(ar_id)) { return document.getElementById(ar_id).href; } else { return "http://www.nytimes.com";}
}

function google_ad_request_done(ads) {
	var s = "";

	if (ads.length == 0) {
		return;
	} else if (ads.length == 1 && ads[0].type != 'image') {
		google_ad_section_line_height = "22px";
		google_ad_section_padding_left = "12px";
		google_title_link_font_size = "18px";
		google_ad_text_font_size = "14px";
		google_visible_url_font_size = "14px";
		google_target_div = 'SponLinkHP';
	} else if (ads[0].type != 'image') {
		google_ad_section_line_height = "14px";
		google_ad_section_padding_left = "7px";
		google_title_link_font_size = "12px";
		google_ad_text_font_size = "11px";
		google_visible_url_font_size = "10px";
		google_target_div = 'SponLinkHP';
	}
	s += '<table width="100%" height="" border="0" cellspacing="0" cellpadding="0" style="width:100%; border-style: solid; border-width: 1px; border-color: #9da3ad" >\n<tr>\n<td style="font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" valign="top"><table width="100%" height="100%" cellspacing="0" cellpadding="0" border="0" style="width:100%; height:100%;">\n<tr>\n <td style="background-color:#9da3ad; width:70%; height:20px; padding-top:2px; padding-left:11px; padding-bottom:2px; font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" width="70%" height="20" bgcolor="#9da3ad" ><span style="font-size: 12px; font-weight: normal; color:#ffffff;" >Ads by Google</span></td>\n<td style="padding-top:2px; padding-bottom:2px; width:30%; height:20px; align:right; background-color:#9da3ad; font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" width="30%" height="20" align="right" bgcolor="#9da3ad" ><span><a style="font-family:Arial,Helvetica,sans-serif; color: white; font-size:12px; padding-right:7px;" href="http://www.nytimes.com/ref/membercenter/faq/linkingqa16.html" onclick="window.open(\'\',\'popupad\',\'left=100,top=100,width=390,height=390,resizable,scrollbars=no\')" target="popupad">what\'s this?</a></span></td>\n</tr>\n</table>\n</td>\n</tr>\n<tr>\n<td style="height:110px; font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333;" valign="top" height="110"><table height="100%" width="100%" cellpadding="4" cellspacing="0" border="0" bgcolor="#f8f8f9" style="height:100%; width:100%; padding:4px; background-color:#f8f8f9;">\n';
	for (i = 0; i < ads.length; ++i) {
	   s += '<tr>\n<td style="font-family:Arial,Helvetica,sans-serif; font-size:12px; color:#333333; background-color:#f8f8f9;" valign="middle" >\n<div style="line-height:' + google_ad_section_line_height + '; padding-left:' + google_ad_section_padding_left + '; padding-bottom:5px;" >\n<a href="' + ads[i].url + '" target="_blank" style="font-size:' + google_title_link_font_size + '; color:#000066; font-weight:bold; text-decoration:underline;"> ' + ads[i].line1 + '</a><br>\n' + ads[i].line2 + ' ' + ads[i].line3 + '<br>\n<a href="' + ads[i].url + '" target="_blank" style="font-size:' + google_visible_url_font_size + '; color:#000066; font-weight:normal; text-decoration:none;">' + ads[i].visible_url + '</a>\n</div>\n </td>\n</tr>\n';
	}
	s += '</table>\n</td>\n</tr>\n</table>';
	document.getElementById(google_target_div).innerHTML = s;
	return;
}
google_ad_output = 'js';
google_max_num_ads = '3';
google_ad_client = 'ca-nytimes_homepage_js';
google_safe = 'high';
google_ad_channel = 'pg_url_test';
google_targeting = 'content';
if (window.nyt_google_count) { google_skip = nyt_google_count; }
google_ad_section = 'default';
google_hints = 'business news online,us news online,online us news,top online news,business international news,online latest news';
// -->
</script>

<script type="text/javascript" language="JavaScript" src="http://pagead2.googlesyndication.com/pagead/show_ads.js"></script>
</div>

</div>
</div><!--close cColumn -->    
</div><!--close spanAB --> 
</div><!--close column --> 
</div><!--close doubleRule -->
</div><!--close baseLayout -->
</div><!--close main -->
<footer class="pageFooter">
<div class="inset">
<nav class="pageFooterNav">
<ul class="pageFooterNavList wrap">
<li class="firstItem"><a href="http://www.nytco.com/">&copy; 2013 The New York Times Company</a></li>
<li><a href="http://spiderbites.nytimes.com/">Site Map</a></li>
<li><a href="http://www.nytimes.com/privacy">Privacy</a></li>
<li><a href="http://www.nytimes.com/ref/membercenter/help/privacy.html#pp">Your Ad Choices</a></li>
<li><a href="http://www.nytimes.whsites.net/mediakit/">Advertise</a></li>
<li><a href="http://www.nytimes.com/content/help/rights/sale/terms-of-sale.html ">Terms of Sale</a></li>
<li><a href="http://www.nytimes.com/ref/membercenter/help/agree.html">Terms of Service</a></li>
<li><a href="http://www.nytco.com/careers">Work With Us</a></li>
<li><a href="http://www.nytimes.com/rss">RSS</a></li>
<li><a href="http://www.nytimes.com/membercenter/sitehelp.html">Help</a></li>
<li><a href="http://www.nytimes.com/ref/membercenter/help/infoservdirectory.html">Contact Us</a></li>
<li class="lastItem"><a href="/membercenter/feedback.html">Site Feedback</a></li>
</ul>
</nav>
</div><!--close inset -->
</footer><!--close pageFooter -->
</div><!--close page -->
</div><!--close shell -->
<script type = "text/javascript" language = "JavaScript">
    var NYTArticleCommentCounts = {"http:\/\/www.nytimes.com\/2013\/09\/16\/world\/africa\/trading-privilege-for-privation-family-hits-a-nerve-in-south-africa.html":{"count":16,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/world\/africa\/trading-privilege-for-privation-family-hits-a-nerve-in-south-africa.html"},"http:\/\/www.nytimes.com\/2013\/09\/17\/nyregion\/thompson-to-concede-to-de-blasio-in-mayoral-primary.html":{"count":24,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/17\/nyregion\/thompson-to-concede-to-de-blasio-in-mayoral-primary.html"},"http:\/\/theater.nytimes.com\/show\/155381\/Kill-The-Bid\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/155381\/Kill-The-Bid\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/16\/booming\/the-whale-who-would-not-be-freed.html":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/booming\/the-whale-who-would-not-be-freed.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/world\/middleeast\/deal-represents-turn-for-syria-rebels-deflated.html":{"count":100,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/world\/middleeast\/deal-represents-turn-for-syria-rebels-deflated.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/us\/vietnam-legacy-finding-gi-fathers-and-children-left-behind.html":{"count":111,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/us\/vietnam-legacy-finding-gi-fathers-and-children-left-behind.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/us\/in-gun-debate-divide-grows-as-both-sides-dig-in-for-battle.html":{"count":320,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/us\/in-gun-debate-divide-grows-as-both-sides-dig-in-for-battle.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/environmental-challenges-invite-creativity":{"count":3,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/environmental-challenges-invite-creativity"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/marketing-to-children-drowns-out-innovation":{"count":3,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/marketing-to-children-drowns-out-innovation"},"http:\/\/movies.nytimes.com\/movie\/456327\/Devrim-arabalari\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/456327\/Devrim-arabalari\/overview"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/managers-can-nurture-creativity":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/managers-can-nurture-creativity"},"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html":{"count":88,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/weight-lifter-80-labeled-a-cheat-but-he-has-a-story.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/cities-are-the-fonts-of-creativity":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/cities-are-the-fonts-of-creativity"},"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/baseball\/rivera-hoping-send-off-isnt-farewell.html":{"count":13,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/baseball\/rivera-hoping-send-off-isnt-farewell.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/keller-the-missing-partner.html":{"count":123,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/keller-the-missing-partner.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/our-society-discourages-innovation":{"count":14,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/15\/is-creativity-endangered\/our-society-discourages-innovation"},"http:\/\/movies.nytimes.com\/movie\/84687\/Beggars-of-Life\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/84687\/Beggars-of-Life\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/the-syrian-pact.html":{"count":79,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/the-syrian-pact.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/krugman-give-jobs-a-change.html":{"count":332,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/krugman-give-jobs-a-change.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/how-to-fall-in-love-with-math.html":{"count":185,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/opinion\/how-to-fall-in-love-with-math.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/ncaafootball\/college-football-fans-shrugging-off-allegations-and-going-about-business-as-usual.html":{"count":7,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/ncaafootball\/college-football-fans-shrugging-off-allegations-and-going-about-business-as-usual.html"},"http:\/\/theater.nytimes.com\/show\/151732\/Playing-Sinatra\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/151732\/Playing-Sinatra\/overview"},"http:\/\/movies.nytimes.com\/movie\/100371\/Love-in-the-Rough\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/100371\/Love-in-the-Rough\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/16\/business\/economy\/summers-pulls-name-from-consideration-for-fed-chief.html":{"count":847,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/business\/economy\/summers-pulls-name-from-consideration-for-fed-chief.html"},"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/soccer\/red-bulls-rewind-alone-in-first-place.html":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/soccer\/red-bulls-rewind-alone-in-first-place.html"},"":{"count":0,"commentsEnabled":true,"assetUrl":""},"http:\/\/www.nytimes.com\/2013\/09\/16\/world\/middleeast\/syria-chemical-weapons-deal.html":{"count":213,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/world\/middleeast\/syria-chemical-weapons-deal.html"},"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=3c6ee8d7d8-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-3c6ee8d7d8-218221249":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=3c6ee8d7d8-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-3c6ee8d7d8-218221249"},"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/football\/in-nfls-violence-a-moral-quandary-for-fans.html":{"count":255,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/16\/sports\/football\/in-nfls-violence-a-moral-quandary-for-fans.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/business\/taste-testing-a-second-career.html":{"count":14,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/business\/taste-testing-a-second-career.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/nyregion\/the-two-wills-of-the-heiress-huguette-clark.html":{"count":282,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/nyregion\/the-two-wills-of-the-heiress-huguette-clark.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/business\/wall-st-exploits-ethanol-credits-and-prices-spike.html":{"count":304,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/business\/wall-st-exploits-ethanol-credits-and-prices-spike.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/sports\/baseball\/an-ace-tries-to-limit-the-damage-as-time-starts-to-run-out.html":{"count":18,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/sports\/baseball\/an-ace-tries-to-limit-the-damage-as-time-starts-to-run-out.html"},"http:\/\/movies.nytimes.com\/movie\/85383\/Blockade\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/85383\/Blockade\/overview"},"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=3c6ee8d7d8-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-3c6ee8d7d8-218189045":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=3c6ee8d7d8-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-3c6ee8d7d8-218189045"},"http:\/\/www.nytimes.com\/2013\/09\/15\/public-editor\/the-delicate-handling-of-images-of-war.html":{"count":12,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/public-editor\/the-delicate-handling-of-images-of-war.html"},"http:\/\/movies.nytimes.com\/movie\/270946\/Die-Frau-Ohne-Schatten-Wiener-Philharmoniker-\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/270946\/Die-Frau-Ohne-Schatten-Wiener-Philharmoniker-\/overview"},"http:\/\/movies.nytimes.com\/movie\/440855\/Man-Made-Afterlife-Entertainment-\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/440855\/Man-Made-Afterlife-Entertainment-\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/what-war-means.html":{"count":231,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/what-war-means.html"},"http:\/\/movies.nytimes.com\/movie\/157103\/Nights-at-O-Rear-s\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/157103\/Nights-at-O-Rear-s\/overview"},"http:\/\/movies.nytimes.com\/movie\/8492\/A-Case-of-Deadly-Force\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/8492\/A-Case-of-Deadly-Force\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/the-annual-republican-crisis.html":{"count":356,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/the-annual-republican-crisis.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/dowd-my-so-called-cia-life.html":{"count":161,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/dowd-my-so-called-cia-life.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/friedman-when-complexity-is-free.html":{"count":236,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/friedman-when-complexity-is-free.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/two-state-illusion.html":{"count":414,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/two-state-illusion.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/douthat-call-me-vlad.html":{"count":98,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/douthat-call-me-vlad.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/kristof-hearing-you-out.html":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/opinion\/sunday\/kristof-hearing-you-out.html"},"http:\/\/movies.nytimes.com\/movie\/110515\/Sky-Murder\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/110515\/Sky-Murder\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/nyregion\/building-blocs-not-lofts.html":{"count":12,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/nyregion\/building-blocs-not-lofts.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/world\/middleeast\/syria-talks.html":{"count":2064,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/world\/middleeast\/syria-talks.html"},"http:\/\/movies.nytimes.com\/movie\/466732\/Rush\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/466732\/Rush\/overview"},"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=9e3007bdc6-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-9e3007bdc6-218187109":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=9e3007bdc6-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-9e3007bdc6-218187109"},"http:\/\/www.nytimes.com\/2013\/09\/14\/sports\/baseball\/scorers-call-rivera-gets-win-not-save.html":{"count":13,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/sports\/baseball\/scorers-call-rivera-gets-win-not-save.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/us\/suicide-of-girl-after-bullying-raises-worries-on-web-sites.html":{"count":765,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/us\/suicide-of-girl-after-bullying-raises-worries-on-web-sites.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/opinion\/blow-occupy-wall-street-legacy.html":{"count":367,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/opinion\/blow-occupy-wall-street-legacy.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/your-money\/financing-start-up-dreams-with-retirement-savings.html":{"count":17,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/your-money\/financing-start-up-dreams-with-retirement-savings.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/opinion\/collins-back-to-boehner.html":{"count":315,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/opinion\/collins-back-to-boehner.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/opinion\/deceptive-practices-in-foreclosures.html":{"count":177,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/opinion\/deceptive-practices-in-foreclosures.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/world\/asia\/4-sentenced-to-death-in-rape-case-that-riveted-india.html":{"count":92,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/world\/asia\/4-sentenced-to-death-in-rape-case-that-riveted-india.html"},"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/a-sicilian-summer-on-the-mainland.html":{"count":40,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/a-sicilian-summer-on-the-mainland.html"},"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=ce4dd010e4-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-ce4dd010e4-218184537":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=ce4dd010e4-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-ce4dd010e4-218184537"},"http:\/\/movies.nytimes.com\/movie\/471788\/GMO-OMG\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471788\/GMO-OMG\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/14\/arts\/music\/homophobia-and-hip-hop-a-confession-breaks-a-barrier.html":{"count":87,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/arts\/music\/homophobia-and-hip-hop-a-confession-breaks-a-barrier.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/business\/economy\/nice-college-but-whatll-i-make-when-i-graduate.html":{"count":247,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/business\/economy\/nice-college-but-whatll-i-make-when-i-graduate.html"},"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/romesco-sauce-with-a-flexible-nature.html":{"count":11,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/romesco-sauce-with-a-flexible-nature.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/the-boy-genius-of-ulan-bator.html":{"count":118,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/the-boy-genius-of-ulan-bator.html"},"http:\/\/theater.nytimes.com\/show\/151257\/Elevator-Repair-Service-s-Arguendo\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/151257\/Elevator-Repair-Service-s-Arguendo\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/14\/world\/middleeast\/russia-united-states-syria-talks.html":{"count":67,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/world\/middleeast\/russia-united-states-syria-talks.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/sports\/soccer\/a-winter-world-cup-gulati-is-in-no-hurry-to-decide.html":{"count":25,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/sports\/soccer\/a-winter-world-cup-gulati-is-in-no-hurry-to-decide.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/how-to-get-a-job-with-a-philosophy-degree.html":{"count":147,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/how-to-get-a-job-with-a-philosophy-degree.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/realestate\/landmarking-the-friars-club.html":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/realestate\/landmarking-the-friars-club.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/your-money\/turning-the-conventional-stock-buying-wisdom-for-retirees-on-its-head.html":{"count":134,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/your-money\/turning-the-conventional-stock-buying-wisdom-for-retirees-on-its-head.html"},"http:\/\/travel.nytimes.com\/2013\/09\/15\/travel\/iquitos-peru-wet-and-wild.html":{"count":49,"commentsEnabled":false,"assetUrl":"http:\/\/travel.nytimes.com\/2013\/09\/15\/travel\/iquitos-peru-wet-and-wild.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/fashion\/Age-Is-No-Obstacle-to-Love-or-Adventure-modern-love.html":{"count":27,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/fashion\/Age-Is-No-Obstacle-to-Love-or-Adventure-modern-love.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/nyregion\/dozens-of-businesses-lost-in-jersey-shore-boardwalk-blaze.html":{"count":120,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/nyregion\/dozens-of-businesses-lost-in-jersey-shore-boardwalk-blaze.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/realestate\/living-apart-together.html":{"count":150,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/realestate\/living-apart-together.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/who-made-that-built-in-eraser.html":{"count":14,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/who-made-that-built-in-eraser.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/earl-sweatshirt-canadians-are-weirdos.html":{"count":3,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/earl-sweatshirt-canadians-are-weirdos.html"},"http:\/\/movies.nytimes.com\/movie\/471489\/Good-Ol-Freda\/overview":{"count":6,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471489\/Good-Ol-Freda\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/14\/sports\/football\/geno-smith-shows-enough-to-keep-jets-hopeful.html":{"count":31,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/sports\/football\/geno-smith-shows-enough-to-keep-jets-hopeful.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/the-fear-that-dare-not-speak-its-name.html":{"count":94,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/the-fear-that-dare-not-speak-its-name.html"},"http:\/\/movies.nytimes.com\/movie\/468567\/While-We-Were-Here\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/468567\/While-We-Were-Here\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/drama-truman-high-school.html":{"count":48,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/drama-truman-high-school.html"},"http:\/\/movies.nytimes.com\/movie\/471939\/Sample-This\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471939\/Sample-This\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/caveat-donor.html":{"count":14,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/caveat-donor.html"},"http:\/\/movies.nytimes.com\/movie\/471714\/Kaze-Tachinu\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471714\/Kaze-Tachinu\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/13\/nyregion\/fire-ravages-jersey-shore-boardwalk-rebuilt-after-hurricane-sandy.html":{"count":4,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/nyregion\/fire-ravages-jersey-shore-boardwalk-rebuilt-after-hurricane-sandy.html"},"http:\/\/www.nytimes.com\/2013\/09\/14\/nyregion\/bloomberg-says-he-will-not-make-endorsement-in-mayoral-race.html":{"count":186,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/14\/nyregion\/bloomberg-says-he-will-not-make-endorsement-in-mayoral-race.html"},"http:\/\/www.nytimes.com\/2013\/09\/13\/booming\/a-three-year-pledge-that-holds-still.html":{"count":18,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/booming\/a-three-year-pledge-that-holds-still.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/the-miss-america-pageant-has-been-beneficial-for-women-of-color":{"count":8,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/the-miss-america-pageant-has-been-beneficial-for-women-of-color"},"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=ce4dd010e4-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-ce4dd010e4-218185981":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=ce4dd010e4-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-ce4dd010e4-218185981"},"http:\/\/movies.nytimes.com\/movie\/470704\/Insidious-Chapter-2\/overview":{"count":4,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/470704\/Insidious-Chapter-2\/overview"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/humbled-and-honored-to-be-a-miss-america":{"count":16,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/humbled-and-honored-to-be-a-miss-america"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/theres-room-for-feminists-in-the-miss-america-pageant":{"count":46,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/theres-room-for-feminists-in-the-miss-america-pageant"},"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/what-becomes-of-the-lost-estates.html":{"count":11,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/what-becomes-of-the-lost-estates.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/the-miss-america-pageant-stills-sends-the-wrong-message":{"count":49,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/the-miss-america-pageant-stills-sends-the-wrong-message"},"http:\/\/movies.nytimes.com\/movie\/447019\/Malavita\/overview":{"count":14,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/447019\/Malavita\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/13\/world\/middleeast\/listing-demands-assad-uses-crisis-to-his-advantage.html":{"count":492,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/world\/middleeast\/listing-demands-assad-uses-crisis-to-his-advantage.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/beauty-pageants-like-the-miss-america-contest-should-die":{"count":113,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/beauty-pageants-like-the-miss-america-contest-should-die"},"http:\/\/theater.nytimes.com\/show\/137875\/Fetch-Clay-Make-Man\/overview":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/137875\/Fetch-Clay-Make-Man\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/13\/opinion\/who-will-be-left-in-egypt.html":{"count":134,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/opinion\/who-will-be-left-in-egypt.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/theater\/too-much-shakespeare-be-not-cowed.html":{"count":2,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/theater\/too-much-shakespeare-be-not-cowed.html"},"http:\/\/movies.nytimes.com\/movie\/471780\/Money-for-Nothing-Inside-the-Federal-Reserve\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471780\/Money-for-Nothing-Inside-the-Federal-Reserve\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/13\/opinion\/global\/cohen-an-anchorless-world.html":{"count":443,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/opinion\/global\/cohen-an-anchorless-world.html"},"http:\/\/www.nytimes.com\/2013\/09\/13\/opinion\/krugman-rich-mans-recovery.html":{"count":907,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/opinion\/krugman-rich-mans-recovery.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/theres-big-money-to-be-made-in-beauty-pageants":{"count":72,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/12\/is-the-miss-america-pageant-bad-for-women\/theres-big-money-to-be-made-in-beauty-pageants"},"http:\/\/www.nytimes.com\/2013\/09\/13\/nyregion\/lhota-accuses-de-blasio-of-trying-to-divide-the-city.html":{"count":190,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/nyregion\/lhota-accuses-de-blasio-of-trying-to-divide-the-city.html"},"http:\/\/www.nytimes.com\/2013\/09\/13\/us\/politics\/at-meeting-with-treasury-secretary-boehner-pressed-for-debt-ceiling-deal.html":{"count":425,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/us\/politics\/at-meeting-with-treasury-secretary-boehner-pressed-for-debt-ceiling-deal.html"},"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/reviews\/hungry-city-distilled-in-tribeca.html":{"count":4,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/18\/dining\/reviews\/hungry-city-distilled-in-tribeca.html"},"http:\/\/movies.nytimes.com\/movie\/440312\/Blackthorn-Rose\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/440312\/Blackthorn-Rose\/overview"},"http:\/\/theater.nytimes.com\/show\/143304\/The-Film-Society\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/143304\/The-Film-Society\/overview"},"http:\/\/movies.nytimes.com\/movie\/462966\/Four\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/462966\/Four\/overview"},"http:\/\/theater.nytimes.com\/2013\/09\/15\/theater\/too-much-shakespeare-be-not-cowed.html":{"count":132,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/2013\/09\/15\/theater\/too-much-shakespeare-be-not-cowed.html"},"http:\/\/www.nytimes.com\/2013\/09\/13\/science\/in-a-breathtaking-first-nasa-craft-exits-the-solar-system.html":{"count":431,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/13\/science\/in-a-breathtaking-first-nasa-craft-exits-the-solar-system.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/garden\/check-in-act-out.html":{"count":4,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/garden\/check-in-act-out.html"},"http:\/\/theater.nytimes.com\/show\/151716\/Carcass\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/151716\/Carcass\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/james-taylor-pig.html":{"count":39,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/james-taylor-pig.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/your-money\/free-apps-for-nearly-every-health-problem-but-what-about-privacy.html":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/your-money\/free-apps-for-nearly-every-health-problem-but-what-about-privacy.html"},"http:\/\/theater.nytimes.com\/show\/155338\/McGoldrick-s-Thread\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/155338\/McGoldrick-s-Thread\/overview"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/even-a-flawed-plan-in-syria-will-be-useful":{"count":4,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/even-a-flawed-plan-in-syria-will-be-useful"},"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/asia\/afghan-army-struggles-in-district-under-siege.html":{"count":44,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/asia\/afghan-army-struggles-in-district-under-siege.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/europe\/as-obama-pauses-action-putin-takes-center-stage.html":{"count":479,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/europe\/as-obama-pauses-action-putin-takes-center-stage.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/russia-must-agree-to-an-enforcement-mechanism":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/russia-must-agree-to-an-enforcement-mechanism"},"http:\/\/www.nytimes.com\/2013\/09\/12\/us\/recall-vote-on-guns-exposes-rift-in-colorados-blue-veneer.html":{"count":204,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/us\/recall-vote-on-guns-exposes-rift-in-colorados-blue-veneer.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/business\/unions-misgivings-on-health-law-burst-into-view.html":{"count":343,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/business\/unions-misgivings-on-health-law-burst-into-view.html"},"http:\/\/movies.nytimes.com\/movie\/105658\/Passion-Flower\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/105658\/Passion-Flower\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/booming\/to-the-best-of-my-memory-it-was-love.html":{"count":167,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/booming\/to-the-best-of-my-memory-it-was-love.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/no-child-left-untableted.html":{"count":500,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/no-child-left-untableted.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/well-need-a-ceasefire-in-syria-first":{"count":7,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/well-need-a-ceasefire-in-syria-first"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/logistical-problems-of-destroying-syrias-weapons-couldnt-be-overcome-now":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/logistical-problems-of-destroying-syrias-weapons-couldnt-be-overcome-now"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/a-delaying-tactic-to-stall-assads-fall":{"count":22,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/a-delaying-tactic-to-stall-assads-fall"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/key-arab-states-want-results":{"count":16,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/key-arab-states-want-results"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/chemical-agents-could-be-secured-quickly":{"count":28,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/11\/can-syrias-chemical-arsenal-be-destroyed\/chemical-agents-could-be-secured-quickly"},"http:\/\/theater.nytimes.com\/show\/157025\/Mike-Daisey-All-the-Faces-of-the-Moon\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/157025\/Mike-Daisey-All-the-Faces-of-the-Moon\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/middleeast\/Obamas-Pivots-on-Syria-Confrontation.html":{"count":687,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/middleeast\/Obamas-Pivots-on-Syria-Confrontation.html"},"http:\/\/theater.nytimes.com\/show\/149000\/I-Can-See-Clearly-Now-The-Wheelchair-on-my-Face-\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/149000\/I-Can-See-Clearly-Now-The-Wheelchair-on-my-Face-\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/kristof-that-threat-worked.html":{"count":155,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/kristof-that-threat-worked.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/sports\/baseball\/where-jeter-and-the-yankees-go-from-here.html":{"count":92,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/sports\/baseball\/where-jeter-and-the-yankees-go-from-here.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/nyregion\/for-thompson-pressure-to-let-de-blasio-win.html":{"count":204,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/nyregion\/for-thompson-pressure-to-let-de-blasio-win.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/diplomacy-as-deterrent.html":{"count":113,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/diplomacy-as-deterrent.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/collins-new-york-has-a-message.html":{"count":210,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/collins-new-york-has-a-message.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/technology\/personaltech\/ftc-looking-into-facebook-privacy-policy.html":{"count":57,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/technology\/personaltech\/ftc-looking-into-facebook-privacy-policy.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/blow-its-a-mad-mad-mad-mad-world.html":{"count":215,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/blow-its-a-mad-mad-mad-mad-world.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/putin-plea-for-caution-from-russia-on-syria.html":{"count":4447,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/opinion\/putin-plea-for-caution-from-russia-on-syria.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/lobster-pasta-requires-a-light-crisp-touch.html":{"count":2,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/lobster-pasta-requires-a-light-crisp-touch.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/dining\/join-our-video-chat-with-fuchsia-dunlop.html":{"count":12,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/dining\/join-our-video-chat-with-fuchsia-dunlop.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/sports\/soccer\/player-ratings-us-2-vs-mexico-0.html":{"count":33,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/sports\/soccer\/player-ratings-us-2-vs-mexico-0.html"},"http:\/\/travel.nytimes.com\/2013\/09\/15\/travel\/cuba-going-with-a-tour-company.html":{"count":32,"commentsEnabled":true,"assetUrl":"http:\/\/travel.nytimes.com\/2013\/09\/15\/travel\/cuba-going-with-a-tour-company.html"},"http:\/\/movies.nytimes.com\/movie\/470893\/Deceptive-Practice-The-Mysteries-and-Mentors-of-Ricky-Jay\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/470893\/Deceptive-Practice-The-Mysteries-and-Mentors-of-Ricky-Jay\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/11\/booming\/advice-for-middle-age-seekers-of-moocs-part-2.html":{"count":6,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/booming\/advice-for-middle-age-seekers-of-moocs-part-2.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/of-two-minds-at-dinner":{"count":5,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/of-two-minds-at-dinner"},"http:\/\/movies.nytimes.com\/movie\/460939\/Winnie-Mandela\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/460939\/Winnie-Mandela\/overview"},"http:\/\/movies.nytimes.com\/movie\/355770\/Boys-Briefs-4-Six-Short-Films-About-Guys-Who-Hustle\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/355770\/Boys-Briefs-4-Six-Short-Films-About-Guys-Who-Hustle\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/rescuing-tartare-from-the-stuffy-old-power-lunchers.html":{"count":4,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/rescuing-tartare-from-the-stuffy-old-power-lunchers.html"},"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/obama-syria.html":{"count":496,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/12\/world\/obama-syria.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/season-well-but-think-of-others-tastes":{"count":29,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/season-well-but-think-of-others-tastes"},"http:\/\/www.nytimes.com\/2013\/09\/11\/us\/court-upbraided-nsa-on-its-use-of-call-log-data.html":{"count":117,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/us\/court-upbraided-nsa-on-its-use-of-call-log-data.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/us\/colorado-lawmaker-concedes-defeat-in-recall-over-gun-law.html":{"count":1659,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/us\/colorado-lawmaker-concedes-defeat-in-recall-over-gun-law.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/salt-is-a-problem-but-salt-shakers-arent":{"count":36,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/salt-is-a-problem-but-salt-shakers-arent"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/can-emotional-intelligence-be-taught.html":{"count":425,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/can-emotional-intelligence-be-taught.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/baseball\/girardi-and-showalter-act-in-the-heat-of-the-moment-fueled-by-a-playoff-race.html":{"count":35,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/baseball\/girardi-and-showalter-act-in-the-heat-of-the-moment-fueled-by-a-playoff-race.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/soccer\/another-big-us-victory-in-columbus.html":{"count":55,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/soccer\/another-big-us-victory-in-columbus.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/at-restaurants-customers-should-have-control-of-the-salt":{"count":17,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/at-restaurants-customers-should-have-control-of-the-salt"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/the-chef-knows-best-about-when-to-salt":{"count":176,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/the-chef-knows-best-about-when-to-salt"},"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/homeland-confusion.html":{"count":102,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/homeland-confusion.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/the-race-to-improve-global-health.html":{"count":40,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/the-race-to-improve-global-health.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/salt-is-a-matter-of-flavor-not-health":{"count":48,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/10\/should-salt-have-a-place-at-the-table\/salt-is-a-matter-of-flavor-not-health"},"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/soccer\/talk-of-a-cooler-2022-world-cup-heats-up.html":{"count":36,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/soccer\/talk-of-a-cooler-2022-world-cup-heats-up.html"},"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=19a018c0c0-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-19a018c0c0-218183661":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/138985\/Philip-Goes-Forth\/overview?utm_source=Mint Mail&utm_campaign=19a018c0c0-PHILIP_Thank_You8_27_2013&utm_medium=email&utm_term=0_b39c34ca4d-19a018c0c0-218183661"},"http:\/\/www.nytimes.com\/2013\/09\/10\/your-money\/relief-from-student-loan-debt-for-public-service-workers.html":{"count":34,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/your-money\/relief-from-student-loan-debt-for-public-service-workers.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/dowd-who-do-you-trust.html":{"count":761,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/dowd-who-do-you-trust.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/friedman-threaten-to-threaten.html":{"count":348,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/opinion\/friedman-threaten-to-threaten.html"},"http:\/\/movies.nytimes.com\/movie\/471456\/Harry-Dean-Stanton-Partly-Fiction\/overview":{"count":12,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471456\/Harry-Dean-Stanton-Partly-Fiction\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/11\/nyregion\/results-of-new-york-citys-mayoral-primaries.html":{"count":396,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/nyregion\/results-of-new-york-citys-mayoral-primaries.html"},"http:\/\/movies.nytimes.com\/movie\/471751\/Shuddh-Desi-Romance\/overview":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471751\/Shuddh-Desi-Romance\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/the-family-apron.html":{"count":20,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/the-family-apron.html"},"http:\/\/travel.nytimes.com\/2013\/09\/10\/travel\/finding-the-right-roadside-rooms.html":{"count":65,"commentsEnabled":true,"assetUrl":"http:\/\/travel.nytimes.com\/2013\/09\/10\/travel\/finding-the-right-roadside-rooms.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/reviews\/restaurant-review-armani-ristorante-fifth-avenue-in-midtown.html":{"count":24,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/reviews\/restaurant-review-armani-ristorante-fifth-avenue-in-midtown.html"},"http:\/\/movies.nytimes.com\/movie\/471849\/Mademoiselle-C\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/movies.nytimes.com\/movie\/471849\/Mademoiselle-C\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/late-summers-grilling-sweet-spot.html":{"count":50,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/late-summers-grilling-sweet-spot.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/technology\/apple-shows-off-2-new-iphones-one-a-lower-cost-model.html":{"count":337,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/technology\/apple-shows-off-2-new-iphones-one-a-lower-cost-model.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/putting-up-tomato-preserves.html":{"count":44,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/putting-up-tomato-preserves.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/train-workers-create-jobs":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/train-workers-create-jobs"},"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/baseball\/yankees-moving-to-wfan-bumping-the-mets.html":{"count":166,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/sports\/baseball\/yankees-moving-to-wfan-bumping-the-mets.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/books\/review\/salingers-big-appeal-the-life-or-the-work.html":{"count":26,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/books\/review\/salingers-big-appeal-the-life-or-the-work.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/world\/asia\/china-cracks-down-on-online-opinion-makers.html":{"count":85,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/world\/asia\/china-cracks-down-on-online-opinion-makers.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/booming\/old-man-twice-neil-youngs-way-and-redlight-kings.html":{"count":17,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/booming\/old-man-twice-neil-youngs-way-and-redlight-kings.html"},"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/our-debt-to-society.html":{"count":23,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/15\/magazine\/our-debt-to-society.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/animals-matter-in-this-concrete-jungle":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/animals-matter-in-this-concrete-jungle"},"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/searching-for-truffles-a-treasure-that-comes-in-black.html":{"count":23,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/searching-for-truffles-a-treasure-that-comes-in-black.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/my-life-as-a-warrior-princess.html":{"count":117,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/my-life-as-a-warrior-princess.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/booming\/bad-dog.html":{"count":512,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/booming\/bad-dog.html"},"http:\/\/www.nytimes.com\/2013\/09\/11\/world\/middleeast\/syrian-chemical-arsenal.html":{"count":1245,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/world\/middleeast\/syrian-chemical-arsenal.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/us\/in-missouri-governor-turns-tax-cut-debate-against-gop.html":{"count":292,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/us\/in-missouri-governor-turns-tax-cut-debate-against-gop.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/booming\/coming-out-about-hiv-and-facing-down-the-stigma.html":{"count":52,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/booming\/coming-out-about-hiv-and-facing-down-the-stigma.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/sports\/soccer\/us-at-home-vs-a-mexican-team-that-has-lost-way.html":{"count":8,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/sports\/soccer\/us-at-home-vs-a-mexican-team-that-has-lost-way.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/an-inclusive-mayor-would-be-nice":{"count":0,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/an-inclusive-mayor-would-be-nice"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/staten-island-is-still-recovering-from-sandy":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/staten-island-is-still-recovering-from-sandy"},"http:\/\/www.nytimes.com\/2013\/09\/10\/nyregion\/on-reed-thin-evidence-a-very-wide-net-of-police-surveillance.html":{"count":10,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/nyregion\/on-reed-thin-evidence-a-very-wide-net-of-police-surveillance.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/business\/the-border-is-a-back-door-for-us-device-searches.html":{"count":194,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/business\/the-border-is-a-back-door-for-us-device-searches.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/nyregion\/long-stormy-mayoral-race-hurtles-to-finish.html":{"count":102,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/nyregion\/long-stormy-mayoral-race-hurtles-to-finish.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/one-classroom-two-genders.html":{"count":118,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/one-classroom-two-genders.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/global\/cohen-rouhanis-new-year.html":{"count":91,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/global\/cohen-rouhanis-new-year.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/a-diplomatic-proposal-for-syria.html":{"count":366,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/a-diplomatic-proposal-for-syria.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/sports\/tennis\/nadal-beats-djokovic-to-win-us-open.html":{"count":181,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/sports\/tennis\/nadal-beats-djokovic-to-win-us-open.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/bruni-for-richer-for-poorer.html":{"count":213,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/opinion\/bruni-for-richer-for-poorer.html"},"http:\/\/www.nytimes.com\/2013\/09\/10\/world\/middleeast\/obama-embraces-russian-proposal-on-syria-weapons.html":{"count":575,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/world\/middleeast\/obama-embraces-russian-proposal-on-syria-weapons.html"},"http:\/\/www.nytimes.com\/2013\/09\/09\/your-money\/trying-to-outguess-the-unpredictable.html":{"count":11,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/09\/your-money\/trying-to-outguess-the-unpredictable.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/make-new-york-city-more-bike-friendly":{"count":10,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/09\/vining-the-new-york-city-primaries\/make-new-york-city-more-bike-friendly"},"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/savoring-a-bygone-splendor-the-maritime-menu.html":{"count":49,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/11\/dining\/savoring-a-bygone-splendor-the-maritime-menu.html"},"http:\/\/tv.nytimes.com\/episode\/5540311\/Boardwalk-Empire\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/tv.nytimes.com\/episode\/5540311\/Boardwalk-Empire\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/10\/science\/improving-respirator-masks-to-put-fresh-air-in-reach.html":{"count":58,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/science\/improving-respirator-masks-to-put-fresh-air-in-reach.html"},"http:\/\/theater.nytimes.com\/show\/158275\/Bike-America\/overview":{"count":1,"commentsEnabled":true,"assetUrl":"http:\/\/theater.nytimes.com\/show\/158275\/Bike-America\/overview"},"http:\/\/www.nytimes.com\/2013\/09\/10\/arts\/design\/new-van-gogh-painting-discovered-in-amsterdam.html":{"count":140,"commentsEnabled":false,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/10\/arts\/design\/new-van-gogh-painting-discovered-in-amsterdam.html"},"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/08\/privacy-and-the-internet-of-things\/informed-consumers-will-use-less-energy":{"count":3,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/roomfordebate\/2013\/09\/08\/privacy-and-the-internet-of-things\/informed-consumers-will-use-less-energy"},"http:\/\/www.nytimes.com\/2013\/09\/09\/dining\/sauteed-chard-makes-its-way-to-center-stage.html":{"count":19,"commentsEnabled":true,"assetUrl":"http:\/\/www.nytimes.com\/2013\/09\/09\/dining\/sauteed-chard-makes-its-way-to-center-stage.html"}}</script>		
<IMG CLASS="hidden" SRC="/adx/bin/clientside/f845e0caQ2FQ5BQ5BQ5BecQ25TQ5DyQ25hQ5BQ5DeQ25k,gQ3EBhEQ25zQ20BMu594c94zc4ch9hMqc" height="1" width="3">






<script type="text/javascript" src="http://js.nyt.com/js2/build/homepage/bottom.js"></script>

			
		<!-- Start UPT call -->
		<img height="1" width="3" border=0 src="http://up.nytimes.com/?d=0/1/&t=1&s=0&ui=&r=&u=www%2enytimes%2ecom%2f%3f">
		<!-- End UPT call -->
	
		
        <script language="JavaScript"><!--
          var dcsvid="";
          var regstatus="non-registered";
        //--></script>
        <script src="http://graphics8.nytimes.com/js/app/analytics/trackingTags_v1.1.js" type="text/javascript"></script>
        <noscript>
          <div><img alt="DCSIMG" id="DCSIMG" width="1" height="1" src="http://wt.o.nytimes.com/dcsym57yw10000s1s8g0boozt_9t1x/njs.gif?dcsuri=/nojavascript&amp;WT.js=No&amp;WT.tv=1.0.7"/></div>
        </noscript>
   
</body>
</html>



