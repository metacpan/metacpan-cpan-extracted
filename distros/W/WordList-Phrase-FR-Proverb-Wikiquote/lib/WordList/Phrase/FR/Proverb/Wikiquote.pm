package WordList::Phrase::FR::Proverb::Wikiquote;

our $DATE = '2016-02-04'; # DATE
our $VERSION = '0.01'; # VERSION

use utf8;

use WordList;
our @ISA = qw(WordList);

our %STATS = ("num_words_contains_unicode",154,"longest_word_len",81,"shortest_word_len",16,"num_words_contains_nonword_chars",306,"num_words",306,"num_words_contains_whitespace",306,"avg_word_len",38.2712418300654); # STATS

1;
# ABSTRACT: French proverbs from en.wikiquote.org

=pod

=encoding UTF-8

=head1 NAME

WordList::Phrase::FR::Proverb::Wikiquote - French proverbs from en.wikiquote.org

=head1 VERSION

This document describes version 0.01 of WordList::Phrase::FR::Proverb::Wikiquote (from Perl distribution WordList-Phrase-FR-Proverb-Wikiquote), released on 2016-02-04.

=head1 SYNOPSIS

 use WordList::Phrase::FR::Proverb::Wikiquote;

 my $wl = WordList::Phrase::FR::Proverb::Wikiquote->new;

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
 | avg_word_len                     | 38.2712418300654 |
 | longest_word_len                 | 81               |
 | num_words                        | 306              |
 | num_words_contains_nonword_chars | 306              |
 | num_words_contains_unicode       | 154              |
 | num_words_contains_whitespace    | 306              |
 | shortest_word_len                | 16               |
 +----------------------------------+------------------+

