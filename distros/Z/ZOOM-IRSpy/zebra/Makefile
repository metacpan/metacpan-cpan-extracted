
IRSPY_ARCHIVE=		records-2010-04-20
IRSPY_ARCHIVE_EXT=	.tar.gz
DUMP_DIR=		irspy-dump
ZEBRA_DIR=		db
ZEBRAIDX=		zebraidx-2.0 
ZEBRAIDX_TEST=		zebraidx-2.0 -c zebra-test.cfg
IRSPY_DATABASE=		$${IRSpyDbName-"localhost:8018/IR-Explain---1"}

# debugging
ZEBRA_TEST_DIR=		db-test

DATE:=	$(shell date '+%Y-%m-%d')

all: help


test:
	xmllint --noout --schema zeerex-2.0.xsd zeerex.xml

terse.properties: pqf.properties
	sed -n 's/#.*//; s/[ 	]*//; s/[ 	][ 	]*/ /g; /./p' $? > $@

newdb:
	tar xzf ${DUMP_DIR}/${IRSPY_ARCHIVE}${IRSPY_ARCHIVE_EXT}
	mkdir -p ${ZEBRA_DIR}/lock ${ZEBRA_DIR}/register ${ZEBRA_DIR}/shadow ${ZEBRA_DIR}/tmp
	${ZEBRAIDX} init
	${ZEBRAIDX} update zeerex.xml
	${ZEBRAIDX} update ${IRSPY_ARCHIVE}
	${ZEBRAIDX} commit

newdb-test:
	tar xzf ${DUMP_DIR}/${IRSPY_ARCHIVE}${IRSPY_ARCHIVE_EXT}
	mkdir -p ${ZEBRA_TEST_DIR}/lock ${ZEBRA_TEST_DIR}/register ${ZEBRA_TEST_DIR}/shadow ${ZEBRA_TEST_DIR}/tmp
	${ZEBRAIDX_TEST} init
	${ZEBRAIDX_TEST} update zeerex-test.xml
	${ZEBRAIDX_TEST} update ${IRSPY_ARCHIVE}
	${ZEBRAIDX_TEST} commit

# note: the test database use localhost:8019/IR-Explain---1
dump:
	rm -rf records-${DATE}.old
	-test -e records-${DATE} && mv records-${DATE} records-${DATE}.old
	mkdir records-${DATE}
	cd records-${DATE} && ../../bin/irspy-dump.pl ${IRSPY_DATABASE}
	cd records-${DATE} && ( for i in *.xml; do tidy -xml -i -m -w 140 $$i; done ) > /dev/null 2>&1 
	tar cf - records-${DATE} | gzip > records-${DATE}.tar.gz
	
clean:
	rm -f terse.properties

distclean: clean
	rm -rf ${IRSPY_ARCHIVE} ${ZEBRA_DIR} ${ZEBRA_DIR} ${ZEBRA_TEST_DIR}

help:
	@echo "make [ dump | test | newdb | newdb-test | clean | distclean ]"

