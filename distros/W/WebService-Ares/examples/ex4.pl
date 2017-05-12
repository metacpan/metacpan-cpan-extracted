#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Data::Printer;
use WebService::Ares::Standard qw(parse);

# Fake XML.
my $xml = <<'END';
<?xml version="1.0" encoding="UTF-8"?>
<are:Ares_odpovedi
xmlns:are="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1"
xmlns:dtt="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_datatypes/v_1.0.4"
xmlns:udt="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/uvis_datatypes/v_1.0.1"
odpoved_datum_cas="2014-08-18T07:43:50" odpoved_pocet="1" odpoved_typ="Standard"
vystup_format="XML" xslt="klient"
validation_XSLT="/ares/xml_doc/schemas/ares/ares_answer/v_1.0.0/ares_answer.xsl"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1
http://wwwinfo.mfcr.cz/ares/xml_doc/schemas/ares/ares_answer/v_1.0.1/ares_answer_v_1.0.1.xsd"
Id="ares">
<are:Odpoved>
<are:Pocet_zaznamu>1</are:Pocet_zaznamu>
<are:Typ_vyhledani>FREE</are:Typ_vyhledani>
<are:Zaznam>
<are:Shoda_ICO>
<dtt:Kod>9</dtt:Kod>
</are:Shoda_ICO>
<are:Vyhledano_dle>ICO</are:Vyhledano_dle>
<are:Typ_registru>
<dtt:Kod>3</dtt:Kod>
<dtt:Text>RES</dtt:Text>
</are:Typ_registru>
<are:Datum_vzniku>1992-07-01</are:Datum_vzniku>
<are:Datum_platnosti>2014-08-18</are:Datum_platnosti>
<are:Pravni_forma>
<dtt:Kod_PF>801</dtt:Kod_PF>
</are:Pravni_forma>
<are:Obchodni_firma>Statutární město Brno</are:Obchodni_firma>
<are:ICO>44992785</are:ICO>
<are:Identifikace>
<are:Adresa_ARES>
<dtt:ID_adresy>314885828</dtt:ID_adresy>
<dtt:Kod_statu>203</dtt:Kod_statu>
<dtt:Nazev_okresu>Brno-město</dtt:Nazev_okresu>
<dtt:Nazev_obce>Brno</dtt:Nazev_obce>
<dtt:Nazev_casti_obce>Brno-město</dtt:Nazev_casti_obce>
<dtt:Nazev_mestske_casti>Brno-střed</dtt:Nazev_mestske_casti>
<dtt:Nazev_ulice>Dominikánské náměstí</dtt:Nazev_ulice>
<dtt:Cislo_domovni>196</dtt:Cislo_domovni>
<dtt:Typ_cislo_domovni>1</dtt:Typ_cislo_domovni>
<dtt:Cislo_orientacni>1</dtt:Cislo_orientacni>
<dtt:PSC>60200</dtt:PSC>
<dtt:Adresa_UIR>
<udt:Kod_oblasti>60</udt:Kod_oblasti>
<udt:Kod_kraje>116</udt:Kod_kraje>
<udt:Kod_okresu>3702</udt:Kod_okresu>
<udt:Kod_obce>582786</udt:Kod_obce>
<udt:Kod_casti_obce>411582</udt:Kod_casti_obce>
<udt:Kod_mestske_casti>550973</udt:Kod_mestske_casti>
<udt:PSC>60200</udt:PSC>
<udt:Kod_ulice>22829</udt:Kod_ulice>
<udt:Cislo_domovni>196</udt:Cislo_domovni>
<udt:Typ_cislo_domovni>1</udt:Typ_cislo_domovni>
<udt:Cislo_orientacni>1</udt:Cislo_orientacni>
<udt:Kod_adresy>19095597</udt:Kod_adresy>
<udt:Kod_objektu>18945341</udt:Kod_objektu>
<udt:PCD>649906</udt:PCD>
</dtt:Adresa_UIR>
</are:Adresa_ARES>
</are:Identifikace>
<are:Priznaky_subjektu>NNAANANANNAANNNNNNNNPNNNANNNNN</are:Priznaky_subjektu>
</are:Zaznam>
</are:Odpoved>
</are:Ares_odpovedi>
END

# Parse.
my $data_hr = parse($xml);

# Print.
p $data_hr;

# Output:
# \ {
#     address       {
#         district     "Brno-město",
#         num          196,
#         num2         1,
#         psc          60200,
#         street       "Dominikánské náměstí",
#         town         "Brno",
#         town_part    "Brno-město",
#         town_urban   "Brno-střed"
#     },
#     company       "Statutární město Brno",
#     create_date   "1992-07-01",
#     ic            44992785
# }