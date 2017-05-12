#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('XML::RSS::Feed');
    use_ok('XML::RSS::Headline::Fark');
}

my $feed = XML::RSS::Feed->new(
    name  => 'fark',
    url   => "http://jobs.perl.org/rss/standard.rss",
    hlobj => "XML::RSS::Headline::Fark"
);
isa_ok( $feed, "XML::RSS::Feed" );
ok( $feed->parse( xml(1) ), "Parse Fark XML" );
my $headline = ( $feed->headlines )[0];
is( $headline->headline,
    q|Netscape intern editing CNN names pic of GWB "a$$hole.jpg" -- unemployment ensues|,
    "Fark headline matched"
);
is( $headline->url,
    q|http://www.worldnetdaily.com/news/article.asp?ARTICLE_ID=41291|,
    "Fark url matched"
);

sub xml {
    my ($index) = @_;
    $index--;
    return (
        q|<?xml version="1.0"?>
<rss version="0.92">
<channel>
<title>Fark</title>
<link>http://www.fark.com/</link>
<description>It's not news, it's fark</description>
<image>
<title>Fark RSS</title>
<url>http://img.fark.com/images/2002/links/fark.gif</url>
<link>http://www.fark.com/</link>
</image>
<lastBuildDate></lastBuildDate>
<item>
<title>[Amusing]	Netscape intern editing CNN names pic of GWB &amp;quot;a$$hole.jpg&amp;quot; -- unemployment ensues</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1200416&amp;location=http://www.worldnetdaily.com/news/article.asp%3fARTICLE_ID=41291</link>
<description>[Drudge]</description>
</item>

<item>
<title>[Cool]	Toy factory looking to hire 20 children as advisors at $12,000 annually</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199711&amp;location=http://www.chinadaily.com.cn/english/doc/2004-11/04/content_388540.htm</link>
<description>(chinadaily.com)</description>
</item>

<item>
<title>[Amusing]	Words you thought you'd never see together: Vatican Sex Guide</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1200017&amp;location=http://www.disinfo.com/site/displayarticle6980.html</link>
<description>[Canada.com]</description>
</item>

<item>
<title>[Cool]	&amp;quot;Grand Theft Auto: San Andreas&amp;quot; gets two thumbs up</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199708&amp;location=http://www.lancasteronline.com/pages/news/ap/4/games_grand_theft</link>
<description>(LancasterOnline.com)</description>
</item>

<item>
<title>[Misc]	Today's &amp;quot;extremely shiny truck spill&amp;quot; story brought to you by Mount Pleasant, NY</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199641&amp;location=http://www.thejournalnews.com/newsroom/110404/b0104greentruck.html</link>
<description>(NY Journal News)</description>
</item>

<item>
<title>[Strange]	I thought I was a geek until I read this article: Sci-fi fans called into an alternate reality</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199766&amp;location=http://news.com.com/Sci-fi%2Bfans%2Bcalled%2Binto%2Ban%2Balternate%2Breality/2100-1023_3-5438916.html%3ftag=nefd.hed</link>
<description>[C\|Net]</description>
</item>

<item>
<title>[Hero]	In an effort to attract more worshippers, Canterbury Cathedral revives its 300-year-old tradition of serving beer</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199568&amp;location=http://news.bbc.co.uk/1/hi/england/kent/3978293.stm</link>
<description>[BBC]</description>
</item>

<item>
<title>[Sad]	America's prison system at work: Man released from prison, promptly goes home and stabs wife in the neck</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199687&amp;location=http://story.news.yahoo.com/news%3ftmpl=story%26cid=391%26e=3%26u=/ibsys/20041104/lo_ksat/2439167</link>
<description>[Yahoo]</description>
</item>

<item>
<title>[Interesting]	The best WiFi hotels</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199526&amp;location=http://www.hotelchatter.com/story/2004/11/2/201522/957</link>
<description>(Hotel Chatter)</description>
</item>

<item>
<title>[Scary]	Old and busted: pirate ship, new hotness: skycrane</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199670&amp;location=http://greenvilleonline.com/news/2004/11/04/2004110452322.htm</link>
<description>(Greenvilleonline)</description>
</item>

<item>
<title>[Misc]	Locusts invade Lebanon (with weird pic)</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199519&amp;location=http://www.dailystar.com.lb/article.asp%3fedition_id=1%26categ_id=2%26article_id=9861</link>
<description>(Some Guy)</description>
</item>

<item>
<title>[Sad]	Elizabeth Edwards diagnosed with breast cancer</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1200026&amp;location=http://www.msnbc.msn.com/id/6408022</link>
<description>[MSNBC]</description>
</item>

<item>
<title>[Photoshop]	Photoshop the teaser poster for Star Wars Episode III: Revenge of the Sith</title>
<link>http://forums.fark.com/cgi/fark/comments.pl?IDLink=1193002</link>
<description>(Starwars.com)</description>
</item>

<item>
<title>[Interesting]	Scientists closing in on discovering why time flows in only one direction. Art Bell surrenders</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199554&amp;location=http://www.spaceref.com/news/viewpr.html%3fpid=15407</link>
<description>(Some time traveller)</description>
</item>

<item>
<title>[Cool]	Computerized rat brain flies flight simulator. Sarah Connor unavailable for comment</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199501&amp;location=http://www.cnn.com/2004/TECH/11/02/brain.dish/index.html</link>
<description>[CNN]</description>
</item>

<item>
<title>[Dumbass]	Man, 46, survives jump into lion's den after trying to convert lions to Christianity (with pic)</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199487&amp;location=http://www.local6.com/news/3887764/detail.html#sillyman</link>
<description>(Some Guy)</description>
</item>

<item>
<title>[NewsFlash]	Like Franco before him, Arafat not dead</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199930&amp;location=http://abcnews.go.com/International/wireStory%3fid=226597</link>
<description>[ABC News]</description>
</item>

<item>
<title>[Scary]	Rat causes school bus wreck. &amp;quot;The rat got underneath the gas pedal and she hit the brake, and that's when we went off the road,&amp;quot; he said. &amp;quot;All I remember is being rolled around, like I was in a washing machine&amp;quot;</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199538&amp;location=http://www.montgomeryadvertiser.com/NEWSV5/storyV5BUSCRASH04W.htm</link>
<description>(Some Guy)</description>
</item>

<item>
<title>[PSA]	Seattle Fark Party this Sunday 1:00 pm at Jillians. Drew's going to be there and hung over from the Vancouver party, let's have some beers and watch football</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199125&amp;location=http://www.fark.com</link>
<description>[FARK]</description>
</item>

<item>
<title>This RSS feed powered by www.pluck.com</title>
<link>http://www.pluck.com/?GCID=C12286x007</link>
<description>Download Pluck and extend Internet Explorer with free tools to read RSS feeds, synchronize bookmarks, share web research and power search eBay, Google and more. Adware and spyware free.</description>
</item>

<item>
<title>[PSA]	Vancouver Fark Party this Saturday 8pm at the Jolly Taxpayer's Pub. Drew's gonna be in town, let's have some beers</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199124&amp;location=http://www.fark.com</link>
<description>[FARK]</description>
</item>

<item>
<title>[Followup]	Email spammers found guilty. Sentenced to serve nine long years in a federal pound-me-in-the-ass prison. Time to tell your cellmates not to buy penis-enlargement pills</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199695&amp;location=http://www.usatoday.com/money/industries/technology/2004-11-03-spam_x.htm</link>
<description>[USA Today]</description>
</item>

<item>
<title>[Amusing]	The softer side of rugby</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199499&amp;location=http://www.nbc4.tv/news/3887638/detail.html</link>
<description>[AP]</description>
</item>

<item>
<title>[Cool]	The coolest pic you'll see today: NGC 7023, The Iris Nebula</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199460&amp;location=http://antwrp.gsfc.nasa.gov/apod/ap041104.html</link>
<description>(Some Astronomer)</description>
</item>

<item>
<title>[Interesting]	A fire that broke out more than 100 years ago at a Chinese coalfield has finally been extinguished. Burning coal emitted 100,000 tons of harmful gases -- including carbon monoxide, sulphur dioxide and 40,000 tons of ashes every year</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199452&amp;location=http://news.bbc.co.uk/1/hi/world/asia-pacific/3978329.stm</link>
<description>[BBC]</description>
</item>

<item>
<title>[Amusing]	Roma Tre University makes students an offer thay can't refuse: Learn all about the Mafia in 20 hours</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199464&amp;location=http://iol.co.za/index.php%3fset_id=1%26click_id=29%26art_id=qw1099542240250B213</link>
<description>[IOL]</description>
</item>

<item>
<title>[Unlikely]	Elton John wants to develop sitcom based on aging rock stars, claims &amp;quot;it's a little bit funny&amp;quot;</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199433&amp;location=http://www.reuters.co.uk/newsPackageArticle.jhtml%3ftype=entertainmentNews%26storyID=615186%26section=news</link>
<description>[Reuters]</description>
</item>

<item>
<title>[Photoshop]	What if other popular movies were performed by puppets?</title>
<link>http://forums.fark.com/cgi/fark/comments.pl?IDLink=1192795</link>
<description>(The Strings Made Me Do It)</description>
</item>

<item>
<title>[NewsFlash]	Arafat enters coma. Aides claim he's just taking a long nap</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199445&amp;location=http://olympics.reuters.com/newsArticle.jhtml%3ftype=topNews%26storyID=6712740</link>
<description>[Reuters]</description>
</item>

<item>
<title>[Interesting]	Texas man on death row commits suicide by hanging. Efforts to resuscitate him fail, denying the criminal justice system all the fun</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199307&amp;location=http://cbsnewyork.com/national/BRF--DeathRowDeath-aa/resources_news_html</link>
<description>[CBS News]</description>
</item>

<item>
<title>[Strange]	Kirstie Alley asks publicist to breast feed her pet possum</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198797&amp;location=http://www.azcentral.com/offbeat/articles/1102kirstie02-ON.html</link>
<description>[AZCentral]</description>
</item>

<item>
<title>[Scary]	Couple on fishing jaunt meet particularly gruesome end after getting caught up in the net roller</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199319&amp;location=http://mdn.mainichi.co.jp/news/20041103p2a00m0dm012002c.html</link>
<description>[MDN]</description>
</item>

<item>
<title>[Ironic]	Al Sharpton rescues man who was laid off from his job of shoveling manure</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199039&amp;location=http://www.ncbuy.com/news/2004-11-03/1010987.html</link>
<description>[NCBuy]</description>
</item>

<item>
<title>[Dumbass]	Man buys tiny-ass beach hut, with no toilet, for $180,000</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199035&amp;location=http://www.yorkshiretoday.co.uk/ViewArticle2.aspx%3fSectionID=55%26ArticleID=881136</link>
<description>(Yorkshire Today)</description>
</item>

<item>
<title>[Florida]	Ohio avoids next &amp;quot;Florida&amp;quot; tag as Kerry concedes -- amusing because that's the actual headline, and true</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199112&amp;location=http://story.news.yahoo.com/news%3ftmpl=story%26cid=584%26e=7%26u=/nm/20041103/pl_nm/election_ohio_dc</link>
<description>[Yahoo]</description>
</item>

<item>
<title>[Amusing]	For auction: Michael Moore's relevance. Shipping is free because it's so tiny</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199079&amp;location=http://cgi.ebay.com/ws/eBayISAPI.dll%3fViewItem%26category=1469%26item=3850553305%26rd=1</link>
<description>[eBay]</description>
</item>

<item>
<title>[Scary]	Liquid heroin found in fruit juice boxes labeled &amp;quot;Hit Fruit Drink&amp;quot;</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198957&amp;location=http://apnews.myway.com//article/20041104/D864NUP80.html</link>
<description>[AP]</description>
</item>

<item>
<title>[Obvious]	Why Bush won</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199249&amp;location=http://www.corporatemofo.com/stories/041103whybushwon.htm</link>
<description>[Corporate Mofo]</description>
</item>

<item>
<title>[Weird]	Groundskeeper finds grenade shell on Wrigley Field. Insert Cubs joke here</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198725&amp;location=http://apnews.myway.com//article/20041103/D864KVQG1.html</link>
<description>[AP]</description>
</item>

<item>
<title>This RSS feed powered by www.pluck.com</title>
<link>http://www.pluck.com/?GCID=C12286x007</link>
<description>Download Pluck and extend Internet Explorer with free tools to read RSS feeds, synchronize bookmarks, share web research and power search eBay, Google and more. Adware and spyware free.</description>
</item>

<item>
<title>[Cool]	New features of Beagle 3 lander include installing antenna on top and camera for live video of death plunge to surface</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198536&amp;location=http://news.bbc.co.uk/2/hi/science/nature/3977967.stm</link>
<description>[BBC]</description>
</item>

<item>
<title>[NewsFlash]	Arafat nearly dead in French hospital. Israeli troops sent to help &amp;quot;stabilize his condition&amp;quot;</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199118&amp;location=http://story.news.yahoo.com/news%3ftmpl=story%26u=/ap/20041104/ap_on_re_mi_ea/arafat%26cid=540%26ncid=716</link>
<description>[AP]</description>
</item>

<item>
<title>[News]	Drudge: Ashcroft to resign in &amp;quot;next few days&amp;quot;</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1199087&amp;location=http://www.drudgereportarchives.com/data/2004/11/04/20041104_022200.htm</link>
<description>[Drudge]</description>
</item>

<item>
<title>[Strange]	Naked man boards moving jumbo jet after being refused ticket</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198778&amp;location=http://story.news.yahoo.com/news%3ftmpl=story%26u=/nm/20041103/od_uk_nm/oukoe_odd_jet%26e=2</link>
<description>[Yahoo]</description>
</item>

<item>
<title>[Boobies]	Serena Williams wears a see-through dress. The Yahoo is there</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198252&amp;location=http://news.yahoo.com/news%3ftmpl=story2%26u=/041102/ids_photos_en/r3530771616.jpg%26e=2%26ncid=1778</link>
<description>[Yahoo]</description>
</item>

<item>
<title>[Scary]	Man in small plane decides to go shopping at Target (with video)</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198453&amp;location=http://www.wistv.com/Global/story.asp%3fS=2514272%26nav=0RaMSgr8</link>
<description>(wistv.com)</description>
</item>

<item>
<title>[Strange]	Staffordshire terrier talks and takes care of cats</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198243&amp;location=http://www.funreports.com/2004/11/03/56958.html</link>
<description>[FunReports]</description>
</item>

<item>
<title>[Hero]	Five-year-old boy delivers baby</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198320&amp;location=http://www.boston.com/news/odd/articles/2004/11/03/five_year_old_boy_helps_mom_deliver_baby</link>
<description>[Boston Globe]</description>
</item>

<item>
<title>[Spiffy]	Scientists set to launch Deep Impact at the end of year: &amp;quot;We're going to hit it and see what happens&amp;quot;</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1198562&amp;location=http://dsc.discovery.com/news/briefs/20041101/deepimpact.html</link>
<description>[Discovery]</description>
</item>

<item>
<title>[Stupid]	Small company successfully patents the most obvious use of the Internet -- international sales -- and sues Dell</title>
<link>http://go.fark.com/cgi/fark/go.pl?IDLink=1197989&amp;location=http://money.cnn.com/2004/11/02/technology/dell_de</link>
<description>[CNN]</description>
</item>
</channel></rss>|
    )[$index];
}
