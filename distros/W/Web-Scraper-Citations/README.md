# Web::Scraper::Citations

[Google scholar citations](http://scholar.google.com/citations) profile scraper. Extracts citation stats.  

##Build status

If this fails, you will probably be OK, might mean Google has banned Circle CI (after having banned Travis)

[![Circle CI](https://circleci.com/gh/JJ/net-citations-scraper.svg?style=svg)](https://circleci.com/gh/JJ/net-citations-scraper)

##Installation

After cloning from here (which you might have done already),

	cpanm --installdeps .
	perl Makefile.PL
	make
	make test
	make install

Done!
