# TOP_TK = ../../../Tk-4.1a0.my		# Set in Makefile
TOP_pTk = $(TOP_TK)/pTk

%.c : mTk/%.c ./Tcl-pTk 
	-chmod a+w $@
	$(PERL) ./Tcl-pTk $< $@

%.h : mTk/%.h ./Tcl-pTk 
	-chmod a+w $@
	$(PERL) ./Tcl-pTk $< $@

%.c : Tk/%.c ./Tcl-pTk
	-chmod a+w $@
	$(PERL) ./Tcl-pTk $< $@


%.h : Tk/%.h ./Tcl-pTk
	-chmod a+w $@
	$(PERL) ./Tcl-pTk $< $@

include Makefile

# Auto generation of Xlib.h disabled for now
#Xlib.h : config/Xdummy.c mkXinfo $(C_FILES) $(wildcard xpm/*.c)
#	$(PERL) mkXinfo Xlib.h -I . $(DEFINE) $(INC)  config/Xdummy.c 

c     : need counts 
	counts *.c | sort -rn > c

need  : GNUmakefile $(LIBOBJS) ../tkGlue.o 
	-ld -r -o /tmp/junk $(LIBOBJS) ../tkGlue.o
	nm -p /tmp/junk >$@

source : $(C_FILES) 

$(wildcard *.t) : mkVFunc

Methods.def : $(TOP_pTk)/mkmethods $(C_FILES)
	$(PERL) $(TOP_pTk)/mkmethods $@ $(C_FILES)
	$(PERL) -i~ -pe 's/"Text"/"eText"/' $@

config :: Methods.def

-include $(wildcard *.d)
