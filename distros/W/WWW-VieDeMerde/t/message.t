#!perl -T

use Test::More;
use WWW::VieDeMerde;
use WWW::VieDeMerde::Message;

use utf8;

my $one = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<root><active_key>readonly</active_key><items><item
id="238320"><author>Belle</author><categorie>inclassable</categorie>
<date>2008-10-09T14:00:53+02:00</date><agree>3696</agree>
<deserved>5807</deserved><commentaires>82</commentaires>
<text>Aujourd'hui, j'attends le bus. Un minibus s'arrête devant moi.
Dedans, plein de gosses, dont un qui me regarde fixement en faisant une
affreuse grimace. Outrée, je lui fait mon plus beau doigt d'honneur. Le
minibus s'en va, et là, je vois à l'arrière &quot;École pour enfants
handicapés&quot;. J'ai honte.
VDM</text><commentable>1</commentable></item></items></root>
EOF

my $all = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<root><active_key>readonly</active_key><items><item
id="238320"><author>Belle</author><categorie>inclassable</categorie><date>2008-10-09T14:00:53+02:00</date><agree>3696</agree><deserved>5807</deserved><commentaires>82</commentaires><text>Aujourd'hui,
j'attends le bus. Un minibus s'arrête devant moi. Dedans, plein de
gosses, dont un qui me regarde fixement en faisant une affreuse grimace.
Outrée, je lui fait mon plus beau doigt d'honneur. Le minibus s'en va,
et là, je vois à l'arrière &quot;École pour enfants handicapés&quot;.
J'ai honte. VDM</text><commentable>1</commentable></item><item
id="238305"><author>cyberg</author><categorie>travail</categorie><date>2008-10-09T13:43:02+02:00</date><agree>5800</agree><deserved>350</deserved><commentaires>37</commentaires><text>Aujourd'hui,
mes collègues n'ont rien trouvé de mieux que de me refaire mon badge et
de le remettre dans mon vestiaire en mettant &quot;gynécologue&quot;
dessus. J'ai travaillé la matinée, dans le magasin de bricolage où je
bosse au rayon plomberie/sanitaire.
VDM</text><commentable>1</commentable></item><item
id="238213"><author>maggiethecat</author><categorie>inclassable</categorie><date>2008-10-09T11:35:17+02:00</date><agree>8072</agree><deserved>487</deserved><commentaires>29</commentaires><text>Aujourd'hui,
je me prends les pieds dans le trottoir et je m'étale de tout mon long
en plein centre-ville. Quand je me suis relevée, je me suis retrouvée
face à tout un cortège funéraire essayant tant bien que mal de ne pas
rire. Ok, j'ai égayé leur journée mais moi, j'ai mal !
VDM</text><commentable>1</commentable></item><item
id="238202"><author>nemito</author><categorie>argent</categorie><date>2008-10-09T11:16:44+02:00</date><agree>8022</agree><deserved>1164</deserved><commentaires>39</commentaires><text>Aujourd'hui,
début du mois, je suis déjà à découvert. Ce soir, je découvre dans ma
boîte aux lettres et pour la première fois de ma vie de jeune salariée,
l'existence de la taxe d'habitation.
VDM</text><commentable>1</commentable></item><item
id="238199"><author>Kiki</author><categorie>inclassable</categorie><date>2008-10-09T11:13:34+02:00</date><agree>4614</agree><deserved>6138</deserved><commentaires>41</commentaires><text>Aujourd'hui,
alors que je passais sur un passage pour piéton, c'est un pote qui se
trouve arrêté en voiture pour me laisser passer. Pour déconner, je me
mets à danser n'importe comment et montre mes fesses. Il ouvre la
portière, descend, et m'applaudit. C'était pas lui mais un illustre
inconnu. VDM</text><commentable>1</commentable></item><item
id="238137"><author>Speee</author><categorie>amour</categorie><date>2008-10-09T09:07:53+02:00</date><agree>10588</agree><deserved>542</deserved><commentaires>83</commentaires><text>Aujourd'hui,
mon copain m'a annoncé qu'il aimait être avec moi car on n'était pas
vraiment en couple. Ah bon ?
VDM</text><commentable>1</commentable></item><item
id="238102"><author>sottise</author><categorie>inclassable</categorie><date>2008-10-09T03:22:32+02:00</date><agree>9906</agree><deserved>854</deserved><commentaires>60</commentaires><text>Aujourd'hui,
j'ai mes règles et je suis en retard pour aller travailler. Je prends
une serviette hygiénique, enlève la partie collante et la pose à
l'envers sur le lit. Au moment de l'utiliser, introuvable ! Mes
collègues l'ont retrouvée : elle était collée sur mes fesses. Déjà 2h
que je bosse... VDM</text><commentable>1</commentable></item><item
id="238035"><author>riri</author><categorie>enfants</categorie><date>2008-10-08T23:59:50+02:00</date><agree>9307</agree><deserved>774</deserved><commentaires>81</commentaires><text>Aujourd'hui,
ma mère a raconté à mes potes que, lorsque j'étais petit, j'avais une
peur bleue du tyrolien dans le Juste Prix.
VDM</text><commentable>1</commentable></item><item
id="237736"><author>loliloling</author><categorie>enfants</categorie><date>2008-10-08T20:04:27+02:00</date><agree>11650</agree><deserved>786</deserved><commentaires>76</commentaires><text>Aujourd'hui,
en rentrant de mon travail, mon fils de 7 ans me dit que sa petite sœur
a vomi mais que c'est pas grave parce qu'il a passé l'aspirateur.
VDM</text><commentable>1</commentable></item><item
id="237727"><author>lilouette25</author><categorie>travail</categorie><date>2008-10-08T19:56:45+02:00</date><agree>12886</agree><deserved>1444</deserved><commentaires>87</commentaires><text>Aujourd'hui,
le prof a distribué les exposés en Sciences du langage. On choisissait
une date et on gagnait un sujet : j'ai eu les isotopies discursives à
disjonction paradigmatique et syntagmatique.
VDM</text><commentable>1</commentable></item><item
id="237670"><author>xplp</author><categorie>inclassable</categorie><date>2008-10-08T19:17:46+02:00</date><agree>12613</agree><deserved>1431</deserved><commentaires>61</commentaires><text>Aujourd'hui,
et depuis quelque temps, je sors tellement peu de chez moi et ma vie est
tellement nulle que je me suis fait un ami qui me ressemble. C'est un
pigeon amputé d'une patte. Je me suis pris de pitié pour lui, je le
nourris à ma fenêtre et lui parle.
VDM</text><commentable>1</commentable></item><item
id="237669"><author>doomiiino</author><categorie>inclassable</categorie><date>2008-10-08T19:17:27+02:00</date><agree>9689</agree><deserved>1258</deserved><commentaires>19</commentaires><text>Aujourd'hui,
j'ai appris que mon portable savait faire plein de choses ! Il a réussi
à s'allumer et à taper un mauvais code PIN trois fois de suite. Clap
clap clap, je n’aurais pas fait mieux.
VDM</text><commentable>1</commentable></item><item
id="237505"><author>Baloo51</author><categorie>argent</categorie><date>2008-10-08T17:10:09+02:00</date><agree>10155</agree><deserved>5500</deserved><commentaires>54</commentaires><text>Aujourd'hui,
en fouillant les poches d'un ancien manteau, j'ai retrouvé un chèque de
130 euros qui m'était destiné. C'est génial ! Enfin, ça le serait si on
était toujours en 2005.
VDM</text><commentable>1</commentable></item><item
id="237502"><author>çamousse</author><categorie>enfants</categorie><date>2008-10-08T17:09:06+02:00</date><agree>14029</agree><deserved>677</deserved><commentaires>84</commentaires><text>Aujourd'hui,
c'est mon jour de congé. J'attends un appel de mon patron pour la grande
réunion de demain. C'est ma fille, 6 ans, qui décroche. &quot;Maman peut
pas répondre, elle se touche dans la baignoire.&quot; En effet, j'étais
bien dans la baignoire, à me DOUCHER.
VDM</text><commentable>1</commentable></item><item
id="237429"><author>tatouaie</author><categorie>sante</categorie><date>2008-10-08T16:14:23+02:00</date><agree>11178</agree><deserved>2362</deserved><commentaires>65</commentaires><text>Aujourd'hui,
et comme chaque jour en rentrant chez moi, mon chien m'attend devant la
porte. Cette fois, il décide de me mordiller le mollet. Bon, ce ne
serait pas grave si, 2 h auparavant, je ne m'étais pas fait mon
tatouage... au mollet.
VDM</text><commentable>1</commentable></item></items><code>1</code><pubdate>2008-10-09T19:54:38+02:00</pubdate><erreurs></erreurs></root>
EOF

