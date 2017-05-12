# -*- Mode: cperl -*-

use Test::More tests => 3;

use Win32::Socketpair 'winsocketpair', 'winopen2';
ok(1, "loaded");

alarm 60;

my $data;

{ local $/; $data = <DATA> }

my $in = $data;
my $out = '';
my $mid = '';
my $mid_done;

my ($here, $there) = winsocketpair;

my $true = 1;
ioctl( $here, 0x8004667e, \$true );
ioctl( $there, 0x8004667e, \$true );

while (1) {
    my $vin = '';
    vec($vin, fileno $there, 1) = 1 unless $mid_done;
    vec($vin, fileno $here, 1) = 1;

    my $vout = '';
    vec($vout, fileno $here, 1) = 1 if length $in;
    vec($vout, fileno $there, 1) = 1 if length $mid;

    if (select($vin, $vout, undef, undef) > 0) {
    if (vec($vin, fileno $there, 1)) {
        unless (sysread($there, $mid, 20, length $mid)) {
        $mid_done = 1;
        shutdown($there, 1) unless length $mid;
        }
    }
    if (vec($vin, fileno $here, 1)) {
        sysread($here, $out, 1037, length $out)
        or last;
    }
    if (vec($vout, fileno $here, 1)) {
        my $written = syswrite($here, $in, 980);
        last unless $written;
        substr($in, 0, $written, '');
        shutdown($here, 1) unless length $in;
    }
    if (vec($vout, fileno $there, 1)) {
        my $written = syswrite($there, $mid, 1356);
        last unless $written;
        substr($mid, 0, $written, '');
        shutdown($there, 1) if (!length $mid and $mid_done);
    }
    }
}

is ($mid, "", "mid empty");
is ($out, $data, "transfer");

=disabled until I work out why it doesn't work.

my ($pid, $socket) = winopen2("more");
ok($pid, "winopen2 pid");
ok(fileno($socket), "winopen2 socket");
binmode($socket);
ioctl( $socket, 0x8004667e, \$true );

$in = $data;
$out = "";

while(1) {
    my $v = '';
    vec($v, fileno $socket, 1) = 1;

    my $vout = length $in ? $v : "";
    my $vin = $v;

    if (select($vin, $vout, undef, undef) > 0) {
    if (vec($vin, fileno($socket), 1)) {
        sysread($socket, $out, 30, length $out)
        or last;
    }
    if (vec($vout, fileno($socket), 1)) {
        my $written = syswrite($socket, $in, 5000)
        or last;
        substr($in, 0, $written, "");
        shutdown($socket, 1) unless length $in;
    }
    }
}
$out =~ s/[^a-z]//sg;
$data =~ s/[^a-z]//sg;
is($out, $data, "open2 more");
=cut

alarm 0;

0;
__DATA__


Rosalía de Castro - Conto gallego

[Nota preliminar: Edición digital a partir de Almanaque gallego... por
Manuel de Castro y López, Buenos Aires, 1923, pp. 95-104, cotejada con
la edición crítica de Mauro Armiño (Obra completa, III, Madrid, Akal,
1980, pp. 517-530) y la de Manuel Arroyo Stephens (Obras completas,
II, Madrid, Fundación José Antonio Castro, 1993, pp. 617-627).]


Un día de inverno ó caer da tarde, dous amigos que eran amigos desde a
escola, e que contaban de anos o maldito número de tres veces dez,
camiñaban a bon paso un sobre unha mula branca, gorda e de redondas
ancas, i outro encima dos seus pés, que non parecían asañarse das
pasadas lixeiras que lles facía dar seu dono.

O da pe corría tanto como o de acabalo, que vendo o sudor que lle
corría ó seu compañeiro pola frente i as puntas dos cabelos, díxolle:

-¿E ti, Lourenzo, por que non mercas un come-toxos que te leve e te
traia por estes camiños de Dios? Que esto de andar leguas a pé por
montes e areales é bo prós cás.

-¡Come-toxos! Anda, e que os monten aqueles pra quens se fixeron, que
non é Lourenzo. Cabalo grande, ande ou non ande, e xa que grande non o
podo ter, sin él me quedo e sírvome dos meus pés que nin beben, nin
comen, nin lle fan menester arreos.

