
use strict;
use Test;
use XML::EasyOBJ;
use FindBin qw/$Bin/;

BEGIN { plan tests => 8 }

my $xml = join('', <DATA>);

ok( my $doc = XML::EasyOBJ->new( -type => 'string', -param => $xml ) );
ok( my @maps = $doc->MAP, 6 );

ok( $doc->MAP(2)->KINGDOM(0)->NAME->getString, 'The Church of the Anhk' );
ok( my @regions = $doc->MAP(2)->KINGDOM(0)->DIPLOMACY->REGION, 2 );
ok( $regions[0]->getString, 'EBRA' );
ok( $regions[1]->getString, 'ULM' );

my $counter = 0;
foreach my $m ( $doc->MAP ) {
	foreach my $k ( $m->KINGDOM ) {
		$counter++;
	}
}
ok( $counter, 43 );

ok( $doc->MAP->KINGDOM(2)->DIPLOMACY->getString, qr/^\s*Vught \(ne\), Wijk \(ne\)\s*WIJK\s*VUGHT\s*$/s );


__END__
<LOTE GAME='91' TURN='6'>

	<MAP AREA='WEST'>
		<KINGDOM ID='ID038' RANK='36' MSI='20.3' NRR='28' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Anfo Nation</NAME>
			<RELIGION>HUMAN PAGAN</RELIGION>
			<RULER>King Leopold</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID015' RANK='8' MSI='44.1' NRR='18' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Grand Duchy of Gistel</NAME>
			<RELIGION>SEEKER</RELIGION>
			<RULER>Grand Duke Trantolus, Overlord of the West</RULER>
			<DIPLOMACY>
				<TEXT>Zrjpe (f)</TEXT>
				<REGION STATUS='F'>ZRJPE</REGION>
			</DIPLOMACY>
			<NOTES>A messenger arrived at the court of the Grand Duke. He had been sent by Doran, Cheif Elder of the Old Church. The message was simple, the Old Church would not stand by while its nations were attacked. The Duke decided to look towards the future of his nation. The messangers ran quickly between Doran and the Duke. The Cheif Elder made his postion clear "Withdraw or suffer a Holy War". The Duke demanded that the Old Church not interfere with his aquisition of the penninsula. After much debate the issue was finally setteled. Gistell forces withdrew from Velsen. The Island Defense Agreement was signed. Chu-Lon, Sonlar, Tearsh,Norta and Gistel signed the IDA. In other news Princes Moira travelled to the region of Zrjpe. She was taken by a young man who happend to be a nobleman of the region. The Grand Duke arrainged a marriage. The Bishop Toben was nearby. He gladly made time to officiate at the ceremony.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID017' RANK='6' MSI='46.6' NRR='6' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Socdom of Hechtel</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>Soclord Magedo</RULER>
			<DIPLOMACY>
				<TEXT>Vught (ne), Wijk (ne)</TEXT>
				<REGION STATUS='NE'>WIJK</REGION>
				<REGION STATUS='NE'>VUGHT</REGION>
			</DIPLOMACY>
			<NOTES>The Soclord left his government in the hands of his Heir Lucretia. He travelled to some of his lands but moved around to quickly to have any effect. While in Vught he received even worse news, Lucretia had taken ill and passed away. Maximus Thrax was snet to gather more slaves to improve the region of Hechtel.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID018' RANK='2' MSI='55.4' NRR='4' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Julich Tribes</NAME>
			<RELIGION>SEEKER</RELIGION>
			<RULER>King Replevin the Clan Lord</RULER>
			<DIPLOMACY>
				<TEXT>Buir (a), Liers (f),</TEXT>
				<REGION STATUS='A'>BUIR</REGION>
				<REGION STATUS='F'>LIERS</REGION>
			</DIPLOMACY>
			<NOTES>Prince Welsen was put in charge of the government. He was worried about the financial state of  the nation that he would one day lead. So, he built a bank in Hainos and a Merchant's Guild in Canay. The King spent his time enjoying his wife and newest son. The various clan leaders were sent to improve relations.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID019' RANK='4' MSI='52.7' NRR='22' NRR_TIE='YES'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>Ancient Empire of the Dragon</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>King Nokolai II, Dreadlord</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

	</MAP>

	<MAP AREA='SOUTH'>
		<KINGDOM ID='ID012' RANK='1' MSI='56.6' NRR='7' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Mighty Empire of Vruda Ungeria</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Wilbur, of the House of Unger, High Tribunal, Grand Executive, Holder of the Axe, Defender of the Faith, Great Chief of the Barbarian Swine Horde</RULER>
			<DIPLOMACY>
				<TEXT>Soltsky (t)</TEXT>
				<REGION STATUS='T'>SOLTSKY</REGION>
			</DIPLOMACY>
			<NOTES>King Wilbur grows ever more paranoid, as threats of war and the Elbar resonate in his royal ears. Accordingly, the KIng of Vruda directs the royal treasurer to divert funds towaards improving the Empies defenses. In particular, a fighter's guild is constructed amongst the barbarian backwoods in Mead Hall, Slotsky. The diplomat from Narva will be there, to make the necessary and proper opening ceremony speeches between draughts of corn ale and honey mead. Wilbur and son Edwin will meanwhile soberly attend to the running of the nation. The Wizard of Robur will ply his new skills, magicking the fields to build reservoirs and better drain the city sewerage.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID013' RANK='14' MSI='34.2' NRR='11' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Mighty Realm of Krosno</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>King Grindall</RULER>
			<DIPLOMACY>
				<TEXT>Dukla (rebels)</TEXT>
			</DIPLOMACY>
			<NOTES>King Elendil had many fine plans. He ordered that some new trails be built to help encourasge the farmers to bring their wares to market. In the process he eat some unclean fruit and took ill. As he passed away with no heir, the country went into turmoil. When it was all over Dukla had broken away from the kingdom, and Grindall had seized power.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID014' RANK='39' MSI='18.1' NRR='32' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Seadragon Rank of Lahti</NAME>
			<RELIGION>MESSENGER</RELIGION>
			<RULER>King Faz-Katu IV, First of the Rank, Crowned Despot of All Seadragons</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID008' RANK='??' MSI='??' NRR='??' NRR_TIE='??'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Kingdom of Torun</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King James</RULER>
			<DIPLOMACY>
				<TEXT>Chipka (c), Lipno (c)</TEXT>
				<REGION STATUS='C'>CHIPKA</REGION>
				<REGION STATUS='C'>LIPNO</REGION>
			</DIPLOMACY>
			<NOTES>King James ordered that the slaves build irrigation ditches and  move rocks, and plant wheat. He then looked at his map. "West of  Torun are a couple of trade centers that I wish to control." So he launched the Merchant War. 5000 swordsmen,1000 well-trained cavalry, 1500 elite swordsmen, and 3000 horsebowman led into battle by King James. King Hawke's forces numbered 7500 swordsmen.   The Merchant War Spring 226- The Toruneese  Horsebowman kill 1000 Cesenian troops. Then the two sides charge. 4000 Cesenians die compared to only 2500 Toruneese. Summer 226-  Arrows kill 500 more Cesenians. The Toruneese are in control of the field. The final charge is masterfully handeled. All 2000 remaining Cesenians die. With the loss of only 500 Toruneese. Aftermath- The Cesenians are now under the control of Torun.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID010' RANK='38' MSI='18.2' NRR='38' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Garden of Klodawa</NAME>
			<RELIGION>MESSENGER</RELIGION>
			<RULER>King Bailey, Prince  of the Free Peoples</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>King Bailey increased his army and his royal family. The Princess Karma was sent to explore the outlying regions. In Stegna he found the Old Church. In Turku he discovered followers of the Blood Cult. In Kalisz he saw people seeking the True Path.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID009' RANK='34' MSI='22.2' NRR='29' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Dell of Decin</NAME>
			<RELIGION>MESSENGER</RELIGION>
			<RULER>King Alfred</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>News from the Dell of Decin. New lands liberated. Princess Destiny getting a fine eduaction.Prince Blada killed in a training exercise. King Alfred announces "The Dell is producing the finest apples and blueberries in the world, along with that new stuffed toy the royal inventors mage for Destiny. I think they call it a "Furrby". Why dont more nations wish to trade with us?" King Alfred gathers his army of  11,500 swordsmen and conquers Plzen. He then aadds 2500 archers and 500 lancers, and conquers Detva.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID011' RANK='??' MSI='??' NRR='??' NRR_TIE='??'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Cesenian League</NAME>
			<RELIGION>HUMAN PAGAN</RELIGION>
			<RULER>King Hawke</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>Destoyed in the Merchant War.</NOTES>
		</KINGDOM>

	</MAP>

	<MAP AREA='NORTH'>
		<KINGDOM ID='ID031' RANK='37' MSI='20.0' NRR='8' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Church of the Anhk</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>High Priest Dathinius</RULER>
			<DIPLOMACY>
				<TEXT>Ebra (ab), Ulm (ab)</TEXT>
				<REGION STATUS='AB'>EBRA</REGION>
				<REGION STATUS='AB'>ULM</REGION>
			</DIPLOMACY>
			<NOTES>Selene begins by declaring Dathinius as heir to the leadership of the Church, the orders missionaires to Ulm to expand the vision of the Anhk family. Then she travelled to Ebra. She was completly taken by the beauty of the area. She finds a very lovely forest that captures her attention. In this place she takes her last breath. An abbey is built on the spot. Dathinius  begins to search the surrounding areas. He sneaks into Narial only to discover pagans. Undauted he goes into Stormwer, but there he finds elves.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID032' RANK='29' MSI='25.1' NRR='27' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Regal Realm of Rostow</NAME>
			<RELIGION>SEEKER</RELIGION>
			<RULER>King Raash, Seeker of the Strange</RULER>
			<DIPLOMACY>
				<TEXT>Aliev (c)</TEXT>
				<REGION STATUS='C'>ALIEV</REGION>
			</DIPLOMACY>
			<NOTES>Prince Jarosh was starting to bet a liitle bored with his royal lifestyle. So he sneaked off to spend some time in more local areas of Delmop. While visiting The Drowned Rat, a local pub, Prince Jarosh was accidentily killed in the middle of a dispute regarding a young brunette. King Raash was not happy at all. " I will make these cities safer for my people." City walls were built for all three cities in the land, and troops were stationed in key areas. Then he diplomacized Aliev.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID041' RANK='28' MSI='25.2' NRR='36' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Naughty Neserea</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>Unknown Ruler</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID006' RANK='41' MSI='14.3' NRR='10' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Peoples Republic of Yzer</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>Unknown Ruler</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID007' RANK='13' MSI='40.4' NRR='5' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Golden Empire of Khatai</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>King Chenchun</RULER>
			<DIPLOMACY>
				<TEXT>Dumaria (fa)</TEXT>
				<REGION STATUS='FA'>DUMARIA</REGION>
			</DIPLOMACY>
			<NOTES>King Chenchun was watching the workers beautify Lauria City. When a young man told him there was exciting news down at the docks. Men had arrived with the head of King Jarimor. This was exciting news for King Chenchun, so he raced to the docks. There he was met by the men. They said they were envoys of Vruda. "We took our army to investigate hereitc rumblings to the north. There we observed what we thought to be rituals of Tarq. As the only good follower of Tarq is a dead follower, we killed them all. Then we rumaged through their belongings and found relics of Elbar. So we came here with the head of King Jarimor to claim the reward. King Jarimor is dead, long live the Old Church."  KIng Chenchun was very happy. "Lets open some corn ale and toast this victory" The men looked at the king and said "show us the way to the ale." The King, knowing that all Vrudanesse sailors always carry plenty of corn ale in ther ships, and never drink from other peoples kegs. He killed them. " FIND ME KING JARIMOR!!!!!!!!"    Duke Pelara looked in the region of Morwen. He found some shady characters, but the killed as a message to keep away from the local underworld, not because they were Tarq spies. His home region of Dumaria, scared by the underworld, distanced themselves from the king. Duke Mulwar found nothing in Mittfel. Duke Krellius was looking in the region of Encora when he found a rather odd item. A helm of strange design. He placed it on his head and was consumed by flame. A local peasent carefully transported the helm to King Chenchun.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID034' RANK='22' MSI='29.0' NRR='30' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Kingdom of Balto</NAME>
			<RELIGION>HUMAN PAGAN</RELIGION>
			<RULER>Unknown Ruler</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID035' RANK='15' MSI='32.2' NRR='31' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Gruzz</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>King Gruzz the XI</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID036' RANK='17' MSI='31.2' NRR='21' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The United Tribes of Diol</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Hector, His Royal Highness, The Emerald King</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>The nation was not active.</NOTES>
		</KINGDOM>

	</MAP>

	<MAP AREA='EAST'>
		<KINGDOM ID='ID033' RANK='18' MSI='30.7' NRR='2' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Spirits of the Pristine Woods</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>Doran, Chief Elder of the Old Church</RULER>
			<DIPLOMACY>
				<TEXT>Sonlar (ca), Sasyk (mn), Lepel (mn), Vruda (ab)</TEXT>
				<REGION STATUS='AB'>VRUDA</REGION>
				<REGION STATUS='MN'>LEPEL</REGION>
				<REGION STATUS='MN'>SASYK</REGION>
				<REGION STATUS='CA'>SONLAR</REGION>
			</DIPLOMACY>
			<NOTES>Enraged by Gistel's invasion of Velsen, Doran set the wheels in motion to bring Velsen back its freedom, by any means necessary. Emissaries flew between the Chief Elder and the Grand Duke. As the deadline for peace approached, it became apparent that the Duke was willling to deal. Tensions throught the lands of Tarsha were high, when at the last moment, Doran announced that an agreement had been reached with the Duke. Gistel would withdraw from Velsen. The nations of Chu-Lon,Tearsh,Sonlar,Norta and Gistel would also sign a mutual defense compact known as the Island Defense Agreement or IDA.    This settled, the Chief Elder had time to concentrate on other matters. He placed a HUGE bounty on the head of King Jarimor of Elbar. Any nation that discovers, reports the location of and aids in the destruction of the fugitive nation will benefit handsomely.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID042' RANK='20' MSI='29.4' NRR='33' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Terrible Twoja</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>Unknown Ruler</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID025' RANK='32' MSI='23.3' NRR='3' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Serene Land of Kas</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Samuel, the Serene One</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>As the workers began to look over the plans for a merchants guild, they realized there was something missing, a bank! So, they built a bank instead. The region of Yutu was explored and happily it was found to be Old Church. Much of King Samuel's time was spent with his royal family. The region of Kas was improved slightly, to compete with Ios. The really important news came from the university where they had learned much about Ironworking. Thus heralding the advance to tech level three.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID044' RANK='31' MSI='23.4' NRR='23' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Glorious Gollel</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>Unknown Ruler</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID026' RANK='33' MSI='22.8' NRR='9' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Duchy of Aragon</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>Duke Rostow II, Patron of the arts</RULER>
			<DIPLOMACY>
				<TEXT>Duru (t), Kelo (t)</TEXT>
				<REGION STATUS='T'>DURU</REGION>
				<REGION STATUS='T'>KELO</REGION>
			</DIPLOMACY>
			<NOTES>A bank was built in Aragon. Prince Derek was sent on a diplomatic mission, as was Count Balck.The region of Bili was improved and Rostow II spent his money on investing in the future of his nation.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID027' RANK='9' MSI='43.6' NRR='17' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Sacrifice Gatherers of Tarq.  (formerly Carnot)</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>Blood Marshal Alstair</RULER>
			<DIPLOMACY>
				<TEXT>Vyborg (ea)</TEXT>
				<REGION STATUS='EA'>VYBORG</REGION>
			</DIPLOMACY>
			<NOTES>The government of Carnot required the Blood Marshal's full attention. He sent Blynder, Prince of the seven hues of Red, along with Dumjon De'mon, Fang Searcher and Red-Robed Seeker to secure the region of Vyborg. The army was increased by the addition of the Red Wizards unit.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID037' RANK='19' MSI='29.4' NRR='15' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Confederacy of Mopti</NAME>
			<RELIGION>SEEKER</RELIGION>
			<RULER>Unknown Ruler</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID028' RANK='23' MSI='28.4' NRR='41' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Red Church</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>Grand Shaman Holtech, The Prophet of Tarq, Keeper of the Sacred Scrolls</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

	</MAP>

	<MAP AREA='ISLANDS'>
		<KINGDOM ID='ID030' RANK='5' MSI='49.8' NRR='19' NRR_TIE='YES'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Kingdom of Faldo</NAME>
			<RELIGION>HUMAN PAGAN</RELIGION>
			<RULER>King Nick Faldo, Monarch of Faldo</RULER>
			<DIPLOMACY>
				<TEXT>Senla (a)</TEXT>
				<REGION STATUS='A'>SENLA</REGION>
			</DIPLOMACY>
			<NOTES>Deciding to learn the secrets of the long forgotten wisdom of the elders, King Nick sat at his desk to study. Leaving orders not to be disturbed unless the NCAA tourney was on the tele, Knig Nick studied diligintley day and night. Ian attempted to bring Senla into the fold by offering discounted memberships...assuming reciprocity would soon follow. Collin, dismayed by the lack of caddies had a thought. " Would it not be better if the Orcs were carying our clubs instead of trying to hit us with clubs?" So he went in search of orcs. He found some, and realized it was a bad idea. Clarke was intrigued by the books the King was reading, who grew annoyed at someone reading over his shoulder, so he gave him his own book. Neither one learned anything usefull.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID029' RANK='30' MSI='23.9' NRR='16' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Seekers of the True Path</NAME>
			<RELIGION>SEEKER</RELIGION>
			<RULER>Prime Seeker Norkell</RULER>
			<DIPLOMACY>
				<TEXT>Temor (ab), Seldon (ab)</TEXT>
				<REGION STATUS='AB'>SELDON</REGION>
				<REGION STATUS='AB'>TEMOR</REGION>
			</DIPLOMACY>
			<NOTES>Studying maagic was all well and good, but at times it was amazxingly boring. Some activity would do the Prme Seeker good. his planned route took him to various places on the island. With joy he saw the seeker people emmbraace the Path. He was able to build religious sites on the island. Once in a while Bishop Toben woul;d send a message to the Prime Seeker about the activities on the Western Front. The people of Zrjpe and Gistel were looking forward to the marriage of the princess Moria. She was to be wed in the region of Zrjpe in the year 226 S.C. Toben was excited as this was one of the few chances he would have to proside over a royal function. He sought out the people of Gistel to assist them in the signing of the Island Defense Pact. Then he let his wonderings take him to the region of Dovai, where he found the Church of  the Anhk. Some young priests were sent to Faldo in hopes that they would consider changing their pagan ways to Seek the True Path.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID003' RANK='40' MSI='14.5' NRR='12' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Glittering Chu-Lon</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>Sir Zembar, Regent for his royal personage</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>Sir Zembar looked after the affairs of the state for his two young charges, the Princess Gwyneth and the Prince Valon. Knowing the pain of the people durinf the 10 year war, and with the loss of two kings, he made it his special purpose to thank the Chu-Lonoins for their support and promises that one day soon, we will be able to live peaceful rich lives. He also spent money to plant flowers at the various battle sites of the war.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID004' RANK='35' MSI='21.8' NRR='40' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Kingdom of Tearsh</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Antipode</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID005' RANK='12' MSI='41.1' NRR='20' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Northern Ice Kingdom of Kal</NAME>
			<RELIGION>SEEKER</RELIGION>
			<RULER>King Kal, the founder</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>Kal was claimed off waivers by John Smith.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID001' RANK='26' MSI='25.4' NRR='35' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Island People of Norta</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Norton, the Great</RULER>
			<DIPLOMACY>
				<TEXT>none</TEXT>
			</DIPLOMACY>
			<NOTES>King Norton built a mages guild  around the shrine to the Old Church that he had built back in 223 S.C. The shrine itself was also expanded. It looks as if the shrine could engulf the abbey that exsists there.  It is noted by many that the shrine generates a healthy feeling in all who spend time there. This could be true, or just a feeling-only the gods know for sure. King Norton prolcaimed "Long live the Old Church"</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID045' RANK='21' MSI='29.1' NRR='22' NRR_TIE='YES'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Majestic Sonlar</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Mixilplyx</RULER>
			<DIPLOMACY>
				<TEXT>Tronchi (nt), Troncha (c)</TEXT>
				<REGION STATUS='C'>TRONCHA</REGION>
				<REGION STATUS='NT'>TRONCHI</REGION>
			</DIPLOMACY>
			<NOTES>King Mixilplyx continued to increase his holdings in the area. He also ordered that defensive fortifications be buiklt through-out his nation. prince Andrew came of age, and was given a nice party.</NOTES>
		</KINGDOM>

	</MAP>

	<MAP AREA='MIDDLE'>
		<KINGDOM ID='ID021' RANK='11' MSI='43.5' NRR='14' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The People who live in Tsin</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Francis, the limp</RULER>
			<DIPLOMACY>
				<TEXT>Pohai (f) Tilos (f)</TEXT>
				<REGION STATUS='F'>POHAI (F) TILOS</REGION>
			</DIPLOMACY>
			<NOTES>King Francis was very worried. "No tax revenue, no tax revenue. How will I pay my military. I must get those tax collectors motivated. I know, I'll kill one of them. That will get the others in line. " Then he called in his favorite Captain. " The treasury lacks the money to pay the troops."   "Well Sire, just make sure they are well fed, and maybe most will wait."  "Oh, thats it, we will sell off the surplus grain, Yes,Yes, ohhhhhh Yes" And thus, a national disaster was avoided. Arthur "two sheds" Jackson was sent to Pohi to increase loyalty in the region. Tim "the enchanter" secured the loyalty of Tilos. In Ye a rather strange thing happened. The leader of the region went completly mad and had to be locked in his bedchambers in his castle for the rest of his life ... chewing on pillows and screaming about the "swine horde of the north". His eldest son Delores (he really wanted a girl) took over the day to day business of Ye for him.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID040' RANK='27' MSI='25.2' NRR='37' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Compact of Kudat</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>King Boris , tamer of the wild boar</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID022' RANK='7' MSI='46.3' NRR='1' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Protectorate of Ios</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>King Gonad, the Venerator</RULER>
			<DIPLOMACY>
				<TEXT>Akti (t)</TEXT>
				<REGION STATUS='T'>AKTI</REGION>
			</DIPLOMACY>
			<NOTES>Prince Ralph was given the responsibility of making sure the tax collectors were doing their jobs correctly. Meanwhile King Gonad ent out to continue gathering slaves. The slaves that would continue to make Ios the most beautiful region in Tarsha. At least to those people in Ios who aren't slaves. Bob, the ally from Ried, went to Akti to discuss matters of state.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID023' RANK='25' MSI='27.6' NRR='34' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The  Vale of Volsk</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>King Moshushu</RULER>
			<DIPLOMACY>
				<TEXT>Velsk (ne), Crkua (ne), Irbit (nt), Serry (fa)</TEXT>
				<REGION STATUS='NT'>IRBIT</REGION>
				<REGION STATUS='FA'>SERRY</REGION>
				<REGION STATUS='NE'>VELSK</REGION>
				<REGION STATUS='NE'>CRKUA</REGION>
			</DIPLOMACY>
			<NOTES>Rothgar, the brother of Moshushu, went out riding with Moshushu's son. They were asttacked by bandits. Rothgar died. Ventos took his place as the heir to the Vale. The ally from Buzau was sent to explore the land. In Athes he found Orcs, so the rest of his plans were cancelled. The ally from Serry was sent out to gather slaves. He was rather taken by the looks of one of the young women in Hulst. As it turned out she did not appreciate his interest. She killed him in his sleep. The region of Serry felt now was a good time to distance themselves from the Vale.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID024' RANK='10' MSI='43.5' NRR='13' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Shmmering Shores of Sasyk</NAME>
			<RELIGION>OLD CHURCH</RELIGION>
			<RULER>King Kalr, the scourge of the seas</RULER>
			<DIPLOMACY>
				<TEXT>Lanchow (ne), Husi (fa), Odesa (nt), Uryu (fa)</TEXT>
				<REGION STATUS='FA'>HUSI</REGION>
				<REGION STATUS='NT'>ODESA</REGION>
				<REGION STATUS='NE'>LANCHOW</REGION>
				<REGION STATUS='FA'>URYU</REGION>
			</DIPLOMACY>
			<NOTES>After years of araiding King Kalr decides to take a break and expand the empire. With this in mind he sets sail for the island of Lanchow, while sending his uncle to Husi and the Tulaneese ally to Uryu and then Amoy to Explore. His trip to Uryu was succesfull, but in Amoy he found Orcs. Before his departure King Kalr orders public projects built in Clan Hold, Odesa, and Norda. He also informs his eldest son Kalr II that he is to become the heir after his great-uncle Kalna retires to become the governor of the City-state of Odesa.</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID043' RANK='16' MSI='32.1' NRR='39' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Council at Melnik</NAME>
			<RELIGION>TARQ</RELIGION>
			<RULER>King Lomax</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID039' RANK='24' MSI='28.1' NRR='42' NRR_TIE='NO'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Sirnan Council</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>Unknown Ruler</RULER>
			<DIPLOMACY>
				<TEXT></TEXT>
			</DIPLOMACY>
			<NOTES>open nation</NOTES>
		</KINGDOM>

		<KINGDOM ID='ID020' RANK='3' MSI='55.2' NRR='19' NRR_TIE='YES'>
			<PLAYER>
				<PLAYER_NAME>John Doe</PLAYER_NAME>
				<EMAIL>john.doe@xyz</EMAIL>
			</PLAYER>
			<NAME>The Wild Kingdom of  Boul</NAME>
			<RELIGION>ANKH</RELIGION>
			<RULER>King Thorkell</RULER>
			<DIPLOMACY>
				<TEXT>Ipin (a)</TEXT>
				<REGION STATUS='A'>IPIN</REGION>
			</DIPLOMACY>
			<NOTES>The duties of the government occupied King Thorkell. Shir Kahn was sent out to gather slaves. Zhearer was sent to explore. We went into Schio only to find Orcs. Undaunted he went into Wuti, and to his great surprise, found more Orcs.</NOTES>
		</KINGDOM>

	</MAP>

</LOTE>








