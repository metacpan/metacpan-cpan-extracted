# $Id: Makefile 113 2006-07-07 10:02:33Z nanardon $

.SUFFIXES: .dvi .pdf .eps .fig .png

SOURCES= \
	mmm_fr.tex

FIGURES= \
	listsexchanges.fig \

IMAGES= \
	reportwww.png \
	listswww.png \

EXAMPLES = \

DVI=$(SOURCES:.tex=.dvi)
PDF=$(SOURCES:.tex=.pdf)
EPS=$(FIGURES:.fig=.eps) $(IMAGES:.png=.eps)

all: pdf

pdf: $(EPS) $(PDF)

dvi: $(EPS) $(DVI)

%.dvi: %.tex $(EPS)
	latex -halt-on-error $< && latex -halt-on-error $<

%.pdf: %.dvi
	dvipdf $< $@

%.eps: %.fig
	fig2dev -L eps  $< $@

.png.eps:
	convert $< $@

clean:
	rm -f $(EPS)
	rm -f $(DVI)
	rm -f $(PDF)

.PHONY: clean