-Verdade é que o teu modo de camiñar é máis barato que ningún ¡negro
de min!, que ora teño que pagar o portasgo sólo porque vou en besta, e
non coma ti, nestes pés que Dios me dou. Pro... así coma así, gusto de
andar as xornadas en pernas alleas pra que as de un non cansen, e xa o
dixen: debías mercar un farroupeiro pra o teu descanso. Mais ti fas
coma o outro: hoxe o gano, hoxe o como, que mañán Dios dirá. Nin tes
arrello nin cousa que o valla; gústanche os birbirichos i as
birbiricheiras, o viño do Ribeiro e as ostras do Carril. ¡Lourenzo!,
debías casarte que ó fin o tempo vai andando, os anos corren, e un
probe de un home faise vello e cróbese de pelos brancos antes de que
poida ter manta na cama e aforrar pra unha ocasión; e esto, Lourenzo,
non se fai sin muller que teña man da casa e garde o diñeiro que un
gana.

-Boi solto, ben se lambe.

-¡O vento! Esas sonche faladurías. ¿Ó derradeiro, pra qué os homes
naceron si non é pra axuntarse cas mulleres, fillo da túa nai?
(Lourenzo tuse). Seica te costipache co resío da serán, malo de
ti. (Lourenzo volve a tusir). Léveme Dios si non é certo, e tanto non
tusiras si ora viñeras a carranchaperna enriba de un farroupeiro.

-¿Costipado eu? Non o estiven na miña vida e penso que ora
tampouco. Pro... sempre que se me fala de casar dame unha tos
que... ¡hem!... ¡hem!... seica esto non é boa siñal. ¿Non cho parece,
Xan?

-O que me parés é que eres rabudo como as uvas do cacho, e eso venche
xa de nacenza, que non polo ben que te estimo deixo de conocer que
eres atravesado coma os cangrexos. Nin podo adiviñar por que falas mal
das mulleres, que tan ben te queren e que te arrolan nas fiadas e nas
festas coma a fillo de rei e sabendo que túa nai foi muller, e que, si
túa nai non fora, ti non viñeras ó mundo coma cada un de tantos.

-Nin moito se perdera anque nunca acá chegara. Que mellor que sudando
polos camiños pra ganar o pan de boca, e mellor que rechinar nas
festas e non nas festas, con meniñas que caras se venden sin valer un
chavo, engañando ós homes, estaría aló na mente de Dios.

-¡Diancre de home!, que mesmo ás veces penso se eres de aqueles que
saúdan ó crego sólo por que non digan. E pois, ti es dono de decir
canto queiras, pro eu tamén che digo que me fai falta un acheguiño, e
que me vou casare antes da festa, así Dios me dé saúde.

-E premita el Señore que non sudes moito, Xan, anque ora é inverno,
que entonces si que inda tusirás máis que eu cando de casar me
falan. E adivírtoche que teñas tino de non matar carneiros na festa,
que é mal encomenzo pra un casado, por aquelo dos cornos retortos que
se guindan ó pé da porta, e xa se sabe que un mal tira por
outro. ¡Diono libre!

-¿E ti qués saber que xa me van parecendo contos de vella eso que se
fala de cornos e de maldade das mulleres? Pois cando nesta nosa terra
se dá en decir que un can rabiou, sea certo ou non sea certo, corre a
bóla e mátase o can. Mais eu por min che aseguro que no atopei nunca
muller solteir que non se fixese mui rogada, nin casada que o seu home
comigo falase; e paréseme que aínda non fago tan mal rapaz, anque o
decilo sea fachenda.

-É que eso vai no axeitarse, e ti seica no acertache, Xan; que ó
demais coma un home queira, non queda can tras palleiro. Eu cho digo,
non hai neste mundo máis muller boa pra os homes que aquela que os
pariu, i así, arrenega de elas coma do demo, Xan, que a muller demo é,
según di non sei que santo moi sabido; i o demo hastra á cruz lle fai
os cornos de lonxe.

-¡Volta cos cornos!

-É tan sabido que si tanto mal che fai anomealos, é porque xa che dan
sombra dende o tellado da que a de ser túa muller.

-¡Seica me queres aqueloutrare! Pouco a pouco, Lourenzo, que nin debes
falar así de quen non conoces, nin tódaslas mulleres han de ter o ollo
alegre, que por moitas eu sei por quen se poidera poñer, non unha,
senón cen vidas.

-O dito, dito queda, que cando eu falo é con concencia; e repítoche
que, sendo muller, non quedo por ningunha, anque sea condesa ou de
sangre nobre, como solen decir, que unhas e outras foron feitas da
mesma masa e coxean do mesmo pé. Dios che mas libre do meu lar, que
ora no lar alleo aínda nas cuspo.

