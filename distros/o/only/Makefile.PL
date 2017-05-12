use inc::Module::Install;

name           ('only');
version_from   ('lib/only.pm');
abstract       ('Load specific module versions; Install many');
author         ('Brian Ingerson <ingy@cpan.org>');
license        ('perl');

requires( perl => '5.004' );
# include_deps   ('Test::More', 5.004);
# build_requires ('Test::More', 0);

clean_files(qw(lib/only/config.pm));
clean_files(qw(t/lib t/site t/distributions t/version t/alternate));

create_config_module();

check_nmake();

&Meta->write;
&Makefile->write;
