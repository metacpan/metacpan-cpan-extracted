
simple:
	dtd2html.pl -o ppd entry.ppd

frame:
	mkdir frame
	dtd2html.pl -f -o frame/ppd entry.ppd

book:
	mkdir book
	dtd2html.pl -b -o book/ppd -s style -x sample.ppd entry.ppd

dtd:
	dtd2html.pl -d -o out.dtd entry.ppd