#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Kramerius::API4::Feed;

if (@ARGV < 1) {
        print STDERR "Usage: $0 library_url [offset] [limit]\n";
        exit 1;
}
my $library_url = $ARGV[0];
my $offset = $ARGV[1] || 0;
my $limit = $ARGV[2] || 1;

my $obj = WebService::Kramerius::API4::Feed->new(
        'library_url' => $library_url,
);

my $mostdesirable_json = $obj->mostdesirable({
        'limit' => $limit,
        'offset' => $offset,
});

print $mostdesirable_json."\n";

# Output for 'http://kramerius.mzk.cz/', pretty print.
# {
#   "rss": "https://kramerius.mzk.cz/search/inc/home/mostDesirables-rss.jsp",
#   "data": [
#     {
#       "issn": "",
#       "author": [
#         "Veselá, Jarmila",
#         "Vlach, Karel",
#         "Werich, Jan",
#         "Zeman, Bohumil",
#         "Zíma, Josef",
#         "Černý, Miroslav",
#         "Čeřovská, Judita",
#         "Adam, Richard",
#         "Benešová, Věra",
#         "Benš, Pavel",
#         "Brom, Gustav",
#         "Chladil, Milan",
#         "Cortés, Rudolf",
#         "Duda, Karel",
#         "Hertl, František",
#         "Jelínek, Jiří",
#         "Kopecký, Miloš",
#         "Kubernát, Richard",
#         "Kučerová, Marta",
#         "Martinová, Eva",
#         "Popper, Jiří",
#         "Procházka, Tomáš",
#         "Simonová, Yvetta",
#         "Směták, Milan",
#         "Vašíček, Jiří",
#         "Orchestr Mirko Foreta",
#         "Sestry Allanovy (hudební skupina)",
#         "Kučerovci (hudební skupina)",
#         "Brněnský estrádní rozhlasový orchestr",
#         "Orchestr Divadla hl. m. Prahy v Karlíně",
#         "Orchestr Gustava Broma",
#         "Orchestr Jaroslava Echtnera",
#         "Orchestr Jiřího Procházky",
#         "Orchestr Karla Krautgartnera",
#         "Orchestr Karla Vlacha"
#       ],
#       "pid": "uuid:49f861c4-0ce0-4bce-be0a-af7f071c5933",
#       "model": "soundrecording",
#       "datumstr": "p1992",
#       "title": "Hity 50. let. 2",
#       "root_pid": "uuid:49f861c4-0ce0-4bce-be0a-af7f071c5933",
#       "root_title": "Hity 50. let. 2",
#       "policy": "private"
#     }
#   ]
# }