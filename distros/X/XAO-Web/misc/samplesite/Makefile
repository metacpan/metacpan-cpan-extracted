# In most cases the only thing you need to change here is project name
#
PROJECT=samplesite

###############################################################################

all:	consistency permissions configure

clean:
	rm -rf ta

dist:	consistency
	VERSION=`date '+%Y%m%d'`; \
		perl -MExtUtils::Manifest=manicopy,maniread \
			-e "manicopy(maniread(),'${PROJECT}-$$VERSION', 'best');"; \
		tar -cvzf ${PROJECT}-$$VERSION.tar.gz ${PROJECT}-$$VERSION; \
		rm -rf ${PROJECT}-$$VERSION

distcheck:
	perl -MExtUtils::Manifest=fullcheck -e fullcheck

test:
	@perl -w -MXAO::TestUtils -e 'XAO::TestUtils::xao_test_all("testcases")'

configure:
	@perl ./configure.pl

permissions:
	@perl -MXAO::TestUtils -eXAO::TestUtils::xao_mf_fix_permissions

consistency:
	@perl -MXAO::TestUtils -eXAO::TestUtils::xao_mf_check_consistency
