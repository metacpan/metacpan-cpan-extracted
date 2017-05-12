.PHONY: $(shell ls)
.SILENT:

OPT = -w -Mstrict -Mv5.10 -MData::Dumper   -Mblib -MData::Show
vi  = vi -p  -c 'set nofoldenable'

all:check

copyright_injector ci:
	perl $(OPT) ../script/copyright-injector.pl  ../examples   check
check add remove :
	perl $(OPT) ../script/copyright-injector.pl -y  ../examples   $@
grep:
	-grep -r Copyright lib/* script/*
