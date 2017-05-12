#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 53;

BEGIN { use_ok('XML::RSS::Feed') }

my $feed = XML::RSS::Feed->new(
    url  => "http://www.jbisbee.com/rdf/",
    name => 'jbisbee',
);
isa_ok( $feed, 'XML::RSS::Feed' );

$SIG{__WARN__} = build_warn("Wide character in print");
my $xml = do { local $/; <DATA> };
$feed->parse($xml);
my $count = 0;
for my $headline ( $feed->headlines ) {
    $count++;
    ok( $headline->headline, "Headline: $count" );
}

my $feed2 = XML::RSS::Feed->new(
    url            => "http://www.jbisbee.com/rdf/",
    name           => 'jbisbee',
    headline_as_id => 1,
);
isa_ok( $feed, 'XML::RSS::Feed' );
$feed2->parse($xml);
$count = 0;
for my $headline ( $feed2->headlines ) {
    $count++;
    ok( $headline->headline, "Headline: $count" );
}

sub build_warn {
    my @args = @_;
    return sub { my ($warn) = @_; like( $warn, qr/$_/i, $_ ) for @args };
}

__DATA__
<?xml version='1.0' encoding='utf-8' ?>
<!--  If you are running a bot please visit this policy page outlining rules you must respect. http://www.livejournal.com/bots/  --><rss version='2.0'>
<channel>
  <title>KYQ</title>
  <link>http://www.livejournal.com/users/kyq/</link>
  <description>KYQ - LiveJournal.com</description>
  <managingEditor>ore_wa@yahoo.com</managingEditor>
  <lastBuildDate>Mon, 01 Nov 2004 10:27:18 GMT</lastBuildDate>
  <generator>LiveJournal / LiveJournal.com</generator>
  <image>
    <url>http://www.livejournal.com/userpic/13848838/491061</url>
    <title>KYQ</title>
    <link>http://www.livejournal.com/users/kyq/</link>
    <width>100</width>
    <height>100</height>
  </image>

