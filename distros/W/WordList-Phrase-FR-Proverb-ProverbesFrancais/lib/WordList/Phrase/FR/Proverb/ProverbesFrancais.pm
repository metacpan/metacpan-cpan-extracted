package WordList::Phrase::FR::Proverb::ProverbesFrancais;

our $DATE = '2016-02-10'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_whitespace",10667,"longest_word_len",376,"num_words_contains_unicode",8225,"num_words_contains_nonword_chars",10667,"shortest_word_len",9,"num_words",10667,"avg_word_len",49.5651073403956); # STATS

1;
# ABSTRACT: French proverbs from proverbesfrancais.com

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::FR::Proverb::ProverbesFrancais - French proverbs from proverbesfrancais.com

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::FR::Proverb::ProverbesFrancais (from Perl distribution WordList-Phrase-FR-Proverb-ProverbesFrancais), released on 2016-02-10.

=head1 SYNOPSIS

 use WordList::Phrase::FR::Proverb::ProverbesFrancais;

 my $wl = WordList::Phrase::FR::Proverb::ProverbesFrancais->new;

 # Pick a (or several) random word(s) from the list
 my $word = $wl->pick;
 my @words = $wl->pick(3);

 # Check if a word exists in the list
 if ($wl->word_exists('foo')) { ... }

 # Call a callback for each word
 $wl->each_word(sub { my $word = shift; ... });

 # Get all the words
 my @all_words = $wl->all_words;

=head1 STATISTICS

 +----------------------------------+------------------+
 | key                              | value            |
 +----------------------------------+------------------+
 | avg_word_len                     | 49.5651073403956 |
 | longest_word_len                 | 376              |
 | num_words                        | 10667            |
 | num_words_contains_nonword_chars | 10667            |
 | num_words_contains_unicode       | 8225             |
 | num_words_contains_whitespace    | 10667            |
 | shortest_word_len                | 9                |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-FR-Proverb-ProverbesFrancais>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-FR-Proverb-ProverbesFrancais>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-FR-Proverb-ProverbesFrancais>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
A beau mentir qui vient de loin
Abondance de biens ne nuit pas
Abondance engendre fâcherie
Abreuver son cheval à tous gués, Mener sa femme à tous festins, De son cheval on fait une rosse, Et de sa femme une catin
Absent le chat, les souris dansent
Accommodez-vous, le pays est large
Acheter est meilleur marché que demander
Adieu paniers, vendanges sont faites
Advienne que pourra
Aide-toi, le ciel t’aidera
Aller et venir font le chemin pelé
Ami au prêter, ennemi au rendre
Ami de table est variable
Ami vaut mieux qu’argent
Amis au prêter, ennemis au rendre
Amitié de grands, Serments de femmes, Et soleil d’hiver, Ne durent guère
Année glanduleuse année chanceuse
Apprentis ne sont pas maîtres
Après la panse viens la danse
Après la pluie vient le beau temps
Après la pluie, le beau temps
Après la poire le vin ou le prêtre
Après trois jours, sa femme, un hôte et de la pluie, Sont trois choses dont on s’ennuie
Argent comptant porte médecine
Argent comptant porte médecine, argent emprunté porte tristesse
Argent fait perdre et pendre gens
Au besoin on connaît l’ami
Au bout de l’aune faut le drap
Au bout du fossé la culbute
Au chant on connaît l’oiseau
Au cheval maigre va la mouche
Au coeur sans but, coeur fidéle
Au corbeau, préfère la pie
Au danger on connaît les braves
Au feu uriner est sain, Et y cracher est vain
Au figuratif, signifie que l’on attribue volontiers certains actes à ceux qui sont coutumier du fait, qui sont réputés posséder ces choses
Au jour du jugement, chacun sera mercier et portera son panier
Au mal de goutte, le médecin ne voit goutte
Au paresseux laboureur, Les rats mangent le meilleur
Au pauvre un œuf vaut un bœuf
Au rire on connaît le fou
Au royaume des aveugles les borgnes sont rois
Aujourd’hui chevalier, demain vacher
Aujourd’hui en chère, demain en bière
Aujourd’hui en fleur, demain en pleur
Aujourd’hui maître, demain valet
Aujourd’hui roi, demain rien
Aussitôt dit, aussitôt fait
Autant croît le désir que le trésor
Autant de pays, autant de guises
Autant de trous, autant de chevilles
Autant de têtes, autant de sentiments
Autant de têtes, autant d’avis
Autant en emporte le vent
Autant vaut traîné que porté
Autres temps, autres mœurs
Aux bonnes fêtes les bon coups
Aux bons ils arrivent souvent malheur
Aux derniers, les bons
Aux grands maux, les grands remèdes
Aux innocents, les mains pleines,
Aux maux extrêmes, les extrêmes remèdes
Aux vêpres on connaît la fête
Avec des Si, on mettrait Paris dans une bouteille
Avec le vent on nettoie le froment, Et vice avec supplice et châtiment
Avocats se querellent, et vont boire ensemble
Bailler caution est occasion de double procès
Barbe bien étuvée, est à demi-rasée
Battre le fer il faut, Tandis qu’il est bien chaud
Beau chemin n’est jamais long
Beau et bon on ne peut pas être
Beau noyau gît sous faible écorce
Beau parler n’écorche la langue
Beau parler n’écorche langue
Beau visage et cœur arrière
Beaucoup de bruit pour rien
Beaucoup savent parler, mais bien peu savent faire
Beauté de femme n’enrichit homme
Beauté n’est qu’image fardée
Belle fille et méchante robe, Trouvent toujours qui les accroche
Belle montre et peu de rapport
Belle vigne sans raison ne vaut rien
Besace bien promenée nourrit son maître
Besogne commencée est plus qu’à demi faite
Besogne qui plaît est à demi faite
Besoin fait maint sentier tenir
Bien bas choit qui trop haut monte
Bien danse à qui la fortune chante
Bien dire fait rire, bien faire fait taire
Bien dire, fait rire; Bien faire, fait taire
Bien faire et laisser dire
Bien faire, et laisser braire
Bien fou qui s’inquiète de l’avenir
Bien fou qui s’oublie
Bien mal acquis ne profite jamais
Bien mal acquis ne profite jamais
Bien mal acquis ne prospère jamais
Bien misérable que celui que Dieu hait, bien riche que celui que Dieu aime
Bien mérite d’aller à pied, Qui ne prend soin de son cheval
Bien nourrir fait dormir, Et bien vivre fait mourir
Bien perdu, bien connu
Bien venu qui apporte
Bien vient à mieux, et mieux à mal
Bienfait qui se fait trop attendre, Est gâté quand il arrive
Bienfait reproché, est à demi payé
Bois inutile porte fruit précieux
Bois tordu fait flamme droite
Bon ami en cour, Rend le procès plus court
Bon atelier, vaut mieux que bon râtelier
Bon avocat, mauvais voisin
Bon capitaine, bons soldats
Bon cavalier monte à toute main
Bon cheval va seul à l’abreuvoir
Bon chien chasse de race
Bon chien chasse de race
Bon chien, N’aboie pas pour rien
Bon cœur ne peut mentir
Bon droit ne se passe point d’aide
Bon droit ne se trouve pas mal d’aide
Bon estomac et mauvais cœur, C’est le secret pour vivre longtemps
Bon fruit vient de bonne semence
Bon grain périt, paille demeure
Bon jour, bonne œuvre
Bon marché ruine
Bon marché vide le panier, Mais n’emplit pas la bourse
Bon mot n’épargne personne
Bon oiseau se dresse lui même
Bon ouvrier ne querelle pas ses outils
Bon ouvrier ne reste jamais sans rien faire
Bon ouvrier n’est pas trop payé
Bon ouvrier se sert de tous outils
Bon payeur Est de bourse d’autrui seigneur
Bon pays, mauvais chemin
Bon poète, mauvais homme
Bon renard ne mange jamais les poules de son voisin
Bon renard ne se prend pas deux fois au même piège
Bon renom s’acquiert par bonne hantise
Bon sang ne peut mentir
Bon sang ne saurait mentir
Bon temps et bonne vie, père et mère oublie
Bonheur passe richesse
Bonne amitié vaut mieux que tour fortifiée
Bonne bête s’échauffe en mangeant
Bonne chère tue plus de gens que l’épée
Bonne femme fait le bon homme
Bonne femme, bon ami, bon melon, Il n’en est pas à foison
Bonne femme, mauvaise tête
Bonne fuite vaut mieux que mauvaise attente
Bonne journée fait qui de fou se délivre
Bonne mine vaut mieux que lettres de recommandation
Bonne mule, mauvaise tête
Bonne parole à cœur mauvais, C’est bon vin en vaisseau punais
Bonne renommée Vaut mieux que ceinture dorée
Bonne renommée vaut mieux que ceinture dorée
Bonne semence fait bon grain Et bons arbres portent beaux fruits
Bonne terre, mauvais chemins
Bonne terre, méchant chemin
Bonne épée, point querelleur
Bonnes sont les dents qui retiennent la langue
Bons nageurs sont souvent noyés
Bonté vaut mieux que beauté
Bouche en cœur au sage, Cœur en bouche au fou
Bourse de joueur n’a pas de serrure
Brebis comptée, le loup la mange
Brebis comptées, le loup les mange
Brebis mal gardée, Du loup est mangée
Brebis qui bêle perd sa gueulée
Bruine est bonne à la vigne, Et à blé la ruine
Bruine obscure-Trois jours dure, Si elle poursuit, En dure huit
Bâtir est parfois nécessaire, Mais planter est toujours utile
Bénéfice à l’indigne est maléfice
Bœuf saignant, mouton bêlant, porc pourri, tout n’en vaut rien s’il n’est bien cuit
Cache ta vie
Cadran solaire et faux ami, Parlent tant que le soleil luit, Et se taisent quand il s’enfuit
Ce ne sont pas les grands mots, Qui remplissent les boisseaux
Ce n’est pas tout que des choux, Il faut encore de la graisse
Ce proverbe a pour origine la défection, sous François, de mercenaires suisses qui n’avaient pas reçu leur solde
Ce que Dieu garde est bien gardé
Ce que femme veut, Dieu le veut
Ce que gantelet saisit, Gorgelet l’engloutit
Ce que je dis à vous, ma nièce, C’est pour vous mon neveu
Ce que l’on acquiert méchamment, On le dépense sottement
Ce que l’on donne aux méchants, toujours on le regrette
Ce que maître veut et valet pleure, sont larmes perdues
Ce qui abonde ne vicie pas
Ce qui arrive à l’un peut arriver à l’autre
Ce qui doit être sera
Ce qui est amer à la bouche peut être doux au cœur
Ce qui est bon à prendre, Est bon à rendre
Ce qui est fait n’est plus à faire
Ce qui ne coûte rien, Est sensé ne valoir rien
Ce qui nuit à l’un, duit à l’autre
Ce qui rentre par une oreille, sort par l’autre
Ce qui se conçoit bien s’énonce clairement, et les mots pour le dire arrivent aisément
Ce qui tombe dans le fossé Est pour le soldat
Ce qui vient par la flûte s’en va par le tambour
Ce qu’on donne aux méchants, toujours on le regrette
Ce qu’on dérobe, Ne fait pas garde-robe
Ce qu’on gagne par le gosier s’en va par le gésier
Ce qu’on méprise est souvent très utile
Cela ne vaut rien Voir aussi : Cela ne vaut pas les quatre fers d’un chien
Celui qui combat avec des lances d’argent est sûr de vaincre
Cent ans bannière, Cent ans civière
Cent ans de chagrins ne paient pas un sou de dettes
Cent ans ne sont pas si longs qu’ils en ont la mine
Cerf bien donné aux chiens est à demi pris
Cest trop d’aimer quand on en meurt
Ceux que le malheur n’abat point, il les instruit
Ceux qui n’ont point d’affaires, s’en font
Ceux qui sont de notre avis, Sont les vrais hommes d’esprit
Chacun croit fort aisément Ce qu’il craint et ce qu’il désire
Chacun doit se résigner à sa situation, à son sort
Chacun doit se résigner à sa situation, à son sort
Chacun décharge son péché, et charge celui d’autrui
Chacun est bossu quand il se baisse
Chacun est l’artisan de sa fortune
Chacun prêche pour son saint
Chacun sait où le bât blesse
Chacun son métier, Les vaches seront bien gardées
Chagrin d’autrui ne touche qu’à demi
Chance vaut mieux que de bien jouer
Changement de propos réjouit l’homme
Changement de temps, entretien de sots
Chapon de huit mois, Dîner de roi
Chaque plat de poisson est payé cinq fois au fisc, et une fois au pêcheur
Charbonnier est maître dans sa loge
Chariot branlant : Voiture suspendue
Charité bien ordonnée commence par soi même
Chasseur, pêcheurs, preneur de taupes, Feraient beaucoup, n’étaient les fautes
Chat ganté ne prit jamais souris
Chat échaudé craint l’eau froide
Chats et chiens, Mauvais voisins
Cheptel de moutons et d’abeilles, Fait souvent bien gratter l’oreille
Cher est le miel qu’on lèche sur les épines
Cheval de foin, cheval de rien; Cheval d’avoine, cheval de peine; Cheval de paille, cheval de bataille
Cheval qui piaffe, n’avance guère
Chien hargneux a toujours oreilles déchirées
Chien échaudé ne revient pas en cuisine
Chose prohibée, Est d’autant plus désirée
Chose promise, chose due
Chute d’ardoise pèse plus au présent, Que chute de tour à l’absent
Château pris, ville rendue
Clé d’or passe partout
Comme l’heure de la mort est incertaine pour chacun de nous, il faut pendre d’avance ses précautions, c’est-à-dire consigner par écrit les conventions que l’on fait
Comme on fait son lit, on se couche
Comme tu fais on fera
Commettre un crime et le nier, N’est pas le chemin de se corriger
Compagnon bien parlant, Vaut en chemin chariot branlant
Comparaison n’est pas raison
Conseil est bon, Mais aide est encore mieux
Conserver libre oreille, cœur et mains, Fait le doux vivre et le mourir serein
Content chacun doit être de son estat
Contentement passe richesse
Conteur sempiternel, Pauvre cervelle
Contre forts et contre faux, Ne valent ni lettres ni sceaux
Contre la mort, point d’appel
Contre un plus puissant que soi, on ne dispute pas sans perte
Corsaires, attaquant corsaires, Ne font pas, dit-on, leurs affaires
Couche-toi plutôt sans souper, que de te lever avec des dettes
Coucher de poule et lever de corbeau Écartent l’homme du tombeau
Coureur comme un Basque
Cruauté est fille de couardise
Cruauté est mainte fois bonne Quand sages hommes à temps la donne
Cède-moi ta place, se dit de ceux dont la conduite n’a d’autre but que de remplacer les autres dans les emplois qu’ils occupent
Cœur content, grand talent
Cœur facile à donner, Facile à ôter
Cœur qui soupire, N’a pas ce qu’il désire
Cœur étroit n’est jamais au large
C’est au pied du mur que l’on voit le maçon
C’est dans l’arène que le gladiateur prend sa décision
C’est la femme qui fait ou défait la maison
C’est la poule qui a pondu l’œuf qui chante
C’est le greffier de Vaugirard Il ne peut écrire quand on le regarde
C’est le signe d’un fou, qu’avoir honte d’apprendre
C’est pain béni, qu’escroquer un avare
C’est peu de chose d’être loué de son père, de sa nourrice et de son curé
Dame qui moult se mire, Peu file
Dans le doute, abstiens-toi
Dans les affaires du monde, ce n’est pas la foi qui sauve,Mais plutôt l’incrédulité
Dans les conseils (consultations), Les murs ont des oreilles
Dans les petites boites sont les fines épices
Dauphinois, fin matois; Ne vous y fiez pas
De belles paroles ne mettent pas de beurre dans les panais
De bien commun, l’on ne fait pas monceau
De cent noyés, pas un sauvé De cent pendus, pas un perdu
De chiens, chevaux, armes, amours, Pour un plaisir, mille doulours
De deux maux, il faut éviter le pire
De fou juge, prompte sentence
De jeune avocat, héritage perdu; De jeune médecin, cimetière bossu
De la panse vient la danse
De l’esprit comme quatre, et pas de sens comme un
De marchand à marchand, il n’y a que la main
De mouton à courte laine, On n’aura pas bonne toison
De tous métiers, il y en a de pauvres et de riches
De tout homme inconnu, le sage se méfie
De trois choses Dieu nous garde De bœuf salé sans moutarde, De valet qui se regarde, Et de femme qui se farde
De trop prés se chauffe, qui se brûle
Dernier couché, premier debout, Doit être chaque maître partout
Des femmes et des chevaux, Il n’en est point sans défauts
Des goûts et des couleurs, on ne discute pas
Des goûts et des couleurs, on ne dispute pas
Des mauvaises coutumes, naissent les bonnes lois
Deux chiens sont mauvais à un os
Deux femmes font un plaid; Trois un grand caquet; Quatre un plein marché
Deux fois bon, c’est une fois bête
Dieu me garde de mes amis; mes ennemis je m’en charge
Dieu ne veut pas plus qu’on ne peut
Dieu nous a point bâtit de ponts, Il nous a donné des mains pour en faire
Dieu nous garde d’un et cetera d’un notaire, Et d’un quiproquo d’un apothicaire
Dieu nous garde d’un homme qui n’a qu’une affaire
Dieu voit qui est bon pèlerin
Difficile chose est de souffrir aise
Différé n’est pas perdu
Dire et faire, sont deux
Dis-moi qui tu hantes, je te dirai qui tu es
Diseur de bons mots, mauvais caractère
Diviser pour régner
Donne au reconnaissant plus qu’il ne demande
Donner et retenir, ne vaut
Donner pour Dieu, n’appauvrit l’homme
Donner un œuf, pour avoir un bœuf
Dos de brochet, ventre de carpe
Double jeune, double morceau
Douces paroles n’écorchent langue
Douces paroles n’écorchent pas la langue
Droit veut que pauvre témoins Ne soit crû n’en plus; n’en moins
Débander l’arc ne guérit pas la plaie
Défie-toi d’un homme qui parle peu, D’un chien qui n’aboie guère Et de l’et cetera d’un notaire
Dépend le pendard, il te pendra
Dépense toujours moins que ta rente
Désir n’est pas volonté
Désir promet plus que jouissance ne tient
D’injuste gain, Juste daim
D’un mauvais payeur, on tire ce qu’on peut
D’un sac à charbon ne saurait sortir blanche mouture
D’une buse on ne peut faire un épervier
Eau coite jour et nuit, noie, submerge et nuit
Eau courante n’est jamais salissante
Eau courante, bonne boisson ; eau immobile, poison
Eau et pain, c’est la viande du chien
Eau et vin dans un estomac, chat et chien dans le même sac
Eau qui court fait joli visage
Eau trouble fait bonne pêche
Eau trouble ne fait pas miroir
Ecrivez les serment sur la cendre
Elle change d’amoureux comme de chemises
Elle est comme les mauvaises vaches, elle a plus de gorge que de lait
Elle est large la voie qui mène en enfer
Elle sait qui elle veut mais elle ne sait pas qui la veut
Elle se fait prier, on voit bien que c’est une belle fille
Elle se marierait avec un bouc coiffé
Elle épouserait un chien avec un chapeau
Elle épouserait un manche à balai costumé
Elles en ont tant porté de grands qu’elles n’en sauraient plus porter des petits
Elles ont mis le char avant les bœufs
Elles partent agnelles au bal et elles reviennent brebis
Eloigne de tes lèvres la fausseté et que tes yeux regardent en face
Embrasse le chien sur le museau, jusque quand tu lui passes la muselière
Emploie ton bien quand il est tien, après ta mort tu n’y as rien
Emprunter n’est pas avancé
Emprunter vaut pas gros mieux que mendier
Empêche un fou de dévorer son sac
En allant et en venant, le garçon fit son an
En amour est folie et sens
En amour l’apprenti en sait plus que le maître
En amour un beau cheveu est plus fort que quatre bœufs
En amour, en procès, en vaillance, un rien fait pencher la balance
En amour, il n’y a guère d’autre raison de ne s’aimer plus que de s’être trop aimés
En amour, il y a plus d’aloès que de miel
En amour, la victoire de l’homme, c’est la fuite
En amour, l’innocence est un savant mystère
En amourettes plaisirs fallaces y a
En amours (il y) a folie et sens
En août fait-il bon glaner
En août les gélines (poules) sont sourdes
En aval tous les saints sont forts
En aventure gisent beaux coups
En avril nuée, en mai rosée
En avril, ne te découvre pas d’un fil; en mai fais ce qu’il te plaît
En bas tous les bons saints aident, en haut fais comme tu peux
En bavardant le rôti brûle
En beau semblant gît fausseté
En beaucoup de nouvelles, y a des bourdes belles
En beauté corporelle gît souvent la mère de vice et marâtre de vertu
En beauté gît souvent le venin
En belle prairie, belle pâture
En bien faisant l’on guerroie le méchant
En bonne maison a-t-on tôt apprêté
En bonne maison, pain rassis et bois sec
En buisson et en maison, fait mal dire sa raison
En buvant et en mangeant on perd l’appétit
En cas hâtif, nul avis
En ce monde chétif et mesquin, quand il y a du pain, il y manque le vin
En ce monde n’a que heur et malheur
En ce monde, fortune et infortune abondent
En ce qu’ils ont de commun, les deux sexes sont égaux; en ce qu’ils ont de différent, ils ne sont pas comparables
En cent livres de plaidoyers n’y a pas une maille d’amour
En chacune maison, sa croix et passion
En chaque pays, vertu est en prix
En cheminant l’on se lasse
En cherchant la vérité, il en coûte d’avouer que ce sont les frivoles qui sont les vrais sages
En chose inique, infâme et laide, en vain s’implore du Seigneur l’aide
En chômant l’on apprend à mal faire
En commençant, pense à finir
En conseil ois (écoute) le vieil
En corps petit, gît bien un grand esprit
En couvent souffle tout vent
En cœur sujet à vice et à péché, n’entrera sagesse, vertu ni bonté
En demandant on va à Rome
En dignité bien sied humanité
En diplomatie, il ne suffit pas d’avoir raison, il s’agit aussi de plaire
En discutant, on s’entend
En donnant aie égard et cure, de tenir règle et bonne mesure
En dressant des embûches à un autre on se tend un piège à soi-même
En défaut de sage monte fol en chaire
En défaut d’homme sage, Monte le fol en chaire et cage
En eau coite tu ne dois mettre un pied, main ni doigts
En eau endormie, nul ne s’y fie
En enseignant lentement, on apprend vite
En enseignant, on apprend
En espérance d’avoir mieux, vit le loup tant qu’il devient vieux
En espérant d’avoir mieux, en vivant devenons vieux
En face du vrai bonheur, les richesses valent l’ombre d’une fumée
En faisant la cage l’oiseau s’en va
En faisant les sots on apprend toujours quelque chose
En fait de goût, chacun doit être le maître chez soi
En fait de procès, qui compte ses pas perd son compte
En fait de semailles et de mariage, garde-toi de conseiller
En fait de soupes et d’amours, les premières sont les meilleures
En faut voir (de) par ce monde
En feu de facon ni braise ni charbon
En fleuve où manque le poisson, jeter filets est sans raison
En forgeant on devient forgeron
En four chaud ne croît point d’herbe
En frottant fer souvent on le polit
En fuyant le loup, j’ai fait rencontre de l’ours
En gagnant avec peine on apprend à bien garder ce qu’on a
En gaine d’or souvent gît glaive de plomb
En gardant le sien, l’on fait guerre à autrui
En gaspillant le bien de Dieu, vient qu’on en n’a plus rien
En gouttes, médecin ne voit goutte
En grand fardeau n’est pas l’acquit
En grand fleuve tel poisson et le bon nageur au fond
En grand torrent grand poison se prend
En grande beauté, rarement loyauté
En grande pauvreté ne gît pas grande loyauté
En grandes entreprises on a beaucoup fait, quand on a montré sa bonne volonté
En grands plaids, petits faits
En guerre comme en amour, pour en finir il faut se voir de près
En hiver au feu et en été au bois et au jeu
En hiver partout pleut, en été là où Dieu veut
En hiver, bonne soupe et vin chaud
En janvier le médecin perd et le fossoyeur gagne
En jeunes gens nulle foi n’est trouvée
En jouant on perd argent et temps
En jouant, le temps se passe ; sage est qui bien le compasse
En juin, de trois habits l’un
En justice tu gagnes une poule et tu perds une brebis
En la balance l’or et le fer font tout un poids pareil et per
En la bouche de l’homme ayant faim, n’entre de froment chacun grain
En la bouche du discret, le public est secret
En la cour du roi, chacun y est pour soi
En la fin connaît-on le bon et le fin
En la fin gît la difficulté
En la fin se chante le Gloria
En la maison Robin de la Vallée n’y a pot au feu ni écuelle lavée
En la maison de ton ennemi, tiens une femme pour ton ami
En la maison du ménestrier, tous sont danseurs
En la maison vaut mieux avoir fontaine que citerne
En la peau de brebis, ce que tu veux s’y écrit
En la peau où le loup est, il y meurt
En la peinture ne gît la figure
En la queue et en la fin, gît de coutume le venin
En la terre des aveugles, celui qui n’a qu’un œil y est roi
En larmes de félon ne se doit nul fier
En lit de chien n’a point d’ointure
En longue voie paille poise
En l’absence du Seigneur, se connaît le serviteur
En l’air pur et clair, se forme le son clair
En l’alphabet, il y a des lettres plus riches les unes que les autres
En l’entreprise du mariage, chacun doit être arbitre de ses propres pensées, et de soi-même prendre conseil
En mai, vin et blé naît
En maigre poil (y) a morsure
En maigre taverne la mouche ne s’hiverne
En maison neuve, qui n’y porte rien n’y trouve
En maison sans bois ni laine, qui n’en apporte pas ne cène
En mal encombrier, patience vaut bouclier
En mal faisant, pensez-y bien, le temps s’en va et la mort vient
En malfait ne gît qu’amende
En mangeant on perd l’appétit, en buvant trop on perd l’esprit
En marchant lentement, nous irons vite
En mariage trompe qui peut
En mariage, comme ailleurs, contentement passe richesse
En matière de sédition, tout ce qui la fait croire l’augmente
En matière d’aumône, il faut fermer la bouche et ouvrir le cœur
En mauvais voisinage se loge-t-on
En mer calme, tous sont pilotes
En moissonnant se passe l’août
En ménage (il) faut savoir manger à la même écuelle
En mêlant le bon et le mauvais, on a le passable
En ne s’emportant pas, on se porte mieux
En neuf minutes le rhume se prend, en neuf semaines il se rend
En nulle contrée ne doit pas être le disciple par-dessus le maître
En parlant du larron, il se trouve derrière le buisson
En parlant, long chemin se raccourcit
En pauvre maison, braise ni tison
En pauvreté n’y a pas grande loyauté
En payant ses dettes on s’enrichit
En pays étranger, les vaches y battent les bœufs
En petit buisson trouve-t-on grand lièvre
En petit champ croît bien blé
En petit corps gît bien un cœur valeureux
En petite cheminée on fait grand feu, et en grande petit feu
En petite maison, la part de Dieu est grande
En petite tête gît grand sens
En peu de temps il advient beaucoup de choses
En peu d’heure Dieu labeure
En place du jeune merle on prend une vieille grive
En plongeant au fond des voluptés, on en rapporte plus de gravier que de perles
En politique comme en amour, il n’y a point de traités de paix, ce ne sont que des trêves’
En procès n’y a point d’amour
En péril et nécessité, prudence est élire sûreté
En remettant les affaires de jour à autre, la mort nous surprend
En rien faisant on a plus de peine qu’en travaillant
En santé et prospérité, facilement nous conseillons autrui
En se cuidant trop près chauffer on se ard
En se moquant dit-on bien vrai
En se taisant, le sot est sage et le sage est sot
En semant, ne pense pas aux pigeons
En septembre, si tu es prudent, achète grains et vêtements
En soi moquant dit-on bien vrai
En son pays nul n’est nommé prophète
En soufflant on allume la chandelle et on l’éteint aussi
En souhaitant nul n’enrichit
En souvent chamaillant le soldat devient aguerri
En suivant le fleuve, on parvient à la mer
En ta santé pas ne te fie, la mort à coup ravit la vie
En ta vie ne te fie
En tant de pays tant de guises
En taverne pas ne t’hiverne, car c’est une dangereuse caverne
En te faisant naître nu, la nature t’avertit de supporter patiemment le fardeau de la pauvreté
En tel peau qu’a le loup quand il naît, mourir lui échet
En temps de famine il n’est pas de pain dur
En temps et lieu on doit tout faire
En temps et saison convient la répréhension
En tous temps fait-il bon bien faire
En tout bien tout honneur
En tout ce qu’avons de faire, le fait plus que dire est nécessaire
En tout pays il y a une lieue de mauvais chemin
En tout temps et toute heure, la mort est prête et meure
En tout temps fait-il bon bien faire
En tout temps le sage veille
En toute chose faut-il commencement
En toute part on prise l’art
En toute saison doit dominer raison
En toute saison femme est bien à la maison
En toutes choses aie mesure
En toutes choses il te faut diligemment préparer
En toutes choses un homme n’est complet
En toutes choses y a mesure
En trinité gît perfection
En trop bonne garde perd-on bien
En trop fier (il y) a danger
En trop parler n’y a pas raison
En trésor gît le cœur très ord
En tyrannisant on se tyrannise
En un corps grand, bien rarement sagesse prend son hébergement
En un long voyage, la paille même est à charge
En une belle gaine d’or couteau de plomb gît et dort
En une heure vient et va l’honneur
En une main il tient le pain, en l’autre le bâton
En une étroite couche, le sage au milieu se couche
En vain plante et sème, qui ne clôt et ne ferme
En vain veut-on chose impossible
En vaisseau ord et mal lavé, vin corrompu et tôt gâté
En vieille granche bat-on bien, mais de vieux fléaux on ne fait rien
En vieille maison, il y a toujours quelque gouttière
En vieillissant, on devient plus fou et plus sage
En vieillissant, on perd toutes ses forces
En vin saveur, en drap couleur, en fille pudeur
En virant et en tournant, on arrive au bout de l’an
En vivant l’on devient vieux
En voulant avoir tout, on perd tout
En voyage et en mariage, ne prends conseil de personne
En été comme en hiver, qui quitte sa place la perd
En été mieux vaut suer que trembler
En été à l’ombre et en hiver au soleil
Encore avec état, on a prou peine à vivre
Encore bien que le renard change son poil, il ne change pas son naturel
Encore fait-il bon avoir des amis en ennemis
Encore n’est pas couché qui aura masle nuit
Endurer faut pour mieux avoir
Enfant brûlé a peur du feu
Enfant et poisson, en eau croît
Enfant et rire, richesse de pauvre
Enfant grandet, adolescent jeune, homme parfait, vieil décrepité
Enfant haï ne sera jamais beau
Enfant humble en jeunesse, heureux en vieillesse
Enfant nourri de vin et femme qui parle latin ne font jamais bonne fin
Enfant par trop caressé, mal appris et pis réglé
Enfants deviennent gens
Enfants et sots sont devins
Enfants illégitimes, sont du tout bon ou du tout mauvais
Enfants nous naissons, enfants nous revenons
Enfants sont richesse de pauvres gens
Enfermer le loup dans la bergerie
Enfoncer les fenêtres ouvertes
Engraisser de mal avoir
Ennemi ne dort
Ennui le jour prolonge
Ennui ne porte point de fruit
Ennui nuit, jour et nuit
Enseigne l’ignorant, il deviendra ton ennemi
Enseigner convient aux enfants, ce qu’est de faire quand seront grands
Entend premier, parle le dernier
Entendement vaut mieux que fortune
Entendre (Il faut entendre) les deux sons de cloche
Entre Pâques et la Pentecôte, le dessert est une croûte
Entre amis la nappe est inutile
Entre bouche et cuiller, vient grand encombrier
Entre bride et éperon, en toute chose gît la raison
Entre chair et ongle, piquer ne dois cousin ni oncle
Entre chien et loup
Entre choisir et non choisir, la fille tarde à s’établir
Entre ci et l’année qui vient, il se passera beaucoup de jours sereins et pluvieux
Entre deux amis n’a que deux paroles
Entre deux de pareil état, par l’huis étroit sort le débat
Entre deux maux, il faut choisir le moindre
Entre deux montagnes vallée
Entre deux selles le cul choit à terre Variante
Entre deux vertes une mûre
Entre esprit et talent, il y a la proportion du tout à sa partie
Entre faire et dire, (y) a moult à redire
Entre gens de même nature, l’amitié s’entretient et dure
Entre haie et buisson, fait mal dire sa raison
Entre homme et femme le diable danse au milieu
Entre la Toussaint et Noël, ne peut trop pleuvoir ni venter
Entre la chair et la chemise, il faut cacher le bien que l’on fait
Entre la coupe et les lèvres il peut se passer bien des choses
Entre la merde et l’urine, le bel enfant se nourrit
Entre la poire et le fromage
Entre le bon sens et le bon goût, il y a la différence de la cause à son effet
Entre le dit et le fait y a grand trait
Entre les deux Notre-Dame, les œufs sont infécondés
Entre les fiançailles et la noce le diable court
Entre les verres et les pots, moins de sages que de sots
Entre l’arbre et l’écorce il ne faut pas mettre le doigt
Entre l’enclume et le marteau, qui doigt y fourre est tenu veau
Entre l’âme et le corps, souvent désaccord
Entre l’écorce et le bois, ne faut pas mettre le doigt
Entre l’écuelle et le pot, il ne faut pas mettre le doigt
Entre mari et femme ne t’y mets pas, même pour un bien
Entre mariage et regret il n’y a que l’épaisseur d’une haie ; si l’on y regarde de près il n’y a que l’épaisseur d’un sabot
Entre nous fols qui plaidoyons les praticiens nous nourrissons
Entre nous soit dit, se disent les femmes quand elles ont tout dit
Entre presque ou et oui, il y a tout un monde
Entre promesse et l’effet, y a grand trait
Entre promettre et donner, doit-on sa fille marier
Entre sept et huit heures filles et femmes couchées, à neuf heures les hommes
Entre trop et trop peu est la juste mesure
Entreprenez doucement, mais poursuivez chaudement
Entretemps que le chien chie le loup s’en va
Envie aux grands fait la guerre et si elle peut les atterre
Envie choit-on de franchise en servage
Envie de se marier et vivre longtemps, à chaque Jean et chaque Catherine, ils sont mariés et ils vivent longtemps et ils voudraient revenir sur leurs pas
Envie en tout art est en vie
Envie ne mourut oncques, mais les envieux mourront
Envier, c’est se reconnaître inférieur
Epargne de bouche vaut rente de pré
Epouse joyeuse est souvent femme pleureuse
Erreur n’est pas crime
Espoir conduit l’homme tant qu’il soit vieux
Espoir de gain diminue la peine
Espoir de profit labeur diminue
Espoir en Dieu convient avoir, car elle vaut mieux qu’or ni (ou) avoir
Espère en Dieu en chaque lieu
Espérance ne donne à boire ni à manger
Espérant proie, plusieurs amis sont qui au partir sont ennemis
Espérer prendre des alouettes à la chute du ciel
Essaim de mai vaut vache à lait
Essuie tes mains convenablement, si tu ne veux pas qu’elles se gercent
Est bien malade qui ne connaît pas la gravité de son mal
Est bon de jeûner, mieux d’aumône donner
Est heureux plus qu’il ne croit, celui qui paie ce qu’il doit
Est pas tout or ce qui brille
Estimer quelqu’un, c’est l’égaler à soi
Et c’est être innocent que d’être malheureux
Et plus (il) y a de chevaux en une étable et plus (il) y a de (la) fiente
Et plus a le diable et plus veut avoir
Et plus a l’homme d’esprit en ce monde et plus est damné
Et plus boit-on et plus voudra-t-on boire
Et plus de morts et moins d’ennemis
Et plus demeure-t-on aux services et plus est-on fol
Et plus est noble un homme et plus est ambitieux
Et plus met-on de paille en l’étable et plus y a de fumier
Et plus vit-on et plus voit-on
Et plus y a de faucheurs et moins y a (à) faucher
Exercice est au corps et à l’âme grand bénéfice
Exercice, à l’âme et corps est bénéfice
Exhibe honneur à ton parent, en te montrant bénévolent
Expérience est mère de science
Eût-il tort, le maître a toujours raison
Face d’homme porte vertu
Facile c’est de penser, difficile est pensée jeter
Fagot a bien rencontré bourrée
Fagot a bien trouvé bourrée
Fagot bien lié est à moitié porté
Faillir ne peut terre bien cultivée
Faim en santé, grande maladie
Faim, pluie et femme sans raison, chassent l’homme de la maison
Fainéant et misère se marièrent, ils eurent un enfant qui s’appela souffre-douleur
Faire Pâques avant les Rameaux
Faire attendre un bienfait, c’est couver un ingrat
Faire avaler le goujon à quelqu’un
Faire beaucoup de bruit pour peu de laine
Faire boire un âne qui n’a pas soif, c’est perdre son temps
Faire bonne chère est de grand coût et de petite mémoire
Faire bonne mise à mauvais jeu
Faire contre mauvaise Fortune, bon cœur est un soutien
Faire convient en sa jeunesse, provision pour la vieillesse, de chose qui est nécessaire et dont on peut avoir à faire
Faire de cent sous quatre livres et de quatre livres rien
Faire de nécessité vertu
Faire de sa pâte gâteau
Faire des châteaux en Espagne
Faire du bois pour clôturer un champ d’orties
Faire du loup le berger
Faire d’un diable deux
Faire d’un néant grande cause
Faire envie vaut mieux que faire pitié
Faire et défaire c’est toujours travailler, mais ce n’est pas gros avancer
Faire haie d’épines à mains nues
Faire la cour et l’amour, peine et dolour (douleur) nuit et jour
Faire le carnaval avec sa femme et Pâques avec son curé
Faire le gros dos
Faire litière d’une chose
Faire l’aumône, c’est prêter au bon Dieu
Faire l’enfant
Faire passer le goût du pain à quelqu’un
Faire ses choux gras de quelque chose
Faire ses orges
Faire son paradis en ce monde
Faire un trou dans l’eau
Faire une croix par-dessus l’épaule
Fais bien sans cesse et sans demeure, en peu de temps se passe l’heure
Fais bien tandis que tu es vivant
Fais bien à ton prochain avant ta mort, car rien ne te vaudra quand seras mort
Fais ce que dois, advienne que pourra
Fais ce que je dis, ne fais pas ce que je fais
Fais ce que tu veux, mais sois le premier
Fais ce que voudras avoir fait quand tu mourras
Fais comme tu voudras, comme tu feras ton lit tu te coucheras
Fais comme tu voudras, tu feras jamais à la guise de tout le monde
Fais comme votre âne qui ne boit qu’à sa soif
Fais de la nuit nuit et du jour jour, et vivras sans ennui et dolour
Fais de l’ami comme de l’or, ne le reçois pas sans l’avoir reconnu
Fais de ta bouche une prison, pour mettre ta langue à la raison
Fais des amis non pas lorsque tu en as besoin, mais pour lorsque tu en auras affaire
Fais du bien à un pauvre bougre, il te chie dans la main
Fais du bien à un vilain, il te chie dans la main
Fais et fasse bonne farine sans sonner trompe ni bucine
Fais la porte de ta maison à l’orient si tu veux qu’elle soit saine
Fais premier le nécessaire, puis ce qui est à plaisir faut faire
Fais ton devoir et arrive que pourra
Fais ton devoir et laisse dire les sots
Fais ton devoir et laisse faire le Bon Dieu
Fais ton devoir et puis tant pis pour le reste
Fais ton devoir, quand bien t’en coûterait gros
Fais ton huis au silvain, si tu veux vivre sain
Fais toujours bien, fera mieux qui pourra
Fais une dette payable à Pâques, et trouveras le carême court
Fais-toi agneau, le loup te mangera
Fais-toi lécher par le chien qui t’a mordu
Faisant son office la balance, d’or ni de plomb n’a connaissance
Faiseur de mariages, maudit sans avantages
Faisons ce qu’on doit faire, et non pas ce qu’on fait
Faisons de nécessité vertu et de mal jour fête
Faisons des ponts pour lorsque nous aurons des chèvres
Fait beau venir vieux, mais fait mal l’être
Fait bon boire quand on a soif
Fait bon venir vieux, mais fait mal s’y trouver
Fait mal servir les paresseux
Fait plus plaisir de donner que de recevoir
Fait ton fait et te connais
Fait toujours bon tenir son cheval par la bride
Faites bien faites mal, vous serez toujours critiqué
Faites ce que vous commandez et vos serviteurs seront payés
Faites du bien à un chien, il vous chie dans la main
Faites du bien à un chien, il vous pisse contre
Faites du bien à un vilain, il vous fera dans la main
Faites la lessive à temps ou le linge devient comme du fumier
Faites l’aumône non pas à l’individu, mais à l’homme
Faites soudain les choses conseillées
Faites une légère écorchure au bout de votre doigt, à chaque instant vous y trébuchez
Faites votre devoir et laissez faire aux dieux
Faites-le court, dépêchez-vous de dire ce que vous voulez
Faites-vous des amis avec les richesses d’iniquité
Fange sèche, envie s’attache
Farine fraîche et pain chaud font la ruine de la maison
Farine fraîche et pain chaud n’enrichissent pas la maison
Farine fraîche et pain tendre aident la maison à descendre
Faudrait croire que la moitié de ce qu’on voit
Faudrait rien croire de ce qu’on entend
Fausseté est prochaine à la vérité, comme adversité à prosperité
Faut accrocher les oiseaux devant (avant) qu’ils (ne) soient hors du nid
Faut aller (vivre) d’après ses moyens
Faut aller doucement, comme l’argent vient
Faut attendre pour voir
Faut avoir assez boue pour son compte pour salir les autres
Faut avoir de la boue pour salir les autres
Faut avoir mangé ensemble une mine de sel pour dire se connaître
Faut avoir à manger pour pouvoir travailler
Faut avoir égard aux autres comme à soi-même
Faut balayer devant chez soi avant de balayer devant chez les autres
Faut battre le fer pendant qu’il est chaud
Faut bien des petits pour un grand
Faut bien manger et bien travailler pour bien servir son maître
Faut boire le vin comme un roi et l’eau comme un taureau
Faut commencer jeune pour (de)venir bon maître
Faut connaître les saints avant de les adorer
Faut coucher sept ans avec sa femme avant de la connaître
Faut croire ce que disent les prêtres mais faut pas faire ce qu’ils font
Faut de tout pour faire un monde
Faut de toutes sortes de choses pour faire un monde
Faut de toutes sortes de gens pour faire un monde
Faut donner aux riches, les pauvres feront toujours
Faut dresser l’arbre pendant qu’il est jeune
Faut dresser l’arbre pendant qu’il est temps
Faut faire les chevilles avec le bois qu’on a
Faut faire suivant son argent
Faut faire vie qui dure mais pas vie qui crève
Faut gagner son pain soi-même pour savoir combien il coûte
Faut garder une poire pour la soif
Faut jamais aller bâtir à côté d’un château
Faut jamais dire hue qu’on eut passe le ru
Faut jamais se battre pour ce qui est suffisant
Faut jamais se battre pour ce qu’il y a assez
Faut jamais se décourager
Faut juger chacun de manière que le loup soit logé repu et la chèvre entière
Faut jurer de rien
Faut laisser aller le monde comme (il) va
Faut laisser le chien quand il dort ; quand il est réveillé, il mord
Faut laisser les ministres parler et les chevriers garder les chèvres
Faut laisser pour ce qu’ils sont
Faut partout une mesure
Faut pas aller au bois si on a peur des branches
Faut pas apprendre aux vieux chats à attraper les souris
Faut pas attendre que soient gros les arbres pour détordre
Faut pas boire quand on a pas soif
Faut pas déranger les guêpes
Faut pas désavouer son cul pour un pet
Faut pas en prendre plus qu’on peut en emporter
Faut pas enseigner à chier à ceux qui ont la diarrhée
Faut pas enseigner à faire des enfants aux mères
Faut pas entreprendre plus qu’on (ne) peut
Faut pas exciter le guêpier si on veut pas être piqué
Faut pas faire emplette d’un porc de laitier ni d’une fille de cabaretier
Faut pas faire les gros que d’après ce qu’on a
Faut pas gaspiller le bien de Dieu
Faut pas laisser tomber le bâton trop vite
Faut pas manger le bien tandis qu’on a de bonnes dents
Faut pas manger son bien tandis qu’on a de bonnes dents
Faut pas marier des crétins pour la fortune
Faut pas mettre la chèvre avec le chou
Faut pas mettre la main au cul après qu’on a pété
Faut pas mettre le feu à côté de la paille
Faut pas mettre le feu à la paille quand il n’a pas besoin
Faut pas mettre tous ses œufs dans le même nid
Faut pas ourdir plus qu’on ne peut tramer
Faut pas ourdir plus qu’on peut taper
Faut pas parler de corde dans la maison du pendu
Faut pas plaindre le cheval qui tombe mais celui qui ne se relève pas
Faut pas plus charger l’âne qu’il peut porter
Faut pas prendre les gens pour des chiens
Faut pas prendre un bâton pourri pour frapper sur les autres
Faut pas péter plus haut qu’on a le cul
Faut pas que la bouche devance les bras
Faut pas que les attaches du bonnet soient encore marquées pour songer à se marier
Faut pas regarder dans la gorge d’un cheval donné
Faut pas remettre au lendemain ce qu’on peut faire le jour avant
Faut pas renvoyer à demain ce qu’on peut faire aujourd’hui
Faut pas se charger de bois vert quand il y en a assez de sec
Faut pas se charger envie de ce qu’on peut pas avoir
Faut pas se croire que le bon fusse rien que d’un côté
Faut pas se déchausser avant que d’aller dormir
Faut pas se dépouiller avant qu’aller dormir ; faut pas se défaire du bien, avant que mourir
Faut pas se déshabiller avant de se coucher
Faut pas se dévêtir avant de s’aller coucher
Faut pas se dévêtir avant que de vouloir aller dormir
Faut pas se dévêtir avant que d’aller dormir
Faut pas se dévêtir trop vite et pas se vêtir trop vite
Faut pas se faire des amis avec des gens qui sont moins que soi
Faut pas se griffer le nez pour se faire beau le visage
Faut pas se laisser manger la laine sur les reins
Faut pas se marier ni à la tenda (attente) ni à la ventura
Faut pas se tenir à la gueule du loup
Faut pas tailler des verges pour se faire à fesser
Faut pas tenir les lapins dans la choulière
Faut pas tirer la chemise avant qu’aller dormir
Faut pas vendre la peau de l’ours avant de l’avoir tué
Faut pas vendre la peau du loup avant de l’avoir tué
Faut pas vendre la peau du loup avant d’avoir tiré la bête
Faut pas verser d’eau sur le feu
Faut pas vouloir péter plus haut qu’on a le cul
Faut peu de lois aux avocats pour amorcer force ducats
Faut peu parler, beaucoup écouter
Faut prendre le bien quand il vient
Faut prendre le temps comme il vient et les femmes comme elles sont
Faut que chacun porte sa croix sur cette terre
Faut que marier une tailleuse pour aller guenilleux et un régent pour crever de faim
Faut que tout le monde vive
Faut que toutes les cartes jouent
Faut qu’avoir de l’argent pour être souhaité mort
Faut qu’une (seule) brebis gâtée pour perdre tout le troupeau
Faut reculer pour mieux sauter
Faut regarder ce qui cuit en sa marmite avant que regarder ce qui cuit en celle des autres
Faut regarder de quel pain on mange
Faut rendre le bien pour le mal
Faut rien croire que ce qu’on voit
Faut rien gaspiller
Faut rien laisser perdre
Faut savoir bien obéir pour savoir bien commander
Faut savoir perdre pour pouvoir gagner
Faut savoir perdre si on veut gagner
Faut savoir se contenter de ce qu’on a
Faut savoir s’arrêter du temps que va bien
Faut se fier de tous et de personne
Faut se tirer près de la courtine pour avoir le purin
Faut semer pour cueillir
Faut semer pour ramasser
Faut songer à nourrir avant de songer à mourir
Faut souvent mettre la vergogne derrière la porte
Faut s’adresser aux parents quand on a besoin de rien
Faut toujours avoir quelque chose à manger avec son pain
Faut toujours bien faire, on peut quitter quand on veut
Faut toujours bien manier avant de traire
Faut toujours commencer un coup pour pouvoir finir
Faut toujours commencer un coup, si on veut finir une fois
Faut toujours espérer le bien, le mal arrive déjà assez
Faut toujours garder une poire pour la soif
Faut toujours payer l’apprentissage
Faut toujours prendre la chose du bon biais
Faut toujours prendre le bien quand il vient ; il ne vient déjà pas trop souvent
Faut toujours prendre patience
Faut toujours se tirer près des vieux, les jeunes ont rien d’argent
Faut toujours songer à soi avant de songer aux autres
Faut tourner sept fois la langue dans la bouche avant de parler
Faut tous aller (mourir) un jour
Faut tout le temps garder une pomme pour la soif
Faut un désordre pour amener un ordre
Faut vivre sur l’espérance
Faut voir plus loin qu’on a le nez
Faut être content de ce qu’on a
Faut être de son temps
Faut être deux pour faire un marché
Faut être quatre jours pendu, quatre jours dépendu avant de se marier
Faut être à ses noces pour qu’elles soient belles
Faute avouée est à moitié pardonnée
Faute de bien fait dormir sur le sien
Faute de blé, on mange de l’avoine
Faute de bois, le feu s’éteint ; éloignez le rapporteur, et la querelle s’apaise
Faute de cheval on se sert d’âne
Faute de crédit et d’accroire, engarde l’homme d’aller boire
Faute de crédit et d’argent, rend l’homme triste, morne et dolent
Faute de grives, on mange des merles
Faute de justice, absence de roi, présage méchef et grand désarroi
Faute de pain n’assouvit pas la faim
Faute de parler, on meurt sans confession
Faute de puissance, le malin n’offense
Faute d’adresse, la bourse blesse
Faute d’argent est par dit et par fait, vrai ennemi familier et parfait
Faute d’argent n’emplit pas la bouteille, ainsi rend l’homme tremblant comme la feille
Faute d’argent, c’est douleur non pareille
Faute d’argent, défaut de joie
Faute d’argent, honte d’accroire, défend l’homme d’aller boire
Faute d’expérience et d’usage, d’âge cause le jeune n’être sage
Faute d’un clou on perdit le cheval
Faute d’un moine, l’abbaye ne chôme pas
Faveur à maints a porté préjudice, là où elle est ne règne point justice
Faveur à maints a porté préjudice, là où il ne règne point justice
Faveurs, femmes et deniers font de vachers chevaliers
Femme acariâtre, bois vert et pain chaud ont bientôt conduit l’homme au tombeau
Femme acariâtre, femme de bal, peu de besogne et la fait mal
Femme accomplie, trois fois discrète
Femme bien élevée aura toujours bonne tenue
Femme bonne et sage, fait toujours bon ménage
Femme bonne qui a mauvais mari, a bien souvent le cœur marri
Femme bonne qui a mauvais mari, a souvent le cœur marri
Femme bonne vaut un empire, qui l’a mauvaise garde qu’elle n’empire
Femme bonne vaut une couronne
Femme bonne vaut une couronne, femme de bien vaut un grand bien
Femme couchée et bois debout, homme n’en vit jamais le bout
Femme couchée et bois debout, on ne sait pas ce que ça peut porter
Femme couchée et bois debout, on n’en voit jamais le bout
Femme couchée et fagot debout, l’homme n’en vit jamis le bout
Femme couchée, fagot debout, homme n’en voit jamais le bout
Femme coureuse, pas du tout ménagère
Femme coureuse, soupe froide
Femme curieuse et courrière, n’est en rien bonne ménagère
Femme de bien vaut un grand bien
Femme de devant chagrin et tourment, femme de derrière pain à manger
Femme de marin, femme de chagrin
Femme de marinier, ni mariée ni demi mariée
Femme de maçon, mariée le matin le soir non
Femme de riche vêtement parée, à un fumier est comparée, qui devers fait sa couverture, au découvrir apert l’ordure
Femme de vin, femme de rien
Femme dorée est vite consolée
Femme d’aubergiste qui file, médecin qui se regarde au miroir, notaire qui ne sait pas le quantième des mois, mauvais pour tous les trois
Femme enivrée est à tous abandonnée
Femme estime toujours son voisin être de violette
Femme et baril, plus ils travaillent mieux ils valent
Femme et boisson sont deux ruine-maisons
Femme et chevaux, Il n’y en a pas sans défauts
Femme et châtaigne, belle en dehors, en dedans la malice
Femme et dentelle, sont plus belles à la chandelle
Femme et drap(s), ne les achetez pas à la chandelle
Femme et gélines, par trop aller dehors s’égarent
Femme et lune, aujourd’hui sereines demain brunes
Femme et melon, à peine les connaît-on
Femme et mule par la douceur, âne et valet par la rigueur
Femme et niais ne pardonnent jamais
Femme et toile, ne les achète pas à la chandelle
Femme et toile, ne les regarde pas à la chandelle
Femme et vin ennivrent les plus fins
Femme et vin ont leur venin
Femme fait et défait la maison
Femme fait souvent la fâchée dans le but d’être caressée
Femme fardée n’a pas de durée
Femme fardée, pomme ridée et ciel pommelé, ne sont pas de longue durée
Femme fenêtrière n’est pas ménagère
Femme fenêtrière, champ au bord d’une rivière, vigne au bord d’un chemin, ont toujours eu mauvaise fin
Femme fenêtrière, champ sur rivière et vigne sur chemin, ont toujours mauvaise fin
Femme fenêtrière, femme fainéante
Femme fort belle, rude et rebelle
Femme gourmande, au bout de l’an mange son patrimoine
Femme grosse, un pied dans la fosse
Femme ivrogneresse, de son corps n’est point maîtresse
Femme jolie et mari jaloux n’ont pas de repos
Femme jolie, miroir de fou
Femme laide, bien gardée
Femme lécheresse ne fera jamais porée épaisse
Femme lécheresse ne fera tôt porée épaisse
Femme mariée qui va coquettement parée, mérite d’être huée
Femme muette ne fut jamais battue
Femme muette n’a jamais été battue
Femme muette n’est jamais battue
Femme ménagère vaut un trésor
Femme mûre attend aventure
Femme ne veut être tenue en cage
Femme oiseuse ne peut pas être vertueuse
Femme orgueilleuse se difforme en délaissant sa propre forme
Femme parlant latin, enfant nourri de vin, ne font pas bonne fin
Femme prudente et sage, est l’ornement du ménage
Femme près de la fenêtre, champ près d’une rivière, vigne près d’un chemin, ont toujours fait de mauvais résultats
Femme qui a mauvais mari, a bien souvent le cœur marri
Femme qui a un bon mari, au visage ou à la porte c’est écrit
Femme qui aime faire des gâteaux, au bout de l’an mange sa dot
Femme qui aime la galette, pauvre ménagère
Femme qui aime vin rouge et vin blanc aura les joues riches de sang, mais ses affaires iront pauvrement
Femme qui boit du vin, fille qui parle latin vont le plus souvent à mauvaise fin
Femme qui boit du vin, fille qui parle latin, soleil levé trop matin, Dieu sait quelle sera leur fin
Femme qui boit du vin, fille qui parle latin, soleil qui se lève trop matin, Dieu sait quelle sera leur triste fin
Femme qui boit du vin, fille qui parle latin, soleil qui se lève trop matin, ne firent jamais bonne fin
Femme qui boit du vin, fille qui parle latin, vont le plus souvent à mauvaise fin
Femme qui chez soi ne fait rien, en d’autres lieux ne fait pas bien
Femme qui envie (peu) file porte chemise vile
Femme qui fait des galettes, au bout de l’an mange sa dot
Femme qui fait des galettes, pauvre ménagère
Femme qui fait des gâteaux, fille qui rit trop, vigne près d’un chemin, rarement font bonne fin
Femme qui file peu a toujours mauvaise chemise
Femme qui gagne et poule qui pond, ce n’est que bruit dans la maison
Femme qui moult se mire peu file
Femme qui ne mange pas avec vous mange ensuite plus que deux
Femme qui ne mange pas, la boisson la soutient
Femme qui ne mange pas, le boire la soutient
Femme qui ne sait coudre, maison loqueteuse
Femme qui n’en a pas besoin ne doit pas sortir dans la rue
Femme qui n’est fidèle n’a pas long cours
Femme qui parle latin, je ne la veux pas pour moi
Femme qui parle pointu est toute venin
Femme qui parlemente, à demi consent
Femme qui perd honneur et honte, ne sera jamais d’estime ni de compte
Femme qui peu file, porte chemise vile
Femme qui pince ses lèvres est toute venin
Femme qui prend elle se vend, femme qui donne s’abandonne
Femme qui prend se rend, donne s’abandonne
Femme qui rit facilement pleure facilement
Femme qui rit, bientôt dans ton lit
Femme qui se meurt d’amour, c’est chercher la lune en plein jour
Femme qui se pare, au bout de l’an mange sa dot
Femme qui ses lèvres mord et par la rue son aller tord, elle montre qu’elle est du métier ord où ses manières lui font tort
Femme qui siffle et poule qui contrefait le coq, sont préludes de catastrophe
Femme qui siffle et poule qui fait le coq, sont préludes de grands maux
Femme qui siffle, homme qui tâte les poules, poule qui chante le coq, c’est trois bêtes de trop
Femme qui tourtelle, femme qui beignetelle, femme qui bricelle, amène à pauvreté sa maison
Femme qui trompe son mari fait jurer à l’amant de ne pas la trahir
Femme qui écoute et ville qui parlemente sont bientôt prises
Femme riche est vite consolée
Femme rit quand elle peut, et pleure quand elle veut
Femme safre et ivrogneresse, de son corps n’est pas maîtresse
Femme sage et de façon, de peu remplit sa maison
Femme sage reste à la maison
Femme sage reste à son ménage
Femme sait un art avant le diable
Femme sale a tôt trouvé de l’eau
Femme sans rime ni raison, chasse l’homme de sa maison
Femme sans soin et sans souci ne vaut pas sous six
Femme sans vice, curé sans caprice et meunier fidèle, c’est trois miracles du ciel
Femme se plaint, femme geint, est malade quand il lui plaît
Femme se plaint, femme gémit, est malade quand il lui plaît
Femme se plaint, femme se deut, femme est malade quand elle veut
Femme se plaint, femme s’afflige, femme est malade quand elle veut
Femme sotte se connaît à la cotte
Femme sotte se connaît à la toque
Femme sotte, se connaît à la cotte
Femme tentée et femme vaincue, c’est tout un
Femme toute par elle fait tout, deux font peu et puis trois rien
Femme travailleuse, homme content
Femme travailleuse, homme heureux
Femme trop piteuse fait souvent fille teigneuse
Femme trop piteuse fait souvent sa fille teigneuse
Femme trop piteuse, rend sa fille teigneuse
Femme vaillante, maison d’or
Femme veut en toute saison être dame en sa maison
Femme veut en toute saison être maîtresse en sa maison
Femme veut en toute saison, être dame en sa maison
Femme à bague, promise ou mariée
Femme à la fenêtre, terre à côté du pont, vigne près du chemin, n’ont jamais fait bonne fin
Femme économe est un trésor, femme alerte vaut son pesant d’or
Femme économe fait la maison bonne
Femme, de riche vêtement parée, à un fumier est comparée, qui devers fait sa couverture, au découvrir apert l’ordure
Femme, fumée et tuille non entière, chassent l’homme de sa maison arrière
Femme, lit, argent et vin, ont leur poison et venin
Femme, livre et cheval ne se prêtent pas
Femme, lune et vent, changent souvent
Femme, roue et poulie grognent si on ne les oint pas
Femmes et châtaignes, belles en-dehors et dedans la malice
Femmes et ânes, ruine des maisons
Femmes sont comme le temps, après la pluie le beau temps
Femmes sont à l’église saintes, ès rues anges, en la maison diablesses, crapauds aux fenêtres, pieds à la porte, aux jardins chèvres
Femmes, enfants, fols et malades, affectent ce que leur est nuisible
Femmes, roues et poulies mal graissées sont criardes
Fendre un cheveu en quatre
Fends du sapin, tu auras de la résine aux mains
Ferrer la mule
Ferrée jument glisse
Feu bien couvert (comme dit ma bru), par sa cendre est entretenu
Feu d’amour et bois vert, mettent la maison à l’envers
Feu d’amour et feu de bois vert, mettent la maison à l’envers
Feu d’étoupes et feu d’étraint, bientôt épris, à coup éteint
Feu qui brûle n’a pas besoin d’être soufflé
Feu sans creux, gâteau sans mioche et bourse sans argent, ne vaillent pas gramment
Feu sans fosse, homme sans argent, ne valent gramment
Feu, argent, sagesse et santé, sont en prix hiver et été
Feu, fèvres, argent et bois, sont bons en tous mois
Fi de jeunesse et de beauté, où il n’y a humilité
Fi de la pute médecine, qui l’homme à la mort enchemine
Fi de l’art qui en raison n’a fondement ni part
Fi de manteau quand il fait beau
Fi de richesse qui n’a joie
Fi de richesse, d’état, d’argent et d’or, qui de vertu n’aime le trésor
Fi d’argent qui n’a joie
Fie-toi au diable, il te prendra
Fie-toi de tous et donne-toi garde de tous
Fiente de chien et marc d’argent, seront tout un au jour du jugement
Fier comme un Écossais, fier comme Artaban
Fier n’a que perdre !
Fierté sans beauté c’est un tronc habillé
Figues de chat et marc d’argent, seront tout un au jugement
Fille aimant silence a grande science
Fille attifée, moitie mariée
Fille bien ajustée, à demi mariée
Fille bonne à marier, est difficile à garder
Fille brunette est de nature gaie et nette
Fille brunette, de nature gaie et nette
Fille cachée est recherchée
Fille comme elle est élevée, étoupe comme elle est filée
Fille comme on l’a élevée, étoupe comme on l’a filée
Fille coureuse et fenêtrière, rarement bonne ménagère
Fille coureuse et souvent à la fenêtre est rarement bonne ménagère
Fille de bonne façon, fait plaisir et avec raison
Fille de bonne maison, a la chemise plus longue que le jupon
Fille d’auberge et cochon de meunier, laisse-les à qui les a élevés
Fille d’auberge et figue de chemin, si elles ne sont touchées aujourd’hui, le seront demain
Fille d’auberge et figues de chemin, si elles ne sont pas touchées le soir, le sont le matin
Fille d’aubergiste et figue de chemin, si elles ne sont pas goûtées à la vesprée sont mauvaises le matin
Fille d’aubergiste et figue qui se trouve dans un carrefour mûrissent avant la saison
Fille d’aubergiste et poire de carrefour mûrissent avant la saison
Fille d’hôte et figue de canton sont plus mûres que de saison
Fille d’hôte et figue de chemin, si elles ne sont touchées le soir le sont le matin
Fille d’hôtelier et figue de coin mûrissent avant la saison
Fille effrontée ne vaut pas un brin de menthe
Fille est comme la rose, elle est belle quand elle est éclose
Fille et escabelle, à cinquante ans se démantibulent
Fille et gobelet sont toujours en danger
Fille et verre sont toujours en danger
Fille fais-toi des frisettes, sinon tu resteras seulette
Fille fenêtrière et trottière, rarement bonne ménagère
Fille fenêtrière, femme qui sait latin, prêtre qui danse, ne vont jamais à bonne fin
Fille fenêtrière, rarement ménagère
Fille fiancée n’est pas mariée
Fille fiancée n’est pas mariée, car tel fiance qui n’épouse pas
Fille fiancée n’est prise ni laissée
Fille gracieuse est toujours jolie
Fille honnête et bien moriginée, est assez riche et bien dotée
Fille honnête et moriginée est assez riche et bien dotée
Fille jolie sans habits, plus courtisée que mariée
Fille jolie sans habits, plus de galants que de maris
Fille jolie, miroir de fou
Fille laide, beaucoup de toilette
Fille laide, bien parée
Fille maigre avec grosse dot plaît à chaque jeune homme
Fille maigre et dot grasse, à chaque jeune homme plaît
Fille mariée, quarante gendres dans la soirée
Fille mûre porte l’enfant à sa ceinture
Fille ne doit être trop nue, non plus que robe trop vêtue
Fille ni prêtre ne savent où ils ont leur pain
Fille oiseuse, rarement vertueuse
Fille oisive à mal pensive, trop en rue tôt perdue
Fille oisive, à mal pensive
Fille ou poule trop en rue, tôt égarée ou perdue
Fille pleure souvent son rire d’il y a un an
Fille pour son honneur garder, ne doit prendre ni donner
Fille promise n’est point prise
Fille pâle demande le mâle
Fille pâle, garçon jaune de teint, du mariage ont grand besoin
Fille qui accepte des cadeaux se vend
Fille qui agrée est à demi-mariée
Fille qui coure, table qui branle et femme qui parle latin, feront toujours triste fin
Fille qui donne s’abandonne
Fille qui plaît est à demi-mariée
Fille qui plaît est à moitié mariée
Fille qui plaît, à moitié mariée
Fille qui prend elle se vend, fille qui demande est perdue
Fille qui prend se vend
Fille qui prend se vend ou se rend
Fille qui prend se vend, fille qui donne s’abandonne
Fille qui prend, elle se vend, fille qui donne elle s’abandonne
Fille qui reçoit des cadeaux, ou se rend ou se vend
Fille qui rit, tôt pleurera
Fille qui se promène, table qui tremble, femme qui parle latin, auront une triste fin
Fille qui siffle et coq qui pond, seront chassés hors du pays
Fille qui siffle et poule qui chante le coq, méritent d’avoir le cou coupé
Fille qui siffle ou poule qui chante le coq, annoncent un malheur
Fille qui siffle, coq qui pond, portent malheur à une maison
Fille qui siffle, le diable l’écoute
Fille qui siffle, poule qui chante le coq, curé qui danse, sont trois diables ensemble
Fille qui siffle, poule qui saute, eau qui danse, ne valent rien
Fille qui siffle, tords-lui le cou
Fille qui siffle, vache qui beugle comme un taureau, poule qui chante le coq, sont trois bêtes qui méritent la mort
Fille qui siffle, vache qui beugle, poule qui chante le coq, c’est trois bêtes de trop
Fille qui siffle, vache qui beugle, poule qui chante le coq, sont trois bêtes de trop
Fille qui trop se mire peu file
Fille qui veut être prise, ni vue ni visitée
Fille qui veux être prise, ne sois ni trop vue ni trop visitée
Fille qui écoute est bientôt dessous
Fille qui écoute est vite dessous
Fille qui écoute et ville qui parlemente, c’est signe qu’elle se veut rendre
Fille qui écoute, ville qui parlemente, sont bientôt prises
Fille recherchée, fille mal placée
Fille requise est souvent mal mise
Fille riche et jolie, pas plutôt nubile est mariée
Fille sans bonne renommée, paysan sans ferme
Fille sans crainte ne vaut pas un brin de menthe
Fille sans crainte ne vaut rien
Fille sans galant, porc sans glands
Fille sans pudeur ne vaut pas un brin d’herbe
Fille telle comme est élevée et étoupe comme elle est filée
Fille trop en rue, en peu tenue
Fille trop nue, robe trop vêtue, n’est jamais chère tenue
Fille trop nue, robe trop vêtue, n’est pas chère tenue
Fille trotteuse et fenêtrière, rarement bonne ménagère
Fille à marier, cheval à vendre
Fille à se parer, jeune à jouer et banqueter et vieillard à boire, dépensent leur avoir
Fille, fais-toi des frisettes, sinon tu resteras seulette
Fille, lentille et pain chaud, sont la ruine de la maison
Fille, lentille, pain chaud, sont la ruine de la maison
Fille, vigne, poirier et champ de fèves, se gardent difficilement
Filles d’hôte et figues de chemin, si elles ne sont goûtées le soir, le sont le matin
Filles d’hôtes et figues de chemin, sont cueillies soir ou matin
Filles d’hôtes et poires de carrefour sont précoces
Filles et verres, toujours en danger
Filles et épingles sont à qui les trouve
Filles sottes à marier, sont pénibles à bien garder
Filles verrières et verres, sont toujours en grands dangers
Filles à marier, méchant troupeau à garder
Filles à marier, troupeau difficile à garder
Filles, vignes, sont malaisées à garder ; sans cesse quelqu’un passe qui voudrait y goûter
Filles, voyez l’épi de blé
Filles, voyez l’épi de blé, quand il est beau il baisse le nez
Fin comme l’ambre
Fin comme une dague de plomb
Fin contre fin fait pas bonne doublure
Fin contre fin ne vaut rien pour de la doublure
Fin contre fin ne vaut rien pour doublure
Fin à quinze ans, fou à cinquante
Finesse gagne au jeu
Finesse n’est qu’en femme ne soit
Fini de manger, le feu, le lit et le pain
Fièvre de nerfs ne veut ni docteur ni médecine
Flatte un loup, il te veut mordre ; fous-lui un coup de pied au cul, il te veut lécher
Flatteur et ensemble vrai ami, est incompatible par tout pays
Fleur à son côté, amant vite trouvé
Fleurer comme baume
Fleurs de mars, peu de fruits l’on mangera
Foi de femme est une plume sur l’eau
Foi de femme, plume sur l’eau
Fol celui qui dit (du) mal des absents
Fol devise et Dieu départ
Fol est celui qui croit trop de léger
Fol est celui qui dit (du) mal des absents
Fol est et hors du sens, qui femme prend pour son argent
Fol est le marchand qui déprise sa denrée
Fol est le prêtre qui blâme ses reliques
Fol est qui cherche ce que ne se peut trouver
Fol est qui cherche son propre dommage
Fol est qui conseil ne croit
Fol est qui dépense plus que sa rente ne vaut
Fol est qui d’autrui médit, s’il ne regarde à soi
Fol est qui est bien et se bouge
Fol est qui est à cheval, éperonne et dit haie
Fol est qui est à table et n’ose manger
Fol est qui fait de son poing un coin
Fol est qui folâtre et folie
Fol est qui jette à ses pieds ce qu’il tient en ses mains
Fol est qui perd la chair pour les os
Fol est qui plus dépense que sa terre ne vaut
Fol est qui pour le bond perd la volée
Fol est qui pour le futur donne le présent
Fol est qui pour néant se peine
Fol est qui quiert meilleur pain que de froment
Fol est qui se coupe de son propre couteau
Fol est qui se couvre d’un sac mouillé
Fol est qui se fait brebis entre les loups
Fol est qui se fie en eau endormie
Fol est qui se marie à femme étourdie
Fol est qui son bien ne pourchasse
Fol est qui s’enivre de sa propre bouteille
Fol est qui s’oublie
Fol est tenu par tout l’empire, qui a le choix et prend le pire
Fol et félon ne peuvent avoir paix
Fol ne croit jusques à tant qu’il reçoit
Fol ne croit jusqu’à tant qu’il reçoit
Fol ne croit s’il ne reçoit
Fol ne croit tant qu’il reçoit
Fol ne voit en sa folie que sens
Fol n’est jamais sans peine
Fol n’est point sage s’il ne reçoit
Fol prise autant l’huile que le fin baume
Fol qui ne croit jusqu’il prend
Fol qui n’estime son ennemi, tant soit mesquin ou petit
Fol semble sage quand il se tait
Folie est de mettre la charrue devant les bœufs
Folie est d’acheter chat en poche
Folie est d’acheter chat en sac
Folie est mettre la charrue devant les bœufs
Folie faire et folie connaître, ce sont deux paires de folies
Folie faire et folie reconnaître, sont deux paires de folies
Folie faite et folie reconnue sont deux folies
Folle espérance déçoit l’homme
Folle est la quérimonie qui est contre le temps
Folle et simple est la brebis qui au loup se confesse
Folle femme n’aime que pour pâture
Folles amours font les gens bêtes
Folles femmes n’aiment que pour pâture
Fonder sur la glace d’une nuit
Fontaine, je ne boirai de ton eau
Fontaine, je ne veux jamais boire de ton eau
Force diminue la crainte
Force d’argent porte partie
Force fait loi
Force n’a lieu
Force n’est pas droit
Force passe droit
Force restes de velours, peu de demoiselles
Forces, peines et peu de gain, mettent tôt l’homme en mauvais train
Fort contre fort
Fort est qui abat et plus fort est qui se relève
Fort est qui abat, plus fort est qui se relève
Fort vin émeut souvent grande tempête
Fort à la table, lâche à l’ouvrage
Fortune aide aux vaillantes gens
Fortune aveugle suit aveugle hardiesse
Fortune est une nourrice de folie
Fortune fait d’un petit un grand et à coup le dévêt en blanc
Fortune la féconde est facile à trouver et difficile à retenir et garder
Fortune ne vient pas seule
Fortune ne vient seule
Fortune n’avance tant personne que bon conseil et vraie conduite
Fortune n’est jamais en repos, happe qui peut
Fortune peut aider aux fols
Fortune peut touloir la richesse, non la vertu ni la sagesse
Fortune soudainement l’homme monte et puis à coup le renverse et démonte
Fortune tourne en petite heure
Fortune varie comme la lune, aujourd’hui seraine demain brune
Fortune, or claire or brune, ne vient sans autre aucune
Fou ne croit qu’il n’ait appris
Fou ne croit qu’il n’ait pris
Fou ne croit s’il ne reçoit
Fou qui cherche meilleur pain que de froment
Fougère de printemps, temps d’automne
Francs sont moult gentilshommes
Fraîche farine et puis chaud pain, ruinent une maison
Frire la vermine de la pauvreté sur le poêlon de l’amour
Frire la vermine de pauvreté dans le bassin de l’amour
Froides mains, chaudes amours
Fromage et melon, au poids les prend-on
Fromage et pain est médecine au sain
Frotter et laver, cela ne remplit pas les poches
Frottez les bottes à un vilain, il dira que vous les avez brûlées
Frottez une bourrique, elle vous fera des pets
Fruit tôt mûri, bien tôt pourri
Fuir le vice est le commencement de la vertu
Fuir quelqu’un comme une brebis galeuse
Fuis haine, courroux et mensonge
Fuis le vin et le sexe féminin
Fuis loger à qui reçoit mauvais hôte
Fuis mélancolie, tristesse et folie
Fuis paresse, avarice et orgueil
Fuis querelles, noises, procès et altercations
Fumée, pluie et femme sans raison, chassent l’homme de sa maison
Fussiez-vous plus noire qu’une mûre, vous êtes blanche pour qui vous aime
Fuyant le loup, il a rencontré la louve
Fuyez le méchant comme le navire fuit un port dangereux
Fâcherie d’amoureux, renouveau d’amour
Fèves et haricots font plus de pets que de rots
Fèves manger fait gros songer
Février le court, le pire de tout
Février l’ânelier
Fête n’est que de vieux chapons, comme disent tous bons fripons
Fête passée, saint oublié
Gagner de l’argent d’abord, la vertu vient après
Gagner par écus et réhasarder par liards
Gain du cordonnier entre par l’huis et ist par le fumier
Gain facile, folle dépense
Gain illégitime vaut perte
Gains ne sont pas rentes
Gale et amour se voient toujours
Gar le bec qui ne reste au sec
Garde avec extrême diligence, ce dont ne sais la décadence
Garde le bec
Garde seulement une pie, elle te crèvera les yeux
Garde ton porte-monnaie pendant que tu vis
Garde toujours dans la main un sou pour aujourd’hui et deux pour demain
Garde-moi de l’eau douce ; car je me garderai bien de la courante moi-même
Garde-toi de courant d’air, de bouillon réchauffé et de moine défroqué
Garde-toi de l’eau coite
Garde-toi de penser, dire ne (ou) faire, chose à Dieu et à toi contraire
Garde-toi du cru et d’aller à pied nu
Garde-toi d’un pauvre enrichi et d’un riche appauvri
Garde-toi d’une femme qui boit et d’une jument débridée
Garde-toi d’une femme savante comme d’une méchante mule
Garde-toi très bien d’avoir affaire au cautéleux et angulaire
Garde-toi, tant que tu vivras, de juger des gens sur la mine
Garder une poire pour la soif
Gardez les filles comme le lait sur le feu
Gardez vos poules, j’ai lâché mes coqs
Gardez vos poules, nos coqs sont lâchés
Gardez-vous de l’enfant mal ceint
Gardez-vous des faux prophètes déguisés en agneaux, car ce sont des loups ravisseurs
Gars de paille vaut fille d’or
Garçon bien nourri et mal vêtu, fille mal nourrie et bien vêtue
Garçon chaton marie chardon
Garçon de paille vaut fille d’or
Garçon doit être mal vêtu, bien nourri, bien battu
Garçon, si tu veux vivre sûr, n’épouse pas une fille au-dessus de toi
Gaspiller le pain, c’est gaspiller le bien de Dieu
Gay qui braille, que de la volaille
Geler en travaillant et suer en mangeant
Gendre et bru sont gens d’autrui
Gens chauds ont beaucoup de maux
Gens de bien aiment la lumière
Gens de bien aiment le jour et les méchants la nuit
Gens de bien aiment le jour et les méchants quièrent ténèbres
Gens de bien ont toujours bien
Gens de bien portent toujours honneur
Gens de bien se montrent toujours où ils sont
Gens de bien sont toujours gracieux
Gens de lettres, gens de peine
Gens d’états doivent fuir les blasonneurs et toujours être accompagnés d’amis fidèles et sages
Gens qui craignent sont toujours en souci
Gens révérends sont toujours par devant
Gens saouls ne sont pas grand mangeurs
Gent grand, gent fainéant
Gent grand, gent vain ; gent petit, gent courageux
Gent petit, gent courageux
Gentilles repentailles qui se font fiançailles
Gloire vaine fleurit et ne porte grain ni profit
Gloire, jugement et vengeance, réserve Dieu en sa puissance
Glouton ne fût jamais sans peine
Gober des mouches
Gourmandise tue plus de gens qu’épée en guerre tranchante
Goutte bien tracassée est à demi pansée
Goutte sur goutte fait la motte
Goutte sur goutte se fait la motte
Goutte à goutte croît la motte
Goutte à goutte la mer s’égoutte
Goutte à goutte l’eau creuse la pierre
Goutte à goutte on emplit la cuve
Gouverne-toi bien en jeunesse, si roi veux être en ta vieillesse
Gouvernement de jeunesse, labour de taureau, pain chaud, bois vert, d’une bonne maison en font une pauvre
Gouverner, c’est prévoir
Gracieuse plaît, non belle
Grain (à) grain croît le pain
Grain ne profite d’avoir les arts ès lèvres et les œuvres aux talons
Grain par grain, croît le pain
Grain siégleux, pain fructueux
Graine de paille ne vaut jamais graine de bois de lit
Graisser la patte à quelqu’un
Graisser ses bottes
Graissez les bottes d’un vilain, il dira que vous les (lui) brûlez
Grand (a)bandon fait grand larron
Grand (a)bandon fait le grand larron
Grand (a)bandon fait les gens larrons
Grand (a)bandon grand larron
Grand aise est fort à endurer
Grand amour cause grand dolour
Grand besoin a de fol, qui de soi-même le fait
Grand besoin a de fol, qui fol se fait
Grand bien ne vient pas en peu d’heure
Grand bien ne vient point en petit d’heure
Grand blagueur, petit faiseur
Grand bois, grandes eaux, grand chemin, sont pour la propriété trois mauvais voisins
Grand cas par un petit s’avère et se châtie par le sévère
Grand char mène, grand char verse
Grand cri abat chastel
Grand folie est de craindre aucunement, ce qu’éviter on ne peut nullement
Grand fumeur, grand buveur
Grand honneur et dignité, engendrent magnanimité
Grand jaseur, grand menteur
Grand nau (navire) veut grande eau et gros moine gras veau
Grand nez, joli visage
Grand prometteur, petit donneur
Grand péché ne peut demeurer caché
Grand rumeur petite toison, dit celui qui tond le cochon
Grand vanteur et petit faiseur
Grand vanteur, petit faiseur
Grande boîte à guérison sont temps, amour et raison
Grande chère et petit testament
Grande chère, petit testament
Grande cité, grande solitude
Grande cuisine sur les chênets, prélude de grande misère au foyer
Grande cuisine, petit héritage
Grande disputation, de vérité perdition
Grande débonnairete à maintes hommes grave
Grande débonnaireté, à maint homme grève
Grande est l’éloquence qui agrée à celui qui oit à regret
Grande et grosse me fasse Dieu, blanche et rose je me ferai
Grande familiarité engendre contemnement d’amitié
Grande fièvre, grande soif
Grande folie est de craindre aucunement, ce qu’éviter on ne peut nullement
Grande fécondité ne parvient à maturité
Grande joie vient bien souvent après deuil
Grande nef, grand souci
Grande rumeur petite toison, dit celui qui tond le cochon
Grande science est folie, si bon sens ne la guide
Grande ville, rien dedans
Grands oiseaux de coutume, sont privés de leur plume
Grands personnages ont par usage, faute d’enfants ou ne sont guère sages
Gras comme un moine
Grasse cuisine, la pauvreté pour voisine
Grasse cuisine, maigre héritage
Grasse cuisine, maigre testament
Grasse poule et maigre coq
Grasse terre, mauvais chemin
Gratte-moi, je te gratterai
Gratter quelqu’un où il lui démange
Grattez le Russe et vous trouverez le Tartare
Gref est le poids et pesanteur de l’ord péché au grand pécheur
Gros babilleur, petit travailleur
Gros d’argent, peu d’escient
Gros larron fait le petit pendre
Gros mangeur, mauvais donneur
Gros oiseau, gros nid
Grosse courtine devant l’étable emplit ni racard ni grange
Grosse tête peu de sens, grandes oreilles et puis rien dedans
Grosse tête, peu de sens
Grosse vache, veau chétif
Grosses gens, bonnes gens
Grossir, c’est vieillir
Grêler sur le persil
Guerre bonne ne peut être la guerre, qui plusieurs terrasse et atterre
Guerre est marchandise
Gueux comme un peintre, comme un rat d’église
Guérir parfois, soulager souvent, consoler toujours
Guéris un mal et n’en fais pas deux
Habile des dents, capable de rien
Habile à la table, habile à l’ouvrage
Habit de béat, a souvent ongles de chat
Habit de velours, ventre de son
Habit rapiécé fait encore sa durée
Habits d’or et ventre de son
Haine de prince signifie mort d’homme
Haine du populaire, supplice grief [grave] et aigre
Happe qui peut, non qui veut
Hardi amant n’est point honteux
Hardi de la langue, couard à la lance
Hardi demandeur, mauvais payeur
Hardi le gagne, hardi le dépense
Hardi à l’écuelle, couard au travail
Hardiment heurte à la porte, qui bonnes nouvelles apporte
Hardiment parle qui a la tête saine
Harnais ne vaut rien qui ne le défend
Harnais ne vaut rien s’il n’est défendu
Herbe connue soit bienvenue
Hercule ne fut pas engendré en une seule nuit
Heure de nuit porte ennui
Heure de plaids est l’heure de la ruse du renard
Heureuse la souris qui a plus qu’un trou
Heureux au jeu, malheureux en amour
Heureux celui qui connaît les divinités des champs
Heureux est celui qui rien ne doit à autrui
Heureux est qui ès cieux fait sa fête
Heureux le mari d’une femme vertueuse, le nombre de ses jours sera doublé
Heureux le médecin qui est appelé sur le déclin de la maladie
Heureux les miséricordieux, car ils obtiendront miséricorde
Heureux les pauvres en esprit, car le royaume des cieux est à eux !
Heureux qui fait bien
Hier vacher, hui chevalier
Hippocrate dit oui, mais Galien dit non
Homicide, mensonge et larcin, s’averent indubitamment en la fin
Homme aime quand il veut, et femme quand elle peut
Homme angulaire est à vérité contraire
Homme assailli demi vaincu et déconfit
Homme chanteur, femme pleureuse
Homme chiche n’est jamais riche
Homme craintif de faible courage, bien le démontre par son visage
Homme de paille vaut femme d’or
Homme de vin, homme de rien
Homme d’argent, homme de rien
Homme endetté, chacun an foudroye
Homme endormi, corps enseveli
Homme fin se lève matin
Homme fort, homme crevé ; grand marcheur, homme brisé ; beau nageur, homme noyé ; beau tireur, homme tué
Homme ivre et pervers, va de travers
Homme ivre n’est pas à soi
Homme ivre, gare aux coups
Homme ivre, triste chose
Homme jeune, envy prisée
Homme joyeux, femme triste
Homme mal marié, mieux le vaudrait noyé
Homme marié, tirez-en la moitié
Homme marié, âne estropié
Homme matineux, gai, sain et laborieux
Homme matineux, sain et besogneux
Homme matineux, sain et solliciteux
Homme mort ne fait pas guerre
Homme mort ne fait pas la guerre
Homme mort ne vaut pas âne vivant
Homme pervers aux bons est contraire et aux innocents donne d’affaire
Homme plaideur et de vrai dire mécru, quand il dit vrai, à bien grand peine est cru
Homme plaideur, homme menteur
Homme pute n’est pas à soi
Homme qui file, femme qui fait des sermons, s’ils ne sont sots sont des fripons
Homme qui porte lance et femme qui porte écusson, ne se doit moquer de son compagnon
Homme rusé, tard abusé
Homme sans femme est un cheval sans bride et la femme sans homme est un bateau sans gouvernail
Homme sans femme, corps sans âme
Homme sans vertu, arbre de fruit nu
Homme sans vertu, argent ni ami, corps enseveli
Homme seul est viande à loup
Homme seul est viande à loups
Homme solitaire et seulet, ange ou brute est
Homme solitaire, ange, brute ou Lucifer
Homme trop bien nourri est toujours en retard
Homme vieil et pauvre qui a mal vécu, de jeune femme sera battu
Homme vieil et pauvre qui a mal vécu, de jeune femme sera fouetté et battu
Homme à deux visages n’agrée en villes ni villages
Hommes pervers donnent plusieurs affaires aux gens de bien
Honneur change mœurs
Honneur fleurit sur la fosse
Honneurs changent leurs mœurs, hui en fleurs, demain en vers
Honneurs changent mœurs
Honneurs changent mœurs, raison n’est qui en honneur ne remue
Honni soit qui mal y pense
Honnête pauvreté est clairsemée
Honore les bons, châtie vilains, tiens cois tes doigts aussi tes mains
Honore les grands, ne méprise les petits
Honore ton père et ta mère
Honte n’est utile ni décente, à âme pauvre et indigente
Honte à mal faire est bien louable et à bien faire vitupérable
Horloge entretenir, jeune damme à gré servir, vieille maison réparer, c’est toujours à recommencer
Hors d’une laide souche, il y part une belle pousse
Hors règle et compas, je ne sais ni degré ni pas
Hui (Aujourd’hui) en figure, demain en sépulture
Hui avant ; trout arrière
Hui, pour aujourd’hui
Humer et souffler, courir et ensemble corner, n’est pas chose à tolérer
Humilité est de tous biens la reine et orgueil de tous vices la vraie racine
Humilité à tout homme bien né, qui plus bas se tient plus haut on l’assied
Hâte-toi à loisir, si veux tant mieux choisir
Hâtez-vous d’en prendre pendant qu’il guérit
Hâtez-vous lentement
Hâtez-vous toujours vers le dénouement
Hâtif besoin fait vieille trotter
Hâtiveté engendre repentance
Héraclès lui-même ne combat pas contre deux adversaires
Hôte qui de soi-même est convié, est bientôt saoul et contenté
Hôtelleries, rues sur un grand chemin le rendent court et facile à tenir
Ici pour conseiller, là pour payer
Ignorance est ennemie à gens sages
Ignorance est mère de tous les maux
Ignorance ne quiert point prudence
Ignorer est motif et occasion, de tout étrif, débat et question
Il a beau danser à qui fortune sonne
Il a beau dormir tard, qui a le bruit de se lever matin
Il a beau mentir celui qui vient de loin
Il a beau mentir qui vient de loin
Il a beau prêcher le jeûne qui est rassasié
Il a beau se lever matin qui a le renom de dormir la grasse matinée
Il a beau se lever tard, qui a bruit de se lever matin
Il a beau vanter sa noblesse quand son déshonneur le blesse
Il a bien appris, qui a pris à craindre Dieu
Il a bien d’autres chiens à fouetter
Il a bien gagné son pain, celui qui fait taire la médisance
Il a bien hanté, il a bien couru les foires
Il a bon courage, mais les jambes lui faillent
Il a chié dans ma bouillie et cela va puer longtemps
Il a craché en l’air et cela lui est retombé sur le nez
Il a des affaires autrement importantes
Il a destoupé (détaupé) un trou pour boucher l’autre
Il a fait une chose dans le dessein de nuire à autrui et s’est nui à lui-même
Il a flairé rose et bouton, et il est tombé sur un étron
Il a peur avant qu’on le touche (allusion à un habitant de Melun nommé Languille ou L’Anguille
Il a trop tardé sauf-conduit, qui après le coup le reçoit
Il a trouvé le pain cher, il a chargé du vin
Il a un œil au bois, l’autre à la ville
Il a été fort maltraité
Il adviendra beaucoup de choses entre ci et là
Il advient en une heure ce qui n’advient pas en cent
Il advient en une heure ce qui n’arrive pas en une année Latin
Il advient souvent en un jour ce qui n’advient en cent ans
Il advient souvent que luxurieux meurt méchamment
Il aime mieux quatre bœufs au feu qu’un à la charrue
Il appartient au juge d’interpréter la loi, non de la faire
Il appartient qu’aux âmes privilégiées de raisonner toujours juste
Il arrive souvent que l’on nous estime à proportion que nous nous estimons nous-même
Il arrive toujours un coup, qui ne ressemble pas les autres
Il aura bien peu de pâte, qui ne lui fera un levain
Il aura bien vite dissipé son bien
Il boit assez qui a deuil
Il comprend à demi mot
Il compte deux fois, qui compte sans son hôte
Il convient apprendre avant d’enseigner
Il convient chercher une chose où elle est
Il convient connaître la portée et capacité du tendre engin
Il convient laisser clabauder les clabauds, jaser et grumeler les gros lourdauds
Il convient pendre la pierre à la ligne
Il convient peser les hommes au grand poids du meunier et non au subtil trébuchet de l’orfèvre
Il convient préalablement purger le tendre esprit de tout vice, avant de l’imbuir de doctrine et vertu
Il convient remédier en temps aux inconvénients
Il convient traiter l’esprit des jouvenceaux à l’instar de l’agriculteur ses arbrisseaux
Il courrait au derrière d’un crabe habillé en femme
Il croit que le soleil ne brille que pour lui
Il cuide (croit) voler sans ailes
Il demeure beaucoup de ce que fol pense
Il doit toujours y avoir plus de médecins que d’apothicaires
Il en a eu tout du long de l’aune
Il en a pour un déjeuner
Il en est de la raillerie comme du sel, l’usage doit en être modéré
Il en est des générations des hommes ainsi que des feuilles sur les arbres
Il en est des lois comme des vêtements, qui sont tous de convention
Il en est du véritable amour comme de l’apparition des esprits
Il en est d’un homme léger comme d’un vase vide; il se laisse facilement prendre par les oreilles
Il en est d’une femme comme d’un baril, plus elle est occupée plus elle vaut
Il en faut autant qu’il faut de pelotes de neige à chauffer un four
Il en faut peu pour faire grogner la femme, la roue et la poulie
Il en juge comme un aveugle des couleurs
Il en sait autant qu’un cochon, qui ne sait compter que jusqu’à un
Il en vaut mieux gagner qu’en point avoir
Il en vient plus qu’il ne s’en va
Il en y a qu’ils ont plus de louange à laisser courir que les autres à guérir
Il engraisse de mélancolie
Il entend bien chat sans qu’on dise minon
Il entend le numéro
Il est (un) temps de veiller et temps de reposer
Il est aisé d’ajouter aux inventions
Il est aisé d’aller à pied quand on tient son cheval par la bride
Il est allé sur son nez, il est revenu sur ses pieds
Il est assez beau qui a tous ses membres
Il est assez éloquent celui qui dit la vérité
Il est aussi facile d’approprier une femme que le vent
Il est aussi innocent que l’agneau qui vient de naître
Il est aussi mauvais d’avoir de l’argent que de n’en avoir pas
Il est autant de fols acheteurs que de fols vendeurs
Il est avantageux de s’accommoder quand on a raison, et de plaider quand on a tort
Il est avare à qui Dieu ne suffit
Il est avec le Ciel des accommodements
Il est avis au renard que chacun mange poules comme lui
Il est avis à vieille vache qu’elle ne fut jamais génise
Il est beau veau qui veau coupe
Il est besoin que le peuple ignore beaucoup de choses vraies et en croie beaucoup de fausses
Il est bien (bon) larron, qui dérobe un larron
Il est bien aise de payer l’écot quand il ne coûte que le dire à Dieu
Il est bien aisé sur autrui, qui est plus aisé que chez lui
Il est bien allié qui a une bonne femme
Il est bien avancé, qui a bien commencé
Il est bien difficile de faire beaucoup de travaux en un coup et de les faire bien
Il est bien difficile, en géographie comme en morale, de connaître le monde sans sortir de chez soi
Il est bien digne de gésir sur la paille, qui le sien à paillarde et putain baille
Il est bien entendu que chacun portera son bissac dans la Vallée de Josaphat
Il est bien fol qui cuide toujours vivre
Il est bien fol qui veut les oies ferrer
Il est bien fol qui à fol sens demande
Il est bien force d’être brave quand on ne saurait faire autrement
Il est bien heureux qui est maître, il est valet quand il veut
Il est bien malheureux qui n’a que promettre à son vu
Il est bien pauvre qui ne voit goutte
Il est bien pauvre qu’il n’a que prommettre
Il est bien plus beau de savoir quelque chose de tout que de savoir tout d’une chose
Il est bien près du temps des cerises, le temps des cyprès
Il est bien tard d’épargner sur le tonneau quand le vin est à la lie
Il est bien tout prêche qui n’a cure de bien faire
Il est bien âne de nature, qui ne peut lire son écriture
Il est bienheureux qui ne prend égard à mauvaise langue, poignant comme un dard
Il est bienheureux qui ne se mêle que de son affaire et querelle
Il est bienheureux qui se mêle de ses affaires
Il est bienséant au chef d’exceller ses sujets en vertu et piété
Il est bienséant à un seigneur d’exceller ses sujets en bonté et vertu
Il est bienvenu celui qui apporte
Il est bon de consoler le malade quand on a la santé
Il est bon de parler, et meilleur de se taire
Il est bon de se garder une poire pour la soif
Il est bon d’avoir des amis partout
Il est bon d’être charitable Mais envers qui ? C’est là le point
Il est bon d’être ferme par tempérament et flexible par réflexion
Il est bon maître, qui jamais ne faille
Il est bon qu’un vaisseau ait deux ancres
Il est caut larron qui dérobe à un larron
Il est comme les pots d’eau bénite, près de la porte, loin du c(h)œur
Il est commun à tous d’errer et diabolique persévérer
Il est dans la nature humaine de haïr ceux que l’on a lésés
Il est dans la prospérité, tout lui réussit, quoiqu’il soit l’objet de l’animadversion générale
Il est de faux dévots ainsi que de faux braves
Il est de la confrérie Saint Hubert, il n’enrage pas pour mentir
Il est des anguilles de Melun, il crie avant qu’on l’écorche
Il est des fatigues qui abattent l’homme le plus robuste
Il est des fatigues qui abattent l’homme le plus robuste
Il est des morts qu’il faut qu’on tue
Il est des paroles qui montent comme la flamme et d’autres qui tombent comme la pluie
Il est descendu aux enfers beaucoup d’hommes auxquels les femmes avaient mis les armes à la main
Il est devenu d’évêque meunier
Il est difficile de contenter tous
Il est difficile de contenter tout le monde et puis sa femme
Il est difficile de discuter avec le ventre, car il n’a pas d’oreilles
Il est difficile de découvrir les parents d’un pauvre
Il est difficile de déguiser sa nature
Il est difficile de faire beaucoup de travail en peu de temps et de le bien faire
Il est difficile de faire plusieurs choses à la fois
Il est difficile de sauver une ville dans laquelle un poisson se vend plus cher qu’un bœuf
Il est difficile de trouver le bonheur en nous et impossible de le trouver ailleurs
Il est difficile de vivre heureux avec de mauvaises mœurs
Il est dur aux femmes d’être loin du mari
Il est encore plus facile de juger de l’esprit d’un homme par ses questions que par ses réponses
Il est exempt de bien faire
Il est extrêmement vain
Il est facile de nager quand on vous tient le menton
Il est facile de se priver quand on a les moyens de mettre fin à ses privations
Il est facile d’avoir le nom et l’effet non
Il est facile d’avoir le nom, la chose à grande peine peut-on
Il est gai comme une colombe hors de sa maison, et triste comme un corbeau dans sa maison
Il est gai, il vit sans souci
Il est glorieux comme un pet qui chante quand il est né
Il est habile dans son commerce
Il est honteux d’être loué par qui ne mérite pas de louagnes
Il est honteux d’être sans honte
Il est impossible de dire qu’on ne sera pas forcé de faire une chose ou que telle chose n’arrivera pas
Il est impossible de faire d’un âne un cheval
Il est impossible de passer tout un jour dans la joie à celui qui le passe avec une femme
Il est impossible que ce qui est fait ne soit pas fait
Il est imprudent de donner son bien durant sa vie
Il est inné dans l’homme de piétiner ce qui est à terre
Il est jamais eu sorti de la farine d’un sac de charbon
Il est jamais eu tombé des pommes d’un pommier sauvage
Il est joli parce que gracieux
Il est mal d’éteindre le vieil paillis épreint
Il est malaisé de joindre le dur avec le dur
Il est maudit en l’Évangile, qui a le choix et prend le pire
Il est maître, qui se sait aider de sa maîtrise
Il est meilleur être cheval que bœuf, loup que brebis
Il est mieux de dire aux enfants « tiens-toi tranquille » que « lève-toi »
Il est mieux de prêter que d’emprunter
Il est mieux de voir un enfant sauter qu’assis
Il est mieux d’être à côté d’un qui chie que d’un qui fend du bois
Il est mon oncle qui le ventre me comble
Il est naturel d’admirer ce qui est nouveau plutôt que ce qui est grand
Il est noble qui noblesse ne blesse et n’oublie et vilain qui commet ignoblesse et vilénie
Il est nouveau maire, il veut tout savoir, il enquiert de tout
Il est pauvre qui Dieu hait
Il est pauvre à qui il faut acheter les quatre éléments
Il est permis d’avoir quelque défiance de la femme la plus accomplie
Il est permis à celui qui vient de loin de mentir
Il est plus aisé de paraître digne des grandes places que de les remplir
Il est plus aisé de quitter ce qu’on tient que de reprendre ce qu’on a quitté
Il est plus aisé de sauter par-dessus un chêne que sûr de parler des grands
Il est plus aisé d’accuser un sexe que d’excuser l’autre
Il est plus aisé d’être sage pour les autres que pour soi-même
Il est plus aisé à bâtir deux cheminées qu’à les entretenir
Il est plus aisé à entrer en carême qu’en sortir
Il est plus aisé à se sauver qu’à se bien marier
Il est plus commode de faire son devoir que de le connaître
Il est plus dangereux de tomber en amour que du haut d’une falaise
Il est plus de gaines que de couteaux
Il est plus de jours que de semaines
Il est plus difficile de dissimuler les sentiments que l’on a que de feindre ceux que l’on n’a pas
Il est plus difficile de donner que de prendre
Il est plus d’ouvriers que de maîtres
Il est plus d’ouvriers que d’outils
Il est plus facile (d’)acheter que (de) payer
Il est plus facile au fils de demander au père qu’au père de demander au fils
Il est plus facile conseiller que faire
Il est plus facile de commencer que de finir
Il est plus facile de critiquer que d’imiter
Il est plus facile de démolir que de bâtir
Il est plus facile de faire entrer sept diables dans une femme que d’en faire sortir un seul
Il est plus facile de faire parler les femmes que de les faire taire
Il est plus facile de farie d’un bon un méchant que d’un méchant un bon
Il est plus facile de garder un huitième de sac de puces qu’une jeune fille
Il est plus facile de garder un plein van de puces au soleil qu’une fille
Il est plus facile de garder un van de puces que des jeunes filles
Il est plus facile de médeciner que de curer
Il est plus facile de se contenir que de se retirer d’une querelle
Il est plus facile de se marier que d’élever maison
Il est plus facile de trouver la Fortune que de la retenir
Il est plus facile descendre que monter
Il est plus facile descendre qu’ascendre
Il est plus facile dire que faire
Il est plus facile démolir que bâtir
Il est plus facile dépenser que gagner
Il est plus facile d’arrêter l’eau que les langues de femme pendant le travail
Il est plus facile d’emprunter que de tourner après
Il est plus facile ferrir que guérir
Il est plus facile lâcher que retenir
Il est plus facile menacer que tuer
Il est plus facile médiciner que curer
Il est plus facile panser ou médiciner que curer
Il est plus facile parler que taire
Il est plus facile penser que d’être
Il est plus facile prendre que rendre
Il est plus facile promettre que donner
Il est plus facile présumer que savoir
Il est plus facile souhaiter qu’enrichir
Il est plus facile tomber que se relever
Il est plus facile vouloir que voler
Il est plus facile à un chameau de passer par le trou d’une aiguille qu’à un riche d’entrer dans le royaume de Dieu
Il est plus honteux de se défier de ses amis que d’en être trompé
Il est plus malheureux de commettre une injustice que de la souffrir
Il est plus naturel au prince donner loyer aux bons que de châtier les mauvais
Il est plus sûr que le vice rend malheureux, qu’il ne l’est que la vertu donne le bonheur
Il est près de la terre et loin du ciel
Il est préférable de souffrir un mal plutôt que d’appliquer un remède qui est pire que ce mal
Il est préférable d’être dans une situation aisée que dans la misère
Il est quelquefois utile d’oublier ce que l’on sait
Il est rare de voir la sagesse alliée à la beauté
Il est riche (celui) que Dieu aime
Il est riche qui Dieu aime
Il est sage qui sait tout
Il est sain qui est son maître
Il est si avare ou si pauvre qu’il est impossible de lui faire payer ce qu’il doit
Il est souvent peu raisonnable d’avoir trop tôt ou trop complètement raison
Il est souvent plus grand d’avouer ses fautes que de n’en pas commettre
Il est tellement maladroit ou incapable que la plus petite difficulté le met dans l’embarras
Il est temps de besogner, temps de chômer
Il est temps de bâtir, temps de démolir
Il est temps de donner, temps de garder
Il est temps de gémir et temps de rire
Il est temps de haïr et temps d’aimer
Il est temps de parler et temps de taire
Il est temps de planter et temps d’arracher
Il est temps de semer, temps de moissoner
Il est temps de souffler et temps de humer
Il est temps de tailler, temps de coudre
Il est temps de tuer, temps de saler
Il est temps de veiller et temps de reposer
Il est toujours assez tôt de payer ou de mourir
Il est toujours assez tôt de se faire du souci
Il est toujours bon de savoir quelque chose, si ce n’est pas pour le gain, c’est pour l’honneur
Il est toujours bon d’avoir plusieurs solutions dans une situation Voir aussi l’autre forme : Il faut avoir plus d’un tour dans son sac
Il est toujours bon d’avoir plusieurs solutions dans une situation Voir aussi l’autre forme : Il faut avoir plus d’une corde à son arc
Il est toujours fête après besogne faite
Il est toujours fête pour celui qui bien fait
Il est toujours plus tard que tu ne crois
Il est toujours préférable de régler un problème avec la personne responsable
Il est toujours saison de bien faire
Il est toujours temps de bien faire
Il est tout à fait innocent
Il est trois bêtes intraitables
Il est trois despotes
Il est trop tard de conseil prendre, quand en bataille il faut descendre
Il est trop tard de dire garde après le coup donné
Il est trop tard de fermer la porte quand le loup est entré
Il est trop tard de fermer le cul quand le pet est sorti
Il est trop tard de fermer les barrières quand les poulains sont passés
Il est trop tard de fermer l’écurie quand les chevaux sont déjà dehors
Il est trop tard de mettre du sel quand la viande sent déjà mauvais
Il est trop tard pour fermer l’écurie quand le cheval s’est sauvé
Il est tôt déçu, qui mal ne pense
Il est tôt déçu, qui mal pense
Il est un temps pour bâtir et un temps pour démolir
Il est une loi qui ordonne àl’homme de chérir sa femme et à la femme de faire ce que désire l’époux
Il est vite arrivé qui grève
Il existe une intrigue
Il fait beau où on voit clair
Il fait beaucoup, celui qui fait bien ce qu’il fait
Il fait bien laisser le jeu quand il est beau
Il fait bien mal, aimer et n’être pas aimé
Il fait bien mauvais au bois, quand les loups se mangent l’un l’autre
Il fait bon avoir des biens, on en sauve toujours quelque pièce
Il fait bon avoir deux (plusieurs) cordes en son arc
Il fait bon battre un glorieux, il ne s’en vante pas
Il fait bon pêcher en eau trouble
Il fait bon reculer pour mieux saillir
Il fait bon redouter fortune et craindre faut les inconvénients
Il fait bon servir à bon maître
Il fait bon vivre et ne rien savoir
Il fait bon vivre et rien savoir; on apprend toujours quelque chose
Il fait bonne journée, qui se délivre d’un fol
Il fait de belles cures, il vaudrait mieux qu’il fasse des prieurés
Il fait d’autrui cuir large courroie
Il fait le simple, mais c’est un fin renard
Il fait mal avoir nom (de) loup, tout le monde vous tape dessus
Il fait mal clocher devant boiteux
Il fait mauvais lutter en un précipice, car il y a danger de choir et de se casser la tête
Il fait mauvais se mettre à la discrétion des bastonnades
Il fait meilleur être à côté d’un chieur, que d’un casseur de pierres
Il fait toujours bon temps pour quelqu’un
Il fait un mariage de Saint-Sauveur, la putain épouse le voleur
Il fait un mariage d’épervier, la femelle vaut mieux que le mâle
Il faudrait devenir vieux avant de devenir jeune
Il faudrait être en bien des endroits à la fois
Il faudrait être en deux trois morceaux
Il faudrait être vieux avant d’être jeune
Il faut [modifier]
Il faut aborder la vie avec un esprit sain ou se pendre
Il faut aimer les gens, non pour soi, mais pour eux
Il faut aller rondement, garde-toi de l’homme angulaire
Il faut aller à la danse et tous mourir sans doubtance
Il faut aller à la guerre sous bride
Il faut aller à maître pour apprendre à faire le poing à sa poche
Il faut anoblir son esprit et faire son âme reine
Il faut appeler méchant celui qui n’est bon que pour soi
Il faut appeler pétrin un pétrin
Il faut apprendre de la vie à souffrir la vie
Il faut apprendre puis le rendre
Il faut apprendre qui veut savoir
Il faut apprendre à obéir pour savoir commander
Il faut argent pour commencer le jeu
Il faut attendre à cueillir la poire qu’elle soit mure
Il faut aussi donner sa part à Messire le diable
Il faut autant avoir souci de son âme que de sa panse
Il faut autant de temps à se refaire qu’on a été malade
Il faut avaler les pilules sans les mâcher
Il faut avoir beaucoup étudié pour savoir peu
Il faut avoir bien faim pour manger des pommes de terre crues
Il faut avoir de la merde au cul pour chier
Il faut avoir deux cordes à son arc
Il faut avoir mangé un double décalitre de sel ensemble pour se connaître
Il faut avoir mauvaise bête par douceur
Il faut avoir partout raison
Il faut avoir plus d’un tour dans son sac
Il faut avoir plus d’une corde à son arc
Il faut avoir senti les atteintes du désespoir pour comprendre le bonheur d’y arracher un semblable
Il faut avoir une bonne clef pour entrer en paradis
Il faut avoir une bouche capable de manger n’importe quel pain et un dos susceptible de se plier à n’importe quel lit
Il faut baiser le chien sur la gueule jusqu’à ce qu’on peut le museler
Il faut battre le fer ce pendant qu’il est chaud
Il faut battre le fer du temps qu’il est chaud
Il faut battre le fer pendant qu’il est chaud
Il faut battre le fer quand il est chaud
Il faut battre le fer tandis qu’il est chaud
Il faut beaucoup de mérite pour sentir vivement celui des autres
Il faut bien commencer pour bien finir
Il faut bien commencer si on veut bien finir
Il faut bien des beautés pour faire un bon dîner
Il faut bien des péchés pour faire une bonne confession
Il faut bien mourir de quelque chose
Il faut bien penser à la mort, aujourd’hui vif demain mort
Il faut bâtir avec les pierres de son pays
Il faut casser le noyau pour avoir l’amande
Il faut casser le noyau pour en avoir l’amande
Il faut ce qu’il faut
Il faut ce qu’il faut pour falloir ce qu’il aurait fallu
Il faut choisir d’aimer les femmes ou de les connaître
Il faut choisir entre les choses opposées
Il faut commencer avant achever
Il faut comparer la pourpre à la pourpre
Il faut compter l’argent deux fois et l’or trois
Il faut conduire les enfants par la pudeur et l’ambition, comme on conduit les chevaux par le frein et l’éperon
Il faut connaître avant aimer
Il faut connaître avant d’aimer
Il faut connaître premier que de juger
Il faut courir aux maladies des yeux comme au feu
Il faut couvrir le feu de la maison avec les cendres de la maison
Il faut craindre ce qui peut ôter la vie et la santé
Il faut craindre les gros vents et les grosses gens
Il faut craindre sa femme et le tonnerre
Il faut craindre trois choses dans ce monde, le devant d’une femme, le derrière d’une mule et l’ombre du noyer
Il faut croire conseil d’un homme qui fait bien ses besognes
Il faut céder, il n’y a pas d’autre parti à prendre
Il faut de la hardiesse, de la confiance en soi-même pour profiter des bonnes occasions : Variante : Ne soyez honteux que d’être honteux
Il faut de la raison partout
Il faut de l’argent pour marier filles
Il faut de plus grandes vertus pour soutenir la bonne fortune que la mauvaise
Il faut de tout pour faire un monde, des noirs et des roux, des blonds et des mélangés
Il faut de vieux os pour faire de bon bouillon
Il faut des centimes jaunes pour faire des francs
Il faut devenir vieux de bonne heure pour rester vieux longtemps
Il faut donner les droits ou les torts à celui qui les a
Il faut donner quelque chose au hasard
Il faut donner un œuf pour gagner un bœuf
Il faut découdre et non déchirer l’amitié
Il faut dépenser qui veut gagner
Il faut en rabattre de moitié
Il faut encore témoigner de la gratitude
Il faut endormir le fanatisme afin de pouvoir le déraciner
Il faut endurer pour durer
Il faut endurer qui veut vaincre et durer
Il faut enter une greffe d’un vieil arbre sur un jeune sauvageon
Il faut entretenir la vigueur du corps pour conserver celle de l’esprit
Il faut essayer de soumettre les circonstances et non s’y soumettre
Il faut estimer ce que l’homme fait non par ce qu’il peut faire
Il faut estimer un homme de bien plus qu’un parent
Il faut faire Mardi Gras avec sa femme et Pâques avec son curé
Il faut faire coucher la colère à la porte
Il faut faire de l’ordre avec du désordre
Il faut faire de nécessité vertu
Il faut faire la lessive à la buanderie
Il faut faire le feu à Noël avec de grosses souches et à Pâques avec des branches
Il faut faire l’âne si on veut avoir du son
Il faut faire pour apprendre
Il faut faire son purgatoire en ce monde ou dans l’autre
Il faut faire trois fois le travail pour le bien faire
Il faut faire vie qui dure On se doit de ménager ses ressources pour les faire durer plus longtemps
Il faut flatter les crétins pour les faire travailler
Il faut fleurir pour porter fruit
Il faut gagner Dieu à force de le prier et pourvoir à la nécessité à force de travailler
Il faut garder la poire pour la soif
Il faut garder les porcs gras, les jeunes porcs coûtent trop à engraisser
Il faut garder une pomme pour la soif
Il faut gouverner la fortune comme la santé
Il faut gratter les gens où il leur démange
Il faut haïr quelque chose pour être gentilhomme
Il faut haïr son ennemi comme s’il pouvait un jour devenir un ami, et aimer son ami comme s’il pouvait devenir un ennemi
Il faut honorer les saints comme on les connaît
Il faut honorer nos maîtres plus que nos parents, car si nos parents nous ont donné la vie, nos maîtres nous ont donné le moyen de bien vivre
Il faut hurler avec les loups
Il faut hurler avec les loups, si l’on veut courir avec eux
Il faut importuner les princes de demandes comme Dieu de prières
Il faut interpréter le mur, non pas la voix
Il faut jamais jurer de rien
Il faut laisser courir le vent par-dessus les tuiles
Il faut laisser courir l’eau par le bas
Il faut laisser dormir les morts
Il faut laisser faire ce que l’on ne peut empêcher Voir aussi : Ne poursuivez pas le vent qui emporte votre chapeau
Il faut laisser le moutier où il est
Il faut laisser le temps au tan
Il faut laisser les gens parler et les chiens aboyer
Il faut laisser les princes en leur opinion
Il faut laisser mûrir les poires pour les cueillir
Il faut laisser passer beaucoup de temps pour refermer les blessures – Tan, du mot tanin, qui met longtemps pour imprégner la peau de cuir
Il faut laisser suer ceux qui ont chaud et trembler ceux qui ont froid
Il faut laver son linge sale en famille
Il faut le désordre pour ramener l’ordre
Il faut le voir pour le croire
Il faut lier le sac avant qu’il (ne) soit plein
Il faut lier à son doigt l’herbe qu’on connaît
Il faut louer la mer et se tenir en terre
Il faut lui mâcher tous ses morceaux
Il faut manger les petits pois avec les riches et les cerises avec les pauvres Les petits pois ne sont bons que quand ils sont primeurs et donc fort chers, alors que les cerises sont meilleures quand elles sont arrivées à pleine maturité et ainsi très peu chères
Il faut manger moins de fromage que de pain
Il faut manger pour vivre, et non pas vivre pour manger
Il faut manger trois coupes de cendres pour aller au paradis
Il faut marier le bétail du pays
Il faut marier le loup pour le dompter
Il faut marier le loup pour l’arrêter
Il faut marier le loup pour l’assagir
Il faut mener les gens comme on les connaît
Il faut mettre à la portée de chacun une chose dont tout le; monde à besoin
Il faut mourir
Il faut mourir pour qu’on dise du bien et se marier pour qu’on dise du mal
Il faut mourir pour se faire regretter, il faut se marier pour se faire mépriser
Il faut mourir pour être loué et se marier pour être décrié
Il faut mourir qui veut vivre
Il faut naître pour être joli, se marier pour être riche et mourir pour être bon
Il faut naître pour être joli, se marier pour être riche et mourir pour être honnête
Il faut ne rien changer aux vieux usages
Il faut n’avoir commerce qu’avec les femmes qui vous en sauront gré
Il faut observer la convenance dans le détail et l’ordre dans l’ensemble
Il faut opter des deux
Il faut oublier les vieilles dettes et puis laisser les jeunes (de)venir vieilles
Il faut partout un commencement
Il faut partout une mesure
Il faut pas attaquer le nid de guêpes
Il faut pas croire que poussin en sait plus que poule
Il faut pas demander aux hommes ce qu’on peut pas leur donner
Il faut pas donner garde(r) le lard au chat
Il faut pas donner garde(r) les brebis au loup
Il faut pas enseigner à chier à ceux qui ont la diarrhée
Il faut pas faire l’épi plus gros que la mortaise
Il faut pas prendre après ce que disent les fous
Il faut pas rire d’un bossu, de peur de se faire rire (soi-)même
Il faut pas se jeter dans la crèche avant qu’entrer à l’écurie
Il faut pas se mettre bas aux pieds ce qu’on a aux mains
Il faut pas s’amuser avec les chiens et avec les crétins
Il faut passer par là ou par la fenêtre
Il faut payer qui veut acheter
Il faut pendre la lessive du temps que le soleil luit
Il faut penser avec les honnêtes gens, mais parler avec le vulgaire
Il faut penser sept fois avant de se mettre en colère et soixante-dix sept fois sept avant de se marier
Il faut perdre un vairon pour pêcher un saumon
Il faut placer le clocher au milieu de la paroisse
Il faut planter un arbre au profit d’un autre âge
Il faut plus craindre les eaux que le vin
Il faut plus de drogues aux trop saouls qu’aux meurs-de-faim
Il faut plus dérober que gagner pour être riche à plaidoyer
Il faut plus d’esprit pour faire l’amour que pour conduire des armées
Il faut plus d’un coup pour mettre bas un chêne
Il faut plus d’une hirondelle pour amener le printemps
Il faut plus que de l’esprit pour être auteur
Il faut pouvoir bien sûr, mais il faut aussi vouloir
Il faut premier à Dieu servir et du corps puis se souvenir
Il faut prendre en gré le temps quand il vient
Il faut prendre en gré le temps quand il vient, folle est la quérimonie qui est contre le temps
Il faut prendre la poule sans crier
Il faut prendre la vie du beau côté
Il faut prendre la vie du beau sens
Il faut prendre le blé comme qu’il croît et puis le temps comme qu’il vient
Il faut prendre le cerf avant de le dépouiller
Il faut prendre le pot-au-feu selon son état et revenu et qui guère n’a dépenser peu
Il faut prendre le saut avant le lièvre
Il faut prendre le taureau par les cornes Quand on veut quelque chose il faut vraiment s’y mettre
Il faut prendre le temps comme il vient
Il faut prendre le temps comme il vient et les hommes comme on les trouve
Il faut prendre le temps comme il vient, les femmes comme elles sont et l’argent pour ce qu’il vaut
Il faut prendre une maison faite et une femme à faire
Il faut presque être trop bon pour l’être assez
Il faut préférer un dommage à un gain malhonnête, car le premier ne cause qu’un chagrin, alors que le second en apporte une infinité
Il faut puiser tant que la corde est au puits
Il faut que celui qui se moque des jambes tordues ait les siennes droites
Il faut que chair qui croît bouge
Il faut que force reste à justice Il ne faut utiliser la force que pour une cause juste
Il faut que jeunesse se passe La jeunesse est difficile mais elle est un moment de la vie comme un autre
Il faut que jeunesse se passe et que vieillesse se casse
Il faut que la maladie prenne son cours
Il faut que la poule aide le coq à gratter
Il faut que la poule aide à gratter au coq
Il faut que la tête soit bien pourrie, pour que la queue sente si mauvais
Il faut que la ville soit fournie, qu’il en y ait des fols et des sages
Il faut que le cœur se brise ou se bronze
Il faut que le désordre ramène l’ordre
Il faut que le mâle soit fin si la femelle ne l’affine
Il faut que le pauvre homme fasse joug au riche
Il faut que le sage porte le fol sur ses épaules
Il faut que les enfants le soient longtemps
Il faut que les femmes se plaignent de leur jardin, pour que ce soit une bonne année
Il faut que les filles descendent et que les vaches montent
Il faut que vertu fasse tête à la noblesse
Il faut quelquefois brûler une chandelle au diable
Il faut qu’il ait été changé en nourrice
Il faut qu’on en fasse, si ce n’est chez soi c’est en allant boire
Il faut qu’on en fasse, si ce n’est pas à la crèche c’est en allant boire
Il faut qu’un fou mette de la graisse dans la soupe et qu’un sage y mette du sel
Il faut qu’un homme soit bien vieil pour haïr un maquereau
Il faut qu’un menteur ait de la mémoire
Il faut qu’une main lave l’autre
Il faut qu’une porte soit ouverte ou fermée
Il faut racheter l’argent prêté
Il faut recevoir le bien avec son mal
Il faut recevoir les calomnies avec plus de calme que les cailloux
Il faut reculer pour mieux sauter
Il faut remplir son tonneau de joie pour n’y laisser place à mélancolie
Il faut rendre le bien pour le mal
Il faut rien qu’être pauvre pour être exploité
Il faut rire avant que d’être heureux, de peur de mourir avant d’avoir ri
Il faut sauver les peuples malgré eux
Il faut savoir avant penser
Il faut savoir changer son arbalète d’épaule
Il faut savoir choisir car tout ne s’obtient pas Voir aussi : Il veut le beurre, l’argent du beurre, et le sourire de la crémière par-dessus le marché, et les autres formes : On ne peut pas sauver la chèvre et les choux et On ne peut pas avoir le lard et le cochon
Il faut savoir choisir car tout ne s’obtient pas Voir aussi les autres formes : On ne peut avoir le beurre et l’argent du beurre et On ne peut pas avoir le lard et le cochon
Il faut savoir choisir car tout ne s’obtient pas Voir aussi les autres formes : On ne peut avoir le beurre et l’argent du beurre et On ne peut pas sauver la chèvre et les choux
Il faut savoir devant qu’avoir
Il faut savoir détendre la corde avant qu’elle se rompe
Il faut savoir détendre la corde avant qu’elle se rompe
Il faut savoir maîtriser sa langue, son sexe et son cœur
Il faut savoir obéir avant que de commander
Il faut savoir raison garder
Il faut savoir tenir sa misère joyeuse
Il faut se conduire avec ses amis comme on voudrait les voir se conduire avec soi
Il faut se contenter de ce qu’on a
Il faut se contenter d’une bonne chose sans chercher à la rendre encore plus exquise
Il faut se donner de la peine pour avoir du profit
Il faut se défier de ce qui est marqué au B
Il faut se défier des garçons peignés et filles frisées
Il faut se défier des hypocrites
Il faut se faire à toutes les circonstances de la vie
Il faut se garder d’éveiller la colère des puissants
Il faut se marier pour se faire critiquer
Il faut se marier pour se faire à blâmer, il faut mourir pour se faire à louer
Il faut se marier pour se faire à décrier, il faut mourir pour se faire à fleurir
Il faut se marier pour être méprisé et mourir pour être loué
Il faut se mesurer qui veut durer
Il faut se méfier des eaux dormantes
Il faut se méfier du devant d’une femme, du derrière d’une mule et d’un curé (d’une nonne, d’un moine) de tous côtés
Il faut se méfier du devant d’une femme, du derrière d’une mule et d’un soldat de tous les côtés
Il faut se méfier d’un taureau qui beugle
Il faut se taire ou dire des paroles de bon augure
Il faut semer qui veut moissonner
Il faut sept ans pour rattraper la première année de mariage
Il faut servir Dieu avant sa panse
Il faut seulement manger par faim et boire par soif
Il faut si bien marier ses enfants qu’ils n’ayent que faire de leurs pères
Il faut souffrir le chaud et le froid
Il faut souffrir pour un mieux
Il faut souffrir pour être belle
Il faut suivre la mode ou être extravagant
Il faut surveiller nos ennemis, car ils voient les premiers nos défauts
Il faut s’agripper au tronc devant de s’agripper aux branches
Il faut s’enquérir qui est mieux savant, non qui est plus savant
Il faut s’habiller du drap du pays
Il faut s’étendre selon sa couverture
Il faut tendre la main à ses amis sans fermer les doigts
Il faut tendre voile selon le vent
Il faut tenir les enfants sur la crainte
Il faut tenir à une résolution parce qu’elle est bonne, et non parce qu’on la prise
Il faut tirer le ridicule avec grâce et d’une manière qui plaise et qui instruise
Il faut tondre ses brebis et non pas les écorcher Ou
Il faut toujours avoir quelque chose à manger avec son pain
Il faut toujours donner un coup à la douve et l’autre au cercle
Il faut toujours faire aller l’eau sur son moulin
Il faut toujours faire coucher la colère à l’huis
Il faut toujours garder une pomme pour la soif
Il faut toujours laisser couler l’eau par le bas
Il faut toujours manger avant de boire
Il faut toujours manger un plat après la soupe
Il faut toujours mettre de l’eau dans son vin
Il faut toujours se méfier du cul d’un mulet, du devant d’une femme, de la rancune d’un prêtre
Il faut tourner sa langue sept fois dans sa bouche avant de parler
Il faut toute la vie pour apprendre à vivre
Il faut travailler en jeunesse, pour reposer en vieillesse
Il faut travailler qui veut manger
Il faut travailler qui veut reposer
Il faut travailler tant que la peau du cul dure
Il faut trois sacs à un plaideur
Il faut trois vieilles femmes pour faire une jeune fille
Il faut tromper les enfants avec les osselets et les hommes avec les serments
Il faut tuer le taureau avant la vache
Il faut un commencement à tout
Il faut un coup de fouet pour stimuler un cheval, il faut un verre de vin pour stimuler un homme
Il faut un fol et un sage, pour trancher un fromage
Il faut une fois mourir
Il faut une mesure à tout
Il faut vivre avec ceux qui vivent
Il faut vivre et laisser vivre
Il faut vivre et non pas seulement exister
Il faut voir et ouïr en cour et y être aveugle et sourd
Il faut à la femme la plus honnête un grain de coquetterie, comme à la fraise un grain de poivre
Il faut à la fois reculer pour mieux saillir
Il faut à tout un commencement
Il faut éclairer l’histoire par les lois et les lois par l’histoire
Il faut écouter beaucoup et parler peu pour bien agir au gouvernement d’un État
Il faut écrire comme on parle
Il faut épargner en jeunesse pour se soutenir en vieillesse
Il faut éprouver l’ami aux petites occasions et l’employer aux grandes
Il faut éteindre la démesure plus qu’un incendie
Il faut être bien monté ou aller à pied
Il faut être chair ou bien os
Il faut être deux pour se quereller
Il faut être enclume ou marteau
Il faut être fol en amour
Il faut être gris pour faire des âneries
Il faut être juste avant d’être généreux, comme on a des chemises avant d’avoir des dentelles
Il faut être marchand ou larron
Il faut être sévère, ou du moins le paraître
Il faut être à la maison partout
Il faut ôter le trot et en faire une haquenée
Il faut, autant qu’on peut, obliger tout le monde
Il faut, quand on agit, se conformer aux règles, et quand on juge, avoir égard aux exceptions
Il faut, quand on gouverne, voir les hommes tels qu’ils sont, et les choses telles qu’elles doivent être
Il foloye beau qui foloye par conseil
Il gagne assez qui putain perd
Il importe autant pour un soldat d’ignorer certaines choses que d’en savoir d’autres
Il la faudrait acheter pour ce qu’elle vaut et la vendre pour ce qu’elle se croit
Il languit qui ne repose
Il lui en pend autant au nez Se dit de quelqu’un qui peut être exposé au même inconvénient
Il lui est très inférieur en mérite
Il lui pense rompre le cul et il se rompt la tête
Il meurt plus d’enfants de trop manger que de mourir de faim
Il ne change point de pays qui voit toujours le soleil
Il ne chante qu’une chanson, il n’aura qu’un denier
Il ne choisit pas qui emprunte
Il ne consent pas à faire ce qu’on lui demande
Il ne convient pas d’être fournier à celui qui a la tête faite de beurre
Il ne croît pas d’herbe sur les chemins battus
Il ne dort pas du tout
Il ne dort pas plus qu’un jaloux
Il ne fait pas bon manger des prunes avec son seigneur
Il ne fait pas bon mettre la main entre l’écorce et le bois
Il ne fait pas bon tomber dans une maison comme un chien sur un jeu de boules
Il ne fait pas ce qui veut qui son pain sale
Il ne fait pas ce qu’il veut qui fait des chausses de sa femme chaperon
Il ne fait que boucher un trou et en ouvrir un autre
Il ne fait rien pendant que les autres travaillent
Il ne fait rien qui commence et ne finit
Il ne fait rien qui n’achève bien
Il ne fait sûr en mer, ni au milieu ni à la rive
Il ne faut (pas) plus craindre la mort que l’enfer
Il ne faut arriver ni trop tôt ni trop tard
Il ne faut avoir de l’esprit que par mégarde et sans y songer
Il ne faut avoir langue à table que pour manger
Il ne faut croire à un moine qu’un œuf et deux à un abbé
Il ne faut dire ses cachettes ni à côté d’un mur ni dans une côte
Il ne faut emprunter qu’à la dernière
Il ne faut faire devant les gens aucune chose qui semble leur reprocher leur infirmité
Il ne faut jamais acheter la cage sans avoir l’oiseau
Il ne faut jamais aimer le soir qu’on ne puisse désaimer le matin
Il ne faut jamais avoir hâte que pour prendre les puces
Il ne faut jamais avoir les yeux plus grands que le ventre
Il ne faut jamais cracher en amont de peur qu’il ne vous en retombe dessus
Il ne faut jamais cracher plus haut que son nez, de peur que cela ne vous retombe dessus
Il ne faut jamais hasarder la plaisanterie qu’avec des gens polis, ou qui ont de l’esprit
Il ne faut jamais juger ni gager de ce qui est en la cervelle d’autrui
Il ne faut jamais plaindre les noces
Il ne faut jamais plaindre sans mal
Il ne faut jamais se faire de souci à l’avance
Il ne faut jamais tourner le dos à la tourte
Il ne faut jamais vendre la peau de l’ours, qu’on ne l’ait mis à terre
Il ne faut jurer de rien
Il ne faut mettre de l’eau dans le gaz
Il ne faut pas affronter l’âne jusqu’à la bride
Il ne faut pas agacer les fous
Il ne faut pas agiter ce qui est tranquille
Il ne faut pas aimer le chevrette plus que la bête
Il ne faut pas aller au bois qui craint les feuilles
Il ne faut pas aller au-devant du temps
Il ne faut pas aller à la guerre qui craint les horions
Il ne faut pas aller à mûres sans havet
Il ne faut pas avoir les yeux plus gros que la tête
Il ne faut pas avoir égard à un seul témoin, fut-il Caton lui-même
Il ne faut pas briser le pont quand on a passé l’eau
Il ne faut pas brusquer pour bien avancer, inutile de traire avant de manier
Il ne faut pas cajoler sa femme ni la quereller en présence d’étrangers
Il ne faut pas changer son cheval borgne contre un aveugle
Il ne faut pas changer son cheval borgne contre un aveugle ni son couteau contre une lame
Il ne faut pas changer son couteau contre une lame
Il ne faut pas changer un cheval borgne contre un aveugle
Il ne faut pas chercher des amis uniquement au forum et au sénat
Il ne faut pas chercher les poux parmi la paille
Il ne faut pas chômer les fêtes avant qu’elles soient venues
Il ne faut pas clocher devant les boiteux
Il ne faut pas clocher devant les boiteux
Il ne faut pas compter sur l’appétit d’un vieux ni sur un franc beau jour d’hiver
Il ne faut pas confondre vitesse et précipitation
Il ne faut pas considérer l’âge en un homme que sa vertu
Il ne faut pas considérer tout le monde de la même manière Voir aussi l’autre forme : Il ne faut pas mettre tous les œufs dans le même panier
Il ne faut pas contrarier les fous
Il ne faut pas courir deux lièvres à la fois
Il ne faut pas crever ses tripes pour couvrir sa tête
Il ne faut pas croire tout ce qu’on voit
Il ne faut pas deux coqs sur un même fumier
Il ne faut pas dire que quelque chose est fait si ça n’est pas vrai, se réjouir à l’avance d’un succès incertain Voir aussi l’autre forme : Il ne faut jamais vendre la peau de l’ours, qu’on ne l’ait mis à terre
Il ne faut pas dire que quelque chose est fait si ça n’est pas vrai, se réjouir à l’avance d’un succès incertain Voir aussi l’autre forme : Il ne faut pas vendre la peau de l’ours avant de l’avoir tué
Il ne faut pas dire tout ce que l’on sait ni manger tout ce que l’on pourrait manger
Il ne faut pas dire « Fontaine je ne boirai pas de ton eau »
Il ne faut pas dire, fontaine je ne boirai jamais de toi
Il ne faut pas discuter sur les sujets qui fâchent Voir aussi l’autre forme : Il ne faut mettre de l’eau dans le gaz
Il ne faut pas discuter sur les sujets qui fâchent Voir aussi l’autre forme : Il ne faut pas jeter de l’huile sur le feu
Il ne faut pas donner et puis reprocher
Il ne faut pas défier un fou
Il ne faut pas déranger le loup dans sa tannière
Il ne faut pas déshabiller Pierre pour habiller Paul
Il ne faut pas empêcher les gens de s’éclairer, de s’instruire
Il ne faut pas enlever la veste avant d’avoir chaud
Il ne faut pas enseigner le poisson à nager
Il ne faut pas essayer de pénétrer dans le sanctuaire
Il ne faut pas excuser un enfant qui agit mal
Il ne faut pas faire vie qui druge mais vie qui dure
Il ne faut pas irriter les frelons
Il ne faut pas jeter de l’huile sur le feu
Il ne faut pas jeter le manche après la cognée
Il ne faut pas joindre la faim à la soif
Il ne faut pas jouer au bœuf
Il ne faut pas juger de la liqueur d’après le vase
Il ne faut pas juger de l’arbre par l’écorce
Il ne faut pas juger d’un homme par ce qu’il ignore, mais par ce qu’il sait
Il ne faut pas laisser Paris pour trouver des chirurgiens en Vosges
Il ne faut pas lier les ânes avec les chevaux
Il ne faut pas manger du cœur
Il ne faut pas marier la fille d’un cabaretier ni acheter le cheval d’un meunier
Il ne faut pas marier la vache et puis le veau
Il ne faut pas mesurer chacun à la même aune
Il ne faut pas mettre dans une cave un ivrogne qui a renoncé au vin
Il ne faut pas mettre la charrue avant les bœufs Il faut s’avoir prendre son temps pour s’organiser correctement
Il ne faut pas mettre la lampe allumée sous le boisseau
Il ne faut pas mettre la main entre le marteau et l’enclume
Il ne faut pas mettre le doigt entre la porte et le gond
Il ne faut pas mettre le doigt entre le gond et la paumelle
Il ne faut pas mettre le doigt entre l’arbre et l’écorce
Il ne faut pas mettre les étoupes auprès du feu
Il ne faut pas mettre tous les œufs dans le même panier
Il ne faut pas mettre tous ses œufs dans la même corbeille
Il ne faut pas mettre tout son argent dans un seul chiffon de toilette
Il ne faut pas mélanger torchons et serviettes
Il ne faut pas ourdir plus qu’on peut tramer
Il ne faut pas parler de corde dans la maison d’un pendu
Il ne faut pas parler latin devant des cordelier
Il ne faut pas penser voler plus haut que le ciel
Il ne faut pas pitoyer un canard qui est boiteux
Il ne faut pas plus de femmes dans une maison que de crémaillère
Il ne faut pas plus de femmes à un souper qu’il n’y a de crémaillère à une cheminée
Il ne faut pas plus de tonneaux que de maîtres dans une maison
Il ne faut pas précipiter une affaire et attendre qu’elle soit en état d’être conclue
Il ne faut pas péter plus haut qu’on a le cul
Il ne faut pas que la souris se moque du chat ni la fille de l’amour
Il ne faut pas que les poules chantent plus haut que les coqs
Il ne faut pas rappeler une mauvaise affaire ou donner à quelqu’un qui n’y songe pas l’occasion de nuire
Il ne faut pas regarder l’herbe à la rosée et les filles à la chandelle
Il ne faut pas remuer la cendre des morts
Il ne faut pas reprocher aux gens leur vieillesse, puisque tous nous désirons y parvenir
Il ne faut pas rester entre deux airs
Il ne faut pas retourner certaines vertus; leur envers est plus laid que bien des vices
Il ne faut pas ruer le manche après la cognée
Il ne faut pas réveiller le chat qui dort
Il ne faut pas sauter du pré au chemin
Il ne faut pas se dépouiller avant de se coucher
Il ne faut pas se dévêtir avant d’aller au lit
Il ne faut pas se dévêtir avant d’aller dormir
Il ne faut pas se faire du mauvais sang avant qu’il en soit temps
Il ne faut pas se fier à un homme qui entend deux messes
Il ne faut pas se fourrer entre la crème et le pot
Il ne faut pas se laisser mener par le bout du nez
Il ne faut pas se mettre des pierres au foie
Il ne faut pas se moquer des chiens avant d’être sorti du village
Il ne faut pas se moquer des mal chaussés
Il ne faut pas se mêler des querelles qui surviennent entre les membres d’une famille
Il ne faut pas se plaindre d’une jambe saine
Il ne faut pas se salir avec la merde
Il ne faut pas semer les poux en une vieille pelisse
Il ne faut pas siffler dans la côte ou bien le loup s’amène
Il ne faut pas souffler le feu qui ne brûle pas
Il ne faut pas s’asseoir entre deux escabeaux
Il ne faut pas s’irriter contre les évènements
Il ne faut pas s’étendre plus long que sa couverture
Il ne faut pas tant baiser son ami à la bouche que le cœur lui en fasse mal
Il ne faut pas tant regarder ce que l’on mange qu’avec qui l’on mange
Il ne faut pas tisonner le feu avec un couteau
Il ne faut pas tomber dans une maison comme une hirondelle dans une cheminée
Il ne faut pas toucher aux idoles
Il ne faut pas toujours croire ce que l’on voit
Il ne faut pas toujours se plaindre avec du mal
Il ne faut pas tuer tout ce qui est gras
Il ne faut pas vendre la peau de l’ours avant de l’avoir tué
Il ne faut pas être plus royaliste que le roi
Il ne faut pas être trop vif pour vivre
Il ne faut passer que de pays en autre pour être gentilhomme
Il ne faut point avoir noise ni débat avec mauvaises gens
Il ne faut point croire de choses impossibles
Il ne faut point de mémoire pour connaître les bons vins
Il ne faut point parler d’autrui qui ne veut payer ses dettes
Il ne faut point permettre que la poule chante le coq
Il ne faut point prendre conseil d’un homme qui fait mal ses besognes
Il ne faut point prendre de serviteur ni de servante qui soient ou riches ou trop chétifs
Il ne faut point se fier ni à l’air serein ni a une femme qui pleure
Il ne faut point éveiller le chat qui dort
Il ne faut publier ni les faveurs des femmes ni celles des rois
Il ne faut que tourner le dos à Dieu pour devenir riches
Il ne faut qu’un coup de pied pour renverser une fourmilière
Il ne faut qu’un coup pour tuer un putois
Il ne faut qu’un fol pour faire choir un quartier de pierre dans un puits, mais il faut dix sages pour l’en tirer
Il ne faut qu’une brebis galeuse pour contaminer tout le troupeau
Il ne faut rien acheter dans un sac
Il ne faut rien croire de ce qu’on voit et puis rien que la moitié de ce qu’on entend
Il ne faut rien mettre au cerveau pour tenir la place de ce qu’on doit mettre
Il ne faut se moquer des chiens que quand on est hors du village
Il ne faut s’enquérir d’où est l’homme, d’où est le vin, d’où est le dire, mais qu’il soit bon
Il ne faut toucher ses yeux qu’avec son coude
Il ne faut toucher à son ennemi que pour lui abattre la tête
Il ne faut toujours pas crier avant d’être battu
Il ne faut trembler que l’on ne voie sa tête à ses pieds
Il ne faut à la cour ni trop voir ni trop dire
Il ne faut être ni enclume ni marteau
Il ne paraît pas que la nature ait fait les hommes pour l’indépendance
Il ne parle pas au roi qui veut
Il ne part du sac que ce qui y est
Il ne peut issir du sac que ce qu’il y a
Il ne peut sortir d’un sac à charbon que ce qu’il y a dedans
Il ne pleut pas sur le chemin autant que dans la cour
Il ne pleut que sur la vendange
Il ne profite pas une figue, de moult donner à un prodigue
Il ne ressemble ni à son père ni à sa mère, par les traits du visage ou par le caractère
Il ne sait rien qui hors ne va
Il ne sait rien qui ne va par villes
Il ne saurais boire et souffler le feu
Il ne saurait partir du sac que ce qui est
Il ne saurait servir à deux autels
Il ne se fait aucun profit qu’au dommage d’autrui
Il ne se faut tuer en son métier mais y vivre
Il ne se fourvoie point qui à bon hôtel va
Il ne se hausse ni ne se baisse
Il ne se tord pas qui va le plain chemin
Il ne se tord pas qui à bon hôtel va
Il ne se trouve point d’aussi grande distance de bête à bête que d’homme à homme
Il ne serait nuls médisants, s’il n’était des écoutants
Il ne sert rien de se tant dépêcher, il faut faire le travail d’adroit
Il ne sert rien d’affirmer avec serment à celui qui n’est pas bien aise d’entendre la vérité
Il ne sert à rien d’agiter une mare d’eau sale
Il ne sert à rien d’être jeune sans être belle, ni belle sans être jeune
Il ne suffit pas de faire le bien, il faut encore le bien faire
Il ne suffit pas d’avoir de l’esprit, il faut encore en avoir assez pour éviter d’en avoir de trop
Il ne suffit pas d’avoir les mains propres, il faut avoir l’esprit pur
Il ne s’agit pas de lire beaucoup, mais de lire utilement
Il ne s’épouvante point du bruit
Il ne te faut pas aller au bois, si tu as peur des dards
Il ne va ni à messe ni à prêche
Il ne va pas tout à honte qui de demi-voie retourne
Il ne veut pas renoncer à la part qui doit lui revenir
Il ne voudrait rien de l’autrui, mais il voudrait que tout fut à lui
Il nie avec indignation avoir commis l’acte qu’on lui attribue
Il nourrit des pigeons qui veut, il les tue qui peut
Il nous faut du nouveau, n’en fût-il plus au monde
Il n’a loisir qu’il ne le prend
Il n’a pas bruit pour néant
Il n’a pas de religion
Il n’a pas fait qui commence
Il n’a pas le bec gelé
Il n’a pas soif qui d’eau ne boit
Il n’appartient pas à un vilain de renier Dieu
Il n’appartient qu’aux grands hommes d’avoir de grands défauts
Il n’appartient qu’à un sot d’être trompé plusieurs fois, le sage ne le peut être qu’une fois
Il n’arrive jamais d’aussi grand malheur que d’autres n’en vaillent de mieux
Il n’aura jamais bon marché qui ne le demande
Il n’aura jamais bon valet qui ne le nourrit
Il n’aura pas bonne part de ses noces qui n’y est
Il n’en chaut (de) savoir comme (comment) les fruits et poissons s’appellent, mais qu’ils soient bons
Il n’en chaut de le voir si on le tient
Il n’en chaut quelle âge ait la bête, si elle porte bien
Il n’en chaut savoir comme les fruits et poissons s’appellent, mais qu’ils soient bons
Il n’en jetterait pas sa part aux chiens
Il n’en n’arrive pas une sans deux
Il n’engendre pas la mélancolie
Il n’entend pas de cette oreille-là
Il n’est aboi ni chasse que de vieil (vieux) chien
Il n’est aboi que de vieil (vieux) chien
Il n’est amis aujourd’hui que de table
Il n’est anglet sans coin
Il n’est argent perdu que par faute d’argent
Il n’est au monde animal traître au prix de l’homme
Il n’est au monde si grand dommage, que seigneur à fol courage
Il n’est avoir que de preud’homme
Il n’est banquet que d’homme chiche
Il n’est besogne que d’ouvriers
Il n’est bien ne (ou) joie si hautaine qu’on prise n’est qu’on l’acquiert à peine
Il n’est bois si vert qui ne s’allume
Il n’est bon acquit que de don
Il n’est bon charretier qui ne verse
Il n’est bon maître qui jamais ne faille
Il n’est bon pour soi, ne pour autrui
Il n’est chance qui ne retourne
Il n’est chariot qui ne verse
Il n’est chasse que de vieux chiens
Il n’est chasse que de vieux chiens
Il n’est cheval qui n’ait méhaing
Il n’est cheval qui n’ait son méhain
Il n’est chose qu’on ne fasse
Il n’est chose si vile qui ne soit utile
Il n’est chose si vile qu’elle ne soit utile
Il n’est chose tant soit-elle vile, qui ne duise et ne soit utile
Il n’est condiment que d’appétit
Il n’est danger que de vilain
Il n’est danger que de vilain
Il n’est de bien faire et taire, et à Dieu complaire
Il n’est dette si tôt perdue que dette trop attendue
Il n’est digne du doux, qui n’a goûté l’amer
Il n’est débiteur qui veut
Il n’est déjeuner que d’écoliers, dîner que d’avocats, souper que de marchands, regoubillonner que de chambrières
Il n’est d’orgueil que de pauvre enrichi
Il n’est entreprise que d’homme hardi
Il n’est envie que de moine
Il n’est fagot qui ne trouve son lieu
Il n’est femme, cheval ni vache, qui n’ait toujours quelque tache
Il n’est feu que de gros bois
Il n’est forteresse qu’un âne chargé d’or ne puisse approcher
Il n’est guère de loyaux amis
Il n’est géhenne au monde que de vin
Il n’est géhenne que de vin
Il n’est hardi qui s’effraie d’un refus
Il n’est homme qui ne prend somme
Il n’est homme qui ne prenne somme
Il n’est honneur ni recueil que de dames
Il n’est jamais feu sans fumée
Il n’est jamais jour si on ne voit le soleil
Il n’est jamais tard à bien faire
Il n’est jamais trop tard pour bien faire
Il n’est jouer qu’à joueurs
Il n’est lumière que du matin, ni manger qu’à bonne faim
Il n’est mal dont bien ne vienne
Il n’est manger qu’à bonne faim
Il n’est mariage que de personnes
Il n’est marié que mort ne démarie
Il n’est martyre que d’amours
Il n’est maître qu’un bon métier
Il n’est messager que soi-même
Il n’est miracle que de vieux saints
Il n’est mis loin du cul qui à la queue se tient
Il n’est mois qui ne revienne
Il n’est nager qu’en grande eau
Il n’est noblesse que de vertu
Il n’est nul mauvais amis
Il n’est nul petit ami
Il n’est nul petit ennemi
Il n’est nulle belle prison
Il n’est nulles laides amours ni belles prisons
Il n’est nuls petits amis
Il n’est nuls petits ennemis
Il n’est nuls petits ennemis
Il n’est orgueil que de pauvre enrichi
Il n’est orgueil que de sot revêtu
Il n’est ouvrage que de maître
Il n’est ouvrage que d’ouvrier
Il n’est pas (r)assuré qui trop haut est monté
Il n’est pas aimé qui est courroucé
Il n’est pas aisé qui des chausses de sa femme fait chaperon
Il n’est pas aisé qui est courroucé
Il n’est pas aisé qui se courrouce
Il n’est pas assûr ((r)assuré) à qui ne méchoit oncques
Il n’est pas bien caché à qui le cul pert
Il n’est pas bien qu’un homme tienne à lui seul les rênes de deux femmes
Il n’est pas bon d’être malheureux, mais il est bon de l’avoir été
Il n’est pas bon maçon qui pierres refuse
Il n’est pas bon que l’homme soit seul
Il n’est pas bon que l’homme soit seul
Il n’est pas bon écolier, qui trotte et saute volontiers
Il n’est pas certain que tout soit incertain
Il n’est pas content qui se plaint
Il n’est pas couvert qui a le cul découvert
Il n’est pas de beauté où règne le désordre
Il n’est pas de cheval qui avec le temps ne devienne rosse
Il n’est pas de famille qui n’ait ses tares
Il n’est pas de fumée sans feu ni d’amour sans quelque semblant
Il n’est pas de satiété dans l’étude
Il n’est pas de vice que les femmes et les guenons ignorent
Il n’est pas digne de délacer les cordons de ses souliers
Il n’est pas digne d’être mercier qui ne sait faire sa loge
Il n’est pas facile de connaître les bonnes femmes et les bons melons
Il n’est pas fils d’homme qui ne prend somme
Il n’est pas fils d’homme qui ne prenne somme
Il n’est pas hardi qui ne s’aventure
Il n’est pas heureux qui veut
Il n’est pas homme qui n’a somme
Il n’est pas marchand qui toujours gagne
Il n’est pas marchand qui toujours gagne
Il n’est pas maçon qui pierre(s) refuse
Il n’est pas maître qui n’ose commander
Il n’est pas ne diable qui se fait noir
Il n’est pas nécessaire d’espérer pour entreprendre, ni de réussir pour persévérer
Il n’est pas pauvre qui n’a guère de bien, mais celui seul qui n’est content de rien
Il n’est pas permis de s’emporter contre la vérité
Il n’est pas permis à tout le monde d’aller à Corinthe
Il n’est pas possible de vivre heureux sans être sage, honnête et juste, ni sage, honnête et juste sans être heureux
Il n’est pas quitte qui doit de reste
Il n’est pas rassuré à qui ne méchoit oncques
Il n’est pas riche qui est chiche
Il n’est pas sage qui n’a peur d’un fol
Il n’est pas sage qui n’a peur d’un fou
Il n’est pas sain de veiller longtemps, se lever matin vaut mieux
Il n’est pas saoul qui n’a rien mangé
Il n’est pas seigneur de son pays, qui de ses sujets est haï
Il n’est pas si diable qu’il est noir
Il n’est pas si méchant qu’il le paraît
Il n’est pas si petit buisson qui ne porte ombre
Il n’est pas sire en son pays, qui de ses sujets est haï
Il n’est pas sûr que cette personne soit celle dont il s’agit, car beaucoup porte le même nom
Il n’est pas temps de fermer les étables quand les chevaux sont pris
Il n’est pas temps de fermer l’étable quand le cheval est perdu
Il n’est pas toujours fête
Il n’est pas toujours saison de brebis tondre
Il n’est pas toujours saison de tondre brebis et mouton
Il n’est pas toujours temps de brebis tondre
Il n’est pas à soi qui est ivre
Il n’est pas échappé qui traîne son lien
Il n’est pauvreté que d’ignorance et maladie
Il n’est permis d’affirmer qu’en géométrie
Il n’est personne qui n’aime la médiocrité dorée
Il n’est pire aveugle que celui qui ne veut pas voir
Il n’est pire eau que l’eau celle qui dort
Il n’est pire ennemi que ses proches
Il n’est pire sourd que celui qui ne veut pas entendre
Il n’est plaisir que d’avoir jouissance
Il n’est plus nécessaire d’étudier les hommes que les livres
Il n’est plus sot que celui qui pense être fin
Il n’est plus temps de fermer les écuries quand les poulains sont dehors
Il n’est plus temps de secouer le joug que l’on s’est imposé
Il n’est point de faveur, alors qu’on en est digne
Il n’est point de garant de forfait ni de folie
Il n’est point de haines implacables, sauf en amour
Il n’est point de petit chez soi
Il n’est point de pire sourd que cil (celui) qui feint le lourd
Il n’est point de terre plus douce que la patrie
Il n’est point d’armes plus puissantes que la vertu
Il n’est point d’herbe contre la mort
Il n’est pour voir que l’œil du maître
Il n’est péché ni (ou) mal tant soit celé qu’en fin ne soit connu et révélé
Il n’est pêcher qu’en eau trouble
Il n’est que boire à la vraie source
Il n’est que bon que les hommes voient de temps à autre comme il fait bon sans femme
Il n’est que de hanter les preuds (preux) et bons
Il n’est que de nager en grande eau
Il n’est que de plier et dresser une plante quand elle est tendre et pliable
Il n’est que de prendre son refuge à Christ
Il n’est que de remédier au mal en temps opportun
Il n’est que de suivre la cohorte des bons et vertueux
Il n’est que de suivre le grand chemin
Il n’est que de vivre
Il n’est que d’aller le grand chemin
Il n’est que d’avoir affaire à gens de bien
Il n’est que d’avoir d’esprit bonne ouverture
Il n’est que d’avoir jouissance
Il n’est que d’être assis à son aise
Il n’est que d’être bien couché
Il n’est que d’être là où on fait le pot bouillir
Il n’est que d’être à son blé moudre
Il n’est que les premières amours
Il n’est que pêcher en eau trouble
Il n’est que pêcher en grand vivier
Il n’est que voir belle dame
Il n’est qui puisse la mort fuir
Il n’est qui puisse mourir fuir
Il n’est richesse que de gain
Il n’est richesse que de science et santé
Il n’est rien de plus terrible que la mer pour dompter un homme
Il n’est rien de rester tard, pourvu qu’il ne faille pas retourner
Il n’est rien de si absent que la présence d’esprit
Il n’est rien de tel que le balai neuf pour balayer la crasse
Il n’est rien d’inutile aux personnes de sens
Il n’est rien impossible à l’homme
Il n’est rien plus agréable que de trouver son pareil
Il n’est rien plus certain que la mort, ni rien plus incertain que son jour
Il n’est rien plus léger que pensée de femme
Il n’est rien que gens ne fassent
Il n’est rien que les gens ne fassent
Il n’est rien qui ne prenne fin par succession de temps
Il n’est rien qu’amour n’emporte
Il n’est règle qui ne faille
Il n’est réplique si piquante que le mépris silencieux
Il n’est sale marmite qui ne trouve son couvercle
Il n’est sauce que d’appétit
Il n’est savate qui ne trouve sa pareille, à moins qu’on ne l’ait brûlée
Il n’est secours que de vrai ami
Il n’est secret que de rien dire
Il n’est si beau acquit (acquisition) que le don
Il n’est si beaux services comme de larron
Il n’est si bel acquêt que le don
Il n’est si belle rose qui ne devienne gratte-cul
Il n’est si bien ferré qui ne glisse
Il n’est si bon char qui ne verse parfois
Il n’est si bon charretier qui ne verse
Il n’est si bon hermite qu’on ne fasse partir de son hermitage
Il n’est si bon marinier (marin) qui ne pérille
Il n’est si bon marinier qui ne périsse
Il n’est si bon parent qu’un bon ami
Il n’est si bon que femme n’assotte
Il n’est si bon qui aussi bon ne soit
Il n’est si bon qui bon ne soit
Il n’est si bon qui n’ait son compagnon
Il n’est si chétif fagot qui ne trouve son lien
Il n’est si ferré qui ne glisse
Il n’est si fin qui n’ait un tour de peigne
Il n’est si fort lien que de femme
Il n’est si fort que le commencement
Il n’est si fort qui ne trouve son maître
Il n’est si fort qui puisse fuir la mort
Il n’est si grand dépris (mépris) que de pauvre orgueilleux
Il n’est si grand péril qu’en change d’apothicaire
Il n’est si juste que femme ne diffame
Il n’est si long jour que la nuit ne suive
Il n’est si mauvais livre dont on ne puisse tirer quelque chose de bon
Il n’est si mauvais sourd que celui qui ne veut pas ouïr
Il n’est si méchant qui ne trouve sa méchante
Il n’est si petit buisson qui ne porte son ombre
Il n’est si petit qui ne puisse nuire
Il n’est si petite chapelle qui n’ait sa dédicace
Il n’est si petite chapelle qui n’ait son saint
Il n’est si riche qui n’ait affaire d’amis
Il n’est si riche qui quelquefois ne doive
Il n’est si sage qui ne faille aucunes fois
Il n’est si sage qui ne fasse des sottises
Il n’est si sûr qui ne glisse
Il n’est si vrai dire qu’en moquant
Il n’est si étrange mensonge que la femme ne croie, s’il est à sa louange
Il n’est tant de gerbes qu’en moisson
Il n’est tel pain que de froment ni tel vin que de sarment
Il n’est tel que d’avoir sa fille pourvue pour trouver des marieurs
Il n’est temps de regimber quand on s’est laissé entraver
Il n’est trésor que de sagesse et santé
Il n’est trésor que de science
Il n’est trésor que de vivre à son aise
Il n’est trésor que santé et avoir argent à planté
Il n’est viande que d’appétit
Il n’est viande si nette qu’un œuf mollet
Il n’est vie que d’être aise
Il n’est vie que d’être bien aise
Il n’est vilain qui ne fait la vilénie
Il n’est vilain qui ne fasse vilénie
Il n’est œuvre que d’ouvriers
Il n’est… si poltron, sur la terre, qui ne puisse trouver plus poltron que lui
Il n’importe d’où vient l’oiseau, s’il chante bien
Il n’importe lequel, disait celui qui prenait le plus gros morceau
Il n’importe l’âge de la vache, si elle est portante
Il n’y [modifier]
Il n’y a animal moins domptable que la femme irraisonnable
Il n’y a arbre qui n’ait quelques branches sèches
Il n’y a au-dessous du fat que celui qui l’admire
Il n’y a aucune mauvaise chaussure qui ne trouve sa pareille
Il n’y a avoir qui vaille savoir
Il n’y a beau maître qui ne se trompe
Il n’y a bête tant soit fière, qui ne se délecte de sa pareille
Il n’y a bêtise qu’un fou n’y crie
Il n’y a celui qui n’aime mieux son profit que celui de son voisin
Il n’y a chance que pour la canaille
Il n’y a chance qui ne rechance
Il n’y a chance qui ne vire
Il n’y a char qui ne verse
Il n’y a chose moins recouvrable que le temps
Il n’y a chose qui plus décontente, que de vivre entre mal gent
Il n’y a chose tant ardue, qu’en bien cherchant ne soit connue
Il n’y a chose tant soit celée, que le temps ne rende avérée
Il n’y a chose tant soit vile qu’elle ne profite à cil (celui) qui en sait la valeur
Il n’y a danger que du trop
Il n’y a de damnés que les obstinés
Il n’y a de la chance que pour la crapule
Il n’y a de mariage qu’une seule fois ni de paradis qu’en un seul endroit
Il n’y a de nouveau que ce qui a vieilli
Il n’y a de nouveau que ce qui est oublié
Il n’y a de plaisir agréable que celui qui se renouvelle en variant
Il n’y a de science que du général
Il n’y a de vraiment bons que les gens bien portants
Il n’y a diligence qui satisfasse, à cil que hâtiveté presse et chasse
Il n’y a douleur qui ne se passe par succession de temps
Il n’y a d’ami, d’épouse, de père ou de frère que dans la patrie; L’exilé partout est seul
Il n’y a d’impossible que ce qui implique contradiction
Il n’y a en amour que les honteux qui perdent
Il n’y a en ville ni village, arts ni métiers où n’y ait plus de méchants que de bons ouvriers
Il n’y a engin tant bon qu’il soit qui n’ait besoin de doctrine
Il n’y a ennemi plus vénéfique que le familier et domestique
Il n’y a ennemi plus vénéfique, que le familier et domestique
Il n’y a femme sans amour, samedi sans soleil, dimanche sans plaisir ni vieillard sans douleur
Il n’y a femme, bête, cheval ni vache, qui n’ait toujours quelque tache
Il n’y a femme, cheval ni vache, qui n’ait toujours quelque tache
Il n’y a femme, cheval ni vache, qui n’eut quelque tache
Il n’y a fer, acier ou diamants, qui vaillent contre le temps
Il n’y a grain ni guère d’intérêt d’être enseveli en liqueurs aromatiques ou en un fumier
Il n’y a grand riche ni celui qui n’ait besoin du petit
Il n’y a guère au monde un plus bel excès que celui de la reconnaissance
Il n’y a guère d’homme assez habile pour connaître tout le mal qu’il fait
Il n’y a guère qu’une naissance honnête, ou qu’une bonne éducation qui rende les hommes capables de secret
Il n’y a géhenne que de femme et de vin
Il n’y a homme de mère né, qui sache ce qui lui pend au nez
Il n’y a homme tant soit-il sage, qui du futur soit présage
Il n’y a honneur ni dignité, qui vaille salut, sagesse et santé
Il n’y a jamais de va-nu-pieds qu’il n’y ait une va-nu-pieds
Il n’y a jamais manque de place pour la vertu
Il n’y a meilleur parent que l’ami fidèle et prudent
Il n’y a meilleur parent que l’ami fidéle et prudent
Il n’y a meilleure plante fruitière que la femme vertueuse
Il n’y a neige ni glace que le soleil ne fonde
Il n’y a neige ni glace que le soleil ne fonde
Il n’y a ni bêtes ni gens
Il n’y a ni laid pot qui ne trouve son couvercle
Il n’y a ni samedi sans soleil ni jeune fille sans amour
Il n’y a nul petit ennemi
Il n’y a pas de belle fille sans lentille, pas de beau garçon sans bouton
Il n’y a pas de belle fille sans tache de rousseur, pas de beau garçon sans bouton
Il n’y a pas de belle rose qui ne porte gratte-cul
Il n’y a pas de belles prisons ni de laides amours
Il n’y a pas de bonne fête sans lendemain
Il n’y a pas de brouillard sans eau
Il n’y a pas de cheval que leur mettent pas la bride
Il n’y a pas de chiens sans puces ni de mules sans vices ni de femmes sans malice
Il n’y a pas de couronnes sans épines
Il n’y a pas de curieux qui ne soit malveillant
Il n’y a pas de fataliste absolu, même à Constantinople
Il n’y a pas de femme plus mal chaussée que la femme du cordonnier
Il n’y a pas de force sans adresse
Il n’y a pas de fraude à tromper un trompeur
Il n’y a pas de fruit qui n’ait été âpre avant d’être mûr
Il n’y a pas de fumée sans feu
Il n’y a pas de grenouille qui ne trouve son crapaud
Il n’y a pas de guerre sans paix
Il n’y a pas de guerre sans paix
Il n’y a pas de jeune fille sans amour ni de femme enceinte sans douleur
Il n’y a pas de laides amours
Il n’y a pas de maison dont le sol ne se salisse
Il n’y a pas de maison sans croix
Il n’y a pas de mal sans bien
Il n’y a pas de mariage sans fleurs ni de mort sans pleurs
Il n’y a pas de mauvais sabot qui ne trouve de quoi faire la paire
Il n’y a pas de mauvaise chaussure qui ne trouve sa pareille
Il n’y a pas de meilleur médecin que soi-même
Il n’y a pas de meilleur remède que celui qui réussit
Il n’y a pas de mortel qui soit sage à toute heure
Il n’y a pas de moyen pour polir le hérisson
Il n’y a pas de médecin pour la peur
Il n’y a pas de noce(s) sans deuil ni de samedi sans soleil
Il n’y a pas de noces sans lendemain
Il n’y a pas de petites économies
Il n’y a pas de pied qui ne trouve son sabot
Il n’y a pas de pire mal que celui de ne pouvoir pas durer dans l’aise ou dans la prospérité
Il n’y a pas de plus grande allégresse pour un fils que la gloire d’un père, et pour un père que les exploits d’un fils
Il n’y a pas de plus pesant fardeau qu’une fille qui apporte une grosse dot
Il n’y a pas de quinze ans laids
Il n’y a pas de richesse préférable à la santé du corps
Il n’y a pas de route royale vers la géométrie
Il n’y a pas de sabot sous le lit qui ne trouve son pareil
Il n’y a pas de samedi sans soleil comme il n’y a pas de fille sans amour
Il n’y a pas de samedi sans soleil ni de belle fille sans amour ni de vieille femme sans douleur
Il n’y a pas de samedi sans soleil ni de femme sans conseil
Il n’y a pas de sarcloir qui ne trouve son manche
Il n’y a pas de sot métier
Il n’y a pas de source de profits aussi sûre que l’économie
Il n’y a pas de vendredi sans deuil ni de samedi sans soleil
Il n’y a pas d’effet sans cause ; toute rumeur a quelque fondement
Il n’y a pas d’oison qui ne trouve son enclos
Il n’y a pas loin de la porcherie à la civière
Il n’y a pas là de quoi fouetter un chat
Il n’y a pas petit pot qui ne trouve son couvercle
Il n’y a pas plus de belles filles sans amourettes que de beaux monticules sans merdre de chien
Il n’y a pas plus de samedis sans soleil que de filles sans amoureux
Il n’y a pas plus de samedis sans soleil que de vieille femme sans conseils
Il n’y a pas plus de samedis sans soleil que vieille femme sans conseils
Il n’y a pas plus sourd que celui qui ne veut pas entendre
Il n’y a pas sur la terre d’homme juste qui fasse le bien sans jamais pécher
Il n’y a pas une dette qui ne se paie
Il n’y a pas une fille sans amant
Il n’y a pas une fille sans amour
Il n’y a pas une méthode unique pour étudier les choses
Il n’y a pas une rose sans un églantier
Il n’y a personne de plus sourd que celui qui ne veut pas croire
Il n’y a personne de plus sourd que celui qui ne veut pas entendre
Il n’y a pire débat que plusieurs mains à un plat
Il n’y a pire débat que plusieurs mains à un plat
Il n’y a pire ennemi qu’un familier ami
Il n’y a pire mal qu’une mauvaise femme, mais rien n’est comparable à une femme bonne
Il n’y a pièce sur le corps, qui ne soit bute de la mort
Il n’y a plus d’assurance au temps non plus qu’à une femme
Il n’y a plus d’attente où il n’y a plus d’espérance
Il n’y a plus d’enfants
Il n’y a plus d’huile dans la lampe
Il n’y a plus que le nid, les oiseaux s’en sont envolés
Il n’y a plus sourd que celui qui ne veut ouïr
Il n’y a point de belle chair près des os
Il n’y a point de bonheur sans courage, ni de vertu sans combat
Il n’y a point de bonne recette pour les gourmands, les ivrognes et les fainéants
Il n’y a point de corneille qui ne trouve ses enfants beaux
Il n’y a point de dette sitôt payée que le mépris
Il n’y a point de fumée sans feu
Il n’y a point de gens qui aient plus souvent tort que ceux qui ne peuvent souffrir d’en avoir
Il n’y a point de génie sans un grain de folie
Il n’y a point de joie meilleure que la joie du cœur
Il n’y a point de laides amours pour celui qui aime
Il n’y a point de laides amours, ni de belles prisons
Il n’y a point de maître d’armes mélancolique
Il n’y a point de montagne sans vallée
Il n’y a point de montée qui n’ait sa dévallée
Il n’y a point de pelle qui ne trouve son fourgon
Il n’y a point de pied contrefait qui ne trouve (un) sabot à sa convenance
Il n’y a point de pire eau que l’eau qui dort
Il n’y a point de plaisir où il y a perte
Il n’y a point de plus sage abbé que celui qui a été moine
Il n’y a point de pot qui ne trouve son couvercle
Il n’y a point de si chétif fagot qui ne trouve son lien
Il n’y a point de si empêché que celui qui tient la queue de la poêle
Il n’y a point de traité entre le lion et l’homme, et le loup et l’agneau ne vivent pas en concorde
Il n’y a point de vice qui n’ait une fausse ressemblance avec quelque vertu, et qui ne s’en aide
Il n’y a point de vices que les femmes et les ivrognes ignorent
Il n’y a point de vie sans peine
Il n’y a point de vieux chaudron qui ne trouve sa crémaillère
Il n’y a point d’accidents si malheureux dont les habiles gens ne tirent quelque avantage
Il n’y a point d’eau plus dangereuse que celle qui dort
Il n’y a que celui qui en a, qui mette du poivre sur les choux de son potage
Il n’y a que ceux qui ne font rien, qui ne se trompent point
Il n’y a que ceux qui ont appris à commander qui sachent obéir
Il n’y a que ceux qui sont dans les batailles qui les gagnent
Il n’y a que deux braves femmes au monde, l’une est perdue, l’autre on ne peut pas la trouver
Il n’y a que la foi qui sauve
Il n’y a que la force de l’État qui fasse la liberté de ses membres
Il n’y a que la main d’un ami qui arrache l’épine du cœur
Il n’y a que la vérité qui blesse
Il n’y a que le cœur qui aille aussi vite que les hirondelles
Il n’y a que le méchant qui soit seul
Il n’y a que le premier pas qui coûte
Il n’y a que les bonnes bêtes qui se saoulent
Il n’y a que les honteux qui perdent
Il n’y a que les personnes qui ont de la fermeté qui puissent avoir une véritable douceur
Il n’y a que les rois et les cocus qui aient le droit de faire grâce
Il n’y a qu’heur en ce monde et malheur
Il n’y a qu’heur et malheur en ce monde
Il n’y a qu’un bon mariage et c’est le premier
Il n’y a qu’un chien laid pour bien aboyer
Il n’y a qu’un mot qui serve
Il n’y a qu’un pas du fanatisme à la barbarie
Il n’y a qu’une brave femme, tous croient l’avoir
Il n’y a qu’une goutte d’eau entre propre et sale
Il n’y a qu’une mauvaise heure au jour
Il n’y a qu’une sorte d’amour, mais il y en a mille différentes copies
Il n’y a qu’à être en Espagne pour n’avoir plus envie d’y bâtir des châteaux
Il n’y a reine sans sa voisine
Il n’y a rien (d’)honnête qui ne soit utile
Il n’y a rien de meilleur pour l’homme que d’être toujours allègre bien faisant pendant sa vie
Il n’y a rien de moindre qu’un enfant gâté
Il n’y a rien de plus difficile à conduire qu’une femme, puis des rouelles de charrue
Il n’y a rien de plus difficile à tenir que le trop aise
Il n’y a rien de plus difficile à écorcher que la queue
Il n’y a rien de plus doux à entendre que le discours d’un père qui loue son fils
Il n’y a rien de plus malheureux que d’être trompé et battu
Il n’y a rien de plus tôt gagné que de la bouche économisé
Il n’y a rien de plus éloquent que l’argent comptant
Il n’y a rien de sale que ce qui n’est pas à sa place
Il n’y a rien de si beau que ce qu’on a
Il n’y a rien de si beau que ce qu’on n’a pas
Il n’y a rien de si infortuné qu’un homme qui n’a jamais souffert
Il n’y a rien de si rapide qu’un sentiment d’antipathie
Il n’y a rien de tel que ce dont on a l’habitude
Il n’y a rien de tel que ce qu’on a coutume
Il n’y a rien d’absolu dans la morale, et en morale
Il n’y a rien d’aussi mauvais qu’un petit chien
Il n’y a rien d’aussi patient que le travail, il attend toujours qu’on le fasse
Il n’y a rien d’aussi vite oublié que la mort
Il n’y a rien d’étrange dans le monde que le vice
Il n’y a rien plus difficile à tenir que le trop aisé
Il n’y a rien que ce qu’on n’a pas qui nous pourrait contenter
Il n’y a rien que les hommes aiment mieux à conserver et qu’ils ménagent moins que leur propre vie
Il n’y a rien qui aille aussi vite que le temps
Il n’y a rien qui n’ait son envers
Il n’y a rien qui se repaît mieux que le temps
Il n’y a rien sur la terre qui en temps et en lieu ne se serre
Il n’y a rien sûr que de mourir
Il n’y a rien à avoir pitié d’un canard boiteux
Il n’y a roi qui n’ait prince issu de paysan ou rôturier, ni rustique qui ne vienne de roi
Il n’y a si beau cheval qui ne (de)vienne rosse, il n’y a si belle fille qui ne vienne une brasse-bouse
Il n’y a si beau cheval qui ne devienne rosse
Il n’y a si bel état que de vivre de ses rentes
Il n’y a si belle chaussure qu’elle ne devienne savate
Il n’y a si bon charretier qui ne verse quelquefois
Il n’y a si bon qui ne perdit patience
Il n’y a si difficile que le commencement
Il n’y a si dur fruit et acerbe qui ne se mûrisse
Il n’y a si fin renard qui ne trouve plus finard
Il n’y a si fort que la mort ne renverse
Il n’y a si fort qui ne trouve son maître
Il n’y a si fort à écorcher que la queue
Il n’y a si grand ni si sage, qui du petit n’ait bien dommage
Il n’y a si grand qui n’ait métier du petit
Il n’y a si grand qu’il n’ait besoin du petit
Il n’y a si grande faute que de laisser son chemin
Il n’y a si grande maison que le vent n’y tire
Il n’y a si long jour qui ne vienne à la nuit
Il n’y a si méchant pot qui ne trouve son couvercle
Il n’y a si petit animalon qui ne devienne lion pour défendre son bastion
Il n’y a si petit buisson qui ne porte son ombre
Il n’y a si petit métier qui ne nourrisse son maître
Il n’y a si petit pot qu’il ne trouve sa poche
Il n’y a si petit saint à qui il ne faille sa chandelle
Il n’y a si petite demoiselle qui ne veuille être priée
Il n’y a si petite mouche qui n’ait sa petite croix
Il n’y a si petite rivalité qui ne porte préjudice
Il n’y a si riche qui n’ait besoin d’amis
Il n’y a si sage qui à la fois ne rage
Il n’y a si vaillant qui ne trouve son maître
Il n’y a si vieille jument qui ne trouve son cavalier
Il n’y a si vile qui ne soit utile
Il n’y a tant bon cheval qui ne bronche
Il n’y a tel que les fous pour prédire l’avenir
Il n’y a tels ennemis que les amis
Il n’y a veneur qui ne prenne plaisir à corner sa prise
Il n’y arrive jamais de malheur que quelqu’un n’en vaille de mieux
Il n’y aura jamais assez de paille et assez de foin pour fermer la bouche aux médisants
Il n’y avait en tout que deux femmes supportables, la première s’est pendue, la seconde est au diable
Il n’y eut jamais belles prisons ni légères amours
Il n’y eut jamais peau de lion à bon marché
Il n’y pas de hauts sans bas
Il n’y pas de mariages sans pourparlers
Il paraît bon pour n’avoir pas le moyen de faire le mauvais
Il parle comme un aveugle des couleurs
Il perd le sens qui perd le sien
Il peut bien espérer au cieux qui désespère en terre
Il peut bien peu, qui ne peut nuire
Il peut exister de la différence entre les choses de même espèces, personnes de même rang
Il peut se passer beaucoup de choses entre le désir et la réalisation d’un désir Mythologie : Ancée, après des vendanges favorables, élevait une coupe pleine de vin vers ses lèvres, quand un sanglier furieux, bondit sur lui et le tua avant qu’il est eut le temps de vider la coupe – Homère : Ulysse décocha une flèche mortelle à Antinoüs, au moment où celui-ci levait sa coupe
Il plaide beau qui plaide sans partie
Il plaide bien qui plaide sans partie
Il plaidoie beau qui plaidoie sans partie
Il pleut à tous vents
Il procède d’un cœur vile et très ord, de prendre femme pour son trésor
Il promet le ciel pour héritage, mais il donnera l’enfer pour partage
Il promet merveilles, mais il ne tient rien
Il rentre par la cheminée, ce qui sort de la cuisine
Il ressemble aux anguilles de Melun, il crie avant qu’on l’écorche
Il ressemble le baillis, il prend derrière et devant
Il ressemble le lieutenant, il prend du tort et du droit
Il reste encore beaucoup à faire, à récolter, dans une science, une entreprise
Il rit assez qui rit le dernier
Il réunit tous les suffrages, celui qui a su mêler l’utile à l’agréable
Il sait trop de chasse qui a été veneur
Il se châtie bien qui se châtie par autrui
Il se faut entraider
Il se faut garder de fols et de leurs faits
Il se faut garder de la cloche comme du canon
Il se faut garder du devant d’un bœuf, du derrière d’un âne et d’un moine de tous côtés
Il se faut lever avant courir
Il se faut prêter à autrui et ne se donner qu’à soi-même
Il se faut savoir contenter de ce qu’on a
Il se fâche d’une chose de quoi il n’a que faire
Il se marierait avec le cul de la lune pour engendrer le beau temps
Il se moque de la misère, l’abondance ne lui peut rien
Il se mord à la queue
Il se mêle de parler de choses qu’il ne connaît pas
Il se noierait dans son crachat
Il se peut seoir sans contredit, qui se met où son hôte lui commande
Il se trouve autant de différence de nous à nous-même, que de nous à autrui
Il se trouve toujours quelqu’un pour jeter des pierres à l’arbre lourd de fruits
Il se trouvent plus de capitaines à table qu’au camp
Il se trouvent plus d’accidents de chirurgie que de médecine
Il se vante de battre sa femme, celui qui n’en a pas
Il semble à un larron que chacun lui est compagnon
Il semble à un larron que chacun lui ressemble
Il serait assez riche, celui qui saurait l’avenir
Il sied au progrès de respecter ce qu’il remplace
Il sied plus mal à un ministre de dire des sottises que d’en faire
Il suffit de l’emporter sur son ennemi; c’est trop de le perdre
Il suffit d’inspirer le regret d’un tort, sans toujours exiger son aveu
Il s’a beau taire de l’écot qui ne paie rien
Il s’a beau taire de l’écot qui rien n’en paye
Il s’a beau taire de l’écot, celui qui est franc
Il s’en défend comme d’un meurtre
Il te faut bien fanner si tu veux bien aryer
Il te semble que chacun est semblable à toi
Il va en son vivant en enfer, qui par avarice à deux autels sert
Il va plus au marché de peaux d’agneaux que de vieilles brebis
Il va à Castro pour fuir le travail, néanmoins là aussi la viande ne lui viendra pas d’elle-même à la bouche
Il va à la boucherie plus de veaux que de bœufs
Il vaudrait mieux savoir que d’avoir
Il vaut encore mieux court cul que tout nu
Il vaut encore mieux qu’il fasse mauvais temps que pas de temps du tout
Il vaut mieux (bien, à fond) savoir un métier que dix à peu près
Il vaut mieux acheter qu’emprunter
Il vaut mieux avaler que cracher
Il vaut mieux avoir affaire au boulanger qu’au curé ou au médecin
Il vaut mieux avoir affaire avec un sourd qu’avec un étourdi
Il vaut mieux avoir des ailes que des cornes
Il vaut mieux avoir en paix un œuf qu’en guerre un bœuf
Il vaut mieux avoir envie que pitié
Il vaut mieux avoir flux de bourse que de ventre
Il vaut mieux avoir l’air que la chanson
Il vaut mieux avoir que compter d’avoir
Il vaut mieux avoir que voir
Il vaut mieux avoir un mari qui aime l’écu que les liens
Il vaut mieux boire le cafe tiède que trop chaud
Il vaut mieux boire à la fontaine qu’au tonneau
Il vaut mieux bourse vide que tête vide
Il vaut mieux changer de plat que d’assiette
Il vaut mieux chanter avec un laid que pleurer avec un joli
Il vaut mieux chanter loin de chez soi que pleurer chez soi
Il vaut mieux chanter près d’une laide que pleurer près d’une belle
Il vaut mieux cheminer et puis s’asseoir que de courir et puis de s’éreinter
Il vaut mieux coucher avec sa chambrière que de plaider
Il vaut mieux courir après qu’avant
Il vaut mieux courir avant qu’après
Il vaut mieux court cul que tout nu
Il vaut mieux céder que procéder
Il vaut mieux deux soutiens que rien qu’un
Il vaut mieux dire « laide allons souper » que « belle qu’avons nous à souper »
Il vaut mieux dire « laide mettons-nous à table » que « belle allons-nous coucher »
Il vaut mieux dix de blesses qu’un de tué
Il vaut mieux donner la laine que la brebis
Il vaut mieux donner que recevoir
Il vaut mieux du pain dans la panetière qu’un beau garçon dans la rue
Il vaut mieux du pain dans l’armoire qu’un bel homme dans la rue
Il vaut mieux du pain sec avec amour que poulets avec des cris
Il vaut mieux déjeuner sans messe que sans vin
Il vaut mieux d’allumer la lampe plutôt que de jurer contre la nuit
Il vaut mieux d’avoir que de devoir
Il vaut mieux endurer que de se fâcher
Il vaut mieux entendre un bœuf parler qu’une fille siffler
Il vaut mieux exceller en une chose que d’être médiocre en plusieurs
Il vaut mieux faire envie que pitié
Il vaut mieux faire les choses soi-même si l’on veut un meilleur résultat
Il vaut mieux faire les choses soi-même si l’on veut un meilleur résultat
Il vaut mieux faire que (de) dire
Il vaut mieux faire vie qui dure que vie qui rompt
Il vaut mieux fermer sa bouche que de mal parler
Il vaut mieux folie que mélancolie
Il vaut mieux glaner dix ans que de ne moissonner qu’une fois
Il vaut mieux glaner dix ans que n’en moissonner qu’un
Il vaut mieux habit trop large que déchiré
Il vaut mieux habiter à Vérone près de Bologne qu’à Péronne près de Boulogne
Il vaut mieux hasarder de sauver un coupable que de condamner un innocent
Il vaut mieux irriter un chien qu’une vieille femme
Il vaut mieux juger le résultat global qu’une partie
Il vaut mieux laisser son enfant morveux que de lui arracher le nez
Il vaut mieux le bois que l’écorce
Il vaut mieux le milieu que les bords
Il vaut mieux le passereau dans la casserole que le ramier en haut de l’épicéa
Il vaut mieux l’avoir été en herbe, et ne l’être point en gerbe
Il vaut mieux manger du pain de son que de n’en manger pas du tout
Il vaut mieux marier un dégourdi que cent couillons
Il vaut mieux mettre aux jambes qu’au ventre
Il vaut mieux monter sur un clocher que sur une brèche
Il vaut mieux mourir que mal vivre
Il vaut mieux mourir selon les règles que de réchapper contre les règles
Il vaut mieux nourriture abandonnée que panse crevée
Il vaut mieux pain sans nappe que nappe sans pain
Il vaut mieux pardonner aux autres qu’à soi-même
Il vaut mieux partir que compter et compter que partir
Il vaut mieux payer le boucher que le médecin
Il vaut mieux payer le boulanger que le médecin
Il vaut mieux pays gâté que pays perdu
Il vaut mieux perdre la borle que le singe
Il vaut mieux perdre la fenêtre que toute la maison
Il vaut mieux peu de bien et ne devoir rien que d’avoir beaucoup de bien et être accablé de dettes
Il vaut mieux peu et bon que beaucoup et mauvais
Il vaut mieux plaire et être au gré d’un homme de bien que de plusieurs mauvais
Il vaut mieux ployer (plier) que rompre
Il vaut mieux plus tard que jamais
Il vaut mieux porter envie que pitié
Il vaut mieux prendre des initiatives et se tromper que de ne pas agir
Il vaut mieux prendre des précautions que d’agir sans réfléchir et subir ensuite les conséquences négatives de ses actes
Il vaut mieux prier Dieu que ses saints
Il vaut mieux prévenir que guérir
Il vaut mieux prêter sur gages que sur rien
Il vaut mieux prêter à un ami que d’emprunter à un ennemi
Il vaut mieux péter en compagnie que crever tout seul
Il vaut mieux péter et trotter que crever
Il vaut mieux que tes enfants te demandent, que d’avoir toi-même à regarder vers les mains de tes enfants
Il vaut mieux recevoir un coup de merlin qu’un coup de langue
Il vaut mieux rien faire que mal faire
Il vaut mieux rien prendre que mal prendre
Il vaut mieux rire auprès d’un vieux que de pleurer auprès d’un jeune
Il vaut mieux rire auprès d’un vieux que pleurer auprès d’un jeune
Il vaut mieux réfléchir avant de parler que de dire une bêtise Voir aussi l’autre forme : Pense deux fois avant de parler, tu en parleras deux fois mieux
Il vaut mieux savoir un métier que dix à peu près
Il vaut mieux se brûler à la maison qu’à l’église
Il vaut mieux se fier à un cheval sans bride qu’à un discours sans ordre
Il vaut mieux se marier que brouter sur les autres
Il vaut mieux se marier que de brûler
Il vaut mieux se taire que de trop bavarder
Il vaut mieux se taire que mal parler
Il vaut mieux se tenir au tronc qu’à la branche
Il vaut mieux sentir du vin que le boire
Il vaut mieux soigner la peau que la chemise
Il vaut mieux sortir de la rive que du milieu
Il vaut mieux suer que trembler
Il vaut mieux suivre Diogène en philosophant qu’Aristippe
Il vaut mieux s’adresser au Bon Dieu qu’aux saints
Il vaut mieux s’adresser à Dieu qu’à ses saints
Il vaut mieux s’arranger que de procéder
Il vaut mieux tard que jamais
Il vaut mieux tard que mal, et cela en tout genre
Il vaut mieux tendre la main que le cou
Il vaut mieux tenir que courir
Il vaut mieux tenir que quérir
Il vaut mieux tomber ès mains d’un médecin heureux que d’un médecin savant
Il vaut mieux tout manger que tout dire
Il vaut mieux tête faite que tête à faire
Il vaut mieux un bon ami que cent parents
Il vaut mieux un bon ami qu’un mauvais parent
Il vaut mieux un bon mois qu’une mauvaise année
Il vaut mieux un bon reste qu’une mauvaise entamure
Il vaut mieux un boquet qu’un roquet
Il vaut mieux un chapeau que deux coiffes
Il vaut mieux un chien bien portant qu’un homme malade
Il vaut mieux un coup de poing qu’un coup de langue
Il vaut mieux un morceau de pain sec avec appétit que chapons et poules avec dégoût
Il vaut mieux un oiseau dans la main que six sur la cime
Il vaut mieux un pet hors du cul qu’un œil hors de la tête
Il vaut mieux un petit dégourdi qu’un grand tout ébaudi
Il vaut mieux un petit feu qui echauffe qu’un gros qui brûle
Il vaut mieux un peu attendre que trop se dépécher
Il vaut mieux un peu de folie que de mélancolie
Il vaut mieux un rat vivant qu’un chien crevé
Il vaut mieux un trou au coude qu’un pli au ventre
Il vaut mieux un vieil homme qu’un jeune qui vous assomme
Il vaut mieux un voisin proche qu’un proche parent
Il vaut mieux un âne vivant qu’un docteur mort
Il vaut mieux un œuf avec paix qu’un veau avec guerre ou dissension
Il vaut mieux une brebis à l’étable qu’à la chambre haute
Il vaut mieux user des sabots que des draps de lit
Il vaut mieux user des souliers que des draps
Il vaut mieux venir au benedicite qu’aux grâces
Il vaut mieux visiter l’enfer de son vivant qu’une fois mort
Il vaut mieux vivre en sûreté pauvrement qu’en grand hasard et péril richement
Il vaut mieux voir le diable que la mort
Il vaut mieux voir les faîtes que les pignons
Il vaut mieux voler en amour qu’en mariage
Il vaut mieux être au sermon qu’en la loge
Il vaut mieux être banqueroutier que de n’être rien
Il vaut mieux être borgne qu’aveugle
Il vaut mieux être cocu que trépassé
Il vaut mieux être de par soi que mal attelé
Il vaut mieux être docte que docteur
Il vaut mieux être homme de prière que de brévière
Il vaut mieux être jeune en paradis que d’être vieil fol au monde
Il vaut mieux être juge de vingt-cinq médecins que de sept échevins
Il vaut mieux être juge des médecins que du prévôt des maréchaux
Il vaut mieux être jument à Talissieux que femme à Béon
Il vaut mieux être le premier de sa race que le dernier
Il vaut mieux être léger de bourse que d’esprit
Il vaut mieux être l’aiguillon que le bœuf
Il vaut mieux être mal mariée que vieille critiquée
Il vaut mieux être mauvais que sot
Il vaut mieux être oiseau de bois ou bocage que de cage
Il vaut mieux être pauvre du sien que riche de celui des autres
Il vaut mieux être premier d’un empire que d’un empereur
Il vaut mieux être sain que savant
Il vaut mieux être seul que mal accompagné
Il vaut mieux être souris que grenoille
Il vaut rien d’être trop bon
Il veut clairer rose et bouton, et puis tomber dans son étron
Il veut le beurre, l’argent du beurre, et le sourire de la crémière par-dessus le marché
Il viendra un temps ou le renard (la vache, le chien) aura besoin de sa queue
Il viendra un temps où les chiens auront besoin de leur queue
Il voit bien un poux sur la tête d’autrui et non pas les écrouelles de son vol
Il voit une paille dans l’œil du voisin
Il y a 2 beaux jours pour l’homme, lorsqu’il prend femme et qu’il l’enterre
Il y a aussi des renards à deux jambes
Il y a autant de chiens à deux pattes que de ceux à quatre
Il y a autant de douleurs dans l’amour que de coquillages sur la rive
Il y a autant de faiblesse à fuir la mode qu’à l’affecter
Il y a autant de morts d’agneaux que de brebis
Il y a autant de samedis sans soleil que de jeunes femmes sans amour
Il y a beau champ pour faire glane
Il y a beaucoup de gens qui sont plus bêtes que les bêtes
Il y a beaucoup de personnes qui entendent le sermon de la même manière qu’elles entendent vêpres
Il y a beaucoup de porteurs de férules, mais peu d’inspirés
Il y a beaucoup d’exagération dans ce récit ou bien Ces prétentions ne sont pas acceptables
Il y a beaucoup moins d’ingrats que l’on ne croît ; car il y a bien moins de généreux que l’on ne pense
Il y a bien de la différence entre chercher la plaisanterie et être plaisant
Il y a bien des bêtes à l’ombre quand le soleil est couché
Il y a bien des ânes à l’ombre quand le soleil est caché
Il y a bien plus de constance à user la chaîne qui nous tient qu’à la rompre Montaigne)
Il y a bien un droit du plus sage, mais non pas un droit du plus fort
Il y a ceux qui s’enhardissent à rien qui se trompent pas
Il y a dans la jalousie plus d’amour-propre que d’amour
Il y a dans la politesse charme et profit
Il y a dans la sobriété de la propreté et de l’élégance
Il y a dans le cerveau des femmes une case de moins, et dans leur cœur une fibre de plus que chez les hommes
Il y a dans les yeux de l’esprit, de l’âme et du corps
Il y a de bons mariages, mais il n’y en a point de délicieux
Il y a de la grâce à bien cueillir les roses
Il y a de sages sots et sots sages, par toutes villes, bourgades et villages
Il y a de tout assez, que de bonnes âmes
Il y a de tout assez, sauf de ce qui manque
Il y a des actes qui ne peuvent être dénoués de conséquences souvent fâcheuses Voir aussi : Il n’y a pas de fumée sans feu
Il y a des blessures qui ne guérissent pas
Il y a des chevilles pour boucher tous les trous
Il y a des coups où il faut savoir ne pas comprendre
Il y a des coups: Il y a des fois
Il y a des couvercles pour tous les pots
Il y a des fois plus à battre qu’à vanner
Il y a des gens que faut rien leur conter que ce qu’on veut que se resache
Il y a des gens que le Bon Dieu prend pas la peine de les punir
Il y a des gens qui mentent simplement pour mentir
Il y a des gens qui n’ont de la morale qu’en pièce, et c’est une étoffe dont ils ne se font jamais d’habit
Il y a des gens qui parlent un moment avant d’avoir pensé
Il y a des gens qui se noieraient dans un crachat
Il y a des honnêtes gens partout
Il y a des héros en mal comme en bien
Il y a des larmes pour le bonheur ; il n’y en a pas pour les grands malheurs
Il y a des lieux que l’on admire; il y en a d’autres qui touchent et où l’on aimerait vivre
Il y a des lumières que l’on éteint en les plaçant sur le chandelier
Il y a des occasions où il vaut mieux perdre que gagner
Il y a des personnes si légères et si frivoles qu’elles sont aussi éloignées d’avoir de véritables défauts que des qualités solides
Il y a des redites pour l’oreille et pour l’esprit, il n’y en a point pour le cœur
Il y a des reproches qui louent, et des louanges qui médisent
Il y a des sottises bien habillées, comme il y a des sots très bien vêtus
Il y a des souliers pour tous les pieds
Il y a des temps où l’on ne doit dépenser le mépris qu’avec économie, à cause du grand nombre de nécessiteux
Il y a des vices et des vertus de circonstances
Il y a deux beaux jours pour l’homme, lorsqu’il prend femme et qu’il l’enterrre
Il y a deux choses auxquelles il faut se faire sous peine de trouver la vie insupportable
Il y a deux manières de plaire
Il y a deux maux en amour, la guerre et la paix
Il y a deux sortes d’esprit
Il y a du bon et du mauvais partout
Il y a du bon plus que de mauvais
Il y a du mérite sans élévation, mais il n’y a point d’élévation sans quelque mérite
Il y a du pain partout
Il y a du plaisir à rencontre les yeux de celui à qui l’on vient de donner
Il y a du remède pour tout que pour la mort
Il y a du temps pour tout
Il y a encore longtemps d’ici-là
Il y a entre la jalousie et l’émulation le même éloignement qu’entre le vice et la vertu
Il y a eu Pâques avant le dimanche des Rameaux
Il y a fagots et fagots
Il y a folie à tout âge
Il y a gens et gens
Il y a la même différence entre les savants et les ignorants qu’entre les vivants et les morts
Il y a loin de la coupe aux lèvres
Il y a l’or et les perles, mais les lèvres sages sont un vase précieux
Il y a moins de mal souvent à perdre sa vigne qu’à la plaider
Il y a moyen partout
Il y a partout de la tricherie qu’aux cartes
Il y a partout des braves gens
Il y a partout des oui et des non
Il y a partout du remède qu’à la mort
Il y a partout quelque chose, sauf chez nous qui nous battons sept fois avant déjeuner
Il y a partout quelque chose, sauf où il n’y a personne
Il y a pas de bon maître qui (ne) se trompe pas
Il y a pas de bon maître sans défaut
Il y a pas de fumée sans feu
Il y a pas de meilleure école que la misère
Il y a pas de moindres maîtresses que les vieilles servantes
Il y a pas de plus gros sourd que celui qui ne veut pas entendre
Il y a pas de porte sans seuil
Il y a pas de roses sans un églantier
Il y a pas de roses sans épines
Il y a pas de saints qui vaillent le Bon Dieu
Il y a pas de vilain métier, il y a bien de vilaines gens
Il y a pas d’ânesse qui ne trouve son âne
Il y a pas qu’on se voie aboyé que de chien blessé
Il y a pas rien que les gros bœufs qui labourent la terre
Il y a pas rien que les renards qui mangent les poules
Il y a pas un malheur sans un bonheur
Il y a pas un meunier qui ait pas mangé de farine volée, il y a pas une chaire qui ait pas entendu des mensonges
Il y a pas une perte sans un profit
Il y a pas une porte sans un seuil
Il y a peu de femmes dont le mérite dure plus que la beauté
Il y a peu de maris que patience et amour de femme ne puissent gagner à la longue
Il y a peu de raison dans les armes
Il y a peu de vices qui empêchent un homme d’avoir beaucoup d’amis, autant que peuvent le faire de trop grandes qualités
Il y a peu d’honnêtes femmes qui ne soient lasses de leur métier
Il y a plus de bonheur à donner qu’à recevoir
Il y a plus de chances de rencontrer un bon souverain par l’hérédité que par l’élection
Il y a plus de chevaux que de colliers
Il y a plus de disciples que d’apôtres en France
Il y a plus de femmes putains que d’hommes ruffians
Il y a plus de fous acheteurs que de fous vendeurs
Il y a plus de fous que de sages, et dans le sage même, il y a plus de folie que de sagesse
Il y a plus de fous que d’ânes cornus
Il y a plus de gens pour adorer le soleil levant que le soleil couchant
Il y a plus de gloire à tuer les guerres avec la parole qu’à tuer les hommes avec le fer
Il y a plus de grandes fortunes que de grands talents
Il y a plus de jeunes peaux à la tannerie que de vieilles
Il y a plus de jours ouvrables que de dimanches
Il y a plus de mariés que de contents à Pâques
Il y a plus de médecins que de malades
Il y a plus de paille que de grain
Il y a plus de paroles dans un setier de vin que dans un tonneau d’eau
Il y a plus de peaux que de cuirs dans la fosse du tanneur
Il y a plus de peine à garder l’argent qu’à l’acquérir
Il y a plus de raison dans un tonnelet de vin que sur un char de blé
Il y a plus de singes que de saints
Il y a plus de vents que de corbeilles
Il y a plus de vieux ivrognes que de vieux médecins
Il y a plus de voleurs que de gibets
Il y a plus d’acheteurs que de connaisseurs
Il y a plus d’honnêtes femmes qu’on ne croit, mais pas tant qu’on le dit
Il y a plus d’outils que d’ouvriers
Il y a plus d’épines que de roses
Il y a plus que les chiens qui aboient
Il y a plus que les chiens qui jappent
Il y a plus à battre qu’à vanner
Il y a plus à crinser qu’à vanner
Il y a quelque anguille sous roche
Il y a quelque chose de plus fort que l’intérêt, c’est le dévouement
Il y a quelque fer qui loche
Il y a quelque obstacle à cette affaire
Il y a quelques rencontres dans la vie où la vérité et la simplicité sont le meilleur manège du monde
Il y a qui dit, il y a qui entend
Il y a qui fait, il y a qui voit
Il y a raine et reine
Il y a remède à tout que contre la mort
Il y a remède à tout qu’à la mort
Il y a remède à tout, sauf à la mort
Il y a rien de feu sans fumée
Il y a rien de moindre qu’un mauvais bigot
Il y a rien de pire aveugle que celui qui (ne) veut pas voir
Il y a rien de roses sans épines
Il y a rien d’aussi pénible que de vivre avec des gens mal élevés
Il y a rien d’impossible
Il y a société entre le crocodile et le roitelet
Il y a sous le ciel un temps pour tout
Il y a souvent bien des fions qui blessent plus que des punaises
Il y a tant de monsieurs aujourd’hui qu’ils n’en valent pas des sires
Il y a tant de si et de cas ès lois que tout n’est qu’un fatras
Il y a toujours en fond de vérité dans la plaisanterie
Il y a toujours moyen de s’entendre
Il y a toujours quelque chose quand les chiens aboient
Il y a trois choses que le diable ne peut comprendre, la soif des forgerons, la faim des chaudronniers et la malice des femmes
Il y a trois moyens de croire
Il y a trois personnes malignes, femme, singe et diable
Il y a trois sortes de personnes qui ont la liberté de tout dire, les enfants, les fous et les ivrognes
Il y a un art de savoir et un art d’enseigner
Il y a un certain espace entre la pote et la coupe
Il y a un certain plaisir parent de la tristesse
Il y a un diable partout
Il y a un dieu dans l’homme de bien
Il y a un enfer pour les curieux
Il y a un manche pour tous les balais
Il y a un remède à tout, si ce n’est à la mort
Il y a un temps de casser les noix et un temps de faire l’huile
Il y a un temps de ceci et un temps de cela
Il y a un temps de coudre et un temps de découdre
Il y a un temps de faire à moudre et un temps de faire au four
Il y a un temps de guerre et un temps de paix
Il y a un temps de lire l’almanac et un temps de lire la bible
Il y a un temps de pleurer et un temps de rire
Il y a un temps de se taire et un temps de parler
Il y a un temps de semer et un temps de recueillir
Il y a un temps de s’aimer et un temps de se détester
Il y a un temps de travailler et un temps de se reposer
Il y a un temps de venir au monde et un temps d’en sortir
Il y a un temps d’aller au prêtre et un temps d’aller à la vogue
Il y a un temps d’être de bonne et un temps d’être grincheux
Il y a un temps pour aimer et un temps pour haïr
Il y a un temps pour la guerre, et un temps pour la paix
Il y a un temps pour ne rien dire, il y a un temps pour parler, mais il n’y a pas un temps pour tout dire
Il y a un temps pour pleurer et un temps pour rire
Il y a un temps pour se taire et un temps pour parler
Il y a un temps pour tout
Il y a un temps pour tout, un temps pour embrasser et un temps pour s’abstenir d’embrassements
Il y a une certaine sorte d’amour dont l’excès empêche la jalousie
Il y a une espèce de honte d’être heureux à la vue de certaines misères
Il y a une fausse modestie qui est vanité, une fausse grandeur qui est petitesse, une fausse vertu qui est hypocrisie, une fausse sagesse qui est pruderie
Il y a une fin à tout
Il y a une mesure à tout
Il y a une sorte de médiocrité d’esprit naturelle à la richesse, tandis que la pauvreté et la sagesse sont proches parentes
Il y a à boire et à manger
Il y a à la foire plus d’un âne qui s’appelle Martin
Il y a écrit sous la queue du chien que jamais gendre ne fera prou
Il y a écrit sous la queue du loup que jamais bru ne fera rien
Il y aura des vices, tant qu’il y aura des hommes
Il y aura plus de joie dans le ciel pour un seul pécheur qui s’amende que pour quatre vingt dix neuf justes qui n’ont pas besoin de repentance
Il y demeure toujours une pierre sous toi que tu ne saurais ôter
Il y en a beaucoup de mariés qui, s’ils avaient le repentir aux talons, courraient diablement vite
Il y en a beaucoup de mariés qui, s’ils avaient le repentir aux talons, ils iraient diablement vite
Il y en a beaucoup qui sont venus au monde fatigués
Il y en a de si malheureux que les vers s’engendrent insques dans leur salière
Il y en a d’autres que les chiens qui aboient
Il y en a plus de mariés que de contents
Il y en a pour tous et pour toutes
Il y en a qui disent que le mariage c’est le couvent de l’attrape
Il y faut y aller finement
Il écorche bien la bête qui le pied tient
Il écorche un poux pour en avoir la peau
Il ôte à Saint Pierre pour bailler à Saint Paul
Ils font l’amour comme les chats à coups de poing
Ils mettent tout ce qu’ils veulent sur le papier
Ils nous font secouer les prunes et ce sont eux qui les mangent
Ils n’auront pas chaud, car ils ont vendu leur bois jusqu’au tremble
Ils ont chacun leur croix
Ils ont chacun leur croix, les uns plus grosse, les autres plus petite, mais le Bon Dieu a porté la plus grosse
Ils ont récolté avant les vendanges
Ils ont tous leur croix
Ils se ressemblent comme deux gouttes d’eau
Ils sont bien tous de la même matière, mais non tous de la même manière
Ils vont tant haut, tant que pour finir ils plantent le nez dans la merde
Ils vont tant haut, tant que pour finir ils tombent le nez dans la flaque
Impossible est de complaire à tous
Impossible est de tout venir à chef
Impossible n’est pas français
Improbité et vice porte son même supplice
Incapable de parler, impuissant à se taire
Incontinent qu’il sont mariés les oreilles leur pendent d’un pied
Indigence engendre rioté
Indigence ôte toute réjouissance
Ingratitude fait tôt oublier
Iniquité engendre adversité
Innocence porte sa défense
Instruire un sot, c’est recoller un pot cassé
Instruis l’enfant selon la voie qu’il doit suivre, et quand il sera vieux il ne s’en détournera point
Ire sans force divine ou humaine est vaine
Israël sera un sujet de sarcasme et de raillerie parmi les peuples
Ivre et idiot vont ensemble
Ivres et forcenés disent toute leur pensée
Ivrogne rien ne cèle
Ivrognerie cause maint accident mauvais
Ivrognerie engendre forcènerie
Ivrognerie est une zizanie et de sobriété vraie ennemie
Ivrognerie fait maint homme méprendre
Ivrognerie prive l’innocent de sa vie
Ivrognes, goinfres et gourmands ne vivent pas en bonne santé et ne meurent pas vieux
Jalousie dépasse sorcellerie
Jalousie est pire que sorcellerie
Jalousie passe rage et pleine folie
Jalousie passe sorcellerie
Jamais Dieu la clame (appel) n’oublie de l’affligé qui le supplie, de cœur humble contrit et monde (pure), et qui pardonne à tout le monde
Jamais amoureux timide n’eut belle amie
Jamais année sèche ne fait pauvre son maître
Jamais aveugle n’a eu trouvé un fer
Jamais beau parler n’écorche la langue
Jamais beauté ne sait chanter
Jamais bien menacé ne fut bien battu
Jamais bon bœuf n’a ruminé à la charrue
Jamais bon cheval ne devient rosse
Jamais bon cheval ne devint rosse
Jamais bon chien ne jappe pour rien
Jamais bon chien ne perdit sa route
Jamais bon chien n’a rogné un bon os
Jamais bon coq n’a été gras
Jamais bon gourmand n’a trouvé mauvais hareng
Jamais bon goût n’a gâté sauce
Jamais bon os ne vient à bon chien
Jamais buse n’a fait pigeon
Jamais bâtard ne fit bien
Jamais bœuf à cornes courbées n’a rien laissé perdre à son maître
Jamais carron n’a été rond
Jamais chapon n’aima poule
Jamais charogne a fait crever bétail
Jamais charogne n’a empoisonné loup
Jamais charogne n’a fait crever bétail
Jamais chat miauleur ne fut bon chasseur
Jamais chat miauleur ne fut bon chasseur non plus que grand homme bon caqueteur
Jamais chat miauleur n’a été bon chasseur
Jamais cheval bien menacé ne fut bien battu
Jamais cheval jarreté n’est resté embourbé
Jamais cheval ni bonhomme, n’amende d’aller à Rome
Jamais cheval à bon jarret n’a laissé son maître dans le bourbier
Jamais cheval à queue de rat ne laissa son maître dans l’embarras
Jamais chiche ne fut riche
Jamais chien couard ne rongea bon os
Jamais coquin n’a fait grande guerre
Jamais corbeau n’a fait canaris
Jamais couard n’érigera trophée ni paresseux fera belle levée
Jamais coup de pied de jument ne fit mal à cheval
Jamais de veuve sans conseil ni de samedi sans soleil
Jamais deux montagnes ne se rencontrent
Jamais deux orgueilleux ne chevaucheront bien un âne
Jamais dormeur ne fait bon guet
Jamais dormeur ne fit bon guet
Jamais femme muette ne fut de son mari battue
Jamais femme muette n’a été battue par son mari
Jamais femme ni cochon ne doit quitter la maison
Jamais femme sautière ne fut bonne ménagère
Jamais fille qui s’est fait trousser le cotillon n’a déshonoré une maison
Jamais fine femme ne mourut sans héritier
Jamais grain ne fructifie, si premier ne se mortifie
Jamais grand nez n’a diffamé beau visage
Jamais grand nez n’a déparé gâté beau visage
Jamais grand vanteur n’a été grand faiseur
Jamais géline n’aima chapon
Jamais homme ne fut pauvre de louer maison
Jamais homme ne fut à priser, pour savoir autrui dépriser
Jamais homme ne gagne de plaider à son seigneur
Jamais homme ne gagne qui plaide à son maître
Jamais homme ne mange foie que le sien n’en ait joie
Jamais homme sage et discret, ne révèle à femme son secret
Jamais honteux n’eut belle amie
Jamais insulain ne prend pour compain (compagnon), car mieux vaut moult lointain que trop prochain
Jamais ivrogne n’a connu le bon vin
Jamais je n’ai vu le juste abandonné, ni sa postérité mendiant son pain
Jamais jument ne fit mal de coup de pied à roussin
Jamais la colère n’a bien conseillé
Jamais la cornemuse ne dit mot si elle n’a le ventre plein
Jamais la nature ne nous trompe; c’est toujours nous qui nous trompons
Jamais la nature n’eut un langage et la philosophie (sagesse) un autre
Jamais la nymphe Calypso ne réussit à persuader Ulysse
Jamais la souris ne confie à un seul trou sa destinée
Jamais les menaces d’un père ne s’accomplissent
Jamais les poux ne crèveront
Jamais lessive ne s’est faite qui ne soit séchée
Jamais louve ne fit d’agneau
Jamais l’homme ne peut être riche, si son cœur en richesse fiche
Jamais l’homme sage et discret ne dit à sa femme son secret
Jamais maison n’a bien allé (marché) où les femmes ont gouverné
Jamais mal acquit ne profite
Jamais mal plus dangereux (grossesse) a rendu son monde si joyeux
Jamais mauvais ouvrier ne trouve bon outil
Jamais mauvais ouvrier n’a eu bon outil
Jamais mauvais ouvrier n’a trouvé de bon aise
Jamais ne fut de grand esprit qui n’eût de folie un petit
Jamais ne fut ni fera qu’une souris fasse son nid en l’oreille d’un chat
Jamais ne fut si beau soulier qui ne devient laide savatte
Jamais ne gagne qui procède à son maître
Jamais ne parlai de lui, sinon en tout honneur
Jamais ne serait médisant, s’il n’était nul écoute
Jamais ne vienne demain, n’apporte son pain
Jamais ne vienne demain, s’il ne rapporte du pain
Jamais ne vienne demain, s’il n’apporte son pain
Jamais ne vient une malheureté sans ajournement d’autre adversité
Jamais n’a-t-il bon marché qui ne l’ose demander
Jamais n’aura bon marché qui ne l’ose demander
Jamais n’aura bon serviteur qui ne le nourrit
Jamais n’est bon marché de fausse marchandise
Jamais n’est misérable l’être qui accepte facilement la mort
Jamais n’est vice de se bien taire si de parler n’est nécessaire
Jamais on a bon marché de méchantes denrées
Jamais on ne surmonte un péril sans péril
Jamais paresseux n’a eu bon temps
Jamais paresseux n’a eu grande écuelle
Jamais pauvre ne s’est marié
Jamais personne n’a trompé tout le monde, et jamais tout le monde n’a trompé personne
Jamais peureux n’a eu belle amie
Jamais pour longue demeurée n’est bon amour oublié
Jamais putain n’aima preud’homme
Jamais renard n’eut gorge emplumée, pour dormir grasse matinée
Jamais riche ne sera, qui l’autrui avec le sien ne mettra
Jamais safran n’a gâté sauce
Jamais sage homme ne vit buveur de vin sans appétit
Jamais sage homme on ne vit, buveur de vin sans appétit
Jamais sautier ne fut bon écolier
Jamais surintendant ne trouva de cruelles
Jamais teigneux n’aima le peigne
Jamais teigneux n’aimera peigne
Jamais un envieux ne pardonne au mérite
Jamais un homme ne mange foie que le sien en ait joie
Jamais une fortune ne vient seule
Jamais une maison n’a bien marché quand les femmes ont gouverné
Jamais vassal ne gagne à plaider à son seigneur
Jamais vendeur ne décrie sa bête
Jamais vertu ne fastidie et n’ennuie ni beauté assouvit
Jamais veuve sans conseil ni samedi sans soleil
Jamais vieil singe ne fait belle moue
Jamais vieille femme ni grand vent n’ont couru pour rien
Jamais vieux singe ne fait belle moue
Jamais vieux singe ne fit belle moue
Jamais vilain n’aima noblesse
Jamais vin blanc ne fut vert
Jamais à un bon chien il ne vient un bon os
Jamais étoupe ne fait bonne chemise
Jamais, homme sage et discret, ne révèle à femme son secret
Jambon et vin d’une année et ami d’une siéclée
Jambon passant un an n’est jamais bon, mais l’ami d’une siéclée est très bon
Janvier et février, comblent ou vident le grenier, février le court est le pire de tout
Janvier froid ou tempéré, passe-le bien couvert
Janvier, la vieille dans le foyer
Janvier, ne te glorifie pas pour tes beaux jours, car le février te suit de près
Je battrai le buisson, tu prendras les oiseaux
Je chie sur la moitié du monde et j’emmerde l’autre moitié, cela fait que tout le monde est emmerdé
Je conviendrais bien volontiers que les femmes nous sont supérieures, si cela pouvait les dissuader de se prétendre nos égales
Je crois afin de comprendre
Je me presse de rire de tout, de peur d’être obligé d’en pleurer
Je me suis repenti d’avoir parlé, mais jamais de n’avoir pas parlé
Je mets la rage assûr au chien lequel je hais
Je ne fais pas le bien que je veux, tandis que je fais le mal que je ne veux pas
Je ne regarde point la valeur du présent, mais le cœur qui le présente
Je ne suis jamais moins seul que dans la solitude
Je ne suis jamais plus occupé que quand je n’ai rien à faire
Je ne trouve rien si cher que ce qui m’est donné
Je n’ai pas d’ennemis quand ils sont malheureux
Je n’enseigne pas, je raconte
Je n’y doit point avoir d’appréhension à table, si le vin est bon
Je plains l’homme accablé du poids de son loisir
Je préfère voir un homme rougir que le voir pâlir
Je suis homme et rien de ce qui est humain ne m’est étranger
Je suis riche des biens dont je sais me passer
Je suis si empêché (occupéà aux affaires d’autrui, que je ne puis entendre aux miennes
Je suis un homme et je ne puis compter sur le jour qui doit suivre
Je veux cela, j’ordonne ainsi; ma volonté, voilà ma raison
Je veux pas mettre mon cul à l’aise pour mettre ma bouche à la misère
Je vis celui qui avait dérobé des épingles fustigé, et celui qui avait volé le trésor, devenu bailli ou juge à la province
Je vis celui qui avait dérobé des épingles être fustigé, et celui qui avait volé le trésor devenir bailli
Jeter de l’huile sur le feu
Jeter des pierres dans le jardin de quelqu’un
Jeter le manche après la cognée
Jeter le mouchoir
Jeter sa langue aux chiens
Jeter son bien par les fenêtres
Jeter son bonnet par-dessus les moulins
Jette ton pain sur la surface des eaux, tu le retouveras dans la suite des jours
Jeune barbier vieil médecin, s’ils font outre ne vaillent pas un brin
Jeune brebis et vieux bélier ont vite fait un troupeau
Jeune cavalier, vieux piéton
Jeune chair et vieux poisson
Jeune charlatan, vieux médecin
Jeune chirurgien, vieux médecin, riche apothicaire
Jeune cœur est souvent volage, tant en ville comme en village
Jeune cœur n’a point de deuil
Jeune en sa croissance, a un loup en la panse
Jeune et jeune mariage de Dieu, jeune et vieux mariage du diable, vieux et vieille mariage de rien
Jeune femme et bois vert mettent la maison à l’envers
Jeune femme et homme âgé, emplissent d’enfants le foyer
Jeune femme et pain chaud sont des ruine-outau
Jeune femme et vieux chevaux mènent l’homme au tombeau
Jeune femme à vieux mari, c’est noix dure à croc pourri
Jeune femme, bois vert et pain chaud, font la ruine de la maison
Jeune femme, bois vert et pain tendre, font bientôt maison à vendre
Jeune femme, pain frais et bois vert, sont la ruine de la maison
Jeune femme, pain tendre et bois vert mettent la maison à l’envers
Jeune femme, pain tendre et bois vert mettent une maison à l’envers
Jeune femme, pain tendre et bois vert, mettent la maison au désert
Jeune fille belle, tête étourdie
Jeune fille fenêtrière, ne sera pas bonne ménagère
Jeune fille légère, mariée sans attendre
Jeune fille qui mène la danse, une fois mariée a la contre-danse
Jeune fille qui ne danse pas ne se marie pas
Jeune fille qui se plaît à danser, une fois mariée a la contre-danse
Jeune fille toujours à la croisée n’est ni bois ni copeau
Jeune fille, pain frais et bois vert, mettent une ferme à désert
Jeune gars vieille guenon, mariage du démon
Jeune homme attifé est vite marie
Jeune homme dans sa croissance, a un loup dans sa panse
Jeune homme et vieille, le diable veille
Jeune qui trop veille, vieillard qui trop dort, vivre longtemps ne s’est jamais vu
Jeune sain, vieux démon
Jeunes filles, oies, cochons et veaux, à conduire vilaines bêtes
Jeunes gens ne songent que de se marier et maints mariés qu’à se démarier
Jeunes nous sautons, trop vieux nous ne pouvons courir
Jeunesse angélique fait vieil âge satanique
Jeunesse et adolescence ne sont qu’abus et ignorance
Jeunesse et folies sont deux mauvaises métairies
Jeunesse mal instruite, cité détruite
Jeunesse oiseuse, vieillesse disetteuse
Jeunesse pourrie, vieillesse pouilleuse
Jeunesse qui veille, vieillesse qui dort, sont bien près de la mort
Jeunesse rêve, vieillesse décompte
Jeunesse, beauté de l’âme
Jeux de mains, jeu de vilain
Jeûne fait vivre
Joie au cœur fait beau teint
Joie du courage donne beau teint au visage
Joie, ennui, mal comme le bien, à la face paraît et vient
Joindre les mains, c’est bien; les ouvrir, c’est mieux
Joli au berceau, laid dans la rue
Joli au berceau, pas beau au mariage
Joli bébé devient laid en grandissant, vilain bébé devient joli en grandissant
Joli et gracieux, rend heureux
Joli vin, grand chanteur
Joli visage est de chaque jour
Jolie fille et mauvais drap trouvent toujours des accrochas
Jolie fille porte sur le front sa dot
Jolie fille sans habits, plus d’amoureux que de maris
Jolie fille sans habits, plus d’amoureux que de maris ; fille bien ajustée, à demi-mariée
Jolie fille vaut une vigne
Jolie à l’extérieur, rien à l’intérieur
Jolies cloches et vilaines gens
Joncs marins en fleur, filles en chaleur
Jouer, gager, prêter, argent, font d’amitié écartement
Jouis du jour présent
Jour ouvrier gagne denier, jour fêté dépensier
Journellement et le plus souvent, en ma bourse n’y a point d’argent
Journée gagnée, journée dépensée et mangée
Joyeuse vie tue un homme
Joyeuse vie, père et mère oublie
Joyeux ne sait quel deuil ont les malores
Juge hâtif est périlleux
Juge l’oiseau à la plume et au chant, et au parler l’homme bon ou méchant
Juger de la pièce par l’échantillon
Juges qui vont en biais sont dignes d’être jugés
Juillet, la faucille et le poignet
Jument ferrée glisse bien
Junon dissimule la colère qui l’enflamma contre son coupable époux
Jupe de lin, chemise de chanvre
Jusqu’aux genoux celui qui veut, plus en haut celui qui peut
Jusqu’aux genoux celui qui veut, à partir des genoux celui qui peut
Jusqu’à ce jour, ce n’est la mode que fille aille quérir garçon
Jusqu’à ce que les châtaigniers soient fleuris, ne sortez pas les couvertures des lits
Jusqu’à vingt-cinq ans, les enfants aiment leurs parents ; à vingt-cinq ans, ils les jugent ; ensuite, ils leur pardonnent
Justice est la plus sûre garde du roi
Justice extrême est extrême injustice
Justice n’a lieu
Justice ploie, l’Église noie, le commun dévoie
Justice sur toutes vertus a le prix
Justice vaut mieux que force
Jà (Jamais) teigneux n’aimera peigne
J’ai chassé les oiseaux et tu les as pris
J’ai des garçons, surveille tes filles
J’ai fait lever les oiseaux de dedans le buisson et un autre les a pris
J’ai l’habitude de me taire sur ce que l’ignore
J’ai trouvé un homme entre mille, mais je n’ai pas trouvé une femme dans le même nombre
J’ai vu sous le soleil que la faveur n’appartient pas aux savants
J’ai vu sous le soleil que la richesse n’appartient pas aux intelligents
J’aime mieux ceux qui rendent le vice aimable que ceux qui dégradent la vertu
J’aime mieux le croire que d’y aller voir
J’aime mieux me battre avec n’importe qui, qu’avec la faim
J’aime mieux un bien présent qu’un meilleur qui est à venir et gît en espérance
J’aime mieux un homme sans argent que de l’argent et point d’homme (Thémistocle) : À propos du mariage de sa fille
J’aime mieux un raisin pour moi que deux figues pour toi
J’aime mieux un tiens que deux tu l’auras
J’aime mieux un vice commode, qu’une fatigante vertu
J’aime mieux une prune pour moi, même si elle n’est pas mûre qu’une poire d’hiver pour toi
J’aime mieux être appelée femme de bien que femme riche
J’aimerais mieux devenir fou que sensible
J’aimerais mieux garder cent moutons près d’un blé qu’une fillette dont le cœur a parlé
J’aimerais mieux que l’un me batît, que l’autre de ses dons me remplît
J’aimerais mieux être le premier dans un village que le second dans Rome
J’en doute, mais je ne veux pas me donner la peine de m’en assurer
J’eus de l’amour pour notre vieille et je la pris pour une jeune pucelle
La Chandeleur froide marque un bon hiver ; la Chandeleur chaude menace d’un hiver après Pâques
La Fortune est aveugle
La Fortune est de verre; au moment où elle brille le plus, elle se brise
La Fortune ne favorise pas toujours les plus dignes
La Fortune ne sourit aux méchants que pour mieux les perdre
La France c’est l’Auvergne, avec quelque chose autour
La Providence a mis du poil au menton des hommes pour que l’on puisse de loin les distinguer des femmes
La Providence n’est que le nom de baptême du hasard
La balle cherche le joueur
La balle vient au jour, au bon joueur
La barbe ne fait pas le philosophe
La beauté amorce l’homme et la larve la truite
La beauté de la femme vient de ses témoins
La beauté de la taille est la seule beauté de l’homme
La beauté du ciel est dans les étoiles, la beauté des femmes est dans leur chevelure
La beauté du corps, découronnée de celle de l’âme, n’est un ornement que pour les animaux
La beauté dure ce qu’elle dure
La beauté d’une femme est quand elle a la tête bien faite
La beauté d’une fille, ne la marie pas
La beauté est le miroir des fous
La beauté est un appui préférable à toutes les lettres de recommandation
La beauté est une courte tyrannie
La beauté est une fleur éphémère
La beauté est une tromperie muette
La beauté et la chasteté sont toujours en querelle
La beauté et la folie vont souvent de compagnie
La beauté ne donne rien à manger
La beauté ne sale pas la marmite
La beauté ne se mange ni ne se boit
La beauté ne se mange pas au plat
La beauté ne se mange pas à la cuillerée
La beauté ne vient pas d’un beau corps, mais de belles actions
La beauté n’est que la promesse du bonheur
La beauté plaît aux yeux, la douceur charme l’âme
La beauté rend la vertu aimable
La beauté sans grâce est un hameçon sans appât
La beauté sans la grâce attire, mais elle ne sait pas retenir; c’est un appât sans hameçon
La beauté sert de tambourin
La beauté, les agréments, tout passe et le vice reste
La beauté, on ne peut pas la manger
La beauté, peux-tu la manger?
La belle est comme la fleur, naît, fleurit, meurt et ne revient plus
La belle est d’ordinaire fainéante
La belle plume fait le bel oiseau
La belle-mère est bonne, mais meilleure si la terre la couvre
La belle-mère ne se souvient pas quand elle était belle-fille
La bellette et la jolie femme ne remplissent pas le grenier
La bellette ne remplit pas le grenier
La besace du pauvre n’est jamais enviée
La blanche chênure doit être vénérable et vénérée
La blouse ne fait pas le paysan
La bon amour ne va jamais sans crainte
La bonne année en peu de temps s’en va, la petite se garde
La bonne bête s’echauffe en mangeant
La bonne cogitation, de l’âme est vraie réfection
La bonne doctrine, à l’esprit est médecine
La bonne et sainte doctrine, au fol sert de vraie médecine
La bonne femme fait le bon mari
La bonne foi n’est pas ce qui abonde en notre siècle
La bonne fortune a deux sœurs, l’abondance de biens et la multitude d’amis, mais la mauvaise en a beaucoup plus, c’est à savoir
La bonne fortune, comme elle est aveugle elle-même, rend aveugles tous ceux qui la suivent
La bonne grâce est au corps ce que le bon sens est à l’esprit
La bonne mangeoire fait la bonne bête
La bonne marchandise trouve facilement acquéreur
La bonne mère ne dit pas, veux-tu?
La bonne nourriture fait la belle créature
La bonne parole mortifie grande discorde
La bonne plaisanterie consiste à ne vouloir point être plaisant; ainsi celui qui émeut ne songe point à nous émouvoir
La bonne renommée vaut mieux que de grandes richesses, et l’estime a plus de prix que l’argent et que l’or
La bonne renommée vaut mieux que les grandes richesses
La bonne semence requiert un terroir fertile
La bonne vie anoblit l’homme en tout âge
La bonne vie dure toujours, la mauvaise vie aura un terme
La bonne volonté trouve le moyen et l’opportunité
La bonne volonté vaut mieux que ce qu’on donne
La bonne éducation fait le bon sang
La bonté de Dieu est insupérable
La bonté et miséricorde dont l’enfant aura usé envers ses parents ne sera jamais oubliée
La bonté vaut mieux que la beauté
La borne sied très bien entre les champs de deux frères
La bouche débouche bien souvent, ce que le cœur juge et sent
La bouche en peut plus que les bras
La bouche parle selon l’abondance du cœur
La bourse cherche le fagot
La bourse de l’avare est insatiable
La bourse d’un amoureux est attachée avec des tiges de poireau
La bourse d’un fou et le cul d’un chien, on les voit quand on veut
La bourse d’un mendiant n’est jamais pleine
La bourse fournie fait la femme étourdie
La bourse ouvre la bouche
La bourse porte beauté
La bourse sortirait plutôt d’enfer que du logis de l’avocat
La bourse vide fait rider le visage
La bouteille, la colère et puis la bourse
La branche ne tombe pas loin du tronc
La bravoure ne cède pas devant le malheur
La bravoure procède du sang, le courage vient de la pensée
La brebis est après la chèvre en quête de laine
La brebis noire fait des agneaux blancs
La brebis qui bêle perd sa goulée
La brebis qui crie le plus a le moins de lait
La brebis qu’on laisse à la gueule du loup y passe bientôt
La bride et le bâton, font le cheval bon
La bête travaille plus que les bras
La bûchille ne saute pas loin du tronc
La calomnie est comme le charbon, si elle ne peut pas brûler elle vous fait noir
La caverne et la potence sont faits pour les misérables
La censure épargne les corbeaux et s’abat sur les colombes
La chair est plus proche que la chemise
La chair qui croît, il faut qu’elle bouge
La chaleur du vin fait sur l’esprit le même effet que le feu produit sur l’encens
La chambrière doit être aveugle pour sa maîtresse
La chance est pour les chanceux
La chandelle qui autrui éclaire et allume, soi-même s’ard, détruit et consume S’ardre = se brûler Du latin ardere = brûler (Cf adjectif ardent
La chandelle qui va devant éclaire mieux que celle qui va derrière
La chapelle Saint Ivre fait de beaux miracles
La charge dompte la bête
La charité couvre toutes les fautes
La charité ne pèche pas
La charité qui ne coûte rien, le ciel l’ignore
La charité équivaut à l’ensemble de tous les préceptes
La charrette dégrade le chemin, la femme gâte l’homme et l’eau le chemin
La charrette gâte le chemin, la femme l’homme et l’eau le vin
La charrue va devant les bœufs
La chasse donne la chasse
La chasse endurcit le cœur aussi bien que le corps
La chasteté est le lys des vertus
La chasteté fait la beauté
La chatte va tant de fois au fromage blanc qu’elle s’y fait prendre
La chemise est plus proche de la peau que la robe
La chemise est plus près de la peau que la robe
La chemise est plus près du corps que la veste
La chemise est plus près du cul que des chausses
La chemise est plus près que la robe
La chemise est plus près que le manchon
La chemise est plus près que le pourpoint
La chemise est sur la peau
La chemise me touche, mais la chair m’est plus proche, car elle se tient à moi
La chemise me touche, mais la chair tient à moi
La chemise nous tient de plus près que notre manteau
La cherté donne goût à la viande
La chose dont il est question augmente
La chose guère vue est chère tenue
La chose périt pour le compte du maître
La chèvre a sauté en la vigne, aussi y sautera la fille
La chèvre broute où c’est qu’elle est attachée
La chèvre est la vache du pauvre
La chèvre qui a repris les boucs
La chèvre, quand elle bêle, perd une morce
La cible de l’avocat est de faire d’or amas
La cinquième roue au chariot ne fait qu’empêcher
La cinquième roue de la charrette gêne plus qu’elle n’aide
La cinquième roue d’un charret fait le plus de bruit
La cinquième roue d’une charrette fait le plus de bruit
La cire molle est la plus traitable
La cithare est docile à de molles pressions, mais elle répond d’une façon discordante à qui l’interroge avec violence
La clarté est la bonne foi des philosophes
La clarté sert au cheminant et la parole à l’écoutant
La cloche du mariage rompt les bras aux femmes et leur allonge la langue
La cloche du sot est vite sonnée
La cloche nous attend pour nous mettre dans le berceau et nous mettre dans la terre
La clémence vaut mieux que la justice
La coiffe vaut mieux que le chapeau
La coiffe à madame est toujours la plus belle
La colère des dieux est lente mais terrible
La colère du roi est comme le rugissement d’un lion et sa faveur est comme la pluie du printemps
La colère est une courte folie
La colère qui continue est une mer en folie
La compassion se prépare à elle-même de grands secours
La complaisance de l’épouse produit bientôt la haine de la courtisane
La comédie corrige les mœurs en riant
La comédie réveille les sens, la musique les jette à la renverse
La concorde augmente les petites fortunes, la discorde ruine les plus grandes
La confiance de plaire est souvent un moyen de déplaire infailliblement
La confiance fournit plus à la conversation que l’esprit
La conscience vaut mille témoins
La constance n’est point la vertu d’un mortel, et pour être constant, il faut être immortel
La continuelle gouttière rompt la pierre
La contrée est malheureuse et méchante, en laquelle le coq se tait et la poule chante
La conversation est l’image de l’esprit
La conversation est un jeu où il ne faut pas mettre un louis contre un écu
La conviction est la conscience de l’esprit
La coquetterie, c’est la véritable poésie des femmes
La corde d’une mandore ou d’un violon, se rompt en la tirant trop
La corruption des meilleurs est la pire
La couche nuptiale est l’asile des soucis; c’est le lit où l’on dort le moins
La cour est une forêt de tous animaux et prairie de toutes herbes
La cour rend des arrêts, et non pas des services
La course n’appartient pas aux agiles ni la bataille aux vaillants
La couteau n’appaise l’hérésie
La coutume ancienne a force de loi
La coutume contraint la nature
La coutume est la meilleure interprète de la loi
La coutume est la reine du monde, chez les dieux comme chez les mortels
La coutume est plus sûre que la loi
La crainte de Dieu est le commencement de la sagesse
La crainte de la guerre est encore pire que la guerre elle-même
La crainte d’un défaut fait tomber dans un pire
La crainte fit les dieux, l’audace a fait les rois
La crasse dépare gens et bêtes
La critique est aisée, et l’art est difficile
La croix est l’escalier des cieux
La croix est plantée partout
La croyance aux préjugés passe dans le monde pour bon sens
La cruche va tant à l’eau qu’elle se rompt
La crèche vide, les chevaux se battent
La créature humaine, de bonne affaire ne doit cesser de bien faire
La cuisine trop grasse amaigrit le maître et fait dépérir sa maison
La cuisinière est tombée dans la marmite
La cuisinière est tombée sur les cendres
La culture de l’esprit est un autre soleil pour les gens instruits
La culture, c’est ce qui reste quand on a tout oublié
La cupidité se tourne contre celui qui s’y livre
La curiosite réduit l’homme à la mendicité
La curiosité est un vilain défaut
La curiosité naît de la jalousie
La célébrité, c’est l’avantage d’être connu de ceux qui ne vous connaissent pas
La côte d’Adam a plus d’aloès que de miel
La demesure en fleurissant produit l’épi de la folie, et la récolte est une moisson de larmes
La dernière goutte est celle qui fait déborder le vase
La difficulté de réussir ne fait qu’ajouter à la nécessité d’entreprendre
La dignité est ton bien ainsi que la probité qui peut te les ravir ?
La dignité est une majesté qui résulte d’une raison droite et sérieuse
La diplomatie est la clef de toutes discussions »Nicolas Violan »
La discipline et bonne accoutumance est de très grande efficace et puissance
La discussion réveille l’objection et tout finit par le doute
La dissimulation est un effort de la raison, bien loin d’être un vice de la nature
La diète guérit davantage que la saignée
La diète n’a jamais tué
La douceur apprivoise les brutes
La douceur de caractère donne la sûreté, mais enlève l’indépendance
La douleur celée n’a point de guérison
La douleur de femme morte dure jusqu’à la porte
La douleur de l’âme pèse plus que la souffrance du corps
La douleur est aussi nécessaire que la mort
La douleur est le remède à la douleur
La douleur qui se tait n’est est que plus funeste
La dure mort, atterre faible et fort
La déesse Kairos, personnification allégorique de l’Occasion, avait la tête rasée, sauf une mèche de cheveux sur le front
La délicatesse est un don de nature, et non une acquisition de l’art
La délicatesse est à l’esprit ce que la bonne grâce est au corps
La délicatesse telle que l’entend Pascal, s’oppose à la grossièreté : c’est une nuance de la spiritualité
La démence exaltée se tourne contre elle-même
La démocratie, c’est le gouvernement du peuple, par le peuple, pour le peuple
La dépendance est née de la société
La dépense coûte plus que la dot
La fable est la sœur aînée de l’histoire
La faiblesse est le seul défaut que l’on ne saurait corriger
La faiblesse est plus opposée à la vertu que le vice
La faim a marié la soif
La faim chasse le loup du bois
La faim est le premier service d’un bon dîner
La faim est mauvaise
La faim est pressante
La faim est un bon conseiller
La faim fait sortir le loup du bois
La faim fait tout faire
La faim fait trouver le pain tendre
La faim n’est pas aussi mauvaise que la soif
La faim rend les gens actifs
La faim rend tout agréable, excepté elle-même
La faim se contente de pain
La faim sert de pitance
La familiarité découvre maints secrets
La familiarité engendre le mépris
La fantaisie est semblable et contraire au sentiment
La fantaisie à femme souvent change
La farine du diable ne fait pas de bon pain
La fausse modestie est le dernier raffinement de la vanité
La fausse modestie est le plus décent de tous les mensonges
La faute de la vache, c’est le veau qui la paye
La faux paît le pré, l’argent oprant l’orge
La faux paît les prés
La faveur a cela de commun avec l’amour, que si elle n’augmente pas, elle décroît
La faveur des princes n’exclut pas le mérite, et ne le suppose pas aussi
La faveur met l’homme au-dessus de ses égaux ; et sa chute au-dessous
La façon de donner vaut mieux que ce qu’on donne
La femme a la nature versatile de la mer
La femme a le bec de pie et le dard fourchu du serpent
La femme a plus de langue que de tête
La femme a plus peur d’être mal nourrie que mal fourbie
La femme a semence de cornes
La femme appartient à qui la paye
La femme au profit, l’homme à l’honneur
La femme avec qui tu te marieras, choisis-la de ta condition
La femme avisée, quand il pleut fait la lessive
La femme belle n’est pas chanteuse
La femme bien mariée est celle qui n’a ni belle-mère ni belle-sœur
La femme bien élevée vit chez elle
La femme bonne et fidèle est un trésor sans pareil
La femme bonne et loyale est un trésor sans égal
La femme chaste est celle qui n’a pas été sollicitée
La femme comme la noix, celle qui se tait est la bonne
La femme coquette est comme l’ombre, suis-la elle te fuit, fuis-la elle te suit
La femme coquette est l’agrément des autres et le mal de qui la possède
La femme c’est comme la barque, il est (à) craindre qu’elle ne chavire
La femme c’est le diable de jour, le Bon Dieu la nuit
La femme c’est un ange la nuit, un démon le jour
La femme du marin est en puissance de mari le matin, veuve le soir
La femme du marinier va bien souvent mariée le matin et veuve le soir
La femme d’un bon mari le porte écrit sur sa figure
La femme en fait sortir par la fenêtre plus que l’homme n’en fait entrer par la porte
La femme est chose variable et changeante
La femme est comme la barque, il est (à) craindre qu’elle ne vienne à faillir
La femme est comme la châtaigne gâtée ; belle au-dehors, amère au-dedans
La femme est comme la châtaigne, belle au-dehors et dedans le ver
La femme est comme la châtaigne, belle dehors et dedans le ver
La femme est comme la châtaigne, brillante en-dehors mais en dedans le défaut
La femme est de feu, l’homme d’étoupe, le diable passe et souffle
La femme est la clef du ménage
La femme est la porte de l’enfer
La femme est le Bon Dieu de la maison
La femme est moins portée que l’homme aux nobles actions, et beaucoup plus aux actions honteuses
La femme est purifiée tout de suite du contact de son mari; de celui d’un autre jamais
La femme est tout à tour la joie et le fléau de la vie des hommes
La femme est un animal à cheveux longs et à idées courtes
La femme est un certain animal difficile à connaître
La femme est à l’homme un mal agréable
La femme est à l’homme un orage domestique
La femme estime toujours son voisin être de violette
La femme et la poêle à frire ne doivent pas bouger de la maison
La femme et la toile mal se choisissent à la chandelle
La femme et la toile ne se choisissent pas à la chandelle
La femme et la toile ne se choisissent à la chandelle
La femme et la toile ne se doivent pas choisir à la chandelle
La femme et la toile se choisissent mal à la chandelle
La femme et le navire, il est à craindre qu’ils ne chavirent
La femme et le riz se nourrissent d’eau
La femme et le riz, d’eau se nourrissent
La femme et le riz, en eau fleurissent
La femme fait oublier ses défauts et peut aller partout la tête haute, si elle est honnête de corps
La femme fait un ménage ou défait
La femme forte surveille les sentiers de sa maison, et elle ne mange pas le pain de l’oisiveté
La femme jolie jamais ne vous enrichira
La femme la plus louée est celle dont on ne parle pas
La femme la plus vertueuse a en elle quelque chose qui n’est pas chaste
La femme laide, l’or la rend jolie
La femme mange comme deux, a de l’esprit comme quatre, de la malice comme six, de la passion comme huit
La femme ne doit pas apporter de tête en ménage
La femme peut enrouler l’homme autour de son doigt
La femme pleure d’un œil et rit de l’autre
La femme pleure tôt ou tard
La femme pour se faire belle se fait laide
La femme prudente et sage est l’ornement du ménage
La femme qui a de la grâce obtient la gloire
La femme qui a le meilleur parfum est celle qui n’est pas parfumée
La femme qui a un mauvais mari le porte écrit sur le visage
La femme qui allaite ne tombe pas grosse
La femme qui blâme son mari, à l’essai demande autre voisin
La femme qui conte tout à l’homme, pleure plus qu’elle ne rit
La femme qui dit tout à son mari, pleure plus qu’elle ne rit
La femme qui fait un métier d’homme appartient au troisième sexe
La femme qui se tait vaut mieux que celle qui parle
La femme qui sort beaucoup à la rue tient sa maison comme un fumier
La femme rit quand elle peut et pleure quand elle veut
La femme règne et ne gouverne pas
La femme sage bâtit la maison, la femme insensée la renverse
La femme sage bâtit sa maison et la femme insensée la renverse de ses propres mains
La femme sage est l’ornement du ménage
La femme sait le lieu malin où le diable cache sa ferraille
La femme sans bijoux est comme un moulin sans meule
La femme sans boucles d’oreilles semble un âne sans muselière
La femme se plie et l’homme se brise
La femme se prend à la vue et non au goûter
La femme sera sauvée par la maternité
La femme serait un ragoût suave si le diable n’y mettait ni sel ni poivre
La femme souffre plus que l’homme du mal d’amour, mais elle sait mieux le dissimuler
La femme sur son dos est aussi forte qu’un chêne debout
La femme toute seule n’est rien
La femme trouve plus facile d’agir mal que bien
La femme varie
La femme veut être servie à la grande mesure
La femme, l’argent et le vin, ont leur bien et leur venin
La femme, ou nonne ou mariée
La femme, si elle est belle, te fait faire sentinelle
La fermeté est l’exercice du courage de l’esprit
La feuille de l’arbre, la langue de la femme, la queue de la chèvre, remuent toujours
La feuille tombe sur la terre, la beauté déchoit aussi
La feuille tombe à terre, ainsi tombe la beauté
La fiancée n’est pas mariée
La fidélité se trouve au chenil
La fierté est l’éclat et la déclaration de l’orgueil
La fierté précède la chute
La figure fait la beauté d’une statue, l’action fait celle de l’homme
La fille abandonnée ne sait refuser negun
La fille de loin a la réputation de demoiselle
La fille est comme la rose, belle quand elle est fermée
La fille et le melon sont difficiles à connaître
La fille jolie est celle qui veut gagner son pain, celle qui aime son travail
La fille n’est jamais née si elle n’est bien mariée
La fille n’est que pour enrichir les maisons étrangères
La fille se fait dévote quand elle ne peut se marier
La fille trop jolie n’aime pas la soupe de pain de maïs
La fille à épouser est celle qui veut gagner son pain, qui aime le travail
La fin couronne l’œuvre
La fin du jour est la nuit
La fin du monde est tous les jours
La fin fait tout
La fin juge le bon et le fin
La fin justifie les moyens
La fin justifie les moyens
La fin loue la vie et le soir le jour
La fin loue l’ouvrier
La fin loue l’œuvre
La fine raillerie est une épine qui a conservé un peu du parfum de la fleur
La fièvre abat le lion
La fièvre continuelle l’homme atterre
La fièvre continuelle tue l’homme
La fièvre de chaque jour tue
La fièvre quarte, c’est la santé des jeunes gens et la mort des vieillards
La flamme est du feu l’âme
La flamme suit de près la fumée (Plaute) : Proverbe général : Il n’y a pas de fumée sans feu
La flatterie est le miel et le condiment de toutes les relations entre les hommes
La flatterie est un commerce honteux, mais profitable au flatteur
La flatterie est une fausse monnaie qui n’a de cours que par notre vanité
La flèche d’un sot file vite
La foi consiste en croire et non en voir
La foi est le triomphe de la théologie sur la faiblesse humaine
La foi qui n’agit point, est-ce une foi sincère
La foi sans bonnes œuvres est morte
La foi sans les œuvres est morte en elle-même
La foi sans œuvre n’a non plus de crédit qu’un vieil songe de nuit
La foi transporte les montagnes
La foi, l’œil ne la renommée, ne doivent être jamais touchées
La foi, l’œil, la renommée, ne veulent guère être touchés
La foire n’est pas sur le pont
La folie est attachée au cœur de l’enfant; la verge de la discipline l’éloignera de lui
La folie est une femme bruyante, stupide, et ne sachant rien
La folie n’a pas d’âge
La fontaine elle-même dit qu’elle a soif
La force brutale dépourvue de raison tombe par son propre poids
La force du cheval est dans le garrot, celle du bœuf est dans le jarret
La force du diable est dans les reins
La force du maître est dans son garrot et la force du bœuf est dans son jarret
La force d’âme est préférable à la beauté des larmes
La force est ce qui agit par soi-même
La force et la grâce sont la parure de la femme
La force fait le droit, et la justice c’est l’intérêt du plus fort
La force pour les bœufs, l’adresse pour les hommes
La fortune (la bonne occasion) passe vite, elle est déjà en train de partir lorsqu’on doit la saisir, et il faut avoir le réflexe de le faire même par des moyens brutaux, impolis
La fortune a pour main droite l’habileté et pour main gauche l’économie Proverbe italien)
La fortune est changeante, le gagnant d’hier est le perdant d’aujourd’hui et réciproquement
La fortune et l’humeur gouvernent le monde
La fortune fait paraître nos vertus et nos vices comme la lumière fait paraître les objets
La fortune favorise les audacieux (Térence, Virgile) : Latin: Audentes fortuna juvat
La fortune peut emporter l’œuvre, non l’esprit
La fortune se dissipe, le fou demeure
La fortune se saisit par les cheveux
La fortune se sert quelquefois de nos défauts pour nous élever
La fortune tourne tout à l’avantage de ceux qu’elle favorise
La fortune vend ce qu’on croit qu’elle donne
La fortune veut qu’on la recherche
La fortune vient en dormant
La foule est la mère des tyrans
La foule est un monstre à mille têtes
La fourbe n’est le jeu que des petites âmes
La fourberie ajoute la malice au mensonge
La fourmi apprend le truand fuir le froid et mauvais temps
La fournaise éprouve l’acier, le vin éprouve le cœur des superbes
La fraise, agréable instrument contre les rhumatismes
La fraude se cache sous les généralités
La froideur est la plus grande qualité d’un homme destiné à commander
La frugalité asservit la nature
La frugalité contient toutes les vertus
La frugalité est la mère des vertus
La fumée et la femme font partir l’homme de sa chambre
La fumée ne manque pas où il y a du feu
La fumée, la toux et l’amour, ne se cachent pas toujours
La fête passe, le fou demeure
La fête passée, adieu le saint
La gaieté des femmes leur tient lieu d’esprit
La gaieté, la santé changent l’hiver en été
La gaieté, la santé, changent l’hiver en été
La gentilhommerie meurt comme la vilénie
La gibecière d’un avocat est une bouche d’enfer
La gloire est le soleil des morts
La gloire est l’ombre de la vertu
La gloire est vaine et fausse monnaie
La gloire ne peut être où la vertu n’est pas
La gloire n’est pour la femme qu’un deuil éclatant du bonheur
La gloire réclame toujours des titres nouveaux
La glore de la femme est sa beauté, celle de l’homme est sa force
La gourmandise tue plus de gens que l’épée
La gourmandise tue plus de gens que l’épée
La grammaire étant l’art de lever les difficultés d’une langue, il ne faut pas que le levier soit plus lourd que le fardeau
La grande ambition des femmes est d’inspirer de l’amour
La grande érudition n’exerce pas l’esprit
La grandeur de l’homme est grande en ce qu’il se connaît misérable Un arbre ne se connaît pas misérable
La gravité est le bouclier des sots
La gravité est un mystère du corps inventé pour cacher les défauts de l’esprit
La grenouille veut se faire aussi grosse que le bœuf
La grâce d’une femme fait la joie de son mari, et son intelligence répand la vigueur dans ses os
La grâce plus belle encore que la beauté
La grêle tombe sur les bons aussi que sur les mauvais
La guerre civile est la chance de l’ennemi
La guerre civile est le règne du crime
La guerre civile ne donne pas de gloire
La guerre est la seule véritable école du chirurgien
La guerre est l’affaire des hommes
La guerre n’admet pas d’excuses
La guerre n’est plaisant qu’à l’inexpérimenté
La génisse chante le chant du taureau
La générosité donne moins de conseils que de secours
La géographie est le seul art dans lequel les derniers ouvrages sont toujours les meilleurs
La haine des faibles n’est pas si dangereuse que leur amitié
La haine est la fille de la crainte
La haine est une colère invétérée
La haine excite les querelles, l’amour couvre toutes les fautes
La haine qui se déclare ouvertement perd le moyen de se venger
La haine, c’est la colère des faibles
La hauteur des manières fait plus d’ennemis que l’élévation du rang ne fait de jaloux
La honte n’est pas de saison quand on est dans le besoin
La hâte est mère de l’échec
La jalousie d’une épouse est une bourrasque d’où sort l’ouragan
La jalousie est cruelle comme l’enfer et ses ardeurs sont des ardeurs de feu
La jalousie est la sœur de l’amour comme le diable est le frère des anges
La jalousie est le plus grand de tous les maux et celui qui fait le moins de pitié aux personnes qui le causent
La jalousie naît avec l’amour, mais elle ne meurt pas toujours avec lui
La jalousie n’est qu’un sot enfant de l’orgueil, ou c’est la maladie d’un fou
La jalousie éteint l’amour comme les cendres éteignent le feu
La jeune fille est une fleur, la jeune femme un fruit, si mauvais se trouve le fruit, quel souvenir restera de la fleur
La jeune fille qui vit retirée sera une très bonne mariée
La jeune veuve jolie et riche, d’un œil pleure et de l’autre fait fête
La jeunesse est toujours agréable et embellit même les plus laids
La jeunesse est une ivresse continuelle; c’est la fièvre de la santé ; c’est la folie de la raison
La jeunesse est à l’été parangonnée et la vieillesse à l’hiver comparée
La jeunesse ressemble à tout ce qui s’accroît, la vieillesse à tout ce qui se corrompt
La joie fait peur
La joie motive santé
La joie prolonge la vie
La jolie femme ne te rendra jamais riche
La jolie ne remplit pas le grenier
La justice est comme la cuisine, il ne faut pas la voir de près
La justice est immortelle
La justice est la vérité en action
La justice est souvent boiteuse
La justice est une si belle chose qu’on ne saurait trop l’acheter
La justice est une vierge qui, si elle est offensée, va s’asseoir aux pieds de Zeus
La justice hâtive est une marâtre de malheur
La justice n’est pas de ce monde
La justice n’est pas une vertu d’État
La justice renferme en elle-même toutes les vertus et celui-là est bon, qui est juste
La justice sans la force est impuissante; la force sans la justice est tyrannique
La justice, c’est de donner à chacun son dû
La lame use le fourreau ou L’épée use le fourreau
La langue a juré, mais non l’esprit
La langue convient refréner, bien entendre et peu parler, car la parole une fois envolée, ne peut être révoquée
La langue des femmes est leur épée
La langue des femmes est leur épée, elles ne la laissent jamais rouiller
La langue en miel, le cœur en fiel
La langue est la meilleure et la pire des choses
La langue est la messagère et miroir de la pensée
La langue est le miroir du ventre
La langue est l’arme de la femme
La langue ne doit jamais parler, sans congé au cœur demander
La langue n’a grain d’os et rompt l’échine et le dos
La langue n’a nul os, et tranche et brise menu et gros
La langue peut bien faillir et l’écriture ne peut mentir
La langue se doit réfreindre par l’empire de raison
La langue se doit réfréner par l’empire de raison
La langue va plus vite que les deux pieds
La lapine porte deux mois, la chatte la chienne 2, la louve 3, la bête qui grogne (truie) 4, la brebis 5, la chèvre 6, autant la bête qui brame (vache) qu’une dame, pour la bourrique et la jument il en faut bien onze pour le moins
La lavure la plus épaisse rend les pourceaux les plus gras
La lettre tue, mais l’esprit vivifie
La liberté des uns s’arrête là où commence celle des autres
La liberté est le droit de faire ce que les lois permettent
La liberté est un bien qui fait jouir des autres biens
La libéralité consiste moins à donner beaucoup qu’à donner à propos
La libéralité engendre amitié
La lie a beau faire, elle retombe au fond par sa propre grossièreté
La lionne n’a qu’un petit, mais c’est un lion
La lisière est pire que le drap
La littérature est l’expression de la société, comme la parole est l’expression de l’homme
La livrée du chrétien se connaît par le bien
La loi assiste les vigilants et non les endormis
La loi doit avoir autorité sur les hommes, et non les hommes sur la loi
La loi du plus fort
La loi est dure, mais c’est la loi
La loi est la forge de l’or
La loi permet souvent ce que défend l’honneur
La loi signifie autre chose le matin que le soir
La louange chatouille et gagne les esprits
La louange de l’étranger est plus grate que du familier
La louange de soi-même fait la bouche puante
La louange est la plus douce des musiques
La loyauté est le bien le plus sacré du cœur humain
La lumière du juste brille joyeusement, mais la lampe des méchants s’éteint
La lumière montre l’ombre et la vérité le mystère
La luxure est comme le poivre, qui ne se tolère qu’à petites doses
La magicienne promet des merveilles et se montre incapable des choses ordinaires
La magnanimité ne doit pas compte à la prudence de ses motifs
La main est le plus sûr et le plus prompt secours
La main est l’instrument des instruments
La main froide, c’est la santé du cœur
La main ne peut rattraper la pierre qu’elle vient de lancer, ni la bouche la parole qu’elle vient de proférer
La main vigilante dominera, mais la main indolente sera tributaire
La maison du charpentier est faite de tronçons, et encore, de tronçons courts et rognés
La maison est à l’envers lorsque la poule chante aussi haut que le coq
La maison où gouverne la femme ne va pas bien
La maison sans feu et sans femme, ressemble au corps qui est sans âme
La maison sans feu, sans femme, ressemble au corps sans âme
La maison vide est pleine de noise
La majesté des dieux ne leur permet point de protéger ouvertement les mortels
La majesté et l’amour n’habitent pas la même demeure
La maladie altère un beau visage, la pauvreté change encore davantage
La maladie de la peau est la santé des boyaux
La maladie du corps est la guérison de l’âme
La maladie du poil est la santé des boyaux
La maladie d’amour ne tue que ceux qui doivent mourir dans l’année
La maladie et la prison n’amendent aucun polisson
La maladie longue tue le gaillard
La maladie récidive quand le médecin n’est content
La maladie vient du mal
La maladie vient à cheval et s’en retourne à pied
La malice la plus couverte est la pire
La malveillance a des dents cachées
La manière de faire des agriculteurs nous sert de beau miroir
La manière de faire en tout
La manière d’obéir fait le mérite de l’obéissance
La manière fait le jeu
La mariée est trop belle, le marié n’en veut pas
La mariée n’est jamais trop belle
La marmite soutient le corps et la maison
La marâtre, quoique faite de miel, n’est pas bonne
La matinée rouge est présage de pluie, la soirée rouge promet beau temps
La mauvaise compagnie est celle qui mène les gens au gibet
La mauvaise femme envenime son mari et arruine
La mauvaise foi est l’âme de la discussion
La mauvaise garde paît le loup
La mauvaise garde paît souvent le loup
La mauvaise graine ne se perd pas
La mauvaise herbe croît (pousse) partout
La mauvaise herbe ne se perd pas
La mauvaise herbe ne se perd pas si facilement
La mauvaise herbe périt difficilement
La mauvaise herbe vient comme la gale et (ne) crève jamais
La mauvaise semence ne se perd jamais
La meilleure alliance est celle qu’on met sous son tablier
La meilleure cachette est de ne rien dire
La meilleure des belles-mères ne vaut pas la plus mauvaise des mères
La meilleure finesse, c’est simplesse
La meilleure réponse qu’on saurait faire c’est de faire ce qu’on est commandé
La meilleure volaille est un gigot de mouton
La menthe augmente l’amour
La mer appartient à tout le monde
La mer n’a pas de branches à quoi qu’on se puisse prendre quand on se noie
La mer serait plutôt sans eau que belle femme sans ami
La merde de nos enfants ne pue jamais
La mesure est la meilleur des choses
La mieux mariée est celle qui n’a ni belle-mère ni belle-sœur
La mise excède assez tôt la recette
La misère aide à supporter la misère
La misère amène la noise
La misère et la teigne arrivent toujours à la fois
La misère regarde à la porte de l’homme travailleur
La misère rend mauvais
La mode est un tyran dont rien ne nous délivre, à son bizarre goût il faut s’accommoder, le sage n’est jamais le premier à la suivre ni le dernier à la garder
La mode et les pays règlent souvent ce que l’on appelle beauté
La modestie ajoute au mérite, et fait pardonner la médiocrité
La modestie est au mérite ce que les ombres sont aux figures dans un tableau; elle lui donne de la force et du relief
La modestie est la plus belle des robes
La modération couvre l’audace, la pudeur couvre l’impudicité, et la piété couvre le crime
La modération donne la durée en dépit même d’accident fâcheux, bien des maux sont le résultat des abus que l’on a commis
La modération est la santé de l’âme
La modération n’a pas de sens pour les femmes
La moindre roue du char fait le plus de bruit
La moitié du monde ne sait comme l’autre vit
La monarchie dégénère en tyrannie, l’aristocratie en oligarchie, et la démocratie en anarchie
La montagne ne fraie pas avec la montagne
La montagne n’a pas besoin de la montagne, mais l’homme a besoin de l’homme
La moquerie est de toutes les injures celle qui se pardonne le moins
La moquerie est souvent indigence d’esprit
La morale doit être l’étoile polaire de la science
La morsure du méchant n’a ni remède ni guérison
La mort casse tout
La mort donne fin à tous vices
La mort du juste est un malheur pour tous
La mort est assise devant la cabane comme devant le château
La mort est douce aux affligés
La mort est quelquefois un châtiment; souvent c’est un don; pour plus d’un, c’est une grâce
La mort est un grand bien, puisqu’elle n’est pas un mal
La mort et la vie sont au pouvoir de la langue
La mort et la vie, Dieu en dispose
La mort et le mariage dépècent tout
La mort fuit qui la cherche et suit et elle suit qui l’abhorre et fuit
La mort mord les rois si tôt et hardiment que les conducteurs de charrois
La mort ne connaît ni âge ni jour
La mort ne lit pas l’almanach
La mort ne surprend point le sage, il est toujours prêt à partir
La mort n’a point de calendrier
La mort n’a point d’ami, le malade n’en a qu’un demi
La mort n’admire et n’épargne Roi d’Angleterre ni d’Espagne
La mort n’est pas une excuse
La mort n’est qu’un épouvantail
La mort n’oublie personne
La mort partout mord
La mort prend le faible et le fort
La mort prend tout
La mort prévue est la plus odieuse des morts
La mort rattrape celui qui fuit le combat
La mort rattrape qui la fuit
La mort rompt les amodiations
La mort vient qu’on ne sait l’heure
La mort égalise toutes les conditions
La mouche au mur contrarie un homme malade
La mouche se brûle à la chandelle
La musique adoucit les mœurs
La musique est le plus cher de tous les bruits
La musique est une douce folie, la poésie une rage
La mère aime tendrement, le père solidement
La mère des sciences est labeur
La mère doit être la conscience et la dignité de la famille
La mère n’est pas l’oiseau qui pondit l’œuf, mais l’oiseau qui l’a fait éclore
La méchanceté fait souvent toute la sûreté des méchants
La méchanceté s’apprend sans maître
La méchanceté, pour se faire encore pire, prend le masque de la bonté
La méchancété boit elle-même la plus grande partie de son venin
La médecine en temps donnée guérit et inconsidérement prise occit
La médecine est un art conjectural, qui n’a presque pas de règles
La médiocrité refuse toujours d’admirer et souvent d’approuver
La médiocrité va son petit chemin, quand trop de feu perd le mérite
La médisance est fille de l’amour-propre et de l’oisiveté
La médisance est le soulagement de la malignité
La médisance est une disposition malveillante de l’âme, qui se manifeste en paroles
La méfiance est mère de la sûreté
La mélancolie ne paye point de dettes
La mémoire du juste est en bénédiction
La mémoire est l’ennemie presque irréconciliable du jugement
La mémoire est toujours aux ordres du cœur
La naissance n’est rien où la vertu n’est pas
La nature a horreur du vide
La nature donne le génie; la société, l’esprit; les études, le goût
La nature fait le mérite, et la fortune le met en œuvre
La nature humaine procline à mal
La nature nous a donné deux oreilles et seulement une langue afin de pouvoir écouter davantage et parler moins
La nature nous a faits frivoles pour nous consoler de nos misères
La nature n’a rien fait d’égal ; sa loi souveraine est la subordination et la dépendance
La neige pendant huit jours sert de mère à la terre, passé ce temps-la elle tient lieu de marâtre
La neige qui tombe en sa saison, est capable de nous saouler de grain, et si c’est hors de saison, de nous donner la faim
La neige qui tombe engraisse la terre
La neige séjourne longtemps sur les sols pierreux, mais disparaît vite sur les terres cultivées
La netteté est le vernis des maîtres
La noblesse aurait subsisté si elle s’était plus occupée des branches que des racines
La noblesse est au bout de l’épée
La noblesse vit de proie
La nonchalance du maître mène le disciple paître
La note du médecin est plus chargée que l’âne du meunier
La nourriture fait la race
La nuit a conseil
La nuit donne conseil
La nuit est mère de pensées
La nuit est mère de toute pensée
La nuit est pour dormir
La nuit est une sorcière
La nuit ne connaît pas la honte
La nuit nuit ou grave
La nuit porte conseil
La nuit tombe en terre pour se reposer
La nuit, le conseil vient au sage
La nuit, l’amour aussi le vin, ont leur poison et leur venin
La nuit, tous les chats sont gris
La nuit, toutes les femmes sont belles
La nuit, à force de penser au jour, on en oublie de regarder les étoiles
La nécessité chasse la mauvaise bête
La nécessité donne la loi et ne la reçoit pas
La nécessité engendre noise
La nécessité est fort agissante
La nécessité est mère de l’invention
La nécessité fait aller le vieillard au marché
La nécessité fait du timide un brave
La nécessité ne sait que vaincre
La nécessité n’a pas de loi et c’est ainsi qu’elle excuse la dispense
La nécessité pousse la mauvaise bête
La nécessité pousse à faire des choses auxquelles on répugne Variante ancienne : La faim fait loup saillir de sa ramée
La négation a toujours une affirmation opposée
La négligence et idiotise du précepteur cause la ruine de la jeunesse
La paix entre ennemis est de courte durée
La paix est la mère nourricière du pays
La paix rend les peuples plus heureux, et les hommes plus faibles
La panosse se moque de l’écouvillon
La panse amène la danse
La parole est d’argent, mais le silence est d’or
La parole est la semence et le précepteur le semeur
La parole est l’ombre de l’action
La parole est l’ombre et l’image de chacun œuvre et tout ouvrage
La parole est l’ombre et l’image de tout œuvre et de chaque ouvrage
La parole s’enfuit, mais l’écriture demeure
La parole vaut l’homme
La parole échappée s’envole sans retour
La patience a fait crever bien des mulets
La patience est la mère des vertus et la soupe la nourriture des ventrus
La patience est l’art d’espérer
La patience est pour l’âme comme un trésor caché
La patrie du sage, c’est le monde
La pauvreté arrive comme un voyageur, et l’indigence comme un homme armé
La pauvreté dompte l’homme de bien plus que tout autre mal, plus que la vieillesse aux cheveux blancs, plus que le frisson de la fièvre
La pauvreté est la mère du crime
La pauvreté est l’aiguillon des arts
La pauvreté est une ladrerie
La pauvreté est une première mort
La pauvreté et la rage sont logés sous même charme
La pauvreté humilie les hommes jusqu’à les faire rougir de leurs vertus
La pauvreté s’approche à la sourdine, de délicate et trop grasse cuisine
La peine a ses plaisirs, le péril a ses charmes
La pelle au four de l’écouvillon se raille
La pelle se fout de la brouette
La pelle se moque du fourgon
La pelle se veut moquer du fourgon
La pelote grossit
La pensée console de tout et remédie à tout
La pensée dans le cœur de l’homme est une eau profonde et l’homme intelligent y puisera
La pensée est libre
La pensée est muable, aussi est la femme et le vent
La pente du vice est une pente douce
La perfectibilité est la faculté qui marque la différence entre les hommes
La perfectibilité est à la perfection ce que le temps est à l’éternité
La perfection d’une pendule n’est pas d’aller vite, mais d’être réglée
La perfection n’est pas de ce monde
La perfidie est un mensonge de toute la personne
La personnalité des femmes est toujours à deux, tandis que celle de l’homme n’a que lui-même pour but
La personne qui fait quelque chose de mal doit subir la même correction Loi du Talion Voir aussi : Lui rendre la monnaie de sa pièce
La persuasion repose sur les lèvres d’un ami fidèle
La perversité ne change pas, quelque honte qu’on lui fasse
La petite fleur tourne parfois, l’amour de la jeune fille tourne toujours
La petite neige arrache les vieux au foyer
La petitesse d’esprit fait l’opiniâtreté, et nous ne croyons pas aisément ce qui est au-delà de ce que nous voyons
La peur aux talons met des ailes
La peur est insensée, elle craint même les choses dont elle attend du secours
La peur et l’ennui en tuent plus que la maladie
La peur gît au cœur, au visage la couleur
La peur ou crainte et grande frayeur, corrompt de menace la vigueur
La philanthropie est la sœur jumelle de la pitié
La philosophie est la vraie médecine de l’âme
La philosophie est une méditation de la mort
La philosophie triomphe aisément des maux passés et des maux à venir, mais les maux présents triomphent d’elle
La physionomie n’est pas une règle qui nous soit donnée pour juger des hommes
La pierre ne pourrit jamais au puits
La pire de toutes les mésalliances est celle du cœur
La pire espèce des méchants est celle des vieux hypocrites
La pire roue du chariot crie toujours
La pire tyrannie est celle de l’habitude
La pitié est le contrepoison de tous les fléaux de ce monde
La piété est au cœur ce que la poésie est à l’imagination
La plaie apparente et extérieure est plus curable que l’intérieure
La plaie guérit, la cicatrice reste
La plaie qu’on fait demeure
La plaisanterie est une sorte de duel où il n’y a pas de sang versé
La pluie fort désirée, incontinent ennuie
La pluie, la faim et la femme sans raison, chassent l’homme de la maison
La plume d’un avocat est un couteau de vendange
La plume d’un avocat est un hain
La plume d’un médecin vaut bien l’épée d’un gentilhomme
La plume fait l’oiseau
La plume rapporte plus que le trident
La plume refait bien l’oiseau
La plume refait l’oiseau
La plume, la cire et le parchemin gouvernent le monde – Les écrits gouvernent le monde
La plupart des hommes emploient la première partie de leur vie à rendre l’autre moitié misérable
La plupart des hommes, pour arriver à leurs fins, sont plus capables d’un grand effort que d’une longue persévérance
La plupart des honnêtes femmes sont des trésors cachés qui ne sont en sûreté que parce qu’on ne les recherche pas
La plupart des mariages sont comme les sabots, il y en a toujours un de mauvais
La plupart des peines n’arrivent si vite que parce que nous faisons la moitié du chemin
La plupart du monde cherche plus accroissement de biens que de vertu
La plus aimée est la plus belle, la plus belle n’est pas la plus aimée
La plus belle fille du monde ne peut donner que ce qu’elle a
La plus belle fille du monde ne peut donner que ce qu’elle a
La plus belle prière, c’est de vivre en paix
La plus belle rose finit par être gratte-cul
La plus belle science, c’est de savoir se conduire
La plus belle tapisserie de la maison est l’homme et la femme
La plus belle victoire est de vaincre son cœur
La plus coûteuse des dépenses, c’est la perte de temps
La plus forte, généreuse et superbe de toutes les vertus est la vaillance
La plus grande consolation dans l’infortune est de trouver des cœurs compatissants
La plus grande malice du diable est de faire croire qu’il n’existe pas
La plus grande perfection de l’âme est d’être capable de plaisir
La plus indomptable de toutes les bêtes sauvages est un jeune garçon
La plus longue heure du jour est celle du sermon
La plus louée n’est pas la première mariée
La plus méchante roue du char crie toujours
La plus perdue de toutes les journées est celle où l’on n’a pas ri
La plus riche dot, c’est la vertu des parents
La plus sage est la moins folle
La plus subtile de toutes les finesses est de savoir bien feindre de tomber dans les pièges que l’on nous tend
La plus subtile folie se fait de la plus subtile sagesse
La plus sûre garde de la chasteté à une fille, c’est la sévérité
La plus universelle qualité des esprits, c’est la diversité
La plus véritable marque d’être né avec de grandes qualités c’est d’être né sans envie
La poire choit soudain quand elle est mûre Soudain quand = dès qu’elle
La poire choit subit qu’elle est mûre, nul péché impuni demeure Subit qu’elle = dès qu’elle
La poire comme la femme, quand elle ne fait pas de bruit est bonne
La poire est mure
La poire fait boire, la pomme désaltère
La poire ne tombe pas loin du poirier
La poire, comme la femme, quand elle ne fait pas de bruit est bonne
La politesse est une clef d’or qui ouvre toutes les portes
La politesse est à l’esprit ce que la grâce est au visage
La polygamie n’est pas l’expression d’un amour extrême, mais d’un mépris excessif des femmes
La pomme du matin tue le médecin
La pomme entamée ne se garde pas
La pomme ne tombe pas loin de l’arbre
La pomme ne tombe pas loin du tronc
La pomme sauvage tombe sous le pommier sauvage
La pompe funèbre est une consolation pour les vivants, plutôt qu’un tribut aux morts
La porte se défend par sa propre serrure
La postérité rend à chacun l’honneur qui lui est dû
La poule a beau gratter, si le coq ne l’aide pas, ne peut pas pondre
La poule domestique chasse la sauvage
La poule ne doit pas chanter avant le coq Avant le coq = devant le coq
La poule ne doit pas chanter devant le coq
La poule ne doit pas chanter devant le coq
La poule noire pont bien un œuf blanc et la vache blanche vêle bien un veau noir
La poêle a rien à reprocher au chaudron
La pratique est la seule théorie qui profite
La première année bras à bras, la deuxième pas à pas, la troisième viens quand tu voudras ; l’amour est une chose éphémère
La première année c’est baisi-baisa, la seconde année c’est berci-berça, la troisième année c’est batti-batta
La première année c’est baison baisetta, la seconde année c’est berçon bercetta, la troisième année c’est bouson bousetta, la quatrième année passe laisse-moi passer
La première année du mariage, les bonbons dans la poche, et la seconde année, la merde à sa place
La première année du mariage, quand même ils se cracheraient aux yeux, pas moyen de se faire enrager ; la seconde année, quand même ils se mangeraient la merde, pas moyen de faire montre (de) bonne grâce
La première année qu’on est marié, on chante ; la seconde, on pleure
La première boîte de guérison est le temps
La première faveur refusée efface toutes les faveurs accordées
La première femme est une ânesse, la seconde la maîtresse
La première fois, on se marie par amour, la seconde par nécessité
La première poule qui chante, c’est celle qui a fait l’œuf
La première qualité du style, c’est la clarté
La première raie n’est pas la pause
La première raie, elle fait pas la journée
La première rogne en mariage, est de l’argent et apanage
La première épouse bergère, la seconde épouse dame
La première épousée est la servante, la seconde la maîtresse
La preuve incombe à celui qui affirme, non à celui qui nie
La prière des grands, c’est le lieu là où les refusants trouvent les coups de bâton
La prière du juste a grande efficace
La prière est la respiration de l’âme
La prière est le plus grand rempart de l’âme
La procession compte dans la messe (L Morin) : Le déplacement se paie avec le travail
La prodigalité est un gouffre sans fond
La profession d’hypocrite a de merveilleux avantages
La promesse est une dette
La prosopolâtrie fait l’idolâtrie
La prospérité demande la fidélité, l’adversité l’exige
La prospérité fait peu d’amis
La prospérité montre les heureux, l’adversité révèle les grands
La prospérité trouve toujours des amis
La providence a fait aux hommes cette faveur que les choses honnêtes apportent plus de profit
La prudence est bonne en soi, mais la pousser trop loin est une duperie
La prudence est le plus sûr des remparts, car jamais il ne tombe et jamais il n’est livré par trahison
La prudence qui sait se rétracter et céder aux conjonctures est une des formes de l’art de gouverner
La pruderie est une espèce d’avarice, la pire de toutes
La précipitation est un mauvais guide
La pudeur chez les femmes n’est qu’une coquetterie bien entendue
La pudeur des femmes tombe avec leur vêtement
La pudeur est dans les yeux
La pudeur est une vertu que l’on attache avec des épingles
La pudeur ne s’enseigne pas, elle est innée
La pureté est à l’âme ce que la propreté est au corps
La putain aussi la corneille, tant plus se lave plus noire est-elle
La qualité laitière de la vache et la force de l’homme passent par les dents
La qualité prime sur le prix
La queue du chat est bien venue, mon tour arrivera aussi
La queue est la pire à écorcher
La queue fait l’oiseau
La queue lui traîne et n’a que manger
La queue refait l’oiseau
La race des femmes est de nature traîtresse
La race ni beauté corporelle ne peuvent anoblir l’homme
La raillerie est l’épreuve de l’amour-propre
La raillerie est une insolence de bon ton
La raison a beau crier, l’imagination a établi dans l’homme une seconde nature
La raison du plus fort est toujours la meilleure
La raison est bonne partout
La raison est la fille du Temps, et elle attend tout de son père
La raison est pour les hommes, la force est pour les bêtes
La raison est un glaive double et dangereux (Montaigne; Pascal) : Deux excès : exclure la raison, n’admettre que la raison
La raison est une arme plus pénétrante que le fer
La raison nous trompe plus souvent que la nature
La raison n’est pas ce qui règle l’amour
La raison passe partout
La raison peut nous avertir de ce qu’il faut éviter, le cœur seul nous dit ce qu’il faut faire
La raison qui s’emporte a le sort de l’erreur
La raison se connaît en temps et saison
La raison souvent n’éclaire que les naufrages
La raison, c’est l’intelligence choisissant la sagesse
La ramassoire se moque de l’écouvillon
La rancune est le propre des méchants
La rareté du fait donne du prix à la chose
La rareté fait le prix des choses
La rave vaut bien le chou
La rechute est pire que la maladie
La recommandation d’un mort est bien peu de chose auprès des vivants
La reconnaissance de la plupart des hommes n’est qu’une secrète envie de recevoir de plus grands bienfaits
La reconnaissance d’un bienfait est un intérêt suffisant
La reconnaissance est la mémoire du cœur
La reconnaissance est un devoir
La reconnaissance est un fardeau et tout fardeau est fait pour être secoué
La reconnaissance vieillit vite
La religion est comme l’eau douce que l’on emporte sur la haute mer, il faut la ménager
La religion mal entendue est une fièvre qui peut tourner en rage
La religion ne nous fait pas bons, mais elle nous empêche de devenir trop mauvais
La richesse a des ailes et, comme l’aigle, elle s’envole vers les cieux
La richesse confond les races
La richesse consiste bien plus dans l’usage que dans la possession
La richesse d’une fille est du coude en avant
La richesse engendre la satiété, et la satiété la démesure
La richesse est la place forte du riche; la pauvreté est la destruction du pauvre
La rime se fait en songeant mais la poésie en bien veillant
La rivière est contrainte chercher chemin
La robe fait l’homme
La robe ne fait pas le médecin
La roche tarpéienne est proche du Capitole
La ronce ne porte jamais le raisin
La roue de la fortune n’est pas toujours une
La roue du chariot mal engraissée crie
La roue tourne
La rougeur est la couleur de la vertu
La rouille ronge le fer
La rouilleure gâte le fer
La route des enfers est facile à suivre; on y va les yeux fermés
La route est longue par le précepte, mais courte et facile par l’exemple
La route qui conduit aux enfers est facile à suivre
La route qui monte et descend est une et la même
La ruse la mieux ourdie peut nuire à son auteur
La ruse vaut mieux que le métier
La récompense du devoir est le devoir même
La récompense d’une bonne action, c’est de l’avoir accomplie
La réflexion augmente les forces de l’esprit, comme l’exercice celles du corps
La réponse est selon que la demande est faite
La répréhension d’un ami fidèle est commendable
La république est le gouvernement qui nous divise le moins
La république sans justice ne peut être sans vice
La réputation d’une femme peut se renouveler
La résignation allège tous les maux auxquels il ne peut être remédié
La résignation est au courage ce que le fer est à l’acier
La sagesse du pauvre est méprisée et ses paroles ne sont pas écoutées
La sagesse du scribe s’acquiert à la faveur du loisir et celui qui a peu d’ouvrage deviendra sage
La sagesse est d’épouser une beauté limitée
La sagesse est pour les sots comme une maison en ruine
La sagesse fait durer, les passions font vivre
La sagesse ne consiste pas plus dans la science que le bonheur dans la richesse
La sagesse, c’est la prévoyance
La saison amène moisson
La saison est d’aller aux bains quand on a argent en bourse
La saleté est compagne de la misère
La santé est la qualité la plus méritoire du corps
La santé est le trésor le plus précieux et le plus facile à perdre; c’est cependant le plus mal gardé
La santé et la réputation se reconnaissent à l’ouvrage et non à la parole
La santé sans argent est moitié maladie
La santé se peint sur le visage
La santé, c’est un esprit sain dans un corps sain
La santé, on ne connaît son prix que quand on l’a perdue
La satisfaction de la bouche est la satisfaction de l’estomac
La satiété engendre le dégoût
La sauce coûte plus cher que le poisson
La sauce fait avaler le morceau
La sauce fait passer le poisson
La sauge sauve
La science de la vie se rapproche davantage de l’art de la lutte que de l’art de la danse
La science de l’ignorant, c’est de reprendre les choses bien dites
La science du fol est tenue pour insipience
La science est comme la terre; on n’en peut posséder qu’un peu
La science ne sert guère qu’à nous donner une idée de l’étendue de notre ignorance
La science vaut mieux que l’or pur
La science, chacun le sait, a ennemi cil qui ne sait
La semence ne fructifie pas en chaque terrien
La semence ne profite rien, n’est qu’elle tombe en bon terrien
La sensualité est semblable au crocodile
La servitude abaisse les hommes jusqu’à s’en faire aimer
La seule avarice du temps, est louable et en prix grand
La seule certitude, c’est que rien n’est certain
La seule vertu remédie au vice
La simplicité affectée est une imposture délicate
La simplicité véritable allie la bonté à la beauté
La simplicité, qui devrait être une qualité naturelle, a souvent besoin d’étude pour s’acquérir
La sincérité est une ouverture de cœur
La sincérité qui n’est pas charitable est comme la charité qui n’est pas sincère
La singulière sagesse est Dieu connaître, lequel ignorer n’est rien savoir
La sobriété est la première médecine
La société a besoin de poètes, comme la nuit a besoin d’étoiles
La société serait une chose charmante, si l’on s’intéressait les uns aux autres
La soie d’été, le drap d’hiver
La soie est un étronc de vers
La soir montre ce qu’a été le jour
La solitude est à l’esprit ce que la diète est au corps
La sonnette qui n’a point de battant vient à s’user, demeurant toujours accrochée contre la paroi
La sotte vanité semble être une passion inquiète de se faire valoir par les petites choses
La sottise est un mal incurable
La sottise et la vanité sont compagnes inséparables
La souffrance est la loi de fer de la nature
La soupe fait le soldat
La souris est tôt prise qui n’a qu’un pertuis
La souris qui n’a qu’un trou est tôt prise
La souris qui n’a qu’une entrée est incontinent happée
La superstition est la seule religion dont soient capables les âmes basses
La superstition introduit les dieux, même dans les plus petits choses
La superstition porte quelque image de la pusillanimité
La superstition suit l’orgueil et lui obéit comme à son père
La surabondance de cire, brûle la maison notre sire
La surprise est l’épreuve du vrai courage
La sursomme abat l’âne
La sévérité bien ordonnée commence par soi-même
La sévérité prévient plus de fautes qu’elle n’en réprime
La table engendre des amis
La table est un larron secret et coûtable
La table mise ouvre l’appétit
La table nous gagne plus d’amis que la bonté
La table remet, le lit repose
La table sans pain fait pleurer, la table sans vin souffrir
La tactique, c’est l’art de se faire demander comme une grâce que l’on brûle d’offrir
La tempérance et le travail sont les deux médecins de l’homme
La tempérance et le travail sont les meilleurs médecins de l’homme
La tempête et l’horrible orage, découvrent du pilote le courage
La tendre har se plie et tord plus aisément que le vieil chêne
La terre couvre tout
La terre ne peut tolérer deux soleils
La terre ne rend jamais sans intérêt ce qu’elle a reçu
La terre nous fait attendre ses présents à chaque saison, mais on recueille à chaque instant les fruits de l’amitié
La terre parle
La terre tourne en un jour, la femme en une seconde
La terre vaut selon son chef, qui l’a bon est sûr de méchef
La timidité n’a jamais mené au premier rang
La tisane de romarin, ou sauve ou fait mourir
La tortue dit que sa propre maison est son logis idéal
La tournure et la démarche ont autant d’accent que la parole
La tourterelle fait pitié quand elle a perdu sa moitié
La toux est le tambour de la mort
La tragédie ne fait plus d’effet depuis qu’elle court les rues
La tricherie revient à son maître
La trop grande charge crève la panse
La trop grande conversation, d’amitié diminution
La trop grande subtilité est une fausse délicatesse, et la véritable délicatesse est une solide subtilité
La truie ne pense pas qu’elle est de la fange
La témérité est l’exagération du courage à braver inutilement des périls
La tête fait courir les jambes
La vache de l’étranger a le pis gros
La vache qui a faim, elle voit l’herbe
La vache se trait par la dent
La valeur consiste à dompter ce qui fait trembler tout autre
La valeur d’une troupe est celle de son commandement Voir aussi : Bon capitaine, bons soldats
La vanité ruine plus de femmes que l’amour
La veille des noces le mari est de la paroisse Saint Innocent, le jour de Saint Pris, le lendemain de Saint Marri
La veille des noces le mari est de la paroisse Saint Innocent, le jour de la paroisse Saint Pris, le lendemain de la paroisse Saint Marri
La veille mouton, le lendemain dragon
La vengeance appartient à Dieu
La vengeance est la joie des âmes basses
La vengeance est plus douce que le miel
La vengeance est un plat qui se mange froid
La vengeance et la rancune portent pas bonheur
La vengeance guette les méchants comme un lion
La vengeance met en général beaucoup de temps à mûrir et se manifeste ainsi au moment où on s’y attend le moins Voir aussi : Ce qui est différé n’est pas perdu
La verge et le bâton, à l’âme consolation
La verge pour les enfants, le bâton pour les grands et la mort pour les méchants
La verge purge le péché
La vermine n’arrive que pour manger
La vertu a bien des prédicateurs et peu de martyrs
La vertu a cela d’heureux qu’elle se suffit à elle-même
La vertu après les écus
La vertu est la route la plus courte vers la gloire
La vertu est la santé de l’âme
La vertu est le juste milieux entre deux vices
La vertu est le meilleur appeau
La vertu est sa propre récompense
La vertu est un flambeau qui n’illumine pas seulement celui qui la possède, mais encore celui qui la regarde
La vertu et le vice n’habitent pas en un même domicile
La vertu même a besoin de limites
La vertu ne gît pas en une seule œuvre
La vertu n’irait pas si loin, si la vanité ne lui tenait compagnie
La vertu prisée croît
La vertu sans argent est un meuble inutile
La veuve riche, pleure d’un œil et cligne de l’autre
La viande de laine se mange saignante
La viande est pour le ventre gras, le pauvre ronge les os
La viande modérée égaie et agaillardit l’esprit
La victoire aime l’effort
La victoire est au premier aussi bien qu’au dernier coureur
La victoire est belle, mais il est encore plus beau d’en bien user
La victoire sur soi est la plus grande des victoires
La vie de l’homme est courte comme l’ombre
La vie de l’homme n’est qu’une chandelle à la face du vent
La vie de l’homme n’est qu’une vessie pleine de vent
La vie de l’homme s’écoule et fuit, la mort à grande randonnée suit
La vie de l’homme étant sur terre, est une perpétuelle guerre
La vie des morts consiste à survivre dans l’esprit des vivants
La vie est courte, l’art est long, l’occasion fugitive, l’expérience trompeuse, le jugement difficile — Hippocrate, parlant de la médecine
La vie est courte, mais les malheurs la rendent longue
La vie est dans la santé, non dans l’existence
La vie est demi usée avant qu’on sache qu’est vie
La vie est faite de bien des morceaux, mais ils sont bien différents
La vie est un dur combat, les morts sont bienheureux
La vie est un songe
La vie est une sorte de mystère triste dont la foi seule a le secret
La vie et non la naissance anoblit l’homme
La vie humaine est semblable à un théâtre
La vie nous console de mourir, et la mort de vivre
La vie n’a de prix que par le dévouement à la vérité et au bien
La vie n’est de soi ni bien ni mal; c’est la place du bien et du mal selon que vous la leur faites
La vie n’est qu’un souffle; le nuage se dissipe et passe
La vie n’est-elle pas plus que la nourriture, et le corps plus que le vêtement
La vie ressemble à un conte; ce qui importe, ce n’est pas son longueur, mais sa valeur
La vie sans bonnes œuvres n’est qu’une propre mort
La vie s’en va comme la rose
La vieille fille voudrait ramasser avec ses deux mains ce qu’elle a repoussé du pied
La vieillesse du lion vaut plus que la jeunesse du faon
La vieillesse est elle-même une maladie
La vieillesse nous attache plus de rides en l’esprit qu’au visage
La vigne et le poirier, la fille et le pêcher, sont difficiles à garder
La violence et la vérité ne peuvent rien l’une sur l’autre
La violence fait les tyrans, la douce autorité les rois
La violence qu’on se fait pour demeurer fidèle à ce qu’on aime ne vaut guère mieux qu’une infidélité
La vive voix a plus d’efficace que n’ont les livres
La voie de vertus ressemble à la pyramide
La voie des méchants est ténébreuse; ils n’aperçoivent pas ce qui les fera tomber
La voie des perfides est rude
La voilà celle que tu désires tant, ne la fais pas servir d’essuie-pieds
La voix du peuple est la voix de Dieu
La voix d’un condamné peut se faire entendre, mais ses paroles sont vaines
La voix d’un viel chien doit-on croire
La voix est la fleur de la beauté
La volonté est réputée pour le fait
La vraie morale se moque de la morale
La vraie noblesse s’acquiert en vivant et non pas en naissant
La vraie richesse est celle de l’esprit
La vraie éloquence se moque de l’éloquence
La vue de l’ivrogne est la meilleure leçon de sobriété
La vue diminue à celui qui ne voit point le soleil
La vue découvre l’œuvre
La vue découvrira le fait
La véritable douleur est rarement exprimée
La véritable politesse consiste à marquer de la bienveillance aux hommes
La vérité engendre la haine
La vérité est au fond du verre
La vérité est courte de jambes
La vérité est dans le rire
La vérité est dans le vin
La vérité est fille du temps
La vérité est la gloire de l’homme
La vérité est plongée au fond d’un puits
La vérité est souvent éclipsée, mais jamais éteinte
La vérité est un flambeau qui luit dans un brouillard sans le dissiper
La vérité est un fruit qui ne doit être cueilli que s’il est tout à fait mûr
La vérité est une dame que l’on replonge volontiers dans son puits, après l’en avoir tirée
La vérité est vaincue par la force
La vérité l’anglet défuit
La vérité ne gagne pas toujours à montrer son visage
La vérité n’est pas aimée des rois
La vérité parle aussi bien contre les femmes que contre les hommes
La vérité qui n’est pas charitable procède d’une charité qui n’est pas véritable
La vérité sort de la bouche des enfants
La vérité s’élève au-dessus du mensonge, comme l’huile au dessus de l’eau
Labeur constant en opération, sur toute chose a domination
Labeur ne grave point quand on y prend plaisir
Labeur sans soin, labeur de rien
Labeur, cure, soin et diligence, sont partout sentiers à la science
Labeur, travail, exercice et la somme, de tristesse atténuent le faix et somme
Labeure bien et recueilleras bien
Laid au berceau, joli dans la rue
Laid en-dehors, beau en-dedans
Laide chatte, beau chaton
Laide chatte, beau minon ; belle minette, laid chaton
Laide femme vaut mieux que la moitié d’une belle
Laisse au fils le sang de son père
Laisse seulement faire la poule, tôt ou tard elle picorera
Laisser aller chacun son chemin, on en reçoit joie sans fin
Laisser aller le chat au fromage
Laisser aller l’eau vers le bas
Laisser courir les batses et courir après la merde
Laissez cuire la viande qui n’est pas à manger
Laissez dire les sots, le savoir a son prix
Laissez pisser le mouton
Laissons toujours faire celui qui emmanche les cerises
Lait et vin font engraisser
Lait et vin tuent le bambin
Lait et vin, poison fin
Lait sur vin est venin, vin sur lait est souhait
Langue de femme, langue de flamme
Langue d’or aboie l’or
Langue empâtée, méfie-toi jeune homme
Langue en mangeant s’embourbe, en buvant s’éclaircit
Langue gâtée, estomac chargé
Langue humaine n’a nul os et tranche menus et gros
Langue humide et pied chaud préservent de tous maux
Langue mensongère, de l’âme est meurtrière
Langue muette n’est pas battue
Langue rouge, signe de santé
Langue sèche, feu dehors
Langue vipérine et double, cause souvent noise et grand trouble
Lard vieux, bonne soupe
Larme de femme affole le sot
Larmes de femmes sèchent vite
Larrons pendus, biens perdus
Las bœuf souef marche
Latin : Res perit domino Le dommage résultant de la perte d’une chose incombe au propriétaire de cette chose
Latin : Vox populi, vox dei L’opinion du plus grand nombre s’impose
Latin: Absens haeres non erit
Latin: Affirmanti, non neganti, incumbit probatio
Latin: Alea iacta est La décision est maintenant traduites en actes irréversibles, impossible de revenir en arrière
Latin: Amat victoria curam
Latin: Aquila non capit muscas
Latin: Aquila non capit muscas – Un homme supérieur ne s’occupe pas des petites questions mais uniquement d’affaires importantes Variantes : L’aigle n’attrape pas (ne vole pas après) les mouches – Autres variantes : Les aigles ne s’amusent pas à prendre des mouches – Les aigles s’occupent pas à piquer des mouches
Latin: Aurora quia habet aurum in ore Jeu de mots entre aurora, aurum et ore Autre version : On l’appelle Aurore parce qu’elle a de l’or dans la bouche
Latin: Cito transit lancea stulti
Latin: Consuetudo est optima legum interpres
Latin: Corruptio optimi pessima
Latin: De minimis non curat praetor Quelqu’un qui commande n’a pas à s’occuper de vétilles
Latin: Dura lex, sed lex
Latin: Fames est optimus coquus
Latin: Festinatio justiliae est noverca infortunii
Latin: Finis coronat opus – L’ouvrage est achevé ou bien : on ne doit pas se décourager
Latin: Fraus latet in generalibus
Latin: Lux umbram monstrat, mysteria autem veritas
Latin: Mens sana in corpore sano
Latin: Mitis praelatus facit ignavos famulatus
Latin: Natura abhorret vaccum
Latin: Prima est ne ars videatur La perfection de l’art, c’est que l’art n’apparaisse pas
Latin: Propria laus sordet in ore
Latin: Queavis terra alit artem
Latin: Risus profundior lachrimas parit
Latin: Sapiens nihil affirmat quod non probat
Latin: Si sapis, uxori sit stata formma tuae
Latin: Sol omnibus lucet On ajoute : mais bien des gens sont à l’ombre Chacun peut profiter des circonstances favorables qui s’offrent à lui Tous les hommes ont droit au bonheur
Latin: Ubi omnes sordent, unus minime sentitur
Latin: Venit morbus eques, suevit abire pedes
Latin: Vesper laudatur dies
Latin: Vetustas pro lege semper habetur
Latin: Vigilantibus, non dormientibus, subveniunt jura
Lauregui a son pourpoint tout couvert de galons, mais le dedans n’est qu’étoupe
Lauregui méprise ce qu’il ne peut comprendre
Laver la laine noire veut pas (de)venir blanche
Laver les mains est une propreté qui contribue à la santé
Le Bon Dieu a envoyé la chèvre avec le buisson
Le Bon Dieu a laissé à tous un morceau de sa croix
Le Bon Dieu a pas crée l’oiseau sans mettre à côté le buisson pour le nourrir
Le Bon Dieu a pour chacun une poire
Le Bon Dieu a pour tous de sa miche
Le Bon Dieu a pour tous un morceau
Le Bon Dieu a été crucifié qu’un coup
Le Bon Dieu change aussi
Le Bon Dieu donne des noisettes à ceux qui ne savent pas les casser
Le Bon Dieu donne les noix à ceux qui ne savent pas les écailler
Le Bon Dieu donne à casser ses coques à celui qui n’a rien de dents
Le Bon Dieu envoie des noisettes à ceux qui n’ont plus de dents
Le Bon Dieu envoie toujours son soleil pour sécher la chemise des pauvres gens
Le Bon Dieu est bon, que les bonnes gens sont rares
Le Bon Dieu est meilleur que les saints
Le Bon Dieu est venu pour les pécheurs, il (n’)est pas venu pour les justes
Le Bon Dieu met toujours le buisson à côté de l’agneau
Le Bon Dieu met toujours le remède à côté du mal
Le Bon Dieu n’envoie pas le cabri sans le buisson pour le nourrir
Le Bon Dieu n’envoie pas l’oiseau sans la becquée pour le nourrir
Le Bon Dieu pardonne tout sauf l’orgueil
Le Bon Dieu se laisse fléchir, mais se laisse pas commander
Le Bon Dieu à tous donne une croix
Le Carême est court quand on a des dettes à Pâques
Le Carême ne dure guère à la table d’autrui
Le Lion devenu vieux
Le Seigneur Dieu sonde tout
Le baillement fréquent est le messager de la faim ou du sommeil
Le baillement ne ment pas
Le bambin pleure pour son bien et le vieux pour son mal
Le beau du jeu est bien faire et parler peu
Le beau jour se prouve au soir
Le beau parler = douce parole
Le beau parler n’écorche pas la langue
Le beau parler réfreint souvent grande ire
Le beau, c’est la splendeur du vrai
Le beau-père dans le cercueil, quatre beaux lards à la cheminée
Le bel esprit est, à le bien définir, le bon sens qui brille
Le besoin est un docteur en stratagème
Le besoin fait la vieille trotter
Le besoin fait tout faire
Le bien cherche le bien
Le bien est très mal employé, qui de son maître n’est subjugué
Le bien fait moins de bruit, le bruit fait moins de bien
Le bien lui vient en dormant
Le bien mal acquis mal finit
Le bien n’est pas dans la grandeur, mais la grandeur dans le bien
Le bien perdu mieux on connaît qu’on ne faisait quand on l’avait
Le bien sué ou à haut prix acheté est le moins envié
Le bien tient à peu de chose, mais n’est pas peu de chose
Le bien, encore que soit peu, qui le refuse est bien gueux
Le bien-faire vaut mieux que le bien-dire
Le blanc et le noir, ont fait Venise richesse avoir
Le boire est le ciment du corps et de l’âme
Le bois a des oreilles et le chemin des yeux
Le bois sec, le pain dur, tiennent la maison en gaieté
Le bois tortu (tordu) fait le feu droit
Le bois volé brûle mieux
Le boiteux veut jouer à la balle
Le boiteux à la fin rattrape le rapide
Le bon a besoin de preuves, le beau n’en demande point
Le bon amour ne va jamais sans crainte
Le bon arbre ne peut produire (de) mauvais fruit
Le bon commencement attrait la bonne fin
Le bon craint de pécher pour l’amour de (la) vertu, le méchant d’offenser de peur d’être battu
Le bon enfant égaie la vieillesse de son père
Le bon fils réjouit son père et le fol contriste sa mère
Le bon goût vient plus du jugement que de l’esprit
Le bon historien n’est d’aucun temps ni d’aucun pays
Le bon juge condamne le crime sans haïr le criminel
Le bon juge ne sera pas un jeune homme; il faut qu’il soit vieux et qu’il ait acquis une connaissance de l’injustice
Le bon lait vient de la chair et non de l’os
Le bon marché coûte cher
Le bon marché déçoit souvent les gens
Le bon pain fait les bonnes soupes
Le bon pasteur donne sa vie pour ses brebis
Le bon pasteur tond en saison son troupeau, sans écorcher le cuir toison ni peau
Le bon pasteur tond son troupeau, sans l’écorcher ni grain toucher le cuir ni peau
Le bon payeur est de bourse d’autrui seigneur
Le bon payeur est d’autrui bourse seigneur
Le bon prince doit également profiter au grand comme au petit
Le bon prince, seigneur ou père, est le vrai médecin de ses vassaux, enfants ou sujets
Le bon profit ne se dit pas
Le bon père ne donnera pas chose mauvaise à son enfant
Le bon sang ne peut mentir
Le bon se connaît entre les mauvais
Le bon sens est la chose du monde la mieux partagée
Le bon sens s’accommode au monde; la sagesse tâche d’être conforme au ciel
Le bon service amène le bénéfice
Le bon ton, c’est le bon goût appliqué aux discours et à la conversation
Le bon valet dit à son maître, après servir convient repaître
Le bon vin fait parler latin
Le bon vin, fait parler latin
Le bon écuyer fait le bon chevalier
Le bonheur des méchants comme un torrent s’écoule
Le bonheur des méchants est un crime des dieux
Le bonheur est en soi, chez soi, autour de soi, et au-dessous de soi
Le bonheur est la poésie des femmes, comme la toilette en est le fard
Le bonheur est à ceux qui se suffisent à eux-mêmes
Le bonheur fuit celui qui le suit
Le bonheur ne fleurit pas pour ceux qui suivent des chemins obliques
Le bonheur ressemble à un diamant, et le plaisir à une goutte d’eau
Le bonheur réside dans l’aisance et l’indépendance
Le bonheur tient aux événements, la félicité tient aux affections
Le bonnet vaut bien le chapeau
Le borgne a pitié de l’aveugle
Le bossu ne voit pas sa bosse et voit celle de son confrère
Le bourgeon n’est pas le raisin
Le bouton devient la rose et la rose le gratte-cul
Le bruit est pour le fat, la plainte est pour le sort, l’honnête homme trompé s’éloigne et ne dit mot
Le bruit ne fait pas de bien, et le bien ne fait pas de bruit
Le buisson a rien d’oreilles, mais il y en a beaucoup qu’il écoute
Le but de la discussion ne doit pas être la victoire, mais l’amélioration
Le but n’est pas toujours placé pour être atteint, mais pour servir de point de mire
Le but sert d’excuse aux actes répréhensibles commis pour l’atteindre
Le bœuf fatigué trace de fortes empreintes
Le bœuf maigre est mieux que le bœuf gras
Le bœuf méchant croît par les cornes
Le bœuf ne sait (ce) que vaut sa corne tant qu’il l’ait perdue
Le bœuf quand il a mangé boit
Le bœuf vieux, changez-le de climat, il y laissera la peau
Le cachet de la médiocrité, c’est de ne pas savoir se décider
Le cadavre d’un ennemi sent toujours bon (Vitellius))
Le calme et la bonace, tempête souvent menace
Le canard et le pigeon, manger d’or, chier de plomb
Le canon est la cloche du soldat
Le caprice de notre humeur est encore plus bizarre que celui de la fortune
Le caractère de l’homme apparaît en voyage
Le caractère du vrai mérite est de n’être jamais content de soi
Le cerveau de la femme est fait de crème de singe et de fromage de renard
Le chagrin causé par le mal d’autrui est passager
Le chagrin en a tué beaucoup, et il n’y a pas en lui de profit
Le chagrin est comme la maladie
Le chagrin ne se guérit pas par des raisons
Le chagrin paie pas de dettes
Le chagrin tue l’homme et nourrit la femme
Le champ a (des) yeux et le bois (des) oreilles
Le changement de modes est l’impôt que l’industrie du pauvre met sur la vanité du riche
Le changement de travail est une espèce de repos
Le chant allège les sombres soucis
Le chapeau doit commander la coiffe
Le chapelet dans la main, le diable dans la capuche
Le char avant les bœufs
Le charbon donne un brasier et le bois du feu; ainsi l’homme querelleur fait une dispute
Le chardon plaît bien à l’ânon et l’étron chaud à lord cochon
Le chasteté est la première beauté
Le chat brûlé ne se laisse pas brûler deux coups Deux coups = deux fois
Le chat est parti, les souris dansent
Le chat qui miaule le soir, ne prend guère de souris le lendemain
Le chatiment qui se fait attendre n’en devient que plus terrible
Le chaudron trouve que la poêle est trop noire
Le chef-d’œuvre de Dieu, c’est le cœur d’une mère
Le chemin battu est le plus sûr
Le chemin de fer et la marée n’attendent pas
Le chemin de la vertu est long et escarpé, mais à mesure que l’on s’élève, le chemin devient plus aisé, quoique difficile
Le chemin du paresseux est comme une haie d’épines
Le chemin est assez mauvais, sans nous jeter encore des pierres
Le chemin est long du projet à la chose
Le chemin est un mauvais voisin
Le chemin s’aplanit pour la juste cause
Le cheval a quatre pattes et pourtant il bronche
Le cheval au quadrige, le bœuf à la charrue
Le cheval court, le cavalier se vante
Le cheval du roi mange à ses heures
Le cheval est dangereux devant, dangereux derrière et inconfortable au milieu
Le cheval est la plus noble conquête que l’homme ait jamais faite (Georges Louis Buffon) : Extrait de Histoire naturelle
Le cheval indompté devient intraitable
Le cheval qui s’emballe avec la herse, se plante les dents de la herse dans le cul
Le cheval qui traîne son lien n’est pas échappé
Le cheval se régit par la bride et par l’éperon et la richesse par la raison
Le cheval va moins vite que l’hirondelle, qui va moins vite que le vent, qui va moins vite que l’éclair
Le chien (de) Maître Jean de Nivelle(s), s’enfuit toujours quand on l’appelle
Le chien a la langue où il a mal
Le chien aboie plutôt que de mordre
Le chien au matin à l’herbe va pour son venin
Le chien du ferronnier s’endort au marteler et se réveille au denteler
Le chien du ferronnier s’endort au son du marteler et se réveille au denteler
Le chien détaché traîne encore son lieu
Le chien inquiet a toujours l’oreille pelée
Le chien larron rend le valet soigneux
Le chien maigre est tout puces
Le chien ne mange pas du son lui-même ni ne veut souffrir que les poules en mangent
Le chien ne mange pas le chien
Le chien ne s’apprivoise pas avec des coups de pierres
Le chien porte sa langue là où il sent son mal
Le chien qui a perdu la queue a pas peur de montrer le cul
Le chien qui est à deux maîtres a sa mangeaille placée bien haut
Le chien qui lâche sa proie pour l’ombre n’a ni l’ombre ni le corps
Le chien qui ne mange pas son content deviendra enragé
Le chien réhume ce qu’il a vomi
Le chien se défend quand on lui ôte un os
Le chien timide aboie plus que les autres
Le chien voyons du fin matin chercher l’herbe contre venin
Le chien échaudé, d’eau froide est intimidé
Le chirurgien doit avoir un œil d’aigle, un cœur de lion et une main de femme
Le cidre qu’on a eu en don a meilleur goût que le vin qu’on a acheté
Le cidre reçu en don a meilleur goût que le vin qui a été acheté
Le cinquième marteau à l’enclume y sert autant que coup de plume
Le clou qui dépasse attire le marteau
Le clou souffre autant que le trou
Le code de salut des nations n’est pas celui des particuliers
Le coffre au feu ne se jette parce qu’on en a perdu la clé
Le coin ne peut rien sans la cognée
Le cois pend le larron
Le collier vaut mieux que le cheval
Le combat est père et roi de l’univers; il a créé les dieux et les hommes; il a rendu les uns esclaves, les autres libres
Le commandement révèle l’homme
Le commencement est la moitié du tout
Le commerce est l’école de la tromperie
Le commerce est mère de monnaie
Le compagnon de lit se choisit pendant qu’il fait jour
Le complant du pauvre est clair et mal fourni de plantes et encore, celles qui y sont se trouvent tordues
Le compliment exagéré est pire qu’une injure
Le conseil est bon pour ceux qui vivent richement
Le contentement fait la richesse
Le contentement vaut mieux que la fortune
Le copeau ne saute guère loin du tronc
Le copeau ne saute pas loin de la bille
Le copeau ne saute pas loin de la souche
Le copeau tient de la nature du bois duquel il est tiré
Le coq amasse, la poule dissipe
Le coq du clocher se tourne au son de tambourin
Le coq est roi sur sa courtine
Le coq est roi sur son fumier
Le corbeau reproche à la corneille la noirceur de tête
Le corps est le temple de l’esprit
Le corps est plutôt habillé que l’âme
Le corps excelle le vêtement et l’âme le corps
Le corps par trop vigoureux rend l’esprit langoureux
Le corrompre avec de l’argent
Le cotillon est bien court par devant
Le coucher de la poule et le lever du corbeau éloignent l’homme de la mort
Le coup de pied de l’âne va au lion devenu vieux
Le coup prévu est moins dur
Le coupable craint la loi et l’innocent le sort
Le coupable est celui à qui le crime profite
Le coupable n’est jamais à repos
Le courage conduit aux étoiles et la peur à la mort
Le courage croît en osant et la peur en hésitant
Le courage est comme l’amour; il veut de l’espérance pour nourriture
Le courage fait les vainqueurs ; la concorde, les invincibles
Le couteau trop aiguisé déchire sa gaine
Le coût dégoûte
Le coût empêche le goût
Le coût fait perdre le goût
Le coût fait perdre le goût
Le crapaud trouve que son petit ressemble à une grenouille
Le cri de la loi est trop faible pour dominer le fracas des armes
Le cri public sert quelquefois de preuve, ou du moins fortifie la preuve
Le crime est juste pour une juste cause
Le crime fait la honte, et non pas l’échafaud
Le crime ne paie pas
Le crocodile verse des larmes avant de dévorer sa proie
Le crédit, c’est à la fois ceinture dorée et bonne renommée
Le cupide tue la poule aux œufs d’or
Le cygne incite les humains de se réjouir de l’avènement de la mort
Le cygne, plus il vieillit, plus il embellit
Le cynisme est l’assurance avec laquelle on fait ou l’on dit des choses honteuses
Le célibat ou la femme de bien
Le cœur a ses raisons que la raison ne connaît point
Le cœur au courage, fait l’ouvrage
Le cœur content est un festin perpétuel
Le cœur content fait la face belle
Le cœur de la coquette est un piège et ses mains sont des liens
Le cœur de l’avare est insatiable
Le cœur de l’homme est avide et insatiable
Le cœur de l’homme est tortueux et inscrutable
Le cœur du fou est sur sa langue, la langue du sage est dans son cœur
Le cœur d’un homme d’État doit être dans sa tête
Le cœur et le courage, font l’ouvrage
Le cœur fait l’œuvre, non pas les grands jours
Le cœur fait l’œuvre, non pas les grands jours ou les grands corps
Le cœur garde le corps et le mène où bon lui semble
Le cœur mène où il va
Le danger est dans le délai
Le danger que l’on pressent, mais que l’on ne voit pas, est celui qui trouble le plus
Le danger vient plus vite quand on le méprise
Le dard du faible est émoussé
Le dernier coup abat le chêne
Le dernier venu est le mieux aimé
Le despote coupe l’arbre pour avoir le fruit
Le dessein fait le crime, et non le hasard
Le destin conduit celui qui consent et tire celui qui résiste
Le destin est comme la tortue d’Eschyle
Le devoir avant tout
Le devoir d’un général n’est pas seulement de songer à la victoire, mais de savoir quand il faut y renoncer
Le devoir d’une épouse est de paraître heureuse
Le devoir est un dieu qui ne veut point d’athée
Le diable a toute la semaine pour s’accaparer de ce qu’on a pris au Bon Dieu le dimanche
Le diable chie toujours au même endroit
Le diable chie toujours sur les prés gras
Le diable est le père de (du) mensonge
Le diable est toujours le même, (de)vient pas vieux
Le diable fait les pots mais il ne fait pas toujours les couvercles
Le diable ne dort jamais
Le diable ne sera pas toujours diable
Le diable nous surveille comme le chat la souris
Le diable n’apparaît qu’à celui qui le craint
Le diable n’est pas aussi noir qu’il en a l’air
Le diable n’est pas toujours à la porte d’un pauvre homme
Le diable n’est pas toujours à un huis
Le diable prend ce qu’on ôte à Dieu
Le diable qui possède les femmes quand elles ont le diable au corps est un diable tenace
Le diable se cache sous les ongles longs
Le diable tient la femme sous l’homme pour tenir l’homme sous lui
Le diable va toujours chier au gros tas
Le diable était beau quand il était jeune
Le diable, plus il a, plus il veut avoir
Le dieu de la guerre est toujours du côté des gros bataillons
Le difficile va dormir sans souper
Le dimanche sans communion, fait de toi un pauvre brenyon
Le dire sans fait, à Dieu déplaît
Le discours a bien autre efficace quand il sort de la bouche d’un homme riche que quand il sort de la bouche d’un pauvre misérable
Le discours est le visage de l’esprit
Le distrait éclate de ce qui lui passe par l’esprit et répond à sa pensée
Le dit a plus d’efficace que l’écrit
Le divorce est le sacrement de l’adultère
Le divorce n’est pas un honneur pour la femme
Le don brise montagne et mont
Le don humilie rocher et mont
Le don lie cil qui le reçoit, qui ne le reconnaît déçoit
Le doute amène l’examen, et l’examen la vérité
Le doute est la clef de toute connaissance
Le doute est le commencement de la sagesse
Le doute est le remède qu’enseigne la sagesse
Le doux parler n’est sans amer
Le droit est l’épée des grands, le devoir est le bouclier des petits
Le droit est pour le mérite, et le succès pour l’intrigue
Le droit vient toujours au droit
Le dé en est jeté
Le débiteur n’aime pas à voir la porte de son créancier
Le découragement est la mort morale
Le dédain de la renommée augmente le renom
Le démarieur aurait plus d’ouvrage que le marieur
Le dépit prend toujours le parti le moins sage
Le désavantage d’être au-dessous des princes est compensé par l’avantage d’en être loin
Le désespoir a souvent gagné des batailles
Le désespoir comble non seulement notre misère, mais notre faiblesse
Le désintéressement n’est parfois qu’un placement à de meilleurs intérêts
Le désir de la renommée tente même les esprits les plus nobles
Le désir de l’homme n’est jamais assouvi
Le désir de paraître habile empêche souvent de le devenir
Le désir est la moitié de la vie L’indifférence est la moitié de la mort
Le désir est le diesel du cœur
Le désir va jusqu’à créer la manie
Le désordre ramène l’ordre
Le fabuliste recommande de faire apprendre aux enfants un métier manuel
Le fainéant, le joueur, l’ivrogne et le mauvais cultivateur sont bêtes de même valeur
Le fait de ne rien faire laisse la possibilité de faire le mal et, en privant de ressources, augmente la tentation
Le fait juge l’homme
Le fanatisme est un monstre qui ose se dire le fils de la religion
Le fard et l’atour de la femme n’est que pour mettre le cerf en rut
Le fardeau ou la charge dompte la bête
Le fat est entre l’impertinent et le sot ; il est composé de l’un et de l’autre
Le faux ami ne se montre qu’au moment où tout se passe bien, de même que l’ombre ne se montre qu’au moment où le soleil brille
Le faux ami ressemble à l’ombre d’un cadran
Le fer aiguise le fer, ainsi l’homme aiguise un autre homme
Le feu de l’amour a plus tôt brûlé un cœur qu’il ne s’en est aperçu
Le feu de paille est un feu qui passe vite
Le feu de paille n’a durée qui vaille
Le feu est demi-vie d’homme
Le feu est la moitié de la vie
Le feu est le grand maître des arts
Le feu est soutenu par la cendre
Le feu est un bon valet mais un mauvais maître
Le feu et la poudre, les fous et les folles, faut les laisser pour ce qu’ils sont
Le feu et l’eau sont de bons valets mais de mauvais maîtres
Le feu et l’eau sont deux bons valets mais il faut pas laisser commander
Le feu le plus couvert est le plus ardent
Le feu ne se peut faire en un lieu si creux que la fumée n’en sorte
Le feu n’éteint pas le feu (Proverbe grec ancien) : Cité par Erasme Les semblables s’ajoutent et ne se neutralisent pas
Le feu plus couvert est le plus ardent
Le feu plus couvert est plus ardent
Le feu qui semble éteint souvent dort sous la cendre
Le feu éprouve l’or et l’or épreuve l’homme (ou le caractère)
Le feu, la mer et la femme amoureuse, sont trois choses dangereuses
Le feu, l’amour aussi la toux se connaissent par-dessus tout
Le fiente aux champs est Jupiter en terre
Le fil dont on renoue les amitiés rompues n’est qu’un fil d’araignée
Le fil triplé ne rompt pas facilement
Le filet pour l’oiseau, l’argent pour l’homme
Le fils de la chèvre est toujours un chevreau
Le fils de putain, s’il est bon c’est par aventure, s’il est mauvais c’est par nature
Le fils qui ressemble à son père fait honneur à la mère
Le flatteur est proche parent du traître
Le fol croit être sage
Le fol est plus hardi qu’un sage
Le fol fait la fête et convie et le sage s’en paît et réjouit
Le fol se coupe de son couteau
Le fol se glorifie de son savoir et le richot de son avoir
Le fol s’enivre de sa bouteille
Le fol, ivrogne et niais, en lieu d’aller droit va en biais
Le fort emporte le faible
Le fou se croit sage et le sage se reconnaît fou
Le fou se reconnaît sans clochette
Le fouet est pour le cheval, le mors pour l’âne, et la verge pour le dos des insensés
Le fouet et l’éperon, rendent le cheval bon
Le four appelle le moulin brûlé
Le fourgon se moque de la pelle
Le froc ne fait pas le moine
Le fromage gratuit se trouve sur la tapette à souris
Le froncement de sourcil de l’ami vaut mieux que le sourire de l’ennemi
Le fruit de la justice se sème dans la paix par ceux qui pratiquent la paix
Le fruit du figuier n’arrive pas en une heure à son point de maturité
Le fruit défendu n’est jamais le fruit des affamés
Le fruit ensuit la belle fleur et la bonne vie grand honneur
Le fruit le plus agréable au monde est la reconnaissance
Le fruit ne tombe pas loin de l’arbre
Le frêne en certaine saison près de la mare est un poison
Le frêre veut bien que sa sœur ait mais que rien du sien n’y ait
Le fuseau doit suivre le gorreau
Le gain a des ailes
Le gain fleure, d’où qu’il vienne, une bonne odeur
Le gain réjouit le cœur des hommes
Le garnement fêtard ne sert que d’empêchement au monde
Le geai c’est un bel oiseau, mais si on le voit trop on s’en fatigue
Le genre d’ennemis le plus funeste, ce sont les louangeurs
Le gentilhomme croit sincèrement que la chasse est un plaisir royal, mais son piqueur n’est pas de ce sentiment
Le gibet n’est que pour les malheureux
Le glaive de la justice n’a pas de fourreau
Le gourmand et gros ivrogne, est comparé au porc qui grogne
Le gouvernement despotique est un ordre de choses où le supérieur est vil et l’inférieur avili
Le goût de la cuisine est meilleur que l’odeur
Le goût est la conscience du beau, comme la conscience est le goût du bon
Le goût est le tact de l’esprit
Le goûter ne vient pas avec se croiser les bras
Le gracieux est toujours joli, le joli n’est pas toujours gracieux
Le grain vient tel qu’était la semence
Le grand a besoin du petit
Le grand bœuf apprend le petit à labourer
Le grand bœuf apprend à labourer le petit
Le grand dormir n’est pas sans songe
Le grand inconvénient des livres nouveaux, c’est qu’ils nous empêchent de lire les anciens
Le grand merci du vilain, c’est un rot
Le grand poisson mange le petit
Le grand qui promet, en promettant est quitte
Le guerrier qui cultive son esprit polit ses armes
Le génie commence les beaux ouvrages, mais le travail les achève
Le génie est toujours gentilhomme
Le génie est une longue patience
Le général qui voit avec les yeux des autres n’est pas capable de commander une armée
Le hasard donne les pensées et le hasard les ôte
Le hasard du jeu est dangereux
Le hasard gagne des batailles, mais le cœur ne se gagne que par des vertus
Le haut prix d’une chose fait qu’on n’a plus envie de l’acheter
Le hoquet, santé pour l’enfant et pour le vieillard fin prochaine
Le héros et le grand homme mis ensemble ne pèsent pas un homme de bien
Le jaloux aime plus, et l’autre aime bien mieux
Le jeu, la femme et vin friand font l’homme pauvre tout en riant
Le jeu, la nuit, lit et le feu, ne se contentent jamais de peu
Le jeu, le vin et les hommes, tous trois sont dissipateurs
Le jeu, les femmes et le bon vin perdent les hommes en se jouant
Le jeune Florian ayant perdu sa mère dit à un jeune garçon qui pleurait après une correction maternelle : Tu es bien heureux, toi, de pouvoir être battu par ta mère
Le jeune en temps envieillit, le fol jamais n’assagit
Le jeune à la noce, le vieux à la fosse
Le jeûne, aumône et oraison, au corps et âme sont guérison
Le jeûne, l’aumône et l’oraison, au corps et âme sont guérison
Le jour a des yeux, la nuit a des oreilles
Le jour auquel on se marie est le lendemain du bon temps
Le jour des noces et de l’enterrement sont deux journées de joie au survivant
Le jour du mariage est le lendemain du bien-être
Le jour est le père du labeur et la nuit est la mère des pensées
Le jour est paresseux mais la nuit est active
Le jour qu’on se marie est le dernier des beaux jours et le premier des laids
Le jour tire son éclat du soleil, nous tirons le nôtre des gens qui nous protègent
Le juge a le butin des voleurs
Le juge est condamné, quand le coupable est absous
Le juge qui a l’âme tachée tient les lois entre ses griffes
Le juge qui fait témoin dédire, pour l’écu va au grand stige
Le juge sans reproche est la postérité
Le jugement est ce qu’il y a de meilleur dans l’homme et le défaut de jugement ce qu’il y a de pire
Le jus d’absinthe est fort amer mais il guérit du mal de mer
Le juste agit par foi dans les moindres choses
Le juste et l’injuste ne résultent pas de la nature, mais de la loi
Le juste milieu
Le juste milieu est le meilleur
Le laboureur du vin souvent boit eau
Le laboureur est du métier d’Adam
Le lait deviendra fromage
Le lait fait sortir les cornes des chevreaux
Le lait ne sort pas des os mais de la nourriture
Le langard (bavard) cèle ce qu’il ignore
Le lard et le navet font le potage bon
Le larron de l’année passée est celui qui fait prendre ceux de la présente année
Le lendemain s’instruit aux leçons de la veille
Le levain d’orge ne peut être levain de froment
Le lien ne fait pas le fagot
Le lierre meurt où il s’attache
Le lieu fait l’homme tel qu’il est
Le lieu ni l’habit ne peuvent illustrer l’homme
Le linceul n’a pas de poches
Le lion et l’aigle font leurs petits parfaits et en certain nombre
Le lion qui tue ne rugit pas
Le lit chaud fait manger la soupe froide
Le lit dur fait la taille droite
Le lit d’un célibataire est le plus confortable
Le lit est fait pour dormir
Le lit est l’écharpe de la jambe
Le lit est médecin
Le lit est une bonne chose, qui ne peut dormir il repose
Le lit est une prison d’un paresseux
Le lit guérit tout
Le lit épuise
Le livre fait vivre
Le lièvre retourne toujours au lancer
Le logis du menteur a brûlé, mais personne ne l’a cru
Le loin porter souvent ennuie
Le loisir est le meilleur des biens
Le long couteau ne fait pas le gueux
Le long jour ne fait pas l’ouvrage
Le loup alla à Rome et y laissa de son poil et rien de ses coutumes
Le loup est fort dans sa tannière
Le loup est le gardien des brebis
Le loup et le chien s’accordent aux dépens de la chèvre qu’ils mangent ensemble
Le loup le plus maudit a le poil le plus luisant
Le loup mange celui qui se fait mouton
Le loup mange de toute sorte de chair, fors de la sienne
Le loup mourra en sa peau, qui ne l’écorchera vif
Le loup ne croit tenir que ce qu’il sent à la gorge en l’avalant
Le loup peut changer de peau, non de naturel
Le loyal riche et gracieux, est bienvenu en chacuns lieux
Le lundi, tout va à reculons
Le luxe, c’est l’art des imbéciles
Le lâche craint la mort, et c’est tout ce qu’il craint
Le lâche insulte, il n’attaque pas
Le lécher est friand mais n’est pas bienséant
Le mal advient à celui qui mal songe
Le mal arrive à cheval et se retire à pied
Le mal caché est le plus grave
Le mal des personnes, les bêtes ne le ressentent pas
Le mal du doigt porte au cœur
Le mal d’autrui n’est que songe
Le mal d’un doigt au corps se met
Le mal est facile, le bien demande beaucoup d’efforts
Le mal est pour celui qui le cherche
Le mal gravit et pullule toujours
Le mal joli (accouchement) dès qu’il est passé on en rit
Le mal ne se fait pas prier pour venir
Le mal n’est pas tout d’une rangée
Le mal paraît un jeu à l’insensé
Le mal passé cause grande joie
Le mal qui l’homme intimide en fin le tue et homicide
Le mal se châtie par autre mal et le bien se doit reconnaître par bénéfice
Le mal se rit de la pommade
Le mal soi-même, il y a pas besoin d’enseigner
Le mal s’apprend plus vite que le bien
Le mal tourne mal
Le mal va toujours en augmentant
Le mal vient bien seul sans l’aller prier
Le mal vient à cheval et le bonheur à pied
Le mal vient à cheval et retourne boiteux et contre-val
Le mal vient à cheval et s’en reva à pied
Le mal vient à cheval mais (re)tourne à pied
Le mal vient à l’improviste, quand on le croit loin il est près
Le mal à la tête a sa source au ventre
Le malade a liberté de tout dire
Le malade n’est pas à plaindre, qui a la guérison en sa manche
Le malade porte son état inscrit sur sa figure
Le maladif voit souvent mourir avant lui le jeune
Le malheur des guerres civiles est que l’on y fait souvent des fautes par bonne conduite
Le malheur des uns fait le bonheur des autres
Le malheur extrême est au-dessus des lois
Le malheur finit par se lasser; les vents ne soufflent pas toujours avec la même violence
Le malheur ne choisit pas toujours la porte où il frappe
Le malheur ne distingue pas et, dans sa course errante, il se pose aujourd’hui sur l’un et demain sur l’autre
Le malheur n’a pas d’amis
Le malheur peut être un pas vers le bonheur
Le malheur vient à cheval et s’en retourne à pied
Le malheureux est chose sacrée
Le malheureux n’a point d’autre ami que sa bourse
Le malin est mieux avisé que le sage
Le manger beaucoup et le beaucoup boire m’a réduit à la pauvreté
Le manger fait réveiller le boire
Le manque de goût et la superfluité des paroles sont le lot commun des hommes
Le manque de soin se paye
Le manteau des jeunes filles fait murmurer les voisines
Le mari fait perdre le deuil à sa femme, mais non la femme au mari
Le mariage convertirait un loup
Le mariage des esprits est plus grand que celui des corps
Le mariage d’amour et le repentir sont de la même année
Le mariage d’un jour vaut mieux que celui d’un an
Le mariage en impromptu étonne l’innocence, mais ne l’afflige pas
Le mariage entre parents, courte vie et longs tourments
Le mariage est comme le melon, c’est une question de chance
Le mariage est comme une nasse d’anguilles; ceux qui sont dehors veulent y entrer, ceux qui sont dedans veulent en sortir
Le mariage est comme une place assiégée; ceux qui sont dehors veulent y entrer et ceux qui sont dedans veulent en sortir
Le mariage est la corde au cou donné à tirer à l’amour qui attache l’homme à la femme
Le mariage est la traduction en prose du poème de l’amour
Le mariage est sujet à de grandes révolutions
Le mariage est toujours le tombeau de l’amour
Le mariage est un mal, mais c’est un mal nécessaire
Le mariage est un état trop parfait pour l’imperfection d’un homme
Le mariage est une cage où l’on prend les godelureaux
Le mariage est une loterie
Le mariage est une loterie
Le mariage et le célibat ont tous les deux des inconvénients ; il faut préférer celui dont les inconvénients ne sont pas sans remède
Le mariage et le macaroni ne sont bons que chaud
Le mariage fait par amourettes, et le repentir, naissent tous deux en une même année
Le mariage lointain appelle la petite maison un château
Le mariage, c’est une rosse de nœud qui se peut pas défaire
Le maréchal pour augmenter son feu le fait d’eau arroser
Le maréchal pour son feu augmenter le vient à la fois d’eau froide arroser
Le mauvais couteau coupe le doigt et non le bois
Le mauvais de son malheur, est propre cause et auteur
Le mauvais dessein est surtout mauvais pour celui qui l’a conçu
Le mauvais et pervers va toujours de travers
Le mauvais foin saigne les chevaux, tond les moutons et tarit les vaches
Le mauvais goût mène au crime
Le mauvais médecin arrive à cheval et s’en retourne à pied
Le mauvais souhait est surtout mauvais pour celui qui l’a formé
Le maître absent, la maison est morte
Le maître accommodant fait le serviteur négligent
Le maître doit faire honneur à sa maison, et non la maison au maître
Le maître enseignant son jouvenceau, doit tenir la règle de l’oiseau
Le maître est bientôt oublié, qui à ses gens n’a rien laissé
Le maître peine autant que l’élève
Le maître qui redoute son serviteur devient son esclave
Le maître se peut coucher où il veut
Le maître venu on apprête le souper
Le meilleur fromage a des vers
Le meilleur gouvernement est celui où l’on n’obéit qu’aux lois
Le meilleur jeu, c’est celui qui dure le moins
Le meilleur moyen de se défaire d’un ennemi est d’en faire un ami
Le meilleur médecin est la marmite
Le meilleur médecin est le pot-au-feu
Le meilleur médecin est le potage
Le meilleur médecin est le toupin
Le meilleur pain et salutaire est le sué pour ordinaire
Le melon est de l’or le matin, de l’argent l’après-midi et le soir il tue
Le melon et le mariage, question de chance
Le mensonge donne des fleurs mais pas des fruits
Le mensonge ne vieillit pas
Le mensonge n’a qu’une jambe, la vérité en a deux
Le mensonge n’est bon à rien, puisqu’il ne trompe qu’une fois
Le mensonge qui fait du bien vaut mieux que la vérité qui fait du mal
Le menteur a privilège et grâce de dire vérité par disgrâce
Le menteur disant la vérité, n’a crédit ni autorité
Le menteur doit avoir bonne mémoire
Le menu peuple a nécessairement besoin de l’appui d’un bon seigneur
Le mercenaire, voyant venir le loup, abandonne les brebis et se sauve
Le meurtrier est toujours l’autre
Le miel est amer à celui qui a mal à la bouche
Le miel lui-même peut dégoûter
Le mieux est l’ennemi du bien
Le mieux vêtu devers le feu, dos au feu, panse à table
Le milieu en toute chose est tenu le meilleur
Le milieu est le meilleur
Le miroir porte en soi l’image laquelle il ne voit
Le moi est haïssable
Le moine qui trouva la poudre à canon voulait miner enfer
Le moine répond comme l’abbé chante
Le moine, la nonne et la béguine sont fort pirs que n’en ont la mine
Le moins en faire est le plus sûr
Le mois de février est bon agnelier
Le mois de février est le mois où les femmes elles parlent le moins de tout l’an
Le mois de février, c’est le mois où les femmes disent le moins de mensonges
Le mois de novembre est malsain, il fait tousser dès la Toussaint
Le mois d’octobre glacé fait vermine trépasser
Le monde appartient à ceux qui se lèvent tôt
Le monde est bossu quand il se baisse
Le monde est du côté de celui qui est debout
Le monde est rond; qui ne sait nager va au fond
Le monde est un grand bal où chacun est masqué
Le monde est un spectacle à regarder et non un problème à résoudre
Le monde est un théâtre où les pires gens ont les meilleurs places
Le monde est un vaste temple dédié à la Discorde
Le monde est une grosse bête
Le monde est une meule
Le monde est une pièce de théâtre; il faut apprendre à jouer son rôle
Le monde est une sphère dont le centre est partout, la circonférence nulle part
Le monde parle, l’eau coule, le vent souffle et l’âge s’écoule
Le monde ressemble la mer, on y voit noyer ceux qui ne savent pas nager
Le monde récompense plus souvent les apparences du mérite que le mérite même
Le monde va toujours en empirant
Le moraliste ajoute : Ce n’est point un grand avantage d’avoir l’esprit vif, si on le l’a juste
Le mort ni le prisonnier n’a plus ni ami ni parent
Le mort n’a plus d’amis
Le mort n’a point d’ami, le malade n’en a qu’un demi
Le mort n’a point d’ami, le malade n’en a qu’à demi
Le mort à la fosse, les vivants à la saoulée
Le mortier sent toujours les aulx
Le moulin est bon tandis que la meule se remue et non tandis qu’elle ne bouge
Le moulin ne meult pas avec l’eau tombée en bas
Le musicien est magicien
Le méchant culbute dans sa propre malice
Le méchant est comme les mouches qui ne s’arrêtent qu’aux plaies
Le méchant est mieux avisé que l’homme de bien
Le méchef, l’homme avisé conseille
Le médecin doit être dur pour les malades comme le maître pour ses disciples
Le médecin est demi-prêtre
Le médecin est le ménestrier du corps et de l’âme
Le médecin est plus à craindre que la maladie
Le médecin n’a point de repos s’il n’est à cheval
Le médecin piteux rend l’homme boiteux
Le médecin pleure au temps des cerises et rit au temps des prunes
Le médecin tire à l’écu, mais l’avocat le prend
Le médecin vaut beaucoup d’autres hommes
Le médiocre est l’excellent pour les médiocres
Le médisant connaît tout le monde fors soi-même
Le ménage va bien mal quand la poule y fait le coq
Le ménage va mal quand la poule chante plus que le coq
Le ménage va mal quand la poule fait le coq
Le ménage va mal quand les poules chantent plus haut que le coq
Le mépris doit être le plus silencieux de nos sentiments
Le mépris est pour le sage plus pénible que les mauvais traitements
Le mérite se cache, il faut l’aller trouver
Le métier des armes fait moins de fortunes qu’il n’en détruit
Le métier n’en vaut rien, tout le monde s’en mêle
Le métier qui ne lasse point est le meilleur
Le même jour a vu naître le peuple des loups et celui des moutons
Le même soleil fait fondre la cire et séher l’argile
Le nain qui est sur l’épaule d’un géant voit plus loin que celui qui le porte
Le nain voit des géants partout
Le naturel de la grenouille est qu’elle boit et souvent gasouille
Le naufragé s’attache aux cordes du vent
Le navire craint plus le feu que l’eau
Le nerf de la guerre, c’est l’argent
Le nez coupé ensanglante la bouche ou le museau
Le nid des oiseaux est toujours altéré
Le noble est l’araignée et le paysan la mouche
Le nom d’ami est commun, mais rare l’amitié fidèle
Le noyer, l’âne, le connin et vilain, veulent être traités de rude main
Le nu ne peut revêtir autrui
Le onzième commandement
Le paiement comptant est toujours le meilleur marché
Le pain brûlé veut être chapelle et le souillé monde et bien lavé
Le pain dans sa patrie vaut encore mieux que des biscuits en pays étrangers
Le pain de maison ennuie
Le pain de noce ne dure pas
Le pain du mensonge est doux à l’homme, mais il laisse la bouche remplie de graviers
Le pain dur fait la maison sûre
Le pain d’autrui est amer
Le pain d’un gendre n’est jamais tendre, le pain d’une tante n’a rien qui tente
Le pain gagné profite à la santé
Le pain lève la faim, l’eau lève la soif
Le pain nourrit bien des sortes de gens
Le pain tombe toujours du côté qui est beurré
Le pain, faut le gagner
Le paon rend du riche vrai parangon
Le papier est comme les ânes, il porte tout
Le papier est doux, il endure tout
Le papier est un bon âne, il porte tout ce qu’on lui met dessus sans se plaindre
Le papier est un bon âne, on lui peut tout mettre dessus
Le papier se laisse écrire
Le papier souffre tout et ne rougit de rien
Le paradis n’existe pas, celui qui le veut doit le faire dans ce monde
Le pardon léger fait recommencer en péché
Le paresseux a froid en travaillant et chaud en mangeant
Le paresseux demande un oiseau, le courageux ne demande qu’un arc et des flèches
Le paresseux dit
Le paresseux est le frère du mendiant
Le paresseux est un voleur
Le paresseux et négligent, craignant la faim est diligent
Le paresseux fait toujours l’occupé
Le paresseux ne rôtit pas son gibier
Le paresseux se leva pour allumer le feu et il mit le feu à la maison et la brûla
Le parler doux et bénin est rarement sans venin
Le pas de l’âne a assez le temps
Le passé assure l’avenir
Le pater aux mains et le diable au sein
Le patient surpasse le héros et celui qui domine son âme l’emporte sur le guerrier qui prend des villes
Le pauvre a l’haleine mauvaise
Le pauvre a l’haleine puante
Le pauvre accepterait bien le rhumatisme du riche
Le pauvre donne afin qu’on lui redonne
Le pauvre enrichi méconnaît parent et ami
Le pauvre est odieux, même à son ami
Le pauvre ne peut, le riche ne veut
Le pauvre n’a point de parents
Le pauvre qui s’attacha à mendier à une seule porte mourut de faim
Le pays de la Chine est beau, mais faut pas y rester trop longtemps
Le pays fait l’homme tel qu’il est
Le paysan meurt de faim et son maître de gourmandise
Le penser ne coûte pas cher
Le petit arbre a sa place au soleil tout aussi que les grands sapins
Le petit de la chienne est chien
Le petit devient bien grand
Le petit gain emplit la bourse
Le peu donné en temps excuse un présent grand
Le peu parler est or et le trop vile est ord
Le peuple donne sa faveur, jamais sa confiance
Le peuple, le feu et l’eau sont des forces indomptables
Le pied dedans, le cul dehors
Le pied sec, la bouche fraîche
Le piment gratuit est plus doux que le sucre
Le pinson chante toujours la même chanson
Le pire châtiment d’une mauvaise action, c’est de l’avoir commise
Le pire de certaines haines, c’est qu’elles sont si viles et rampantes qu’il faut se baisser pour les combattre
Le pire des défauts est de les ignorer
Le pire diable chasse le moindre
Le pire diable est celui qui prie (Proverbe polonais))
Le pis de la vache du voisin est toujours plus grand
Le plaisir de trouver vaut mieux que ce qu’on trouve
Le plaisir des disputes, c’est de faire la paix
Le plaisir des grands est de pouvoir faire des heureux
Le plaisir est double lorsqu’il est fait promptement
Le plaisir est l’appât du mal
Le plaisir est plus grand qui vient sans qu’on y pense
Le plaisir et la gloire ne s’accordent jamais
Le plaisir le plus délicat est de faire celui d’autrui
Le plaisir n’est pas un mal en soi, mais certains plaisirs apportent plus de peine que de plaisir
Le plaisir peut s’appuyer sur l’illusion, mais le bonheur repose sur la réalité
Le plaisir retardé est un agréable tourment
Le plat du bas est toujours le premier vide
Le plat du bas est toujours vide
Le plus bel homme n’est pas toujours celui qui a la plus belle barbe
Le plus bref est le meilleur
Le plus court chemin est la ligne droite
Le plus court moyen de vaincre la tentation, c’est d’y succomber
Le plus dangereux ridicule des vieilles personnes qui ont été aimables, c’est d’oublier qu’elles ne le sont plus
Le plus de bruit vaut le moins d’argent
Le plus difficile n’est pas de faire des enfants, c’est de les nourrir
Le plus dégradant esclavage, c’est d’être l’esclave de soi-même
Le plus embarrassé est celui qui tient la queue de la casserole
Le plus fort le gagne
Le plus fort âne ne saurait toujours tirer au collier
Le plus fructueux de tous les arts, c’est l’art de bien vivre
Le plus grand est le premier pourri
Le plus grand orateur du monde, c’est le succès
Le plus grand service que l’on puisse attendre de la reconnaissance des méchants, c’est qu’à l’ingratitude ils n’ajoutent pas l’injustice
Le plus habile des financiers est celui qui a inventé le purgatoire
Le plus heureux n’est pas celui qui porte une belle chemise
Le plus lent à promettre est toujours le plus fidèle à tenir
Le plus lourd bagage pour un voyageur, c’est une bourse vide
Le plus ord fait-on le cuisinier
Le plus proche de l’église est le plus éloigné de l’autel
Le plus puissant est celui qui a la puissance sur soi-même
Le plus riche en mourant n’emporte qu’un linceul
Le plus riche est celui qui désire le moins
Le plus riche n’emporte que son linceul
Le plus riche n’emporte qu’un linceul
Le plus sage est celui qui ne pense point l’être
Le plus sage se tait
Le plus sage se tait par usage
Le plus souvent tout ce qu’on projette est emporté par un éboulement
Le plus souvent, c’est par une exception que l’on comprend ou admet un acquis inaperçu
Le plus sûr moyen de conserver la République est de ne rien faire en vue de l’intérêt particulier
Le plus sûr moyen de ruiner un pays est de donner le pouvoir aux démagogues
Le poisson aime l’eau, l’oiseau aime l’air et la bonne femme sa maison
Le poisson commence à pourrir par la tête
Le poisson dans le ventre ou au rivage doit toujours être à flot
Le poisson et l’hôte deviennent puants passé trois jours et les faut jeter hors de la maison
Le poisson n’engraisse pas
Le poisson pourrit par la tête
Le poisson qui naît dans l’eau doit mourir dans l’huile
Le poisson, le riz et le melon veulent le vin très fort
Le poisson, le riz et le piment demandent du vin très fort
Le poltron se dit prudent et l’avare économe
Le possible habite près du nécessaire
Le pot de loin est d’or, quand on y est c’est de la terre
Le pot de terre au pot d’airain, ensemble ne doit faire train
Le pot vide éclate sous le feu (Proverbe allemand) : Les pauvres sont plus sujets aux malheurs que les riches
Le poulain sauvage fait un bon cheval
Le poulain va volontiers l’amble, dont la mère fut hacquenée
Le pourceau affamé songe au gland
Le pourri cherche un maître qui lui donne sept dimanches la semaine
Le poussin bien couvé est à moitié élevé
Le poussin qui ne suit sa mère, bien souvent cher le compère
Le pouvoir de l’argent
Le pouvoir des nombres est d’autant plus respecté que l’on n’y comprend rien
Le pouvoir habite près de la nécessité
Le poète naît, l’orateur se fait
Le premier bien est la santé, le deuxième la beauté, le troisième la richesse
Le premier coup en vaut deux
Le premier coup fait la moitié du combat
Le premier degré de la folie est de se croire sage, et le second est de le proclamer
Le premier lien est celui des services
Le premier prend, le dernier part en grognant
Le premier pris en vaut deux
Le premier précepte d’un roi, c’est de savoir supporter la haine
Le premier qui chausse le pantalon gouverne la maison
Le premier sillon n’est pas le chantier
Le premier soupir de l’amour est le dernier de la sagesse
Le premier tour est le plus beau
Le prince n’est pas au-dessus des lois, mais les lois sont au-dessus du prince
Le prince qui n’aime point son peuple peut être un grand homme, mais il ne peut être un grand roi
Le prince, père ou maître, doit humainement et doucement admonester et non tuer le délinquant
Le prix de l’or règle la valeur des autres métaux
Le prix s’oublie, la qualité reste
Le prodigue est pire que l’avare, car il consomme non seulement son bien, mais celui d’autrui
Le profit de l’un est le dommage de l’autre
Le profit qu’un sage retire de la philosophie est de vivre en société avec lui-même
Le propre de la médiocrité est de se croire supérieur
Le propre de la pruderie, c’est de mettre d’autant plus de factionnaires que la forteresse est moins menacée
Le propre de la puissance est de protéger
Le propre des imbéciles est de détester tout ce qu’ils ignorent
Le propre du calomniateur est d’épier et d’être inquisiteur
Le propre du loup est (de) dévorer tout
Le propre du méchant ouvrier est faire état d’autrui métier
Le proverbe dit qu’il est des avocats payés pour dire des injures
Le prudent doit tout moyen chercher, avant les armes appréhender
Le prudent se fait du bien, le vertueux en fait aux autres
Le précepte est une lampe, la loi une lumière, et les avertissements qui instruisent sont le chemin de la vie
Le préjugé est fâcheux, parce qu’il exclut tout jugement
Le présent accouche de l’avenir
Le présent du gentilhomme est bientôt suivi de quelque demande
Le prêteur ne s’occupe pas des affaires minimes
Le public ne peut guère s’élever qu’à des idées basses
Le puissant foule aux pieds le faible qui menace
Le purgatoire est le dogme du bon sens
Le pute et méchant oiseau, s’aide de la langue pous couteau
Le pâté d’anguille lasse
Le père du juste est dans l’allégresse
Le père le plus sévère dans ses réprimandes est rude en paroles, mais il est père dans ses actions
Le père nourrit la fille et le voisin la marie
Le père trop gentil rend l’enfant trop hardi
Le péché pénètre entre la vente et l’achat
Le quotient intellectuel d’une foule est égal à celui du plus imbécile de ses membres
Le railleur est en abomination parmi les hommes
Le raisin noir est aussi bon que le blanc
Le raisonnement est aussi naturel à l’homme que le vol aux oiseaux
Le ramage tu l’oublies, le plumage tu t’en souviens
Le rat ne doit pas se moquer du chat ni la fille de l’amour
Le refus des louanges est un désir d’être loué deux fois
Le regard ment, le sourire est perfide, la parure ne trompe jamais
Le remarié et ce qui a été semé à nouveau ne vaut rien
Le remords précède la vertu comme l’aurore précède le jour
Le remède est pire que le mal
Le remède à l’habitude est l’habitude contraire
Le renard cache sa queue
Le renard change de poils, non d’esprit
Le renard ne chasse jamais près de sa tanière
Le renard qui attend que la poule tombe reste affamé
Le repentir est un jugement que l’on donne contre soi-même
Le repentir vient toujours quand c’est trop tard
Le repos et le repas revigore le corps et l’esprit las
Le rhumatisant a un almanac dans la tête
Le rhume est vaincu par la sudation
Le riche a la vengeance, et le pauvre a la mort
Le riche commet une injustice, et il frémit d’indignation; le pauvre est maltraité, et il demande pardon
Le riche est douillet
Le riche est un coquin ou le fils d’un coquin
Le riche et le pauvre sont tous deux pareils dans le cercueil
Le riche mange de l’or et chie du plomb
Le riche parle et tout le monde se tait
Le ridicule déshonore plus que le déshonneur
Le ridicule ne tue pas
Le rioteux n’a grain métier qu’on le chatouille
Le rire est une chose sérieuse avec laquelle il ne faut pas plaisanter
Le rire est une insulte au malheur
Le rire profond amène les larmes
Le ris et le caquet, pas ne duisent en banquet
Le ris, à moquerie est proche et déris
Le roi d’un peuple libre est seul un roi puissant
Le roi est homme comme un autre
Le roi ne dîne pas deux fois
Le roi n’est pas servi sans qu’il parle
Le roi perd son droit là où il n’y a que prendre
Le roi perd son droit, où n’y a que prendre
Le roi qui règne est toujours le plus grand
Le roi se trompe, le peuple paie
Le roman est l’histoire du présent, tandis que l’histoire est le roman du passé
Le roquet aboie quand il rencontre des inconnus, l’homme quelconque est choqué par la rencontre de la vertu
Le rossignol chante mieux dans la solitude des nuits qu’à la fenêtre des rois
Le rouge matin et le conseil féminin ne sont pas à croire
Le royaume de Dieu, ce n’est ni le manger ni le boire
Le râteau va bien avec la fourche
Le résultat justifie l’acte
Le sabat invite à l’ébat
Le sabbat a été fait pour l’homme, et non l’homme pour le sabbat
Le sablon va toujours au fond
Le sac de l’étranger est troué
Le sac est favorable à la pièce qui peut servir à le rapetasser
Le sac ne fut oncques si plein que n’y entrât bien un grain
Le sacrifice de soi est la condition de la vertu
Le sage a deux langues, l’une pour dire la vérité, l’autre pour dire ce qui est opportun
Le sage a ses yeux dans sa tête, mais le fou part à l’aveuglette
Le sage change d’avis et le sot s’entête
Le sage doit quitter la vie avec autant de décence qu’il se retire d’un festin
Le sage doit se fâcher assez tôt et une seule fois
Le sage guérit de l’ambition par l’ambition même
Le sage ne pense, dit et ne fait, ce qu’à Dieu n’agrée et ne plaît
Le sage n’affirme rien qu’il ne prouve
Le sage n’est pas sans souffrir de comprendre avec trop de sagesse
Le sage se conforme avec la vie de ses compagnons
Le sage se conforme à la vie de ses compagnons
Le sage se fait une gloire d’oublier les offenses
Le sage se régit par raison et le fol avec le bâton
Le sage sort le crabe du trou avec la main d’autrui
Le sage s’interroge lui-même, le sot interroge les autres
Le saint de la ville ne fait pas de miracles
Le saint de la ville n’est point adoré
Le saint qui ne guérit de rien n’a pas de pèlerins
Le salaire, selon le mercenaire
Le sang des martyrs est la semence des chrétiens
Le sang ne peut jamais failler
Le sang n’empêche pas de différer de rang
Le sang se lave dans le sang
Le sarclet veut aller du pair avec la bêche
Le savant est avare de mots
Le savoir qu’on ne complète pas tous les jours diminue
Le savoir vaut la force et même marche par-dessus
Le savoir-vivre est dans le monde plus obligé qu’observé
Le savoir-vivre vaut bien ce qu’il coûte
Le savon est gris et il lave blanc
Le scandale du monde est ce qui fait l’offense, et ce n’est pas pécher que pécher en silence
Le scandale est souvent pire que le péché
Le scepticisme est la carie de l’intelligence
Le scorpion pique celui qui l’aide à sortir du feu
Le secret de réussir c’est d’être adroit, non d’être utile
Le secret des arts est de corriger la nature
Le semer et la moisson, ont leur temps et leur saison
Le sens commun ne s’enseigne pas
Le sens commun, mais c’est justement le sens rare
Le sens de la mesure est un trésor
Le sentier de la vertu est âpre et ardu
Le sentier de vertu est unique et ardu
Le sentier de vertu est âpre et ardu
Le sermon édifie, l’exemple détruit
Le serpent est caché sous les fleurs
Le serpent rend l’homme prudent
Le service fait par vertu dure
Le serviteur doit avoir des oreilles de lièvres
Le serviteur prudent commandera au fils insensé, et il partagera l’héritage entre les frères
Le seul bien qui ne puisse nous être ravi est le plaisir d’avoir fait une bonne action
Le seul moyen d’obliger les hommes à dire du bien de nous, c’est d’en faire
Le seul secret que gardent les femmes, c’est celui qu’elle ignorent
Le silence est d’or
Le silence est la plus haute sagesse de l’homme
Le silence est l’esprit des sots, et l’une des vertus du sage
Le silence est l’âme des choses
Le silence est un aveu
Le silence tient lieu de sagesse au sot
Le singe est toujours singe, fût-il vêtu de pourpre
Le singe tant plus il monte en haut, tant plus il montre son cul
Le soc de la charrue s’use au poids de la terre
Le soir achève la journée, et la mort notre destinée
Le soir de la vie apporte avec soi sa lampe
Le soir loue l’ouvrier et le matin l’hôtelier
Le sol riche produit aussi de mauvaises herbes
Le soldat doit avoir assaut de lévrier, fuite de loup, défense de sanglier
Le soldat est aux gages de la mort; il va se faire tuer pour vivre
Le soleil de mars donne des rhumes tenaces
Le soleil de mars donne la fièvre
Le soleil de mars met les enfants au tombeau
Le soleil est le fourneau des pauvres
Le soleil est l’œil du firmament
Le soleil est passé sur votre toit, jamais il ne reviendra
Le soleil est souvent obscurci par les nuages et la raison par la passion
Le soleil fait sortir le médecin
Le soleil luit pour tout le monde
Le soleil ne chauffe que ce qu’il voit
Le soleil ne luit pas partout
Le soleil ni la mort ne se peuvent regarder fixement
Le soleil se lève pour tous
Le sommeil du laborieux est doux
Le sommeil est la moitié de la santé
Le sommeil est le frère jumeau de la mort
Le sommeil est le seul don gratuit qu’accordent les dieux
Le sommeil nourrit celui qui n’a pas de quoi manger
Le sort fait les parents, le choix fait les amis
Le sort sourit aux audacieux
Le sot a un grand avantage sur l’homme d’esprit, il est toujours content de lui-même
Le sot donne libre cours à tous ses emportements, mais le sage, en les réprimant, les calme
Le sot ne s’instruit que par les évènements
Le sot rit et pleure sans savoir pourquoi
Le sot varie comme la lune
Le soupçon d’un amant est le songe d’un homme éveillé
Le soupçon est pour les hommes estimables une injure silencieuse
Le sourire est un devoir social
Le souvenir des peines passées est agréable
Le souverain bien est d’être bien sain et en bonne couche
Le spectacle de la nature est toujours beau
Le spectacle du monde ressemble à celui des jeux Olympiques; les uns y tiennent boutique; d’autres paient de leur personne; d’autres se contentent de regarder
Le style est le vêtement de la pensée
Le style n’est rien, mais rien n’est sans le style
Le style, c’est l’homme
Le sublime n’est pas dispensé d’être raisonnable
Le subtil est subit épreint, et subit passé et éteint
Le succès des desseins des hommes est soumis à la volonté divine Variante (allusion sexuelle) : L’homme propose, la femme dispose
Le succès est aux yeux des hommes un dieu
Le succès fut toujours un enfant de l’audace
Le succès, c’est d’avoir ce que vous désirez Le bonheur, c’est d’aimer ce que vous avez
Le suffrage d’un sot fait plus de mal que sa critique
Le suicide est en général une lâcheté
Le superflu, chose très nécessaire
Le supérieur doit avoir suprême égard de montrer bon exemple à ses sujets
Le supérieur s’indigne de la concurrence de son inférieur
Le surplus rompt le couvercle
Le séducteur est le moins heureux parmi les méchants
Le tabac incommode à le prendre trop souvent
Le tablier sale met de la graisse au pot
Le tact est une qualité qui consiste à peindre les autres tels qu’ils se voient
Le tact, c’est le bon goût appliqué au maintien et à la conduite
Le talent est un don que Dieu nous a fait en secret et que nous révélons sans le savoir
Le talent ne prend pas feu des applaudissements
Le tamis dit à l’aiguille
Le tard venu est d’ordinaire mal couché
Le tavernier s’enivre bien de sa taverne
Le temps bien employé fait monter à cheval
Le temps c’est de l’argent
Le temps de la réflexion est une économie de temps
Le temps donne la santé et si l’ôte
Le temps dévore tout
Le temps est cher en amour comme en guerre
Le temps est comme l’argent, n’en perdez pas et vous en aurez assez
Le temps est la seule richesse dont on puisse être avare sans déshonneur
Le temps est le meilleur interprète de toute loi douteuse
Le temps est le meilleur sauveur des hommes justes
Le temps est le médecin de l’âme
Le temps est le plus sage de tous les conseillers
Le temps est tantôt une mère, tantôt une marâtre
Le temps est un grand maître, il règle bien des choses
Le temps est une lime qui travaille sans bruit
Le temps et l’usage rendent l’homme sage
Le temps et l’usage, rendent l’homme sage
Le temps et non la volonté met fin à l’amour
Le temps fuit comme un chat maigre
Le temps fuit sans retour
Le temps guérit les douleurs et les querelles
Le temps guérit tout
Le temps marche, il faut aller avec
Le temps met tout en lumière
Le temps mène les gens
Le temps mûrit toutes choses, par temps toutes choses viennent en évidence; le temps est père de vérité
Le temps ne s’arrête jamais et tout change perpétuellement dans le monde
Le temps n’a pas de loisir
Le temps n’est pas toujours en bonne disposition
Le temps n’épargne pas ce qu’on a fait sans lui
Le temps passe et la mort vient
Le temps perdu ne revient pas
Le temps perdu n’est jamais recouvert
Le temps révèle tout, c’est un bavard qui parle sans être interrogé
Le temps se change en bien peu d’heure, tel rit matin qui le soir pleure
Le temps s’en va légèrement, étudiez diligemment
Le temps trouble, méchants égaie et bons trouble
Le temps use l’erreur et polit la vérité
Le temps œuvre
Le temps, la fortune et le vent changent comme la lune
Le tempérant est celui qui est modéré dans ses désirs
Le terme vaut de l’argent
Le testament ne fait pas mourir le testateur
Le thé âpre est parfumé à la première tasse
Le titre ne fait pas le maître
Le ton fait la chanson
Le tonnerre d’avril annonce une bonne récolte
Le tort commun des malheureux est de ne jamais vouloir croire à ce qui leur est favorable
Le train est là où est la bourse
Le train mange le bien
Le traitement fait à parents, de tes enfants semblable attends
Le travail bien fait ne demande pas le temps qu’on lui a mis
Le travail c’est la santé
Le travail de la jeunesse fait le repos de la vieillesse
Le travail de l’esprit est le repos du cœur
Le travail est beau quand il est fait
Le travail est pour les hommes un trésor
Le travail est souvent le père du plaisir
Le travail fait de nuit, se fait connaître le jour
Le travail fait lentement est d’ordinaire beau
Le travail fait n’attend rien
Le travail ne vient pas des os mais des gros morceaux
Le travail n’a jamais fait un homme beau
Le travail payé par avance s’enfuit
Le travail que tu peux faire toi-même, ne le renvoie pas à d’autres
Le travail éloigne de nous trois grand maux
Le travail, le faudrait toujours faire deux fois
Le travailleur est tenté par un démon, l’oisif l’est par mille
Le triomphe des femmes est de nous faire adorer leurs défauts et jusqu’à leurs vices
Le triomphe des méchants est court
Le troisième jour de plaie, grande douleur
Le trop amène le trop peu
Le trop bien met à mal
Le trop changer empire
Le trop châtier ne fait qu’empirer
Le trop de confiance attire le danger
Le trop d’attention qu’on a pour le danger fait le plus souvent qu’on y tombe
Le trop et le trop peu, rompt la fête et le jeu
Le trop parler (me) mène à perdition
Le trop parler n’est pas marque d’esprit
Le trop passe la mesure
Le trop saouler en perd plus que la faim ou le jeûne
Le trop se gâte et le peu bâte
Le trot de l’âne dure peu
Le trot gâte le cheval
Le trou et l’occasion, invitent le larron
Le témoin véridique délivre des âmes
Le vaisseau le plus sûr est celui qui est à l’ancre
Le vaisseau peut périr pour avoir trop de pilotes
Le vaisseau se remplit goutte à goutte
Le valet du diable fait plus qu’on ne lui demande
Le veau flatteur tète deux mamelles
Le velours, les galons, la dentelle, refroidissent la marmite
Le venin des aspics est moins à craindre que la dissimulation de l’homme qui veut nuire
Le vent n’abat que ce qui ne tient pas
Le vent n’entre jamais en la maison d’un avocat
Le vent, la femme et la fortune sont changeants comme la lune
Le vent, la femme et la fortune tournent comme la lune
Le ventre de la femme est le tambourin des fols
Le ventre n’écoute pas de la raison
Le ventre plein fait du tumulte
Le ventre plein fait la tête vide
Le ventre plein, on conseille mieux
Le vertueux est citoyen de tout le monde
Le vertueux est semblable à Dieu et le vicieux aux brutes
Le veuve qui se remarie, veut s’emplumer de sa folie
Le viateur moins chargé va plus à son aise et assuré
Le viateur vide et nu, n’est dévalisé de nul
Le vice est caché par la richesse et la vertu par la pauvreté
Le vieil éléphant sait où trouver de l’eau
Le vieillard sait parce qu’il a vu et entendu
Le vieux chien n’aboie pas en vain
Le vif a peu d’amis et le mort n’en a point
Le villageois court au vin pour mettre à sa maladie fin
Le vin a deux défauts
Le vin de Bourgogne fait beaucoup de bien aux femmes, surtout quand ce sont les hommes qui le boivent
Le vin de Bourgogne pour les rois, le vin de Bordeaux pour les gentilshommes, le vin de Champagne pour les duchesses
Le vin doux, pour ordinaire, devient bien fort vinaigre
Le vin en fait faire de toute espèce
Le vin entre avec la douceur et sort avec amertume
Le vin est bon, à qui en prend par raison
Le vin est la nourriture de l’homme
Le vin est le lait des vieillards
Le vin est le lait des vieillards
Le vin est le lait des vieux, le lait est le vin des enfants
Le vin est le lait des vieux, les mouches elles-mêmes l’aiment
Le vin est le miroir des hommes
Le vin est nécessaire, Dieu ne le défend pas, sinon il eût fait la vendange amère
Le vin est un bon ouvrier mais un mauvais maître
Le vin est un bon valet mais un mauvais maître
Le vin et la folie sont d’un accord
Le vin fait de tous animaux à table
Le vin fait sauter les vieux
Le vin fini la soif tôt recommence
Le vin gâté est partout abhorré
Le vin ne connaît pas les convenances
Le vin noie les soucis
Le vin n’est pas bon qui ne réjouit son homme
Le vin n’est pas ouvrier
Le vin paye toujours son gîte
Le vin plaît bien qui ne coûte rien
Le vin pour boire, l’eau pour se raser
Le vin pour le corps, le rire pour l’âme
Le vin qui ne coûte rien est digéré avant qu’il soit bu
Le vin réjouit le cœur des hommes
Le vin répandu ne sera pas recueilli
Le vin se connaît à la saveur
Le vin sur le lait rend le cœur gai, le lait sur le vin rend le cœur chagrin
Le vin terrasse l’homme
Le vin tue les vers
Le vin vaut mieux que de l’eau
Le vin épargne le pain
Le vin, bu avec mesure, fortifie les faibles et pris outre mesure, il affaiblit les forts et les gaillards
Le vin, le jeu, les femmes, trois braves destructeurs
Le vinaigre trop acide ronge le vase qui le contient
Le vingt-et-un décembre, les femmes parlent moins que les autres jours, c’est le plus court de l’an
Le visage est le miroir du cœur
Le visage est l’image de l’âme
Le visible est à nous, le caché est à Dieu
Le voile des prudes n’est si épais que parce qu’il y a beaucoup à cacher
Le vrai honnête homme est celui qui ne se pique de rien
Le vrai moyen d’être trompé, c’est de se croire plus fin que les autres
Le vrai n’est pas plus sûr que le probable
Le vrai peut quelquefois n’est pas vraisemblable
Le vrai sage est celui qui apprend de tout le monde
Le vrai se découvre souvent par son contraire
Le vulgaire est de tous les états
Le véritable bienfaiteur va à de nouvelles œuvres comme la vigne qui donne chaque saison de nouveaux raisins
Le vêtement d’un homme, le rire de ses lèvres et sa démarche révèlent ce qu’il est
Le « politiquement correct » est la meilleure chose qu’on ait inventée pour permettre aux imbéciles de l’ouvrir et obliger les gens de bon-sens à la fermer
Lequel est le plus riche de tous? C’est celui qui se contente de ce qui lui faut justement
Les Pharisiens hypocrites filtrent le moustique et avalent le chameau
Les Vertus sont à pied et le Vice à cheval
Les absents ont toujours tort
Les absents sont assassinés à coups de langue
Les actes d’hier sont les conséquences d’aujourd’hui Voir aussi : Qui sème le vent récolte la tempête
Les actes font croire aux paroles
Les actions font mention
Les admonitions doivent être bénignes
Les affaires sont les affaires Traduction du proverbe anglais
Les affaires, c’est l’argent des autres
Les agneaux de l’automne sont toujours faibles
Les agneaux nés en hiver sont difficiles à élever
Les aigles ne s’amusent pas à prendre des mouches
Les aigles s’occupent pas à piquer des mouches
Les alouettes rôties ne tombent pas aval la cheminée
Les amis de mes amis sont mes amis, les ennemis de mes amis sont mes ennemis, les ennemis de mes ennemis sont mes amis
Les amis les plus dévoués sont comme les chiens les plus fidèles ils finissent par vous mordre si vous les maltraitez
Les amis sont des voleurs de temps
Les amis véritables se reconnaissent à l’épreuve du malheur
Les amitiés renouées demandent plus de soins que celles qui n’ont jamais été rompues
Les amours commencent par anneaux et finissent par couteaux
Les amours passent, les douleurs restent
Les amours qui s’accommodent par anneaux se finissent par couteaux
Les animalons admonestent les humains de se garder de choses vicieuses
Les animalons incitent les humains à prudence
Les animaux advisent les humains de cacher leur prospérité
Les animaux n’existent pas par eux-mêmes, mais pour servir
Les animaux n’ont pas ce qu’ils leur faut et si vivent
Les années font plus de vieux que de sages
Les années se suivent mais ne sont pas pareilles
Les années se suivent mais se ressemblent pas
Les ans apportent la mort
Les ans savent plus que les livres
Les ans se suivent et se ressemblent pas
Les ans sont faits pour les chevaux
Les apothicaires ne vendent pas de jeunesse
Les apparences sont trompeuses
Les apparences sont trompeuses
Les apprentis sont (pas) les maîtres
Les apprentis y sont maîtres
Les arbres attardés portent les meilleurs fruits
Les armes des ours, lions et tigres sont leurs dents, et médisants et des calomniateurs leur méchante langue
Les armes sont journalières
Les arts libéraux ne peuvent donner la vertu, mais ils disposent l’âme à la recevoir
Les aumônes ne sont pas toutes de pain
Les autres fois les affaires allaient et venaient, maintenant elles vont et viennent
Les avares sont comme les cochons, ils ne font de bien qu’après leur mort
Les avares sont comme les cochons, ils ne sont bons qu’après leur mort
Les avares sont comme les cochons, sont rien bons qu’après leur mort
Les avares sont comme les furoncles, ils amassent pour crever
Les avocats n’ont point de livre de droits
Les avocats n’ont point de paragraphe de fidélité
Les avocats n’ont que leurs lois
Les baisers d’un ennemi sont trompeurs
Les balais neufs balaient toujours bien
Les balais neufs balaient toujours bien, mais quand il n’y a plus d’aiguilles ils ne balaient plus
Les balais neufs vont toujours bien
Les battus payent l’amende
Les beaux chemins ne mènent pas bien loin
Les beaux esprits se rencontrent
Les beaux habits sont des cache-misères
Les beaux jours de janvier, trompent l’homme en février
Les beaux parleurs ne sont pas les beaux faiseurs
Les beaux parleurs sont les plus filous
Les beaux rideaux cachent souvent les vilains lits
Les belles femmes portent leur gain de cause
Les belles plumes font les beaux oiseaux
Les belles promesses font les fous joyeux
Les belles-mères ne lâchent pas les louches avec plaisir
Les bien fourrés les reins au feu, les mal vêtus le dos au vent
Les bien vêtus l’échine au feu, les mal vêtus le dos au vent
Les bienfaits s’écrivent sur le sable et les injures sur l’airain
Les biens et les maux qui nous arrivent ne nous touchent pas selon leur grandeur, mais selon notre sensibilité
Les biens mondains sont trésors volages et incertains
Les biens sont d’iceux qui en jouissent
Les biens s’écoulent comme l’eau de la rivière et l’amour reste à la maison
Les biens viennent les biens vont, l’amour ne nous quitte jamais
Les bijoux sont la dernière chose qu’on achète et la première qu’on vend
Les blagues les plus courtes sont toujours les meilleures
Les blagues les plus courtes sont toujours les moins longues
Les blessures d’un ami sont inspirées par la fidélité, mais les baisers d’un ennemi sont trompeurs
Les boiteux fuient et les menteurs s’attrapent
Les boiteux ont la rage de danser
Les bonnes belles-mères dansent toutes dans une émine
Les bonnes femmes font les bons hommes
Les bonnes femmes sont toutes au cimetière
Les bonnes idées se apparaissent plusieurs fois, on peut se congratuler mutuellement pour avoir la même idée Voir aussi : Les grands esprits se rencontrent
Les bonnes intentions peuvent amener le pire résultat Voir : effet pervers
Les bonnes lettres sont en haut prix et valeur en tout état et pays
Les bonnes mœurs portent de bons fruits
Les bonnes nouvelles sont toujours retardées, et les mauvaises ont des ailes
Les bonnes paroles sont un rayon de miel, douces à l’âme et salutaires au corps
Les bonnes régions sont toujours peuplées par les rosses
Les bonnes œuvres consolent l’âme
Les bons chevaux font les lieues courtes
Les bons chevaux s’échauffent en mangeant
Les bons chiens n’ont pas facilement les bons os
Les bons comptes font les bons amis
Les bons coqs sont maigres
Les bons coqs sont toujours maigres
Les bons livres font les bons clercs
Les bons maris ne sont pas les plus sains
Les bons maîtres font les bons domestiques
Les bons maîtres font les bons valets
Les bons morceaux ne profitent pas à chacun
Les bons ouvriers font les bons outils
Les bons ouvriers ont toujours de bons outils
Les bons ouvriers sont jamais trop chers
Les bons pâtissent pour les méchants
Les bons seront de Dieu reçus et les méchants seront extrus
Les bons subissent souvent les conséquences des fautes commises par les méchants
Les bons s’en vont, les mauvais restent
Les bons s’en vont, les mauvais restent, disait le vagabond qui avait volé une paire de souliers neufs
Les bons trayeurs gagnent leur vie dans la selle
Les bons valets font les bons maîtres et les bons maîtres font les bons valets
Les bramées passent, mais les coups cassent
Les braves gens sont aussi rares que les corbeaux blancs
Les brebis sont faites pour être tondues
Les brebis s’égarent quand le maître est absent
Les buissons parlent
Les bâtards ont neuf malices de plus que les autres
Les bêtes n’ont pas appris à mentir
Les bêtes sont au bon Dieu, mais la bêtise est à l’homme
Les bêtes sont comme on les fait
Les bêtes trouvent toujours meilleur celui des autres que le sien
Les cadeaux sont des hameçons
Les cailles rôties ne tomberont pas dans ton tablier
Les cancans se propagent comme la plume au vent
Les carottes font une belle peau
Les causes qui manquent de raison ont besoin de fortes paroles
Les censures d’un père sont un remède agréable, l’utilité en surpasse l’amertume
Les centimes bien comptés font les fortunes
Les centimes font les francs
Les chagrins qu’on se fait sont plus grands que ceux qu’on a
Les chambres vides font les sottes dames
Les chambrières de cabaret, les figuiers le long d’un chemin, sont exposées aux fréquentes visites des passants
Les champignons, mange-les très propres
Les chants les plus nouveaux sont les plus captivants
Les charités se font pas rien qu’en pain et en fromage
Les chats font des chats et les chiens des chiens
Les chats font les chats et puis ils apprennent à prendre les souris
Les chats font les chats, si ce n’est des gris c’est des noirs
Les chats ne font pas des chiens
Les chats ne font pas les rats
Les chats sans queue n’ont pas peur de montrer le cul
Les chemins sont plus grands à pied qu’à cheval
Les chemises des morts n’ont pas de poches
Les chevaux courent après les bénéfices et puis les ânes les attrapent
Les chevaux courent les bénéfices, les ânes les attrapent
Les chevaux et les poètes doivent être nourris, non engraissés
Les chevaux tirent toujours, si ce n’est pas au char c’est au râtelier
Les cheveux blancs marquent les années et non pas la sagesse
Les cheveux blancs sont pas plus pesants que les autres
Les cheveux blancs sont une couronne d’honneur, c’est dans les chemins de la justice qu’on la trouve
Les chiennes ressemblent à leurs maîtresses
Les chiens aboient contre les inconnus
Les chiens aboient, la caravane passe
Les chiens blancs deviennent enragés tout aussi bien que les noirs
Les chiens chassent de race
Les chiens et les sangliers n’ont pas la même odeur
Les chiens font comme ils peuvent, les maîtres comme ils veulent
Les chiens font des chiens et les chats des chats
Les chiens ne font pas des chats
Les chiens ne font pas les lièvres
Les chiens ne se mangent pas entre eux
Les chiens qui aboient ne mordent pas
Les chiens sans queue n’ont pas peur de montrer le cul
Les chiens se connaissent tous entre eux
Les chiens sont beaux aux champs
Les chiffons et les filles adhèrent de tous côtés
Les choses de ce monde sont belles dans leur temps
Les choses extrêmes sont comme si elles n’étaient point
Les choses les plus insignifiantes, réunies, prennent de l’importance Voir aussi: Petite charge pèse de loin Et : Au long aller petit faix pèse
Les choses les plus opposées ont des points de contact ou conduisent au même résultat
Les choses naturelles ne sont pas honteuses Naturalia non sunt turpia
Les choses ne valent que ce qu’on les fait valoir
Les choses où l’on a volonté, plus elles sont défendues et plus elles sont désirées
Les choses répétées plaisent
Les choses valent autant qu’on les fait valoir
Les chèvres semblent des demoiselles, quand on les regarde à la chandelle
Les chèvres s’attrappent par les cornes, les femmes par la langue
Les cimetières sont pleins de gens irremplaçables
Les cloches sonnent plus haut que les trompettes
Les cloches sont les trompettes des cimetières
Les colombes ne tombent pas toutes rôties
Les compagnons de voyage s’entrecommuniquent leurs pensées
Les compliments ne donnent rien à manger
Les compliments ne nourrissent personne
Les compliments ne rassasient que ceux qui les font
Les compliments sont le protocole des sots
Les conseilleurs ne sont pas les payeurs
Les conseils de la vieillesse éclairent sans échauffer, comme le soleil de l’hiver
Les conseils du vin n’ont jamais fait bonne fin
Les conséquences de la colère sont beaucoup plus graves que ses causes
Les contraires se guérissent par les contraires Contraria Contrariis curantur
Les contraires s’accordent et la discordance crée la plus belle harmonie
Les copeaux ne volent pas bien loin du tronc
Les copeaux restent toujours près du tronc
Les corbeaux entre eux ne se crèvent pas les yeux
Les corbeaux vont à la charogne
Les corbeaux-mêmes meurent de faim de promesses
Les cordonniers sont les plus mal chaussés
Les cornes comme les dents font souffrir pour pousser puis elles vous aident à manger
Les cornes ne viennent qu’à jeunes bêtes
Les corps sont sujets à la mutation du temps comme la girouette au vent
Les coups de bâton d’un dieu font honneur à qui les endure
Les coups de tonnerre épouvantent les enfants et les menaces font trembler les esprits faibles
Les couronnes (ne) prient pas pour celui qui est mort
Les couronnes ont souvent plus d’épines que de roses
Les courtes folies sont les meilleures
Les crimes secrets ont les dieux pour témoins
Les curieux viennent pas vieux
Les curés sont les charretiers des âmes
Les curés, il faut les respecter et pas s’en mêler
Les deniers font courir les chevaux
Les dentelles n’enrichissent personne
Les dents
Les derniers venus ferment les portes
Les derniers venus pleurent les premiers
Les derniers venus sont les maîtres
Les derniers venus sont les mieux aimés
Les derniers venus sont souvent les maîtres
Les dettes abrègent la vie
Les dettes réduisent l’homme libre en esclavage
Les dettes sont une épine dans la chair
Les deux plus tristes choses du monde
Les dieux aident ceux qui agissent
Les dieux ont donné un remède contre le venin des serpents, mais il n’y en a pas contre une femme méchante
Les dieux vengeurs suivent de près les arrogants
Les dignités accordées à un homme indigne sont comme une flétrissure
Les dits des vieux sont les dits des sages
Les dits discrets bien à temps dits, égaient et récréent les esprits
Les domestiques ne sont plus bons dès qu’ils veulent passer sur le maître
Les douleurs légères s’expriment; les grandes douleurs sont muettes
Les doux possèderont la terre
Les droits et les torts sont jamais de la même part
Les délicats sont malheureux, rien ne saurait les satisfaire
Les délices des grands sont les larmes des petits
Les désirs ne peuvent s’étendre à ce que l’on ne connaît pas
Les eaux douces font les plus grands ravages
Les eaux dérobées sont plus douces, et le pain du mystère est le plus suave
Les eaux en lieu étroit vont plus raidement
Les eaux tranquilles font des ravages quand elles sont dérangées
Les eaux troubles font les plus grands ravages
Les enfants dans leur simplicité, révèlent des vérités que l’on voulait cacher
Les enfants des autres puent
Les enfants des enfants sont la couronne des vieillards, et les pères sont la gloire de leurs enfants
Les enfants des joueurs sont à bonne raison enclins à pleurer et gémir
Les enfants et les fous disent la vérité
Les enfants et les insensés éparpillent les vérités
Les enfants font les pères et mères fols, mais quand ils sont grands il les font enrager
Les enfants gâtés savent bien faire obéir les leurs
Les enfants ont plus besoin de modèles que de critiques
Les enfants ont toujours un boyau vide
Les enfants ont toujours une tripe vide
Les enfants peut-être seraient plus chers à leurs parents et réciproquement les pères à leurs enfants, sans le titre d’héritiers
Les enfants qui se chamaillent bien, s’aiment ordinairement bien
Les enfants sans os (avortement) jettent les mères au tombeau
Les enfants sentent ceux qui les aiment
Les enfants sont comme l’eau, ils passent par toutes les fentes
Les enfants sont comme on les fait
Les enfants sont comme on les élève
Les enfants sont de chair qui bouge
Les enfants sont la pitance des pauvres gens
Les enfants sont la richesse des pauvres gens
Les enfants sont le fromage des pauvres gens
Les enfants sont les pères et mères fols, mais quand ils sont grands il les font enrager
Les enfants, c’est plus facile de les commander que de les élever
Les enfants, les fous et les cochons, se reconnaissent à leurs actions
Les ennemis de nos ennemis sont nos amis
Les entêtés vont dormir sans souper
Les envieux mourront, mais jamais l’envie
Les envieux, ingrats, irraisonnables valent moins qu’un méchant troupeau de diables
Les esprits médiocres condamnent d’ordinaire tout ce qui passe à leur portée
Les esprits originaux ont un sentiment naturel de leurs forces qui les rend entreprenants, même sans qu’ils s’en aperçoivent
Les extrémités se touchent
Les extrêmes sont toujours fâcheux ; mais ce sont des moyens sages quand ils sont nécessaires
Les faibles et les petits y restent pris; les puissants et les riches les déchirent et passent
Les faits parlent d’eux-mêmes
Les faits viennent tout seuls, malgré le silence dont on les cache
Les faubourgs sont plus grands que la ville
Les fautes des plus grands sont les plus scandaleuses
Les fautes du médecin, la terre les recouvre
Les faveurs des puissants vont à ceux qui les fréquentent
Les femmes avant de se marier arracheraient un chêne, une fois mariées c’est à peine si elles arracheraient une rave
Les femmes avant de se marier arracheraient un chêne, une fois qu’elles sont mariées c’est à peine si elles arracheraient une rave
Les femmes des autres sont toujours trop vêtues
Les femmes doivent être comme les fourneaux, toujours à la maison
Les femmes et le vin mettent la maison à l’envers
Les femmes et les imbéciles ne pardonnent jamais
Les femmes et les melons, on ne les connaît pas de loin
Les femmes et les serpents, on les attrappe dans le lit
Les femmes et les vieux bateaux, il y a toujours quelque chose à refaire
Les femmes fardées sont femmes le jour et guenons la nuit
Les femmes fenêtrières et les terres de frontières sont malaisées à garder
Les femmes font et défont les maisons
Les femmes font les maisons
Les femmes font ou défont les maisons
Les femmes ne disent la vérité que quand elles se trompent
Les femmes ne donnent à l’amitié que ce qu’elles empruntent à l’amour
Les femmes ne sont pas des maçons mais elles font et défont les maisons
Les femmes n’aiment que le rubis
Les femmes ont la langue bien pendue
Les femmes ont leurs jambes au col
Les femmes ont plus de honte de confesser une chose d’amour que de la faire
Les femmes ont, pour l’ordinaire, plus de vanité que de tempérament, et plus de tempérament que de vertu
Les femmes pardonnent parfois à celui qui brusque l’occasion, mais jamais à celui qui la manque
Les femmes porteraient le trouble dans un bateau de crucifix
Les femmes pourraient compenser un peu la perte de leurs charmes, en perfectionnant leur caractère
Les femmes préfèrent les hommes qui les prennent sans les comprendre, aux hommes qui les comprennent sans les prendre
Les femmes publiques offrent du miel et font boire du fiel
Les femmes rougissent d’entendre nommer ce qu’elles ne craignent aucunement de faire
Les femmes sont aussi dangereuses ennemies qu’elles sont faibles amies
Les femmes sont bonnes jusqu’à quarante ans
Les femmes sont comme les chevaux, il est malaisé de connaître les bonnes
Les femmes sont comme les chevaux, il faut leur parler avant de leur passer la bride
Les femmes sont comme les côtelettes, plus on les bat plus elles sont tendres
Les femmes sont comme l’homme les fait
Les femmes sont des saintes à l’église, des anges dans la rue, des diables au logis
Les femmes sont extrêmes; elles sont meilleures ou pires que les hommes
Les femmes sont plus chastes des oreilles que de tout le reste du corps
Les femmes sont plus folles que malades
Les femmes sont saintes à l’église, diables à la maison, singes au lit
Les femmes sont toujours meilleures l’année qui vient
Les femmes s’attachent aux hommes par les faveurs qu’elles leur accordent; les hommes guérissent par ces mêmes faveurs
Les femmes veulent toujours avoir le dernier mot
Les femmes vont plus loin en amour que la plupart des hommes, mais les hommes l’emportent sur elles en amitié
Les femmes à la maison comme les chats, et les hommes à la rue comme les chiens
Les femmes, c’est comme les balais, il n’en faut qu’un par cuisine
Les fesses de la femme ont des yeux
Les figues sont d’or le matin, d’argent à midi et le soir de plomb
Les figues, le matin sont d’or, à midi d’argent et le soir de plomb
Les filles aspirent toujours à descendre vers la plaine, les vaches à monter
Les filles de bons paysans, les fromages de pauvres gens, sont mûres avant d’être vieux
Les filles de bons paysans, les fromages des pauvres gens sont vite mûrs
Les filles de maintenant montrent le cul et cachent la tête
Les filles des riches et les veaux des pauvres sont vite placés
Les filles et la balayure ne peuvent être très loin de la maison
Les filles et les chevaux sont des ruine-maison
Les filles et les courges, plus on les garde moins elles valent
Les filles et les détritus ne pourraient être trop loin de la maison
Les filles et les feux veulent toujours qu’on pense à eux
Les filles et les huîtres feraient aux pierres faire du cidre
Les filles et les moutons ne doivent pas trop vieillir, ils perdent de la valeur
Les filles et les pommes est une même chose
Les filles et les épingles sont à ceux qui les trouvent
Les filles jusqu’à 25 ans choisissent ; après 25 ans, à qui en voudra
Les filles pleurent d’un, œil les femmes de deux, les nonnes de quatre
Les filles sont comme les chevaux, elles n’ont pas de maison
Les filles sont comme les prunes, quand elles sont mûres elles tombent
Les filles à marier sont pénibles à garder
Les filles, ce sont des vignes
Les filles, les lentilles et le pain chaud sont la ruine de la maison
Les fleurs sans fruit et sans odeur ne sont en prix ni en valeur
Les folies de carnaval se dévoilent pour la Toussaint
Les fols font les banquets aux sages
Les fossés doit remplir février et le mois de mars essuyer
Les fous et les sottes gens ne voient que leur humeur
Les fous inventent les modes, et les sages les suivent, mais de loin
Les fous ont leur manie, et nous avons la nôtre
Les fous sont aux échecs, les plus proches des rois
Les fripouilles s’entendent entre eux pour dépouiller quelqu’un
Les fruits défendus sont les meilleurs
Les fruits sont à tous, et la terre n’est à personne
Les fèves sont en fleurs
Les gains honteux ont perdu plus de gens qu’ils n’en ont sauvé
Les galants n’obsèdent jamais que quand on le veut bien
Les garçons ressemblent à leur mère et les filles à leur père
Les geais ont toujours mangé des cerises
Les gens de qualité savent tout sans avoir rien appris
Les gens du commun ne trouvent pas de différence entre les hommes
Les gens en place ne sont pas les plus méritants
Les gens heureux croient toujours avoir raison
Les gens le disent, les fous le croient
Les gens les plus forts sont charroyés les plus vite
Les gens médiocres arrivent à tout, parce qu’ils n’inquiètent personne
Les gens payent bien quand ils payent comptant
Les gens qui viennent en visite font toujours plaisir, si ce n’est en arrivant, c’est en partant
Les gens serviables sont plus rares que les corbeaux blancs
Les gens sont toujours gens de bien jusques ils soient pris au fait
Les gourmands creusent leur tombe avec leurs fourchettes
Les gourmands font leur fosse avec les dents
Les gouttes qui tombent sans cesse usent le rocher
Les grammairiens sont pour les auteurs ce qu’un luthier est pour un musicien
Les grandes douleurs sont muettes
Les grandes hacquenées ne font pas les grandes journées
Les grandes pensées viennent du cœur, et les grandes affections viennent de la raison
Les grands aiment pour le service et pour le profit
Les grands bœufs ne font pas les grandes arées
Les grands diseurs ne sont pas les grands faiseurs
Les grands esprits se rencontrent
Les grands et les vautours se déchirent entre eux
Les grands font ce qu’ils veulent et les petits ce qu’ils peuvent
Les grands font sans argent ce que les petits ne peuvent faire par argent
Les grands génies, pareils aux édifices élevés, veulent être vus à une juste distance
Les grands hommes le sont quelquefois jusque dans les petites choses
Les grands hommes ont la terre entière pour tombeau
Les grands hommes sont des météores destinés à brûler pour éclairer la terre
Les grands hommes sont plus grands que nous parce qu’ils ont la tête plus élevée, mais ils ont les pieds aussi bas que les nôtres
Les grands mangeurs et les grands dormeurs sont incapables de quelque chose de grand
Les grands mettent les petits à l’hameçon
Les grands ne pardonnent pas aux petits de les avoir sauvés
Les grands noms abaissent au lieu d’élever ceux qui ne les savent pas soutenir
Les grands n’aiment les petits que pour le service
Les grands n’estiment souvent qu’autant qu’on les encense
Les grands oiseaux sont toujours déplumés
Les grands poissons mangent les petits
Les grands présents font mourir le gourmand
Les grands vendent trop cher leur protection pour que l’on se croie obligé à aucune reconnaissance
Les grands voleurs chassent les petits
Les gros fumiers amènent les gros amis
Les gros mangent les petits
Les gros ne se mangent pas ensemble
Les gros ne se mangent pas entre eux
Les gros parleurs sont souvent des paresseux
Les gros poissons commencent à pourrir par la tête
Les gros poissons mangent les petits
Les gros prieurs sont les plus mauvais
Les gros sont plus sujets à mourir subitement que les maigres
Les gros tendent la malengère aux menus
Les gros écrasent les pauvres diables
Les grosses courtines amènent les grands amis
Les grosses courtines ne se font pas conscience de tromper et de profiter des petites gens
Les guenilles, les belles filles, trouvent toujours à se placer
Les généralisations hâtives sont le fait des enfants et des sauvages
Les habitants des frontières à laquelle on attribue certains défauts sont pires encore que ceux de l’intérieur
Les habits cachent bien de la misère
Les habits ne font pas l’homme
Les hommes cherchent fortune mais c’est aux filles de s’en garder
Les hommes communs sont nés pour les grands hommes
Les hommes deviennent bons en devenant vieux
Les hommes emploient leur capacité à bien, les femmes l’emploient à mal
Les hommes font la guerre et Dieu donne la victoire
Les hommes font les lois, les femmes font les mœurs
Les hommes guérissent souvent sans médecin mais non sans remède
Les hommes manquent plus de conquêtes par leur maladresse que par la vertu des femmes
Les hommes naissent bien dans l’égalité, mais ils n’y sauraient demeurer
Les hommes ne connaissent pas le monde, par la raison qui fait que les hannetons ne connaissent pas l’histoire naturelle
Les hommes ne croient jamais les autres capables de ce qu’ils ne sont pas capables de faire eux-mêmes (Cardinal de Retz) »
Les hommes ne vivraient pas longtemps en société, s’ils n’étaient les dupes les uns des autres
Les hommes n’aiment pas toujours ce qu’ils estiment, les femmes n’estiment que ce qu’elles aiment
Les hommes ont les maux qu’ils ont eux-mêmes choisis
Les hommes ont toujours raison et les femmes n’ont jamais tort
Les hommes ont été, sont et seront menés par les évènements
Les hommes peuvent fatiguer de leur constance, les femmes jamais
Les hommes proposent et Dieu dispose
Les hommes qui se remarient n’oublient jamais les bonnes grâces de leur première femme
Les hommes recouvrent leur diable du plus bel ange qu’ils peuvent trouver
Les hommes sans raison, le temps sans saison
Les hommes se délassent quelquefois d’une vertu par une autre vertu; ils se dégoûtent plus souvent d’un vice par un autre vice
Les hommes se rencontrent et les montagnes non
Les hommes semblent être nés pour faire des dupes, et l’être d’eux-mêmes
Les hommes sont comme les chiffres
Les hommes sont les roturiers du mensonge, les femmes en sont l’aristocratie
Les hommes sont plus avides d’éloges que jaloux de les mériter
Les hommes sont très vains, et ils ne haïssent rien tant que de passer pour tels
Les hommes voudraient que les femmes soient comme les almanachs, qu’elles changent tous les ans
Les hommes, c’est le mois d’avril quand ils vont à la veillée et le mois de décembre quand ils sont mariés
Les hommes, c’est tous les mêmes, c’est tous des porcs
Les hommes, les faut pas connaître pour les aimer
Les hommes, les faut prendre par l’estomac
Les hommes, on les apprend à connaître à l’usure
Les honneurs changent les mœurs
Les humains sont instruits des animaux brutes, voire des animalons, de mener une vie correcte et bien réglée
Les humains sont instruits des animaux, d’esquiver ce que leur est nuisible
Les humains sont instruits par les abeilles de faire leur profit des étranges contrées
Les humains sont instruits par les animalons de rendre obéissance à Dieu
Les humains sont instruits par les animaux de chercher remède à leurs passions et méhains
Les humains sont instruits par les brutes de subvenir à leurs progéniteurs
Les héros sont faits comme les autres hommes
Les hérétiques sont nécessaires Oportet haereses esse
Les ignorants attaquent une doctrine neuve et hardie, qu’ils sont dans l’incapacité de comprendre
Les inconvénients de l’abondance
Les inférieurs sont souvent d’accord avec leurs supérieurs
Les inimitiés qui ne sont pas bien fondées sont les plus opiniâtres
Les injures ne prouvent rien
Les injures que nous infligeons et celles que nous subissons se pèsent rarement à la même balance
Les injures sont les raisons de ceux qui ont tort
Les interprètes sont autant de traîtres Traduction du proverbe italien
Les jeunes brebis, elles lèchent le sel; les vieilles, elles rongent le sachet
Les jeunes filles d’aujourd’hui sont vite envolées
Les jeunes fous déprisent conseil vieil
Les jeunes gens, quand ils se marient, au plaisir ils pensent ; ils ne pensent pas qu’il faut avoir un berceau à balancer, pot de bouillie, farine de froment dans une boîte, sel blanc dans un tesson
Les jeunes mariés doivent manger seuls leur première miche de pain
Les jeunes mariés doivent toujours s’attendre à quelques guignons
Les jeunes médecins font les cimetières bossus
Les jeunes ont tous les droits et puis les vieillards tous les devoirs
Les jours ouvriers sont pour fournir deniers
Les jours se suivent et ne se ressemblent pas
Les jours se suivent mais se ressemblent pas
Les jours sont courts
Les jours s’ensuivent, mais ils ne sont pas semblables
Les justes éloges sont un parfum que l’on réserve pour embaumer les morts
Les larmes d’une femme cachent des embûches
Les larmes d’une femme servent d’épices à sa méchanceté
Les larmes sont l’éloquence des femmes
Les larmes valent mieux que le rire, car l’adversité améliore le cœur
Les larrons s’accordent à dérober et discordent à partiser
Les lentilles font venir le lait aux filles
Les liens du sang sont forts, quand s’y ajoute l’amitié
Les liens du sang sont indestructibles
Les lieues sont doubles en hiver
Les lieues sont plus grandes de nuit que de jour
Les livres ont leur destin
Les livres sont les monuments les plus durables
Les lois dorment souvent, mais ne meurent jamais
Les lois d’un État changent avec le temps
Les lois sont les esclaves de la coutume
Les lois sont semblables aux toiles d’araignées
Les lois sont toujours utiles à ceux qui possèdent et nuisibles à ceux qui n’ont rien
Les longs contes font les courts jours
Les longs contes font les jours courts
Les longs discours font les courts jours
Les longs détours font les courts jours
Les longs propos font les courts jours
Les louis d’or font à marier les culs tords
Les louis d’or marient les culs tords
Les loups ne font pas des agneaux
Les loups ne se mangent pas entre eux
Les loups ne se mangent pas entre eux
Les loups n’ont jamais fait des agneaux
Les lunettes et les cheveux gris sont des quittances d’amour
Les lunettes sont l’arquebuse de la mort
Les lèvres du juste nourrissent beaucoup d’hommes
Les lèvres menteuses sont en abomination devant le Seigneur
Les lèvres serrées annoncent le coquin ou l’avare
Les maigres mangent plus que les gras
Les maigres sont dangereux
Les mains crottées font manger le pain blanc
Les maisons des avocats sont faites de têtes de fols
Les maisons empêchent de voir la ville
Les maisons sont belles quand il y a de riches gens dedans
Les maisons tombent toutes en quenouilles
Les mal vêtus devers le vent
Les maladies de foie engraissent le médecin
Les maladies suspendent nos vertus et nos vices
Les maladies viennent par kilos et partent par onces
Les maladies viennent sans qu’on les cherche
Les maladies, on sait quand elles viennent, mais pas quand elles partent
Les malheureux ont toujours tort
Les malheureux se consolent en voyant plus malheureux qu’eux
Les malicieux ont l’âme petite, mais la vue perçante
Les manières, que l’on néglige comme de petites choses, sont souvent ce qui fait que les hommes décident de nous en bien ou en mal
Les marchands d’oignons connaissent les ciboulettes
Les mariages de loin ne sont que des tours et châteaux
Les mariages faits au loin ne sont que tours et châteaux
Les mariages vus de loin ne sont que tours et châteaux
Les mariages, il ne faut ni les faire ni les défaire
Les mariages, les partages, gâtent les bonnes maisons
Les mariés n’ont qu’un mois de bon temps
Les marques d’honneur asservissent les dieux et les hommes
Les mathématiciens étudient le soleil et la lune et oublient ce qu’ils ont sous les pieds
Les mathématiques rendent l’esprit juste en mathématiques, tandis que les lettres le rendent juste en morale
Les mathématiques sont une gymnastique de l’esprit et une préparation à la philosophie
Les mauvais bergers sont la ruine du troupeau
Les mauvais chiens aboient en se sauvant
Les mauvais couteaux coupent les doigts et laissent le bois
Les mauvais emprunteurs sont de mauvais prêteurs
Les mauvais ouvriers n’ont jamais de bons outils
Les mauvais ouvriers ont toujours de mauvais outils
Les mauvaises compagnies corrompent les bonnes mœurs
Les mauvaises femmes sont comme les chèvres, elles sont bien là où elles ne sont pas
Les mauvaises herbes se rensemencent toujours
Les mauvaises herbes, il n’y a pas besoin de les semer
Les mauvaises nouvelles ont des ailes
Les maux viennent assez tout seuls, n’a pas besoin de les appeler
Les maux viennent à cheval et s’en (re)tournent à pieds
Les maîtres aiment le service et non pas les serviteurs
Les maîtres commandent et puis les serviteurs exécutent
Les maîtres des forges sont brûlés comme leurs fourneaux
Les meilleures dents, c’est celles qui retiennent la langue
Les meilleurs champignons, jette-les au fumier
Les membres sont ordinairement de la nature du chef
Les mensonges de cet an, font vivre l’an qui vient
Les mensonges se montrent, la vérité reste cachée
Les mensonges se montrent, la vérité reste à l’ombre
Les mensonges vont sur une jambe, les vérités sur deux
Les menteurs ne gagnent qu’une chose, c’est de ne pas être crus, même lorsqu’ils disent la vérité
Les menteurs sont si tôt reconnus que les boiteux
Les mets friands sont causes de grands vices
Les meubles qui reluisent disent merci à la cuisinière
Les mieux nourris sont les mieux payés
Les mieux peux (repus) sont les mieux payés
Les mieux repus sont les mieux payés
Les mieux vêtus devers le feu
Les misanthropes sont honnêtes; c’est pour cela qu’ils sont misanthropes
Les misères de la vie enseignent l’art du silence
Les modes rendent les riches pauvres
Les moines sont dans leur couvent comme des rats dans une cloche à fromage
Les monuments les plus durables sont les monuments de papier
Les morts gouvernent les vivants
Les morts ne mordent pas
Les morts ne pouvant se défendre, on leur donne souvent tous les torts
Les morts ont toujours tort
Les morts sont toujours loués
Les morveux veulent moucher les autres
Les mots ne bâtissent pas de murs
Les moucherons mêmes sont fâcheux lorsqu’ils sont attroupés
Les murailles ont des oreilles
Les murailles parlent
Les murs ont des oreilles
Les musaraignes qui traversent la route crèvent
Les méchants sont comme la mer agitée qui ne peut se calmer
Les méchants sont les bourreaux du Seigneur Dieu
Les méchants sont toujours surpris de trouver de l’habileté dans les bons
Les médecins laissent mourir, les charlatans tuent
Les médecins ne peuvent pas empêcher à mourir
Les médiocres sont les plus éloquents en face de la foule
Les mémoires excellentes se joignent volontiers aux jugements débiles
Les neufs balais balaient toujours bien
Les nobles sont comme les livres Il en est beaucoup qui ne brillent que par leurs titres
Les noisettes sont plus dures que les noix
Les noisettes viennent toujours à ceux qui ne peuvent pas les casser
Les noix viennent toujours à ceux qui n’ont plus de dents pour les casser
Les noix, les filles, les châtaignes, leur robe cache le ver
Les occasions font les gens larrons
Les oies ont partout bon bec
Les oiseaux sont dénichés
Les oisons (oisillons) mènent les oies paître
Les opposés s’attirent
Les oreilles me sifflent, quelqu’un dit du mal de moi
Les oreilles ne sont pas pour parler
Les oreilles n’empêchent pas les ânes de porter le bât
Les orgueils blessés sont plus dangereux que les intérêts lésés
Les ouï-dire vont partout et les fous croient tout
Les pactes et l’accord rompent la loi
Les papiers portent tout et les fous croient tout
Les papiers sont comme les ânes, ils portent tout ce qu’on leur met dessus
Les parents doivent seuls être témoins des maux d’un parent
Les parents sont lieutenants et vice-régents de Notre Seigneur Dieu
Les parents élèvent souvent moindres qu’eux
Les paresseux ont toujours envie de faire quelque chose
Les paresseux sont souvent de gros mangeurs
Les paresseux trouvent toujours moyen de leur esquiver du travail
Les parois ont oreilles
Les parois sont papier aux fols
Les paroles de la vérité sont simples
Les paroles des sages ont des aiguillons et leurs recueils comme des clous plantés
Les paroles du soir ne ressemblent pas à celles du matin
Les paroles passent, les coups cassent
Les paroles rompent pas les os, mais font rompre
Les paroles sont des femelles et les écrits sont des males
Les paroles sont des femelles, les écrits sont des mâles
Les paroles sont des femmes, les écrits sont des hommes
Les paroles sont femelles et les actes sont mâles
Les paroles sont femmes et effets sont hommes
Les paroles sont les souffles de l’âme
Les paroles s’en vont, les écrits restent
Les paroles s’envolent, les écrits restent
Les partages gâtent les bonnes maisons
Les passions sont les seuls orateurs qui persuadent toujours
Les passons sont les vents qui enflent les voiles du navire; elles le submergent quelquefois, mais sans elles il ne pourrait voguer
Les pauvres gens font leur soupe avec de l’ail
Les pauvres gens ne devraient pas songer à engendrer des enfants pour les mettre dans la misère, mais ce sont précisement eux qui en ont le plus
Les pauvres gens n’ont pas de proches parents
Les pauvres gens n’ont que ce qu’ils choient
Les pauvres gens n’ont que peine et misère
Les pauvres gens sont toujours foutus, de quel côté ils se tournent
Les pauvres meurent de trop manger, les riches de faim
Les paysans ne sont pas assez savants pour raisonner de travers
Les peines sont bonnes avec du pain
Les peintres et les poètes ont toujours eu le droit de tout oser
Les perles ne se dissolvent pas dans la boue
Les personnes d’esprit ne sont jamais laides
Les personnes d’une santé délicate vivent plus que les autres parce qu’elles prennent plus de précautions
Les personnes qui ont des goûts et des intérêts opposés se complètent Voir aussi le proverbe opposé : Qui se ressemble s’assemble
Les personnes âgées en savent plus que les jeunes qui pensent à tort tout connaître sans expérience
Les petites bêtes font pas facilement du mal aux autres
Les petites rivières ne sont jamais grandes
Les petites roues portent les grand faix, les grands roues les petits faix
Les petites roues portent les grands faix
Les petits cadeaux entretiennent l’amitié
Les petits chevaux font autant d’ouvrage que les gros
Les petits chevaux font des petits poulains
Les petits oiseaux recherchent toujours leur nid
Les petits pots ont des oreilles
Les petits pots ont des oreilles et petites ruches des abeilles
Les petits pâtissent toujours des discordes des grands
Les petits ruisseaux font les grandes rivières
Les petits ruisseaux sont transparents parce qu’ils sont peu profonds
Les petits sont sujets aux lois et les grands en font à leur guise
Les petits travaillent autant que les grands
Les petits vont toujours vers le bas
Les pieds secs, la bouche fraîche
Les pierres parlent
Les pierres roulent toujours au gros murger
Les pierres roulent toujours au gros tas de pierres
Les pierres sont dures partout
Les pierres sont partout bien dures
Les pierres sont partout dures
Les pierres vont toujours au murger
Les pies font la cour en Carême et se marient à Pâques
Les places éminentes sont comme les rochers escarpés, où les aigles et les reptiles peuvent seuls parvenir
Les plaies de la conscience ne se cicatrisent pas
Les plaies fraîches sont les plus aisément remédiables
Les plaisirs sont où on les prend, disait celui qui baisait sa chèvre au cul
Les plantes instruisent les femmes d’avoir cure de leurs filles
Les pleurs ont aussi leur volupté
Les plumes font l’oiseau beau
Les plumes refont bien l’oiseau
Les plus accommodants, ce sont les plus habiles; on hasarde de perdre en voulant trop gagner
Les plus bons médecins sont le docteur gaieté, le docteur diète, et le docteur tranquillité
Les plus courtes erreurs sont toujours les meilleurs
Les plus courtes folies sont les meilleures
Les plus courtes folies sont toujours les meilleures
Les plus grands maux sont ceux qui viennent de la tête
Les plus hauts chênes n’ont pas les prix
Les plus riches en mourant n’emportent qu’un drap, non plus que les plus pauvres
Les plus riches sont souvent les plus chiches
Les plus rouges sont les premiers pris
Les plus sages faillent souvent en beau chemin
Les poires sont mûres, il faut les cueillir
Les poltrons fuient le danger, le danger fuit les braves
Les pommiers ne vieillissent point pour porter des pommes
Les pommiers sauvages ne donnent pas des pommes du mois d’août
Les portes de l’enfer sont ouvertes jour et nuit
Les postes éminentes rendent les grands hommes encore plus grands, et les petits hommes beaucoup plus petits
Les pots fêlés sont ceux qui durent le plus
Les poules auront des dents
Les poules donnent plus d’œufs quand elles sont bien nourries
Les poules et les femmes, les trop promener perd
Les poules pondent par le bec
Les poules pondent par le bec
Les poules qui chantent comme les coqs, les filles qui sifflent, les prêtres qui dansent, il faudrait leur tordre le cou
Les poules qui chantent et le filles qui sifflent, faut pas (les) laisser vivre
Les poules qui gloussent plus fort ne sont pas les meilleures pondeuses
Les poussins du mois d’avril sont toujours rabougris
Les poètes et les rois ne naissent pas chaque année
Les premiers billets doux sont lancés par les yeux
Les premiers morceaux nuisent aux derniers
Les premiers seront les derniers, et les derniers seront les premiers
Les premiers seront les derniers, les derniers seront les premiers
Les premiers sont toujours contents, les derniers vont en grognant
Les premiers vont devant
Les princes sont cause de gain et de perte
Les princes sont causes de perte et de gain
Les principes sont dans l’usage commun et devant les yeux de tout le monde
Les promesses tiennent les fous joyeux
Les propres condamnations sont toujours accrues, les louanges mescrues
Les préférences ont cela de bon qu’elles inspirent toujours un peu le désir de les mériter
Les préjugés sont la raison des sots
Les préjugés sont les rois du vulgaire
Les présents apaisent les dieux et persuadent les tyrans
Les présents brisent les rocs
Les présents brisent les rocs
Les présents d’un homme lui élargissent la voie
Les présents entrent partout sans marteau
Les présents valent mieux que les absents
Les présomptueux se présentent, les hommes d’un vrai mérite aiment à être requis
Les prêtres et les magistrats ne dépouillent jamais leur robe entièrement
Les puissants oppriment les faibles
Les puissants sont puissamment châtiés
Les pères gâtent leurs enfants par trop en endurer
Les pères ont mangé des raisins verts et les dents des enfants en ont été agacées
Les pédagogues doivent suivre la façon de faire de l’agriculteur
Les pédagogues sont instruits par la poule de ne courir ni tracasser
Les quatre fins de l’homme
Les quatre âges se passent sans savoir qu’on y passe
Les quatre éléments sont nécessaires aux corps vivants
Les querelles entre époux ne durent que de la table au lit
Les querelles ne dureraient pas si longtemps, si le tort n’était que d’un côté
Les raisons se laissent toutes dire
Les remords sont plus douloureux que les coups
Les remèdes d’apothicaires ne font pas toujours du bien au malade et font toujours mal à la bourse
Les reproches ne sont faits qu’à ceux que l’on estime
Les requêtes répondues, les présents cessent
Les riches ne peuvent acheter le privilège de mourir vieux
Les riches ne peuvent être bons, et s’ils ne sont pas bons, ils ne sont pas heureux
Les riches ont toutes les aisances
Les riches qui marient la canaille sont toujours mal vus
Les richesses de l’avare, comme le soleil couché, ne réjouissent pas les vivants
Les richesses démontrent la qualité de leurs maîtres et possesseurs
Les richesses qui ne sont pas dans l’âme ne nous appartiennent pas
Les risées viennent à mal
Les rivières les plus profondes sont les plus silencieuses
Les rivières ne se précipitent pas plus vite dans la mer que les hommes dans l’erreur
Les robes des femmes sont si longues et si bien tissues de dissimulation que l’on ne peut reconnaître ce qui est dessous
Les rois malaisément souffrent qu’on leur résiste
Les rois n’aiment rien tant qu’une prompte obéissance
Les rois sont auteurs de lois
Les roses tombent, les épines demeurent
Les royaumes sont heureux où les philosophes sont rois, et où les rois sont philosophes
Les ruisseaux sont de mauvais voisins
Les révolutions sont des temps où le pauvre n’est pas sûr de sa probité, le riche de sa fortune, et l’innocent de sa vie
Les sages apprennent plus des sots que les sots ne s’instruisent à l’exemple des sages
Les sages portent leurs cornes dans leur cœur, et les sots sur leur front
Les saints ne deviennent pas vieux
Les saints ne peuvent si Dieu ne veut
Les scrupules sont fils de l’orgueil le plus fin
Les scélérats croient que les honnêtes gens sont des méchants
Les semblables se guérissent par les semblables
Les sens abusent la raison par de fausses apparences
Les sentences sont les saillies des philosophes
Les serments d’amour ne comportent pas de sanction
Les serviteurs ne sont plus bons quand ils veulent passer à maître
Les soldats ont plus à craindre du général que de l’ennemi
Les sommets sont balayés par les vents
Les songes ne sont pas toujours vérifiés par l’évènement
Les sots font bâtir les maisons et les sages les achètent
Les sots font les banquets et les sages s’en gaudissent
Les sots sont punis et non les vicieux
Les soucis d’esprit empêchent de dormir
Les soucis ne laissent pas dormir
Les soucis sont de tristes coussins
Les sous ce n’est pas tout, mais c’est déjà quelque chose
Les sous font les sous
Les sous, les livres, les écus et les louis, sont le Bon Dieu de bien des gens
Les talents du soldat et ceux du général ne sont pas les mêmes
Les taupes qui traversent la route crèvent
Les temps sont durs, mais faut aller avec
Les terres fertiles font les esprits infertiles
Les toilettes des filles engloutissent la récolte
Les tonneaux vides et les sots font le plus de bruit
Les tours les plus hautes font les plus hautes chutes
Les tours sont l’ornement de la ville et les nefs sont celui de la mer, comme les enfants sont l’ornement de l’homme
Les tout fous et les tout fins (ne) se marient pas
Les traductions augmentent les fautes d’un ouvrage et en gâtent les beautés
Les travaux se comportent mieux, venant par lopins que par squadrons
Les trop longues promenades perdent les poules et les femmes
Les trop somptueux habillements sont de la chambre de famine truchement
Les trésors acquis par le crime ne profitent pas
Les témoins sont fort chers, et n’en a pas qui veut
Les ténèbres cachent l’évènement futur
Les uns en vivent dont les autres en meurent
Les uns font tant que les autres sont à dam
Les uns sont sains, les autres langoureux
Les vaches donnent du lait par la goule
Les vaches qui branlent la queue, c’est pas les plus qui ont du lait
Les vaches qui mangent des chardons font le lait très bon
Les vagabonds sont pestes ès cités
Les vents qui soufflent dans les hauteurs changent sans cesse
Les vers ont chié la soie
Les vertus devraient être sœurs, ainsi que les vices sont frères
Les vertus se perdent dans l’intérêt, comme les fleuves se perdent dans la mer
Les vertus sont des titres, les souffrances sont des droits
Les vices entrent dans la composition des vertus, comme les poisons entrent dans la composition des remèdes
Les vieillards aiment à donner de bons préceptes, pour se consoler de n’être plus en état de donner de mauvais exemples
Les vieillards sont comme les enfants, ils ont que ce qu’on leur fait
Les vieillards sont comme les enfants, ils ont que le chaud qu’on leur met
Les vieillards sont comme les vieux meubles, se remuent pas
Les vieux amis et les vieux écus sont les meilleurs
Les vieux bœufs ont les cornes dures
Les vieux chats aiment les jeunes souris
Les vieux chevaux savent bien lever le cul
Les vieux en savent plus que les jeunes
Les vieux fous sont plus fous que les jeunes
Les vieux habits ne durent pas
Les vieux meurent plus difficilement que les jeunes
Les vieux ont le cuir dur
Les vieux paillards grisonnent
Les vieux papillons n’ont qu’à mourir avant l’hiver
Les vieux serviteurs donnent de mauvais maîtres
Les vieux écus roulent aussi bien que les neufs
Les vignes et les femmes jolies sont difficiles à garder
Les vilains s’entretuent et les seigneurs s’embracent
Les vilains, quand ils ont fait un bouc, ils veulent mettre la corne qux autres gens
Les villageois vont à la besogne avant que d’être levé
Les visages souvent sont de doux imposteurs
Les visites font toujours plaisir, surtout quand elles s’en vont
Les vocations manquées déteignent sur toute l’existence
Les voleurs se croient que sont tous comme eux
Les voyages forment la jeunesse
Les voyous ne veulent pas ceux de leur sorte
Les vraies victoires sont celles que l’on remporte sans verser de sang
Les véritables conquérants sont ceux qui savent faire les lois ; les autres sont les torrents qui passent
Les vérités géométriques ne nous causent aucun sentiment de plaisir, ni aucune espérance
Les yeux aux sourds servent d’oreilles
Les yeux de l’homme ne sont jamais rassasiés
Les yeux et les oreilles sont de mauvais témoins pour les hommes, car ils ont une âme barbare
Les yeux ne se trompent pas, si la raison leur commande
Les yeux ont toujours faim de voir
Les yeux par tout le monde n’ont qu’un même langage
Les yeux parlent de l’amour
Les yeux sont aveugles lorsque l’esprit est ailleurs
Les yeux sont faits pour voir
Les yeux sont la cale de la fontaine
Les âmes fortes repoussent la volupté, comme les navigateurs évitent les écueils
Les ânes sont têtus, quand ils ne veulent pas avancer, on met une ânesse devant et ils courent après
Les ânes, les cordes et les femmes sont la perdition des âmes
Les écouteurs aux portes ne valent guère mieux que les voleurs
Les écouteurs ne valent pas mieux que les voleurs
Les écouteurs sont moindres que les voleurs
Les écouteurs sont pires que les voleurs
Les écouteurs valent pas mieux que les voleurs
Les écrits sont des mâles et les paroles des femelles
Les écrits sont des mâles, les paroles des femelles
Les écus de son père la feront trouver belle
Les écus ne font pas les mariages heureux, cependant ils aident un bon peu
Les écus valent mieux que les promesses
Les épines viennent avant les fleurs
Les états et honneurs font changer conditions et mœurs
Les étoupes arrière du feu et les jeunes une lieue du jeu
Les étourneaux sont maigres parce qu’ils vont en troupe
Les études deviennent des habitudes Abeunt studia in mores
Les études influent sur les mœurs
Les êtres sensibles ne sont pas des êtres sensés
Les œuvres de la violence ne sont pas durables
Les œuvres et faits de la jeunesse doivent apporter repos à la vieillesse
Les œuvres font la vertu, comme les arbres la forêt
Lever matin ne vieillit pas, donner aux pauvres n’appauvrit pas, prier Dieu ne retarde pas
Lever à six, dîner à six, souper à six, coucher à dix, font vivre l’homme dix fois dix
Liberté et pain cuit
Liberté vaut mieux que mondain avoir
Libre n’est celui qui sert autrui
Limaces et femmes à vendre, plus elles courent mieux elles se font prendre
Limaçons et femmes à vendre, plus ils courent mieux ils se font prendre
Linge fin n’est pas toujours le plus propre
Lire et rien entendre, est comme chasser et rien prendre
Lit chaud, froid dîner
Litiger est à l’avocat vendanger
Litière bien arrangée, bouvier de qualité
Loger le diable dans sa bourse
Loin de Jupiter, loin de la foudre Procul a Jove, procul à fulmine
Loin de l’œil, loin de cœur
Loin de son bien, proche de sa perte
Loin de son bien, près de sa perte
Loin de son bien, près de sa ruine
Loin de son bien, près de son dommage
Loin des yeux, loin du cœur
Loin le chat, les souris dansent
Long plaignant, long vivant
Long voyage, long mensonge
Longs cheveux, courtes idées
Longue attente met souvent en vente meilleur marché qu’on ne veut
Longue demeurée fait changer ami
Longue jouissance n’acquiert pas possession
Longue langue, courte main
Longue maladie lasse le médecin et le malade
Longue maladie, courte mort
Longue table et court sermon
Longuement procéder est à l’avocat vendanger
Longues amours, longues douleurs
Longues oreilles, oreilles d’âne
Longues raisons, grands mensonges
Lors même qu’une chose ne serait pas honteuse, elle semble l’être quand elle est louée par la multitude
Lorsque la faim est à la porte, l’amour s’en va par la fenêtre
Lorsque la jeune fille est mariée, on ne manque pas de gendres
Lorsque le malade est mort, on trouve assez de remèdes à lui faire
Lorsque le malade lâche des vents, le médecin peut s’en aller
Lorsque l’on veut changer les mœurs et les manières, il ne faut pas les changer par des lois
Lorsque mars est marécageux, le cimetière pêche
Lorsque notre haine est trop vive, elle nous met au-dessous de ceux que nous haïssons
Lorsque tu te maries, tu ne prends pas, tu es pris
Lorsqu’il tonne en avril, le vigneron se réjouit
Lorsqu’on est rompu, il fait bon passer par le lit
Louange humaine est chose vaine
Loue le champ qui est sis sur le coteau, mais acquiers pour toi celui qui est en plaine
Louer autrui puis blâmer, par usage d’être inconstant est signe et de peu sage
Louer les princes des vertus qu’ils n’ont pas, c’est leur dire impunément des injures
Louer maison à avocat, jamais louage n’en auras
Loup affamé nulle part a place
Lourde chatte, brave minou
Loyauté vaut mieux qu’argent
Lui enlever les moyens de gagner sa vie par son travail
Luxurieux, ord, sale et aveugle ne voit pas le danger où il est plongé
Là ou il y a abondance, il y a excroissance
Là où Dieu a son église, le diable a sa chapelle
Là où Dieu veut il pleut
Là où chat n’est, souris se réveillent
Là où est votre trésor, là aussi sera votre cœur
Là où force règne, droit n’y a lieu
Là où il a son bien, il a son cerveau
Là où il n’y a que prendre, le roi perd son droit
Là où il n’y a rien, le roi perd ses droits
Là où il y a amour, il y a souffrance
Là où il y a pas, on peut pas entamer
Là où il y a un bon os, il y a un bon chien
Là où il y a un coq, il ne faut pas que la poule chante
Là où la chèvre est attachée, il faut qu’elle broute
Là où le diable ne saurait aller, on envoie une vieille femme
Là où le soleil ne touche pas, n’allez pas élever de maison
Là où le soleil ne vient pas, bientôt le médecin viendra
Là où l’on est bien, là est la patrie
Là où nous avons mal, on nous heurte
Là où on parle du loup, on le rencontre
Là où on se chamaille bien, c’est la preuve qu’on s’aime bien
Là où pain faut tout est à vendre
Là où qu’il n’y a pas de mal, on ne met pas d’emplâtre
Là où raison faut, sens d’homme n’a métier
Là où tous puent, un seul sent à peine mauvais
Lâchez vos poules, les coqs arriveront bientôt
Lèche-moi, je te lécherai
Lève-toi bon matin et couche-toi de bonne heure
Lèvre gercée, froid glacial
Lèvre mince et nez pointu, n’ont jamais rien valu
Lèvre pincée, cœur fermé
Lèvre pincée, hautain
Lèvre pincée, mortifiée
Lèvre pointue, têtu
Lèvre retroussée, esprit fermé
Lèvre riante, gracieux
Lèvre violette, la mort à côté
L’Italienne ne croit être aimée de son amant que quand il est capable de commettre un crime pour elle; l’Anglaise, une folie; la française, une sottise
L’abandon fait le larron
L’abattu veut toujours luire
L’abbé doit être un miroir
L’abbé ne vit que tant qu’il plaît aux moines
L’abeille est honorée parce qu’elle travaille non pour elle seule, mais pour tous
L’abeille est petite, mais son miel est la plus douce des douceurs
L’ablatif est un cas disolatif et le datif est partout optatif
L’aboi d’un viel chien doit-on croire
L’abondance des choses engendre ennui
L’abondance engendre la nausée
L’abondance satisfait l’appétit
L’absence diminue les médiocres passions et augmente les grandes, comme le vent éteint les bougies et allume le feu
L’absence d’un mois de mari sont cent ans à une femme de bien
L’absence d’une personne aimée diminue peu à peu l’amour qu’on lui porte
L’absence est le plus grand des maux
L’absent ne sera pas héritier
L’abus n’abolit pas l’usage
L’abuseur sera abusé
L’accessoire suit la nature du principal
L’accoutumance de mal faire, rend l’homme cruel comme une bête
L’accusé innocent craint la Fortune et non pas les témoins
L’acte apparent prouve l’intention secrète
L’adresse est faible en face de la nécessité
L’adulateur empoisonne les cœurs humains
L’adulateur est des humains empoisonneur
L’adulateur est vrai vorateur
L’adversité découvre du courage la qualité
L’adversité finit par atteindre celui qu’elle a parfois frôlé
L’affaire va mal quand la poule approche le coq
L’affection ou la haine change la justice de face
L’affirmation et l’opiniâtreté sont signes exprès de bêtise
L’affliction pour femme morte dure jusqu’à la porte
L’affliction pour une femme morte ne dure que jusqu’à la porte
L’agasse , c’est un bel oiseau, mais quand on le voit trop souvent il fatigue
L’agasse est un bel oiseau, mais trop chanter ennuie
L’agneau qui bêle perd une goulée, la chèvre broute dans ce temps
L’agneau qui se confesse au loup est fou
L’agneau sous la peau d’un renard a encore peur du loup
L’aigle d’une maison n’est qu’un sot dans une autre
L’aigle ne chasse point aux mouches
L’aigle ne prend pas des mouches
L’aigle n’engendre pas la colombe
L’aigle seul a le droit de fixer le soleil
L’aigle, quand il est malheureux, appelle le hibou son frère
L’aiguille habille tout le monde et demeure elle-même toute nue
L’ail chasse les microbes
L’ail cru et le vin pur rendent la mort sûre
L’ail est l’épice du paysan
L’aimable répréhension sert au pécheur de guérison
L’air du matin vaut de l’or
L’air ne fais pas la chanson
L’allaitement flétrit les femmes et l’accouchement les rétablit
L’amant ne connaît que son désir, il ne voit pas ce qu’il prend
L’amant sans fortune peut être aimable, mais il ne peut être heureux
L’ambitieux est parangonné au paon
L’ambition est un vice qui peut engendrer la vertu
L’ambition ne vieillit pas
L’ami aime en tout temps, et dans l’adversité il devient un frère
L’ami de tout le monde n’est l’ami de personne
L’ami de tout le monde n’est l’ami de personne
L’ami est quelquefois plus proche qu’un frère
L’ami le plus dévoué se tait sur ce qu’il ignore
L’ami qui souffre seul fait une injure à l’autre
L’ami vieux et le compte récent sont les meilleurs de tous
L’ami véritable est l’ami des heures difficiles
L’amitié de deux frères est plus solide qu’un rempart
L’amitié d’un grand homme est un bienfait des dieux
L’amitié est comme une terre où l’on sème
L’amitié est le mariage de l’âme, et ce mariage est sujet à divorce
L’amitié est toujours profitable, l’amour est parfois nuisible
L’amitié est une égalité harmonieuse
L’amitié fait tout plan, l’argent fait tout
L’amitié se doit entretenir
L’amitié, c’est un parapluie qui s’enverse quand il fait méchant temps
L’amorce est ce qui (en)gagne le poisson et non la ligne
L’amour a besoin des yeux, comme la pensée a besoin de la mémoire
L’amour arrive sur la pointe des pieds et repart en claquant la porte
L’amour avidement croit tout ce qu’il souhaite
L’amour chasse jalousie
L’amour comme la goutte, on ne sait où ils se cachent
L’amour commence par l’anneau et finit par le couteau
L’amour de la justice n’est pour la plupart des hommes que la crainte de souffrir l’injustice
L’amour de la patrie est plus fort que toutes les raisons du monde
L’amour de l’art n’a jamais enrichi personne
L’amour des enfants n’est pas équivalent à l’amour des parents
L’amour d’un gendre est aussi chaud que la cendre
L’amour d’une jeune fille, c’est un feu de paille, il n’en reste ni charbon ni braise
L’amour d’une mère est toujours dans son printemps
L’amour d’une mère ne vieillit pas
L’amour embourbe les jeunes et noie les vieux
L’amour est aveugle
L’amour est aveugle et rend aveugle
L’amour est comme la lance d’Achille, qui blesse et guérit
L’amour est comme la mort, s’il n’entre point par la petite porte, il entre par la petite fenêtre
L’amour est fort comme la mort
L’amour est l’histoire de la vie des femmes, c’est un épisode dans celle des hommes
L’amour est l’étoffe de la nature que l’imagination a brodée
L’amour est mêlé de miel et de fiel
L’amour est nu, mais masqué
L’amour est souvent un fruit du mariage
L’amour est un tyran qui n’épargne personne
L’amour est une herbe amère
L’amour est à la portée de tous, mais l’amitié est l’épreuve du cœur
L’amour et la gale, on ne sait où ils commencent
L’amour et la goutte, on ne sait où ils se mettent
L’amour et la teigne s’attaquent à tous sans distinction
L’amour et la toux ne se cachent pas
L’amour et la toux ne se peuvent cacher
L’amour et la toux ne se peuvent celer
L’amour et l’amitié s’excluent l’un l’autre
L’amour fait assez, l’argent fait tout
L’amour fait danser les ânes
L’amour fait passer le temps et le temps fait passer l’amour
L’amour ne connaît pas de lois
L’amour ne fait pas bouillir la marmite
L’amour ne peut pas se cacher, et quand on cesse d’en avoir, cela se cache encore bien moins
L’amour ne se donna jamais pour apprenti
L’amour n’est pas un feu que l’on tient dans la main
L’amour n’est que le roman du cœur, c’est le plaisir qui en est l’histoire
L’amour passe, la faim vient
L’amour plaît plus que le mariage, par la raison que les romans sont plus amusants que l’histoire
L’amour qui naît subitement est le plus long à guérir
L’amour qui vient de la beauté n’est pas fin
L’amour qui vient de la poule n’est pas amour de qualité
L’amour se paye par amour
L’amour se peut appeler une sauce, propre à donner goût à toute viande
L’amour tombe aussi bien sur une bouse de vache que sur une feuille de rose
L’amour vit d’inanition et meurt de nourriture
L’amour ôte l’esprit à ceux qui en ont et en donne à ceux qui n’en ont pas
L’amour-propre est le plus grand de tous les flatteurs
L’amour-propre offensé ne pardonne jamais
L’amoureuse qui tient pied à deux souliers ne sera jamais épousée
L’amphore garde longtemps l’odeur du premier vin qu’elle a contenu
L’an passé est toujours le meilleur
L’an passé ne reviendra plus
L’animal même sauvage, quand on le tient enfermé, oublie son courage
L’apparence ne compte pas en amour Ou bien, être amoureux empêche de voir certains défaut pourtant bien évidents
L’apprendre est grande sueur, mais son fruit est douceur
L’appétit aussi tôt ouvert que les yeux
L’appétit est le meilleur cuisinier
L’appétit et la faim, ne trouvent jamais mauvais pain
L’appétit et la faim, ne trouvent nul mauvais pain
L’appétit vient en mangeant
L’appétit vient en mangeant et la soif en buvant
L’appétit vient en mangeant, en buvant s’en va la soif
L’araignée mange la mouche et le lézard l’araignée
L’arbre croît comme on le soigne et le fruit tombe pas loin du tronc
L’arbre devient solide sous le vent
L’arbre est devenu tordu pour n’avoir été redressé lorsque ce n’était qu’un sillon
L’arbre ne tombe qu’après la feuille
L’arbre par trop souvent transplanté ne produira fruit à planté
L’arbre penche du côté où il va tomber
L’arbre qui porte des fruits a beaucoup à souffrir
L’arbre sans fruit est digne de feu
L’arbre sec ne reverdit pas
L’arbre tombe du côté où il penche
L’arbre transplanté devient à la fois plus fécond et fertile
L’arc par trop tendu s’afflachit
L’arc toujours ou trop ne doit être tendu, car il romprait
L’arc toujours tendu se gâte
L’arc trop tendu se rompt
L’arc trop tendu s’afflachit
L’arc trop tendu, tôt lâché ou rompu
L’arc-au-ciel (arc-en-ciel) du soir, fait beau temps paroir
L’arc-en-ciel du matin, présage de pluie pour le soir
L’argent a droit partout
L’argent a moins de valeur que l’or, et l’or que la vertu
L’argent a raison partout
L’argent ard gens
L’argent contribue au bonheur de celui qui sait l’employer et fait le malheur de celui qui se laisse dominer par l’avarice ou la cupidité
L’argent court, quand (bien) même il n’a pas de jambes
L’argent demeure au plus vivant
L’argent est fait pour circuler
L’argent est fait pour rouler
L’argent est le Bon Dieu de ce monde
L’argent est le nerf de la guerre (Rabelais) ou : Les nerfs des batailles sont les pécunes
L’argent est le nerf des affaires (Bion de Boristhène) Voir aussi
L’argent est l’âme du commerce
L’argent est pour rouler
L’argent est rond
L’argent est rond, il s’arrête pas longtemps par les mains
L’argent est serviteur ou maître
L’argent est source de bien pour les bons et source de mal pour les méchants
L’argent est un autre sang
L’argent est un bon serviteur et un mauvais maître
L’argent est un bon serviteur et un mauvais maître
L’argent est un bon valet et un mauvais maître
L’argent est un onguent
L’argent et la folie ne peuvent se dissimuler
L’argent fait fou les gens
L’argent fait la guerre, tel le dit qui n’en a guère
L’argent fait parler les muets
L’argent ne fait pas le bonheur en ménage, mais il aide à s’en passer
L’argent ne se perd qu’à faute d’argent
L’argent ne se trouve pas sous le sabot d’un cheval
L’argent ne tombe pas bas du toit
L’argent n’a pas de maître
L’argent n’a pas de poux
L’argent n’a pas d’odeur
L’argent n’a rien de maître
L’argent n’a rien d’odeur
L’argent n’aime personne
L’argent n’est pas tout
L’argent protège
L’argent prêté fait perdre le souvenir
L’argent prêté n’est pas en sûreté
L’argent qui n’est pas arrivé par le droit chemin s’en reva
L’argent qui t’a été prêté, sans demander soit apprêté
L’argent seul ne peut suffire à rendre heureux dans la vie Certains ajoutent mais il y contribue ou ironiquement des pauvres
L’argent s’amène, l’argent s’en va
L’argent s’en va, la honte demeure
L’argent tente tous
L’argent tombe pas aval la borne
L’argent tombe pas aval la cheminée
L’argent tremble devant la porte du juge et de l’avocat
L’argent va au pauvre tout comme une selle à une vache
L’argent va aux riches
L’argent volé vaut jamais ce qu’il coûte ; bonne conscience coûte jamais ce qu’elle vaut
L’argent économisé est deux fois gagné
L’arme cause mainte(s) larme
L’arrogance, si elle n’est pas une diablerie, elle en a du moins l’apparence
L’art de gouverner, c’est l’art de choisir
L’art de l’intrigue suppose de l’esprit et exclut le talent
L’art de parler, peu nécessaire est à cil qui ne se peut taire
L’art de persuader consiste autant en celui d’agréer qu’en celui de convaincre
L’art de savoir ami entretenir n’est pas moindre que le savoir acquérir
L’art de tout avoir est de n’exiger rien
L’art de vivre est une tactique où nous serons longtemps novices
L’art est de cacher l’art
L’art et industrie humaine a grande efficace
L’art et l’usage rend l’idiot sage
L’art ne fait que des vers, le cœur seul est poète
L’artisan vit partout
L’ascète n’a rien à lui que sa harpe
L’asile le plus sûr est le sein de sa mère
L’aspect des guerriers est pour une part dans la victoire
L’athée ne nie pas Dieu et la religion, il n’y pense point
L’attendu n’arrive point, c’est l’inattendu qui se présente
L’attente et chose latente tourmente
L’attente tourmente
L’aubépine demeure sur les hauts chemins
L’audace cache de grandes craintes
L’audacieux triomphe du péril avant de l’apercevoir
L’augment d’eau gâte le potage
L’aumône aux pauvres n’a jamais personne eu mis à la misère
L’aumône du pauvre n’appauvrit pas
L’aumône est sœur de la prière
L’aurore a de l’or dans la bouche
L’aurore est l’amie des muses
L’aurore prend pour sa part le tiers de l’ouvrage
L’automne a encore de beaux jours
L’automne est le père des fruits
L’avalanche va toujours en contraval
L’avare a la goutte aux doigts
L’avare au rat d’une minière se compare en cette manière
L’avare court après les rouges centimes pour laisser courir les écus
L’avare est comme les porcs, il ne fait pas de bien qu’après sa mort
L’avare et le porc ne sont bien qu’après leur mort
L’avare fait de toute herbe faix
L’avare ferme les yeux quand il voit un pauvre
L’avare ne fait de bien que quand il meurt
L’avare ne possède pas son or, c’est son or qui le possède
L’avare se dit économe, le poltron se dit prudent
L’avarice ayant tué un homme se réfugia dans l’église et elle n’en est pas sortie de celle-ci depuis
L’avaricieux est toujours affamé de bien
L’avenir d’un enfant est l’œuvre de sa mère
L’avenir n’est à personne, l’avenir est à Dieu
L’avenir pour la jeunesse, le souvenir pour la vieillesse
L’aveu de notre faute est presque l’innocence
L’aveugle ne peut juger des couleurs
L’aveugle voudrait que les autres le fussent aussi
L’aveuglement des hommes est le plus dangereux effet de leur orgueil
L’avoine fait le cheval
L’avoir et le savoir font un grand coup
L’eau courante n’est ni mauvaise ni puante
L’eau court toujours en aval
L’eau court toujours en la mer
L’eau de citerne, de tous maux gouverne
L’eau de citerne, tous maux gouverne
L’eau de la fontaine ne monte point plus haut que sa source
L’eau dormante vaut pis que la courante
L’eau dormante vaut pis que l’eau courante
L’eau dormante, c’est la plus trompeuse
L’eau fait pleurer, le vin chanter
L’eau fait pourrir la barque
L’eau fait venir des grenouilles dans le ventre et le vin tue les vers
L’eau gâte le vin et le vin ne gâte pas l’eau
L’eau gâte le vin, la charrette le chemin et la femme le voisin
L’eau gâte le vin, la charrette le chemin et la femme l’homme
L’eau gâte le vin, les charrettes les chemins et les femmes l’homme
L’eau perd le lait et trop d’importunité les amis
L’eau qui court ne fait pas mal au museau
L’eau qui court pas, elle tournoie
L’eau qui dort pue
L’eau qui dort, c’est celle qui noie
L’eau qui dort, l’eau qui noie
L’eau qui dégoutte ronge la pierre
L’eau va toujours au bief
L’eau va toujours en aval
L’eau va toujours à la fontaine
L’eau va à la rivière
L’eau à traits de bœuf bois et le vin comme roi
L’eau à volonté, le vin avec modération
L’eau éteint le feu et l’aumône expie les péchés
L’eau, le seigneur et le grand chemin, sont tous de mauvais voisins
L’efficace de vertu est de résister à vice
L’effronterie est toujours la marque d’une âme de la dernière roture
L’effronté dans un festin se fait traiter avec des perdrix rôties, au bien que le honteux n’a que les restes du pain
L’empereur n’est qu’un homme
L’emprunteur devient valet du prêteur
L’encens gâte plus de cervelle que la poudre n’en fait sauter
L’enclume de femme rompt tous marteaux
L’enclume n’a pas peu du bruit
L’enfance est le sommeil de la raison
L’enfant bien instruit donne espoir de bon fruit
L’enfant est l’ancre de la mère
L’enfant qui ressemble au père est l’honneur de la mère
L’enfant reconnaît sa mère à son sourire
L’enfant sans discipline en sa jeunesse fera rarement fruit en sa vieillesse
L’enfer a été fait pour les curieux
L’enfer des femmes, c’est la vieillesse
L’enfer est pas fait pour les chiens
L’enfer est pavé de bonnes intentions
L’enfer est tout pavé de bonnes intentions
L’engin de l’homme tout façonne et donne
L’engin humain prend sa forme par vertueux exercice
L’engin humain se maintient et croît par bon exercice
L’engin puéril, pour vif et accord qu’il soit, a métier (besoin) de l’aide du maître
L’ennui est entré dans le monde par la paresse
L’ennui est une maladie dont le travail est le remède
L’ennui naquit un jour de l’uniformité
L’entrée de plusieurs médecins fait mourir
L’entêtement et le dégoût se suivent de près
L’entêtement représente le caractère, à peu près comme le tempérament représente l’amour
L’envie a le teint livide et les discours calomnieux
L’envie escorte la gloire
L’envie est plus irréconciliable que la haine
L’envie et la colère abrègent la vie (ou les jours)
L’envie ronge les envieux comme la rouille ronge le fer
L’envie s’attache toujours au mérite, elle ne cherche pas querelle à la médiocrité
L’envie, c’est la douleur de voir autrui jouir de ce que nous désirons; la jalousie, c’est la douleur de voir autrui posséder ce que nous possédons
L’envieux aperçoit en autrui ce qui n’y est pas et ne voit pas en soi-même ce qui y est, car il a les yeux faits de travers
L’envieux est un animal très fielleux et poisonneux
L’envieux est à autrui mauvais et à soi-même pire
L’envieux jamais ne méliore (améliore) et qui s’en accointe souvent péjore
L’envieux maigrit de l’embonpoint des autres
L’envieux préfère la pute ordure à la bonne et suave odeur
L’erreur d’un jour devient une faute, si l’on y retombe
L’erreur est aussi grande de se fier à tous que de tous se défier
L’erreur est humaine
L’erreur est la règle, la vérité est l’accident de l’erreur
L’esclave de mauvaise volonté est malheureux sans être moins esclave
L’esclave n’a qu’un maître, l’ambitieux en a autant qu’il y a de gens utiles à sa fortune
L’espoir différé rend le cœur malade, mais le désir accompli est un arbre de vie
L’espoir du doux repos soulage le dur labeur de tout ouvrage
L’esprit dans le sommeil a de claires visions
L’esprit de conversation consiste bien moins à en montrer beaucoup qu’a en faire trouver aux autres
L’esprit de l’homme le soutient dans la maladie, mais l’esprit de l’homme abattu, qui le relèvera ?
L’esprit des femmes est d’argent vif, leur cœur est de cire
L’esprit des femmes est léger comme le vent de midi
L’esprit est nourri par le silence de la nuit
L’esprit est prompt, mais la chair est faible
L’esprit est toujours la dupe du cœur
L’esprit est un tonneau plein de sagesse et de folie
L’esprit meut la masse
L’esprit ne peut remplacer le tact, le tact peut suppléer à beaucoup d’esprit
L’esprit puéril est le plus docile
L’esprit qu’on veut avoir gâte celui qu’on a
L’esprit sert à tout, mais il ne mène à rien
L’espérance en Dieu est certaine et toute autre vaine
L’espérance est la nourrice des hommes de peu d’esprit
L’espérance est le plus utile et le plus pernicieux des biens
L’espérance est le songe d’un homme éveillé
L’espérance nourrit les exilés
L’espérance que le mari en refera un autre, la femme oublie le deuil de son enfant mort
L’essai d’amour coûte trop cher
L’estime des hommes est un bien plus sûr que l’argent
L’estime vaut mieux que la célébrité, la considération vaut mieux que la renommée
L’estomac est le dos d’un âne
L’exactitude est la politesse des rois
L’exagération est le mensonge des honnêtes gens
L’excellence de l’esprit est un perpétuel festin
L’exception confirme la règle
L’excès de sommeil fatigue
L’excès de travailler aide fort bien à sommeiller
L’excès d’un très grand bien devient un mal très grand
L’excès en tout est un défaut
L’exemple descend et ne monte pas
L’exemple est le plus grand de tous les séducteurs
L’exemple est un dangereux leurre
L’exemple souvent n’est qu’un miroir trompeur
L’exemple touche plus que ne fait la menace
L’exercice et la propreté entretiennent la santé
L’exilé, qui n’a de demeure nulle part, est un mort sans tombeau
L’expérience confirme que la mollesse et l’indulgence pour soi et la dureté pour les autres n’est qu’un seul et même vice
L’expérience est le fruit d’un vieil arbre
L’expérience vous instruit beaucoup
L’expérience, on l’attrape à ses dépens
L’extrême exactitude est le sublime des sots
L’habileté est le talent de voir juste la fin de chaque chose
L’habileté est à la ruse ce que la dextérité est à la filouterie
L’habit change les mœurs ainsi que la figure
L’habit fait l’homme
L’habit ne fait l’homme et la barbe ne fait pas le philosophe
L’habit ne fait pas le moine
L’habit ne fait pas le moine mais la belle plume fait le bel oiseau
L’habit ne rend pas le singe beau quoiqu’il soit fait de soie
L’habit refait le moine
L’habitude est une seconde nature
L’habitude fait beaucoup
L’harmonie la plus douce est le son de voix de celle que l’on aime
L’hellébore, c’est du poison pour les personnes saines et la guérison des fols
L’herbe qu’on connaît doit-on lier à son doigt
L’herbe qu’on connaît faut mettre à son doigt
L’herbe qu’on connaît, on la doit bien lier à son doigt
L’herbe qu’on connaît, on la doit lier à son doigt
L’heur de la maison est d’avoir de procès vacation
L’heure du berger se trouve dans la fortune comme en amour
L’heure fugitive vole d’une aile incertaine
L’hirondelle et l’orphie au 15 avril
L’histoire est la philosophie enseignée par l’exemple
L’histoire est un perpétuel recommencement
L’histoire est écrite pour raconter, non pour prouver
L’hiver donne le froid, le printemps la verdure, l’été le blé et l’automne le bon vin
L’hiver et les dettes sont de vilaines bêtes
L’hiver n’a point de matin
L’homme a deux bons jours sur terre, lorsqu’il prend une femme et lorsqu’il l’enterre
L’homme a plus soif de gloire que de vertu
L’homme absurde est celui qui ne change jamais
L’homme adultère laboure le champ d’autrui et laisse le sien inculte
L’homme affamé dévore sa moisson, l’homme altéré engloutit ses richesses
L’homme arrive novice à chaque âge de la vie
L’homme bien marié ne sait pas ce que Dieu lui a donné
L’homme bien sain, mangeant bien et buvant, sans travail ne le sera longtemps
L’homme bon est comme un arbre planté près d’un cours d’eau, qui donne son fruit en tout temps et dont le feuillage ne se flétrit jamais
L’homme chargé de péché est bien empêché
L’homme cherche, la femme récuse
L’homme choit (tombe) en vice facilement, mais en vertu (se re)dresse lentement
L’homme choit en vice facilement mais en vertus dresse lentement
L’homme chétif, pauvre et mesquin, de chacun est proche et voisin
L’homme commande et la femme en fait à sa tête
L’homme couard (lâche, vague, indécis) ne vaut rien en bataille, car il fuit avant que coup on lui baille
L’homme couard ne vaut rien en bataille, car il fuit avant que coup on lui baille
L’homme cruel n’est pas touché par les larmes,il s’en repaît
L’homme curieux est toujours gueux
L’homme curieux est toujours malheureux
L’homme c’est le feu, la femme l’étoupe, le diable le soufflet
L’homme de bien a part en toute région, comme en la mer le poisson
L’homme de bien ne se dispute avec personne et, autant qu’il le peut, en empêche les autres
L’homme de bon sens, même s’il est lent, atteint un homme agile
L’homme de génie est souvent le premier et le dernier de sa dynastie
L’homme de nature sanguine, volontiers plaisante et badine
L’homme de passage, n’attrape femme si elle est sage
L’homme doit au vin d’être le seul animal à boire sans soif
L’homme doit dresser sa femme dès la première miche de pain
L’homme doit manger pour lui et pour sa femme
L’homme doit suivre son inclination naturelle
L’homme doit être constant tant en prospérité qu’adversité
L’homme dont le caractère se confond avec le nôtre vaut mieux que mille parents
L’homme double de cœur et courage est inconstant en tout ouvrage
L’homme doux, en tous lieux est reçu
L’homme débonnaire rend la femme grasse
L’homme dépourvu de l’aide de Dieu n’est sûr en nul lieu
L’homme est bien sot, qui ne sait se faire moquer de soi
L’homme est de chair, non de fer
L’homme est de feu, la femme d’étoupe et le diable souffle
L’homme est de glace aux vérités; il est de feu pour les mensonges
L’homme est dieu ou bête
L’homme est fait d’étoupe et la femme de filasse, le diable a bien vite fait d’y mettre le feu
L’homme est feu et la femme étoupe, le diable vient qui souffle
L’homme est inconstant comme l’oiseau est volage
L’homme est indigne de l’être si de sa femme il n’est maître
L’homme est indigne d’être homme, si de sa femme il n’est maître
L’homme est jugé par son intention
L’homme est la mesure de toutes choses
L’homme est le plus muable de tous autres animaux
L’homme est l’âme de (la) maison
L’homme est né pour bien travailler et l’âne pour somme ou charge porter
L’homme est prisé par sa constance et le fin or par sa substance
L’homme est semblable à un souffle, ses jours sont comme l’ombre qui passe
L’homme est tenu par ses paroles ainsi que le bœuf par les cornes
L’homme est toujours un sot, quand la femme en sait trop
L’homme est très noble créature quand par raison (il) guide sa nature
L’homme est un apprenti, la douleur est son maître
L’homme est un corrompu qui fait le délicat
L’homme est un dieu tombé qui se souvient des cieux
L’homme est un individualiste
L’homme est un loup pour l’homme
L’homme est un être sociable; la nature l’a fait pour vivre avec ses semblables
L’homme est une chose abjecte et vile, s’il ne s’élève au-dessus de l’humanité
L’homme et la fortune ont toujours des projets différents
L’homme fait la femme et la femme fait l’homme
L’homme fait son pouvoir et Dieu son vouloir
L’homme fatigué, la pensée vide
L’homme fleurit pour mourir
L’homme frugal est son propre médecin
L’homme généreux invente même des raisons de donner
L’homme généreux se croit toujours riche
L’homme habile est supérieur à l’homme fort
L’homme heureux ne porte pas de chemise
L’homme influençable n’est qu’une glaise molle
L’homme le plus adroit se brûle avec le feu
L’homme le plus fort ne saurait toujours labourer ni tirer au collier
L’homme malade en sa maison est un pauvre à la porte
L’homme marié est un oiseau en cage
L’homme meurt autant de fois qu’il perd l’un des siens
L’homme meurt de son chagrin, la femme s’en nourrit
L’homme meurt du mal dont il a peur
L’homme naquit pour travailler, comme l’oiseau pour voler
L’homme ne doit être honoré que par ses bonnes œuvres
L’homme ne peut rien rencontrer de meilleur que la femme, quand elle est bonne, mais rien de pire, quand elle est mauvaise
L’homme ne se connaît pas lui-même
L’homme ne vit pas pour manger, mais il boit et mange pour vivre
L’homme ne vit pas seulement de pain
L’homme noble, c’est l’homme vertueux
L’homme n’a pas plus le pouvoir d’être constant que celui d’écarter les maladies
L’homme n’a pas été créé pour la femme, mais la femme pour l’homme
L’homme n’a raison ni bon sens, s’il dit tout à sa femme
L’homme n’est bon qu’à la condition de l’être à l’égard de tous
L’homme n’est que la flamme, la femme est le brasier
L’homme n’est qu’un roseau, le plus faible de la nature, mais c’est un roseau pensant
L’homme n’est à priser pour sa science, s’il n’a pure et monde la conscience
L’homme obéissant à raison, excelle tous animaux et créatures mortelles
L’homme par les paroles et le bœuf par les cornes
L’homme par trop ne convient louer, car on le voit tôt varier
L’homme patient et courageux fait lui-même son bonheur
L’homme propose et Dieu dispose
L’homme propose, Dieu dispose
L’homme prudent fait de tout son profit
L’homme prudent fait de toute herbe faix
L’homme prudent sait dissimuler un outrage
L’homme quand il est sot tout jeune, pour vieillir ne devient point sage
L’homme quand il n’est pas marié, ne sait pas ce que Dieu lui a donné
L’homme qui a contentement, est nommé riche justement
L’homme qui a cœur et courage, de fortune ne craint l’orage
L’homme qui a les yeux malades ne peut regarder le jour ni le coupable entendre la vérité
L’homme qui a sa femme morte, a cent écus à sa porte
L’homme qui est seul est fol
L’homme qui flatte son prochain tend un filet sous ses pieds
L’homme qui moult boit, tard paye ce qu’il doit
L’homme qui ne prend pas femme est une moitié de ciseaux
L’homme qui possède la paix de l’âme n’est importun ni à lui-même ni aux autres
L’homme qui se confie à Dieu est un arbre qui ne cesse de porter du fruit
L’homme sage, prudent et discret, à femme ne révèle son secret
L’homme se connaît en trois choses, à la bile, à la bourse et au verre
L’homme se demène, mais Dieu le mène
L’homme se marie quand il veut et la femme quand elle peut
L’homme se marie quand il veut et la femme seulement quand elle trouve
L’homme se pendrait au gerbier plutôt que d’avouer ses défauts
L’homme seul est dieu ou démon Homo solus, aut deus aut daemon
L’homme soupçonneux incrimine la loyauté de chacun
L’homme suivant règle et raison est noble sans comparaison
L’homme s’agite, mais Dieu le mène
L’homme s’attachera à sa femme, et ils deviendront une seule chair
L’homme toujours gai est un bien triste mortel
L’homme veut dompter les animaux et demeure farouche et sauvage
L’homme vieil amoureux doit-on moquer
L’homme à la langue bavarde ne s’affermit pas sur la terre
L’homme à l’homme est ennemi ou à soi-même
L’homme, quand il est sot tout jeune, pour vieillir ne devient point sage
L’homme, ses jours sont comme l’herbe; comme la fleur des champs, il fleurit; qu’un souffle passe sur lui, il n’est plus
L’honneur défend des actes que la loi tolère
L’honneur d’une fille est à elle, elle y regarde à deux fois ; l’honneur d’une femme est à son mari, elle y regarde moins
L’honneur est le diamant que la vertu porte au doigt
L’honneur nourrit les arts
L’honneur, c’est la poésie du devoir
L’honnête homme au sens du XVIIe s est celui qui possède des vertus morales et des qualités pour la vie mondaine « L’honnête homme est un homme poli et qui sait vivre »
L’honnête homme tient le milieu entre l’habile homme et l’homme de bien, quoique dans une distance inégale de ces deux extrêmes
L’horloge ne peut exister sans horloger
L’huile comme aussi vérité, retournent toujours en sommité
L’huile d’olive fait fuir tous les maux
L’huis de derrière est celui qui gâte la maison
L’humanité se compose de plus de morts que de vivants
L’humanité se compose de plus de morts que de vivants
L’humble et sujet mérite pardon et le rebelle punition
L’humilité est le contrepoison de l’orgueil
L’humilité est l’autel sur lequel Dieu veut qu’on lui fasse des sacrifices
L’humilité est un artifice de l’orgueil
L’humilité ne doit pas aller jusqu’à l’humiliation
L’humilité précède la gloire
L’huître est pour le juge, les écailles pour les plaideurs
L’hypocrisie est un hommage que le vice rend à la vertu
L’hypocrisie porte un masque qui déteint
L’hypocrite prétend éviter les plus petites fautes, mais il se permet les plus grandes
L’hérésie est le fruit d’un peu de science et de loisir
L’hôte de la soif s’appelle la fièvre
L’hôte est toujours le plus foulé
L’hôte est toujours le plus gravé
L’hôte et la pluie, après trois jours ennuient
L’hôtel et le poisson, en trois jours sont poison
L’ignorance de la loi n’excuse personne
L’ignorance et l’incuriosité font un doux oreiller
L’ignorance ne voit pas, même ce qui frappe ses regards
L’ignorance n’est défaut d’esprit, ni le savoir n’est preuve de génie
L’ignorance toujours est prête à s’admirer
L’ignorance vaut mieux qu’un savoir affecté
L’ignorant a des ailes d’aigle et les yeux d’hibou
L’ignorant est cruel comme un tyran
L’ignorant est obstiné
L’image et la peinture, sert au simple de lecture
L’imagination est la folle du logis
L’imagination qui fait naître les illusions est comme les rosiers qui produisent des roses dans toutes les saisons
L’imbécile épouse la bête
L’impertinent est un fat outré
L’importance sans mérite obtient des égards sans estime
L’importun va souper chez sa maîtresse le soir même qu’elle a la fièvre
L’impossible a plus de force que le serment
L’impromptu est la pierre de touche de l’esprit
L’impudent est celui qui supporte le mépris, pourvu qu’il fasse ses affaires
L’impératrice est une femme
L’inattention fait échouer le navire
L’incapacité sert d’excuse pour éviter le travail
L’incrédulité est quelquefois le vice d’un sot, et la crédulité le défaut d’un homme d’esprit
L’incurie entraîne bien des fautes
L’indifférence est le sommeil de l’âme
L’indigent de peu est content et l’avare toujours mal content
L’indignation fait jaillir la stance
L’indolence est le sommeil des esprits
L’indulgence est la parure des vertus
L’indulgence est une partie de la justice
L’industrie surpasse la force
L’indécent n’est pas le nu, mais le troussé
L’infidélité est comme la mort, elle n’admet pas de nuances
L’infortune est la sage-femme du génie
L’ingratitude la plus odieuse, mais la plus commune et la plus ancienne, est celle des enfants envers leurs parents
L’inimitié est une colère qui guette une occasion de vengeance
L’injustice est une impiété
L’innocence est toujours accompagnée du rayonnement qui lui est propre
L’innocence à rougir n’est point accoutumée
L’innocent trouve le moyen d’être éloquent, même s’il est lent à parler
L’inquiétude amène la vieillesse avant le temps
L’insensé laisse voir aussitôt sa colère, mais l’homme prudent sait dissimuler un outrage
L’insensé qui retombe dans sa folie est comme le chien qui retourne à son vomissement
L’instigateur est plus coupable que le délinquant
L’instinct, c’est tout sentiment et tout acte qui prévient la réflexion
L’instruction accroît la valeur innée
L’instruction pour les femmes, c’est le luxe; le nécessaire, c’est la séduction
L’instruire et l’enseigner, grand art a métier
L’intelligence et l’âge ne viennent pas ensemble
L’intelligence, c’est comme la confiture, moins on en a, plus on l’étale
L’intention fait la culpabilité et le délit
L’intérêt des hommes a fait de la Fortune une déesse
L’intérêt est plus aveugle que l’amour
L’intérêt n’a point de temples, mais il est adoré
L’intérêt n’est la clef que des actions vulgaires
L’intérêt personnel est le poison de tout sentiment vrai
L’invention est l’unique preuve du génie
L’ironie est la bravoure des faibles et la lâcheté des forts
L’ivresse est une folie volontaire
L’ivrogne et le fainéant se ruinent promptement, la mauvaise ménagère en fait autant
L’ivrognerie n’a jamais fait aucune maison et en a défait plus d’une
L’ivrognerie tue plus de gens que la guerre
L’objet de la guerre, c’est la paix
L’objet principal de la politique est de créer l’amitié entre les membres de la cité
L’obscur par le plus obscur
L’obscurité donne la paix aux hommes simples
L’obstination et ardeur d’opinion est la plus sûre preuve de bêtise
L’obstination tient moins à la volonté qu’au peu de capacité
L’obéissance est un métier bien rude
L’occasion du gain est brève
L’occasion est chauve
L’occasion fait le larron
L’occasion n’a qu’une mèche de cheveux
L’occasion semble chercher ceux qui sont les plus capables d’en profiter
L’offense d’un qui fut ton ami, est plus grave que d’un ennemi
L’offense est plus facilement tolérée par les oreilles que par les yeux
L’office du bon maître est de connaître la nature de ses disciples
L’office du bon pasteur est tondre et non écorcher son troupeau
L’office du bon prince est favoriser et défendre l’homme de bien et punir le flagitieux
L’office du bon roi ou recteur est de porter soin de son peuple
L’office du petit est révérer le grand et du grand comporter l’imbécillité du petit
L’office fait l’homme Magistratus facit homines
L’oie, l’abeille et le veau
L’oiseau doit beaucoup à son plumage
L’oiseau par ses plumes est jugé beau
L’oiseau se défend par son vol, le lion par sa force, le taureau par ses cornes, l’abeille par son aiguillon; la raison est la défense de l’homme
L’oiseleur, pour trop regarder les merles, se jette dans un puits
L’oisiveté est la mère de tous les vices
L’oisiveté est le naufrage de la chasteté Otium naufragium castitatis
L’oisiveté est l’ennemie de l’âme
L’oison mène l’oie paître et le bejaune (jeune) précède le maître
L’olivier se brise, le roseau plie
L’ombre d’un grand nom demeure
L’ombre la plus mauvaise pour la maison d’un paysan, c’est un château
L’on a beau prêcher à l’âne avant qu’il devienne docteur
L’on connaît avec le temps les bons payeurs et marchands
L’on connaît les parents et les amis à noces et à mort en maints pays
L’on dit par bourgs, villes et villages, vin et femmes attrapent les plus sages
L’on doit ajouter plus de foi à l’œil qu’à l’oreille
L’on doit donner conseil aux prospères et remède aux pauvres et indigents
L’on doit également considérer la vie, d’icelui qui médit comme de qui il médit
L’on endure tout mais que le trop aise
L’on est plus sociable et d’un meilleur commerce par le cœur que par l’esprit
L’on estime le fait et le dit d’iceux qu’ont argent et crédit
L’on honore communément ceux qui ont beaucoup d’argent
L’on ne doit jamais aller à noces sans y être convié
L’on ne doit pas le monde aimer, car on y trouve par trop d’amer famine y a, en gain froidure, chaleur pestilence et ordure
L’on ne doit pas mettre la charrue devant les bœufs
L’on ne doit semer toute sa semence en un champ
L’on ne doit tant donner à Saint Pierre, que Saint Paul demeure derrière
L’on ne peut cacher anguilles en sac
L’on ne peut courir ensemble et corner
L’on ne peut faire d’une colombe un épervier
L’on ne peut fêter avant commencer
L’on ne peut homme nu dépouiller
L’on ne peut humer et souffler tout ensemble
L’on ne peut servir ensemble Dieu et le diable
L’on ne peut voler sans ailes
L’on ne peut écorcher une pierre
L’on ne saurait faire en dix ans ce qu’on fait en trente
L’on ne s’amende pas de vieillir
L’on ne tient pas toujours ce qu’on promet
L’on n’achète pas sûrement ce qu’appartient à plusieurs gens
L’on n’est sage tant que l’on n’a follé
L’on n’estime la voix ni le dit, de qui n’a vertu ni crédit
L’on peut bien de tout user et abuser, comme d’un vent éteindre et allumer
L’on peut bien imposer silence au sentiment, mais non lui marquer des bornes
L’on peut de tout user et abuser et d’un même souffle éteindre et allumer
L’on prouve que l’on a du caractère quand on parvient à vaincre le sien
L’on trouve toujours aux douceurs d’héritier, des consolations qu’on ne peut rejeter
L’opinion d’un sage vaut mieux que la croyance ou l’assurance de cent autres qui ne le sont point
L’opinion est la reine du monde
L’opinion est la reine du monde, parce que la sottise est la reine des sots
L’opinion vraie est le bien de la pensée
L’opulence a sa misère; elle est lâche et tient à la vie
L’or du soleil en janvier Est or que l’on ne doit envier
L’or est le sang des États
L’or est un tyran invisible
L’or et la beauté ont peur des larrons
L’or jaune on le divise, l’amour on ne le partage pas
L’or périt et l’argent meurt l’ami du monde
L’or s’épure au feu, l’homme s’éprouve au creuset du malheur
L’or à celui qui est lié n’est rien prisé
L’or, la femme et la toile, ne les prends qu’à la lumière du jour
L’or, la femme et les étoffes, ne les choisis qu’en plein jour
L’or, la gale et l’amour ne peuvent pas se cacher toujours
L’or, même à la laideur, donne un teint de beauté
L’ordre amène le pain, le désordre la faim
L’ordre est un des éléments du beau avec la grandeur
L’ordure est du porc la nourriture et de mainte créature la pourriture
L’oreille est le chemin du cœur
L’oreille est le chemin du cœur et le cœur l’est du reste
L’oreiller fait ce qu’il lui plaît de l’homme et de la femme
L’oreiller porte conseil
L’orgueil ayant pris le vol vers le ciel alla fondre aux enfers
L’orgueil est le dédain de tout ce qui n’est pas soi
L’orgueil est l’apanage des sots
L’orgueil est une bête chère à nourrir
L’orgueil fait sauter bien des gens
L’orgueil mondain, Dieu le hait et rabat
L’orgueil ne réussit jamais mieux que quand il se couvre de modestie
L’orgueil ne veut pas devoir, et l’amour-propre ne veut pas payer
L’orgueil précède la ruine et la hauteur précède la chute
L’orgueil s’installe au large dans une tête vide
L’orgueil tord le cou
L’orgueilleux ne connaît ni son faible ni le fort des autres, jusqu’à ce qu’il les sente ou expérimente
L’orgueilleux regarde les autres avec des yeux chassieux et soi-même sans yeux, en aveugle
L’ormeau a le branchage fort beau, mais il ne porte point de fruit
L’outrage ne vient pas de qui t’injurie, mais de ton jugement qui te fait croire que l’on t’outrage
L’ouvrage de plusieurs est plus grand, et plus grand est le profit
L’ouvrage qu’on fait le dimanche, le diable le prend le lundi
L’ouvrier est digne de son loyer
L’un a les faits et l’autre les plaids
L’un ami pour l’autre veille
L’un fait lever les oiseaux de dedans le buisson et un autre les a pris
L’un meurt dont l’autre vit
L’un meurt d’une même fièvre et l’autre en réchappe
L’un n’empêche pas l’autre
L’un sert à nous faire le mal et l’autre à nous y endurcir
L’un sème, l’autre récolte
L’un tire à hue et l’autre à dia
L’un veut aller ou agir d’un côté, tandis que l’autre va du côté opposé
L’une main lave l’autre et les deux lavent le visage
L’union fait la force
L’univers est une espèce de livre dont on n’a lu que la première page quand on n’a vu que son pays
L’usage est fait pour le mépris du sage
L’usage est le tyran des langues
L’usage fait briller le métal
L’usage nous fait voir une différence énorme entre la dévotion et la bonté
L’usage nous fait voir une distinction énorme entre la dévotion et la conscience
L’usage seulement fait la possession
L’utilité de la vertu est si manifeste que les méchants la pratiquent par intérêt
L’État est le navire qui porte notre fortune
L’âge d’or était l’âge où l’or ne régnait pas
L’âge est la plus grande des maladies, il ne laisse personne
L’âge ne pardonne rien
L’âge n’est que pour les chevaux
L’âge présent ne vaut pas celui des aïeux
L’âge rend indulgent sur le caractère, et difficile sur l’esprit
L’âge rend l’homme sage
L’âme d’un amant vit dans le corps de l’amante
L’âme d’un roi et celle d’un savetier sont jetées au même moule
L’âme est le seul oiseau qui soutienne sa cage
L’âme et le corps souvent sont discords
L’âme perverse perd celui qui la possède
L’âme vile est enflée d’orgueil dans la prospérité et abattue dans l’adversité
L’âne de tous est mangé des loups
L’âne est né à la charge et l’homme à bien opérer
L’âne mal tondu, au bout de huit jours s’égalise
L’âne piqué ne repique
L’âne porte le vin et boit l’eau
L’âne porte tout ce qu’on lui met sur le bât
L’âne procède en âne
L’âne se couvre de la peau du lion
L’âne se reconnaît aux oreilles et le fou au parler
L’éclat ne saute pas loin du tronc
L’école est une piscine de vie
L’écoutant fait le médisant
L’écouteur est pire qu’un voleur
L’écouvillon reproche au fourgon
L’écouvillon se moque du râble
L’écriture ne ment point
L’écu a les forces d’Hercule
L’écu est le laquais de l’honneur
L’écu est un fruit qui est toujours mûr
L’écu fait d’hiver le printemps
L’écu fait d’hiver l’été
L’écu léger, est au médecin congé
L’éducation a des racines amères, mais ses fruits sont doux
L’éducation développe les facultés, mais ne les crée pas
L’égalité n’a d’autre existence que celle de son nom
L’égalité, c’est l’utopie des indignes
L’égoïsme est semblable au vent du désert, qui dessèche tout
L’éloge des absents se fait sans flatterie
L’éloquence a autant de force dans le gouvernement des hommes que le fer dans la bataille
L’éloquence est la lumière qui fait briller l’intelligence
L’élégance est un résultat de la justesse et de l’agrément
L’élévation est au mérite ce que la parure est aux belles personnes
L’émeraude ne perd pas de son prix faute de louange
L’émulation est l’aliment du génie, l’envie est le poison du cœur
L’épervier prend toujours la meilleure poule
L’épée coûte plus à entretenir qu’un cheval
L’épée incite à la violence
L’épée use le fourreau
L’équité considère ce qu’il convient de faire plutôt que ce qu’il faut faire
L’équité consiste à s’en rapporter plus volontiers à des arbitres qu’à un tribunal, car l’arbitre peut voir ce que l’équité autorise et le juge ne peut voir que la loi
L’équité est une justice en dehors de ce que la loi ordonne
L’étable est par trop tard fermé, quand le cheval est échappé
L’étable est trop tard fermé quand le cheval s’en est allé
L’étalon ne sent pas les coups de pieds de la jument
L’état fait beaucoup, l’esprit fait davantage
L’étoupe près du feu s’enflamme
L’étranger désire toujours s’en retourner en son pays
L’étrangère est un puits étroit
L’étude est le garde-fou de la jeunesse
L’été qui s’enfuit est un ami qui part
L’été sème, l’hiver mange
L’évènement est le maître des sots
L’évènement juge les actes
L’œil du maître engraisse le cheval
L’œil du maître réal engraisse le cheval
L’œil du sage est du soleil l’image
L’œil fait le guet
L’œil l’amour attire
L’œil malade, la lumière le fait souffrir
L’œil qui ne te voit pas ne te pleurera pas
L’œuvre l’ouvrier découvre
Ma fille se marier, c’est tous les jours travailler, dans la douleur enfanter et jusqu’à la mort pleurer
Ma fille se marier, c’est tous les jours travailler, dans la douleur enfanter, sans nul espoir soupirer et jusqu’à la mort pleurer
Magnanimité n’a besoin ni métier d’aiguillon à courroux ni bouclier
Mai froid, l’année gaie
Mai jardinier ne comble grenier
Mai pluvieux, l’année abondante en grains
Maigre cheval le cul écorché
Maigre vie fait le chien vieux
Maille après maille se fait le bas
Maille à maille fait-on le haubergeon
Maille à maillon, fait-on haubergeon
Main chaude, amour froid
Main droite et bouche monde, peut aller par tout le monde
Main du médecin trop piteux, rend le mal souvent bien chancreux
Main froide, amour chaud
Main gercée, diligente main
Main harpeuse et glueuse, partout est odieuse
Main légère pour prendre, pesante pour donner
Mains froides, cœur bien placé
Mains froides, cœur chaud
Mains laver, innocence prouver
Mains œuvreuses sont heureuses
Maint beau gibier est perdu par faute de faire pourchasse
Maintenant pris, maintenant pendu
Maintenant que tu es marié, tu as chanté la plus belle de tes chansons
Maintenant seule pécune est réputée sage par fortune
Maints deniers et courages, font ès villes maints ouvrages
Maints livres ne vivent pas plus que leurs affiches
Maints ne cherchent les grands que pour avoir privilège de mal faire
Maints sont bons parce qu’ils ne peuvent nuire
Maints sortent bons parce qu’ils ne peuvent nuire
Maison bâtie, vigne plantée et fille nourrie
Maison chétive est où la poule chante et le coq se tait
Maison de terre, cheval d’herbe, ami de bouche, ne vaillent pas le pied d’une mouche
Maison déreglée, famille gâtée
Maison d’adultère jamais ne prospère
Maison est pour les fils, les filles trouveront
Maison faite et femme à faire
Maison ne convient acheter, qui meubles n’a pour y bouter
Maison sans enfants, poirier sauvage sans poires
Maison sans femme et sans flamme, corps sans âme
Maison sans femme, corps sans âme
Maison sans tête de femelle est comme un soulier sans semelle
Maison sans voisins vaut cent louis de plus
Maison à beaucoup de filles, tout se dépense pour les noces
Majesté n’est que de Dieu
Mal accroît qui ne doit rendre
Mal acquis en tout art et métier ne profite au tiers héritier
Mal acquis, mal dépensé
Mal aimera les étrangers, celui qui hait ses familiers
Mal an et femme sans raison, ne manquent en nulle saison
Mal attend qui ne perattend
Mal au cul n’est pas santé
Mal aux dents qui enfle, mal de dents guéri
Mal avisé a assez (de) peine
Mal avisé a souvent peine
Mal avisé ne fut jamais sans peine
Mal avisé n’est pas sans peine
Mal battu, longuement pleuré
Mal bien pansé, mal guéri à moitié
Mal commence qui bien n’achève
Mal connu est à moitié guéri
Mal connu, à moitié guéri
Mal contrepoids fait à l’enclume qui lui contremet une plume
Mal de dent et mal d’enfant sont les plus grands
Mal de naissance (héréditaire) mal qui croît
Mal de trop avoir, mal de rien avoir
Mal de tête est un mal de luxe qui demande à boire, à manger ou à dormir
Mal de tête veut dormir
Mal de tête veut dormir ou repaître
Mal de tête veut repaître Repaître = manger
Mal d’autrui n’est que songe
Mal d’enfant : les douleurs de l’accouchement
Mal d’œil se guérit du coude
Mal entend, mal répond
Mal est caché à qui le cul apert
Mal est la guerre dont ne revient aucun
Mal fait inviter l’âne aux noces, quand il lui faut porter bois ou eau
Mal fait inviter l’âneau, à porter la somme ou l’eau
Mal fait qui ne parfait
Mal fait une œuvre qui n’y pense
Mal gagne qui tout dépense
Mal gouverner à autrui, qui soi-même ne se sait gouverner
Mal les mouches, mal les taons, marie-toi, marie-toi pas, diable l’un, diable l’autre
Mal marié, bien harié
Mal mariée n’a pas tout pleuré au berceau
Mal mariée, fille noyée
Mal nage qui se surcharge
Mal nourrit qui n’en savoure
Mal par conseil remédié, ne fut oncques guère estimé
Mal pense qui ne contrepense
Mal pense qui ne repense
Mal peut curer l’infirmité, qui n’en connaît la qualité
Mal prie qui s’oublie »
Mal prêcher qui n’a cure de bien faire
Mal reposent les mal couchés
Mal sans gravité s’en va comme il est venu
Mal se chauffe qui se brûle
Mal se conduit qui le bien d’autrui veut
Mal se mouille qui ne s’essuie
Mal se peut laver la tête ni couronne, qui au barbier ne va en personne
Mal sert qui ne parsert
Mal soupe qui tard dîne
Mal soupé ne peut reposer
Mal sur mal n’est pas santé
Mal sus mal n’est pas santé, mais un mal est par autre contenté
Mal va le char, mal va la charrue
Mal va qui naît et ne grandit pas
Mal verra le lointain, qui pas ne voit le prochain
Mal vienne au pèlerin, qui déprise son bourdoncin
Mal vit qui ne s’amende
Mal vit qui n’amende
Mal étendu, mal séché
Malade de bonne maison, avec peu de chose en a assez
Malade qui rassemble les couvertures est à point de mourir
Maladie rend la face blémie
Maladie, disette et vieillesse, causent l’homme tomber en détresse
Maladies viennent à cheval et s’en retournent à pied
Male est la guerre dont ne revient aucun
Male herbe ne peut périr
Male, masle = mauvaise
Malgré les pigeons on sème tous les ans
Malheur aux plantes infécondes, qui ne produisent fruit ni frondes
Malheur ne dure pas toujours
Malheur à celui par qui le scandale arrive
Malheur à celui qui est seul, car s’il tombe, il n’aura personne pour le relever
Malheur à celui qui scandalise les petits
Malheur à qui tombe sous main d’un tiran sévère et vilain
Malheureuse est la maison et méchante Où le coq se tait et la poule chante
Malheureuse la souris qui n’a qu’un trou
Malheureux de trop avoir et malheureux de pas assez avoir
Malheureux est le pays où que le diable est en haut pris Pris = prix, contraire de mépris
Malice engendre son propre supplice
Malice n’est sur malice de femme
Malice obscurcit la vérité, qui en fin reste en sommité
Malle = mal, mauvaise
Malle est la guerre dont ne revient aucun
Manche désirée fait court bras
Mange Bon Dieu, chie diable
Mange aussi bas que voudras, couche aussi haut que pourras
Mange de l’eau bouillie, cela te rendra plus vieux
Mange la viande crue et le poisson cuit
Mange la viande jeune et les poissons vieux
Mange peu et tiens-toi chaud
Mange ton poisson à présent qu’il est frais, marie ta fille à présent qu’elle est jeune
Mange à ton goût et habille-toi au goût des autres
Manger chaud, coucher haut, boire avec mesure, l’homme sera tout à fait bien
Manger chaud, coucher haut, boire à pleine rasade, l’homme sera tout à fait droit
Manger c’est tricher
Manger et boire assis et dormir sur le côté
Manger peu est sain mais n’engraisse pas
Manger un peu de soupe et boire un peu de vin font fuir maladie et médecin
Manger une pomme le soir fait dormir
Mangeurs, joueurs, blagueurs ne valent guère
Mangez lentement, mâchez longuement
Mangez à volonté, buvez en sobriété
Manteau couvre laid et beau
Manteau de velours, ventre de son
Manteau ou cape cache le début de la grossesse
Manteau, couvre laid et beau
Marchand de ciboulettes se connaît en oignons
Marchand d’oignons se connaît en ciboulettes
Marchand qui perd ne peut rire
Marchandise de voisin ne vaut rien
Marchandise n’épargne nul
Marchandise n’épargne personne
Marchandise offerte est à demi vendue
Mari et femme ont besoin l’un de l’autre dans leur vieillesse
Mari et femme sont joints ensemble comme la mie à la croûte
Mari ivrogne et femme joueuse, chassent vite les biens de la maison
Mari ivrogne et femme qui joue dissipent promptement les biens de la maison
Mariage de jeune avec jeune est de Dieu, de jeune et de vieille est de rien, de vieux et de jeune est du diable
Mariage de jeune et jeune mariage de bon Dieu, mariage de jeune et vieux mariage du diable, mariage de deux vieux mariage de merde
Mariage de jeune homme avec jeune fille est de Dieu, mariage de jeune homme avec vieille femme est de rien, mariage de vieillard avec jeune fille est du diable
Mariage de jeunes gens est de Dieu, mariage de vieux est de rien, mariage de vieille avec jeune est du diable
Mariage de jeunes mariage de joie, mariage de vieux avec jeune mariage de pouilleux, mariage de vieux avec vieux mariage de sots
Mariage d’amour, bonnes nuits mauvais jours
Mariage d’amour, mariage d’un jour
Mariage d’amour, vie de dolour = Dolour = douleur
Mariage d’argent, mariage de rien
Mariage d’inclination, dans six mois coups de bâton Mariage d’inclination = mariage forcé
Mariage d’intérêt n’est jamais heureux
Mariage entre parents : mariages consanguins
Mariage entre parents, vie courte et longs tourments
Mariage ménage
Mariage pluvieux, mariage heureux
Mariage sans nécessité est une félicité
Mariage, repentir de toute la vie
Marie des sous, marie de la merde
Marie jolie, marie deux
Marie le loup, il s’arrêtera bien
Marie ta fille lorsqu’elle en a l’envie et ton fils quand l’occasion s’en présente
Marie ta fille quand elle veut, ton fils quand il en a l’occasion
Marie terre, marie merde
Marie ton fils quand tu voudras et ta fille quand tu pourras
Marie ton fils quand tu voudras et ta fille quand tu pourras ; mieux vaut marier sa fille qu’avoir des regrets plus tard
Marie ton fils quand tu voudras et ta fille quand tu pourras ; mieux vaut tôt marier sa fille qu’avoir plus tard des regrets
Marie ton garçon quand tu voudras et ta fille quand tu pourras
Marie-toi avec une fermière, elle a de la bouse de vache dans ses sabots
Marie-toi chez toi
Marie-toi dans ton pays, dans ta rue et dans ta maison si tu peux
Marie-toi à ta porte avec des gens de ta sorte
Marie-toi, marie-toi pas, le repentir manquera pas
Marie-toi, marie-toi pas, tu t’en repentiras
Marie-toi, ne te marie pas, pour sûr tu t’en repentiras
Marie-toi, ne te marie pas, tu vas t’en repentir
Marie-toi, tu sauras combien te coûte le sel
Marier est bon, mais de se remarier ne vaut guère
Marier est bon, mais se remarier ne vaut guère
Marier est bon, remarier ne vaut rien
Marier un veuf à une veuve, c’est mettre deux personnes à l’aise
Maries-toi, ne te maries pas, pour sûr tu t’en repentiras
Mariez le Gave et il arrêtera ses débordements
Mariez l’Adour et l’Adour cessera ses débordements
Mariez votre fils quand vous voudrez et votre fille quand vous pourrez
Mariez-vous par amour vous souffrirez, ne vous mariez pas vous souffrirez
Mariez-vous, mariez-vous pas; mal les mouches, mal les taons; mal les poux, mal les teignes; diable l’un, diable l’autre
Marié ou non, chaud le chaud, froid le froid
Mars aride, avril humide, mai le gai tenant de tous deux, présagent l’an plantureux
Mars et avril, temps de dragées de mariage
Mars gris, avril pluvieux et mai venteux, font l’an fertile et plantureux
Mars pèle les brebis
Mars tue avec ses marteaux le grand bœuf dans le coin de l’étable
Mars tue, avril écorche, mai enterre
Mars venteux et avril pluvieux, font le mai gai et gracieux
Martyr n’est si grand que d’amour
Matin faut à monter la montagne, au soir aller à la fontaine
Matines bien sonnées sont à demi chantées
Mau = mauvais
Mau mariagement est la source de tout mal han
Mau règne ne peut vivre
Mauvais chien ne trouve où mordre
Mauvais esprit, mauvais cœur
Mauvais est le fruit qui ne mûrit point
Mauvais est l’avis qui ne peut varier
Mauvais héritier se déshérite
Mauvais ouvrier ne trouve jamais bon outil
Mauvais ouvrier ne trouvera jamais bon outil
Mauvais rapport fait briser alliance
Mauvais signal que de ne pas sentir son mal
Mauvaise affaire lorsque le coq se tait et que la poule chante
Mauvaise compagnie déprave des jeunes la vie
Mauvaise compagnie, au gibet l’homme convie
Mauvaise conversation, donne de soi suspicion
Mauvaise est la poule, si pour le coq elle n’est
Mauvaise femme et la fumée, chassent souvent l’homme de sa maison
Mauvaise fille se moque de sa mère
Mauvaise fille à sa mère fait la nique
Mauvaise garde permet au loup de se repaître
Mauvaise herbe croît soudain
Mauvaise herbe croît toujours
Mauvaise herbe croît volontiers
Mauvaise herbe ne peut crever
Mauvaise herbe ne peut mourir
Mauvaise herbe ne se perd pas
Mauvaise herbe périt difficilement
Mauvaise langue, mauvaises gens
Mauvaise nouvelle vient tôt assez
Mauvaise réputation va jusqu’à la mer; bonne réputation reste au seuil de la maison
Mauvaise réputation, son haleine sent mauvais
Mauvaise tête, bon cœur
Mauvaise vie et bonne mort, jamais ne furent d’accord
Mauvaise vie et bonne mort, ne vont pas souvent d’accord
Mauvaise vie et mauvaise fin, jamais ne pardonnent rien
Mauvaise vie, mauvaise fin
Mauvaises plantes se conservent assez
Maux de femmes, comme l’aurore, vers midi s’évaporent
Maux de jambes, mauvais maux, demandent repos
Maçon avec raison, fait maison
Maître André, faites des perruques !
Maître endormi et imprudent, rend son serf lourd et négligent
Membre n’est sain quand le chef deut ; quand la tête a peine, chacun membre se démène
Menaces ne sont pas lances
Mener une femme et une ânesse ne se font pas sans peine
Mensonge périt comme un songe
Mensonge souvent répété acquiert force de proverbe
Mentir est le fait des esclaves
Mer passée, amour oublié
Mes amis, c’est grand bonheur si d’ivrogne on ne devient voleur
Messager a congé de tout dire, mais non de tout faire
Messager ne doit mal ouïr ni mal avoir
Messager qui trouve fontaine, lui est avis que Dieu le mène
Messager sûr porte bon heur Bon heur = bonheur
Mesure conduit amélioration
Mesure deux fois, ne coupe qu’une
Mesure dure, beauté meurt
Mesure le pas à la jambe
Mesurer faut à la science l’homme, non à la corpulence
Mesurer les autres à son aune
Mets raison en toi, ou elle s’y mettra
Mets ta joie dans la femme que Dieu t’a donnée, dans la tendresse de ta biche et dans les grâces de ta gazelle, et bois l’eau de ta source
Mets ta main souvent en ton sein et ne médiras de ton prochain
Mets ton fumier près et puis ton gendre loin
Mets à ta porte une sonnette, mets à ton cœur point de serrure
Mettez fol à part soi et il pensera de soi
Mettez fol à part soi, il pensera de soi
Mettez le fol sus le banc, il branle les pieds ou dit quelque chant
Mettez un chapeau d’homme à un bouc, on trouverait une femme pour l’épouser
Mettre de l’eau dans son vin
Mettre la charrue avant les bœufs
Mettre les oranges au balcons
Mettre quelqu’un dans la gueule du loup
Mettre quelqu’un hors des gonds
Mettre ses seins en évidence
Mettre tous ses œufs dans le même panier
Meurs et après tu pourras être loué
Meurtre et paillardise ne se peuvent jamais celer
Miaule un, aboie deux, bêle trois, ronronne quatre, brame neuf comme la femme de la maison
Miel et vin, poison fin
Mieult vaut être de Dieu aimé que de grand matin levé
Mieux aime truie bran que roses
Mieux aimerais être néant que d’être pauvre et n’avoir rien
Mieux tard que jamais
Mieux vaut (se) taire que mal dire
Mieux vaut acheter qu’emprunter
Mieux vaut aise qu’orgueil
Mieux vaut aller au boulanger qu’à l’apothicaire Apothicaire
Mieux vaut ami au besoin que denier au poing
Mieux vaut ami en place qu’argent en bourse
Mieux vaut ami en voie qu’argent en courroie
Mieux vaut ami grondeur que flatteur
Mieux vaut amour liant deux cœurs que richesse emplissant étable
Mieux vaut appétit que sauce
Mieux vaut argent en huche qu’écu en paroi
Mieux vaut assez que trop
Mieux vaut au corps douleur qu’en âme aigreur
Mieux vaut avoir qu’espoir
Mieux vaut avoir une tourte de pain sur la table qu’un miroir sur la fenêtre
Mieux vaut bas état sûr que royaume avec peur
Mieux vaut beau ventre que belle manche
Mieux vaut beaucoup de bis que peu de blanc
Mieux vaut belle manche que belle panse
Mieux vaut bien attendre que follement commencer
Mieux vaut bien et prestement mourir que longuement languir
Mieux vaut bien faire que bien dire
Mieux vaut bien parler que mal taire
Mieux vaut bien vivre que le promettre
Mieux vaut bon cul que bonnes culottes
Mieux vaut bon gardeur que bon amasseur
Mieux vaut bon gardeur que bon gagneur
Mieux vaut bon prochain voisin que parent lointain ni (ou) cousin
Mieux vaut bon que beau
Mieux vaut bon sommeil que bon lit
Mieux vaut bon éconduit que mauvais octroi
Mieux vaut bonne faim que bonne nourriture
Mieux vaut bonne fuite que mauvaise attente
Mieux vaut bonne renommée que ceinture dorée
Mieux vaut bouffée de clerc que journée de vilain
Mieux vaut bouillie restée que ventre crevé
Mieux vaut ce qu’est fait par nature que par aucun art ou figure
Mieux vaut celui qui est rapiécé que celui qui est troué
Mieux vaut celui qui piaule que celui qui est gaillard
Mieux vaut chanter loin que pleurer près
Mieux vaut chenu que chauve, sec et nu
Mieux vaut chômer que mal besogner
Mieux vaut comprendre peu que comprendre mal
Mieux vaut condamnation du médecin que de juge
Mieux vaut couard que trop hardi
Mieux vaut de l’amour plein le poing que de l’argent plein le four
Mieux vaut de main battu, que de langue féru
Mieux vaut de vertu trésor que d’or
Mieux vaut demander que faillir et errer
Mieux vaut des mains être battu que de langue être féru Féru = frappé, ferrere
Mieux vaut deux de blessés qu’un de mort
Mieux vaut deux pieds que trois échasses
Mieux vaut devoir son salut à une prompte retraite que de subir la loi du vainqueur
Mieux vaut dire « veux-tu du mien » que dire « donne-moi du tiens »
Mieux vaut du pain sec avec de l’amour que des poulets avec de la brouille
Mieux vaut décousu que rompu
Mieux vaut délier que couper
Mieux vaut eau du firmament que tout autre arrosement
Mieux vaut en corps douleur qu’en âme aigreur
Mieux vaut en paix un œuf qu’en guerre un bœuf
Mieux vaut enfants que maladies
Mieux vaut engin (ingéniosité) que force
Mieux vaut engin (ruse) que force
Mieux vaut engin (ruse) que force et bois qu’écorce
Mieux vaut enruiné qu’enhuilé
Mieux vaut espérer que se désespérer
Mieux vaut exciter le rire que la dérision
Mieux vaut faire envie que pitié
Mieux vaut faire gagner le boucher que le pharmacien
Mieux vaut faire la cour à toutes qu’à une seule et la perdre
Mieux vaut folier en herbe qu’en gerbe
Mieux vaut fontaine que citerne
Mieux vaut fou qui s’avise que sage qui s’abîme
Mieux vaut fromage maintenant que rôti dans une heure
Mieux vaut garder trente chèvres qu’une femme
Mieux vaut garder un âne que de tenir un cheval et de le faire crever de faim
Mieux vaut glisser du pied que de la langue
Mieux vaut goujat debout qu’empereur enterré
Mieux vaut gracieux que joli
Mieux vaut grands bras que grande langue
Mieux vaut habiter dans une terre déserte qu’avec une femme querelleuse
Mieux vaut heur et félicité que beauté
Mieux vaut heur que trop beau nom
Mieux vaut honte en face et visage que douleur en cœur ni courage
Mieux vaut juger entre ennemis qu’entre ses amis
Mieux vaut la cendre divine que du monde la farine
Mieux vaut la cendre du Souverain que la farine du faux monde et vain
Mieux vaut la huche au pain bien garnie que bel homme dans la rue
Mieux vaut la main plein d’amour que de richesses plein le four
Mieux vaut la paix certaine que la victoire espérée
Mieux vaut la rougeur au front que la peine au cœur
Mieux vaut la vieille voie que la nouvelle sente Nouvelle sente = nouveau sentier
Mieux vaut laisser la peau que le veau
Mieux vaut laisser sa femme morveuse que lui arracher le nez
Mieux vaut laisser son enfant morveux que de lui arracher le nez
Mieux vaut le chien vivant que le lion mort
Mieux vaut le laisser morveux que lui arracher le nez
Mieux vaut le mal à tort tolérer que mal perpétrer
Mieux vaut le plus mauvais fils que le meilleur gendre
Mieux vaut l’armoire que l’apothicaire
Mieux vaut l’honneur que le bonheur
Mieux vaut l’ombre d’un preud viellard que les armes d’un jeune cocard Preud = preux
Mieux vaut maintenant un œuf que dans le temps un bœuf
Mieux vaut marier sa fille que d’avoir du chagrin par la suite
Mieux vaut marié qu’estropié
Mieux vaut mendiant qu’ignorant
Mieux vaut monocle ou borgne qu’aveugle
Mieux vaut mourir avec fame et honneur que vivre à blâme et déshonneur
Mieux vaut mourir d’indigestion que de faim
Mieux vaut mourir qu’avoir toujours souffrance
Mieux vaut ne pas changer d’attelage au milieu du gué
Mieux vaut non savoir que mal savoir
Mieux vaut notre vie que la perdition d’autrui
Mieux vaut obédience que sacrifice
Mieux vaut os donné que os mangé
Mieux vaut ouïr chanter les oisillons que d’être enfermé ès prisons
Mieux vaut pain en huche qu’écu en paroi
Mieux vaut paix que victoire
Mieux vaut pauvre et homme de bien que riche et ne valoir rien
Mieux vaut payer et peu avoir que moult avoir et toujours devoir
Mieux vaut pays gâté que pays perdu
Mieux vaut perdre la toison que brebis, bélier ne (ou) mouton
Mieux vaut perdre la toison que le mouton et une fenêtre que la maison
Mieux vaut perdre l’occasion d’un bon mot qu’un ami
Mieux vaut perdre une fenêtre qu’une maison
Mieux vaut petit secours en lieu et temps que fors (sercours) accompli tard venant
Mieux vaut peu de biens avec suffissance que grande richesse avec concupiscence
Mieux vaut peu que rien
Mieux vaut plaire qu’être jolie
Mieux vaut plein la main d’amour que richesses plein un four
Mieux vaut plein poing de bonne vie que ne fait sept muid de clergé
Mieux vaut plein poing de bonne vie que ne fait un muid de clergé
Mieux vaut ployer que rompre
Mieux vaut ployer que rompre
Mieux vaut prochain ami que lointain parent
Mieux vaut promptement un œuf que demain un bœuf
Mieux vaut préserver notre vie que détruire autrui
Mieux vaut prévenir le mal que le braver
Mieux vaut prévenir que guérir
Mieux vaut prévenir que guérir
Mieux vaut péter que crever
Mieux vaut péter que crever et se marier que brûler
Mieux vaut péter que crever et se marier que de se brûler
Mieux vaut qui refuse et puis fait que qui accorde et rien ne fait
Mieux vaut quitter fenêtre que maison
Mieux vaut recevoir une pièce de mauvais aloi qu’un ami feint
Mieux vaut reculer que mal saillir
Mieux vaut refuser et puis faire qu’accorder et ne (rien) faire
Mieux vaut remède que conseil
Mieux vaut rencontrer une ourse privée de ses petits qu’un sot infatué de sa sottise
Mieux vaut rendre ses enfants vertueux que riches ne (ou) pécunieux
Mieux vaut repentance de son maléfice que persévérance en malice
Mieux vaut rester assis que mal danser
Mieux vaut rester sur sa faim qu’avoir des nausées
Mieux vaut rien que peu (ou mal) parler
Mieux vaut rire que pleurer
Mieux vaut roder que se noyer
Mieux vaut rustiquement vérité dire que civilement et facondement mentir
Mieux vaut règle que rente
Mieux vaut santé que science
Mieux vaut savoir que penser
Mieux vaut savoir qu’avoir
Mieux vaut science que force
Mieux vaut se fier à son courage qu’à la fortune
Mieux vaut se saouler que se casser une jambe
Mieux vaut se taire pour paix avoir que d’être battu pour dire voir
Mieux vaut se taire que de trop parler
Mieux vaut se taire que mal dire
Mieux vaut se taire que mal parler
Mieux vaut servir d’arbitre entre deux ennemis qu’entre deux amis, car l’un des amis deviendra un ennemi, et l’un des ennemis un ami
Mieux vaut servitude en paix que seigneurie en guerre
Mieux vaut seul que mal accompagné
Mieux vaut soi (se) taire que folie dire
Mieux vaut souffler que brûler
Mieux vaut souffler que se brûler
Mieux vaut souffrir de l’estomac que de l’esprit
Mieux vaut souffrir la puanteur que le risque d’être éborgné
Mieux vaut souffrir que mourir
Mieux vaut sous acheter que sous enprunter
Mieux vaut subtilité que force
Mieux vaut suer que tousser
Mieux vaut suer que trembler
Mieux vaut suer que trembler, le chaud est la vie, le froid la mort
Mieux vaut s’aimer un peu moins pour que l’amour dure plus longtemps
Mieux vaut s’arranger que de se battre
Mieux vaut taire que mal dire
Mieux vaut tard que jamais
Mieux vaut tenir le petit pour ami que le grand pour ennemi
Mieux vaut tenir que courir
Mieux vaut tirer viande dure que sentir viande pourrie
Mieux vaut tondre l’agneau que le cochon
Mieux vaut tondre l’agneau que le pourceau
Mieux vaut tourte de pain sur la table que miroir sur la fenêtre
Mieux vaut trop se taire que trop parler
Mieux vaut trésor d’honneur que d’or
Mieux vaut tâcher de rendre ses enfants sages et prudents que riches et opulents
Mieux vaut tôt mourir pour la liberté que longuement languir en captivité
Mieux vaut un bien lointain qu’un mal prochain
Mieux vaut un bon jour et un œuf qu’un grand méchant bœuf
Mieux vaut un bon marié qu’un mauvais prêtre
Mieux vaut un bon renom que de l’or au gousset
Mieux vaut un bon voisin qu’un mauvais parent
Mieux vaut un bonjour et un œuf, qu’un grand méchant bœuf
Mieux vaut un chien jeune qu’un homme malade
Mieux vaut un en la main que deux demain
Mieux vaut un enfant morveux qu’un enfant sans nez
Mieux vaut un estomac plein qu’un habit neuf
Mieux vaut un gigot voisin et prochain qu’un gras mouton lointain
Mieux vaut un morceau de pain avec la paix qu’une maison pleine de viande avec la discorde
Mieux vaut un pied nu que nul
Mieux vaut un pied que deux échasses
Mieux vaut un pied-nu que nul
Mieux vaut un pou dans les choux que point de viande
Mieux vaut un prenant que trente-six galants
Mieux vaut un proche voisin qu’un lointain parent
Mieux vaut un présent que deux après et dire attends
Mieux vaut un présent que deux attends
Mieux vaut un présent que deux et dire attends
Mieux vaut un présent que deux futurs
Mieux vaut un seul beau fait notable que maints petits incommendables
Mieux vaut un tenez que deux vous l’aurez
Mieux vaut un tiens que deux tu l’auras
Mieux vaut un trou à l’habit qu’une ride au ventre
Mieux vaut un âne sur terre qu’un savant dans (la) terre
Mieux vaut un œil que nul
Mieux vaut une belle garce qu’une laide pucelle
Mieux vaut une bonne fuite que mauvaise attente
Mieux vaut une fille faite qu’un gars à faire
Mieux vaut une fois bien finir que toujours peiner et languir
Mieux vaut une heurette de bonheur que de l’univers la faveur
Mieux vaut une main pleine de repos que les deux mains pleines de labeur et de poursuite du vent
Mieux vaut une miette de pain avec amour que poules grasses avec dolour
Mieux vaut une minute de bonne renommée qu’une vie incorrecte d’une siéclée
Mieux vaut une poignie de bonne vie que d’un muid de clergé
Mieux vaut une seule mouche à miel que cent bourdons sans miel
Mieux vaut user des souliers que des draps de lit
Mieux vaut vertu que force
Mieux vaut vertu souveraine que force humaine
Mieux vaut viande dure que semoule claire
Mieux vaut vieillesse honorée que jeunesse mal famée
Mieux vaut vivre vertueusement que naître noblement
Mieux vaut à cloche se lever qu’à la trompette
Mieux vaut échouer avec honneur que réussir par fraude
Mieux vaut être avec un veuf à manger son bien qu’avec un jeune homme à fricasser la pauvreté
Mieux vaut être avec vérité repris d’un ennemi que faussement loué du feint ami
Mieux vaut être couillon qu’aveugle
Mieux vaut être de Dieu aimé que de grand matin levé
Mieux vaut être empallé que mal marié
Mieux vaut être ennuyé qu’apitoyé
Mieux vaut être marteau qu’enclume
Mieux vaut être martyre que confesseur
Mieux vaut être médiocrement riche que désordonnément taquin et chiche
Mieux vaut être oiselet de bois ou de bocage que grand oiseau de cage
Mieux vaut être pendu que mal marié
Mieux vaut être petit pommier fécond et fruitier qu’un grand Liban sec, étendu loin le sentier
Mieux vaut être pour autrui riche que pour soi avare et chiche
Mieux vaut être que sembler homme de bien
Mieux vaut être rongé de vermine que de s’engraisser de rapine
Mieux vaut être sans fame que mensongèrement loué
Mieux vaut être saoul que bête
Mieux vaut être seul que mal accompagné
Mieux vaut être vertueux et bon que d’en avoir le seul renom
Mieux vaut, si tu hurles, avec les loups qu’avec les chiens
Mieux vaux rustiquement vérité dire que civilement et facondement mentir
Mieux vos champs seront épierrés, plus de grains vous recueillerez
Mil tots (tours) de roue toute la lieue du Bassigni et à la fin tombe par le chemin
Miroir de rue, fumier de maison
Misère amène noise
Misère et calamité, découvrent la vraie amitié
Modestie passe la beauté au sexe c’est nécessité
Modérer ses prétentions
Moindre mon espoir, plus grand mon amour
Moine apostat ne hait rien tant que cloître
Moine qui danse, table qui branle et femme qui parle latin, se renversent à la fin
Moins le bouc pue, moins la chèvre l’aime
Moins on sait, plus on croit
Mois de mai est le mois des chats
Mois de mai, mois des fleurs, mois des pleurs
Mois des fleurs, mois des pleurs
Moitié figue, moitié raisin
Mon ami est un autre moi (Cicéron, Amicus est tanquam alter idem) – D’où la locution
Mon coq est lâché, gardez vos poules
Mon coq est lâché, rentrez vos poules
Mon cul m’est plus proche qu’une chemise
Mon plus beau jour est celui qui m’éclaire
Mon plus proche parent, c’est moi-même
Monde = munde, pure Cf immonde = impur Cf mundus (latin) = pur
Montagne claire et femme fardée, ne sont pas de longue durée
Monter sur la vieille pour courir sur la fille
Montre-moi tes camarades et je te dirai tes habitudes ou mœurs
Montre-moi un menteur, je te montrerai un larron
Moquerie et le déspect, suit pas à pas la pauvreté
Morceau avalé n’a plus de vertu
Morceau qui plaît, à demi mâché
Morceaux petits et répétés remplissent le ventre fut-il difficile
Mort de loup, santé de brebis
Mort du louveau, santé de l’agneau
Mort d’abbé, noces de moines
Mort et vendition, rompent toute amodiation
Mort le chien, morte la rage
Mort ne mord
Mort n’a (pas d’)ami
Mort n’a ami
Mort n’a tort
Mort n’épargne ni petit ni grand
Mort trop désirée, vie de longue durée
Mort, mariage et vendition, gâtent toute amodiation
Morte est ma fille, perdu est mon gendre
Morte est ma fille, plus rien ne m’est mon gendre
Morte la bête, mort le venin
Morte la bête, mort le venin
Morte la couleuvre, mort le venin
Morte la fille, mort le gendre
Moult a affaire qui la mer (a) à boire
Moult dire et bien faire, n’est pas d’un même maître
Moult dépenser, rien gagner ni acquérir, fait l’homme en son pain guérir
Moult est chétif et fol niais, qui croit qu’ici soit son pays
Moult parler et rire font l’homme pour fol tenir
Moult parler nuit et moult gratter cuit
Moult remaint de ce que fol pense
Moult à dur cœur qui n’amollie, quand il trouve qui le supplie
Mourant affamé n’a pas d’oreilles
Mourir convient c’est chose seure (sûre) et ne savons le jour ni l’heure
Mourir est aussi l’un des actes de la vie
Mourir est toujours la dernière chose qu’on fait
Mourir glorieusement est un bienfait des dieux
Mourir jeune est affligeant, vivre vieux est inquiétant
Moyennement se voir cause amitié
Mule et femme, le bâton les améliore
Mules enfanter, chose impossible par nature
Muraille blanche, papier aux fols
Muraille blanche, papier de fol
Muraille blanche, papier de sots
Muraille écrite sert de peinture et de leçon
Mène ta gorge d’après ta bourse
Mère compâtissante fait fille teigneuse
Mère compâtissante fait les enfants crasseux
Mère compâtissante, enfant foireux
Mère piteuse fait fille teigneuse
Mère piteuse, fille teigneuse
Mère pleureuse, enfant hardi
Mère trop piteuse, fait sa famille teigneuse
Mère, pourquoi me marier ma fille, pour filer, enfanter et pleurer
Mères piteuses font leurs enfants teigneux
Méchant est le conseil qui n’a son déconseil
Méchant est le puits auquel il convient porter l’eau
Méchant ouvrier ne trouvera jamais bons outils
Méchant voisin, prochain venin
Méchante femme fait mauvais ménage
Méchante femme fait mauvais ménage
Méchante parole jetée, va partout à la volée
Méchante parole, le bon n’affole
Méchantes paroles ont méchant lieu
Méchants ouvriers ne trouvent jamais bons outils
Médecin compatissant, bourreau des malades
Médecin de village va à cheval mais s’en retourne à pied
Médecin et maréchal font mourir homme et cheval et les jettent à la fosse
Médecin trop compâtissant rend la plaie vénimeuse
Médecin, guéris-toi toi-même
Médecin, prêtre et fou, nous le sommes tous un peu
Médiocre et rampant, et l’on arrive à tout
Méfie-toi de la femme mariée qui porte trop de luxe
Méfie-toi de l’eau qui ne court pas et du chat qui ne miaule pas
Méfie-toi des chiens qui ont des dents, ils mordent
Méfie-toi des femmes qui se peignent la nuit
Méfie-toi du chien qui n’aboie pas
Méfie-toi d’eau qui ne court pas et de femme qui ne prie pas
Méfiez-vous de l’homme qui se tait et du chien qui n’aboie pas
Méfiez-vous de qui a les lèvres souillées de vin
Méfiez-vous des vanteurs
Méfiez-vous des yeux qui regardent pas
Mélancolie fait malade le sain et le malade mourir
Mémoire du bien tôt se passe
Mémoire du mal a longue trace
Mémoire du mal a longue trace, mémoire du bien tantôt passe
Mémoire est mère de sagesse
Mémoire et usage, rendent l’homme sage
Mémoire s’avachit sans exercice
Ménages séparés, à l’enfer condamnés
Ménagère qui suit les bals, laisse brûler la viande
Mépriser la renommée, c’est mépriser les vertus
Métier d’auteur, métier d’oseur
Mêle à ta sagesse un grain de folie; il est bon de faire à propos quelque folie
Même aux yeux de l’injuste un injuste est horrible
Même avec cent livres de moins, épousez l’aînée
Même laide, si elle a des écus, une jeune fille trouve à se marier
Même quand la blessure guérit, la cicatrice demeure
Même si deux hommes font la même chose, le résultat n’est pas le même
Même si les yeux ne dorment pas, au lit les os reposent
Même si on est outragé, on ne peut haïr ses enfants
Même un cheveu a son ombre
Même à son ennemi, on doit tenir parole
Naissance d’un garçon est accroissement de bien, celle d’une fille est appauvrissement de la maison
Nature a comparti à tous animaux, forcer de se pouvoir garantir
Nature a pourvu à plusieurs choses d’une arme défensive
Nature a produit à toute bête son ennemi
Nature envy (difficilement) se déguise
Nature est contente de peu
Nature excelle doctrine et lecture
Nature fait chien chasser
Nature fait le chien tracer
Nature ne peut mentir
Nature ne se peut déguiser
Nature n’a fait chose tant sublime, dont vertu n’en vienne à chef et cime
Nature n’est que le chaos
Nature peut tout et fait tout
Nature répugne à son inégale
Ne (ré)veille point le chat qui dort
Ne baisotte pas ta chambrière, de peur qu’elle ne prenne vanité, croyant devenir la maîtresse de la maison
Ne brûle pas ta maison pour en chasser les souris
Ne bâtis pas ta maison sous les rochers ni le long de l’eau
Ne chaloir à qui brûle la maison, mais qu’on se chauffe bien
Ne cherchez jamais à employer l’autorité là où il ne s’agit que de raison
Ne choisis l’or, la toile et une femme qu’en plein jour
Ne clame pas tout ce qu’on te chante
Ne clocher devant un boiteux
Ne clochez pas devant les boiteux
Ne compte pas le prix du beurre avant (d’)avoir acheté la vache
Ne compte pas les œufs au cul de la poule
Ne comptez pas sur ses promesses, il vous pétera dans la main
Ne confie jamais un secret à un valet, parce que c’est toi qui es valet après
Ne confie pas ta farine à qui lèche ta cendre
Ne convoite point l’avoir d’autrui
Ne coupe pas la barbe au chat, par les souris il serait pris
Ne crie après personne, tu seras aimé d’un chacun
Ne crois de léger
Ne crois pas que du bois que tu coupes tout le monde se chauffe
Ne crois pas toujours qu’on te regarde de derrière les volets qu’il n’y a personne
Ne crois pas tout ce que tu ois
Ne danse pas tout ce qu’on te chante
Ne devient pas âgé qui veut
Ne dis jamais que tu as femme belle ou de l’argent dans l’escarcelle
Ne dis pas de mal du médecin, tu peux en avoir besoin
Ne dis pas tout ce que tu sais et penses
Ne dis pas tout ce que tu sais ni ne mange tout ce que tu peux manger
Ne dis pas « hue! » avant d’être en haut la montée
Ne dis pas ‘you!’ avant que d’être de l’autre côté de l’eau
Ne dis pas »c’est impossible »,dis je ne sais pas
Ne dites rien de ce que je vous ai dit
Ne donne jamais l’éperon à cheval qui volontiers trotte
Ne donne pas ta fille à un oiseleur ou à un pêcheur
Ne donne pas tant à Saint Pierre, que Saint Paul demeure derrière
Ne donne pas tout ce que tu as
Ne donne ta fille à un pêcheur à la ligne ni à un chasseur de vigne
Ne donne ton cœur à personne avant d’avoir mangé avec lui un décalitre de sel
Ne décidons jamais où nous ne voyons goutte
Ne déplaire à personne nourrit l’homme en santé
Ne désirer que ce qu’on a, c’est avoir tout ce qu’on désire
Ne faire mal à son ennemi, mais quand mal lui vient on s’éjouit
Ne faire messager de fols
Ne faire point de déplaisir et on ne s’en souviendra jamais
Ne faire son déjeuner de ce que le chat ne veut point
Ne fais pas aller trop chargée l’ânesse pleine
Ne fais pas d’un fol ton messager
Ne fais pas passer des ciboulettes pour du persil au marchand de légumes
Ne fais pas ton nid à côté d’un château
Ne fais pas tout ce que tu peux
Ne fais pas un four de ton bonnet ni de ton ventre un jardinet
Ne faites pas aux autres ce que vous ne voudriez pas qu’ils vous fassent
Ne faut bâtir sa maison d’arrête de poisson
Ne faut jamais dire le malade être guéri, si l’on n’a vu le malade partir
Ne faut jamais, pour ne pas se tromper, vendre la peau de l’ours avant de l’avoir tué
Ne faut pas apprendre à chier à ceux qui ont la diarrhée
Ne faut pas attendre que les alouettes tombent aval la borne
Ne faut pas autour du feu tourner trop le cul
Ne faut pas briser le pont quand on a passé le flot
Ne faut pas bâcler pour bien avancer, inutile de traire avant de manier
Ne faut pas croire aux saints qui pètent
Ne faut pas dire hue avant d’avoir passé le ru
Ne faut pas enfourner plus qu’on ne peut cuire
Ne faut pas faire aux autres ce qu’on ne voudrait pas qu’ils vous fassent à soi-même
Ne faut pas ficher ses doigts par toutes les fentes
Ne faut pas juger de l’arbre par l’écorce
Ne faut pas mettre la charrue devant les bœufs
Ne faut pas mettre tous ses œufs dans le même panier
Ne faut pas ourdir plus qu’on ne peut tramer
Ne faut pas piler le poivre avant d’avoir le lièvre
Ne faut pas plus de femmes dans une maison qu’il y a de fourneaux
Ne faut pas plus de femmes à souper que de crémaillères à la cheminée
Ne faut pas plus de tiroirs que de tables dans une maison
Ne faut pas plus de tonneaux que de maîtres dans une maison
Ne faut pas péter plus haut que le cul
Ne faut pas réveiller le chat qui dort
Ne faut pas se déshabiller avant de se mettre au lit
Ne faut pas se dévêtir avant de s’aller coucher
Ne faut pas souffrir avant qu’il en soit temps
Ne faut pas suivre le loup jusqu’au bois
Ne faut pas s’amuser avec les fous
Ne faut pas troquer son cheval borgne contre un non-voyant
Ne faut pas vendre la peau de l’ours avant de l’avoir tué
Ne faut pas voir les prés par la rosée ni les filles à la chandelle
Ne faut pas écorcher tout ce qui est gras
Ne faut pas, autour du feu, tourner trop le cul
Ne faut personne payer pour médire
Ne faut point de bottes à celui qui ne chevauche point
Ne faut porter que pour rapporter
Ne faut qu’une étincelle pour allumer un grand feu
Ne flatte nulluy
Ne font lessive que les pouilleux
Ne frappe jamais coup que tu n’en abattes
Ne furent jamais si grosses noces qu’il n’en n’y eut des mal dînés
Ne fut le mauvais vent et femme sans raison, jamais n’aurions mauvais temps, journée ni saison
Ne joue point au fol, endure ce qu’il dit ou fait
Ne jouons pas avec les grands, le plus doux a toujours des griffes à la patte
Ne juge pas tout ce que tu vois
Ne jugez point et vous ne serez point jugés
Ne jure et ne paillarde point
Ne la main (met) en bourse d’autrui
Ne laisse l’étoupe près des tisons ni les jeunes filles près des garçons
Ne laisse ni l’étoupe près du feu ni les jeunes filles près des jeunes gens
Ne laisse pas aller l’épervier que tu tiens sur la perche pour l’espérance d’un autour qui te doit venir
Ne laisse pas une bonne chair pour en manger une mauvaise
Ne loue jamais ton vin, ta femme, ton cheval, de peur que les autres les désirent
Ne loue jamais ton vin, ta femme, ton cheval, de peur qu’un autre en ait envie
Ne mange pas tout ton pain blanc le premier
Ne mange pas viande crue, ne va pas jambes nues
Ne manger que pour se garder de mourir
Ne marie ni un buveur ni un jureur
Ne mets pas tous tes œufs dans la même corbeille
Ne mets ton doigt en anneau trop étroit
Ne mettez jamais le doigt dans un anneau trop étroit
Ne mettez pas votre doigt entre l’écorce et l’arbre
Ne meus point la fange
Ne médire de personne, sa renommée demeure bonne
Ne méprise ton ennemi, tant soit petit comme fourmi
Ne nous associons qu’avec que nos égaux
Ne parlant point d’autrui, on ne lui rapporte rien
Ne parle mal des trépassés
Ne parle pas de corde dans la maison d’un pendu
Ne parle sans en être requis, si veux être en estime et prix
Ne pas prendre de risques
Ne pense pas au beurre avant d’avoir la chèvre
Ne pense, dis et ne fais, ce qu’à Dieu déplaît
Ne pleure pas ce que tu n’eus oncques
Ne pleut que ne dégoutte
Ne porte pas la pâte au four pour les autres
Ne porte point faux témoignage
Ne poursuivez pas le vent qui emporte votre chapeau
Ne prend pas le cul à Marijeanne si Mina n’est pas là
Ne prends pas tout ce que tu désires
Ne profite pas ce qui se mange mais ce qui se digère
Ne pèse pas ton aumône
Ne quitte pas le manteau si tu as chaud, ne pars pas sans la gourde s’il fait froid
Ne remettez jamais à demain ce que vous pouvez faire le jour même
Ne renvoie jamais à demain ce que tu peux faire aujourd’hui
Ne renvoie pas à demain ce que tu peux faire aujourd’hui
Ne reprends ce que n’entends
Ne romps l’œuf mollet avant que ton pain soit prêt
Ne romps l’œuf mollet avant qu’avoir fait tes apprêtes
Ne rompt l’œuf mollet, si ton pain n’est apprêté
Ne ronge pas trop longtemps le même os
Ne réveille point le chat qui dort
Ne réveillez pas le chien qui dort
Ne se soucie du fait d’autrui, amène bon repos chez lui
Ne siffle pas dans la côte, si tu as peur de voir arriver le loup
Ne sois pas comme celui qui donne et qui revoudrait
Ne sois pas toujours là rien que pour dire Amen
Ne sois point hâtif
Ne sois point langagier
Ne sois point paresseux, si ne veux être disetteux
Ne soit point à autrui qui peut être à lui-même
Ne souffle pas sur le feu qui ne brûle pas
Ne souffre à ta femme pour rien de mettre son pied sur le tien, car le lendemain la pute bête le voudrait mettre sur ta tête
Ne soyez honteux que d’être honteux
Ne te couvre pas de la peau du loup, si tu ne veux pas être réputé loup
Ne te fais ennemi de grand, car le petit donne bien malhan
Ne te fais jamais le fou des gens
Ne te fais pas aimer, fais-toi craindre
Ne te fie de (à) l’ami réconcilié
Ne te fie de menteur ni de vent, car bien fol est qui s’y attend
Ne te fie en personne, même pas à ta chemise
Ne te fie ni aux femmes ni aux sous
Ne te fie pas aux serments des maquignons et des mendiants
Ne te fie pas en tout le monde
Ne te fie pas à un cheval qui transpire, à un homme qui jure ni à une femme qui pleure
Ne te fie point et tu ne seras point trompé
Ne te flatte de femme belle ni d’écus dans ton escarcelle
Ne te mange pas par les deux bouts
Ne te mets pas entre deux pierres qui roulent
Ne te moque des maux (mal) chaussés
Ne te prends ni harpe au potier, qui de terre vile fait le denier
Ne te trouve pas trop tard au four pour demander à cuire
Ne te vante pas, on ne te croirait pas Ne te décrie pas, on te croirait trop
Ne touche pas le chaudron, tu te remplirais de suie
Ne tue et n’homicide point
Ne t’amuse pas à prêter ton argent à celui à qui tu serais obligé après de le demander le chapeau au poing
Ne t’arrête à nulle tentation, ne t’émoie pour nulle tribulation, ne t’élève pour nulle consolation
Ne t’attends qu’à toi seul
Ne t’attriste de rien et ta vie sera longue
Ne t’y fie qu’à bonnes enseignes
Ne va aux foires et aux marchés que pour les affaires, il y aura toujours assez de fainéants, d’ivrognes et de gourmands sans toi
Ne va avec un âne que si tu as quelque chose à porter
Ne vante pas le mariage le troisième jour, mais la troisième année
Ne veille (réveille) point le chat qui dort
Ne veuille devenir à coup (tout à coup) opulent, à ce que ne soit soudain indigent
Ne vis pas seulement pour manger, mange seulement pour durer
Ne vous fiez ni au chien silencieux ni à l’eau dormante
Ne vous fiez pas aux apparences
Ne vous fiez pas aux larmes d’un fou, il rit et pleure à volonté
Neige au blé est bénéfique, comme au vieillard la bonne pelisse
Net de corps, net d’âme
Netteté nourrit la santé
Neuf buveurs de cidre, neuf chasseurs et neuf parleurs de fête, ne sont pas capables de nourrir une femme
Nez avec boutons, nez aviné
Nez de géline aime à gratter
Nez qui flaire, homme gourmand
Ni eau ni femme ni aronde (hirondelle), en ta maison ne s’y abondent
Ni en bru bavarde, ni en vigne voisine du chemin, ni en champ qui borde une rivière, ni en maison proche de couvent, n’emploie ton argent
Ni femme ni toile, il ne faut acheter à la chandelle
Ni femmes près d’hommes ni étoupe près de tisons
Ni grain de lieu marécageux ni bois de lieu ombrageux
Ni gras poussin ni sage Breton
Ni homme à voix de soprano ni femme à voix de basse
Ni jeune médecin ni vieux barbier
Ni la femme ni la toile, ne les considérez à la chandelle
Ni la filasse près du tison ni la fillette près du garçon
Ni la pauvreté ne peut avilir les âmes fortes, ni la richesse ne peut élever les âmes basses
Ni les étoupes proches aux tisons ni moins les filles près des barons
Ni l’or ni la grandeur ne nous rendent heureux
Ni l’étoupe près du feu ni la femme près de l’homme
Ni maison d’angle ni femme au balcon
Ni pantalons la femme ni jupes l’homme
Ni par beau temps ni par mauvais temps, ne laisse la cape et le goûter
Ni par beau temps ni par mauvais temps, ne laisse ta cape en arrière
Ni par mauvais ni par beau, en hiver ne quitte ton manteau
Ni par pluie ni par beau, ne laisse ton manteau
Ni peu ni trop
Ni si jolie qu’elle tue, ni si laide qu’elle effraie
Ni tellement jolie qu’elle tue, ni tellement laide qu’elle épouvante
Ni trop de filles ni trop de vignes
Ni un cheval ni un lièvre courent si vite qu’une dette
Ni vous sans moi, ni moi sans vous
Ni âne de roulier (= transporteur) ni fille d’hôtelier
Nid tissu (tissé) et achevé, oiseau perdu et envolé
Noble cœur d’homme ne doit point enquérir du fait des femmes
Noble est qui noblesse ne blesse et n’oublie et vilain qui commet vilénie
Noblesse oblige
Noir terrien porte grain et bien et le blanc ne porte rien
Noire chatte a le poil souef
Noire chatte a souef poil
Noire géline pond blanc œuf
Noire géline pond blancs œufs
Noix et femme, celle qui se tait est bonne
Noix, filles et châtaignes, les hardes couvrent la malice
Non d’où tu es, mais d’où tu pais
Non en la canne (à pêche) ni au haim, (en l’hameçon) (au crochet), mais en l’amorce gît l’engain
Non en la canne ni au haim, mais en l’amorce gît l’engain
Nonne qui danse, table qui branle, femme qui parle latin, ne firent jamais bonne fin
Nonne qui danse, table qui branle, femme qui parle latin, n’ont jamais fait bonne fin
Nos chimères sont ce qui nous ressemble le mieux
Nos estomacs sont nos maîtres
Nos plus sûrs protecteurs sont nos talents
Nos vertus ne sont le plus souvent que des vices déguisés
Notaire, putain et barbier, paissent en un même pré et vont tous par un même sentier
Notre bonheur n’est qu’un malheur plus ou moins consolé
Notre demeure n’est ferme ni sûre
Notre défiance justifie la tromperie d’autrui
Notre ennemi, c’est notre maître
Notre esprit a toujours quelque « mais » en réserve
Notre intérêt est la boussole que suivent nos opinions
Notre meilleur ami, c’est encore le travail
Notre mérite nous attire l’estime des honnêtes gens, et notre étoile celle du public
Notre repentir n’est pas tant un regret du mal que nous avons fait, qu’une crainte de celui qui nous en peut arriver
Notre repentir vient trop tard, quand il ne peut remédier au mal
Notre vie et notre mort, est en la puissance du Seigneur fort
Notre vie s’écoule et s’évanouit tacitement
Nourris bien ton cochon, si tu veux de la bonne viande
Nourris le corbeau, il te crèvera les yeux
Nourris ton cheval comme tu veux qu’il tire
Nourris-moi de la chair d’aujourd’hui, du pain d’hier, et du vin de l’année passée, et je dirai adieu aux médecins
Nourris-moi de la viande d’aujourd’hui, du pain d’hier et du vin de l’an passé, et médecin allez-vous en
Nourrissez bien vos vaches et la crême restera sur le lait
Nourriture abondante se noie avec du vin
Nourriture passe nature
Nourriture passe nature
Nourriture, pourriture
Nous aimons quelquefois jusqu’aux louanges que nous ne croyons pas sincères
Nous aimons toujours ceux qui nous admirent, et nous n’aimons pas toujours ceux que nous admirons
Nous aurions souvent honte de nos plus belles actions si le monde voyait tous les motifs qui les produisent
Nous avons d’assez bons préceptes, mais peu de maîtres
Nous avons joui du bon, pourquoi rejetons-nous le fond ?
Nous avons tous assez de force pour supporter les maux d’autrui
Nous convenons de nos défauts, mais c’est pour que l’on nous démente
Nous convenons volontiers d’un mérite qui n’est pas celui que nous devons avoir
Nous défendre quelque chose, c’est nous en donner envie
Nous faisons cas du beau, nous méprisons l’utile
Nous gagnerions plus de nous laisser voir tels que nous sommes que d’essayer de paraître ce que nous ne sommes pas
Nous méprisons beaucoup de choses, pour ne pas nous mépriser nous-même
Nous ne croyons le mal que quand il est venu
Nous ne racontons que nos maux
Nous ne somme pas si misérables comme nous sommes vils
Nous ne sommes pas ici pour enfiler des perles
Nous ne sommes pas ici pour ne rien faire de sérieux, pour ne nous occuper que de bagatelles
Nous ne sommes savants que de la science présente
Nous ne trouvons guère de gens de bon sens que ceux qui sont de notre avis
Nous nous corrigeons moins de nos défauts que de nos qualités
Nous n’aurons pas un jour de bon tant que nous serons pas morts et puis alors nous savons pas qui nous rencontrerons
Nous n’avons part à la gloire de nos ancêtres qu’autant que nous nous efforçons de leur ressembler
Nous n’avons pas assez de force pour suivre toute notre raison
Nous n’avons pas assez d’amour-propre pour dédaigner le mépris d’autrui
Nous n’avons que notre vie en ce monde
Nous n’avouons de petits défauts que pour persuader que nous n’en avons pas de grands
Nous pardonnons souvent à ceux qui nous ennuient, mais nous ne pouvons pardonner à ceux que nous ennuyons
Nous parlons de nos petits défauts, pour qu’on ne voie pas les gros
Nous passons, ce que nous avons fait demeure
Nous plaisons plus souvent dans le commerce de la vie par nos défauts que par nos bonnes qualités
Nous promettons selon nos espérances et nous tenons selon nos craintes
Nous querellons les malheureux, pour nous dispenser de les plaindre
Nous sommes instruits des animaux, de conserver, vertir et hanter les savants
Nous sommes instruits par doctrine évangélique, que les ennemis de l’homme sont ses domestiques
Nous sommes la terre, Dieu est le potier
Nous sommes rien que fermiers du bien
Nous sommes tant après l’autrui, que nous en perdons le nôtre
Nous sommes tous de chair et d’os
Nous sommes tous de la même matière, mais nous ne sommes pas tous de la même manière
Nous sommes tous de la même terre, lorsque nous n’avons pas été creusés dans la même manière
Nous sommes tous sous le même soleil
Nouveau roi, nouvelle loi
Nouveaux mariés, ça leur cuit à la bourse
Nouvel amour, nouvelle aversion
Nouvelle cheminée est bien tôt (bientôt) enfumée
Nouvelle cheminée est bientôt enfumée
Nouvelle femme, nouvel argent
Noyer, femme et âne ont de loi même lien, toutes trois les coups cessants jamais ne feront rien
Noël au balcon, Pâques au tison
Nues et vents, sans pleuvoir
Nul bien délicieux ni apprécié, s’il n’est communiqué et divulgué
Nul bien ni honneur, sans peine et labeur
Nul bien sans mal vient
Nul bien sans peine
Nul bienfait perdu
Nul blasonner grain ne devroit (devrait), de l’art auquel n’est bien adroit
Nul bois sans écorce
Nul chevalier sans prouesse
Nul contraire sans son adversaire
Nul en prix en son pays
Nul endroit sans son envers
Nul grain sans sa paille
Nul grand dormir sans songe acquérir
Nul homme sans somme
Nul humain sans méhaing
Nul jour n’est qui n’ait vespre
Nul jour sans soir
Nul jour sans trait de ligne ou quelque tour
Nul jour sans trait ou labour
Nul mal demeure impuni et nul bien fut oncques péri
Nul mal et nul bien, sans peine ne vient
Nul mal sans aucun bien
Nul miel sans fiel
Nul ne dise son secret à femme folle et enfant
Nul ne dois faix entreprendre, s’il ne le peut porter
Nul ne doit désirer plus qu’il n’a, de peur de perdre ce qu’il a
Nul ne doit faix entreprendre qu’il ne puisse bien porter
Nul ne doit faix entreprendre, si ne le peut bien porter
Nul ne doit être témoin ouï ni en sa propre cause avoir audit
Nul ne donne ce qu’il n’a point
Nul ne fait si bien l’œuvre que celui à qui elle est
Nul ne fait si bien sa besogne que celui à qui elle est
Nul ne gouverne son maître si ne manie sa bourse
Nul ne mange de l’oie du roi que cent ans après il ne rende la plume
Nul ne naît appris et instruit
Nul ne part son fromage, qui n’y ait honte ou dommage
Nul ne part son fromage, qu’il n’y ait honte ou dol ou dommage
Nul ne parvient à la vieillesse, qui n’a passé par la jeunesse
Nul ne perd que autrui ne gagne
Nul ne perd que l’autre n’y gagne
Nul ne perd qu’autrui ne gagne
Nul ne peut bien à deux maîtres servir, ni la grâce de chacun desservir
Nul ne peut donner ce qu’il n’a pas
Nul ne peut haïr la musique s’il n’est sourd
Nul ne peut servir deux maîtres
Nul ne peut servir à deux seigneurs
Nul ne peut être bienheureux, s’il n’est sage, bon et vertueux
Nul ne peut être bon maître, qui n’a été bon valet
Nul ne peut être sage ne (ou) prudent qui ne souffre et n’est patient
Nul ne peut être sage ni prudent, qui ne souffre et n’est patient
Nul ne peut être vrai ami, qui pense un temps être ennemi
Nul ne pèle son fromage, qu’il n’y ait perte ou dommage
Nul ne sait ce que c’est que la guerre s’il n’y a pas son fils
Nul ne sait ce que lui pend au nez
Nul ne sait mieux quel soit le poids de pauvreté que celui qui l’a éprouvé
Nul ne sait nommer son père
Nul ne sait que c’est que de bien qui n’a enduré du mal
Nul ne sait qui vit ni qui meurt
Nul ne sait qu’il ne l’essaye
Nul ne sait qu’à l’œil lui pend
Nul ne se croit laid
Nul ne se doit louer ni moins blâmer, les faits font l’homme tel qu’il est réclamer
Nul ne se doit vanter d’avoir ami trouvé, si auparavant ne l’a très bien éprouvé
Nul ne vienne demain, qui n’apporte son pain
Nul ne vienne demain, s’il n’apporte son pain
Nul ne voit jamais si clair aux affaires d’autrui que celui à qui elles touchent le plus
Nul noble sans noblesse, nul chevalier sans prouesse
Nul n’a puissance de tollir (enlever, retirer) aux gens leur penser
Nul n’amende s’il ne méfait
Nul n’est bien heure (heureux) avant qu’il soit enterré
Nul n’est contant de ce qu’il a
Nul n’est content de sa fortune, ni mécontent de son esprit
Nul n’est content de son sort
Nul n’est d’autrui à droit déprisé, qui premièrement ne se déprise
Nul n’est heureux que le gourmand
Nul n’est poète sans art
Nul n’est prophète en son pays
Nul n’est prophète en son pays
Nul n’est riche qui n’ait métier (aie besoin) d’amis
Nul n’est riche qu’il n’ait métier d’amis
Nul n’est si large que celui qui n’a que donner
Nul n’est si riche qu’il n’ait métier d’amis
Nul n’est tenu à l’obligation faite par contrainte ou par déception
Nul n’est trop bon et peu le sont assez
Nul n’est vilain si du cœur ne lui vient
Nul n’est vilain, si le cœur ne lui meurt
Nul n’est à l’abris du temps
Nul or sans écume
Nul pain sans peine, nul bien sans haine
Nul plaisir sans déplaisir
Nul poulain n’est sans méhain
Nul péché n’est si celé, qu’en la fin ne soit révélé
Nul royaume en autrui contrée, est sûr et de longue durée
Nul samedi sans soleil
Nul sang blanc
Nul si fin que femme n’assote
Nul style, art, métier ni boutique, qui n’ait larron en sa pratique
Nul trop n’est bon ni bon assez
Nul trop n’est bon, nul peu n’est assez
Nul vice sans son supplice
Nul vieil (vieux) vêtement sans poux
Nul vin sans lie
Nulle amitié sans crainte
Nulle belle fille sans amour et nul vieillard sans dolour
Nulle douceur sans labeur
Nulle farine sans son
Nulle femelle ne cherche le mâle hors du printemps sauf la femme
Nulle femelle ne recherche le mâle passé le printemps, sauf les femmes
Nulle grande cité ne peut être longuement en paix, car si elle n’a un ennemi étranger, ne lui manquera le familier
Nulle heure est tant heureuse, qu’inheureuse ne soit
Nulle laide jeunesse
Nulle maison sans croix ou passion
Nulle montagne sans vallée
Nulle muse sans son excuse
Nulle noblesse de paresse
Nulle noix sans coque
Nulle putain sans rufian
Nulle reine sans sa voisine
Nulle rose sans épine
Nulle souris sans pertuis
Nulle terre sans guerre
Nulle vertu sans fatigue, qui la veut qu’il la brigue
Nulles heures sont bonnes
Nullui sans blasme
Nuls biens sans peine
Nuls vifs (vivants) sans vices
Nus, nous sommes tous les mêmes
Nécessité abaisse gentilesse
Nécessité apprend les gens
Nécessité apprend les gens
Nécessité est de raison la moitié
Nécessité fait gens méprendre
Nécessité fait loi
Nécessité fait vieille trotter
Nécessité n’a loi
Nécessité n’a loi, foi ni roi
Nécessité n’a pas de loi
Nécessité n’a point de loi
Nécessité rabaisse gentilesse
Nécessité rend magnanime, le couard et pusillanime
N’a de plaisir qui ne s’en donne
N’a pas besoin d’avoir tant d’amis, s’ils sont bons
N’a rien fait, n’a rien peur
N’achète cheval jouant de la queue
N’agace pas un guêpier, si tu as peur des guêpes
N’aie point peur de ton dernier trépas, car qui le craint languit et ne vit pas
N’aille à laver la lessive qui a les pieds faits de sel
N’arrive ni trop tôt ni trop tard
N’attelez pas tous vos bœufs à la même charrue
N’attelle pas ensemble l’âne et le cheval
N’avoir que du pain frais à manger et des filles à marier, la maison ne peut que baisser
N’ayez d’intolérance que vis-à-vis de l’intolérance
N’ayez ni trop de vignes ni trop de filles ni trop de maisons dans les villes pauvres
N’ayez pas trop de filles ni trop de vignes
N’empêchez pas les folles de rire, ni les enfants d’aller aux cerises
N’en faut pas prendre plus que pour son argent
N’en faut pas prendre plus qu’on en peut porter
N’espère aucun bien d’homme chiche
N’espérer que paradis
N’est pas bon de mettre tous ses œufs dans le même panier
N’est pas fou qui des folies fait, mais fou qui (ne) s’amende pas
N’est pas homme qui ne prend somme
N’est pas la peine d’attendre qu’on ait plus de dents pour aller aux noisettes
N’est pas lait tout ce qui blanchoie
N’est pas le tout de promettre, il faut tenir
N’est pas le tout de se lever matin, faut encore arriver à temps
N’est pas le tout de se lever matin, faut encore partir assez vite
N’est pas le tout de se lever matin, faut encore se bouger
N’est pas marchand qui toujours gagne
N’est pas mort qui combat
N’est pas nécessaire de louer celui qui se loue
N’est pas pauvre, qui a deux bons bras
N’est pas perdu quanque (quand) en péril gît
N’est pas prêt qui commence
N’est pas que les gros bœufs qui brassent la terre
N’est pas rien que les gros bœufs qui labourent la terre, les petits font bien leur part
N’est pas sage qui a peur du fou
N’est pas seigneur de son pays, qui de ses sujets est haï
N’est pas sire de ses pays, qui de ses hommes est haï
N’est pas toujours fête quand les cloches sonnent
N’est pas tous les jours fête, quand même les cloches sonnent
N’est pas tout de pétrir, faut encore enfourner
N’est pas tout perdu, quand en péril gît
N’est pas tout que se lever matin, faut arriver à l’heure
N’est pas voleur celui qui voleur vole
N’est rien de prêter aux gens qui retournent
N’est si masle (mauvaise) chose qui n’aide ni si bonne qui ne nuise
N’humilie pas qui veut
N’oublier rien pour dormir
N’usez que de pièces d’or et d’argent dans le commerce de la parole
N’y a pas de gens plus à plaindre que ceux qui savent pas faire droit
N’y a point de terre sans drachée
N’y pense plus, tu l’auras
N’écorche pas ta bête avant qu’elle soit saignée
N’écoutez jamais les harangues de ceux qui portent doubles langues
N’émeut point la fange
N’épargnons la chair, qui pourrira en terre
N’être ni pour un ni pour autre
Obéissez à vieux et ne vieillissez pas avec eux
Occasion trouve qui son chat bat
Oignez vilain, il vous poindra
Oignez vilain, il vous poindra Poignez vilain, il vous oindra
Oins le vilain, il te poindra Poins-le, il t’oindra
Ois, vois et te tais, si (tu) veux vivre en paix
Oiseau ne peut voler sans ailes
Oiseau qui chante n’a pas soif, agneau qui bêle veut téter
Oisiveté est mère d’impudicité
Oisiveté, chancre de santé
Oisiveté, chancre de tout bien et de santé
Olive, une est de l’or, deux de l’argent et la troisième tue
Omettre de bien faire est à raison contraire
On (de)vient fou en (de)venant vieux
On (ne de)vient pas riche sans rien faire
On (ne) peut pas attacher tous les chiens
On (ne) peut pas cueillir de farine de froment dans un sac de charbon
On (ne) peut pas sortir de la farine blanche d’un sac de charbon
On (ne) sort pas de la farine blanche d’un sac de charbon
On (ne) vit pas de l’air du temps
On a assez à balayer devant sa porte
On a aussitôt reconnu un menteur qu’un boiteux
On a beau abreuver le bœuf, s’il n’a pas soif
On a beau graisser les souliers à un vilain, ils restent toujours rouges
On a beau mener le bœuf à l’eau, s’il n’a soif
On a beau prêcher qui n’a cure de bien faire
On a beau savonner la tête d’un âne, elle reste toujours grise
On a besoin pour vivre de peu de vie, il en faut beaucoup pour agir
On a de la fortune sans bonheur, comme on a des femmes sans amour
On a divers sujets de mépriser la vie, mais on n’a jamais raison de mépriser la mort
On a fait l’Amour aveugle, parce qu’il a de meilleurs yeux que nous
On a jamais mauvais marché de bonne denrée
On a le renom qu’on se fait
On a néant pour néant
On a peine à haïr ce qu’on a bien aimé
On a plus aisément de l’or que de l’esprit
On a plus de mal à se damner qu’à se sauver
On a plus de mal à suivre la cour qu’à se sauver
On a plus de maux de crier merci que d’offenser
On a plus tôt fait la folie que le sens
On a plus vite déroché que monté
On a plutôt appris une langue en cuisine qu’en une école
On a souvent besoin d’un plus petit que soi
On a souvent à se repentir d’avoir trop parlé
On a tous assez à faire chez soi
On a tous des croix à porter
On a tous les ans douze mois
On a tous sa place au soleil
On a tous une croix à porter ou bien à traîner
On a vite assez de tout que de l’honneur
On a vite de tout assez que de l’honneur
On affaiblit toujours ce qu’on exagère
On aide bien au bon Dieu à faire de bon blé
On aime aussi bien la femme qui a quelque chose que celle qui n’a rien
On aime le service et non pas les serviteurs
On aime les grands parce qu’ils peuvent donner
On aime l’empereur pour l’amour de l’empire
On aime mieux dire du mal de soi-même que de n’en point parler
On aime mieux son égal que son maître
On aime mieux un batteur en grange qu’un buveur
On aime sans raison, et sans raison l’on hait
On aime trahison, non pas les traîtres
On aime à deviner les autres, mais l’on n’aime pas à être deviné
On apprend plus vite le mal que le bien
On apprend rien que (qui) coûte
On apprend rien sans qu’il ne coûte
On apprend tous les jours quelque chose
On attrape des vices à tout âge
On attrape les merles en pipant et les maris en filant
On attrape plus vite un menteur qu’un boiteux
On attrape plus vite un menteur qu’un voleur
On aura jamais bon âne vieux
On aura toujours plus de terre que de vie
On aura tous assez de terre pour se couvrir
On aurait souvent besoin d’être comme les escargots, d’avoir les yeux au bout des cornes
On baisse le soc pour l’amour de la charrue
On cesse d’être ami avec quelqu’un, le jour qu’on lui emprunte de l’argent
On change bien de chemin, mais on ne change pas de manières
On change plutôt une montagne qu’un naturel
On chie pas plus haut qu’on a le cul
On commence par être dupe, on finit par être fripon
On compte les défauts de qui se fait attendre
On conduit la nature, on ne la change pas
On connaît bien au pommier la pomme
On connaît bien le beau entre le laid
On connaît bien le maître au valet
On connaît bien l’ivrogne à la trogne
On connaît bien mouches en lait
On connaît bien tout hormis soi-même
On connaît bien à la barbe l’homme
On connaît la femme au pied et à la tête
On connaît le cerf aux abattures
On connaît le maître à l’ouvrage et souvent le cœur au visage
On connaît les boiteux à la marche et bossus à la course
On connaît l’ami dans le besoin
On connaît par les fleurs l’excellence du fruit
On connaît pas le moine à l’habit
On connaît pas son monde par les chemins
On connaît à l’ouvrage l’ouvrier
On crie tant Noël qu’il vient
On crie toujours le loup plus grand qu’il n’est
On crie toujours le loup plus gros qu’il n’est
On croit aux saints sitôt qu’ils font miracles
On croit d’un fol bien souvent, qu’il soit clerc pour ses vêtements
On croit d’un fol le plus souvent, qu’il soit grand clerc au vêtement
On croit d’un grand fol bien souvent, qu’il soit grand clerc au vêtement
On croit quelquefois haïr la flatterie, mais on ne hait que la manière de flatter
On devient l’homme de son uniforme
On dit bien quand le cœur conduit l’esprit
On dit bien vrai qu’en chaque saison, la femme fait ou défait la maison
On dit communément en villes et villages, que les grands clercs ne sont pas les plus sages
On dit en un commun langage, qui trop parle n’est pas sage
On dit en un commun usage, fol qui se tait semble bien sage
On dit par tout le monde, qu’où famille croît et abonde, qu’elle écure bourse et monde
On dit que les bègues excellent au chant et les boiteux à la danse
On dit que promesse fait dette
On dit qu’au temps où l’herbe pousse, le sommeil est bon le matin
On doit acquérir en jeunesse dont on puisse vivre en vieillesse
On doit battre le fer quand il est chaud
On doit battre le fer tandis qu’il est chaud
On doit battre le fer tant qu’il est chaud
On doit des égards aux vivants; on ne doit aux morts que la vérité
On doit dire bien du bien
On doit dire du bien le bien
On doit dire le bien du bien
On doit honorer gens de bien et supporter les fols
On doit honorer les bons
On doit honorer les gens de bien et supporter les fols
On doit lier à son doigt l’herbe que très bien on connaît
On doit louer les gens après leur vie
On doit plaire par mœurs et non par robe de couleur
On doit prendre l’herbe qu’on connaît
On doit quérir en jeunesse dont on vive en viellesse
On doit souffrir patiemment ce qu’on ne peut amender sainement
On doit soutenir ce qui est de droit et de raison
On doit supporter les fols
On doit tenir la chose certaine et délaisser l’incertaine
On doit à chacun le sien rendre, sur peine de la mort attendre
On donne les offices et promotion et non prudence ni discrétion
On donne rien pour rien
On donne toujours (à) casser les noisettes à ceux qui n’ont plus de dents
On donne toujours à casser les noix à ceux qui ne les savent pas casser
On donne toujours à rompre les noisettes à ceux qui n’ont pas de dents
On donne un œuf pour recevoir un bœuf
On dort avec l’épouse, non avec la fortune
On dresse le cheval quand il est encore poulain
On dresse un arbre quand il est jeune, pas quand il est vieux
On déjoue beaucoup de choses en feignant de ne pas les voir
On déjoue une plaisanterie, en ayant l’air d’y applaudir
On en parle fort en la rue des muets
On endure tout fors qu’aise
On endure tout mais qu’aise
On entend bien souvent dire ‘gros paresseux’, mais jamais ‘petit paresseux’
On entretient et contregarde sa santé par bien connaître sa complexion et par user de bon régime
On envie toujours ce qu’on n’a pas
On est bien malade, quand on ne peut souffrir ni le mal ni le remède
On est bien plus tôt marié que bien mis
On est jamais mieux servi que par soi-même
On est jamais trop vieux pour apprendre
On est la moitié de l’année au lit
On est moins révolté du vice que choqué du ridicule
On est pas loué de tous
On est pas toujours bien avisé
On est plus en terre qu’en prés
On est plus longtemps allongé que debout
On est plus longtemps couché que levé
On est plus sage par mal avoir qu’on n’est par bien et joie avoir
On est semblable à ceux avec lesquels on converse
On est semblable à ceux avec qui on converse
On est souvent battu du bâton qu’on apporte
On est souvent satisfait d’être trompé par soi-même
On est toujours mieux chez soi que chez les autres
On est toujours riche à marier mais pauvre à enterrer
On est tout sain quand le mal prend
On est trompé en melons comme en garçons
On est vite marié, mais on ne sait ce qui va arriver
On est à Dieu ou au diable
On est également payé pour aiguiser comme pour faucher
On estime les vertus, mais ce sont les qualités que l’on aime
On fait (soi-)même son sort
On fait bien mal pour puis abattre
On fait bien tout ce qu’on peut, mais pas tout ce qu’on veut
On fait des bêtises à tout âge
On fait la nouvelle d’autant plus grande que le lieu d’où elle vient est éloigné
On fait pas de moindre pacte qu’à l’église
On fait plus de travail d’une semaine que d’un jour
On fait plus en un jour qu’en un an
On fait plus souvent ce qu’on peut que ce qu’on voudrait
On fait rien que ce qu’on peut
On fait ses enfants, mais on ne fait pas leur fortune
On fait toujours le loup plus gros qu’il n’est
On fait tout pour argent
On finit toujours par trouver chaussure à son pied
On fit (ferait, aurait fait) une belle-mère en sucre, elle était (serait) encore amère
On force pas un âne à boire quand il n’a pas soif
On fout toujours les pierres au murger
On frappe toujours sur le cheval qui tire
On guérit d’un coup de couteau, on ne guérit pas d’un coup de langue
On honore communément ceux qui ont (de) beaux habillements
On honore les saints comme on les connaît
On jette toujours des pierres au monceau
On jouit moins de ce qu’on obtient que de ce qu’on espère
On juge de la pièce, pas de l’échantillon
On juge d’une individualité par ses paroles, ses actions
On laisse pas pour un bœuf de labourer
On laisse plus de choses à faire après sa mort que de faites
On lie bien le sac avant qu’il soit plein
On lie bien son sac devant qu’il soit plein
On lie le sac avant qu’il soit plein
On lit plus vite un livre emprunté qu’un livre acheté
On lui donne le doigt et il vous prend le bras
On l’emporte souvent sur la duplicité, en allant son chemin avec simplicité
On mange bien des perdrix sans oranges
On mariera plus de gens à soupe de graisse que de gens à soupe de viande
On mettrait un chapeau à un chien, qu’on lui trouverait aussi une femme
On meurt aussi bien auprès de la vieille que de la jeune
On meurt comme on a vécu
On meurt vert ou mûr
On mène en vain le bœuf à l’eau, s’il n’a soif
On mène le bœuf en vain à l’eau, n’est qu’il ait soif ou par trop chaud
On ne badine pas avec l’amour
On ne baille pas devant les personnes
On ne bat pas le diable à coups de poing
On ne blâme le vice et on ne loue la vertu que par intérêt
On ne cache pas aiguilles au sac
On ne change pas le sang en eau
On ne change pas une équipe qui gagne
On ne connaît en la prospérité le bon ami, mais en adversité
On ne connaît jamais combien vaut un bon ami, tant qu’on (ne) l’ait (pas) perdu
On ne connaît pas le vin aux cercles
On ne connaît pas le vin en cercle
On ne connaît pas les gens au visage
On ne connaît pas les gens aux robes ni le vin aux cercles
On ne connaît pas les gens à la robe
On ne connaît pas les gens à les voir
On ne connaît point le vin aux cercles
On ne cueille point de noisettes sur les ronciers
On ne demande pas au renard s’il faut l’écorcher
On ne dit jamais tachetée à une génisse, qu’elle n’ait quelque tache
On ne dit pas bouchard à un cheval qui n’a pas de poil blanc
On ne dit pas tachetée à une genisse qui n’a pas de tache
On ne doit aller aux noces sans mander
On ne doit contraindre le temps, ni sur Dieu hâter les ans
On ne doit dire son secret à femme, fol et enfant
On ne doit juger d’homme ni de vin, sans les éprouver soir et matin
On ne doit laisser lieu sûr pour se mettre en danger
On ne doit le droit violer, sinon à cause de dominer
On ne doit mettre le doigt entre l’écorce et le bois
On ne doit pas aller à mûres sans haver
On ne doit pas bonne terre pour mauvais seigneur laisser
On ne doit pas demander à bon homme dont il fut né, à bon vin où il crût
On ne doit pas enseigner les chatons à sourisser
On ne doit pas laisser le plus pour le moins
On ne doit pas lier les ânes avec les chevaux
On ne doit pas mentir en vain
On ne doit pas mettre le doigt entre l’écorce et le bois
On ne doit pas mettre les étoupes près le feu
On ne doit pas mêler le torchon avec l’essuie-mains
On ne doit pas semer les poux ès vieilles pelisses
On ne doit pas à gras porcel le cul oindre
On ne doit pas à gras pourceau(x) le cul oindre
On ne doit pas épargner blé de meunier, vin de curé ni pain de fournier
On ne doit point guérir la brebis qui se veut perdre
On ne doit point mentir de vain
On ne doit servir à boire qu’à une main
On ne doit trop prendre des siens ni ses amis trop requérir
On ne doit épargner blé de meunier, vin de curé ni moins pain de fournier
On ne donne pas de crosse à un mort
On ne donne pas les souris à garder à un chat
On ne donne rien de si bon marché que les compliments
On ne donne rien si libéralement que ses conseils
On ne dort guère, quand qu’on se propose d’aller à la chasse
On ne déracine pas les vieux arbres
On ne fait pas au four tous les jours
On ne fait pas boire un âne qui n’a pas soif
On ne fait pas ce qu’on veut, on fait ce qu’on peut
On ne fait pas de moindre pacte qu’à l’église
On ne fait pas de neuves écuelles avec de vieux tessons
On ne fait pas de néant grasse porée de gras choux
On ne fait pas de processions pour tailler les vignes
On ne fait pas de rien grasse porée
On ne fait pas des processions pour tailler les vignes
On ne fait pas deux vies
On ne fait pas d’omelette(s) sans casser des œufs
On ne fait pas tout en un jour
On ne fait pas à grand coup (tout d’un coup) douce(s) vieille
On ne fait pas à grands coups (tout d’un coup) vieilles douces
On ne fait que ce qu’on peut et pas ce qu’on veut
On ne fit pas Rome en un jour
On ne jette de pierres qu’à l’arbre chargé de fruits
On ne joue pas avec le feu
On ne loue d’ordinaire que pour être loué
On ne loue que ceux qui en ont besoin
On ne lâche pas le lièvre, pour courir après le chasseur
On ne mange jamais son pain tout seul
On ne marie jamais de pauvres gens
On ne met pas de fers à un chien
On ne met rien sur table pour les chevaux
On ne meurt pas de manger salement
On ne meurt que d’une mort
On ne meurt qu’une fois
On ne parle jamais assez
On ne parle jamais de soi-même sans perte
On ne perd les États que par timidité
On ne perd pas de temps quand on aiguise ses outils
On ne peut avoir le beurre et l’argent du beurre
On ne peut avoir trop d’amis
On ne peut briser mariage si on ne brise sa huche
On ne peut connaître les bons melons et les femmes de bien
On ne peut connaître ni les melons ni les femmes
On ne peut contenter tout le monde et son père
On ne peut contrefaire le génie
On ne peut courir et corner
On ne peut décrotter sa robe sans emporter le poil
On ne peut empêcher l’eau de couler, les ânes de braire et les femmes de parler
On ne peut faire d’une buse un épervier
On ne peut faire d’une fille deux gendres
On ne peut faire tort au diable
On ne peut homme nu dépouiller
On ne peut jouir en paix du bien obtenu par des voies illégitimes Voir aussi : Bien mal acquis ne profite jamais – Jamais mal acquit ne profite (Villon, 1461) – Ce qui vient par la flûte s’en retourne au tambour
On ne peut mal faire à un pot rompu
On ne peut mourir que d’une mort
On ne peut pas avoir le lard et le cochon
On ne peut pas courir et corner
On ne peut pas donner plus qu’on a
On ne peut pas faire la lessive et les vendanges tout en une fois
On ne peut pas forcer à payer quelqu’un qui ne possède rien
On ne peut pas marcher quand on a les pieds cuits
On ne peut pas plus compter sur le soleil d’hiver que sur l’amour d’une belle fille
On ne peut pas prendre deux mères au même nid
On ne peut pas sauver la chèvre et les choux
On ne peut pas vivre avec les morts
On ne peut pas être au carillon et puis à la procession
On ne peut pas être de tous aimé
On ne peut prendre un homme rai (rasé) aux cheveux
On ne peut reconnaître bien bon melon ni (ou) femme de bien
On ne peut rien aimer que par rapport à soi
On ne peut répondre de son courage quand on n’a pas été dans le péril
On ne peut se promettre de rien
On ne peut servir à deux seigneurs
On ne peut souffler et humer ensemble
On ne peut tirer à deux cibles
On ne peut trouver de poésie nulle part, quand on n’en porte pas en soi
On ne peut vivre que d’amour et d’eau fraîche
On ne peut vivre sans eau, on peut vivre sans vin
On ne peut voler sans ailes
On ne peut à la fois courir et sonner du cor
On ne peut être de tous aimé
On ne peut être en même temps au carillon et à la procession
On ne peut être malade à la table d’un cardinal par faute de vivre
On ne peut être à la fois au four et au moulin
On ne plaint jamais dans autrui que des maux dont on ne se croit pas exempt soi-même
On ne prend mie (ni) le lièvre au tambour ni l’oiseau à la tarterelle
On ne prend ni le lièvre au tambour ni l’oiseau à la tartarelle ou sonnette
On ne prend pas (le) lièvre au tambourin
On ne prend pas chat sans mouffles
On ne prend pas deux fois les oiseaux dans le même nid
On ne prend pas deux mères dans le même nid
On ne prend pas la lune aux dents
On ne prend pas l’oiseau à la crécelle
On ne prend pas tel chat sans mouffles
On ne prend point ce chat sans mouffles
On ne prend un âne pour compagnon que si on a une charge à porter
On ne prête pas de corde à celui qui nous voudrait pendre
On ne prête pas de corde à celui qui voudrait se pendre
On ne prête qu’aux riches
On ne reconnaît les biens qu’après qu’ils sont perdus
On ne redresse pas les infirmes de nature
On ne refuse pas la pitié aux malheureux, pourvu qu’ils n’en demandent pas davantage
On ne regarde pas dans votre estomac mais à votre cul
On ne rend pas l’argent quand la toile est levée
On ne revient pas sur une affaire qui a reçu un commencement quelque soit l’excuse
On ne rit pas toujours en ménage
On ne répète pas deux fois la messe pour les sourds
On ne sait ni qui va (meurt) ni qui vient
On ne sait pas de quoi on pourrait avoir besoin
On ne sait pas toujours ce qui cuit dans la marmite des autres
On ne sait pour qui on amasse
On ne sait qui meurt ni qui vit
On ne sait qui vit ne (ni) qui meurt
On ne sait si peu boire qu’on ne s’en sente
On ne saurait couper du bois sans faire de copeaux
On ne saurait faire cinquante besognes à la fois
On ne saurait faire d’omelette sans casser des œufs
On ne saurait faire d’un sot, un habile homme
On ne saurait faire d’une buse un épervier
On ne saurait faire le feu si bas que la fumée n’en sorte
On ne saurait faire une omelette sans casser des œufs
On ne saurait façonner le beurre sans s’engraisser les doigts
On ne saurait garder de gens trompeurs ou simulateurs, qui se montrent amis par devant et en derrière autrement
On ne saurait garder un chat quand il a goûté la crème
On ne saurait recevoir que ce qu’on a semé
On ne saurait remuer du beurre sans s’engraisser les doigts
On ne saurait servir à deux autels
On ne saurait si bien se garder qu’aucunefois on ne se soit trompé
On ne saurait si peu boire qu’on ne s’en ressente
On ne saurait être à la fois au four et au moulin
On ne se doit soucier de ce qui peut advenir à l’homme
On ne se gratte que où cela démange
On ne se joue pas deux fois à l’eau
On ne se peut de larron privé garder, ni de la mort écarter ni échapper
On ne se peut de larron privé guetter
On ne se saurait fier en personne
On ne se souvient plus en hiver de l’été
On ne se voit jamais emmerdé que par les merdeux
On ne sent une cravate et une femme que lorsqu’on les a autour du cou
On ne songe jamais à tout
On ne sort du sac que ce qu’il y a
On ne sort pas une seillée de sang d’un moustique
On ne soucie que tout devienne mais que l’on se garde et maintienne
On ne surmonte le vice qu’en le fuyant
On ne sème ni plante les fous hêtres, ils croissent bien par eux
On ne séduit guère que ceux qui sont déjà séduits
On ne s’aime bien que quand on n’a plus besoin de se le dire
On ne s’appuie que sur ce qui résiste
On ne s’engraisse pas en ne buvant que de l’eau froide
On ne s’intéresse guère aux affaires des autres que lorsqu’on est sans inquiétude sur les siennes
On ne taille pas le pied à l’âne, pour une fois qu’il s’achoppe
On ne taille pas les pieds à un cheval, la première fois qu’il s’achoppe
On ne tire du sac que ce qu’il y a
On ne tire pas des coups de fusil aux idées
On ne trompe point en bien
On ne trouve de l’humeur que chez les autres
On ne trouve jamais deux mères dans le même nid
On ne trouve laides amours
On ne va jamais bien loin, quand c’est qu’on se dépêche
On ne va pas aux mûres sans crochet
On ne va pas demander là où c’est qu’on fait l’aumône
On ne vante que ce qui en a besoin
On ne vend pas chat en sac
On ne vend pas un œuf qui n’est pas encore pondu
On ne vend point chat en sac
On ne vieillit pas à table
On ne vieillit pas à table
On ne vit pas de beauté
On ne voit clair que quand on a les yeux crevés
On ne voit cygne noir, nulle neige noire, nul lait noir, nul blanc corbeau, nul sang blanc, nulle puce blanche, nul feu froid, le soleil n’est obscur, ciel immobile on ne connaît
On ne voit jamais beau cimetière pour y être enterré
On ne voit pas l’homme puissant au faible porter loyauté
On n’a guère de mal volontaire
On n’a jamais bon marché de mauvaise marchandise
On n’a jamais eu vu un couvreur rester sur un toit
On n’a jamais eu vu un âne à courtes oreilles
On n’a jamais fini d’apprendre
On n’a jamais laissé personne sans l’enterrer
On n’a jamais que ce qu’on mérite
On n’a jamais qu’un bon mariage dans sa vie
On n’a jamais ramassé des poires à Botzi sous un pommier sauvage
On n’a jamais ramassé des poires à Botzi sur un pommier
On n’a jamais une croix seule
On n’a jamais vu les jeunes oiseaux donner à manger aux vieux
On n’a jamais vu un couvreur rester sur un toit
On n’a jamais vu un feu qui ne brûle pas
On n’a jamais vu un âne à courtes oreilles
On n’a jamais vu une agasse (agace, pie) avec un corbeau
On n’a pas bâti l’église en un jour
On n’a pas bâti église d’un jour
On n’a pas de pire ennemi que soi-même
On n’a pas de pires ennemis que ceux qui ont eu été vos amis
On n’a pas de pires ennemis que ceux qui ont été vos amis
On n’a pas de profit de la misère des autres
On n’a pas encore tout pleuré au berceau
On n’a pas lettres de toujours vivre
On n’a pas un guignon sans deux
On n’a plus d’argent que de vie
On n’a que ce qu’on soigne
On n’a que faire de mener des femmes par pays, car il s’en trouve assez partout
On n’a rien que ce qu’on choie
On n’a rien sans peine, pas même un crouille femme
On n’abat pas un chêne au premier coup
On n’achète pas la tête dans un sac
On n’achète pas un cheval qui boite
On n’achète pas un cheval sans l’avoir vu
On n’aime (pas) le charretier quand il charrie mal
On n’aime pas par contrainte
On n’aime point à voir ceux à qui l’on doit tout
On n’aime trahison, non pas les traîtres
On n’apparie point un geai avec une agasse
On n’appelle jamais vache tachetée, qu’elle n’eut quelque tache
On n’apprend pas aux vieux singes à faire les grimaces
On n’apprend pas à un vieux singe à faire des grimaces
On n’apprend rien que ne coûte quelque chose
On n’apprend rien qu’il n’en coûte
On n’apprend rien qu’à ses dépens
On n’apprend rien sans que coûte
On n’arrête pas une rivière qui déborde
On n’aura jamais bon âne vieil
On n’aurait jamais rien à regretter que d’avoir pas assez bien fait
On n’embrasse pas toutes les belles
On n’embrasse pas toutes les belles
On n’emporte avec soi que le bien qu’on a fait
On n’emporte avec soi que le bien qu’on a fait
On n’en dit jamais une sans deux
On n’en dit jamais une sans deux
On n’en sait jamais trop
On n’en sait jamais trop
On n’engraisse pas les gorets à l’eau claire
On n’engraisse pas les gorets à l’eau claire
On n’engraisse pas les porcs avec de l’eau claire
On n’engraisse pas les porcs avec de l’eau claire
On n’entame pas un sac de blé par le milieu
On n’entame pas un sac de blé par le milieu
On n’est jamais blâmé que par ceux qui valent moins
On n’est jamais blâmé que par ceux qui valent moins
On n’est jamais blâmé que par moindre que soi
On n’est jamais blâmé que par moindre que soi
On n’est jamais blâmé que par plus mauvais que soi
On n’est jamais blâmé que par plus mauvais que soi
On n’est jamais emmerdé que par la merde et on n’est jamais aboyé que par les chiens
On n’est jamais emmerdé que par la merde et on n’est jamais aboyé que par les chiens
On n’est jamais méprisé que par moindre que soi
On n’est jamais méprisé que par moindre que soi
On n’est jamais riche si l’on ne met du bien d’autrui avec le sien
On n’est jamais riche si l’on ne met du bien d’autrui avec le sien
On n’est jamais sali que par la boue
On n’est jamais sali que par la boue
On n’est jamais si bien servi que par soi-même
On n’est jamais si bien servi que par soi-même
On n’est jamais si malheureux qu’on croit ni si heureux qu’on avait espéré
On n’est jamais si malheureux qu’on croit ni si heureux qu’on avait espéré
On n’est jamais trahi que par les siens
On n’est jamais trahi que par les siens
On n’est jamais trahi que par ses amis
On n’est jamais trahi que par ses amis
On n’est nulle part bien comme chez soi
On n’est nulle part bien comme chez soi
On n’est pas au village pour faire du bourgeois
On n’est pas au village pour faire du bourgeois
On n’est pas contraint de prendre
On n’est pas contraint de prendre
On n’est pas de fer
On n’est pas de fer
On n’est pas gentilhomme pour avoir un père qui a vendu un pré
On n’est pas gentilhomme pour avoir un père qui a vendu un pré
On n’est pas loué de tous
On n’est pas maître de son cœur
On n’est pas né pour la gloire, lorsqu’on ne connaît pas le prix du temps
On n’est pas quitte en payant
On n’est pas quitte en payant
On n’est pas toujours bien avisé
On n’est pas tous faits pour bien danser
On n’est point l’ami d’une femme lorsqu’on peut être son amant
On n’est pris qu’en prenant
On n’est rien sûr que de mourir
On n’est, avec dignité, épousée et veuve qu’une fois
On n’imagine pas combien il faut d’esprit pour n’être jamais ridicule
On n’offense personne en l’aimant
On n’oublie jamais tout
On n’y enterre que les morts
On n’y recouvre pas deux fois
On n’écorche pas l’anguille par la queue
On n’écorche pas l’anguille par la queue
On obtient davantage en léchant qu’en mordant
On ouvre mieux l’esprit que l’on ne le clôt
On pardonne aisément un tort que l’on partage
On pardonne les infidélités, mais on ne les oublie pas
On pardonne tant que l’on aime
On parle jamais assez
On parle mal des femmes, mais chacun les cherche et les suit
On parle quand on voit parler
On parle toujours mal quand on n’a rien à dire
On parle à son aise quand on a les pieds chauds
On perd beaucoup de choses par faute de demander
On perd en peu de temps ce qu’on a gagné en long temps
On perd moins son temps à réduire son butin qu’à fuir après
On peut avec honneur remplir les seconds rangs
On peut bien voyager en vie, car après la mort on n’a vie
On peut briller par la parure, mais on ne plaît que par la personne
On peut construire un trône avec des baïonnettes, mais on ne peut pas s’asseoir dessus
On peut convaincre les autres par ses propres raisons; on ne les persuade que par les leurs
On peut croiser les bras, mais trop souvent ça fait partir le pain
On peut dire des prêtres ce qu’on dit de la langue, que c’est la pire des choses ou la meilleure
On peut dominer par la force, mais jamais par la seule adresse
On peut pas aller contre le sort
On peut pas attacher tous les chiens
On peut pas avoir le beurre et l’argent du beurre
On peut pas casser les pierres avec le poing
On peut pas chier plus haut qu’on a le cul
On peut pas cueillir de farine de froment dans un sac de charbon
On peut pas dire deux messes pour un sourd
On peut pas discuter avec un fou
On peut pas donner ce qu’on n’a pas
On peut pas donner ce qu’on n’a pas reçu
On peut pas faire comme on veut
On peut pas faire deux vies
On peut pas faire plus qu’on peut
On peut pas faire tout à la fois
On peut pas prendre deux mères dans le même nid
On peut pas prendre plus qu’il y a dans le sac
On peut pas prendre à redresser un vieil arbre
On peut pas redresser un vieil arbre
On peut pas ressusciter les morts
On peut pas sortir de la farine blanche d’un sac de charbon
On peut pas être au four et au moulin
On peut pas être en même temps au four et au moulin
On peut pas être à la fois au four et au moulin
On peut rien faire qu’à coup d’argent
On peut résister à tout hors à la bienveillance
On peut se fier de personne
On peut se passer de boire, non de manger
On peut venir à bout de tout, excepté d’une mauvaise femme
On peut violer les lois sans qu’elles crient
On peut être honnête homme, et fort mauvais époux
On peut être plus fin qu’un autre, mais pas plus fin que tous les autres
On peut être un héros sans ravager la terre
On prend les bêtes par les cornes et les hommes par les paroles
On prend les bœufs par les cornes et les hommes par les paroles
On prend les villes par les oreilles
On prend l’homme par la langue et le bœuf par les cornes
On prend plus de mouches avec une cuillerée de du miel qu’avec un tonneau de du vinaigre
On prend plus tôt un menteur qu’on ne fait un boiteux
On prend plus tôt un menteur qu’un aveugle ni (ou) un boiteux
On prend sapience de tout reste (sauf) de la mort d’un fils et d’argent perdu
On prend toujours les voisins pour plus heureux qu’ils ne sont
On presse l’orange, et on jette l’écorce
On profite des circonstances heureuses qui se présentent
On promet beaucoup pour se dispenser de donner peu
On raille toujours sur les coins qui tirent le plus fort
On rajeunit en dansant
On rattrape plus aise (aisément) un menteur qu’un boiteux
On reconnaît l’arbre à son fruit
On reconnaît l’oiseau à son chant, à son parler l’homme méchant
On rencontre sa destinée souvent par des chemins qu’on prend pour l’éviter
On revient sage des plaids
On revient sage par jours
On revient toujours à ses premières amours
On rogne pas le pied à un cheval, la première fois qu’il s’achoppe
On récolte ce que l’on sème
On récolte ce qu’on a semé
On résiste à l’invasion des armées, on ne résiste pas à l’invasion des idées
On sait bien quand on s’en va, mais on ne sait quand on reviendra
On sait ce qu’on perd, on ne sait pas ce qu’on trouve
On sait ce qu’on quitte, on ne sait pas ce qu’on va prendre
On sait comment on part, mais on ne sait pas comment on revient
On sait pas ni qui vit ni qui meurt
On sait pas pourquoi les affaires se font
On sait quand qu’on s’en va, on ignore quand qu’on reviendra
On sait tous être ‘donne’, quand ça sort pas de sa poche
On se cogne toujours là où c’est qu’on est blessé
On se console rarement des grandes humiliations, on les oublie
On se console souvent d’être malheureux par un certain plaisir qu’on trouve à le paraître
On se croit toujours plus sage que sa mère
On se fait belle, on devient riche, on naît élégante
On se fait une habitude d’un long malade
On se lasse de tout, excepté du travail
On se moque de ceux qui montrent leurs meurtrissures pour se vanter
On se moque toujours des maux (mal) chaussés
On se mâchure les mains, quand on touche du charbon
On se pardonne beaucoup plus à soi qu’aux autres
On se perd souvent par celui duquel on se fie
On se peut bien garder d’un larron, d’un menteur garder ne se peut-on
On se repent jamais d’avoir bien fait
On se repent toujours d’un mauvais marché
On se touche toujours au doigt malade
On se voit jamais sali que par la merde
On sort du sac que ce qu’il y a
On sort pas de la farine blanche d’un sac de charbon
On souffre pour les avoir, on souffre pour les garder, et on souffre pour les perdre
On souhaite la paresse d’un méchant et le silence d’un sot
On s’advise tout en mourant
On s’ennuie moins à table qu’au sermon
On s’habitue à ses infirmités, le plus difficile, c’est d’y habituer les autres
On s’éreinte en voulant porter sa maison sur son cul
On s’évieillit joyeusement à la marmite
On tend les voiles du côté que vient le vent
On tiendrait plutôt un panier de rats qu’une fille de vingt ans
On tient bien cher celui dont on amende
On tient plus cher ce qu’on a à grande peine ou bien cher acheté
On tient toujours du lieu dont on vient
On tient toujours plus à sa peau qu’à sa chemise
On tire toujours ce qu’on peut des vieux chevaux
On tire tout ce qu’on peut des vieux chevaux
On tirerait plutôt de l’huile d’un mur que de l’argent de cet homme-là
On tombe du côté où l’on penche
On tombe toujours du côté où on penche
On triche partout qu’aux cartes
On trouve partout son semblable
On trouve plus vite un menteur qu’un boiteux
On trouve remède à tout fors à la mort
On trouve toujours chaussure à son pied
On trouve toujours son pareil
On trouve trop de gens de métier de laquais
On trouvera comme on aura fait
On va mourir de froid auprès du feu
On va pas à la forêt sans hache
On va tant à la fontaine qu’on y rompt son petit pot
On va à cheval pour les procès et pour les maladies à pied
On vend au marché plus de harengs que de soles
On vendrait le diable s’il était cuit
On veut que le pauvre soit sans défaut
On vieillit sans s’en apercevoir, on vieillit malgré soi
On vient (devient) pas riche sans rien faire
On vient (devient) sage à ses dépens
On vit avec la femme, pas avec l’argent
On vit pas de l’air du temps
On voit au morceau ce qu’a été l’écuelle
On voit bien encore aux tessons ce que fut le pot
On voit bien que c’est la fille de la maison, sa chemise dépasse son cotillon
On voit bien à sa couleur quelle peut être sa douleur
On voit jamais les garçons jeter des pierres aux arbres secs
On voit moins de pieds de chèvres au marché que de pieds de chevreaux
On voit par la bête le saut qu’elle peut faire
On voit plus de vieux gourmands que de vieux médecins
On voit plus de vieux ivrognes que de vieux médecins
On voit toujours clair pour les autres
On vous fera de tel pain soupes
Once d’état, livre d’or
Oncques (Jamais) amour(s) et seigneurie(s) ne se tinrent compagnie
Oncques amour et seigneurie ne s’entretinrent compagnie
Oncques amour ni (ou) seigneurie s’entretinrent grande compagnie
Oncques bon cheval ne devint rosse
Oncques chapon n’aima géline
Oncques convoitise ne fît grand mont
Oncques de putain léale (fidèle) amie
Oncques dormeur ne fit bon guet
Oncques d’étoupes bonne chemise
Oncques en chaud four ne crût herbe
Oncques foulon ne caressa charbonnier
Oncques géline n’aima chapon
Oncques n’aima bien qui pour (si) peu hait
Oncques putain n’aima preudhomme
Oncques sautier bon écolier
Oncques souhait n’emplit le sac
Oncques tripière n’aima haranguère
Oncques vanteur ne fut grand faiseur
Oncques vieil (vieux) singe ne fit belle moue
Oncques vilain n’aima noble homme
Onze mois ont tôt mangé un mois de senaison
Opinion n’est pas science
Or est ce qui or vaut
Or est qui or vaut
Or est qu’or vaut
Or va pis que devant
Or vaut ce qu’or vaut
Ord va la brebis à la chèvre laver
Ordre et contrordre, désordre
Ordre, moyen et raison, régissent la maison
Ordure sans ordre
Oreille fine, joli chanteur
Ores (Bien) que la faucille soit tordue, elle ne laisse pas de scier droit le chaume
Orgeuil est de tous vices la racine et humilité de tous biens la reine
Orgueil n’a bon œil
Orgueilleuse semblance montre fol cuidance
Orgueilleuse semblance montre folie évidente
Ou chevalier ou rien
Ou de paille ou de foin, il faut que le ventre soit plein
Ou de vrai ou de menterie, faut entretenir la ménie
Ou rendre ou pendre
Ou rendre ou pendre, ou la mort d’enfer attendre
Ou tout un, ou tout autre
Ou un beau si, ou un beau non
Ouaille cornue et vache pansue, ne change ni ne mue
Ouaille cornue et vache pansue, ne la change et ne mue, parce qu’elles sont les meilleures
Ouvre la porte au bonheur lorsqu’il se présente, et attends à pied-ferme le malheur qui te doit arriver
Ouvre ta bourse, j’ouvrirai ma bouche
Ouvrier gaillard (vigoureux, excellent) cèle son art
Ouïr dire va par la ville
Ouïr dire va par ville
Ouïr ni voir ne faut, ce que rien ne vaut
Ouïr, voir et (se) taire, sont choses ardues à faire
Ouïr, voir et se taire de tout, fait l’homme être bienvenu partout
Ouïr, voir et se taire de tout, nourrit concorde et paix partout
Ouïr, voir et taire, par mer et par terre
Où (il) y a femmes et oisons, (il y) a paroles à foison
Où Dieu veut, il pleut
Où berbis sont, laine est
Où cette vie prend fin, commence mort ou joie sans fin
Où chats ne sont, souris s’éveille
Où chiens y a, puces y a
Où entre le boire, ist (s’en va, ire en latin) le savoir
Où entre l’oignon, n’entre pas le médecin
Où est Dieu, où est diable
Où est coq, poule ne chante
Où est la force, la raison cède
Où est la paresse, est la graisse
Où est le coq, faut pas que la poule chante
Où est le coq, la poule ne chante pas
Où est le corps, est la mort
Où est l’amour, là est l’œil
Où est raison, n’y a confusion
Où faim règne, force exule
Où faim règne, force exulte
Où faute y a du cuir du lion, appliquer y convient la peau du renard
Où femme gouverne et domine, tout va souvent à ruine
Où femme il y a, silence il n’y a
Où femmes y a, enfants, oisons, caquets ne manquent à grande foison
Où femmes y a, silence n’y a
Où force est, justice n’a lieu
Où force est, raison est perdue
Où force est, raison n’a lieu
Où force règne raison n’a lieu
Où gît accord, n’y a remord
Où il faut un domestique, on n’en prend pas deux
Où il n’y a amour, il y a haine
Où il n’y a bon chef ni (ou) roi, survient méchef et tout désarroi
Où il n’y a pas de blé, il n’y a pas de pain
Où il n’y a pas de sang, il ne faut pas de pansement
Où il n’y a pas d’amour le soleil manque
Où il n’y a point de Dieu, n’y a point d’aide
Où il n’y a que frire, n’y a plaisir
Où il n’y a que mâcher, n’y a que frire, n’y a déduit ni grand plaisir
Où il n’y a rien à faire, il n’y a rien à manger
Où il n’y a rien, le roi perd ses droits
Où il n’y a rien, le roi perd son droit
Où il n’y a rien, on peut rien prendre
Où il n’y a rien, personne ne s’y tient
Où il y a abondance de paroles, il n’y a pas grande sagesse
Où il y a beaucoup de lumière, il y a beaucoup d’ombre
Où il y a des chiens, il y a des puces
Où il y a des filles, les garçons viendront
Où il y a deux femmes marché, où il y en a trois foire
Où il y a du hi-han, il y a de l’âne
Où il y a femmes, il y a diables
Où il y a ivrognerie, il y a coups et misère
Où il y a la justice, il n’y a pas besoin de gendarmes
Où il y a le coq, la poule ne chante pas
Où il y a rien de feu, il y a rien de fumée
Où il y a rien, le diable perd ses droits
Où il y a rien, personne ne peut rien
Où il y a suffisamment d’escient, il y a suffisamment de souffrance
Où jeunesse gagne la place, la vieillesse tôt se déplace
Où justice défaut, paix défaut
Où justice est en vigueur, la république est en fleur
Où la charrette peut entrer, elle peut sortir
Où la chèvre est attachée, faut qu’elle broute
Où la chèvre est attachée, il faut qu’elle broute
Où la chèvre est liée, il faut qu’elle broute
Où la chèvre est liée, il faut qu’elle broute
Où la dent est douloureuse, la langue appuie
Où la femme gouverne et domine, tout s’en va souvent en ruine
Où la guêpe a passé, le moucheron demeure
Où la tête passe, le reste du corps y passe
Où la vache est attachée, faut qu’elle broute
Où la valeur, la courtoisie
Où la vieille balle et carde, grande poussière s’élève et vole
Où le Bon Dieu veut, il pleut
Où le char peut entrer, il peut sortir
Où le diable ne peut aller, sa mère tâche d’y mander
Où le loup habite, ne (se) commet daim ni délit
Où le loup trouve un agneau, il y en cherche un nouveau
Où le soleil luit, la lune n’y a que faire
Où le soleil pénètre, il y a la santé
Où le vent, là le manteau
Où les maux sont, ils foisonnent
Où les méchants sont autorisés de parler, présage de la ruine des cités on peut juger
Où l’heur n’est, labeur est inutile
Où l’hôtesse est belle, le vin est bon
Où l’or abonde, il succombe langue faconde
Où manque chef, survient méchef
Où manque et défaut le courage, force languit en tout ouvrage
Où manque la police, abonde malice
Où manque la santé, la fortune fait défaut
Où menteur sont, la foi y est périe
Où nous avons dîné, nous souperons
Où n’y a feu, n’y a fumée
Où n’y a sujétion (soumission), n’y a roi ni raison Où il n’y a roi, n’y a aloi Et où manque justice, manque loi
Où on donne, on prend
Où on mange le pain dur, on amasse or et argent
Où on ne veut pas s’endormir, faut pas se coucher
Où pain faut, tout est à vendre
Où pain faut, tout y est à vendre
Où paix défaut (fait défaut) guerre abonde
Où paix est, Dieu est
Où paix est, Dieu est Et où y a guerre, tout n’en vaut guère
Où paix faut (fait défaut), guerre abonde
Où passe l’aiguille suit le fil
Où richesse est, péché est
Où rien n’y a, le roi perd son droit
Où règne et domine sensualité, n’a lieu ni demeure raison ni équité
Où sensualité domine, raison s’avachit
Où serviteur veut être maître, l’herbe fait à son maître paître
Où sont les chiens, des puces Où est le pain, des rats Où est la femme, le diable
Où sont les grands hommes, sont les grandes idoles
Où vit une fille amoureuse, on clot la porte vainement
Où y a femmes et oisons, à paroles est foison
Où y a miel, gît souvent poison et fiel
Où y a ordre, n’y a que remordre
Où y a pain, y a souris
Pas vu pas pris pris pendu
Pierre qui roule n’amasse pas mousse
Plus on est de fous, plus on rit
Plus on juge, moins on aime
Plus vaut tard que jamais
Point d’argent, point de Suisse
Point n’est besoin d’espérer pour entreprendre, ni de réussir pour persévérer
Pour mener à bien certaines entreprises, il faut se résigner à faire les sacrifices nécessaires
Quand le chat n’est pas là les souris dansent
Quand on parle du loup on en voit la queue
Quand une combinaison, une équipe permet de réussir, il est préférable de laisser les choses ainsi de manière à gagner encore
Qui aime bien châtie bien
Qui dort, dîne
Qui ne dit mot consent
Qui ne tente rien, n’a rien
Qui sème le vent récolte la tempête
Qui trop embrasse, mal étreint
Qui va à la chasse perd sa place
Qui vivra verra
Qui vole un oeuf vole un boeuf
Rien ne sert de courir, il faut partir à point
Rira bien qui rira le dernier
Se dit d’une solution qui n’apporte pas forcément de gain
Tant va la cruche à l’eau qu’à la fin elle se casse
Tant va la cruche à l’eau qu’à la fin elle se casse
Tout se vend avec de la présentation et du conditionnement
Tout vient à point à qui sait attendre
Tout vient à point à qui sait attendre
Un coup d’epée dans l’eau
Un coup pour rien
Un homme averti en vaut deux
Un « Tiens » vaut mieux que deux « Tu l’auras »
Une de perdue dix de retrouvées
Une mauvaise marchandise est toujours trop chère
le bonnet, les béquilles, la tabatière, le coin du feu
le titre n’est pas garantie du savoir
l’ennui, le vice et le besoin
À barque désespérée, Dieu fait trouver le port
À beau jeu, beau retour
À bon chat, bon rat
À bon demandeur bon refuseur
À bon entendeur, il ne faut qu’une parole
À bon entendeur, salut
À bon vin point d’enseigne
À chaque Saint sa chandelle
À chaque jour suffit sa peine
À charcutier, bonne saucisse
À chemin battu il ne croît point d’herbe
À cheval donné, on ne regarde pas les dents
À cheval donné, on ne regarde pas à la bride
À chevaux maigres vont les mouches
À cœur vaillant rien d’impossible
À donner donner, à vendre vendre
À faute de chapon, Pain et oignon
À femme sotte nul ne s’y frotte
À fol conteur, Sage écouteur
À force de forger on devient forgeron
À grands seigneurs, peu de paroles
À la Chandeleur l’hiver cesse ou reprend vigueur
À la Chandeleur, l’hiver se passe ou prend vigueur
À la chandelle, la chèvre semble demoiselle
À la guerre comme à la guerre
À la meilleure femme le meilleur vin
À laver la tête d’un âne, on perd sa lessive
À l’heureux l’heureux
À l’impossible nul n’est tenu
À l’ongle on connaît le lion
À l’œuvre on connaît l’artisan
À l’œuvre on connaît l’ouvrier
À mal enfourner, on fait les pains cornus
À mauvais jeu, bonne mine
À menteur, menteur et demi
À méchant ouvrier, point de bon outil
À nouvelles affaires, nouveaux conseils
À pauvres gens, enfants sont richesse
À propos de l’ingratitude dédaigneuse de Frédéric II, qui se sépara de Voltaire après avoir tiré de lui tous les services qu’il pouvait rendre
À père amasseur, fils gaspilleur
À père avare, enfant prodigue; à femme avare, galant escroc
À père avare, fils prodigue
À père prodigue, fils avare
À quelque chose malheur est bon
À riche homme souvent sa vache vêle et du pauvre le loup veau emmène
À sotte demande, point de réponse
À tous seigneurs tous honneurs
À tout bon compte revenir
À tout perdre il n’y a qu’un coup périlleux
À tout péché miséricorde
À tout seigneur tout honneur
À tout venant beau jeu
À toute bête la nature a donné son ennemi
À toute heure, Chien pisse et femme pleure
À trompeur, trompeur et demi
À trop tirer, on rompt la corde
À trop vieux corps, point de remède
À tête de fer bras d’acier
À un chacun sent bon sa merde
À un cheval hargneux il faut une étable à part
À une femme et à une vieille maison il y a toujours à refaire
À vaillant homme courte épée
À vaincre sans péril, on triomphe sans gloire
À vieille mule, frein doré
Âne avec le cheval n’attèle
Épouse ton égale
Éveillé comme une potée de souris
Évite que ta langue ne devance ta pensée
Évitez de vous mêler des affaires publiques
Évitez les trois quarts du chemin à l’ami qui revient
Évitez même la tombe de votre marâtre
Être aussi ignorant que l’enfant qui vient de naître
Être aux premières loges
Être comme les deux doigts de la main
Être digne d’éloge vaut mieux que d’être loué
Être en paradis, se croire dans le paradis
Être entre le marteau et l’enclume
Être faux comme un jeton
Être fort en gueule
Être frais comme un gardon
Être gras comme un moine
Être hors de gamme
Être ivre mort
Être l’esclave du plaisir, c’est la vie d’une courtisane et non celle d’un homme
Être malheureux comme les pierres
Être paresseux comme une couleuvre
Être réglé comme un papier de musique
Être souple comme un gant
Être sur la litière
Être sur le grabat
Être sur le pavé du roi
Être à couvert ou à l’abri de la pluie
Ôte-toi de là que je m’y mette
Ôter le pain de la main à quelqu’un
Œil luisant vaut de l’argent
Œil ouvert, poche fermée
Œil pour œil, dent pour dent
Œil un autre œil voit et non soi
Œil vif, signe de santé
Œuf d’une heure, pain d’un jour, vin d’un an, maîtresse de quinze, ami de trente
Œufs trop cuits, poissons trop crus rendent bossus les cimetières
