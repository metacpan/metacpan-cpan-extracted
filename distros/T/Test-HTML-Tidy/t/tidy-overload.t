# $Id: tidy-overload.t,v 1.1 2004/02/26 06:10:00 andy Exp $

use Test::More tests => 3;

BEGIN { use_ok( 'Test::HTML::Tidy' ); }
BEGIN { use_ok( 'HTML::Tidy' ); }

my $html = do { local $/ = undef; <DATA> };

my $tidy = HTML::Tidy->new();
$tidy->ignore( text => [ qr/table.+summary/, qr/unescaped/ ] );

# XXX Need to check it without the ignores, too
html_tidy_ok( $tidy, $html, 'Passed with some ignoring' );

__DATA__
<?xml version="1.0" encoding="iso-8859-1"?>
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US"><head><title>Andy&#39;s Want List</title>
<link type="text/css" rel="stylesheet" href="wants.css" />
</head><body>
<table cellspacing="0" cellpadding="5" border="1"><tr valign="top"><th>CDs</th> <th>Books</th></tr> <tr valign="top"><td width="55%"><p><b>Beastie Boys</b>: Licensed To Ill; Paul's Boutique</p>
<p><b>Black Sabbath</b>: Master Of Reality; Sabbath, Bloody Sabbath</p>
<p><b>Buzzcocks</b>: Buzzcocks</p>
<p><b>George Carlin</b>: Carlin on Comedy; Complaints & Grievances</p>
<p><b>Johnny Cash</b>: Ballads Of The True West; Love/God/Murder; Ride This Train</p>
<p><b>Ray Charles</b>: Genius & Soul: The 50th Anniversary Collection</p>
<p><b>The Corn Sisters</b>: Other Women</p>
<p><b>Deep Purple</b>: Machine Head (reissue)</p>
<p><b>Bruce Dickison</b>: The Chemical Wedding</p>
<p><b>Dixie Chicks</b>: Wide Open Spaces</p>
<p><b>Steve Earle</b>: El Corazon</p>
<p><b>Elton John</b>: Caribou; Don't Shoot Me, I'm Only The Piano Player; Elton John</p>
<p><b>Joe Ely</b>: Live at Antones</p>
<p><b>Alejandro Escovedo</b>: More Miles Than Money</p>
<p><b>Ethyline</b>: Long Gone</p>
<p><b>Ella Fitzgerald</b>: The Songbooks</p>
<p><b>Fleetwood Mac</b>: Then Play On</p>
<p><b>Freakwater</b>: End Time; Feels Like The Third Time; Old Paint; Springtime</p>
<p><b>Furslide</b>: Adventure</p>
<p><b>Bobbie Gentry</b>: American Quilt (compilation)</p>
<p><b>Handsome Family</b>: In The Air</p>
<p><b>Iron Maiden</b>: Iron Maiden; Seventh Son Of A Seventh Son</p>
<p><b>The Kinks</b>: Kinks Kronikles</p>
<p><b>Tom Lehrer</b>: The Remains Of Tom Lehrer</p>
<p><b>John Lennon</b>: Double Fantasy</p>
<p><b>Mermen</b>: The Amazing California Health and Happiness Road Show; The Mermen at the Haunted House</p>
<p><b>Montrose</b>: Montrose</p>
<p><b>The Muffs</b>: Alert Today, Alive Tomorrow; Hamburger</p>
<p><b>Naked Raygun</b>: Jettison; Raygun... Naked Raygun; Understand?</p>
<p><b>Willie Nelson</b>: Classic & Unreleased Collection; Gospel Favorites; Night & Day; Revolutions of Time: 1975-1993; Somewhere Over The Rainbow (reissue)</p>
<p><b>The New Pornographers</b>: Mass Romantic</p>
<p><b>Randy Newman</b>: 12 Songs; Land Of Dreams</p>
<p><b>Tom Petty</b>: Echo; Wildflowers</p>
<p><b>Rainmakers</b>: Balls; Flirting With The Universe; Oslo-Wichita Live; Skin</p>
<p><b>Rolling Stones</b>: It's Only Rock & Roll</p>
<p><b>Roxy Music</b>: Country Life; Roxy Music; Stranded</p>
<p><b>Soundtrack</b>: The Harder They Come; The Muppet Movie</p>
<p><b>Styx</b>: Cornerstone; Pieces of Eight</p>
<p><b>VA: Blues Masters</b>: Vol 1, 8, 10, 12, 13</p>
<p><b>VA: Didn't It Blow Your Mind</b>: Vol 5, 7, 8, 9, 10, 11, 12, 13, 16, 18, 19, 20</p>
<p><b>VA: Have A Nice Day</b>: Vol 23, 24, 25</p>
<p><b>Various Artists</b>: 70s Party Killers; Badlands: A Tribute To Nebraska; Classic Railroad Songs, Vol. 3: Night Train; Farm Aid, Vol 1; Loud, Fast & Out Of Control; Tales From The Rhino: The Rhino Records Story; Testify!</p>
<p><b>Visqueen</b>: King Me</p>
<p><b>Neil Young</b>: Live Rust</p></td> <td width="55%"><p class="hot"><b>Mac OS X Hints</b>, by Rob Griffiths (ORA <a href="isbnlookup.php?isbn=0596004516">0596004516</a>)</p>
<p class="hot"><b>Refactoring</b>, by Martin Fowler (<a href="isbnlookup.php?isbn=0201485672">0201485672</a>)</p>
<p><b>13 Fatal Errors Managers Make</b>, by W. Steven Brown (<a href="isbnlookup.php?isbn=0425096440">0425096440</a>)</p>
<p><b>Ain't Nobody's Business If You Do: The Absurdity of Consensual Crimes in Our Free Country</b>, by Peter McWilliams (<a href="isbnlookup.php?isbn=0931580587">0931580587</a>)</p>
<p><b>AntiPatterns: Refactoring Software, Architectures, and Projects in Crisis</b>, by William J. Brown (<a href="isbnlookup.php?isbn=0471197130">0471197130</a>)</p>
<p><b>Ban The Humorous Bazooka</b>, by Mark Henry Sebell (<a href="isbnlookup.php?isbn=0793141087">0793141087</a>)</p>
<p><b>Building Secure Servers with Linux</b>, by Michael D. Bauer (ORA <a href="isbnlookup.php?isbn=0596002173">0-596-00217-3</a>)</p>
<p><b>The Design of the UNIX Operating System</b>, by Maurice J. Bach (<a href="isbnlookup.php?isbn=0132017997">0132017997</a>)</p>
<p><b>The Leader's Voice</b>, by Boyd Clarke and Ron Crossland (<a href="isbnlookup.php?isbn=1590790162">1590790162</a>)</p>
<p><b>The Little Schemer</b>, by Daniel P. Friedman, Matthias Felleisen (<a href="isbnlookup.php?isbn=0262560992">0262560992</a>)</p>
<p><b>The Medical Detectives</b>, by Berton Roueche (<a href="isbnlookup.php?isbn=0452265886">0452265886</a>)</p>
<p><b>The Museum Of Bad Art</b>, by Tom Stankowicz (<a href="isbnlookup.php?isbn=0836221850">0836221850</a>)</p>
<p><b>Perl for C Programmers</b>, by Steve Oualline (<a href="isbnlookup.php?isbn=073571228X">073571228X</a>)</p>
<p><b>Personal Accountability</b>, by John G. Miller (<a href="isbnlookup.php?isbn=0966583213">0966583213</a>)</p>
<p><b>Psychology of Computer Programming</b>, by Gerald Weinberg (<a href="isbnlookup.php?isbn=0932633420">0932633420</a>)</p>
<p><b>Rain Making: The Professional's Guide to Attracting New Clients</b>, by Ford Harding </p>
<p><b>Riding the Waves of Culture: Understanding Cultural Diversity in Global Business</b>, by Alfons Trompenaars (<a href="isbnlookup.php?isbn=0786311258">0786311258</a>)</p>
<p><b>Running Mac OS X Panther</b>, by James Duncan Davidson (ORA <a href="isbnlookup.php?isbn=0596005008">0-596-00500-8</a>)</p>
<p><b>The Social Life of Information</b>, by John Seely Brown (<a href="isbnlookup.php?isbn=0875847625">0875847625</a>)</p>
<p><b>Social Psychology of Organizing</b>, by Karl Weick (<a href="isbnlookup.php?isbn=0075548089">0075548089</a>)</p>
<p><b>Taking Chances: Lessons in Putting Passion and Creativity Into Your Worklife</b>, by Dale Dauten (<a href="isbnlookup.php?isbn=0937858692">0937858692</a>)</p>
<p><b>TCP/IP Network Administration, 3e</b>, by Craig Hunt (ORA <a href="isbnlookup.php?isbn=0596002971">0-596-00297-1</a>)</p>
<p><b>Too Good To Be True</b>, by Jan Harold Brunvand (<a href="isbnlookup.php?isbn=0393047342">0393047342</a>)</p>
<p><b>The Total Package: The Secret History and Hidden Meanings of Boxes, Bottles, Cans, and Other Persuasive Containers</b>, by Thomas Hine (<a href="isbnlookup.php?isbn=0316365467">0316365467</a>)</p></td></tr> <tr><th colspan="2">Movies to rent</th></tr> <tr><td colspan="2"><p><BR /><font face="Tahoma" size="+1"><b>A</b></font>cross 110th Street,
Adaptation,
American Movie,
Amistad,
Amores Perros,
Annie Hall,
Any Given Sunday,
The Apartment,
<BR />The <font face="Tahoma" size="+1"><b>B</b></font>ad Lieutenant,
Bang The Drum Slowly,
The Basketball Diaries,
Being John Malkovich,
Ben-Hur,
The Big Kahuna,
The Big Sleep,
Black Like Me,
Blow,
Bonnie & Clyde,
Born On The Fourth Of July,
Bound,
Boys Don't Cry,
The Bridge On The River Kwai,
A Bridge Too Far,
<BR /><font face="Tahoma" size="+1"><b>C</b></font>atch-22,
Chicken Run,
Chinatown,
The Conversation,
Cool Hand Luke,
Crumb,
<BR /><font face="Tahoma" size="+1"><b>D</b></font>ark City,
Das Boot,
The Deer Hunter,
The Defiant Ones,
The Dirty Dozen,
Dirty Pretty Things,
Donnie Darko,
<BR /><font face="Tahoma" size="+1"><b>E</b></font>lectra Glide In Blue,
<BR /><font face="Tahoma" size="+1"><b>F</b></font>alling Down,
Fearless,
A Few Good Men,
A Fistful Of Dollars,
Five Easy Pieces,
Flawless,
The Flying Leathernecks,
For A Few Dollars More,
<BR /><font face="Tahoma" size="+1"><b>G</b></font>alaxy Quest,
The Game,
Gladiator,
The Godfather, Part II,
The Good, The Bad and The Ugly,
Gosford Park,
The Grifters,
<BR /><font face="Tahoma" size="+1"><b>H</b></font>ard Eight,
Harold and Maude,
Henry and June,
Hideous Kinky,
Honeysuckle Rose,
Hoop Dreams,
House Of Games,
<BR /><font face="Tahoma" size="+1"><b>I</b></font>ce Age,
Ice Station Zebra,
In The Heat Of The Night,
The Insider,
<BR /><font face="Tahoma" size="+1"><b>K</b></font>-Pax,
Kelly's Heroes,
The Killing Fields,
Kingpin,
The Krays,
<BR /><font face="Tahoma" size="+1"><b>L</b></font>enny,
Lock, Stock & Two Smoking Barrels,
Lone Star,
The Longest Day,
<BR />The <font face="Tahoma" size="+1"><b>M</b></font>an Who Wasn't There,
The Manchurian Candidate,
Manhattan,
McCabe & Mrs. Miller,
Mean Streets,
Midnight Cowboy,
Midnight Express,
Miller's Crossing,
Monster,
Mullholland Drive,
<BR /><font face="Tahoma" size="+1"><b>N</b></font>ashville,
Network,
North By Northwest,
Nothing To Lose,
Nurse Betty,
<BR /><font face="Tahoma" size="+1"><b>O</b></font> Brother Where Art Thou?,
October Sky,
On The Waterfront,
Once Upon a Time In The West,
One Trick Pony,
Onee Upon a Time In America,
The Onion Field,
<BR /><font face="Tahoma" size="+1"><b>P</b></font>aris, Texas,
Plump Fiction,
Priscilla, Queen of the Desert,
<BR />The <font face="Tahoma" size="+1"><b>Q</b></font>uiet Man,
Quills,
Quiz Show,
<BR /><font face="Tahoma" size="+1"><b>R</b></font>aging Bull,
Rated X,
Rear Window,
Rebel Without A Cause,
The Replacement Killers,
Repo Man,
Rififi,
The Right Stuff,
River's Edge,
Run Lola Run,
Running Out Of Time,
<BR />The <font face="Tahoma" size="+1"><b>S</b></font>ands Of Iwo Jima,
The Searchers,
Seven Days In May,
Shaft,
Shakes The Clown,
Shane,
Short Cuts,
Singin' In The Rain,
Smoke Signals,
Soylent Green,
A Streetcar Named Desire,
Sunset Boulevard,
Swimming To Cambodia,
<BR />The <font face="Tahoma" size="+1"><b>T</b></font>ailor of Panama,
The Taking Of Pelham One Two Three,
Thelma & Louise,
Thief,
The Third Man,
To Die For,
Topkapi,
Trainspotting,
Twelve Angry Men,
Twelve O'Clock High,
<BR /><font face="Tahoma" size="+1"><b>U</b></font>nforgiven,
The Usual Suspects,
<BR />The <font face="Tahoma" size="+1"><b>V</b></font>anishing,
Vertigo,
<BR /><font face="Tahoma" size="+1"><b>W</b></font>aking Ned Devine,
Weeds</p></td></tr></table></body></html>
