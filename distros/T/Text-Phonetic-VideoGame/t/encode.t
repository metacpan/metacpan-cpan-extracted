use strict;
use warnings;
use Text::Phonetic::VideoGame;
use Test::More;
use List::MoreUtils qw( uniq );
use Data::Dumper;

my @tests = (
    [
        q{Ninja Gaiden 3},
        q{Ninja Gaiden III},
    ],
    [
        q{Hot Wheels World Race},
        q{Hotwheels world race},
    ],
    [
        q{Clay Fighter Tournament Edition},
        q{clayfighter tournament},
    ],
    [
        q{Clay Fighter},
        q{ClayFighter},
    ],
    [
        q{Allstar Baseball 2001},
        q{all star baseball 2001},
        q{all-star baseball '01},
        q{all-star baseball 01},
        q{all-star baseball 2001},
        q{allstar baseball '01},
        q{allstar baseball 01},
    ],
    [
        q{Backyard Football 09},
        q{Backyard Football 2009},
    ],
    [
        q{Madden 06},
        q{Madden 2006},
        q{madden '06},
        q{madden nfl 06},
        q{madden nfl 2006},
    ],
    [
        q{Pirates of the Caribbean At World's End},
        q{Pirates of the Caribbean: At World's End},
        q{Pirates of the Caribbean: At Worlds End},
    ],
    [
        q{Bart's Nightmare},
        q{Barts Nightmare},
    ],
    [
        q{The Hulk},
        q{hulk},
    ],
    [
        q{Chip & Dale 2},
        q{Chip and Dale Rescue Rangers 2},
    ],
    [
        q{Mario Kart DS},
        q{mariokart ds},
    ],
    [
        q{spider-man battle},
        q{spiderman battle},
    ],
    [
        q{Wii Fit},
        q{wiifit},
    ],
    [
        q{Wario World},
        q{warioworld},
    ],
    [
        q{Sega Smash Pack},
        q{Sega Smashpack},
    ],
    [
        q{Mega Man X6},
        q{Megaman X6},
    ],
    [
        q{Final Fantasy VII},
        q{final fantasy 7},
    ],
    [
        q{New York Times Crosswords},
        q{ny times crossword},
    ],
    [
        q{f zero gx},
        q{f-zero gx},
        q{fzero gx},
    ],
    [
        q{Blinx Time Sweeper},
        q{blinx the time sweeper},
        q{blinx: time sweeper},
    ],
    [
        q{King's Field},
        q{kings field},
    ],
    [
        q{Mr. Driller 2},
        q{mr driller 2},
    ],
    [
        q{Starfox Adventures},
        q{star fox adventures},
    ],
    [
        q{Starfox 64},
        q{star fox 64},
    ],
    [
        q{Pacman World 2},
        q{pac man world 2},
        q{pac-man world 2},
    ],
    [
        q{Wrestlemania 19},
        q{Wrestlemania xix},
    ],
    [
        q{McDonald Treasure Adventure},
        q{McDonald's Treasure Adventure},
        q{McDonalds Treasure Adventure},
    ],
    [
        q{Medal of Honor - Infiltrator},
        q{Medal of Honor Infiltrator},
        q{Medal of Honor: Infiltrator },
    ],
    [
        q{final fantasy 1 & 2},
        q{final fantasy 1 and 2},
        q{final fantasy I & II},
        q{final fantasy I and II},
    ],
    [
        q{Suikoden 3},
        q{suikoden iii},
    ],
    [
        q{Tiger Woods 2004},
        q{tiger woods golf 2004},
        q{tigerwoods 2004},
    ],
    [
        q{Lord of the Rings - Two Towers},
        q{Lord of the Rings Two Towers},
        q{Lord of the Rings the Two Towers},
        q{Lord of the Rings: The Two Towers},
        q{Lord of the Rings: Two Towers},
    ],
    [
        q{Tom and Jerry},
        q{tom & jerry},
    ],
    [
        q{bass master},
        q{bassmaster},
        q{bassmasters},
    ],
    [
        q{Toy Story 2},
        q{toystory 2},
    ],
    [
        q{FF Anthology},
        q{Final Fantasy Anthology},
    ],
    [
        q{Black Nintendo DS Lite},
        q{black ds lite},
    ],
    [
        q{Comix Zone},
        q{comic zone},
    ],
    [
        q{Aladdin},
        q{aladin},
        q{alladin},
    ],
    [
        q{SSX Tricky},
        q{ssx-tricky},
    ],
    [
        q{Kingdom Hearts Chain of Memories},
        q{kingdom hearts: chain of memories},
    ],
    [
        q{Mortal Combat 2},
        q{Mortal Combat II},
        q{Mortal Kombat 2},
        q{Mortal Kombat II},
    ],
    [
        q{Zelda Collector Edition},
        q{Zelda Collectors Edition},
        q{zelda collector's edition},
    ],
    [
        q{MechAssault},
        q{mech assault},
    ],
    [
        q{Yoshi's Story},
        q{yoshi story},
        q{yoshis story},
    ],
    [
        q{Grand Theft Auto Vice City},
        q{gta vice city},
    ],
    [
        q{Ultra mix 3},
        q{Ultramix 3},
    ],
    [
        q{NBA Street V3},
        q{NBA Street Vol 3},
    ],
    [
        q{Hot Wheels Stunt Track Driver},
        q{Hotwheels stunt track driver},
    ],
    [
        q{Final Fantasy III},
        q{final fantasy 3},
    ],
    [
        q{SUPER BATTLE TANK 2},
        q{Super Battletank 2},
    ],
    [
        q{Halo 3 LE},
        q{Halo 3 Limited},
        q{Halo 3 Limited Edition},
    ],
    [
        q{Kirby Air Ride},
        q{Kirby Airride},
    ],
    [
        q{SanAndreas},
        q{san andreas},
    ],
    [
        q{Guitar Hero 3},
        q{Guitar Hero iii},
    ],
    [
        q{Burger Time Deluxe},
        q{BurgerTime Deluxe},
    ],
    [
        q{Clubhouse Games},
        q{club house games},
    ],
    [
        q{6-PAK},
        q{6-pack},
    ],
    [
        q{Dance Dance Revolution Max 2},
        q{ddr max 2},
    ],
    [
        q{Grand Theft Auto Collector's},
        q{Grand Theft Auto Collectors},
        q{Grand Theft Auto Collectors Edition},
    ],
    [
        q{blitz '01},
        q{blitz 01},
        q{blitz 2001},
    ],
    [
        q{Pokemon Leaf Green},
        q{Pokemon LeafGreen},
    ],
    [
        q{Tom and Jerry In House Trap},
        q{tom & jerry in house trap},
    ],
    [
        q{Scooby Doo The Movie},
        q{Scooby-Doo The Movie},
    ],
    [
        q{Spiderman},
        q{spider man},
        q{spider-man},
    ],
    [
        q{Tomb Raider 3},
        q{Tomb Raider III},
    ],
    [
        q{final fantasy 6},
        q{final fantasy vi},
    ],
    [
        q{Half-Life 2},
        q{half life 2},
    ],
    [
        q{Mr. Do!},
        q{mr do},
        q{mr. do},
    ],
    [
        q{Ninja Gaiden 2},
        q{Ninja Gaiden II},
    ],
    [
        q{Lord of the Rings - Third Age},
        q{Lord of the Rings Third Age},
        q{Lord of the Rings: The Third Age},
        q{Lord of the Rings: Third Age},
    ],
    [
        q{Project Gotham Racing},
        q{project gothem racing},
    ],
    [
        q{gotham racing},
        q{gothom racing},
    ],
    [
        q{light speed rescue},
        q{lightspeed rescue},
    ],
    [
        q{BrainDead 13},
        q{brain dead 13},
    ],
    [
        q{Break Thru},
        q{BreakThru},
    ],
    [
        q{amped 2},
        q{amped ii},
    ],
    [
        q{Breath of Fire IV},
        q{breath of fire 4},
        q{breathe of fire 4},
        q{breathe of fire iv},
    ],
    [
        q{Cruis'n USA},
        q{Cruisn' USA},
        q{cruisin usa},
        q{cruisn usa},
        q{crusin u.s.a.},
        q{crusin usa},
    ],
    [
        q{Nightfire},
        q{night fire},
    ],
    [
        q{Star Wars Bounty Hunter},
        q{Star Wars: Bounty Hunter},
    ],
    [
        q{Time Shift},
        q{TimeShift},
    ],
    [
        q{Ratchet Deadlock},
        q{Ratchet: Deadlock},
    ],
    [
        q{Disney Sport Snowboarding },
        q{Disney Sports Snowboarding},
        q{Disney's Sports Snowboarding },
    ],
    [
        q{wolfenstein},
        q{wolfenstien},
    ],
    [
        q{Tetris & Dr Mario},
        q{Tetris & Dr. Mario},
        q{Tetris and Dr Mario },
        q{Tetris and Dr. Mario},
    ],
    [
        q{Dance Dance Revolution Ultramix 2},
        q{ddr ultramix 2},
    ],
    [
        q{Ultra mix 2},
        q{Ultramix 2},
    ],
    [
        q{Madden 2007},
        q{madden '07},
        q{madden 07},
        q{madden nfl 07},
        q{madden nfl 2007},
    ],
    [
        q{Half-Life},
        q{half life},
    ],
    [
        q{Bomberman Hero},
        q{bomber man hero},
    ],
    [
        q{Mario Kart Wii},
        q{mariokart wii},
    ],
    [
        q{Fantastic 4},
        q{Fantastic Four},
    ],
    [
        q{Donkey Kong Country 2},
        q{Donkey Kong Kountry 2},
        q{donkeykong country 2},
    ],
    [
        q{Super Mario Bros & Duck Hunt & World Class Track Meet},
        q{Super Mario Bros Duck Hunt World Class Track Meet},
        q{Super Mario Bros and Duck Hunt and World Class Track Meet},
    ],
    [
        q{Blitz the League},
        q{Blitz: The League},
    ],
    [
        q{Brothers in Arms Earned in Blood},
        q{Brothers in Arms: Earned in Blood},
    ],
    [
        q{Roller Coaster Tycoon},
        q{Rollercoaster Tycoon},
    ],
    [
        q{Super Cross 2000},
        q{super cross '00},
        q{super cross 00},
        q{supercross '00},
        q{supercross 00},
        q{supercross 2000},
    ],
    [
        q{Super Smash Bros Brawl},
        q{Super Smash Bros. Brawl},
        q{Super Smash Brothers Brawl},
        q{SuperSmash Bros Brawl},
    ],
    [
        q{Harvest Moon - Save the Homeland},
        q{Harvest Moon Save the Homeland},
        q{Harvest Moon: Save the Homeland},
    ],
    [
        q{Project Snowblind},
        q{project snow blind},
    ],
    [
        q{Hot Wheels Stunt Track Challenge},
        q{Hotwheels stunt track challenge},
    ],
    [
        q{Astro Boy Omega Factor},
        q{astroboy omega factor},
    ],
    [
        q{Ms Pac Man},
        q{Ms. Pac Man},
        q{Ms. Pacman},
        q{ms pac-man},
        q{ms pacman},
        q{ms. pac-man},
    ],
    [
        q{Magical Starsign},
        q{magical star sign},
    ],
    [
        q{Earthbound},
        q{earth bound},
    ],
    [
        q{World Cup 98},
        q{world cup '98},
        q{world cup 1998},
    ],
    [
        q{Pacman World 3},
        q{pac man world 3},
        q{pac-man world 3},
    ],
    [
        q{Fear Effect 2},
        q{Fear Effect ii},
    ],
    [
        q{Torino 2006},
        q{torino 06},
    ],
    [
        q{Kane & Lynch},
        q{Kane and Lynch},
    ],
    [
        q{Turok Evolution},
        q{turok: evolution},
    ],
    [
        q{JoJo Bizarre Adventure},
        q{Jojo's Bizarre Adventure},
    ],
    [
        q{Star Wars Battlefront},
        q{Star wars Battle front},
        q{star wars: battlefront},
    ],
    [
        q{Mega Man},
        q{megaman},
    ],
    [
        q{Contra 4},
        q{contra iv},
    ],
    [
        q{DinoThunder},
        q{dino thunder},
    ],
    [
        q{Ape Escape 2},
        q{ape escape ii},
    ],
    [
        q{FIFA 2002 Soccer},
        q{fifa soccer 2002},
    ],
    [
        q{Need for Speed Pro Street},
        q{Need for Speed Prostreet},
        q{Need for Speed: Prostreet },
    ],
    [
        q{Dance Dance Revolution Mario Mix},
        q{ddr mario mix},
    ],
    [
        q{FIFA 2008},
        q{fifa 08},
    ],
    [
        q{Yoshi's Island DS},
        q{yoshis island ds},
    ],
    [
        q{Agent Under Fire},
        q{agent underfire},
    ],
    [
        q{Crash Nitro Cart},
        q{crash nitro kart},
        q{crash nitro-cart},
        q{crash nitro-kart},
    ],
    [
        q{Stuntman},
        q{stunt man},
    ],
    [
        q{Bart vs the Juggernauts },
        q{Bart vs. the Juggernauts},
    ],
    [
        q{Castlevania 2 Simon's Quest},
        q{Castlevania 2 Simons Quest},
        q{Castlevania II Simon's Quest},
    ],
    [
        q{castlevania 2},
        q{castlevania II},
    ],
    [
        q{Simons Quest},
        q{simon's quest},
    ],
    [
        q{Fuzion Frenzy},
        q{fusion frenzy},
    ],
    [
        q{Castlevania Curse of Darkness},
        q{Castlevania Curse of the Darkness},
    ],
    [
        q{Mario Kart 64},
        q{mariokart 64},
        q{mariokart64},
    ],
    [
        q{Elder Scrolls 4 Oblivion},
        q{Elder Scrolls 4: Oblivion},
        q{Elder Scrolls IV Oblivion},
        q{Elder Scrolls IV: Oblivion},
    ],
    [
        q{Sly 3},
        q{Sly3},
    ],
    [
        q{Michael Jackson Moonwalker},
        q{Michael Jackson's Moonwalker},
    ],
    [
        q{Shadow Gate},
        q{Shadowgate},
    ],
    [
        q{Brain Age},
        q{Brainage},
    ],
    [
        q{Blitz 2003 Football},
        q{blitz 2003},
    ],
    [
        q{FIFA 64 Soccer},
        q{fifa 64},
        q{fifa soccer 64},
    ],
    [
        q{Hot Wheels Velocity X},
        q{Hotwheels Velocity X},
    ],
    [
        q{Fighters Destiny 2},
        q{fighter's destiny 2},
    ],
    [
        q{After Burner II},
        q{After burner 2},
        q{Afterburner 2},
        q{Afterburner ii},
    ],
    [
        q{eddy jawbreakers},
        q{eddy: jawbreakers},
    ],
    [
        q{Need for Speed Porsche Unleashed},
        q{Need for Speed: Porsche Unleashed},
    ],
    [
        q{wario ware},
        q{warioware},
    ],
    [
        q{shadow of empire},
        q{shadow of the empire},
        q{shadows of the empire},
    ],
    [
        q{Final Fantasy XII Collector's Edition},
        q{final fantasy 12 collector},
    ],
    [
        q{hang time},
        q{hangtime},
    ],
    [
        q{Teenage Mutant Ninja Turtles 2 Back from the Sewers},
        q{Teenage Mutant Ninja Turtles II Back from the Sewers},
    ],
    [
        q{NASCAR 2007},
        q{nascar 07},
    ],
    [
        q{ren & stimpy Fire Dogs},
        q{ren and stimpy Fire Dogs},
    ],
    [
        q{Trials & Tribulations},
        q{Trials and Tribulations},
    ],
    [
        q{Metriod Fusion},
        q{Metroid Fusion},
    ],
    [
        q{NEED FOR SPEED UNDER GROUND},
        q{Need for Speed - Underground },
        q{Need for Speed Underground},
        q{need for speed: underground},
    ],
    [
        q{Jak 3},
        q{jak iii},
        q{jax 3},
    ],
    [
        q{Soduku Fever},
        q{Sudoku Fever},
    ],
    [
        q{Hitman Contracts},
        q{Hitman: Contracts },
    ],
    [
        q{Cel Damage},
        q{cell damage},
    ],
    [
        q{wrath of cortex},
        q{wrath of the cortex},
    ],
    [
        q{P.N. 03},
        q{p.n.03},
    ],
    [
        q{Resident Evil Zero},
        q{resident evil 0},
        q{resident evil: zero},
    ],
    [
        q{Cruis'n Velocity},
        q{Cruisn Velocity},
        q{Cruisn' Velocity},
    ],
    [
        q{Sponge Bob Square Pants Bikini},
        q{Sponge Bob SquarePants bikini},
        q{SpongeBob Square Pants bikini},
        q{SpongeBob SquarePants bikini},
    ],
    [
        q{Excitebike},
        q{excite bike},
    ],
    [
        q{Punch-Out},
        q{punch out},
        q{punchout},
    ],
    [
        q{Dead or Alive Beach Volleyball},
        q{doa beach volleyball},
    ],
    [
        q{azurick},
        q{azurik},
    ],
    [
        q{Spyro the Dragon},
        q{spyro: the dragon},
    ],
    [
        q{Ghosts 'n Goblins},
        q{Ghosts n' goblins},
    ],
    [
        q{House of the Dead 3},
        q{house of dead 3},
        q{house of the dead iii},
    ],
    [
        q{double dragon 5},
        q{double dragon v},
    ],
    [
        q{shell shock nam},
        q{shell shock vietnam},
        q{shellshock nam},
        q{shellshock vietnam},
    ],
    [
        q{Sword of Vermilion},
        q{Sword of Vermillion},
    ],
    [
        q{Final Fantasy Tactics},
        q{ff tactics},
    ],
    [
        q{EARTH WORM JIM 2},
        q{Earthworm Jim 2},
    ],
    [
        q{Pac-In-Time},
        q{pac in time},
    ],
    [
        q{Monsters Inc Scream Team},
        q{Monsters Inc. Scream Team},
        q{Monsters, Inc Scream Team},
        q{Monsters, Inc. Scream Team},
    ],
    [
        q{A Bug's Life},
        q{Bug's Life},
        q{bugs life},
    ],
    [
        q{Final Fantasy II},
        q{final fantasy 2},
    ],
    [
        q{A Hero's Tail},
        q{A Hero's Tale},
        q{hero's tale},
        q{heros tale},
    ],
    [
        q{Spyro A Heros Tail},
        q{Spyro a Hero's Tail},
        q{Spyro: Hero's Tail},
    ],
    [
        q{Motocross Maniacs},
        q{Motorcross Maniacs},
    ],
    [
        q{Zack & Wiki},
        q{Zack and Wiki},
    ],
    [
        q{Hitman Blood Money},
        q{Hitman: Blood Money},
    ],
    [
        q{TMNT Tournament},
        q{Teenage Mutant Ninja Turtles Tournament},
    ],
    [
        q{Swords and Serpents},
        q{swords & serpents},
    ],
    [
        q{Street Fighter 2 Special},
        q{Street Fighter II Special},
    ],
    [
        q{FIFA 2005},
        q{fifa 05},
        q{fifa soccer 2005},
    ],
    [
        q{Smart Ball},
        q{smartball},
    ],
    [
        q{NEED FOR SPEED UNDER GROUND 2},
        q{Need for Speed - Underground 2},
        q{Need for Speed Underground 2},
        q{Need for Speed Underground ii},
        q{need for speed: underground 2},
    ],
    [
        q{Splinter Cell Double Agent},
        q{Splinter Cell: Double Agent},
    ],
    [
        q{X-men Legends 2},
        q{xmen legends 2},
    ],
    [
        q{Jak and Daxter},
        q{jax and daxter},
    ],
    [
        q{Monsters Inc},
        q{Monsters, Inc},
    ],
    [
        q{Alien vs Predator Extinction},
        q{Alien vs. Predator Extinction},
        q{Aliens vs Predator Extinction},
        q{Aliens vs. Predator Extinction},
    ],
    [
        q{SUPER BATTLE TANK},
        q{Super Battletank},
    ],
    [
        q{X-men Legends},
        q{xmen legends},
    ],
    [
        q{Kingdom Hearts 2},
        q{KingdomHearts 2},
        q{kingdom hearts ii},
    ],
    [
        q{f zero gp},
        q{f-zero gp},
        q{fzero gp},
    ],
    [
        q{Red Steel},
        q{Redsteel},
    ],
    [
        q{Pacman Fever},
        q{pac-man fever},
    ],
    [
        q{Mayan Adventure},
        q{The Mayan Adventure},
    ],
    [
        q{Tomb Raider Last Revelation},
        q{Tomb Raider The Last Revelation },
    ],
    [
        q{Phoenix Wright - Ace Attorney},
        q{Phoenix Wright Ace Attorney},
        q{Phoenix Wright: Ace Attorney},
    ],
    [
        q{Super Mario Bros 2},
        q{super mario bros. 2},
        q{super mario brothers 2},
    ],
    [
        q{Pokemon Fire Red},
        q{pokemon firered},
    ],
    [
        q{Scooby Doo Monsters Unleashed},
        q{Scooby-Doo Monsters Unleashed},
    ],
    [
        q{Saint's Row 2},
        q{Saints Row 2},
    ],
    [
        q{Final Fantasy 8},
        q{final fantasy viii},
    ],
    [
        q{Starsky & Hutch},
        q{Starsky and Hutch},
    ],
    [
        q{Star Tropics},
        q{startropics},
    ],
    [
        q{Boom Bots},
        q{Boombots},
    ],
    [
        q{Bart vs the Space Mutants},
        q{Bart vs. the Space Mutants},
    ],
    [
        q{Silent Hill Homecoming},
        q{Silent Hill: Homecoming},
    ],
    [
        q{Tiger Woods 2005},
        q{tiger woods 05},
    ],
    [
        q{Tiger Woods PGA Tour 2005},
        q{tiger woods pga tour 05},
    ],
    [
        q{Final Fantasy X 10},
        q{final fantasy 10},
        q{final fantasy X},
    ],
    [
        q{Genghis Khan ii},
        q{genghis khan 2},
    ],
    [
        q{GTA 4},
        q{Grand Theft Auto 4},
        q{Grand Theft Auto IV},
    ],
    [
        q{Assasins Creed},
        q{Assassin's Creed},
        q{Assassins Creed},
    ],
    [
        q{Crash of the Titans},
        q{Crash: of the Titans},
    ],
    [
        q{FF Chronicles},
        q{Final Fantasy Chronicles},
    ],
    [
        q{Super Smash TV},
        q{super smash T.V.},
    ],
    [
        q{thunder strike},
        q{thunderstrike},
    ],
    [
        q{Hot Wheels All Out},
        q{Hotwheels all out},
    ],
    [
        q{FIFA 2007},
        q{fifa '07},
        q{fifa 07},
    ],
    [
        q{Mortal Combat 3},
        q{Mortal Combat III},
        q{Mortal Kombat 3},
        q{Mortal Kombat III},
    ],
    [
        q{Halo 2},
        q{halo2},
    ],
    [
        q{Teenage Mutant Ninja Turtles 3 radical rescue},
        q{Teenage Mutant Ninja Turtles III Radical Rescue},
    ],
    [
        q{Dead or Alive 2},
        q{doa 2},
    ],
    [
        q{baldur's gate},
        q{baldurs gate},
    ],
    [
        q{Eye Toy Groove},
        q{eyetoy groove},
    ],
    [
        q{The Goonies 2},
        q{goonies 2},
        q{goonies II},
    ],
    [
        q{Spyro Enter the Dragonfly},
        q{spyro: Enter the Dragonfly},
        q{spyro: Enter the Dragon fly},
    ],
    [
        q{NCAA Football 2007},
        q{ncaa football 07},
    ],
    [
        q{The Ren and Stimpy Show Time Warp},
        q{ren & stimpy Time Warp},
        q{ren and stimpy Time Warp},
    ],
    [
        q{Pirates if the Caribbean},
        q{Pirates of the Caribbean},
    ],
    [
        q{Guitar Hero 2},
        q{Guitar Hero II},
    ],
    [
        q{Sponge Bob Square Pants Volume 2},
        q{Sponge Bob SquarePants Volume 2},
        q{SpongeBob Square Pants Volume 2},
        q{SpongeBob SquarePants Volume 2},
    ],
    [
        q{Tony Hawk Underground},
        q{Tony Hawks Underground},
        q{tony hawk's underground},
    ],
    [
        q{Earth worm Jim },
        q{Earthworm Jim},
    ],
    [
        q{Army Men Air Combat},
        q{army men - air combat},
        q{army men: air combat},
    ],
    [
        q{T2 The Arcade Game},
        q{t2 arcade game},
    ],
    [
        q{Sponge Bob Square Pants Yellow Avenger},
        q{Sponge Bob SquarePants yellow avenger},
        q{SpongeBob Square Pants yellow avenger},
        q{SpongeBob SquarePants yellow avenger},
    ],
    [
        q{PGR 3},
        q{Project Gotham Racing 3},
    ],
    [
        q{Far Cry Instincts},
        q{farcry instincts},
    ],
    [
        q{South Park},
        q{southpark},
    ],
    [
        q{Tony Hawk Project 8},
        q{tony hawk's project 8},
        q{tony hawks project 8},
    ],
    [
        q{Aerofighters Assault},
        q{aero fighters assault},
    ],
    [
        q{Harry Potter - Quidditch},
        q{Harry Potter: Quidditch},
    ],
    [
        q{NBA Live 2006},
        q{nba live 06},
    ],
    [
        q{zelda 2},
        q{zelda ii},
    ],
    [
        q{Need for Speed 2 - Hot Pursuit},
        q{Need for Speed 2 Hot Pursuit},
        q{need for speed: hot pursuit 2},
    ],
    [
        q{MLB 2006},
        q{mlb 06},
    ],
    [
        q{WWF Smackdown},
        q{wwe smackdown},
    ],
    [
        q{Pitfall Lost Expeditions},
        q{Pitfall: Lost Expeditions},
    ],
    [
        q{Wars Complete Saga },
        q{Wars The Complete Saga },
    ],
    [
        q{Pokemon Stadium},
        q{pokeman stadium},
    ],
    [
        q{Kingdom Hearts},
        q{KingdomHearts},
    ],
    [
        q{The Sims 2 Pets},
        q{sims 2 pets},
    ],
    [
        q{Allstar Baseball 2003},
        q{all star baseball 2003},
        q{all-star baseball 2003},
    ],
    [
        q{Super Punch Out},
        q{super punch-out},
        q{super punchout},
    ],
    [
        q{Golden Sun The Lost Age},
        q{golden sun lost age},
        q{golden sun: lost age},
        q{golden sun: the lost age},
    ],
    [
        q{NASCAR 2000},
        q{nascar '00},
        q{nascar 00},
    ],
    [
        q{ESPN Football 2K5},
        q{ESPN Football 2005},
    ],
    [
        q{Warioware Twisted},
        q{wario ware twisted},
    ],
    [
        q{Soul Calibur 3},
        q{soul calibur iii},
        q{soulcalibur 3},
        q{soulcalibur iii},
    ],
    [
        q{Xbox 360 Arcade},
        q{xbox360 arcade},
    ],
    [
        q{Medal of Honor - Underground},
        q{Medal of Honor Underground},
        q{Medal of Honor: Underground},
    ],
    [
        q{Resident Evil The Umbrella Chronicles},
        q{Resident Evil Umbrella Chronicles},
        q{Resident Evil: Umbrella Chronicles},
    ],
    [
        q{Mega Man X5},
        q{Megaman X5},
    ],
    [
        q{SimCity 2000},
        q{sim city 2000},
    ],
    [
        q{R.C. Pro-Am},
        q{R.C. ProAm},
        q{RC Pro AM},
        q{RC Pro-AM},
        q{RC ProAM},
    ],
    [
        q{Civilization 2},
        q{Civilization II},
    ],
    [
        q{Fzero X},
        q{f zero x},
        q{f-zero x},
    ],
    [
        q{Mario & Sonic at the Olympic},
        q{Mario & Sonic olympic},
        q{Mario and Sonic Olympic Games},
        q{Mario and Sonic olympic},
        q{mario & sonic olympics},
    ],
    [
        q{Harvest Moon A Wonderful Life},
        q{harvest moon - wonderful life},
        q{harvest moon wonderful life},
        q{harvest moon: a wonderful life},
        q{harvest moon: wonderful life},
    ],
    [
        q{Namco Museum  4},
        q{Namco Museum Volume 4},
    ],
    [
        q{Spartan Total Warrior},
        q{spartan - total warrior},
        q{spartan: total warrior},
    ],
    [
        q{Mega Man Zero 2},
        q{megaman zero 2},
    ],
    [
        q{Cruis'n Exotica},
        q{Cruisn' Exotica},
        q{cruisn exotica},
        q{crusin exotica},
    ],
    [
        q{Mario Kart Super Circuit},
        q{mario cart super circuit},
        q{mario cart: super circuit},
        q{mario kart - super circuit},
        q{mario kart: super circuit},
    ],
    [
        q{Disney Sport Skateboarding },
        q{Disney Sports Skateboarding},
    ],
    [
        q{disney skateboarding},
        q{disney's skateboarding},
    ],
    [
        q{F-zero},
        q{f zero},
        q{fzero},
    ],
    [
        q{Saint's Row},
        q{Saints Row},
    ],
    [
        q{Breath of Fire 3},
        q{breath of fire iii},
        q{breathe of fire 3},
        q{breathe of fire iii},
    ],
    [
        q{King's Quest V},
        q{Kings Quest V},
    ],
    [
        q{Blitz 2002 Football},
        q{blitz 2002},
    ],
    [
        q{Cruis'n World},
        q{cruisin world},
        q{cruisn world},
        q{cruisn' world},
        q{crusin world},
    ],
    [
        q{Battletanks},
        q{Battletanx},
        q{battle tanks},
        q{battle tanx},
    ],
    [
        q{Excitebike 64},
        q{excite bike 64},
    ],
    [
        q{NCAA Football 09},
        q{NCAA Football 2009},
    ],
    [
        q{Bass Hunters},
        q{bass hunter},
    ],
    [
        q{NBA Jam 2000},
        q{nba jam '00},
        q{nba jam 00},
    ],
    [
        q{Pilot Wings},
        q{pilotwings},
    ],
    [
        q{Gun Metal},
        q{gun metal},
        q{gunmetal},
    ],
    [
        q{Alundra 2},
        q{alundra ii},
    ],
    [
        q{MX vs. ATV Unleashed},
        q{mx vs atv unleashed},
    ],
    [
        q{Triple Play 2000},
        q{triple play '00},
        q{triple play 00},
        q{tripple play 2000},
    ],
    [
        q{Prince of Persia Warrior Within},
        q{Prince of Persia the Warrior Within},
        q{Prince of Persia: Warrior Within},
    ],
    [
        q{Mike Tyson's Punch Out},
        q{Mike Tyson's Punch-Out},
        q{Mike Tysons Punch Out},
        q{Mike Tysons Punch-Out},
        q{mike tyson punch out},
        q{mike tyson punch-out},
        q{mike tyson punchout},
    ],
    [
        q{The Typing of the Dead},
        q{Typing of the Dead},
    ],
    [
        q{r-type 3},
        q{r-type iii},
        q{rtype 3},
        q{rtype iii},
    ],
    [
        q{FIFA 98 Soccer},
        q{fifa '98},
        q{fifa 1998},
        q{fifa 98},
        q{fifa soccer 98},
    ],
    [
        q{Blade 2 II},
        q{blade 2},
        q{blade ii},
    ],
    [
        q{Disney Sport Soccer },
        q{Disney Sports Soccer},
        q{Disney's Sports Soccer },
    ],
    [
        q{Adventures of Dr Franken},
        q{Adventures of Dr. Franken },
    ],
    [
        q{Mario Kart Double Dash},
        q{mario cart double dash},
        q{mario kart - double dash},
        q{mario kart: double dash},
        q{mariocart double dash},
        q{mariokart double dash},
    ],
    [
        q{Namco Museum  2},
        q{Namco Museum Volume 2},
    ],
    [
        q{Da Vinci Code},
        q{DaVinci Code},
    ],
    [
        q{wario ware mega},
        q{warioware mega},
    ],
    [
        q{Bomberman Second Attack},
        q{bomber man second attack},
    ],
    [
        q{Soduku Gridmaster},
        q{Sudoku Gridmaster},
    ],
    [
        q{NASCAR 99},
        q{nascar '99},
        q{nascar 1999},
        q{nascar99},
    ],
    [
        q{Paper Mario ( The Thousand},
        q{Paper Mario The Thousand},
    ],
    [
        q{Paper Mario Thousand Year Door},
        q{paper mario - and thousand year door},
        q{paper mario - thousand year door},
        q{paper mario and the thousand year door},
        q{paper mario and thousand year door},
    ],
    [
        q{Capcom Classic Collection},
        q{Capcom Classics Collection },
    ],
    [
        q{Scooby Doo Creep Capers},
        q{Scooby-Doo Creep Capers},
    ],
    [
        q{Madden 09},
        q{Madden 2009},
    ],
    [
        q{The Sims 2},
        q{sims 2},
    ],
    [
        q{SUPER BATTLE TANK war},
        q{super battletank war},
    ],
    [
        q{Vigilante 8},
        q{vigilante8},
    ],
    [
        q{Animal Crossing Wild World},
        q{animal crossing: wild world},
    ],
    [
        q{NBA Street Basketball},
        q{nba street},
    ],
    [
        q{Final Fantasy IV},
        q{final fantasy 4},
    ],
    [
        q{socom 2},
        q{socom ii},
    ],
    [
        q{A link to the past},
        q{link to past},
    ],
    [
        q{Assassin's Creed Limited Edition},
        q{Assassins Creed Limited Edition},
    ],
    [
        q{Super Mario All-Star},
        q{Super Mario Allstars},
        q{super mario all stars},
        q{super mario all-stars},
        q{super mario allstar},
    ],
    [
        q{Twisted Metal 4},
        q{Twisted Metal IV},
    ],
    [
        q{Madden 2008},
        q{madden '08},
        q{madden 08},
        q{madden nfl 08},
        q{madden nfl 2008},
    ],
    [
        q{Harvest Moon Another Wonderful Life},
        q{harvest moon - another wonderful life},
        q{harvest moon: another wonderful life},
    ],
    [
        q{Doom 2},
        q{Doom II},
    ],
    [
        q{Warioware Touched},
        q{wario ware touched},
    ],
    [
        q{Duck Tails},
        q{Duck Tales},
    ],
    [
        q{Bust-A-Move 3000},
        q{bust a move 3000},
        q{bustamove 3000},
    ],
    [
        q{The X-Files},
        q{X-Files The Game},
    ],
    [
        q{Lion King},
        q{The Lion King},
    ],
    [
        q{Luigi's Mansion},
        q{Luigi’s Mansion},
        q{luigi mansion},
        q{luigis mansion},
    ],
    [
        q{Castlevania Legacy},
        q{castlevania: legacy},
    ],
    [
        q{Disney Sport Football },
        q{Disney Sports Football},
        q{Disney's Sports Football },
    ],
    [
        q{Moto GP 2},
        q{motogp 2},
    ],
    [
        q{tony hawk pro skater 3},
        q{tony hawk's pro skater 3},
        q{tony hawks pro skater 3},
    ],
    [
        q{tokyo extreme},
        q{tokyo xtreme},
    ],
    [
        q{Batman Vengance},
        q{Batman Vengeance},
    ],
    [
        q{Scooby Doo Cyber Chase},
        q{Scooby Doo and the Cyber Chase},
        q{scooby-doo and the cyber chase},
        q{scooby-doo cyber chase},
    ],
    [
        q{Mortal Kombat Shaolin Monks},
        q{Mortal Kombat: Shaolin Monks},
    ],
    [
        q{Rugrats in Paris},
        q{rugrats paris},
    ],
    [
        q{Wrestlemania 2000},
        q{wrestle mania 2000},
        q{wrestlemania 00},
    ],
    [
        q{Rebel Assault 2 },
        q{Rebel Assault II},
    ],
    [
        q{ISS 64 Soccer},
        q{iss 64},
    ],
    [
        q{Super Mario Bros 3},
        q{super mario bros. 3},
        q{super mario brothers 3},
    ],
    [
        q{Pacman Collection},
        q{pac man collection},
        q{pac-man collection},
    ],
    [
        q{Madden 2005},
        q{madden 05},
        q{madden nfl 05},
        q{madden nfl 2005},
    ],
    [
        q{Moto GP 07},
        q{moto gp 2007},
        q{motogp 07},
    ],
    [
        q{Pac-Attack},
        q{pac attack},
    ],
    [
        q{The Ren and Stimpy Show Buckeroos},
        q{ren & stimpy Buckeroos},
        q{ren and stimpy Buckeroos},
    ],
    [
        q{streets of L.A.},
        q{streets of la},
    ],
    [
        q{Quake 2},
        q{quake ii},
        q{quake2},
    ],
    [
        q{Jak II},
        q{jak 2},
        q{jax 2},
    ],
    [
        q{Ratchet and Clank},
        q{ratchet & clank},
    ],
    [
        q{Namco Museum  5},
        q{Namco Museum Volume 5},
    ],
    [
        q{Beavis and Butt-Head},
        q{beavis & butt-head},
        q{beavis & butthead},
        q{beavis and butthead},
    ],
    [
        q{Blastcorps},
        q{blast corp},
        q{blast corps},
        q{blastcorp},
    ],
    [
        q{SSX 3},
        q{ssx3},
    ],
    [
        q{Kirby's Dream Land 2},
        q{kirby dream land 2},
        q{kirby dreamland 2},
        q{kirby's dreamland 2},
    ],
    [
        q{Final Fantasy XII},
        q{final fantasy 12},
    ],
    [
        q{Dr. Mario},
        q{dr mario},
    ],
    [
        q{Need for Speed - Carbon},
        q{Need for Speed Carbon},
        q{need for speed: carbon},
    ],
    [
        q{Disney Sport Motocross },
        q{Disney Sports Motocross},
        q{Disney's Sports Motocross },
    ],
    [
        q{Pokemon Stadium 2},
        q{pokeman stadium 2},
    ],
    [
        q{Twisted Metal 2},
        q{Twisted Metal II},
    ],
    [
        q{Firefighter F.D.},
        q{firefighter fd},
    ],
    [
        q{Sonic Hedgehog 3},
        q{Sonic the Hedgehog 3},
        q{sonic 3},
    ],
    [
        q{Silent Hill Origins},
        q{Silent Hill: Origins },
    ],
    [
        q{Guilty Gear X Advance Edition},
        q{guilty gear x advance},
    ],
    [
        q{Lufia and The Fortress of Doom},
        q{lufia fortress of doom},
        q{lufia: fortress of doom},
    ],
    [
        q{Jungle Book},
        q{The Jungle Book},
    ],
    [
        q{Terminator 2 Judgement Day},
        q{t2 judgement day},
    ],
    [
        q{Pirates of the Caribbean Dead Mans Chest},
        q{Pirates of the Caribbean: Dead Mans Chest},
    ],
    [
        q{Turok Rage Wars},
        q{turok: rage wars},
    ],
    [
        q{FIFA 99 Soccer},
        q{fifa '99},
        q{fifa 1999},
        q{fifa 99},
        q{fifa soccer 99},
    ],
    [
        q{Mr. Driller},
        q{mr driller},
    ],
    [
        q{FIFA 2004},
        q{fifa 04},
        q{fifa soccer 2004},
    ],
    [
        q{Medal of Honor - Frontline},
        q{Medal of Honor Frontline},
        q{medal of honor (frontline)},
        q{medal of honor: frontline},
    ],
    [
        q{Ninja Gaden},
        q{Ninja Gaiden},
    ],
    [
        q{Final Fantasy 9},
        q{final fantasy ix},
    ],
    [
        q{sim earth},
        q{simearth},
    ],
    [
        q{Sonic & Knuckles},
        q{Sonic and Knuckles},
    ],
    [
        q{NHL 2006},
        q{nhl 06},
    ],
    [
        q{Clay Fighter Sculptors Cut},
        q{clayfighter sculptors cut},
    ],
    [
        q{Halo 3},
        q{Halo3},
    ],
    [
        q{Super Smash Bros. Melee},
        q{super smash bros melee},
        q{super smash brothers melee},
    ],
    [
        q{Mega Man Zero 3},
        q{megaman zero 3},
    ],
    [
        q{Sponge Bob SquarePants lights},
        q{SpongeBob Square Pants lights},
        q{SpongeBob SquarePants lights},
    ],
    [
        q{FIFA 06},
        q{FIFA 2006},
        q{fifa soccer 2006},
    ],
    [
        q{The Matrix Path of Neo},
        q{matrix path of neo},
        q{matrix: path of neo},
    ],
    [
        q{ISS 98 Soccer},
        q{international superstar soccer '98},
        q{international superstar soccer 1998},
        q{international superstar soccer 98},
        q{iss '98},
        q{iss 1998},
        q{iss 98},
    ],
    [
        q{advance wars dual strike},
        q{advance wars: dual strike},
    ],
    [
        q{WWE Wrestlemania X8},
        q{wrestlemania x8},
    ],
    [
        q{lord of the rings - return},
        q{lord of the rings the return},
        q{lord of the rings: return},
    ],
    [
        q{Mega Man Zero},
        q{megaman zero},
    ],
    [
        q{yoshi's island},
        q{yoshis island},
    ],
    [
        q{Joe and Mac},
        q{joe & mac},
    ],
    [
        q{Super Mario Bros & Duck Hunt},
        q{Super Mario Bros and Duck Hunt},
        q{Super Mario Bros. & Duck Hunt},
    ],
    [
        q{Crash Twinsanity},
        q{Crash: Twin Sanity},
        q{Crash: Twinsanity},
    ],
    [
        q{Harvest Moon - Magical Melody},
        q{Harvest Moon Magical Melody},
        q{Harvest Moon: Magical Melody},
    ],
    [
        q{Xenosaga 2},
        q{xenosaga ii},
    ],
    [
        q{Sponge Bob Square Pants The Movie},
        q{Sponge Bob SquarePants movie},
        q{SpongeBob Square Pants movie},
        q{SpongeBob SquarePants movie},
        q{square pants movie},
        q{square pants the movie},
        q{squarepants movie},
        q{squarepants the movie},
    ],
    [
        q{pac-man 2},
        q{pacman 2},
    ],
    [
        q{Vigilante 8 2nd Offense},
        q{vigilante 8 second offense},
    ],
    [
        q{Moto GP 3},
        q{motogp 3},
    ],
    [
        q{Sponge Bob Square Pants Super},
        q{Sponge Bob SquarePants super},
        q{SpongeBob Square Pants super},
        q{SpongeBob SquarePants super},
    ],
    [
        q{Tony Hawk American Wasteland},
        q{tony hawk's american wasteland},
        q{tony hawks american wasteland},
    ],
    [
        q{Bookworm},
        q{book worm},
    ],
    [
        q{Spiderman Maximum Carnage},
        q{spider-man maximum carnage},
    ],
    [
        q{tony hawk pro skater 4},
        q{tony hawk's pro skater 4},
        q{tony hawks pro skater 4},
    ],
    [
        q{Harvest Moon Friends Mineral Town},
        q{harvest moon - friends of mineral town},
        q{harvest moon: friends of mineral town},
    ],
    [
        q{Twisted Metal Black},
        q{Twisted Metal: Black},
    ],
    [
        q{Tony Hawk Underground 2},
        q{Tony Hawk's Underground 2},
        q{Tony Hawks Underground 2},
    ],
    [
        q{FIFA 2003},
        q{fifa soccer 2003},
    ],
    [
        q{Smuggler's Run},
        q{smugglers run},
    ],
    [
        q{Need for Speed - Most Wanted},
        q{Need for Speed Most Wanted},
        q{need for speed: most wanted},
    ],
    [
        q{Sponge Bob Square Pants Atlantis Squarepants},
        q{Sponge Bob SquarePants atlantis},
        q{SpongeBob Square Pants atlantis},
        q{SpongeBob SquarePants atlantis},
    ],
    [
        q{Sonic Adventure 2 Battle},
        q{Sonic Adventure Battle 2},
    ],
    [
        q{The Sims Bustin Out},
        q{The Sims Bustin' Out},
    ],
    [
        q{Enter the Matrix},
        q{enter matrix},
    ],
    [
        q{NBA Live 2007},
        q{nba live 07},
    ],
    [
        q{Crash Bandicoot - warped},
        q{Crash Bandicoot Warped},
        q{Crash Bandicoot: warped},
    ],
    [
        q{Fighters Destiny},
        q{fighter's destiny},
    ],
    [
        q{Alien vs Predator},
        q{Alien vs. Predator},
    ],
    [
        q{Time Splitters Future Perfect},
        q{Time Splitters: Future Perfect},
        q{TimeSplitters: Future Perfect},
        q{timesplitters future perfect},
    ],
    [
        q{Mortal Kombat Deception},
        q{Mortal Kombat: Deception},
        q{mortal combat deception},
    ],
    [
        q{Gran Turismo 3},
        q{grand turismo 3},
    ],
    [
        q{Battle front ii},
        q{Battlefront 2},
        q{Battlefront II},
        q{Battlefront ii},
        q{battle front 2},
    ],
    [
        q{Street Fighter 2 turbo},
        q{Street Fighter II Turbo},
    ],
    [
        q{NASCAR Thunder 02},
        q{NASCAR Thunder 2002},
    ],
    [
        q{Dance Dance Revolution Ultramix},
        q{ddr ultramix},
    ],
    [
        q{Metroid Prime},
        q{metroid: prime},
        q{metroidprime},
    ],
    [
        q{Pitfall Beyond the Jungle},
        q{Pitfall: Beyond the Jungle},
    ],
    [
        q{Dance Dance Revolution Max},
        q{ddr max},
    ],
    [
        q{Lufia and The Rise of Sinistrals},
        q{lufia rise of sinistrals},
        q{lufia: Rise of Sinistrals},
    ],
    [
        q{Halo 3 Legendary},
        q{Halo 3 Legendary Edition},
        q{Halo 3: Legendary},
    ],
    [
        q{Prince of Persia Two Thrones},
        q{Prince of Persia the Two Thrones},
        q{Prince of Persia: Two Thrones},
    ],
    [
        q{King's Field 2},
        q{King's Field II},
        q{Kings Field 2},
    ],
    [
        q{18 wheeler},
        q{Eighteen Wheeler},
    ],
    [
        q{Rainbow Six},
        q{rainbow 6},
    ],
    [
        q{Bust-A-Move 99},
        q{bust a move 99},
        q{bust-a-move 1999},
        q{bustamove 99},
    ],
    [
        q{Sorcerer Stone},
        q{Sorcerer's Stone},
        q{Sorcerers Stone},
    ],
    [
        q{Splashdown Rides Gone Wild},
        q{splashdown - rides gone wild},
        q{splashdown: rides gone wild},
    ],
    [
        q{Gran Turismo 4},
        q{grand turismo 4},
    ],
    [
        q{Season Ice},
        q{Season of Ice},
    ],
    [
        q{Rayman 2},
        q{raymen 2},
    ],
    [
        q{Amazing Spider man },
        q{Amazing Spider-man },
        q{Amazing Spiderman},
    ],
    [
        q{Goldeneye},
        q{golden eye},
    ],
    [
        q{Medal of Honor - European Assault},
        q{Medal of Honor European Assault},
        q{Medal of Honor: European Assault },
    ],
    [
        q{nascar 06},
        q{nascar 2006},
    ],
    [
        q{Gradius 3},
        q{gradius iii},
    ],
    [
        q{Power puff girls},
        q{Powerpuff Girls},
    ],
    [
        q{Amazing Spider man 2},
        q{Amazing Spider-man 2},
        q{Amazing Spiderman 2},
    ],
    [
        q{True Crimes new york},
        q{true crime NY},
        q{true crime new york},
        q{true crime: new york},
        q{true crimes: new york},
    ],
    [
        q{Sponge Bob Square Pants Volume 1},
        q{Sponge Bob SquarePants volume 1},
        q{SpongeBob Square Pants volume 1},
        q{SpongeBob SquarePants volume 1},
    ],
    [
        q{Sponge Bob SquarePants creature},
        q{SpongeBob Square Pants creature},
        q{SpongeBob SquarePants creature},
    ],
    [
        q{tiger woods 08},
        q{tiger woods 2008},
    ],
    [
        q{NASCAR Thunder 03},
        q{NASCAR Thunder 2003},
    ],
    [
        q{Bust-A-Move 2},
        q{bust a move 2},
        q{bustamove 2},
    ],
    [
        q{Command & Conquer},
        q{Command and Conquer},
    ],
    [
        q{Shrek Superslam},
        q{shrek super slam},
    ],
    [
        q{Wario Land 4},
        q{warioland 4},
    ],
    [
        q{CSI Crime Scene Investigation},
        q{CSI: Crime Scene Investigation },
    ],
    [
        q{Mega Man X4},
        q{Megaman X4},
    ],
    [
        q{Allstar Baseball 2004},
        q{all star baseball 2004},
        q{all-star baseball 2004},
    ],
    [
        q{Twisted Metal 3},
        q{Twisted Metal III},
    ],
    [
        q{F.E.A.R},
        q{FEAR},
    ],
    [
        q{ANIMAL CROSSINGS CITY FOLK},
        q{Animal Crossing City Folk},
    ],
    [
        q{Ace Combat 4},
        q{ace kombat 4},
    ],
    [
        q{Battletanx Global Assault},
        q{battle tank global assault},
        q{battle tanx global assault},
    ],
    [
        q{Fire Emblem Sacred Stones},
        q{fire emblem - sacred stones},
        q{fire emblem: sacred stones},
    ],
    [
        q{extra time 2002},
        q{extratime 2002},
    ],
    [
        q{Mace Dark Age},
        q{Mace: The Dark Age},
    ],
    [
        q{Donkey Kong Country 3},
        q{Donkey Kong Kountry 3},
    ],
    [
        q{Bomberman 64},
        q{bomber man 64},
    ],
    [
        q{StarFox},
        q{star fox},
    ],
    [
        q{Lord of the Rings Fellowship},
        q{Lord of the Rings: The Fellowship},
        q{lord of the rings - fellowship},
        q{lord of the rings the fellowship},
        q{lord of the rings: fellowship},
    ],
    [
        q{Pacman World},
        q{pac-man world},
    ],
    [
        q{Backyard Wrestling 2},
        q{Backyard Wrestling ii},
    ],
    [
        q{Street Fighter 2},
        q{Street Fighter II},
    ],
    [
        q{Donkey Kong Country},
        q{Donkey Kong Kountry},
    ],
    [
        q{NBA Street Vol 2},
        q{nba street 2},
        q{nba street vol. 2},
    ],
    [
        q{final fantasy 5},
        q{final fantasy v},
    ],
    [
        q{The Getaway},
        q{getaway},
    ],
    [
        q{Battletoads and Double Dragon},
        q{Battletoads/Double Dragon },
    ],
    [
        q{Need for Speed High Stakes},
        q{need for speed: high stakes},
    ],
    [
        q{robot on wheel},
        q{robot on wheels},
    ],
    [
        q{Banjo Kazooie Grunty's Revenge},
        q{banjo-kazooie grunty's revenge},
    ],
    [
        q{Conflict Desert Storm},
        q{conflict: desert storm},
    ],
    [
        q{WWE Wrestlemania 21},
        q{Wrestlemania 21},
    ],
    [
        q{Ultimate Spiderman},
        q{ultimate spider-man},
    ],
    [
        q{California Games 2},
        q{California Games II},
    ],
    [
        q{Medal of Honor - Rising Sun},
        q{Medal of Honor Rising Sun},
        q{Medal of Honor: Rising Sun},
    ],
    [
        q{Tom and Jerry Magic Ring},
        q{tom & jerry magic ring},
    ],
    [
        q{Bloodrayne},
        q{blood rayne},
    ],
    [
        q{Mystical Ninja's},
        q{mystical ninja},
        q{mystical ninjas},
    ],
    [
        q{Kill.Switch},
        q{kill switch},
        q{killswitch},
    ],
    [
        q{Brain Age 2},
        q{Brainage 2},
    ],
    [
        q{Final Fantasy IV Advance},
        q{final fantasy 4 advance},
        q{final fantasy 4: advance},
        q{final fantasy iv: advance},
    ],
    [
        q{Mario vs. Donkey Kong},
        q{mario vs donkey kong},
    ],
    [
        q{Mortal Kombat 4},
        q{mortal combat 4},
        q{mortal kombat4},
    ],
    [
        q{Spyro Collector's Edition},
        q{Spyro Collectors Edition},
        q{Spyro: Collector's Edition},
    ],
    [
        q{Cabela's Dangerous Hunts 2},
        q{dangerous hunts 2},
    ],
    [
        q{Burger Time},
        q{Burgertime},
    ],
    [
        q{The House of the Dead 2},
        q{house of the dead 2},
    ],
    [
        q{Metroid Prime Hunters},
        q{metroid prime: hunters},
    ],
    [
        q{Ape Escape 3},
        q{ape escape iii},
    ],
    [
        q{Track & Field},
        q{Track and Field},
    ],
    [
        q{ACME All-Stars},
        q{ACME AllStars},
    ],
    [
        q{Scooby Doo Mystery Mayhem},
        q{Scooby-Doo Mystery Mayhem},
    ],
    [
        q{Disney Party},
        q{disney's party},
    ],
    [
        q{Dead or Alive 3},
        q{doa 3},
    ],
    [
        q{Medal of Honor  - Vanguard},
        q{Medal of Honor Vanguard},
        q{Medal of Honor: Vanguard},
    ],
    [
        q{F zero Maximum Velocity },
        q{F-zero Maximum Velocity},
        q{Fzero Maximum Velocity },
    ],
    [
        q{NCAA March Madness 06},
        q{NCAA March Madness 2006},
    ],
    [
        q{Scooby Doo Mystery},
        q{scooby doo: mystery},
        q{scoobydoo mystery},
    ],
    [
        q{Robotech Battlecry},
        q{Robotech: Battlecry},
    ],
    [
        q{Kings Field Ancient City},
        q{king's field ancient city},
    ],
    [
        q{Duck Tails 2},
        q{Duck Tales 2},
    ],
    [
        q{NASCAR Thunder 04},
        q{NASCAR Thunder 2004},
    ],
    [
        q{R.C. Pro-Am 2},
        q{R.C. Pro-Am II},
        q{RC Pro AM 2},
        q{RC Pro AM II},
        q{RC Pro-AM II},
    ],
    [
        q{Scooby Doo Unmasked},
        q{Scooby-Doo Unmasked},
    ],
    [
        q{Far Cry},
        q{farcry},
    ],
    [
        q{Soul Calibur 2 II},
        q{soul caliber 2},
        q{soul caliber ii},
        q{soul calibur 2},
        q{soul calibur ii},
        q{soulcalibur 2},
        q{soulcalibur ii},
    ],
    [
        q{Disney Sport Basketball },
        q{Disney Sports Basketball},
        q{Disney's Sports Basketball},
    ],
    [
        q{space channel 5},
        q{space channel five},
    ],
    [
        q{Tomb Raider 2},
        q{Tomb Raider II},
    ],
    [
        q{Super Ghouls 'N Ghosts},
        q{super Ghouls & Ghosts},
    ],
    [
        q{Bart vs the World},
        q{Bart vs. the World },
    ],
    [
        q{road runner death valley},
        q{road runner's death valley},
    ],
    [
        q{Marvel Super Heroes vs. Street Fighter},
        q{marvel super heroes vs street fighter},
    ],
    [
        q{Paperboy},
        q{paper boy},
    ],
    [
        q{Sonic Hedgehog 2},
        q{Sonic the Hedgehog 2},
        q{sonic 2},
    ],
    [
        q{Bust-A-Move DS},
        q{bust a move ds},
    ],
    [
        q{Tomb Raider Legend},
        q{Tomb Raider: Legend},
    ],
    [
        q{Chrome Hounds},
        q{Chromehounds},
    ],
    [
        q{sarge's heroes},
        q{sarges heroes},
    ],
    [
        q{STAR FOX ASSAULT},
        q{Starfox Assault},
    ],
    [
        q{Hogan's Alley},
        q{hogans alley},
    ],
    [
        q{NCAA Football 08},
        q{NCAA Football 2008},
    ],
    [
        q{Far Cry Instincts Evolution},
        q{Farcry Instincts Evolution},
    ],
    [
        q{super mario},
        q{supermario},
    ],
    [
        q{kotr 2},
        q{knights of old republic 2},
    ],
    [
        q{Moto GP - Used},
        q{Moto GP},
    ],
    [
        q{Karaoke Revolution Country},
        q{Karaoke Revolution Country - Game Only},
    ],
    [
        q{Ninja Bread Man},
        q{Ninjabread Man},
    ],
    [
        q{Bass Fishing},
        q{Sega Bass Fishing},
    ],
    [
        q{Avatar: The Game},
        q{James Cameron's Avatar: The Game},
    ],
    [
        q{MLB 2K10},
        q{Major League Baseball 2K10},
    ],
    [
        q{Hot Wheels: Battle Force 5},
        q{Hot Wheels: Battleforce 5},
    ],
    [
        q{Dora Saves the Crystal Kingdom},
        q{Dora the Explorer: Dora Saves the Crystal Kingdom},
    ],
    [
        q{SpeedZone},
        q{Speed Zone},
    ],
    [
        q{Cake Mania In The Mix},
        q{Cake Mania: In the Mix!},
    ],
    [
        q{CSI Hard Evidence},
        q{CSI: Crime Scene Investigation: Hard Evidence},
    ],
    [
        q{EA Smarty Pants},
        q{Smarty Pants},
    ],
    [
        q{Barbie Island Princess},
        q{Barbie as the Island Princess},
    ],
    [
        q{Spyro The Eternal Night},
        q{The Legend of Spyro: The Eternal Night},
    ],
    [
        q{Splinter Cell Double Agent},
        q{Tom Clancy's Splinter Cell: Double Agent},
    ],
    [
        q{SpongeBob SquarePants Creature from Krusty Krab},
        q{Spongebob: Creature From Krusty Krab},
    ],
    [
        q{Playground},
        q{EA Playground},
    ],
    [
        q{Lara Croft Tomb Raider Anniversary},
        q{Tomb Raider Anniversary},
    ],
    [
        q{Disney Think Fast},
        q{Think Fast},
    ],
    [
        q{Lego Batman The Videogame},
        q{LEGO Batman},
    ],
    [
        q{Legend of Zelda: Twilight Princess},
        q{Zelda: Twilight Princess},
    ],
    [
        q{Bigs 2, The},
        q{The Bigs 2},
    ],
    [
        q{I Spy Funhouse},
        q{I Spy Fun House},
    ],
    [
        q{Tom Clancy's End War},
        q{Tom Clancy's EndWar},
    ],
    [
        q{Tony Hawk American Skateland},
        q{Tony Hawk's American Sk8land},
    ],
    [
        q{Jagged Alliance DS},
        q{Jagged Alliance},
    ],
    [
        q{Namco Museum},
        q{Namco Museum DS},
    ],
    [
        q{Wonderworld Amusement Park},
        q{Wonder World Amusement Park},
    ],
    [
        q{Warhammer 40k Squad Command},
        q{Warhammer 40,000: Squad Command},
    ],
    [
        q{Mario Party 7 w/ Microphone},
        q{Mario Party 7 with Microphone},
    ],
    [
        q{Fairly Odd Parents Shadow Showdown},
        q{The Fairly OddParents: Shadow Showdown},
    ],
    [
        q{Bad Boys Miami Takedown},
        q{Bad Boys: Miami Take Down},
    ],
    [
        q{SpyHunter 2},
        q{Spy Hunter 2},
    ],
    [
        q{Aliens vs. Predator Extinction},
        q{Aliens Versus Predator: Extinction},
    ],
    [
        q{Mister Mosquito},
        q{Mr. Mosquito},
    ],
    [
        q{Jump Start Pet Rescue},
        q{JumpStart Pet Rescue},
    ],
    [
        q{Pro Bull Riders: Out of the Chute},
        q{PBR Out of the Chute},
    ],
    [
        q{Soldier of Fortune: Pay Back},
        q{Soldier Of Fortune Payback},
    ],
    [
        q{Ghost Hunter},
        q{Ghosthunter},
    ],
    [
        q{Spyhunter: Nowhere To Run},
        q{Spy Hunter Nowhere to Run},
    ],
    [
        q{Warhammer 40K Fire Warrior},
        q{Warhammer 40000 Fire Warrior},
    ],
    [
        q{NBA Shoot Out 2001},
        q{NBA ShootOut 2001},
    ],
    [
        q{Bad Boys: Miami Take Down},
        q{Bad Boys Miami Takedown},
    ],
    [
        q{Gundam: Federation vs. Zeon},
        q{Mobile Suit Gundam Federation vs Zeon},
    ],
    [
        q{Gundam Vs Zeta Gundam},
        q{Mobile Suit Gundam: Gundam vs. Zeta Gundam},
    ],
    [
        q{Uno Free Fall},
        q{Uno Freefall},
    ],
    [
        q{Sherlock Holmes vs. Jack the Ripper},
        q{Sherlock Holmes Versus Jack the Ripper},
    ],
    [
        q{Hasbro Family Game Night 4: The Game Show},
        q{Family Game Night 4: The Game Show},
    ],
    [
        q{Rabbids Travel in Time},
        q{Raving Rabbids: Travel in Time},
    ],
    [
        q{Asphalt: 3D},
        q{Asphalt},
    ],
    [
        q{Nintendo 3DS Aqua Blue},
        q{Aqua Blue Nintendo 3DS},
    ],
    [
        q{Star Fox 64 3D},
        q{Star Fox 64},
    ],
    [
        q{Playstation 3 system 40GB},
        q{Playstation 3 system 40 GB},
    ]
);

plan tests => scalar @tests;
my $phonetic = Text::Phonetic::VideoGame->new;
for my $test (@tests) {
    my $msg = $test->[0];
    my @encodings = $phonetic->encode(@$test);
    my @unique = uniq @encodings;
    if ( @unique == 1 ) {
        ok( 1, $msg );
        next;
    }

    # if the hashes don't match, produce more helpful output
    my ( %got, %expected );
    @got{ @$test } = @encodings;
    diag( Dumper(\%got) );
    ok( 0, $msg );
}
