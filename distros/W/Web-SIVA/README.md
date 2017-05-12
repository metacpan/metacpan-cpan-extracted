# perl5-web-siva

[![Build Status](https://travis-ci.org/JJ/perl5-web-siva.svg?branch=master)](https://travis-ci.org/JJ/perl5-web-siva)

`Web::SIVA` Perl module for scraping air quality web in Andalucía,
Spain. It extracts quantitative data
from
[this web](http://www.juntadeandalucia.es/medioambiente/site/portalweb/menuitem.7e1cf46ddf59bb227a9ebe205510e1ca/?vgnextoid=7e612e07c3dc4010VgnVCM1000000624e50aRCRD&vgnextchannel=3b43de552afae310VgnVCM2000000624e50aRCRD) and
returns it in a reasonable format. Some data from Granada has been
uploaded to [FigShare](https://figshare.com/articles/Air_quality_data_Granada_1998-_March_2017/4724839)


## INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

If there are some dependencies missing,

	cpanm --installdeps .
	
You should do it anyway, just in case. 

## DEPENDENCIES

`Mojo::DOM` for scraping, `LWP::Simple` for downloading 



## COPYRIGHT AND LICENCE

Copyright (C) 2017, JJ

This library is free software; you can redistribute it and/or modify
it under the GPL