<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/65305.html</guid>
  <pubDate>Mon, 01 Nov 2004 10:27:18 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/65305.html</link>
  <description>Right, I&apos;ve calmed down quite a bit since the last post, but I still am kicking you-know-who&apos;s ass. Not physically, but I basically talked about it with my Company Sergeant Major aka Boss-man and he&apos;s gonna be doing extra duties this month. Which means more breaks for me. Heheheheh *snort*. No, actually I don&apos;t feel good about it. In fact I feel terrible, I feel like a monster. But it had to be done. If I went easy on him, it&apos;d rob me of credibility, so there. &lt;br /&gt;&lt;br /&gt;MSG Man chapter 8 is probably the shortest chapter I&apos;ve done in a while, at only 24 pages. So sorry if it disappoints you. I did take my time to make sure it&apos;s drawn better though, and it&apos;s a stepping stone to the more exciting developments in the comic, so I hope that makes up for it. I&apos;m planning to use the rest of this week to get the chapter up in the site, and eventually URDrawing (though I have reservations about that).&lt;br /&gt;&lt;br /&gt;Kang, out.</description>
  <comments>http://www.livejournal.com/users/kyq/65305.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/65198.html</guid>
  <pubDate>Sun, 31 Oct 2004 03:54:40 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/65198.html</link>
  <description>Angry doesn&apos;t even describe what I&apos;m feeling at the moment. Allow me to elaborate:&lt;br /&gt;&lt;br /&gt;As you might know, my job in the army is that of an Armskote man, aka He who looks after ze gunz. This is a 24 hour job, so when it&apos;s my tour of duty, I&apos;ve to be in here no matter what, till the end of my duty. Then, one of my assistants comes in and takes over me till the end of his tour of duty. I have 2 assistants, both of whom were store men, and 1 who is going to leave me as he&apos;s being posted out. Wait, wait there&apos;s more...&lt;br /&gt;&lt;br /&gt;My current assistant, who has always been, to put it politely, a fucking slacker, never really had my utmost approval in the first place. But as long as he kept coming for his duty, I didn&apos;t care. Just last week though, despite ALREADY having ASKED him at the start of the month &quot;Which days do you wish to have (to take a day off for)?&quot;, he told me at the last minute that his birthday was on the 29th. Since it&apos;s always nice to celebrate your birthday and have the weekend off too, I OFFERED to exchange weekend duties with him anyway despite me having the power to say no. He declined, saying that he&apos;ll find a way to still enjoy his birthday and come for duty. Fair enough. &lt;br /&gt;&lt;br /&gt;Just 2 days ago, he called me and asked if he could come for duty a bit later, as he feared that he&apos;d be too drunk to come. Rather annoyed, but still I understood it was his birthday and let him come an hour later. What does he do? On Saturday morning, his mother calls telling me he&apos;s too sick to come. I talk to him and true enough he sounds sick. I gave him some verbal lashing and then told him to come tomorrow (sunday, which is today) for duty. Guess what? He didn&apos;t even bother to call me this morning, as according to his mother, he&apos;s in fucking hospital.&lt;br /&gt;&lt;br /&gt;Now it&apos;s his RESPONSIBILITY as an Armskote man to make sure he&apos;s WELL ENOUGH to come for HIS duty. I can say, have NEVER fallen sick and not turned up for duty, neither have I deliberately pulled off any sort of stunt to skive on my duties either. True, he might be so fucking sick he couldn&apos;t crawl out of bed. Tough shit. YOU know you have duty the next day, you should know jolly well not to get so fucking piss drunk, get caught in the rain and have a fucking fever!!! Tell me, am I wrong in being angry? Am I wrong in being MOTHER FUCKINGLY FURIOUS?!?! He&apos;s spoiled my plans, spoiled my weekend and most of all, spoiled my trust for him. &lt;br /&gt;&lt;br /&gt;&lt;br /&gt;He&apos;s going to get it from me. Oh yes he is. &lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;On a lighter note, I&apos;ve finished pencilling MSG Man 8.</description>
  <comments>http://www.livejournal.com/users/kyq/65198.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/64958.html</guid>
  <pubDate>Thu, 28 Oct 2004 14:39:25 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/64958.html</link>
  <description>Nothing like sitting in your favourite Transformer shop, chatting with Transformer fan friends (especially my new one who for now will be known as Jazzbot), blaring Transformer music at max volume. Take THAT stupid kinky women&apos;s wear shops and your crappy bubblegum music! BOOOYAH!!!!</description>
  <comments>http://www.livejournal.com/users/kyq/64958.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/64536.html</guid>
  <pubDate>Tue, 26 Oct 2004 02:46:53 GMT</pubDate>
  <title>Not your daddy&apos;s halloween pic</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/64536.html</link>
  <description>&lt;img src=&quot;http://msgman.kuiki.net/halloween2k4.jpg&quot;&gt;&lt;br /&gt;&lt;br /&gt;Muahahahahaha.</description>
  <comments>http://www.livejournal.com/users/kyq/64536.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/64434.html</guid>
  <pubDate>Sun, 24 Oct 2004 13:17:48 GMT</pubDate>
  <title>Feh..</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/64434.html</link>
  <description>..Don&apos;t wanna stay in camp. Boring. Work to do. Can&apos;t be arsed to do it. &lt;br /&gt;&lt;br /&gt;Yet, don&apos;t wanna go home. Crap to do, like pain-stakingly applying to Unis that probably won&apos;t accept me. Can&apos;t be arsed to do it. &lt;br /&gt;&lt;br /&gt;Yet, I probably do wanna go home. Dunno why really. Getting to talk to her is a slight incentive, even though she&apos;s just a friend. &lt;br /&gt;&lt;br /&gt;Aside from that, once again I&apos;m getting no satisfaction from anything anymore. Well, aside from drawing guys in girls&apos; school uniforms. Yeah, that&apos;s becoming disturbingly fun.</description>
  <comments>http://www.livejournal.com/users/kyq/64434.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/64227.html</guid>
  <pubDate>Fri, 15 Oct 2004 10:11:39 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/64227.html</link>
  <description>An utterly terrible 3 days has almost passed me, filled with stupid people and unreasonable superiors, who all demand the world out from a man who is forced to do a stupid job that is in no way related to my future career whatsoever. Christ I&apos;m tired. And pissed. And stressed. I&apos;m not kidding when I say I could use a hug right now...&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;On the bright side, I&apos;ve started drawing MSG man 8. Progress has been wonderful.</description>
  <comments>http://www.livejournal.com/users/kyq/64227.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/63873.html</guid>
  <pubDate>Mon, 11 Oct 2004 14:46:45 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/63873.html</link>
  <description>&lt;img src=&quot;http://msgman.kuiki.net/ruistyle.jpg&quot;&gt;&lt;br /&gt;&lt;br /&gt;omfg soft colours.</description>
  <comments>http://www.livejournal.com/users/kyq/63873.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/63574.html</guid>
  <pubDate>Mon, 11 Oct 2004 03:20:48 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/63574.html</link>
  <description>Best way to counter feeling-like-crap ness? Start drawing MSG Man. Which I have, yes. MSG Man chapter 8 is being drawn, hopefully to be out by month&apos;s end.</description>
  <comments>http://www.livejournal.com/users/kyq/63574.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/63427.html</guid>
  <pubDate>Wed, 06 Oct 2004 14:30:44 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/63427.html</link>
  <description>I&apos;ve been feeling like crap. Physically and emotionally. Mock me if you will, I don&apos;t care.</description>
  <comments>http://www.livejournal.com/users/kyq/63427.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/63149.html</guid>
  <pubDate>Wed, 29 Sep 2004 00:25:12 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/63149.html</link>
  <description>I don&apos;t know what&apos;s wrong with me lately. I&apos;ve been having such massive mood swings as of late, one moment I feel fine and suddenly I&apos;m either really angry or extremely upset. Mostly upset. Upset about so many things I don&apos;t even know what I&apos;m upset about, but I&apos;m upset. I want to break down and sob, but nothing comes out. I don&apos;t have anyone I&apos;m comfortable enough with to really talk about anything anymore and let&apos;s not even get to my life and hobby. Maybe I need to see a Psychiatrist. I think I&apos;d really need to see one. I just don&apos;t find happiness in anything anymore these days and anything that does manage to make me somewhat happy, the effect is only short-lived. If my life was a game, I really feel like just turning the console off now. If only it were that easy...</description>
  <comments>http://www.livejournal.com/users/kyq/63149.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/62837.html</guid>
  <pubDate>Wed, 22 Sep 2004 04:06:57 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/62837.html</link>
  <description>&lt;a href=&quot;http://msgman.kuiki.net/lsb&quot;&gt;&lt;img src=&quot;http://msgman.kuiki.net/nico.jpg&quot;&gt;&lt;/a&gt;&lt;br /&gt;There isn&apos;t a whole lot yet, but La Signora Boss debuts. (click on image)</description>
  <comments>http://www.livejournal.com/users/kyq/62837.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/62690.html</guid>
  <pubDate>Thu, 16 Sep 2004 19:38:01 GMT</pubDate>
  <title>Coming soon...</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/62690.html</link>
  <description>&lt;img src=&quot;http://msgman.kuiki.net/lasigboss.jpg&quot;&gt;</description>
  <comments>http://www.livejournal.com/users/kyq/62690.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/62398.html</guid>
  <pubDate>Fri, 10 Sep 2004 00:40:40 GMT</pubDate>
  <title>My first critic</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/62398.html</link>
  <description>Got my first searing attack on MSG Man, particularly by a bloke named Uni on the URD board. His post got the crap blighted out of it and deleted, but from what I hear he said MSG Man was &apos;the kind of contribution we don&apos;t need&apos; as it &apos;makes no progress&apos; and blah blah blah... Normally I&apos;d be angry and/or upset, but right now I&apos;m a little tickled and maybe a wee bit ticked. Considering it&apos;s from some bloke who hasn&apos;t contributed anything more than quality whining, I&apos;d just take him as my first critic.&lt;br /&gt;&lt;br /&gt;EDIT: OK I lie. I AM upset. There, happy?</description>
  <comments>http://www.livejournal.com/users/kyq/62398.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/62016.html</guid>
  <pubDate>Fri, 03 Sep 2004 19:00:33 GMT</pubDate>
  <title>グレート山田アッタク！！！</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/62016.html</link>
  <description>Should have done my pictoral tribute to my fave GGXX character LONG ago&lt;br /&gt;&lt;img src=&quot;http://msgman.kuiki.net/may.jpg&quot;&gt;&lt;br /&gt;She is t3h r0x0rz.</description>
  <comments>http://www.livejournal.com/users/kyq/62016.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/61926.html</guid>
  <pubDate>Thu, 02 Sep 2004 17:10:26 GMT</pubDate>
  <title>MSG Man Chapter 7: Highly Addictive</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/61926.html</link>
  <description>It&apos;s done, YAY!&lt;br /&gt;&lt;a href=&quot;http://msgman.kuiki.net/season2.html&quot;&gt;&lt;img src=&quot;http://msgman.kuiki.net/chapter7/msg7cover.jpg&quot;&gt;&lt;br&gt;Read it now!&lt;/a&gt;</description>
  <comments>http://www.livejournal.com/users/kyq/61926.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/61495.html</guid>
  <pubDate>Wed, 01 Sep 2004 10:03:29 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/61495.html</link>
  <description>New purchase&lt;br /&gt;&lt;img src=&quot;http://msgman.kuiki.net/pinky.jpg&quot;&gt;&lt;br /&gt;&lt;img src=&quot;http://msgman.kuiki.net/pinky2.jpg&quot;&gt;&lt;br /&gt;God these things are poisonous.</description>
  <comments>http://www.livejournal.com/users/kyq/61495.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/61265.html</guid>
  <pubDate>Sat, 21 Aug 2004 15:44:39 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/61265.html</link>
  <description>Back from Perth land, saw a few Unis, met the gang again and well...was a little more than a little boring to be honest, aside from doing the things mentioned earlier. It&apos;s back to camp for me tomorrow too, so I&apos;m feeling a little glum. I&apos;d say the usual &quot;I miss you guys&quot; stuff, but I&apos;m gonna be seeing Perth a lot sooner than I think ;).</description>
  <comments>http://www.livejournal.com/users/kyq/61265.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/61129.html</guid>
  <pubDate>Wed, 11 Aug 2004 13:46:39 GMT</pubDate>
  <title>In Perth</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/61129.html</link>
  <description>Must not think about work, must not think about work, must not think about work, must not think about work, must not think about work, must not think about work...&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;Oh and I love not being in Singapore.</description>
  <comments>http://www.livejournal.com/users/kyq/61129.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/60713.html</guid>
  <pubDate>Tue, 03 Aug 2004 14:01:22 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/60713.html</link>
  <description>What a wonderful day, while waiting for my inconsiderate Ragnarok Online twit of a brother to quit hogging the fucking connection, the PC almost dies. Right after that, I get a call that I&apos;m needed at camp NOW. Yay.&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;But you know what? Instead of growling and cursing as I always do, I feel that I&apos;ve been doing too much of that. I&apos;ll instead do this - everytime I update my LJ for now, I&apos;ll say something I LIKE/Love. So here goes...&lt;br /&gt;&lt;br /&gt;&lt;br /&gt;I love my friends, IRL, #rosarian and otherwise.</description>
  <comments>http://www.livejournal.com/users/kyq/60713.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/60562.html</guid>
  <pubDate>Mon, 02 Aug 2004 19:57:19 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/60562.html</link>
  <description>I&apos;m starting to hate these two games a whole lot, namely Ragnarok Online and Utopia. Why? Because I know people WHO ALWAYS HOG THE FUCKING COMUPUTER PLAYING NOTHING BUT THESE GODDAMN GAMES THAT&apos;S WHY!!!! DO THEY THINK THEY&apos;RE THE ONLY FUCKERS WHO NEED TO USE THE PC?!?! I DON&apos;T FUCKING CARE WHO YOU ARE, YOU&apos;D BETTER LEARN TO HAVE A BIT OF FUCKING BASIC COURTESY!!!</description>
  <comments>http://www.livejournal.com/users/kyq/60562.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/60370.html</guid>
  <pubDate>Tue, 27 Jul 2004 10:41:21 GMT</pubDate>
  <title>We are the children of the internet!</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/60370.html</link>
  <description>sad, ain&apos;t it? My bro&apos;s been hogging the modem cos he wants to download the stupid Ragnarok Online client onto his lap top (I&apos;m typing from it), and so I&apos;ve had not much to do. Felt...so...bored.... ah well. (end random babbling)</description>
  <comments>http://www.livejournal.com/users/kyq/60370.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/60044.html</guid>
  <pubDate>Sun, 25 Jul 2004 09:49:42 GMT</pubDate>
  <title>DVD vol. 2</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/60044.html</link>
  <description>Better get it while it&apos;s hot folks!&lt;br /&gt;&lt;img src=&quot;http://msgman.kuiki.net/dvdfour.jpg&quot;&gt;</description>
  <comments>http://www.livejournal.com/users/kyq/60044.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/59782.html</guid>
  <pubDate>Sun, 25 Jul 2004 08:21:36 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/59782.html</link>
  <description>Rui just likes getting comfortable&lt;br /&gt;&lt;img src=&quot;http://msgman.kuiki.net/ruicomf.jpg&quot;&gt;&lt;br /&gt;If this looks familiar it should.</description>
  <comments>http://www.livejournal.com/users/kyq/59782.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/59468.html</guid>
  <pubDate>Sat, 24 Jul 2004 16:57:26 GMT</pubDate>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/59468.html</link>
  <description>Watched Spiderman 2. Pretty..damn...awesome movie...... makes me wish I could an MSG Man movie.</description>
  <comments>http://www.livejournal.com/users/kyq/59468.html</comments>
</item>
<item>
  <guid isPermaLink='true'>http://www.livejournal.com/users/kyq/59286.html</guid>
  <pubDate>Fri, 23 Jul 2004 03:46:18 GMT</pubDate>
  <title>お前はなぜここに？！</title>
  <author>ore_wa@yahoo.com</author>  <link>http://www.livejournal.com/users/kyq/59286.html</link>
  <description>Years after my first comic, Jubilation Sensation, died off, once again 2 of my oldest characters will be &apos;reunited&apos;. &lt;img src=&quot;http://msgman.kuiki.net/siblings.jpg&quot;&gt; A bit of a spoiler, but what the hell, not as if anyone REALLY bothers.</description>
  <comments>http://www.livejournal.com/users/kyq/59286.html</comments>
</item>
</channel>
</rss>