-¡Ah! ladrón da honra allea, léveche o deño si eu quixera que cuspiras
na do meu, que o pensamento de que quizais terei que manter muller pra
un rabudo coma ti faime pór os cabelos dreitos e o entendimento
pensatible. Pro... falemos craros, Lourenzo, coma bos compañeiros que
somos. Ti es máis listo que eu, ben o vexo, e por donde andes sábeste
amañar que adimira, mentras que eu me quedo ó pé do lume vendo como o
pote ferve e cantan os grilos. Se conto, o conto vai no amaño... pro
esto de que as has de botar todas nunha manada, sin deixar unha pra
min, vállanme tódolos santos que me fai suare. ¡Vaia!, dime que aínda
viches mulleres boas, e que non todas lle saben poñer a un home
honrado os cornos na testa.

-Todas, Xan, todas; e pra os Xans aínda máis; que mesmo parés que o
nome as atenta.

-¡Condenicado de min, que seique é certo! Pro meu pai e miña nai
casáronse e ieu me quero casare, que mesmo se me van os ollos cando
vexo ó anoitecido un matrimonio que fala paseniño sentado á porta da
eira, mentras corren os meniños á luz do luar por embaixo das
figueiras.

-¡Ó aire, ó aire! ¡E déixate de faladurías! Paseniño que paseniño,
tamén se dan beliscos e rabuñadas, e paseniño se fan as figas.

-En verdade, malo me vai parecendo o casoiro, pro moito me temo que a
afición non me faga prevaricare. Mais sempre que me case, caisareime
cunha do meu tempo, cheíña de carne, con xuício e facendosa, que poida
que neso no haxa tanto mal... ¿Que me dis?

-Que es terco coma unha burra. Ti telo deño, Xan, i ora estache
facendo as cóchegas co casoiro. Pro ten entendido que non hai volta
sinón que Diolo mande, que tratándose de aquelo da franqueza das
mulleres, todas deitan coma as cestas e cán coma si non tivesen pés.

Así falando Xan e Lourenzo, iban chegando a cerca de un lugar. E como
xa de lonxe empezasen a sentir berros e choros, despois de un alto,
por saber o que aló pasaba, viron que era un enterro, e a un rapaz que
viña polo camino preguntáronlle polo morto, e respondeulles que era un
home de unha muller que inda moza quedaba viuda e sin fillos que nunca
tivera, e que o morto non era nativo de aquela aldea, pro que tiña
noutra hardeiros.

Foise o rapaz, e Lourenzo, chegándose a Xan, díxolle entonces:

-¿E ti qués, Xan, que che faga ver o que son as mulleres, que ora a
ocasión é boa?

-¿E pois como?

-Facendo que esa viuda, que non sei quen é, nin vin na miña vida, me
dé nesta mesma noite palabra de casamento pra de aquí a un mes.

-¿E ti estás cordo, Lourenzo?

-Máis que ti, Xan; ¿qués ou non qués?

-E pois ben, tolo. Vamos a apostare, e si ganas perdo a miña mula
branca que herdei do meu pai logo fará un ano, e que a estimo por esto
e por ser boa como as niñas dos ollos. Curareime entonces do mal de
casoiro; pro si ti perdes, tes que mercar un farroupeiro e non volver
a falar mal das mulleres, miñas xoias, que aínda as quero máis que á
miña muliña branca.

-Apostado. Báixate, pois, da mula, e fai desde agora todo o que che eu
diga sin chistar, e hastra mañán pola fresca nin ti es Xan nin eu
Lourenzo, sinón que ti es meu criado i eu son teu amo. Agora ven tras
min tendo conta da mula, que eu irei diante, e di a todo amén.

Meu dito, meu feito.

Lourenzo tirou diante e Xan botou a pé, indo detrás ca mula polas
bridas, que eran monas, así coma os demais arreos, e metían moita
pantalla.

Ó mesmo tempo que eles iban chegando ó Campo Santo, iña chegando tamén
o enterro, rompendo a marcha o estandarte negro e algo furado da
parroquia, o crego i as mulleres que lle facían o pranto, turrando,
turrando polos pelos como si fosen cousa allea, berrando hastra
enroucare e agarrándose á tomba de tal maneira que non deixaban andar
ós que a levaban.

