
PATH_SHEET=\some-where\docbook-xsl-1.62.4 # FIXME


all:
	dtd2db.pl -o ppd -x sample.ppd entry.ppd
	xsltproc -o ppd.html --timing --novalid $(PATH_SHEET)\xhtml\docbook.xsl ppd.xml

chunk:
	xsltproc --novalid $(PATH_SHEET)\xhtml\chunk.xsl ppd.xml

chm:
	xsltproc --novalid --stringparam htmlhelp.chm ppd.chm --param htmlhelp.show.advanced.search 1 $(PATH_SHEET)\htmlhelp\htmlhelp.xsl ppd.xml
	hhc htmlhelp.hhp

pdf:
	xsltproc -o ppd.fo --timing --novalid --stringparam paper.type A4 $(PATH_SHEET)\fo\docbook.xsl ppd.xml
	fop -fo ppd.fo -pdf ppd.pdf

lint:
	xmllint --noout --valid ppd.xml 2> lint.err

dtd:
	dtd2db.pl -d -o out.dtd entry.ppd

clean:
	rm *.xml
	rm *.gen
	rm *.ent
	rm *.html
	rm *.fo
	rm *.pdf
