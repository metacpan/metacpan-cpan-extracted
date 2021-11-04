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
	@echo "create_migration name=???	Create a new migration"
	@echo "dependencies			list (most) CPAN dependencies"
	@echo ""


update_cpanlib:
	@cpanm --verbose --installdeps .

update_db:
	@sqitch deploy

update: update_cpanlib update_db

server:
	@CATALYST_DEBUG=1 DBIC_TRACE=1 perl -Ilib -I ../lib/  ./lib/Example/Server.pm

dependencies:
	@ack '^use ' -h --nobreak | perl -nle'++$lines{$_}; END { print for sort grep $lines{$_}==1, keys %lines; }

create_migration:
	perl -Ilib  -I ~/Desktop/Valiant/lib -I ./lib/ -MExample -e 'Example->create_migration("$(name)", "$(notes)")'