-¡Ai, Antón! ¡Antón! -decía unha poñéndose como a Madalena cas mans
cruzadas enriba da cabeza-. Antón, meu amigo, que sempre me decías:
«¡Adiós, Mariquiña!» cando me topabas no camiño. ¡Adiós, Antón, que xa
non te verei máis!

I outra, indo arrastro atrás da caixa e pegando en sí, desía tamén:

-¿En onde estás, Antón, que xa non me falas? Antón, malpocadiño, que
che fixeron as miñas más uns calzós de lenzo crúo e non os puxeches,
Antón; ¿quen ha de pór agora a túa chaqueta nova i os teus calzós,
Antón?

I a viuda, i unhas sobriñas da viuda, todas cubertas de bágoas,
vestidas de loito e os periquitos desfeitos de tanto turrar por eles,
e os panos desatados, berrando ainda máis; sobre todo a viuda, que
indo de cando en cando a meterse debaixo da mesma tomba, de donde a
tiñan que arrancar por forza, decía:

-¡Ai, meu tío!1¡Ai, meu tío, bonito como unha prata e roxiño como un
ouro, que cedo che vai comela terra as túas carniñas de manteiga! ¡E
ti vaste, meu tío! ¿Ti vaste? ¿E quen sera agora o meu acheguiño, e
quen me dirá como me decías ti, meu ben: «Come, Margaridiña, come pra
engordare, que o teu é meu, Margaridiña, e si ti coxeas, tamén a min
me perece que estou coxo»? ¡Adiós, meu tío, que xa nunca máis
dormiremos xuntiños nun leito! ¡Quen me dera ir contigo na tomba,
Antón, meu tío, que ó fin contigo, miña xoíña, entérrase meu corazón!

Así a viudiña se desdichaba seguindo ó morto, cando de repente,
meténdose Lourenzo entre as mulleres, cubertos os ollos cun pano e
saloucando como si lle saíse da ialma, escramou berrando, aínda máis
que as do pranto:

-¡Ai, meu tío!, ¡ai, meu tío, que ora vexo ir mortiño nesa tomba!
Nunca eu aquí viñera pra non te atopar vivo, e non é polo testamento
que fixeches en favor meu deixándome por hardeiro, que sempre te
quisen como a pai, e esto que me habías de chamar para despedirte de
min e que te hei de ver xa morto, párteme as cordas do corazón. ¡Ai,
meu tío! ¡ai, meu tío!, que mesmo me morro ca pena.

Cando esto oíron todas as do pranto, puxéronse arredor de Lourenzo,
que mesmo se desfacía á uña de tanto dór como parecía ter.

-¿E logo ti como te chamas, meu fillo? -lle preguntaron moi
compadecidas de el.

-Eu chámome Andruco, e son sobriño do meu tío, que me deixou por
hardeiro e me mandou chamare por unha carta pra se despedir de min
antes de morrer; pro, como tiven que andar moita terra, xa sólo o podo
ver na tomba. ¡Ai, meu tío! ¡Ai, meu tío!

-¿E ti de onde es, mozo?

-Eu son da terra do meu tío -volveu a desir Lourenzo, saloucando
hastra cortárselle a fala.

-¿E teu tío de dónde era?

-Meu tío era da miña terra.

E sin que o poideran quitar de esto, Lourenzo, proseguindo co pranto,
foise achegando á viudiña, que, aínda por entre as bágoas que a
curbían, poido atisvare aquel mozo garrido que tanto choraba polo seu
tío. Despois que se viron xuntos, logo lle dixo Lourenzo que era
hardeiro do difunto, i ela mirouno con moi bos ollos, e, acabado o
enterro, díxolle que tiña que ir co ela á súa casa, que non era xusto
parase noutra o sobriño do seu home, e que así chorarían xuntos a súa
disgrasia.

-Disgrasia moita. ¡Ai, meu tío! -dixo Lourenzo-; pro consoládevos, que
co que él me deixou conto facerlle decir moitas misas pola ialma, para
que el descanse e poidamos ter nós maior consolo acá na terra, que ó
fin, ña tía, Dios mándanos ter pacencia cos traballos, e... que
queiras que non queiras, como dixo o ioutro, a terriña cai enriba dos
corpos mortos e... ¿que hai que facer? Nós tamén temos que ir, que así
é o mundo.

Así falando e chorando, tornaron camiño da casa da viuda, e Xan, que
iba detrás ca mula e que nun principio non entendera nin chisca do que
quería facer Lourenzo, comenzou a enxergare e pasoulle así, polas
carnes unha especie de escallofrío, pensando en si iría a perder a súa
mula branca. Anque, a ver o dor e as bágoas da viudiña, que non lle
deixaban de correr a fío pola cara afrixida, volveu a ter confianza en
Dios e nas mulleres, a quen tan ben quería.

