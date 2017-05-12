
UNICODE_VERSION = 6.3.0

../precis_preparation.c: precis_preparation.pl
	perl precis_preparation.pl \
		precis-tables-$(UNICODE_VERSION).csv \
		DerivedAge-$(UNICODE_VERSION).txt \
		UnicodeData-$(UNICODE_VERSION).txt \
		ArabicShaping-$(UNICODE_VERSION).txt \
		Scripts-$(UNICODE_VERSION).txt \
		../precis_preparation.c

