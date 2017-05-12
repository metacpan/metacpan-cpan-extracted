TEXS = DocMain.tex Configuration.tex CrawlerOperation.tex DocMain.tex documentation.tex FAQ.tex Intro.tex \
 OpenSourceDistr.tex SystemComponents.tex ExpectedPerformance.tex  ClassificationEval.tex
GENTEXS = ConfigVars.tex DepGraph.tex ManPages.tex SQL.tex InstallationTest.tex PlugInTemplate.tex
IMGS = CrawlerArchitecture.xfig.eps TopicFilter.xfig.eps CrawlerSpeed.ps Config.ps focusedrobot.eps
BINS = ../bin/combine*
MODULES = ../Combine/*.pm

all : pdf html
dvi : DocMain.dvi
pdf : DocMain.pdf
ps  : DocMain.ps

DocMain.pdf : DocMain.dvi
	    rm -f DocMain.aux DocMain.log DocMain.pdf DocMain.toc DocMain.out
	    pdflatex DocMain.tex

DocMain.ps : DocMain.dvi
	   dvips -o DocMain.ps DocMain.dvi

tex : $(TEXS) $(GENTEXS) $(IMGS) myalvis.bib
	latex DocMain.tex

DocMain.dvi : $(TEXS) $(GENTEXS) $(IMGS) myalvis.bib
	    latex DocMain.tex
	    bibtex DocMain
	    latex DocMain.tex
	    latex DocMain.tex

ConfigVars.tex : ../conf/default.cfg ../conf/job_default.cfg $(BINS) $(MODULES) genConfigDoc.pl
	./genConfigDoc.pl > ConfigVars.tex

DepGraph.tex : $(BINS) $(MODULES) genDepGraph.pl
	./genDepGraph.pl > DepGraph.tex

ManPages.tex : $(BINS) $(MODULES) genPod2latex.pl
	./genPod2latex.pl > ManPages.tex

SQL.tex : ../bin/combineINIT extrSQLdoc.pl
	./extrSQLdoc.pl > SQL.tex

InstallationTest.tex : InstallationTest.pl genInstTest.pl
	./genInstTest.pl > InstallationTest.tex

PlugInTemplate.tex : ../templates/classifyPlugInTemplate.pm genPlugInTemplate.pl
	./genPlugInTemplate.pl > PlugInTemplate.tex

html : DocMain.dvi
	htlatex DocMain.tex "html,2"
	\rm -rf HTML
	mkdir HTML
	mv DocMain*.html DocMain*.png DocMain.css HTML/

clean :
	\rm -rf HTML *.aux *.log *.dvi  DocMain*.html DocMain*.png DocMain.css DocMain.ps DocMain.pdf *.toc $(GENTEXS)
	\rm -f DocMain.4ct  DocMain.4tc  DocMain.bbl  DocMain.blg  DocMain.idv  DocMain.lg  DocMain.out DocMain.tmp  DocMain.xref
