
TOP = ..
LIB = ../lib
POD2HTML = perl -I ~/dev/perl/podpeople/lib \
		~/dev/perl/podpeople/bin/pod2coolhtml

MOD = ${LIB}/Text/Refer.pm

dist: all

all: readme htmls


readme: ../README

../README : ${MOD}
	pod2readme -t $< > ../README

htmls: ${MOD}
	( ${POD2HTML} -R ${LIB} -I Text -O . )

