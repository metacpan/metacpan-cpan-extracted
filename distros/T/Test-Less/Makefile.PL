use inc::Module::Install;

name('Test-Less');
author('Brian Ingerson <ingy@cpan.org>');
abstract('Test Categorization and Subset Execution');
license('perl');
version_from('lib/Test/Less.pm');

requires(qw(
    perl 5.6.1
    Test::Harness 2.46
    Test::Base 0.40
    Spiffy 0.24
));

install_script('test-less');

clean_files('t/Test-Less');

check_nmake();

&WriteAll();
