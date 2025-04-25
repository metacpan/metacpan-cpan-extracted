
UNICODE_VERSION = 9.0.0
PERL = perl5.26.0

../precis_preparation.c: precis_preparation.pl precis-table.csv
	$(PERL) precis_preparation.pl \
		$(UNICODE_VERSION) \
		precis-table.csv \
		../precis_preparation.c

precis-table.csv: make_table.pl
	$(PERL) make_table.pl $(UNICODE_VERSION) > precis-table.csv || \
	rm -f precis-table.csv