The statistics is available in the C<%STATS> package variable.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/WordList-Phrase-FR-Proverb-Wikiquote>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-WordList-Phrase-FR-Proverb-Wikiquote>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=WordList-Phrase-FR-Proverb-Wikiquote>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Source: L<https://en.wikiquote.org/wiki/French_proverbs>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
A qui la tête fait mal, souffre par tout le corps.
A tout pourquoi il y a (un) parce que.
A vrai dire peu de paroles.
Abondance de bien ne nuit pas.
Aide-toi et le ciel t'aidera.
Amour, toux et fumée en secret ne sont demeurés.
Apres la pluie, le beau temps.
Bacchus a noyé plus de gens que Neptune.
Beacoup de paille, peu de grains.
Bien mal acquit ne profite jamais.
Bien nourri et mal apris.
Bois tordu fait feu droit.
Bon coeur ne peut mentir.
Bon marché tire agent de bourse.
Bon sang ne saurait mentir.
Bonne renommée vaut mieux que ceinture dorée.
Bonne volonté est reputé pour le fait.
Bons nageurs sont à la fin noyés.
C'est dans le besoin qu'on reconnaît ses vrais amis.
C'est donner deux fois, donner promptement.
C'est en forgeant qu'on devient forgeron.
C'est l'exception qui confirme la règle.
C'est la poule qui chante qui a fait l'œuf.
C'est le ton qui fait la chanson.
C'est trop d'un ennemi et pas assez de cent amis.
C'est viande mal prête que lièvre en buisson.
C'est volour prendre la lièvre au son du tampour.
Ce n'est pas aux vieux singes qu'on apprend à faire des grimaces.
Ce n'est pas la vache qui crie le plus fort qui donne le plus de lait.
Ce que chante la corneille, chante le corneillon.
Ce que l'enfant écoute au foyer, est bientôt connu jusqu'au moutier.
Ce que tout le monde dit doit être vrai.
Ce qui croît soudain, perit le lendemain.
Ce qui est fait n'est plus à faire.
Celui que veut être jeune quand il est vieux, doit être vieux quand il est jeune.
Celui qui est lent à manger est lent à travailler.
Celui qui fuit de bonne heure peut combattre derechef.
Celui qui n'est pas avec moi est contre moi.
Ceux que Jupiter veut perdre, il commence par leur oter la raison.
Chacun doit balayer.
Chacun peut être riche en promesses.
Chacun pour soi et Dieu pour tous.
Chacun sent le mieux où le soulier le blesse.
Chagrin partagé, chagrin diminué; plaisir partagé, plaisir doublé.
Chaque chose vaut son prix.
Charité bien ordonnée commence par soi-même.
Chassez le naturel, il revient au galop.
Chat échaudé craint l'eau froide.
Cherchons la femme.
Chien qui aboie ne mord pas.
Choisissez votre femme par l'oreille bien plus que par les yeux.
Coffre ouvert, rend le saint pervers.
Comme on fait son lit, on se couche.
Comparaison n'est pas raison.
Coucher de poule et lever de corbeau écartent l'homme du tombeau.
Courte priére pénètre les cieux .
D'un costé Dieu poingt, de l'autre il vingt.
Dans le doute, abstiens-toi.
De la mesure dont nous mesurons les autres nous serons mesurés.
De mauvais grain jamais bon pain.
De qui je me fie Dieu me garde.
De tout s'avise à qui pain faut.
Deux ancres sont bonnes au navire.
Diviser pour régner.
Don d'ennemi c'est malencontreux.
Donnant donnant.
Donner un oeuf pour avoir une fève.
En toute chose il faut considérer la fin.
Entre l'arbre et l'écorce il ne faut pas mettre le doigt.
Envie est toujours en vie.
Faire d'une mouche un éléphant.
Faire le pas plus long que la jambe.
Faire un cygne d'un oison.
Fais ce que tu peux, si tu ne peux faire ce que tu veux.
Fais comme je dis, non comme j'agis.
Faute avouée est à moitié pardonnée.
Faute de mieux le roi couche avec sa femme.
Femme bonne vaut une couronne.
Ferveur de novice ne dure pas.
Folle est la brebis qui au loup se confesse.
Fuis le plaisir qui amène repentir.
Gardez-vous des faux prophètes.
Heureux sont les enfants dont les pères sont damnés.
Hâtez-vous lentement.
Il faut battre le fer pendant qu'il est chaud.
Il faut bonne mémoire après qu'on a menti .
Il faut casser le noyau pour en avoir l'amande.
Il faut donner au diable son dû.
Il faut laisser aller le monde comme il va.
Il faut laver son linge sale en famille.
Il faut manger pour vivre, et non pas vivre pour manger.
Il faut prêcher d'exemple.
Il faut qu'une porte soit ouverte ou fermée.
Il faut reculer pour mieux sauter.
Il faut réfléchir avant d'agir.
Il faut être deux pour danser le tango.
Il faut être matelot avant d’être capitaine.
Il n'est pas chance qui ne retourne.
Il n'est pire aveugle que celui qui ne veut pas voir.
Il n'est rien tel qui balai neuf.
Il n'y a pas de fumée sans feu.
Il n'y a point d'homme necessaire.
Il n'y a point d'église où le diable n'ait sa chapelle.
Il n'y a que la foi que sauve.
Il ne convient pas à fol qu'on lui rende cloche au col.
Il ne faut jamais quitter le certain pour l'incertain.
Il ne faut pas brûler la chandelle par les deux bouts.
Il ne faut pas changer d'attelage au milieu d'un gué.
Il ne faut pas faire ces choses a moitié.
Il ne faut pas jeter les perles devant les poureaux.
Il ne faut pas jouer avec le feu.
Il ne faut pas mettre tous ses œufs dans le même panier.
Il ne faut pas réveiller le chat qui dort.
Il ne faut pas se fier aux apparences.
Il ne faut pas vendre la peau de l'ours avant de l'avoir tué.
Il ne faut point parler de corde dans la maison d'un pendu.
Il tirerait de l'huile d'un mur.
Il vaut mieux plier que rompre.
Il vaut mieux qu'on dise "il court-là", qu'"il gît ici".
Il vaut mieux suer que trembler
Il y a péril en la demeure.
Il y a serpent caché sous des fleurs.
Jamais deux sans trois.
Jamais honteux n'eut belle amie.
Jamais paresseux n'eut grande écuelle.
Je crains l'homme d'un seul livre.
Jeter de l'huile sur le feu.
Jeunneuse pauresse, viellise pouilleuse.
Juge hâtif est périlleux.
L'argent est fait pour rouler.
L'attaque est la meilleure défence.
L'enfer est pavé de bonnes intentions.
L'envie s'attache à la gloire.
L'espoir fait vivre.
L'essentiel du courage c'est la prudence.
L'habit ne fait pas le moine.
L'histoire se répéte.
L'homme propose, et Dieu dispose.
L'honnêteté est la meilleure politique.
L'on ne saurait écorcher une pierre.
L'on passe la haie par où elle est plus basse.
L'or force le verrou.
La belle plume fait le bel oiseau.
La confiance appelle la confiance.
La femme du cordonnier est toujours mal chaussée.
La fortune ne fait pas le bonheur.
La fortune sourit aux audacieux.
La nuit porte conseil.
La nuit porte conseil.
La nuit tous les chats sont gris.
La parole a été donnée à l'homme pour déguiser sa pensée.
La parole est d'argent, mais le silence est d'or.
La parole est l'ombre du fait.
La parole s'enfuit, et l'écriture demeure.
La pomme ne tombe jamais loin de l'arbre.
La punition boite, mais elle arrive.
La raison du plus fort est toujours la meilleure.
La répétition est la mère de la mémoire.
La seconde pensée est la meilleure.
La variété plaît.
La vérité est dans le vin.
La vérité se dit en badinant.
Langue muette n'est jamais battue.
Le chien aboit, la caravane passe.
Le fait juge l'homme.
Le fil ténu casse.
Le mal appelle le mal.
Le meilleur n'en vaut rien.
Le miel est doux, mais l'abeille pique.
Le monde appartient à ceux qui se lèvent tôt.
Le plus grand malheur ou bonheur de l'homme est une femme.
Le remède est pire que le mal.
Le temps et l'usage rendent l'homme sage.
Le trop de précautions ne nuit jamais.
Les absents ont toujours tort.
Les apparences sont trompeuses.
Les bons comptes font les bons amis.
Les cordonniers sont les plus mal chaussés.
Les fous inventent les modes, et les sages les suivent.
Les goûts et les couleurs ne se discutent pas.
Les grands voleurs pendent les petits.
Les habitudes ont la vie dure.
Les murs ont des oreilles.
Les plaisanteries les plus courtes sont les meilleures.
Les premiers seront les derniers.
Les rats quittent le navire qui coule.
Les soucis font blanchir les cheveux de bonne heure.
Les volontés sont libres.
Loin des yeux, loin du cœur.
Mettre la charrue devant les bœufs.
Mieux vaut faire que dire.
Mieux vaut peu que rien.
Mieux vaut prévenir que guérir.
Mieux vaut que entre fou avec tous que sage tout seul.
Mieux vaut savoir que richesse.
Mieux vaut tenir que courir.
Mieux vaut un présent que deux futurs.
Mieux vaut être seul que mal accompagné.
Nature passe nourriture, et nourriture survainc nature.
Ne meurs cheval, herbe te vient.
Ne te mêle pas des affaires d'autrui.
Ne touchez pas aux blessures guéries.
Noblesse oblige.
Oignez vilain, il vous poindra. Poignez vilain, il vous oindra.
On a que ce que l'on mérite.
On n'est jamais si bien servi que par soi-même.
On naît poète, on devient orateur.
On ne change pas une équipe qui gagne.
On ne fait pas boire un âne qui n'a pas soif.
On ne jette des pierres qu'a l'arbre chargé de fruits.
On ne peut aider qui ne veut point écouter.
On ne prend pas les oiseaux à la tartelle.
On ne tue pas le loup parce qu'il est gris, mais parce qu'il a dévoré la brebis.
On prend plus de mouches avec du miel qu'avec du vinaigre.
On revient toujours<br />
à ses premières amours.
Par savoir vient avoir.
Patience et longueur de temps font plus que force ni que rage.
Patience passe science.
Pendant le faveur de la fortune, il faut se préparer à sa défaveur.
Personne ne peut être juge dans sa propre cause.
Petit poisson deviendra grand.
Pierre qui roule n'amasse pas mousse.
Plus ça change, plus c'est la même chose.
Pour estimer le doux, il faut goûter de l'amer.
Pour un de perdu, deux de retrouvés.
Prudence est la mère de súreté.
Quand on dîne avec le diable, il faut se munir d'une longue cuiller.
Quand on n'a pas ce que l'on aime, il faut aimer ce que l'on a.
Quand on n'a pas de tête, il faut avoir des jambes.
Quand on n'avance pas, on recule.
Que bien aime, tard oublie.
Qui a age, doit être sage.
Qui a bu, boira.
Qui a froid souffle le feu.
Qui a tête de cire ne doit pas s'approcher du feu.
Qui aime Dieu est sur en tout lieu.
Qui court deux lièvres à la fois, n'en prend aucun.
Qui m'aime aime mon chien.
Qui mal commence, mal achève.
Qui ne fait pas quand póte, nu face cand vrea.
Qui ne risque rien n'a rien.
Qui ne sait obéir, ne sait commander.
Qui parle trop, manque souvent.
Qui parle trop, personne ne l'écoute.
Qui s'attend à l'accueil d'autrui, a souvent mal dîné.
Qui s'excuse, s'accuse.
Qui se croit sage est un grand fou.
Qui se détourne évite le danger.
Qui se fait brebis, le loup le mange.
Qui se resemble, s'assemble.
Qui sème le vent, récolte la tempête.
Qui sème peu, peu récolte.
Qui trop embrasse mal étreint.
Qui veut plaire à tout le monde doit se lever de bonne heure.
Qui vole un œuf vole un bœuf.
Qui écoute aux portes, entend souvent sa propre honte.
Rejeter le bon et le mauvais.
Rendre le bien pour le mal.
Revenons à nos moutons.
Sans deniers Georges ne chante.
Sans tentation, il n'y a point de victoire.
Santé passe richesse.
Se couper le nez pour faire dépit à son visage.
Selon l'argent, la besogne.
Si jeunesse savait, si vieillesse pouvait.
Si la montagne ne va pas à Mahomet, Mahomet ira à la montagne.
Si le ciel tombait il y aurait bien des alouettes prises.
Si tous disent que tu es un âne, brais.
Si tu t'en fuis le, il te suivra, ce t'en fuiz, il s'en fuira.
Souvent on a coutume de baiser la main qu'on voudrait qui fût brûlée.
Tant crie l'on Noël, qu'il vient.
Tant va la cruche à l'eau qu'enfin elle se brise.
Tel maître, tel valet.
Tel père, tel fils.
Telle mère, telle fille.
Tirer les marrons de la patte du chat.
Tout ce qui branle ne tombe pas.
Tout chemin mène à Rome.
Tout est bien que finit bien.
Tout vient à point à qui sait attendre.
Trop enquérir n'est pas bon.
Un clou chasse l'autre.
Un jour sans vin est comme un jour sans soleil.
Un mal et un péril ne vient jamais seul.
Un peu d'aide fait grand bien.
Un point fait à temps en sauve cent.
Un tiens vaut, ce dit-on, mieux que deux tu l'auras.
Une hirondelle ne fait pas le printemps.
Ventre affamé n'a point d'oreilles.
Vive la différence.
Vive la modération, vive Pauline.
Vouloir, c'est pouvoir.
À bois noueux, hache affilée.
À chaque fou plaît sa marotte.
À chaque oiseau son nid est beau.
À cheval donné on ne regarde pas les dents
À confesseurs, médicins, avocats, la vérité ne cèle de ton cas.
À goupil endormi rien ne tombe en la gueule.
À grands maux, grands remèdes.
À l'étroit mais entre amis.
À l'œuvre, on connaît l'artisan.
À mauvais ouvrier point de bon outil.
À qui il a été beaucoup donné, il sera beaucoup demandé.
À raconter ses maux, souvent on les soulage.
À tort se lamente de la mer qui ne s'ennuie d'y retourner.