-¿E vós, ña tía, terés un sitiño pra meter esta mula i o meu criado,
que un e outro de tanto camiñare veñen cansados coma raposos?

-Todo terei pra vós, sobriño do meu tío, que mesmo con vervos pareceme
que o estou vendo e sérveme de moito consolo.

-¡Dencho ca viudiña, os consolos que atopa! -marmurou Xan pra si
metendo a mula no pesebre. Pro de esto a casarse -añadeu, contento de
si mesmo-, aínda hai la mare.

E co esta espranza póxose a comer con moitas ganas un bo anaco de
lacón que a viuda lle deu, mollándoo co unha cunca de viño do Ribeiro
que ardía nun candil e que lle alegrou a pestana, mentras tía e
sobriño estaban aló enriba no sobrado, falando da herencia e do morto
cos que os acompañaban.

De esta maneira pasouse o día e chegou a noite, e quedaron solos na
casa a viuda, Lourenzo e Xan, que desque viu cerrar as portas estuvo á
axexa, co corazón posto na muliña branca, a ialma en Lourenzo e a
espranza en Dios, que non era pra menos. E, non sin pena, veu coma a
viudiña e Lourenzo foron ceando, antre as bágoas, uns bocados de porco
e de vaca que puñan medo ós cristianos e uns xarros de viño que foran
capaces de dar ánimos ó peito máis angustiado. Pro ó mesmo tempo nada
se falaba do particulare, e Xan non podía adiviñare como se axeitaría
Lourenzo, pra ganar a aposta, que vía por súa.

Ó fin trataron de se ir deitar, e a Xan puxéronselle os cabelos
dreitos cando veu que en toda a casa non había máis que a cama do
matrimonio, e que a viudiña tanto petelescou pra que Lourenzo se
deitase nela que aquél tivo que obedecer, indo ela, envolta nun
mantelo, a meterse detrás de un trabado que no sobrado había.

Xan, ca ialma nun fío, viu, desde o faiado, donde lle votaron unhas
pallas, coma a viudiña matou o candil e todo quedou ás escuras.

-Seica quedarás comigo, miña muliña branca, i abofé que te vin perdida
-escramou entonces-; ó fin as mulleres foron feitas de unha nosa
costilla e algo han de ter de bo. Sálvame, viudiña, sálvame de este
apreto, que inda serei capaz de me casar contigo.

Deste modo falaba Xan pra si, anque ó mesmo tempo non podía cerrar
ollo, que a cada paso lle parecía que ruxían as pallas.

Así pasou unha hora longa, en que Xan, contento, xa iba a dormir,
descoidado, cando de pronto oieu, primeiro un sospiro, e despois
outro, cal si aqueles sospiros fosen de alma do outro mundo;
estremeceuse Xan e ergueuse pra escoitar mellore.

-¡Ai!, ¡meu tío!, ¡meu tío! -dixo entonces a viudiña; ¡que fría estou
neste taboado, pro máis frío estás, ti, meu tío, nesa terriña que te
vai comere!

-¡Ai, meu tío!, ¡meu tío! -escramou Lourenzo da outra banda, como si
falase consigo mesmo-; canto me acordo de ti, que estou no quente, e
ti no Campo Santo, nun leito de terra donde xa non tes compañía.

-¡Ai! ¡Antonciño! -volveu a decir a viuda-, ¡que será de ti naquel
burato, meu queridiño, cando eu que estou baixo cuberto...!, ¡bu, bu,
bu!... ¡qué frío va!, ¡tembro como si tuvese a perlesía!, ¡bu, bu,
bu!...

-¡Miña tía!

-¿E seica non dormes, meu sobriño?

-E seica vós tampouco, ña tía, que vos sento tembrare como unha vara
verde.

-¿Como qués ti que durma, acordándome nesta noite de xiada do teu tío,
que ora dorme no Campo Santo, frío como a neve, cando si el vivira
dormiríamos ambos quentiños nese leito donde ti estás?

-¿E non podiades vós poñervos aquí nun ladiño, anque fora envolta no
mantelo coma estades, e aínda máis habendo necesidá como agora, xa que
non queres que eu vaia dormir ó chan, que mesmo pode darvos un frato
co dór e co frío, i é pecado, ña tía, tentar contra a saúde?

