use inc::Module::Install;

name('WWW-Scraper-ISBN-TWYlib_Driver');
author('Ying-Chieh Liao <ijliao@csie.nctu.edu.tw>');
abstract("Search driver for TWYlib's online catalog.");
license('perl');
version_from('lib/WWW/Scraper/ISBN/TWYlib_Driver.pm');

requires(qw(
	perl				5.6.1
	Test::More			0
	WWW::Scraper::ISBN		0.25
	WWW::Scraper::ISBN::Driver	0.18
	Template::Extract		0.40
	WWW::Mechanize			1.16
));

WriteAll();
