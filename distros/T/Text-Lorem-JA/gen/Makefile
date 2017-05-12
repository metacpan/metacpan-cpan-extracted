SOURCES:=	text/43535.txt text/44814.txt

define PREPEND_COMMENT
# This dictionary is built from following out-of-copyright articles.
# - "学問の自由" by 寺田 寅彦 on http://www.aozora.gr.jp/cards/000042/card43535.html
# - "劇の好きな子供たちへ" by 岸田 国士 on http://www.aozora.gr.jp/cards/001154/card44814.html
endef
export PREPEND_COMMENT

DICT:=		../share/dict.txt

target:		$(DICT)

clean:
	rm -f $(DICT)
	rm -f text/*

$(DICT):	$(SOURCES)
	@echo "$$PREPEND_COMMENT" > $@
	cat $^ | mecab -O simple | carton exec perl make_dict.pl --skip-bracket >> $@

text/%.txt:	recipe/%.pl
	carton exec perl $<