-Deixa, meu fillo, deixa; que aunque penso que mal no houbera en que
eu me deitase ó lado de un sobriño como ti, envolta no mantelo e por
riba da roupa, estanto como estoxi tembrando, ¡bu, bu, bu!... quérome
ir afacendo, que moitas de estas noites han de vir pra min no mundo,
que si antes fora rica e casada agora son viuda e probe; e canto tiven
meu agora teu é, que a min non me queda máis que o ceo i a terra.

-E... pois, miña tía... Aquí pra entre dous pecadores, e sin que naide
nos oia máis que Dios, vouvos a decire que eu sei de un home rico e da
sangre do voso difuntiño que, si vós quixérades, tomaríavos por
muller.

-Cala, sobriño, e no me fales de outro home... que inda parés que o
que tiven está vivo.

-Deixá, miña tía, que así non perderedes nin casa, nin leito, nin
facenda, que é moito perder de unha vez, sin contar co meu tío; a quen
lle hei de dicir moitas misas, como días ten o ano, pra que descanse e
non vos veña a chamar nas noites de inverno. Así el estará aló ben, e
vós aquí; e si el vivira, non outra cousa vos aconsellara, senón que
tomárades outra ves home da súa sangre, a quen lle deixou o que él e
vós coméchedes xuntos na súa vida.

-E seica tes razón, meu sobriño, pro... ¡si este era o teu pensamento,
Antón, meu tío!, ¿por que non mo dixeche antes de morrer, que entonces
eu o fixera anque fora contra voluntade, sólo por te servire?

-Pola miña conta, ña tía, que si meu tío nada vos dixo, foi porque se
lle esquenceu co conto das agonías, e non vos estrañe, que a calquera
lle pasara outro tanto.

-Tes razón, tes; a morte é moi negra e naquela hora todo se
esquence. ¡Ai!, ¡meu tío!, ¡meu tío! ¿Que non fixera eu por che dar
gusto?, bu, bu, bu!... ¡que frío vai!

-Vinde pra aquí, que, si non vos asañás, direivos que eu son o que vos
quer por muller.

-¿Ti que me dis, home? Pro, à ver que o adiviñei logo; que sólo un
sobriño do meu tío lle quixera cumprir así a voluntade...

-Pro é ser, tiña que ser de aquí a un mes, que despois teño que ir a
Cais en busca de outra herencia, e quixera que antes quedárades outra
vez dona do que foi voso. O que ha de ser, sea logo, que ó fin meu tío
haio de estar deseando desde a tomba.

-¡Ai!, ¡meu tío!, ¡meu tío!, que sobriño che dou Dios, que mesmo de
oílo paréceme que te estou oíndo; pro... meu fillo... é aínda moi
cedo, e anque ti máis eu nos volvéramos a casar ca intención de lle
facer honra e recordar ó difunto, o mundo murmura... e...

-Deixávos do mundo, que casaremos en secreto e naide o saberá.

-E pois ben, meu sobriño, e sólo pro que es da sangre do meu tío, e xa
que me dis que se ha de alegrar na tomba de vernos xuntos... co
demáis... ¡ai!, Dios me valla... eu queríalle moito a meu tío! ¡Bu,
bu, bu!... ¡como xía!

-Vinde pra onda min envolta no mantelo, que non é pecado xa que habés
de ser miña muller.

-Pro... aínda non a son, meniño, e teño remorsos... ¡Bu, bu, bu!, que
frato me dá pola cabeza e polo corazon.

-Ña tía, vinde e deixávos de atentar contra a saúde, que se al
pecásedes, antes de casar témonos que confesare.

-Irei, logo... irei, que necesito un pouco de caloriño.

Entonces sintíronse pasadas, ruxiron as pallas, e a viuda escramou con
moita dolore:

-¡Ai, miña Virxen do Carmen, que axiña te ofendo!

-¡Ai, miña muliña branca, que axiña te perdo! -marmurou entonces Xan,
con sentimento e con coraxe. E chegándose enseguida á porta do
sobrado, berrou con forza:

-¡Meu amo, a casa arde!

-Non arde, home, non, que é rescoldo.

-Pois rescoldo ou lúa, si agora non vindes voume ca mula.

E Lourenzo, saltando de un golpe ó chan, dixo:

-Agarda logo... Esperaime, ña tía, que logo volvo.

E hai cen anos que foi esto, e aínda hoxe espera a viuda polo sobriño
do seu tío.


