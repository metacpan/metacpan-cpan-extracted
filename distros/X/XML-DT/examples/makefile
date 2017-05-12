all:
	arq.pl arq.xml > _.html
	scp _.html alfarrabio.um.geira.pt:public_html/img_arq/lista.html
	arq2.pl arq.xml > _.d1
	scp _.d1 alfarrabio.um.geira.pt:aea/img_arq.d1

A=xml::dt.html

$a: XML/DT.pm
	pod2html --title XML/DT.pm > xml::dt.html

_titulos: pub.pl _10nov.xml
	pub.pl _10nov.xml > _titulos

_10nov.xml: 10nov.sgm publico.dtd
	sx 10nov.sgm > _10nov.xml

clean:
	rm -f _*