#' ;

my @good_ids = (238320, 238305, 238213, 238202, 238199, 238137, 238102,
           238035, 237736, 237727, 237670, 237669, 237505, 237502, 237429);

my @good_authors = qw/Belle cyberg maggiethecat nemito Kiki Speee
                    sottise riri loliloling lilouette25 xplp doomiiino Baloo51
                    çamousse tatouaie/;

BEGIN { my $plan = 0; }
plan tests => $plan;

my $t = XML::Twig->new();

BEGIN { $plan += 2; }
$t->parse($one);
my $root = $t->root;
my $vdms = $root->first_child('items');
my $vdm = $vdms->first_child('item');
my $vdm_parsed = WWW::VieDeMerde::Message->new($vdm);
ok(defined $vdm_parsed, "WWW::VieDeMerde::Message->new() returns something");
ok($vdm_parsed->isa('WWW::VieDeMerde::Message'), "with the right class");

$t->parse($all);
my @vdms = WWW::VieDeMerde::Message->parse($t);

BEGIN { $plan += 1; }
is(@vdms, 15, "there are 15 entries in the big extract");

BEGIN { $plan += 2; }
my @ids = map {$_->id} @vdms;
is_deeply(\@ids, \@good_ids, "goods ids for entries");
my @authors = map {$_->author} @vdms;
is_deeply(\@authors, \@good_authors, "good nicknames for authors");




