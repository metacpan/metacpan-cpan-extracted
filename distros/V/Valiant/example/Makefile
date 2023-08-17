#
# makefile to help find your way around
#

help:
	@echo ""
	@echo "==> Manage Demo Application"
	@echo "update_cpanlib			Install CPAN libs"		
	@echo "update_db			Deploy Sqitch"
	@echo "update				(both above)"
	@echo "server				Start demo application"
	@echo "dependencies			list (most) CPAN dependencies"
	@echo ""


update_cpanlib:
	@cpanm --verbose --installdeps .

update_db:
	@sqitch deploy

update: update_cpanlib update_db

server:
	@DBIC_TRACE=1 perl \
		-I ../lib \
		-I /Users/jnapiorkowski/Desktop/Catalyst/Catalyst-Runtime/lib \
		-I ./lib \
		./lib/Example/PSGI.pm

dependencies:
	@ack '^use ' -h --nobreak | perl -nle'++$lines{$_}; END { print for sort grep $lines{$_}==1, keys %lines; }

