#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Kramerius::API4::Feed;

if (@ARGV < 1) {
        print STDERR "Usage: $0 library_url\n";
        exit 1;
}
my $library_url = $ARGV[0];

my $obj = WebService::Kramerius::API4::Feed->new(
        'library_url' => $library_url,
);

my $custom_json = $obj->custom;

print $custom_json."\n";

# Output for 'http://kramerius.mzk.cz/', pretty print.
# {
#   "data": [
#     {
#       "issn": "",
#       "author": [
#         "Činčera, Josef K."
#       ],
#       "pid": "uuid:9ebcb206-24b7-4dc7-b367-3d9ad7179c23",
#       "model": "monograph",
#       "datumstr": "1923",
#       "title": "Šachy",
#       "root_pid": "uuid:9ebcb206-24b7-4dc7-b367-3d9ad7179c23",
#       "root_title": "Šachy",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "pid": "uuid:65713490-24e7-11e3-a5bb-005056827e52",
#       "model": "periodical",
#       "datumstr": "1890-1924",
#       "title": "Rašple: humoristický list dělného lidu : humoristicko-satyrický list dělného lidu : list politicko-humoristický",
#       "root_pid": "uuid:65713490-24e7-11e3-a5bb-005056827e52",
#       "root_title": "Rašple: humoristický list dělného lidu : humoristicko-satyrický list dělného lidu : list politicko-humoristický",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Gershwin, George",
#         "Rich, Fred",
#         "Hotel Astor Orchestra",
#         "Crooners (hudební skupina)"
#       ],
#       "pid": "uuid:59e708b6-c462-4610-90c5-ac5ca030050a",
#       "model": "soundrecording",
#       "datumstr": "1914",
#       "title": "Oh, Kay!. Clap yo' hands : fox trot. Do-do-do : fox trot",
#       "root_pid": "uuid:59e708b6-c462-4610-90c5-ac5ca030050a",
#       "root_title": "Oh, Kay!. Clap yo' hands : fox trot. Do-do-do : fox trot",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "pid": "uuid:58d629d0-a466-11e8-a81d-5ef3fc9bb22f",
#       "model": "periodical",
#       "datumstr": "1926",
#       "title": "Moravský illustrovaný zpravodaj : společenský, nepolitický týdeník",
#       "root_pid": "uuid:58d629d0-a466-11e8-a81d-5ef3fc9bb22f",
#       "root_title": "Moravský illustrovaný zpravodaj : společenský, nepolitický týdeník",
#       "policy": "private"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Zýbal, František,"
#       ],
#       "pid": "uuid:593878da-bfbb-4579-a1b5-743897383f78",
#       "model": "monograph",
#       "datumstr": "1941",
#       "title": "Malovaná mládež: humoresky ze života slováckých junáků",
#       "root_pid": "uuid:593878da-bfbb-4579-a1b5-743897383f78",
#       "root_title": "Malovaná mládež: humoresky ze života slováckých junáků",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "pid": "uuid:259f2cc0-973f-11e4-b7ae-001018b5eb5c",
#       "model": "periodical",
#       "datumstr": "1909-1931",
#       "title": "Kopřivy: list satyrický",
#       "root_pid": "uuid:259f2cc0-973f-11e4-b7ae-001018b5eb5c",
#       "root_title": "Kopřivy: list satyrický",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "mime": "image/jpeg",
#       "pid": "uuid:d22baf06-7fb6-4488-bc6f-995b644fd085",
#       "model": "page",
#       "datumstr": "1920",
#       "title": "[1]",
#       "root_pid": "uuid:ba4934d1-0a1e-4a01-a89d-c948477ca833",
#       "root_title": "Plán Velkého Brna",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Mácha Karel Hynek,"
#       ],
#       "pid": "uuid:f5a09c95-2fd8-11e0-83a8-0050569d679d",
#       "model": "monograph",
#       "datumstr": "1896",
#       "title": "Máj",
#       "root_pid": "uuid:f5a09c95-2fd8-11e0-83a8-0050569d679d",
#       "root_title": "Máj",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Rais, Karel Václav"
#       ],
#       "pid": "uuid:530719f5-ee95-4449-8ce7-12b0f4cadb22",
#       "model": "monograph",
#       "datumstr": "1889",
#       "title": "Když slunéčko svítí",
#       "root_pid": "uuid:530719f5-ee95-4449-8ce7-12b0f4cadb22",
#       "root_title": "Když slunéčko svítí",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Mahen, Jiří"
#       ],
#       "pid": "uuid:b53d33f0-70a5-11e5-9690-005056827e51",
#       "model": "monograph",
#       "datumstr": "1921",
#       "title": "Jak se dělá divadlo?: nezbytná příručka pro všechna divadla a pro ochotníky",
#       "root_pid": "uuid:b53d33f0-70a5-11e5-9690-005056827e51",
#       "root_title": "Jak se dělá divadlo?: nezbytná příručka pro všechna divadla a pro ochotníky",
#       "policy": "public"
#     },
#     {
#       "issn": "1802-6265",
#       "pid": "uuid:bdc405b0-e5f9-11dc-bfb2-000d606f5dc6",
#       "model": "periodical",
#       "datumstr": "1936 - 1945",
#       "title": "Lidové noviny",
#       "root_pid": "uuid:bdc405b0-e5f9-11dc-bfb2-000d606f5dc6",
#       "root_title": "Lidové noviny",
#       "policy": "public"
#     },
#     {
#       "issn": "0862-7967",
#       "pid": "uuid:f1c7c08d-8f64-4b66-be28-5f209c2c7021",
#       "model": "periodical",
#       "datumstr": "1885-1928,1945-2001",
#       "title": "Rovnost : list sociálních demokratů českých",
#       "root_pid": "uuid:f1c7c08d-8f64-4b66-be28-5f209c2c7021",
#       "root_title": "Rovnost : list sociálních demokratů českých",
#       "policy": "public"
#     },
#     {
#       "issn": "0862-1985",
#       "pid": "uuid:13f650ad-6447-11e0-8ad7-0050569d679d",
#       "model": "periodical",
#       "datumstr": "1987-",
#       "title": "Duha",
#       "root_pid": "uuid:13f650ad-6447-11e0-8ad7-0050569d679d",
#       "root_title": "Duha",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "mime": "image/jpeg",
#       "pid": "uuid:c53e4155-5748-11e3-8d00-0050569d679d",
#       "model": "page",
#       "datumstr": "[1902]",
#       "title": "[a]",
#       "root_pid": "uuid:4d38f82d-eff9-4d74-93cf-01d6a71dc00d",
#       "root_title": "Novy hanácky pěsničke",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Martini Johann Georg"
#       ],
#       "pid": "uuid:2fa33e93-7bb8-441c-aa5a-0f63bd565b94",
#       "model": "graphic",
#       "datumstr": "1844",
#       "title": "Brünn",
#       "root_pid": "uuid:2fa33e93-7bb8-441c-aa5a-0f63bd565b94",
#       "root_title": "Brünn",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "pid": "uuid:a101de00-2119-11e3-a5bb-005056827e52",
#       "model": "periodical",
#       "datumstr": "1897-1921",
#       "title": "Brněnské noviny",
#       "root_pid": "uuid:a101de00-2119-11e3-a5bb-005056827e52",
#       "root_title": "Brněnské noviny",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "pid": "uuid:eb3adc60-dd58-11e2-9923-005056827e52",
#       "model": "periodical",
#       "datumstr": "1848-1921",
#       "title": "Brünner Zeitung",
#       "root_pid": "uuid:eb3adc60-dd58-11e2-9923-005056827e52",
#       "root_title": "Brünner Zeitung",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Masaryk, Tomáš Garrigue"
#       ],
#       "pid": "uuid:1400b020-1959-11e3-9319-005056827e51",
#       "model": "monograph",
#       "datumstr": "1919",
#       "title": "Ideály humanitní: (několik kapitol)",
#       "root_pid": "uuid:1400b020-1959-11e3-9319-005056827e51",
#       "root_title": "Ideály humanitní: (několik kapitol)",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "pid": "uuid:1715b00c-4885-43b9-86cc-db9f41f2cccf",
#       "model": "graphic",
#       "datumstr": "1910-1940",
#       "title": "[Neznámý muž s dýmkou]",
#       "root_pid": "uuid:1715b00c-4885-43b9-86cc-db9f41f2cccf",
#       "root_title": "[Neznámý muž s dýmkou]",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "mime": "image/jpeg",
#       "pid": "uuid:c4d92170-dd82-11e6-b333-5ef3fc9ae867",
#       "model": "page",
#       "datumstr": "[1905]",
#       "title": "[1]",
#       "root_pid": "uuid:1f7250f0-c83b-11e6-8032-005056827e52",
#       "root_title": "Album von Brünn",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "mime": "image/jpeg",
#       "pid": "uuid:a32dbd70-9375-11e7-a9a4-005056827e51",
#       "model": "page",
#       "datumstr": "1907",
#       "title": "[1a]",
#       "root_pid": "uuid:16361ef0-5b01-11e7-b9d9-005056827e52",
#       "root_title": "Moravské ovoce: Pojednání o ovocných odrůdách doporučených ku pěstování v českých krajích markrabství Moravského",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Machát, František",
#         "Neubert, Václav"
#       ],
#       "pid": "uuid:5e1e9cd8-eecd-4627-9a1a-09c53caaf9a8",
#       "model": "map",
#       "datumstr": "[mezi 1918 a 1920]",
#       "title": "Stát československý",
#       "root_pid": "uuid:5e1e9cd8-eecd-4627-9a1a-09c53caaf9a8",
#       "root_title": "Stát československý",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "pid": "uuid:fa14a490-3d00-11e6-8746-005056825209",
#       "model": "periodical",
#       "datumstr": "1922-1943",
#       "title": "Salon: společnost, sport, divadlo, film, moda, výtvarné umění",
#       "root_pid": "uuid:fa14a490-3d00-11e6-8746-005056825209",
#       "root_title": "Salon: společnost, sport, divadlo, film, moda, výtvarné umění",
#       "policy": "private"
#     },
#     {
#       "issn": "",
#       "author": [
#         "Vrchlický, Jaroslav"
#       ],
#       "pid": "uuid:7b5117e0-cc57-11e3-b110-005056827e51",
#       "model": "monograph",
#       "datumstr": "1913",
#       "title": "Noc na Karlštejně: veselohra o 3 jednáních",
#       "root_pid": "uuid:7b5117e0-cc57-11e3-b110-005056827e51",
#       "root_title": "Noc na Karlštejně: veselohra o 3 jednáních",
#       "policy": "public"
#     },
#     {
#       "issn": "",
#       "mime": "image/jpeg",
#       "pid": "uuid:4ac1bb48-5774-11e3-ae9f-0050569d679d",
#       "model": "page",
#       "datumstr": "1898",
#       "title": "[a]",
#       "root_pid": "uuid:3da9a2e8-5c49-4279-8537-f0f59c0562d4",
#       "root_title": "Hasičská kronika",
#       "policy": "public"
#     }
#   ]
# }