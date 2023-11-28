#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Kramerius::API4::Info;

if (@ARGV < 2) {
        print STDERR "Usage: $0 library_url lang\n";
        exit 1;
}
my $library_url = $ARGV[0];
my $lang = $ARGV[1];

my $obj = WebService::Kramerius::API4::Info->new(
        'library_url' => $library_url,
);

my $info_json = $obj->info($lang);

print $info_json."\n";

# Output for 'http://kramerius.mzk.cz/' and 'cs', pretty print.
# {
#   "rightMsg": "<div style=\"color:black;\">\n    <p>Vámi požadovaný dokument není možné volně prohlížet v souladu se zákonem č. 121/2000 Sb. (autorský zákon). Autorský zákon připouští zpřístupnění děl 70 let po smrti všech autorů (včetně překladatele, ilustrátora apod.) a 50 let od vydání díla. Noviny a časopisy se v Moravské zemské knihovně zpřístupňují po uplynutí 110 let od vydání. Doba trvání majetkových práv 110 let vyplývá ze <a href=\"https://smlouvy.gov.cz/smlouva/11093632\">smlouvy mezi NK ČR a DILIA</a>. Zpřístupnění děl je však možné provést až k 1. lednu roku následujícího.</p>\n    \n    <h4>Jak se k dokumentu dostanu?</h4>\n    <p>Můžete zkusit Vámi požadovaný dokument vyhledat na stránce <a href=\"http://dnnt.mzk.cz/\">http://dnnt.mzk.cz/</a>. Na této stránce jsou zpřístupněna díla nedostupná na trhu vydaná do roku 2000 (periodika až do roku 2010). Přístup k dílům nedostupným na trhu mají registrovaní čtenáři <a href=\"https://ndk.cz/knihinst\">zapojených institucí</a>. Jednou z nich je samozřejmě i Moravská zemská knihovna v Brně, jež nabízí svým uživatelům i možnost vzdálené <a href=\"https://www.mzk.cz/sluzby/registrace\">registrace</a>. Více informací ke zpřístupňování děl nedostupných na trhu naleznete na <a href=\"https://dnnt.nkp.cz/\">této stránce</a>.</p>\n    <p>Tento dokument je také přístupný registrovaným čtenářům na počítačích ve studovnách v budově <a href=\"https://www.mzk.cz/\">Moravské zemské knihovny v Brně</a> (před návštěvou si raději ověřte otevírací dobu). Po přihlášení na počítač zvolte na ploše ikonu aplikace \"Digitální knihovna MZK\", kde získáte přístup k plným textům v režimu pro čtení. Z těchto dokumentů lze zde i tisknout.</p>\n    \n    <h4>Nemohu se dostat do studovny MZK v Brně a požadovaný dokument není na seznamu děl nedostupných na trhu, jak mám postupovat?</h4>\n    <p>První možností je požádat o papírovou kopii digitálního dokumentu v Národní knihovně ČR, pokud mají stejný dokument ve vlastní digitální knihovně <a href=\"http://www.digitalniknihovna.cz/nkp\">Kramerius</a>. V takovém případě pak můžete vyplnit objednávkový <a href=\"http://www.nkp.cz/sluzby/formulare/kramerius-objednavka\">formulář</a>. Druhou možností je zajít do Vaší nejbližší knihovny a pokud titul fyzicky nemají, tak o něj zažádat prostřednictvím tzv. meziknihovní výpůjční služby. Pro získání informací o dostupnosti titulu a knihovně, která jej vlastní, můžete využít webu centrálního portálu <a href=\"https://www.knihovny.cz/\">Knihovny.cz</a>.</p>\n\n    <h4>Chybí Vám další informace?</h4>\n    <p>Nenašli jste zde všechny potřebné informace? Máte pocit, že některý z našich dokumentů není veřejně přístupný a měl by být? Chcete nahlásit nějakou chybu? Napište nám!\n    Veškeré dotazy vyřídíme přes emailovou adresu <a href=\"mailto:kramerius@mzk.cz\"  target=\"blank\">digitalniknihovna@mzk.cz</a>.</p>\n</div>\n\n",
#   "intro": "﻿Vítejte v Digitální knihovně. Digitální knihovna nabízí digitální dokumenty prostřednictvím systému Kramerius a obsahuje jak volná, tak autorsky chráněná díla různých žánrů ve webovém rozhraní s přístupem k více digitálním knihovnám v ČR. Design webu Digitální knihovny přináší jednoduchý a srozumitelný způsob práce s digitálními dokumenty. Provozovatelem Digitální knihovny je Moravská zemská knihovna v Brně.\n</br>\n</br>\n<h3>Obsah Digitální knihovny</h3>\n\n<p>V Digitální knihovně najdete digitalizované knihy, noviny a časopisy, mapy, rukopisy, archiválie, zvukové nahrávky, grafiky, hudebniny a elektronické dokumenty vytvořené přímo v digitální podobě (např. odborné sborníky).\n\n<p>Na dokumenty je odkazováno z portálu <a target=\"blank\" href=\"https://knihovny.cz\">Knihovny.cz</a> a knihovního katalogu MZK <a target=\"blank\" href=\"https://vufind.mzk.cz/Search/Home\">Vufind</a>. Odkaz je pojmenován jako Digitalizovaný dokument.\n\n</p>\n<p>Stručný návod pro práci s Digitální knihovnou najdete <a target=\"blank\" href=\"https://www.mzk.cz/sluzby/navody/digitalni-knihovna-kramerius\">zde</a>.\n</p>\n\n<h3>Autorsko-právní ochrana</h3>\n<p>Některé dokumenty jsou přístupné veřejně a některé lze prohlížet pouze v budově knihovny z důvodu autorsko-právní ochrany. Zpřístupnit dokumenty veřejně můžeme až 70 let po smrti autora či spoluautora a 50 let trvají nakladatelská práva.</p>\n<p>Pokud se Vám zdá, že by dokument měl být veřejně přístupný, <a href=\"mailto:digitalniknihovna@mzk.cz\">napište buď nám</a> nebo přímo do knihovny, která digitální dokument vlastní.</p>\n<br/>\n<p>Jakékoliv připomínky pište na mail <a href=\"mailto:digitalniknihovna@mzk.cz\">digitalniknihovna@mzk.cz</a>.</p>\n</br>\n<p>\n<small>\nPoslední aktualizace 3. února 2021, Markéta Krutská</small>\n</p>\n",
#   "pdfMaxRange": "100",
#   "version": "5.7.2",
#   "hash": "965ef7014605959ef0c62a8c13935c6d648dc15d"
# }