sourcedir=../../testfiles/23-methods
insource=${sourcedir}/test1.in
in=test1.in
procf=test1.txt
outsource=${sourcedir}/test1.out
#outrsource=${sourcedir}/text-replace.out
#outr=text-replace.out
help:
	@echo '# Makefile for test 23-methods'
	@echo '# Used only for development'
	@echo make
	@echo '	test	run full test (make -C ../.. test)'
	@echo '	em1	emacs input and output for checking'
	@echo '	em2	emacs input and replace-output for checking'
	@echo '	cp-back-in	copy input back to source'
	@echo '	cp-back-o	copy output to source'
	@echo '	cp-back-or	copy replace-output to source'
	@echo '	cp-back-m	copy Makefile to source'

.PHONY: help em1 em2 cp-back-in cp-back-o cp-back-or cp-back-m test
test:; make -C ../.. test
em1:; emacs -nw ${in} ${procf}
em2:; emacs -nw ${in} ${outr}
cp-back-in:; cp ${in} ${insource}
cp-back-o:;  cp ${procf} ${outsource}
#cp-back-or:; cp ${outr} ${outrsource}
cp-back-m:; cp Makefile ${sourcedir}/


