use Test::More;
use utf8;

use Text::Info;

my %tests = (
    'Dette er første setning. Dette er andre setning. Går det bra å f.eks. forkorte "for eksempel"?' => [
        'Dette er første setning',
        'Dette er andre setning',
        'Går det bra å f.eks. forkorte "for eksempel"',
    ],

    "Pierre Vinken, 61 years old, will join the board as a nonexecutive director Nov. 29. Mr. Vinken is chairman of Elsevier N.V., the Dutch publishing group. Rudolph Agnew, 55 years old and former chairman of Consolidated Gold Fields PLC, was named a director of this British industrial conglomerate." => [
        "Pierre Vinken, 61 years old, will join the board as a nonexecutive director Nov. 29",
        "Mr. Vinken is chairman of Elsevier N.V., the Dutch publishing group",
        "Rudolph Agnew, 55 years old and former chairman of Consolidated Gold Fields PLC, was named a director of this British industrial conglomerate",
    ],

    "«I motsetning til andre drittpakker, så inneholdt denne dritt», skriver Pål Hansen, regionredaktør i NRK Troms og Finnmark." => [
        "«I motsetning til andre drittpakker, så inneholdt denne dritt», skriver Pål Hansen, regionredaktør i NRK Troms og Finnmark",
    ],

    "Den 29. januar skjedde det noe. Ingen vet helt - for å si det sånn - hva som skjedde. Men det skjedde rundt kl. 12.13, sånn ca. Eller kanskje det var nærmere kl. 12:13.43? Uansett så var det noe som involvert 12 kg. torsk!" => [
        "Den 29. januar skjedde det noe",
        "Ingen vet helt - for å si det sånn - hva som skjedde",
        "Men det skjedde rundt kl. 12.13, sånn ca",
        "Eller kanskje det var nærmere kl. 12:13.43",
        "Uansett så var det noe som involvert 12 kg. torsk",
    ],

    "Omtrent klokka 16.30 i dag fikk politiet melding om at det var løsnet skudd i Tøyengata i Oslo, og at en mann var truffet." => [
        "Omtrent klokka 16.30 i dag fikk politiet melding om at det var løsnet skudd i Tøyengata i Oslo, og at en mann var truffet",
    ],

    "Vi ville også spørre om det er med hensikt innslaget fortsatt er tilgjengelig på nrk.no via et Google-søk." => [
        "Vi ville også spørre om det er med hensikt innslaget fortsatt er tilgjengelig på nrk.no via et Google-søk",
    ],

    "I tillegg er det ekstremt viktig for utøverne, som har lagt opp sesongen sin ut fra en plan, sier daglig leder Henning Andersen til VG. I utgangspunktet var fristen til å skaffe pengene 15. januar, men den ble siden forlenget med tre dager." => [
        "I tillegg er det ekstremt viktig for utøverne, som har lagt opp sesongen sin ut fra en plan, sier daglig leder Henning Andersen til VG",
        "I utgangspunktet var fristen til å skaffe pengene 15. januar, men den ble siden forlenget med tre dager",
    ],

    "Og så var det... noe annet som skjedde..." => [
        "Og så var det... noe annet som skjedde",
    ],

    "Og så var det...noe annet som skjedde..." => [
        # TODO: Should probably fix this so that "det... noe" is retained.
        "Og så var det...noe annet som skjedde",
    ],

    '- Det er noe helt spesielt med "Riskafjord", sier en tydelig spent og litt nervøs Magne T. Frøyland i styret i AS Riskafjord.' => [
        'Det er noe helt spesielt med "Riskafjord", sier en tydelig spent og litt nervøs Magne T. Frøyland i styret i AS Riskafjord',
    ],

    "-27. januar at Kåstad forteller historier fra boken på barneskoler." => [
        "27. januar at Kåstad forteller historier fra boken på barneskoler",
    ],

    "-27. jan. at Kåstad forteller historier fra boken på barneskoler." => [
        "27. jan. at Kåstad forteller historier fra boken på barneskoler",
    ],

    "Politiet innrømmer at virkeligheten har endret seg etter terrorangrepet 22/7. - Tiltakene vi har iverksatt er i overkant av hva saken skulle tilsi, men det er rett og slett for å ikke ta noen sjanser, opplyser Fredriksen." => [
        "Politiet innrømmer at virkeligheten har endret seg etter terrorangrepet 22/7",
        "Tiltakene vi har iverksatt er i overkant av hva saken skulle tilsi, men det er rett og slett for å ikke ta noen sjanser, opplyser Fredriksen",
    ],

    "Det ble bare 15. plass på Tora Berger i dag." => [
        "Det ble bare 15. plass på Tora Berger i dag",
    ],

    "Det norske laget drar til Val di Fiemme proppfulle av selvtillit og med det suksessrike VM i Oslo i 2011 frisk i minne. Den gang ble Petter Northug jr. den ubestridte VM-kongen med intet mindre enn fem medaljer, hvorav tre kom i den edleste valøren." => [
        "Det norske laget drar til Val di Fiemme proppfulle av selvtillit og med det suksessrike VM i Oslo i 2011 frisk i minne",
        "Den gang ble Petter Northug jr. den ubestridte VM-kongen med intet mindre enn fem medaljer, hvorav tre kom i den edleste valøren",
    ],

    "The work to choose a successor to retired Benedict XVI begins in earnest Tuesday, as the cardinals charged with the task prepare to be locked away in a secret election, or conclave, in Vatican City. One of their number will almost certainly emerge from the process as the new spiritual leader of the world's 1.2 billion Roman Catholics. Applause echoed round St. Peter's as Cardinal Angelo Sodano, dean of the College of Cardinals, offered thanks for the \"brilliant pontificate\" of Benedict XVI, whose shock resignation precipitated the selection of a new pope. \"My brothers, let us pray that the Lord will grant us a pontiff who will embrace this noble mission with a generous heart,\" he concluded. In the afternoon, the 115 cardinal-electors -- those younger than 80 who are eligible to vote -- will go to the Pauline Chapel for further prayers. If they do, it's likely the first smoke might be seen around 8 p.m. (3 p.m. ET), he said. If they do, it's likely the first smoke might be seen around 8 pm. (3 pm. ET), he said." => [
        "The work to choose a successor to retired Benedict XVI begins in earnest Tuesday, as the cardinals charged with the task prepare to be locked away in a secret election, or conclave, in Vatican City",
        "One of their number will almost certainly emerge from the process as the new spiritual leader of the world's 1.2 billion Roman Catholics",
        "Applause echoed round St. Peter's as Cardinal Angelo Sodano, dean of the College of Cardinals, offered thanks for the \"brilliant pontificate\" of Benedict XVI, whose shock resignation precipitated the selection of a new pope",
        '"My brothers, let us pray that the Lord will grant us a pontiff who will embrace this noble mission with a generous heart," he concluded',
        'In the afternoon, the 115 cardinal-electors -- those younger than 80 who are eligible to vote -- will go to the Pauline Chapel for further prayers',
        "If they do, it's likely the first smoke might be seen around 8 p.m. (3 p.m. ET), he said",
        "If they do, it's likely the first smoke might be seen around 8 pm. (3 pm. ET), he said",
    ],

    "- Dette dreier seg om mobil i bil, men vi følger med på utviklingen av annen elektronikk, og dersom man for eksempel kjører uforsvarlig fordi man taster på GPS-en eller drikker kaffe, så vil dette rammes av veitrafikklovens paragraf 3." => [
        "Dette dreier seg om mobil i bil, men vi følger med på utviklingen av annen elektronikk, og dersom man for eksempel kjører uforsvarlig fordi man taster på GPS-en eller drikker kaffe, så vil dette rammes av veitrafikklovens paragraf 3",
    ],

    "For et par år siden inngikk de en utbyggingsavtale med Petter Øygarden og Bratsberg Gruppen.  At Porsgrunn kommune nå er interessert i å kjøpe en del av eiendommen, kan være en vinn-vinn-situasjon." => [
        "For et par år siden inngikk de en utbyggingsavtale med Petter Øygarden og Bratsberg Gruppen",
        "At Porsgrunn kommune nå er interessert i å kjøpe en del av eiendommen, kan være en vinn-vinn-situasjon",
    ],

    "Les også: Saken mot blogger Eivind Berge" => [
        "Les også",
        "Saken mot blogger Eivind Berge",
    ],

    "– Dette er den minst gjennomtenkte valgkampsaken i Norge på mange år. Her hadde Oslo Ap før første gang på mange år en god mulighet til å vinne makten i Oslo. Jeg skjønner ikke hvordan det er mulig å gjøre et så dårlig strategisk valg. De har selv bidratt til at Fabian Stang og Stian Berger Røsland mest sannsynlig får fortsette, sier pr-nestor Hans Geelmuyden, sjef i Geelmuyden Kiese." => [
        "– Dette er den minst gjennomtenkte valgkampsaken i Norge på mange år",
        "Her hadde Oslo Ap før første gang på mange år en god mulighet til å vinne makten i Oslo",
        "Jeg skjønner ikke hvordan det er mulig å gjøre et så dårlig strategisk valg",
        "De har selv bidratt til at Fabian Stang og Stian Berger Røsland mest sannsynlig får fortsette, sier pr-nestor Hans Geelmuyden, sjef i Geelmuyden Kiese",
    ],

    "Tor M. Sonsson" => [
        "Tor M. Sonsson",
    ],

    # "If you want cake open, door A. If you want a car, open door C." => [
    #     "If you want cake, open door A",
    #     "If you want a car, open door C",
    # ],
);

foreach my $sentence ( keys %tests ) {
    my $text     = Text::Info->new( $sentence );
    my $got      = [ map { $_->text } @{$text->sentences} ];
    my $expected = $tests{ $sentence };

    is_deeply( $got, $expected, "Sentence content matches!" );
    is( $text->sentence_count, scalar(@{$got}), "Sentence count matches!" );
}

done_testing;
