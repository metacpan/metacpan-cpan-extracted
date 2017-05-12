#!/bin/bash

perl -Ilib scripts/drop.tables.pl
perl -Ilib scripts/create.tables.pl

echo Run populate.countries.pl

perl -Ilib scripts/populate.countries.pl -maxlevel debug

echo Run populate.subcountries.pl

perl -Ilib scripts/populate.subcountries.pl -maxlevel debug

echo Run export.as.html.pl

perl -Ilib scripts/export.as.html.pl -w data/iso.3166-2.html

cp data/iso.3166-2.html $DR/
cp data/iso.3166-2.html ~/savage.net.au/Perl-modules/html/WWW/Scraper/Wikipedia/ISO3166/

echo Copied data/iso.3166-2.html to doc root

echo Run export.as.csv.pl

perl -Ilib scripts/export.as.csv.pl \
	-countries_file				data/countries.csv \
	-subcountry_categories_file	data/subcountry_categories.csv \
	-subcountries_file			data/subcountries.csv \
	-subcountry_info_file		data/subcountry_info.csv

echo Finished
